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
        'model': 'gpt-4-turbo',
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
}
