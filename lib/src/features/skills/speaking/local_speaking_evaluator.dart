import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Local-only speaking test evaluator that doesn't use database
/// Evaluates speaking responses directly via AI without storing
class LocalSpeakingEvaluator {
  /// Evaluate speaking answers locally without database storage
  static Future<Map<String, dynamic>> evaluateLocal({
    required Map<String, dynamic> testData,
    required Map<String, String> answers,
  }) async {
    final title = testData['title'] ?? 'Speaking Test';
    final moduleType = testData['module_type'] ?? 'speaking';
    final difficulty = testData['difficulty'] ?? 'B1';
    final questions = testData['questions'] as List<dynamic>;

    // Normalize questions so each uses a 5-point scale (0-5)
    final normalizedQuestions = questions.map<Map<String, dynamic>>((q) {
      final m = Map<String, dynamic>.from(q as Map);
      m['points'] = 5;
      return m;
    }).toList();

    // Build evaluation prompt using normalized questions
    final questionsWithAnswers = normalizedQuestions.map((q) {
      final qid = q['question_id'];
      final questionId = (qid is String) ? qid : qid.toString();
      return {
        'question_text': q['question_text'],
        'user_answer': answers[questionId] ?? '',
        'points': q['points'] ?? 5,
      };
    }).toList();

    final prompt = _buildEvaluationPrompt(
      title: title,
      moduleType: moduleType.toString(),
      difficulty: difficulty.toString(),
      questionsWithAnswers: questionsWithAnswers,
    );

    // Get AI evaluation
    print('🎤 Calling AI for speaking evaluation...');
    print('Questions: ${questions.length}');
    print('Answers provided: ${answers.length}');

    final aiResponse = await _callChatGPT(prompt);

    print('✅ AI Response received');
    print(
      'Response preview: ${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}...',
    );

    // Parse the response
    // Parse using normalized questions so totals reflect 5 points per question
    final results = _parseAIResponse(aiResponse, normalizedQuestions, answers);

    print('📊 Final score: ${results['score']}/${results['total_points']}');

    return results;
  }

  static String _buildEvaluationPrompt({
    required String title,
    required String moduleType,
    required String difficulty,
    required List<Map<String, dynamic>> questionsWithAnswers,
  }) {
    return """
You are an experienced IELTS Speaking examiner. Evaluate these transcribed spoken responses.

Test Information:
- Title: $title
- Module: $moduleType
- Difficulty: $difficulty

IMPORTANT: The user_answer is a transcription from speech recognition and may contain:
- Minor transcription errors (e.g., "there" instead of "their")
- Missing punctuation
- Filler words (um, uh, like)

BE GENEROUS with scoring - if the student makes an attempt and the response shows effort, give credit.

Evaluate based on IELTS Speaking criteria:
1. Fluency and Coherence: Does the response flow naturally? Is it organized?
2. Lexical Resource: Vocabulary range and accuracy
3. Grammatical Range: Variety of structures used
4. Task Achievement: Does it answer the question adequately?

Scoring Guidelines:
- Use a 0-5 scale for each question (0 = no credit, 5 = excellent)
- Award FULL points (equal to the 'points' value provided for the question) if the response addresses the question with reasonable content
- Award PARTIAL points (1-4) if the response is incomplete but shows understanding
- Award 0 points ONLY if no response or completely off-topic

For each question, you MUST provide:
- is_correct: true if response addresses question (be very lenient), false only if empty/wrong
- points_earned: Award the maximum points listed unless response is very poor
- feedback: Brief constructive feedback (1-2 sentences)

Questions and Responses:
${jsonEncode(questionsWithAnswers)}

CRITICAL: Return ONLY valid JSON, no markdown, no code blocks, no extra text.
Use this EXACT format (points_earned should be an integer between 0 and the question's points):
{
  "results": [
    {
      "question_index": 0,
      "is_correct": true,
      "points_earned": 4,
      "feedback": "Your feedback here"
    }
  ],
  "overall_feedback": "Overall assessment (2-3 sentences)",
  "total_points_earned": 16,
  "total_points_possible": 20
}
""";
  }

  static Future<String> _callChatGPT(String prompt) async {
    final apiKey = dotenv.env['CHATGPT_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('CHATGPT_API_KEY is missing.');
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an IELTS speaking examiner. Return ONLY valid JSON with no markdown formatting or code blocks.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.2,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI evaluation failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  static Map<String, dynamic> _parseAIResponse(
    String aiResponse,
    List<dynamic> questions,
    Map<String, String> answers,
  ) {
    try {
      // Clean up response - remove markdown code blocks if present
      String cleanResponse = aiResponse.trim();
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.replaceAll(RegExp(r'```json\s*'), '');
        cleanResponse = cleanResponse.replaceAll(RegExp(r'```\s*'), '');
        cleanResponse = cleanResponse.trim();
      }

      final parsed = jsonDecode(cleanResponse) as Map<String, dynamic>;
      final results = parsed['results'] as List;
      final overallFeedback =
          parsed['overall_feedback'] ?? 'Evaluation complete.';
      final totalEarned = parsed['total_points_earned'] ?? 0;
      // If the AI did not return total points possible, compute from question defaults (5 points each)
      final totalPossible =
          parsed['total_points_possible'] ??
          questions.fold<int>(0, (sum, q) {
            final p = q['points'];
            final int points = p is int ? p : (p is num ? p.toInt() : 5);
            return sum + points;
          });

      // Build detailed answers list
      final detailedAnswers = <Map<String, dynamic>>[];
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final qid = q['question_id'];
        final questionId = (qid is String) ? qid : qid.toString();

        final result = results.firstWhere(
          (r) => r['question_index'] == i,
          orElse: () => {
            'is_correct': false,
            'points_earned': 0,
            'feedback': 'No response provided',
          },
        );

        detailedAnswers.add({
          'question_num': i + 1,
          'question_text': q['question_text'],
          'user_answer': answers[questionId] ?? '',
          'is_correct': result['is_correct'] ?? false,
          'points_earned': result['points_earned'] ?? 0,
          'points_available': q['points'] ?? 5,
          'feedback': result['feedback'] ?? '',
        });
      }

      return {
        'detailed_answers': detailedAnswers,
        'feedback_text': overallFeedback,
        'score': totalEarned is int
            ? totalEarned
            : (totalEarned as num).toInt(),
        'total_points': totalPossible is int
            ? totalPossible
            : (totalPossible as num).toInt(),
        'test': {
          'title': questions.isNotEmpty
              ? questions[0]['question_text']
              : 'Speaking Test',
          'text': 'Local speaking evaluation',
          'test_type': 'speaking',
          'module_type': 'speaking',
          'difficulty': 0,
        },
      };
    } catch (e) {
      throw Exception('Failed to parse AI response: $e\nResponse: $aiResponse');
    }
  }
}
