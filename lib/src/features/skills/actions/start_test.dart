import '../models/test_properties.dart';
import '../../../library/test_helper.dart';

class StartTest {
  /// Starts a test by creating it in the backend and fetching the details.
  /// 
  /// [difficulty] - The selected difficulty level.
  /// [testType] - The type of test (Reading, Listening, etc.).
  /// [moduleType] - The specific module (e.g., Predicting Answers).
  /// 
  /// Returns a Map containing the test data and questions.
  Future<Map<String, dynamic>> execute({
    required Difficulty difficulty,
    required TestType testType,
    required Enum moduleType,
  }) async {
    // Convert enums to strings expected by TestHelper
    // Difficulty.band_5 -> "5"
    final difficultyStr = difficulty.name.replaceAll('band_', '');
    
    // TestType.listening -> "listening"
    final testTypeStr = testType.name;
    
    // ModuleType -> "predictingAnswers" (camelCase from enum name)
    final moduleTypeStr = moduleType.name;

    // Create and store test
    final testId = await TestHelper.createAndStoreTest(
      difficulty: difficultyStr,
      testType: testTypeStr,
      moduleType: moduleTypeStr,
    );

    // Fetch the created test with questions
    return await TestHelper.fetchTestById(testId: testId);
  }
}
