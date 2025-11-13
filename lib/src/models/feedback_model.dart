class Feedback {
  final String feedbackId;
  final String resultId;
  final String? feedbackText;
  final DateTime createdAt;

  Feedback({
    required this.feedbackId,
    required this.resultId,
    this.feedbackText,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedback_id'],
      resultId: json['result_id'],
      feedbackText: json['feedback_text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}