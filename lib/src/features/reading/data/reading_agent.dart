import 'dart:convert';
import 'package:prep_pilot_ai/src/services/ai_agent.dart';

enum ReadingLength { short, medium, long }

enum ReadingDifficulty { a1, a2, b1, b2, c1, c2, adaptive }

class ReadingTest {
  ReadingTest({required this.passage, required this.questions});

  final String passage;
  final List<String> questions;
}

class ReadingCheckResult {
  ReadingCheckResult({
    required this.index,
    required this.isCorrect,
    required this.expected,
    required this.feedback,
    required this.score,
  });

  final int index;
  final bool isCorrect;
  final String expected;
  final String feedback;
  final int score; // 0 or 1
}

class ReadingAgent {
  ReadingAgent({AiAgent? ai}) : _ai = ai ?? AiAgent();
  final AiAgent _ai;

  Future<ReadingTest> generate({
    required ReadingLength length,
    required ReadingDifficulty difficulty,
  }) async {
    final wordRange = switch (length) {
      ReadingLength.short => '100-150',
      ReadingLength.medium => '250-350',
      ReadingLength.long => '450-650',
    };

    final qCount = switch (difficulty) {
      ReadingDifficulty.a1 || ReadingDifficulty.a2 => 3,
      ReadingDifficulty.b1 || ReadingDifficulty.b2 => 4,
      ReadingDifficulty.c1 || ReadingDifficulty.c2 => 5,
      ReadingDifficulty.adaptive => 4,
    };

    final difficultyLabel = difficulty.name.toUpperCase();

    final prompt =
        '''You are an English exam item writer specializing in the SCANNING skill.
Create a factual reading passage and short, specific questions that require scanning for details.

Constraints:
- CEFR level: $difficultyLabel
- Passage length: ${wordRange} words
- Question count: $qCount
- Questions must be answerable by locating specific details in the passage (names, dates, numbers, places, short facts). Avoid inference or opinion.

Return ONLY valid minified JSON using double quotes:
{"passage":"...","questions":["Q1","Q2",...]}
''';

    final parsed = await _ai.jsonOnly<Map<String, dynamic>>(
      system: 'You return JSON only. No prose. No markdown.',
      userPrompt: prompt,
      temperature: 0.5,
      maxTokens: 1200,
    );
    final passage = (parsed['passage'] as String).trim();
    final questions = (parsed['questions'] as List).cast<String>();
    return ReadingTest(passage: passage, questions: questions);
  }

  Future<List<ReadingCheckResult>> checkAnswers({
    required String passage,
    required List<String> questions,
    required List<String> answers,
  }) async {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < questions.length; i++) {
      items.add({
        'index': i,
        'question': questions[i],
        'user_answer': i < answers.length ? answers[i] : '',
      });
    }

    final prompt =
        '''You are an IELTS/TOEFL reading checker for the SCANNING skill.
Given the passage, questions, and user answers, grade each answer as correct or incorrect based on factual match. Prefer exact facts over paraphrase.

Return ONLY valid minified JSON array. For each item include:
{"index":0,"is_correct":true|false,"expected":"short fact","feedback":"one-sentence reason","score":0|1}

Passage:\n${_escapeForPrompt(passage)}\n\nData:${jsonEncode(items)}
''';

    final parsed = await _ai.jsonOnly<List<dynamic>>(
      system: 'You return JSON only. No prose. No markdown.',
      userPrompt: prompt,
      temperature: 0.0,
      maxTokens: 1200,
    );
    return parsed.map((e) {
      final m = e as Map<String, dynamic>;
      return ReadingCheckResult(
        index: (m['index'] as num).toInt(),
        isCorrect: m['is_correct'] as bool,
        expected: (m['expected'] as String?)?.trim() ?? '',
        feedback: (m['feedback'] as String?)?.trim() ?? '',
        score:
            (m['score'] as num?)?.toInt() ?? (m['is_correct'] == true ? 1 : 0),
      );
    }).toList();
  }

  String _escapeForPrompt(String s) {
    return s.replaceAll('\\', r'\\').replaceAll('"', r'\"');
  }
}
