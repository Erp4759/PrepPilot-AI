import '../services/supabase.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {

  /// 특정 결과(result_id)에 달린 모든 피드백을 가져옵니다.
  Future<List<Feedback>> fetchFeedbackForResult(String resultId) async {
    try {
      final response = await supabase
          .from('feedback')
          .select('*')
          .eq('result_id', resultId);
      
      final List<dynamic> data = response;
      return data.map((json) => Feedback.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching feedback: $e');
      return [];
    }
  }

  /// 새로운 피드백을 추가합니다.
  Future<void> addFeedback(String resultId, String feedbackText) async {
    try {
      await supabase.from('feedback').insert({
        'result_id': resultId,
        'feedback_text': feedbackText,
      });
    } catch (e) {
      print('Error adding feedback: $e');
      // 필요시 UI에 에러를 알릴 수 있도록 rethrow
    }
  }
}