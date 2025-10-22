import '../models/test_result.dart';

class MockResults {
  static final List<TestResult> results = [
    TestResult(
      id: '1',
      title: 'Reading Comprehension',
      score: '7.5/9',
      date: 'Oct 20, 2025',
    ),
    TestResult(
      id: '2',
      title: 'Listening Practice',
      score: '6.0/9',
      date: 'Oct 19, 2025',
    ),
    TestResult(
      id: '3',
      title: 'Writing Task 2',
      score: '8.0/9',
      date: 'Oct 18, 2025',
    ),
    TestResult(
      id: '4',
      title: 'Speaking Part 2',
      score: '7.0/9',
      date: 'Oct 17, 2025',
    ),
  ];
}
