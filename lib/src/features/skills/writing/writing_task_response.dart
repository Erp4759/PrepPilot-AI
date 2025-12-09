import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_properties.dart';
import '../widgets/skill_settings_dialog.dart';
import '../widgets/skill_loading_screen.dart';
import '../widgets/skill_glass_card.dart';
import '../actions/start_test.dart';
import '../actions/submit_answers_and_check_results.dart';

class WritingTaskResponseScreen extends StatefulWidget {
  const WritingTaskResponseScreen({super.key});

  static const routeName = '/writing_task_response';

  @override
  State<WritingTaskResponseScreen> createState() =>
      _WritingTaskResponseScreenState();
}

class _WritingTaskResponseScreenState extends State<WritingTaskResponseScreen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.b2;
  Timer? _timer;
  static const int _totalSeconds = 600;
  int _remainingSeconds = _totalSeconds;
  bool _isSubmitting = false;

  // Backend Data
  Map<String, dynamic>? _testData;
  List<dynamic> _questions = [];
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSettingsDialog());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SkillSettingsDialog(
        selectedDifficulty: _selectedDifficulty,
        onStart: (difficulty) {
          setState(() {
            _selectedDifficulty = difficulty;
          });
          Navigator.of(context).pop();
          _startTest();
        },
        onCancel: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() {
      _testState = TestState.loading;
    });

    try {
      final testMap = await StartTest().execute(
        difficulty: _selectedDifficulty,
        testType: TestType.writing,
        moduleType: WritingModuleType.task_response,
      );

      setState(() {
        _testData = testMap;
        _questions = testMap['questions'] ?? [];

        // Initialize controllers for each question
        _controllers.clear();
        for (var q in _questions) {
          _controllers[q['question_id']] = TextEditingController();
        }

        _testState = TestState.test;
        _startTimer();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting test: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitTest();
        }
      });
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = <String, String>{};
      _controllers.forEach((questionId, controller) {
        answers[questionId] = controller.text;
      });

      final testId = _testData!['test_id'];
      final submissionResult = await SubmitAnswersAndCheckResults()
          .submitAnswers(testId: testId, answers: answers);

      final resultId = submissionResult['result_id'];
      final fullResult = await SubmitAnswersAndCheckResults().fetchResult(
        resultId: resultId,
      );

      setState(() {
        _resultData = fullResult;
        _isSubmitting = false;
        _testState = TestState.results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting test: $e')));
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _restartTest() {
    setState(() {
      _testState = TestState.initial;
      _controllers.clear();
      _questions = [];
      _testData = null;
      _resultData = null;
    });
    _showSettingsDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _GradientBackground(),
          SafeArea(child: _buildContent()),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_testState == TestState.initial) {
      return const SizedBox.shrink();
    }
    if (_testState == TestState.loading) {
      return const SkillLoadingScreen();
    }
    if (_testState == TestState.results && _resultData != null) {
      return _buildResultsScreen();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimerCard(),
                const SizedBox(height: 24),
                if (_testData != null && _testData!['text'] != null) ...[
                  SkillGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Instructions / Context",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _testData!['text'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF334155),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ..._questions.map((q) => _buildQuestionCard(q)),
                const SizedBox(height: 40),
                SkillPrimaryButton(
                  label: _isSubmitting ? 'Evaluating...' : 'Submit All',
                  onTap: _isSubmitting ? () {} : _submitTest,
                  icon: _isSubmitting ? null : Icons.check_circle,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionId = question['question_id'];
    final questionText = question['question_text'];
    final questionNum = question['question_num'];
    final controller = _controllers[questionId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SkillGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $questionNum',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / _totalSeconds;
    final isLowTime = _remainingSeconds < 60;

    return SkillGlassCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isLowTime
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ),
            ),
            child: Center(
              child: Icon(
                isLowTime ? Icons.timer_off : Icons.timer,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isLowTime
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF6366F1),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isLowTime
                        ? const Color(0xFFEF4444).withOpacity(0.15)
                        : const Color(0xFF6366F1).withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLowTime
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6366F1),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _SmallBackButton(
            onTap: () {
              _timer?.cancel();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'Linking Devices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final score = _resultData!['score'];
    final totalPoints = _resultData!['total_points'];
    final feedbackText = _resultData!['feedback_text'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkillGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Evaluation Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $score / $totalPoints',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Feedback:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedbackText ?? "No feedback available.",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SkillPrimaryButton(
                  label: 'Try Again',
                  onTap: _restartTest,
                  icon: Icons.refresh,
                ),
                const SizedBox(height: 16),
                SkillSecondaryButton(
                  label: 'Back to Menu',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -80,
            top: -120,
            child: _Blob(
              colors: const [Color(0x286366F1), Color(0x288B5CF6)],
              size: 560,
            ),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _Blob(
              colors: const [Color(0x28FFD17C), Color(0x28B78DFF)],
              size: 460,
            ),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _Blob(
              colors: const [Color(0x2878C8FF), Color(0x28FFA078)],
              size: 680,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.colors, required this.size});

  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors, stops: const [0.2, 1]),
        ),
      ),
    );
  }
}

class _SmallBackButton extends StatelessWidget {
  const _SmallBackButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
