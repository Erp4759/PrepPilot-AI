class Question {
  final String questionId;
  final int questionNum;
  final String questionText;
  final String? questionType;
  final int points;

  Question({
    required this.questionId,
    required this.questionNum,
    required this.questionText,
    this.questionType,
    required this.points,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id'],
      questionNum: json['question_num'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      points: json['points'] ?? 1,
    );
  }
}

class Test {
  final String testId;
  final String? title;
  final String? text;
  final int? timeLimit;
  final List<Question> questions;

  Test({
    required this.testId,
    this.title,
    this.text,
    this.timeLimit,
    required this.questions,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      testId: json['test_id'],
      title: json['title'],
      text: json['text'],
      timeLimit: json['time_limit'],
      // 관계형 데이터 파싱 (questions 테이블 데이터가 리스트로 들어옴)
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e))
              .toList() ?? [],
    );
  }
}