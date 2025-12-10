import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/supabase.dart';

class NoInternetException implements Exception {
  final String message;
  NoInternetException([
    this.message =
        'No internet connection. Please check your WiFi or mobile data.',
  ]);

  @override
  String toString() => message;
}

class TestHelper {
  // -------------------------------------------------------------
  // CONNECTIVITY CHECK
  // -------------------------------------------------------------
  static Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();

    if (result.contains(ConnectivityResult.none)) {
      throw NoInternetException();
    }

    try {
      final response = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (response.isEmpty || response[0].rawAddress.isEmpty) {
        throw NoInternetException(
          'Connected to network but no internet access.',
        );
      }
    } on SocketException {
      throw NoInternetException('Connected to network but no internet access.');
    } on TimeoutException {
      throw NoInternetException(
        'Connection timed out. Please check your internet.',
      );
    }
  }

  /// Mark all user answers for a given test_id
  static Future<void> markUserAnswers({required String testId}) async {
    await checkConnectivity();

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
    final userAnswersData = await supabase
        .from('user_answers')
        .select('answer_id, question_id, user_answer')
        .filter(
          'question_id',
          'in',
          '(${questions.map((q) => "'${q['question_id']}'").join(',')})',
        );

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
        'model': 'gpt-4o-mini',
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
}
