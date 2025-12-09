class TestResult {
  final String resultId;
  final String testId;
  final String userId;
  final String title;
  final int score;
  final int totalPoints;
  final String testType;
  final String moduleType;
  final int difficulty;
  final DateTime createdAt;

  const TestResult({
    required this.resultId,
    required this.testId,
    required this.userId,
    required this.title,
    required this.score,
    required this.totalPoints,
    required this.testType,
    required this.moduleType,
    required this.difficulty,
    required this.createdAt,
  });

  factory TestResult.fromMap(Map<String, dynamic> map) {
    final testData = map['tests'] as Map<String, dynamic>;
    return TestResult(
      resultId: _toStringSafe(map['result_id']),
      testId: _toStringSafe(map['test_id']),
      userId: _toStringSafe(map['user_id']),
      title: _toStringSafe(testData['title']),
      score: _parseIntSafe(map['score']),
      totalPoints: _parseIntSafe(map['total_points']),
      testType: _toStringSafe(testData['test_type']),
      moduleType: _toStringSafe(testData['module_type']),
      difficulty: _parseIntSafe(testData['difficulty']),
      createdAt: _parseDateSafe(map['created_at']),
    );
  }

  static int _parseIntSafe(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
      // try parsing as double then toInt
      final parsedDouble = double.tryParse(v);
      if (parsedDouble != null) return parsedDouble.toInt();
    }
    return fallback;
  }

  static String _toStringSafe(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static DateTime _parseDateSafe(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
      // try common numeric string
      final asInt = int.tryParse(v);
      if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.now();
  }

  String get scoreDisplay => '$score/$totalPoints';

  String get dateDisplay {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  int get percentage =>
      totalPoints > 0 ? ((score / totalPoints) * 100).round() : 0;
}
