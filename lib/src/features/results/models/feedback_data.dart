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
    final detailedAnswersList = (data['detailed_answers'] as List)
        .map((answer) => DetailedAnswer.fromMap(answer))
        .toList();

    return FeedbackData(
      feedbackId: data['feedback_id'] as String,
      resultId: data['result_id'] as String,
      feedbackText: data['feedback_text'] as String,
      createdAt: DateTime.parse(data['feedback_created_at'] as String),
      testId: data['test_id'] as String,
      userId: data['user_id'] as String,
      score: data['score'] as int,
      totalPoints: data['total_points'] as int,
      title: data['test']['title'] as String,
      text: data['test']['text'] as String,
      testType: data['test']['test_type'] as String,
      moduleType: data['test']['module_type'] as String,
      difficulty: data['test']['difficulty'] as int,
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
      questionNum: map['question_num'] as int,
      questionText: map['question_text'] as String,
      correctAnswer: map['correct_answer'] as String,
      userAnswer: map['user_answer'] as String,
      isCorrect: map['is_correct'] as bool,
      pointsEarned: map['points_earned'] as int,
      pointsAvailable: map['points_available'] as int,
    );
  }
}
