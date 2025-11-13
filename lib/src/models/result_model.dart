// 사용자가 제출한 개별 답안 모델
class UserAnswer {
  final String answerId;
  final String questionId;
  final String? userAnswer;
  final bool? isCorrect;
  final int? pointsEarned;

  UserAnswer({
    required this.answerId,
    required this.questionId,
    this.userAnswer,
    this.isCorrect,
    this.pointsEarned,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      answerId: json['answer_id'],
      questionId: json['question_id'],
      userAnswer: json['user_answer'],
      isCorrect: json['is_correct'],
      pointsEarned: json['points_earned'],
    );
  }
}

// 시험 결과 전체 모델
class Result {
  final String resultId;
  final String testId;
  final String userId;
  final int? score;
  final int? totalPoints;
  final DateTime createdAt;

  // 관계형 쿼리로 함께 가져올 데이터
  final List<UserAnswer> userAnswers; // `user_answers` 테이블
  final String? testTitle; // `tests` 테이블에서 가져온 제목
  final String? username; // `users` 테이블에서 가져온 이름

  Result({
    required this.resultId,
    required this.testId,
    required this.userId,
    this.score,
    this.totalPoints,
    required this.createdAt,
    this.userAnswers = const [],
    this.testTitle,
    this.username,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      resultId: json['result_id'],
      testId: json['test_id'],
      userId: json['user_id'],
      score: json['score'],
      totalPoints: json['total_points'],
      createdAt: DateTime.parse(json['created_at']),

      // 중첩된 user_answers 파싱
      userAnswers: (json['user_answers'] as List<dynamic>?)
              ?.map((e) => UserAnswer.fromJson(e))
              .toList() ??
          [],
      
      // 중첩된 tests 테이블에서 title 파싱 (있을 경우)
      testTitle: json['tests']?['title'],
      
      // 중첩된 users 테이블에서 username 파싱 (있을 경우)
      username: json['users']?['username'],
    );
  }
}