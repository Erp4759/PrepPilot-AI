class FeedbackData {
  final String feedbackId;
  final String resultId;
  final String feedbackText;
  final DateTime createdAt;

  // Result data
  final String testId;
  final String userId;
  final int score;
  final int totalPoints;

  // Test data
  final String title;
  final String text;
  final String testType;
  final String moduleType;
  final int difficulty;

  // Detailed answers
  final List<DetailedAnswer> detailedAnswers;
  // Safe parsing helpers (shared within this class)
  static int _parseIntSafe(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
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
      final asInt = int.tryParse(v);
      if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.now();
  }

  const FeedbackData({
    required this.feedbackId,
    required this.resultId,
    required this.feedbackText,
    required this.createdAt,
    required this.testId,
    required this.userId,
    required this.score,
    required this.totalPoints,
    required this.title,
    required this.text,
    required this.testType,
    required this.moduleType,
    required this.difficulty,
    required this.detailedAnswers,
  });

  factory FeedbackData.fromCompleteResult(Map<String, dynamic> data) {
    final rawList = data['detailed_answers'];
    final detailedAnswersList = (rawList is List)
        ? rawList.map((answer) => DetailedAnswer.fromMap(answer)).toList()
        : <DetailedAnswer>[];

    return FeedbackData(
      feedbackId: _toStringSafe(data['feedback_id']),
      resultId: _toStringSafe(data['result_id']),
      feedbackText: _toStringSafe(data['feedback_text']),
      createdAt: _parseDateSafe(data['feedback_created_at']),
      testId: _toStringSafe(data['test_id']),
      userId: _toStringSafe(data['user_id']),
      score: _parseIntSafe(data['score']),
      totalPoints: _parseIntSafe(data['total_points']),
      title: _toStringSafe(data['test']?['title']),
      text: _toStringSafe(data['test']?['text']),
      testType: _toStringSafe(data['test']?['test_type']),
      moduleType: _toStringSafe(data['test']?['module_type']),
      difficulty: _parseIntSafe(data['test']?['difficulty']),
      detailedAnswers: detailedAnswersList,
    );
  }

  int get percentage =>
      totalPoints > 0 ? ((score / totalPoints) * 100).round() : 0;

  int get correctCount => detailedAnswers.where((a) => a.isCorrect).length;

  int get totalQuestions => detailedAnswers.length;
}

class DetailedAnswer {
  final int questionNum;
  final String questionText;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final int pointsEarned;
  final int pointsAvailable;

  const DetailedAnswer({
    required this.questionNum,
    required this.questionText,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    required this.pointsAvailable,
  });

  factory DetailedAnswer.fromMap(Map<String, dynamic> map) {
    return DetailedAnswer(
      questionNum: _parseIntSafe(map['question_num']),
      questionText: _toStringSafe(map['question_text']),
      correctAnswer: _toStringSafe(map['correct_answer']),
      userAnswer: _toStringSafe(map['user_answer']),
      isCorrect: map['is_correct'] == true,
      pointsEarned: _parseIntSafe(map['points_earned']),
      pointsAvailable: _parseIntSafe(map['points_available']),
    );
  }

  static int _parseIntSafe(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
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
      final asInt = int.tryParse(v);
      if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.now();
  }
}
