import 'package:flutter/material.dart';
import '../../../library/test_helper.dart';

class ChatGPTTestScreen extends StatefulWidget {
  const ChatGPTTestScreen({super.key});
  static const routeName = '/chatgpt-test';

  @override
  State<ChatGPTTestScreen> createState() => _ChatGPTTestScreenState();
}

class _ChatGPTTestScreenState extends State<ChatGPTTestScreen> {
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _testTypeController = TextEditingController();
  final TextEditingController _moduleTypeController = TextEditingController();

  String _response = '';
  bool _isLoading = false;

  // Test data
  String? _currentTestId;
  Map<String, dynamic>? _testData;
  Map<String, TextEditingController> _answerControllers = {};

  // Result data
  Map<String, dynamic>? _submissionResult;

  Future<void> _runTestGeneration() async {
    final difficulty = _difficultyController.text.trim();
    final testType = _testTypeController.text.trim();
    final moduleType = _moduleTypeController.text.trim();

    if (difficulty.isEmpty || testType.isEmpty || moduleType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
      _testData = null;
      _currentTestId = null;
      _submissionResult = null;
    });

    try {
      // Generate and store the test
      final testId = await TestHelper.createAndStoreTest(
        difficulty: difficulty,
        testType: testType,
        moduleType: moduleType,
      );

      // Fetch the generated test with questions
      final testData = await TestHelper.fetchTestById(testId: testId);

      // Initialize answer controllers for each question
      final questions = testData['questions'] as List;
      _answerControllers.clear();
      for (var question in questions) {
        _answerControllers[question['question_id']] = TextEditingController();
      }

      setState(() {
        _currentTestId = testId;
        _testData = testData;
        _response = 'Test created successfully!';
      });
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTest() async {
    if (_currentTestId == null || _testData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No test to submit")));
      return;
    }

    // Collect answers
    final answers = <String, String>{};
    _answerControllers.forEach((questionId, controller) {
      answers[questionId] = controller.text.trim();
    });

    // Check if all questions are answered
    if (answers.values.any((answer) => answer.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Submit and evaluate the test
      final result = await TestHelper.submitAndEvaluateTest(
        testId: _currentTestId!,
        answers: answers,
      );

      setState(() {
        _submissionResult = result;
        _response = 'Test submitted and evaluated successfully!';
      });

      // Show success dialog
      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      setState(() => _response = 'Error submitting test: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result ID: ${result['result_id']}'),
            const SizedBox(height: 8),
            Text('Feedback ID: ${result['feedback_id']}'),
            const SizedBox(height: 16),
            const Text(
              'Your test has been evaluated!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetTest() {
    setState(() {
      _currentTestId = null;
      _testData = null;
      _submissionResult = null;
      _response = '';
      _answerControllers.clear();
      _difficultyController.clear();
      _testTypeController.clear();
      _moduleTypeController.clear();
    });
  }

  @override
  void dispose() {
    _difficultyController.dispose();
    _testTypeController.dispose();
    _moduleTypeController.dispose();
    _answerControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Generator'),
        actions: [
          if (_testData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetTest,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Test Generation Form
                  if (_testData == null) ...[
                    TextField(
                      controller: _difficultyController,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty (e.g. Band 5, Band 6)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _testTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Test Type (e.g. Reading, Listening)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _moduleTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Module Type (e.g. Scanning, Matching)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _runTestGeneration,
                      child: const Text('Generate Test'),
                    ),
                  ],

                  // Test Display
                  if (_testData != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _testData!['title'] ?? 'Test',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _testData!['text'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Difficulty: ${_testData!['difficulty']} | '
                              'Type: ${_testData!['test_type']} | '
                              'Module: ${_testData!['module_type']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Questions
                    Text(
                      'Questions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...(_testData!['questions'] as List).map((question) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${question['question_num']}: ${question['question_text']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller:
                                    _answerControllers[question['question_id']],
                                decoration: const InputDecoration(
                                  hintText: 'Enter your answer',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submissionResult == null ? _submitTest : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _submissionResult == null
                            ? 'Submit Test'
                            : 'Test Already Submitted',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],

                  // Response/Status
                  if (_response.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _response,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],

                  // Submission Result
                  if (_submissionResult != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✅ Test Submitted Successfully!',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Result ID: ${_submissionResult!['result_id']}',
                            ),
                            Text(
                              'Feedback ID: ${_submissionResult!['feedback_id']}',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your answers have been marked and feedback has been generated!',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
