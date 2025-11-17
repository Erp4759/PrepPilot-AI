import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatGPTService {
  ChatGPTService._internal();
  static final ChatGPTService _instance = ChatGPTService._internal();
  factory ChatGPTService() => _instance;

  final _baseUrl = "https://api.openai.com/v1/chat/completions";
  String? _apiKey;

  void initialize() {
    _apiKey = dotenv.env['CHATGPT_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('CHATGPT_API_KEY not found in .env');
    }
  }

  Future<String> sendPrompt(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4-turbo",
        "messages": [
          {"role": "user", "content": prompt},
        ],
        "temperature": 0.7,
        "max_tokens": 500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch response: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }
}
