class FeedbackData {
  final String testType; // 'reading', 'listening', 'writing', 'speaking'
  final String question;
  final String userAnswer;
  final String aiAnalysis;
  final double score;

  const FeedbackData({
    required this.testType,
    required this.question,
    required this.userAnswer,
    required this.aiAnalysis,
    required this.score,
  });
}
