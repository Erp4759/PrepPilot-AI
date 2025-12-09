import '../models/feedback_data.dart';

class MockFeedback {
  static final Map<String, FeedbackData> feedbackById = {
    'f1': FeedbackData(
      feedbackId: 'f1',
      resultId: 'r1',
      feedbackText:
          'Good summary but missed some key consequences; include working conditions and environmental impacts.',
      createdAt: DateTime.parse('2025-10-20T12:30:00Z'),
      testId: 't1',
      userId: 'u1',
      score: 6,
      totalPoints: 9,
      title: 'Reading Comprehension',
      text: 'Passage about Industrial Revolution and its social impacts',
      testType: 'reading',
      moduleType: 'inference',
      difficulty: 3,
      detailedAnswers: [
        DetailedAnswer(
          questionNum: 1,
          questionText: 'Summarize the passage',
          correctAnswer:
              'The passage explains industrialization, urbanization, and resulting social and environmental consequences.',
          userAnswer:
              'People moved to cities for factory jobs; new machines and better transport emerged.',
          isCorrect: true,
          pointsEarned: 6,
          pointsAvailable: 9,
        ),
      ],
    ),
    'f2': FeedbackData(
      feedbackId: 'f2',
      resultId: 'r2',
      feedbackText:
          'Too brief; take notes during listening and capture specific impacts mentioned.',
      createdAt: DateTime.parse('2025-10-19T12:30:00Z'),
      testId: 't2',
      userId: 'u1',
      score: 4,
      totalPoints: 9,
      title: 'Listening Practice',
      text: 'Conversation about climate change impacts',
      testType: 'listening',
      moduleType: 'gist_listening',
      difficulty: 4,
      detailedAnswers: [
        DetailedAnswer(
          questionNum: 1,
          questionText: 'List three main effects discussed',
          correctAnswer:
              'Rising ocean temperatures, disrupted weather patterns, ecosystem instability',
          userAnswer: 'Weather changes',
          isCorrect: false,
          pointsEarned: 4,
          pointsAvailable: 9,
        ),
      ],
    ),
  };
}
