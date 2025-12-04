import '../../../library/test_helper.dart';

class SubmitAnswersAndCheckResults {
  /// Submits user answers for a test, evaluates them, and generates feedback.
  /// 
  /// [testId] - The ID of the test being submitted.
  /// [answers] - A map where keys are question IDs and values are user answers.
  /// 
  /// Returns a Map containing the result ID, feedback ID, and success status.
  Future<Map<String, dynamic>> submitAnswers({
    required String testId,
    required Map<String, String> answers,
  }) async {
    return await TestHelper.submitAndEvaluateTest(
      testId: testId,
      answers: answers,
    );
  }

  /// Fetches the complete result details including feedback and detailed answers.
  /// 
  /// [resultId] - The ID of the result to fetch.
  /// 
  /// Returns a Map containing the complete result data.
  Future<Map<String, dynamic>> fetchResult({
    required String resultId,
  }) async {
    return await TestHelper.fetchCompleteResult(resultId: resultId);
  }

  /// Fetches the history of results for the current user.
  /// 
  /// Returns a List of Maps containing result summaries.
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    return await TestHelper.fetchAllResults();
  }
}
