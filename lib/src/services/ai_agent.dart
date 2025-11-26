import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum AiRole { system, user, assistant }

class AiMessage {
  AiMessage(this.role, this.content);
  final AiRole role;
  final String content;

  Map<String, String> toMap() => {
    'role': switch (role) {
      AiRole.system => 'system',
      AiRole.user => 'user',
      AiRole.assistant => 'assistant',
    },
    'content': content,
  };
}

class AiAgent {
  AiAgent({String? model}) : _model = model ?? 'gpt-4o-mini';

  static const _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model;

  String get _apiKey {
    final key = dotenv.env['CHATGPT_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('CHATGPT_API_KEY is missing.');
    }
    return key;
  }

  Future<String> respond({
    String? system,
    required String user,
    double temperature = 0.7,
    int? maxTokens,
    String? model,
  }) async {
    final messages = <AiMessage>[];
    if (system != null && system.isNotEmpty) {
      messages.add(AiMessage(AiRole.system, system));
    }
    messages.add(AiMessage(AiRole.user, user));
    return chat(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      model: model,
    );
  }

  Future<String> chat({
    required List<AiMessage> messages,
    double temperature = 0.7,
    int? maxTokens,
    String? model,
  }) async {
    final body = jsonEncode({
      'model': model ?? _model,
      'messages': messages.map((m) => m.toMap()).toList(),
      'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
    });

    final res = await http.post(
      Uri.parse(_chatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_apiKey}',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('OpenAI chat failed: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['choices'][0]['message']['content'] as String).trim();
  }

  Future<T> jsonOnly<T>({
    required String userPrompt,
    String? system,
    double temperature = 0.0,
    int? maxTokens,
    String? model,
    T Function(dynamic raw)? transform,
  }) async {
    final sys = [
      'You strictly return JSON only. No prose. No markdown. Use double quotes.',
      if (system != null && system.isNotEmpty) system,
    ].join('\n');

    final content = await respond(
      system: sys,
      user: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      model: model,
    );

    final jsonText = _extractJson(content);
    final decoded = jsonDecode(jsonText);
    if (transform != null) return transform(decoded);
    return decoded as T;
  }

  String _extractJson(String content) {
    final trimmed = content.trim();
    // Try to extract object or array
    final startIdx = trimmed.indexOf('{');
    final startArr = trimmed.indexOf('[');
    int start;
    int end;
    if (startIdx != -1 && (startArr == -1 || startIdx < startArr)) {
      start = startIdx;
      end = trimmed.lastIndexOf('}');
    } else {
      start = startArr;
      end = trimmed.lastIndexOf(']');
    }
    if (start != -1 && end != -1 && end >= start) {
      return trimmed.substring(start, end + 1);
    }
    // Fallback: assume already pure JSON
    return trimmed;
  }
}

// Simple global instance and helpers for convenience across the app.
final AiAgent aiAgent = AiAgent();

Future<String> aiChat({
  String? system,
  required String user,
  double temperature = 0.7,
  int? maxTokens,
  String? model,
}) => aiAgent.respond(
  system: system,
  user: user,
  temperature: temperature,
  maxTokens: maxTokens,
  model: model,
);

Future<T> aiJson<T>({
  required String userPrompt,
  String? system,
  double temperature = 0.0,
  int? maxTokens,
  String? model,
  T Function(dynamic raw)? transform,
}) => aiAgent.jsonOnly<T>(
  userPrompt: userPrompt,
  system: system,
  temperature: temperature,
  maxTokens: maxTokens,
  model: model,
  transform: transform,
);
