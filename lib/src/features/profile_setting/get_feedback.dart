import 'package:flutter/foundation.dart';
import '../../services/supabase.dart';

/// 요약 (한국어):
/// 사용자의 학습 레벨(1~5)과 painpoint(취약점) 추출에 필요한 데이터들을
/// Supabase에서 조회하여 간단한 평가/추론을 수행합니다.
///
/// Summary (English):
/// Fetches the data required to compute a user's learning level (1-5) and
/// pain points from Supabase and performs a simple heuristic analysis.

class FeedbackSummary {
  // Per-module learning levels (values 1..5)
  final Map<String, int> learningLevels;

  // Total number of tests considered
  final int totalTests;

  FeedbackSummary({
    required this.learningLevels,
    required this.totalTests,
  });
}

/// Calculation formula:
/// level = round( sum_over_tests(difficulty * score) * (5 / sum_over_tests(total_points)) )
/// The result is clamped between 1 and 5.
Future<FeedbackSummary> computeLearningLevelAndPainPoints(String userId) async {
  try {
    // 1) Fetch user's results and test metadata.
    final resultsResp = await supabase
        .from('results')
        .select('result_id, score, total_points, tests(test_id, test_type, module_type, difficulty)')
        .eq('user_id', userId);

    final results = (resultsResp as List).cast<Map<String, dynamic>>();

    if (results.isEmpty) {
      // return defaults for four main modules
      return FeedbackSummary(
        learningLevels: {'reading': 1, 'listening': 1, 'writing': 1, 'speaking': 1},
        totalTests: 0,
      );
    }

    // Aggregation for difficulty calculation only
    // 1) normalize difficulty by maxDifficulty across user's tests
    // 2) normalizedScore = score / totalPoints
    // 3) contrib = weight * normalizedScore, where weight = difficulty / maxDifficulty
    // 4) rawLevel per module = average(contribs)
    // 5) level = 1 + rawLevel * 4  (then rounded and clamped to 1..5)

    final Map<String, List<double>> moduleContribs = {}; // module -> list of contrib values

    // find maxDifficulty among user's tests (avoid division by zero)
    double maxDifficulty = 0.0;
    for (final r in results) {
      final tests = r['tests'] as Map<String, dynamic>?;
      final int difficulty = (tests != null && tests['difficulty'] != null) ? (tests['difficulty'] as int) : 0;
      if (difficulty > maxDifficulty) maxDifficulty = difficulty.toDouble();
    }
    if (maxDifficulty <= 0) maxDifficulty = 1.0;

    // compute contrib per test and collect per-module
    for (final r in results) {
      final int score = (r['score'] as int?) ?? 0;
      final int totalPoints = (r['total_points'] as int?) ?? 0;
      final tests = r['tests'] as Map<String, dynamic>?;
      final int difficulty = (tests != null && tests['difficulty'] != null) ? (tests['difficulty'] as int) : 0;
      final String moduleType = (tests != null && tests['module_type'] != null) ? (tests['module_type'] as String) : 'unknown';

      final double weight = difficulty / maxDifficulty;
      final double normalizedScore = totalPoints > 0 ? (score / totalPoints) : 0.0;
      final double contrib = weight * normalizedScore; // 0..1

      moduleContribs.putIfAbsent(moduleType, () => []).add(contrib);
    }

    // Compute per-module learning levels using the user's formula
    final Map<String, int> learningLevels = {};
    moduleContribs.forEach((module, contribList) {
      final double rawLevel = contribList.isNotEmpty ? (contribList.reduce((a, b) => a + b) / contribList.length) : 0.0;
      final double levelFloat = 1.0 + rawLevel * 4.0; // maps 0..1 -> 1..5
      int level = levelFloat.round();
      if (level < 1) level = 1;
      if (level > 5) level = 5;
      learningLevels[module] = level;
    });

    // Update user's difficulty fields in `users` table based on computed levels.
    try {
      final Map<String, int> columnMap = {
        'reading': learningLevels['reading'] ?? 0,
        'listening': learningLevels['listening'] ?? 0,
        'speaking': learningLevels['speaking'] ?? 0,
        // prefer 'scanning' if present; if only 'writing' exists map it to scanning_difficulty
        'scanning': learningLevels['scanning'] ?? learningLevels['writing'] ?? 0,
      };

      // build update payload only for non-zero values
      final Map<String, Object?> updateData = {};
      if ((columnMap['reading'] ?? 0) > 0) updateData['reading_difficulty'] = columnMap['reading'];
      if ((columnMap['listening'] ?? 0) > 0) updateData['listening_difficulty'] = columnMap['listening'];
      if ((columnMap['speaking'] ?? 0) > 0) updateData['speaking_difficulty'] = columnMap['speaking'];
      if ((columnMap['scanning'] ?? 0) > 0) updateData['scanning_difficulty'] = columnMap['scanning'];

      if (updateData.isNotEmpty) {
        await supabase.from('users').update(updateData).eq('user_id', userId);
        if (kDebugMode) print('Updated user difficulties: $updateData for user $userId');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to update user difficulties: $e');
    }

    return FeedbackSummary(
      learningLevels: learningLevels,
      totalTests: results.length,
    );
  } catch (e) {
    if (kDebugMode) print('computeLearningLevelAndPainPoints error: $e');
    return FeedbackSummary(
      learningLevels: {'reading': 1, 'listening': 1, 'writing': 1, 'speaking': 1},
      totalTests: 0,
    );
  }
}

