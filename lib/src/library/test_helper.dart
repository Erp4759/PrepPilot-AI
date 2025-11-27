import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/supabase.dart';

class TestHelper {
  /// Generate an IELTS test → save to Supabase → return test_id
  static Future<String> createAndStoreTest({
    required String difficulty,
    required String testType,
    required String moduleType,
  }) async {
    // 1. Fetch prompt from Supabase
    final promptData = await _getPromptFromSupabase(
      testType: testType,
      moduleType: moduleType,
    );

    // 2. Inject variables into the prompt
    final finalPrompt = _injectVariablesIntoPrompt(
      promptTemplate: promptData['prompt_text'],
      difficulty: difficulty,
      testType: testType,
      moduleType: moduleType,
    );

    // 3. Generate test JSON via ChatGPT
    final testJson = await _generateTestFromChatGPT(finalPrompt);

    // 4. Store test in Supabase
    final testId = await _storeTestInSupabase(
      promptId: promptData['prompt_id'],
      testJson: testJson,
      difficulty: difficulty,
      testType: testType,
      moduleType: moduleType,
    );

    // 5. Store questions in Supabase
    await _storeQuestionsInSupabase(testId: testId, testJson: testJson);

    return testId;
  }

  // -------------------------------------------------------------
  // FETCH PROMPT FROM Supabase
  // -------------------------------------------------------------
  static Future<Map<String, dynamic>> _getPromptFromSupabase({
    required String testType,
    required String moduleType,
  }) async {
    final response = await supabase
        .from("prompts")
        .select("prompt_id, prompt_text")
        .eq("test_type", testType)
        .eq("module_type", moduleType)
        .maybeSingle();

    if (response == null ||
        !response.containsKey('prompt_id') ||
        !response.containsKey('prompt_text')) {
      throw Exception(
        'No prompt found for test_type=$testType and module_type=$moduleType',
      );
    }

    return {
      "prompt_id": response['prompt_id'],
      "prompt_text": response['prompt_text'],
    };
  }

  // -------------------------------------------------------------
  // INJECT VARIABLES INTO PROMPT
  // -------------------------------------------------------------
  static String _injectVariablesIntoPrompt({
    required String promptTemplate,
    required String difficulty,
    required String testType,
    required String moduleType,
  }) {
    return promptTemplate
        .replaceAll('{difficulty}', difficulty)
        .replaceAll('{testType}', testType)
        .replaceAll('{moduleType}', moduleType);
  }

  // -------------------------------------------------------------
  // CHATGPT REQUEST
  // -------------------------------------------------------------
  static Future<Map<String, dynamic>> _generateTestFromChatGPT(
    String prompt,
  ) async {
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
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to generate test: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final content = data["choices"][0]["message"]["content"];
    return jsonDecode(content);
  }

