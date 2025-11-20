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

    setState(() => _isLoading = true);

    try {
      // Use TestHelper to generate and store the test
      final testId = await TestHelper.createAndStoreTest(
        difficulty: difficulty,
        testType: testType,
        moduleType: moduleType,
      );

      setState(() => _response = 'Test created successfully! Test ID: $testId');
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _difficultyController.dispose();
    _testTypeController.dispose();
    _moduleTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              onPressed: _isLoading ? null : _runTestGeneration,
              child: Text(_isLoading ? 'Loading...' : 'Generate Test'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_response, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
