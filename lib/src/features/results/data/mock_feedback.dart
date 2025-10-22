import '../models/feedback_data.dart';

class MockFeedback {
  static final Map<String, FeedbackData> feedbackById = {
    '1': FeedbackData(
      testType: 'reading',
      question:
          'The Industrial Revolution brought significant changes to society. Manufacturing shifted from home-based production to factories, leading to urbanization as workers moved to cities. This period saw innovations in textile manufacturing, steam power, and transportation. However, it also created challenging working conditions and environmental concerns that would shape labor movements and environmental policies for generations.\n\nSummarize the main points in 2-3 sentences.',
      userAnswer:
          'The Industrial Revolution caused people to move to cities for factory jobs. New machines were invented and transportation improved.',
      aiAnalysis:
          'Your answer correctly identifies urbanization and technological innovations as key changes. However, you missed critical aspects mentioned in the passage: the challenging working conditions and environmental concerns that led to labor movements and policy changes. For a higher band score, ensure you capture all main points from the passage, including consequences and long-term impacts.',
      score: 6.0,
    ),
    '2': FeedbackData(
      testType: 'listening',
      question:
          'Listen to the conversation about climate change. What three main effects were discussed?',
      userAnswer: 'Weather changes',
      aiAnalysis:
          'Your answer is too brief and captures only one general effect. The audio discussed three specific impacts: rising ocean temperatures, disrupted weather patterns, and ecosystem instability. To improve, take notes during listening and aim to capture specific details rather than general statements.',
      score: 4.5,
    ),
  };
}
