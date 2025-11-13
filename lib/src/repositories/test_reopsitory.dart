import '../services/supabase.dart'; // 작성한 supabase 서비스 파일 import
import '../models/test_model.dart';

class TestRepository {
  
  /// Test ID를 기반으로 테스트 정보와 문제들을 함께 가져오는 함수
  Future<Test?> fetchTestWithQuestions(String testId) async {
    try {
      // supabase 변수는 services/supabase.dart에서 가져옴
      final response = await supabase
          .from('tests')
          .select('*, questions(*)') // questions 테이블을 조인해서 가져옴
          .eq('test_id', testId)
          .single(); // ID 검색이므로 단일 결과 반환

      return Test.fromJson(response);
    } catch (e) {
      print('Error fetching test: $e');
      return null;
    }
  }

  /// 예시: 특정 모듈 타입의 모든 테스트 목록 가져오기
  Future<List<Test>> fetchTestsByModule(String moduleType) async {
    try {
      final response = await supabase
          .from('tests')
          .select('*, questions(*)')
          .eq('module_type', moduleType);

      final List<dynamic> data = response;
      return data.map((json) => Test.fromJson(json)).toList();
    } catch (e) {
      print('Error list fetch: $e');
      return [];
    }
  }
}