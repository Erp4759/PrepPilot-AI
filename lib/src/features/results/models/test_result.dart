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
      resultId: map['result_id'] as String,
      testId: map['test_id'] as String,
      userId: map['user_id'] as String,
      title: testData['title'] as String,
      score: map['score'] as int,
      totalPoints: map['total_points'] as int,
      testType: testData['test_type'] as String,
      moduleType: testData['module_type'] as String,
      difficulty: testData['difficulty'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
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
