import '../models/test_result.dart';

class MockResults {
  static final List<TestResult> results = [
    TestResult(
      resultId: 'r1',
      testId: 't1',
      userId: 'u1',
      title: 'Reading Comprehension',
      score: 7,
      totalPoints: 9,
      testType: 'reading',
      moduleType: 'inference',
      difficulty: 3,
      createdAt: DateTime.parse('2025-10-20T12:00:00Z'),
    ),
    TestResult(
      resultId: 'r2',
      testId: 't2',
      userId: 'u1',
      title: 'Listening Practice',
      score: 6,
      totalPoints: 9,
      testType: 'listening',
      moduleType: 'gist_listening',
      difficulty: 4,
      createdAt: DateTime.parse('2025-10-19T12:00:00Z'),
    ),
    TestResult(
      resultId: 'r3',
      testId: 't3',
      userId: 'u1',
      title: 'Writing Task 2',
      score: 8,
      totalPoints: 9,
      testType: 'writing',
      moduleType: 'task_response',
      difficulty: 5,
      createdAt: DateTime.parse('2025-10-18T12:00:00Z'),
    ),
    TestResult(
      resultId: 'r4',
      testId: 't4',
      userId: 'u1',
      title: 'Speaking Part 2',
      score: 7,
      totalPoints: 9,
      testType: 'speaking',
      moduleType: 'part_2',
      difficulty: 0,
      createdAt: DateTime.parse('2025-10-17T12:00:00Z'),
    ),
  ];
}
