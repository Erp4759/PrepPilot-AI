import '../services/supabase.dart'; // 중앙 Supabase 클라이언트
import '../models/result_model.dart'; // 방금 만든 모델

class ResultRepository {

  /// 특정 사용자의 모든 결과 목록을 가져옵니다. (간단한 정보만)
  Future<List<Result>> fetchResultsForUser(String userId) async {
    try {
      // 목록에서는 무거운 user_answers는 빼고, test 제목만 가져옵니다.
      final response = await supabase
          .from('results')
          .select('*, tests(title)') // tests 테이블의 title을 join
          .eq('user_id', userId);
      
      final List<dynamic> data = response;
      return data.map((json) => Result.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user results: $e');
      return [];
    }
  }

  /// 특정 결과(result_id)의 상세 정보를 가져옵니다. (답안 포함)
  Future<Result?> fetchResultDetails(String resultId) async {
    try {
      // 여기서는 해당 결과의 모든 user_answers와 사용자 정보까지 가져옵니다.
      final response = await supabase
          .from('results')
          .select('*, user_answers(*), users(username)')
          .eq('result_id', resultId)
          .single(); // ID로 조회하므로 single() 사용

      return Result.fromJson(response);
    } catch (e) {
      print('Error fetching result details: $e');
      return null;
    }
  }

  // 여기에 점수, 답안 등을 저장하는 createResult 함수를 추가할 수 있습니다.
}