  // -------------------------------------------------------------
  // STORE TEST (tests TABLE)
  // -------------------------------------------------------------
  static Future<String> _storeTestInSupabase({
    required Map<String, dynamic> testJson,
    required String promptId,
    required String difficulty,
    required String testType,
    required String moduleType,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final testData = {
      "prompt_id": promptId,
      "user_id": user.id,
      "test_type": testType,
      "module_type": moduleType,
      "title": testJson["test"]["title"],
      "text": testJson["test"]["test_description"],
      "difficulty": _parseDifficulty(difficulty),
      "time_limit": null,
    };

    final response = await supabase
        .from("tests")
        .insert(testData)
        .select("test_id")
        .single();

    return response["test_id"];
  }

  // -------------------------------------------------------------
  // STORE QUESTIONS (questions TABLE)
  // -------------------------------------------------------------
  static Future<void> _storeQuestionsInSupabase({
    required String testId,
    required Map<String, dynamic> testJson,
  }) async {
    final questions = testJson["questions"] as Map<String, dynamic>;

    final questionInserts = questions.entries.map((entry) {
      final number = int.parse(entry.key);
      final q = entry.value;

      return {
        "test_id": testId,
        "question_num": number,
        "question_text": q["question_text"],
        "correct_answer": q["correct_answer"],
        "question_type": "text",
        "points": q["points"],
      };
    }).toList();

    await supabase.from("questions").insert(questionInserts);
  }

  // -------------------------------------------------------------
  // PARSE DIFFICULTY
  // -------------------------------------------------------------
  static int _parseDifficulty(String difficulty) {
    return int.tryParse(difficulty.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  /// Saves multiple user answers at once
  ///
  /// [answers] - Map of question_id to user_answer
  ///
  /// Returns the list of answer IDs that were created
  static Future<List<String>> saveUserAnswers({
    required Map<String, String> answers,
  }) async {
    if (answers.isEmpty) {
      throw Exception('Answers map cannot be empty');
    }

    // Prepare batch insert data
    final answerInserts = answers.entries.map((entry) {
      return {'question_id': entry.key, 'user_answer': entry.value};
    }).toList();

    // Insert all answers at once
    final response = await supabase
        .from('user_answers')
        .insert(answerInserts)
        .select('answer_id');

    // Extract and return the created answer IDs
    return (response as List).map((row) => row['answer_id'] as String).toList();
  }

  /// Fetch a test by test_id with all its questions
  /// Returns a Map containing test data and questions list
  static Future<Map<String, dynamic>> fetchTestById({
    required String testId,
  }) async {
    // Fetch test with its questions in a single query
    final response = await supabase
        .from('tests')
        .select('''
          test_id,
          prompt_id,
          user_id,
          test_type,
          module_type,
          title,
          text,
          time_limit,
          difficulty,
          status,
          created_at,
          updated_at,
          questions (
            question_id,
            question_num,
            question_text,
            question_type,
            correct_answer,
            points
          )
        ''')
        .eq('test_id', testId)
        .single();

    return response;
  }

  /// Fetch only test metadata (without questions)
  static Future<Map<String, dynamic>> fetchTestMetadata({
    required String testId,
  }) async {
    final response = await supabase
        .from('tests')
        .select('''
          test_id,
          prompt_id,
          user_id,
          test_type,
          module_type,
          title,
          text,
          time_limit,
          difficulty,
          status,
          created_at,
          updated_at
        ''')
        .eq('test_id', testId)
        .single();

    return response;
  }

  /// Fetch only questions for a specific test
  static Future<List<Map<String, dynamic>>> fetchTestQuestions({
    required String testId,
  }) async {
    final response = await supabase
        .from('questions')
        .select('''
          question_id,
          question_num,
          question_text,
          question_type,
          correct_answer,
          points
        ''')
        .eq('test_id', testId)
        .order('question_num');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Mark all user answers for a given test_id
  static Future<void> markUserAnswers({required String testId}) async {
    // 1. Pull test + question data
    final test = await supabase
        .from('tests')
        .select('title, text')
        .eq('test_id', testId)
        .maybeSingle();

    if (test == null) {
      throw Exception('Test not found for test_id=$testId');
    }

    final questions = await supabase
        .from('questions')
        .select('question_id, question_text, points')
        .eq('test_id', testId);

    if (questions.isEmpty) {
      throw Exception('No questions found for test_id=$testId');
    }

    // 2. Pull user_answers for this test
    final questionIds = questions.map((q) => q['question_id']).toList();

    final userAnswersData = await supabase
        .from('user_answers')
        .select('answer_id, question_id, user_answer')
        .inFilter('question_id', questionIds);

    if (userAnswersData.isEmpty) {
      throw Exception('No user answers found for test_id=$testId');
    }

    // 3. Build the marking prompt
    final prompt = _buildMarkingPrompt(
      title: test['title'],
      text: test['text'],
      questions: questions,
      userAnswers: userAnswersData,
    );

    // 4. Call ChatGPT to mark answers
    final markingResults = await _markAnswersWithChatGPT(prompt);

    // 5. Update user_answers with is_correct & points_earned
    for (final result in markingResults) {
      await supabase
          .from('user_answers')
          .update({
            'is_correct': result['is_correct'],
            'points_earned': result['points_earned'],
          })
          .eq('question_id', result['question_id']);
    }
  }

  // -------------------------------------------------------------
  // Build ChatGPT marking prompt
  // -------------------------------------------------------------
  static String _buildMarkingPrompt({
    required String title,
    required String text,
    required List<dynamic> questions,
    required List<dynamic> userAnswers,
  }) {
    // Merge user answers with questions
    final data = questions.map((q) {
      final ua = userAnswers.firstWhere(
        (u) => u['question_id'] == q['question_id'],
        orElse: () => {'user_answer': ''},
      );
      return {
        'question_id': q['question_id'],
        'question_text': q['question_text'],
        'points': q['points'],
        'user_answer': ua['user_answer'],
      };
    }).toList();

    return """
  You are an IELTS examiner. Mark the user's answers.

  Context:
  Title: $title
  Text: $text
  Questions and user answers: ${jsonEncode(data)}

  Rules:
  - For each question, decide if the user_answer is correct.
  - Assign points earned (0 or full points).
  - Return JSON ONLY in this format:

  [
    {
      "question_id": "question_id",
      "user_answer": "user_answer",
      "is_correct": true/false,
      "points_earned": 0
    }
  ]
""";
  }

  // -------------------------------------------------------------
  // Call ChatGPT to mark the answers
  // -------------------------------------------------------------
  static Future<List<dynamic>> _markAnswersWithChatGPT(String prompt) async {
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
        'model': 'gpt-4-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark answers: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    return jsonDecode(content) as List<dynamic>;
  }

  /// Generate overall feedback for a test and store it in the feedback table
  ///
  /// [testId] - The test ID to generate feedback for
  /// [resultId] - The result ID to associate the feedback with
  ///
  /// Returns the feedback_id of the created feedback
  static Future<Map<String, dynamic>> generateAndStoreFeedback({
    required String testId,
    required String resultId,
  }) async {
    // 1. Pull test data
    final test = await supabase
        .from('tests')
        .select('title, text, test_type, module_type, difficulty')
        .eq('test_id', testId)
        .maybeSingle();

    if (test == null) {
      throw Exception('Test not found for test_id=$testId');
    }

    // 2. Pull questions with correct answers
    final questions = await supabase
        .from('questions')
        .select(
          'question_id, question_num, question_text, correct_answer, points',
        )
        .eq('test_id', testId)
        .order('question_num');

    if (questions.isEmpty) {
      throw Exception('No questions found for test_id=$testId');
    }

    // 3. Pull user answers with marking results
    final questionIds = questions.map((q) => q['question_id']).toList();

    final userAnswersData = await supabase
        .from('user_answers')
        .select('question_id, user_answer, is_correct, points_earned')
        .inFilter('question_id', questionIds);

    if (userAnswersData.isEmpty) {
      throw Exception('No user answers found for test_id=$testId');
    }

    // 4. Calculate overall statistics
    final totalQuestions = questions.length;
    final correctAnswers = userAnswersData
        .where((a) => a['is_correct'] == true)
        .length;
    final totalPointsAvailable = questions.fold<int>(
      0,
      (sum, q) => sum + (q['points'] as int? ?? 0),
    );
    final totalPointsEarned = userAnswersData.fold<int>(
      0,
      (sum, a) => sum + (a['points_earned'] as int? ?? 0),
    );
    final percentage = totalPointsAvailable > 0
        ? (totalPointsEarned / totalPointsAvailable * 100).round()
        : 0;

    // 5. Merge questions with user answers
    final detailedResults = questions.map((q) {
      final ua = userAnswersData.firstWhere(
        (u) => u['question_id'] == q['question_id'],
        orElse: () => {
          'user_answer': '',
          'is_correct': false,
          'points_earned': 0,
        },
      );
      return {
        'question_num': q['question_num'],
        'question_text': q['question_text'],
        'correct_answer': q['correct_answer'],
        'user_answer': ua['user_answer'],
        'is_correct': ua['is_correct'],
        'points_earned': ua['points_earned'],
        'points_available': q['points'],
      };
    }).toList();

    // 6. Build feedback prompt
    final prompt = _buildFeedbackPrompt(
      test: test,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      totalPointsEarned: totalPointsEarned,
      totalPointsAvailable: totalPointsAvailable,
      percentage: percentage,
      detailedResults: detailedResults,
    );

    // 7. Generate feedback via ChatGPT
    final feedbackText = await _generateFeedbackWithChatGPT(prompt);

    // 8. Store feedback in database
    final response = await supabase
        .from('feedback')
        .insert({'result_id': resultId, 'feedback_text': feedbackText})
        .select('feedback_id')
        .single();

    // 9. Return feedback_id and statistics
    return {
      'feedback_id': response['feedback_id'],
      'total_points_earned': totalPointsEarned,
      'total_points_available': totalPointsAvailable,
      'percentage': percentage,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
    };
  }

  // -------------------------------------------------------------
  // Build feedback prompt
  // -------------------------------------------------------------
  static String _buildFeedbackPrompt({
    required Map<String, dynamic> test,
    required int totalQuestions,
    required int correctAnswers,
    required int totalPointsEarned,
    required int totalPointsAvailable,
    required int percentage,
    required List<Map<String, dynamic>> detailedResults,
  }) {
    return """
  You are an experienced IELTS examiner providing comprehensive feedback to a student.

  Test Information:
  - Test Type: ${test['test_type']}
  - Module: ${test['module_type']}
  - Title: ${test['title']}
  - Difficulty Level: ${test['difficulty']}

  Performance Summary:
  - Questions Answered Correctly: $correctAnswers / $totalQuestions
  - Total Points Earned: $totalPointsEarned / $totalPointsAvailable
  - Overall Score: $percentage%

  Detailed Results:
  ${jsonEncode(detailedResults)}

  Instructions:
  1. Provide an overall assessment of the student's performance
  2. Highlight strengths (what they did well)
  3. Identify areas for improvement (specific weaknesses based on incorrect answers)
  4. Give actionable advice and study recommendations
  5. Provide encouragement and next steps

  Keep the feedback constructive, specific, and encouraging. Focus on helping the student improve.
  Write in a friendly, professional tone suitable for IELTS preparation.

  Return ONLY the feedback text (no JSON, no extra formatting).
""";
  }

  // -------------------------------------------------------------
  // Generate feedback via ChatGPT
  // -------------------------------------------------------------
  static Future<String> _generateFeedbackWithChatGPT(String prompt) async {
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
        'model': 'gpt-4-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate feedback: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  /// Submit test answers, mark them, and generate feedback in one flow
  ///
  /// [testId] - The test ID being submitted
  /// [answers] - Map of question_id to user_answer
  ///
  /// Returns a Map containing answer_ids, result_id, and feedback_id
  static Future<Map<String, dynamic>> submitAndEvaluateTest({
    required String testId,
    required Map<String, String> answers,
  }) async {
    try {
      // 1. Save user answers
      final answerIds = await saveUserAnswers(answers: answers);

      // 2. Create result record
      final resultId = await _createResult(testId: testId);

      // 3. Update user answers with result_id
      await _updateAnswersWithResultId(
        answerIds: answerIds,
        resultId: resultId,
      );

      // 4. Mark answers (this updates is_correct and points_earned)
      await markUserAnswers(testId: testId);

      // 5. Generate feedback based on marked answers
      final feedbackData = await generateAndStoreFeedback(
        testId: testId,
        resultId: resultId,
      );

      // 6. Update results with score and total points
      await _updateResults(
        resultId: resultId,
        score: feedbackData['total_points_earned'],
        totalPoints: feedbackData['total_points_available'],
      );

      return {
        'answer_ids': answerIds,
        'result_id': resultId,
        'feedback_id': feedbackData['feedback_id'],
        'success': true,
      };
    } catch (e) {
      throw Exception('Failed to submit and evaluate test: $e');
    }
  }

  // -------------------------------------------------------------
  // Create a result record
  // -------------------------------------------------------------
  static Future<String> _createResult({required String testId}) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await supabase
        .from('results')
        .insert({
          'test_id': testId,
          'user_id': user.id,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .select('result_id')
        .single();

    return response['result_id'];
  }

  // -------------------------------------------------------------
  // Update a result record with score and total points
  // -------------------------------------------------------------
  static Future<void> _updateResults({
    required String resultId,
    required int score,
    required int totalPoints,
  }) async {
    await supabase
        .from('results')
        .update({'score': score, 'total_points': totalPoints})
        .eq('result_id', resultId);
  }

  // -------------------------------------------------------------
  // Update user answers with result_id
  // -------------------------------------------------------------
  static Future<void> _updateAnswersWithResultId({
    required List<String> answerIds,
    required String resultId,
  }) async {
    await supabase
        .from('user_answers')
        .update({'result_id': resultId})
        .inFilter('answer_id', answerIds);
  }
}
