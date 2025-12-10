import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/test_properties.dart';
import '../widgets/skill_settings_dialog.dart';
import '../widgets/skill_loading_screen.dart';
import '../widgets/skill_glass_card.dart';
import '../actions/start_test.dart';
import '../actions/submit_answers_and_check_results.dart';
import '../../../library/results_notifier.dart';
import 'local_speaking_evaluator.dart';
import '../actions/exit_confirmation_dialog.dart';

class SpeakingPart1Screen extends StatefulWidget {
  const SpeakingPart1Screen({super.key});

  static const routeName = '/speaking_part_1';

  @override
  State<SpeakingPart1Screen> createState() => _SpeakingPart1ScreenState();
}

class _SpeakingPart1ScreenState extends State<SpeakingPart1Screen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data
  static const int _totalSeconds = 300; // 5 minutes for Part 1
  int _remainingSeconds = _totalSeconds;
  bool _isSubmitting = false;
  Timer? _timer;

  // Backend Data
  Map<String, dynamic>? _testData;
  List<dynamic> _questions = [];
  final Map<String, String> _answers = {}; // Store spoken answers
  Map<String, dynamic>? _resultData;

  // Speech Recognition
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _shouldKeepListening = false;
  String _currentQuestionId = '';
  String _currentTranscript = '';

  @override
  void initState() {
    super.initState();
    _initSpeechRecognition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog();
    });
  }

  Future<void> _initSpeechRecognition() async {
    _speechToText = stt.SpeechToText();
    await _speechToText.initialize(
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition error: ${error.errorMsg}'),
            ),
          );
        }
      },
      onStatus: (status) async {
        // Auto-restart if recognition ends but we expect to keep listening
        if (status == 'done' && mounted) {
          if (_shouldKeepListening && _currentQuestionId.isNotEmpty) {
            // give plugin a brief moment then restart
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            try {
              await _startListening(_currentQuestionId);
            } catch (_) {}
          } else {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SkillSettingsDialog(
        selectedDifficulty: _selectedDifficulty,
        // Speaking should only offer CEFR-style difficulties
        allowedDifficulties: [
          Difficulty.a1,
          Difficulty.a2,
          Difficulty.b1,
          Difficulty.b2,
          Difficulty.c1,
          Difficulty.c2,
          Difficulty.adaptive,
        ],
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
        testType: TestType.speaking,
        moduleType: SpeakingModuleType.part_1,
      );

      setState(() {
        _testData = testMap;
        _questions = testMap['questions'] ?? [];

        // Initialize empty answers for each question
        _answers.clear();
        for (var q in _questions) {
          final qid = q['question_id'];
          final questionId = (qid is String) ? qid : qid.toString();
          _answers[questionId] = '';
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

  Future<void> _startListening(String questionId) async {
    if (!_speechToText.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available')),
      );
      return;
    }

    if (_isListening && _currentQuestionId == questionId) {
      // Stop listening (user tapped to stop)
      _shouldKeepListening = false;
      await _speechToText.stop();
      setState(() {
        _isListening = false;
        _answers[questionId] = _currentTranscript;
      });
    } else {
      // Start listening
      setState(() {
        _currentQuestionId = questionId;
        _currentTranscript = _answers[questionId] ?? '';
        _isListening = true;
        _shouldKeepListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _currentTranscript = result.recognizedWords;
            _answers[questionId] = _currentTranscript;
          });
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 20),
        partialResults: true,
        localeId: 'en_US',
      );
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    if (_isListening) {
      _shouldKeepListening = false;
      await _speechToText.stop();
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final testId = _testData!['test_id'];

      try {
        // Try to save answers and generate feedback on the server
        final submission = await SubmitAnswersAndCheckResults().submitAnswers(
          testId: testId,
          answers: _answers,
        );

        final resultId = submission['result_id'] as String;
        final fullResult = await SubmitAnswersAndCheckResults().fetchResult(
          resultId: resultId,
        );

        // Notify the app that a new server-side result was created
        ResultsNotifier.instance.notifyNewResult(resultId);

        setState(() {
          _resultData = fullResult;
          _testState = TestState.results;
        });
      } catch (e) {
        // If server-side save failed (e.g., not logged in), fallback to local evaluation
        final results = await LocalSpeakingEvaluator.evaluateLocal(
          testData: _testData!,
          answers: _answers,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Result not saved: $e — showing local feedback'),
            ),
          );
        }

        setState(() {
          _resultData = results;
          _testState = TestState.results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting test: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _restartTest() {
    if (_isListening) {
      _speechToText.stop();
    }
    setState(() {
      _testState = TestState.initial;
      _answers.clear();
      _questions = [];
      _testData = null;
      _resultData = null;
      _isListening = false;
      _isSubmitting = false;
      _currentQuestionId = '';
      _currentTranscript = '';
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

    return _buildTestScreen();
  }

  Widget _buildTestScreen() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / _totalSeconds;
    final isLowTime = _remainingSeconds < 60;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildTimerCard(minutes, seconds, progress, isLowTime),
                const SizedBox(height: 24),

                // Test Title
                if (_testData != null)
                  SkillGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _testData!['title'] ?? 'Part 1 - Interview',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _testData!['text'] ??
                              'Answer the following questions about yourself and familiar topics.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: const Color(0xFF5C6470).withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Questions
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final q = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _questions.length - 1 ? 0 : 20,
                    ),
                    child: _buildQuestionCard(q, index + 1),
                  );
                }),

                const SizedBox(height: 32),

                // Submit Button
                SkillPrimaryButton(
                  label: 'Submit',
                  onPressed: _submitTest,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _SmallBackButton(
            onTap: () async {
              final shouldExit = await showExitConfirmationDialog(context);
              if (shouldExit) {
                _timer?.cancel();
                _speechToText.stop();
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'Speaking - Part 1',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(
    int minutes,
    int seconds,
    double progress,
    bool isLowTime,
  ) {
    return SkillGlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isLowTime
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(
                  child: Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C6470).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isLowTime
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question, int questionNumber) {
    final qid = question['question_id'];
    final questionId = (qid is String) ? qid : qid.toString();
    final questionText = question['question_text'] as String;
    final currentAnswer = _answers[questionId] ?? '';
    final isCurrentlyListening =
        _isListening && _currentQuestionId == questionId;

    return SkillGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    questionNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Answer display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentlyListening
                    ? const Color(0xFF6366F1)
                    : Colors.black.withOpacity(0.1),
                width: isCurrentlyListening ? 2 : 1,
              ),
            ),
            child: Text(
              currentAnswer.isEmpty
                  ? 'Tap the microphone to record your answer'
                  : currentAnswer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: currentAnswer.isEmpty
                    ? const Color(0xFF5C6470).withOpacity(0.5)
                    : const Color(0xFF1E293B),
                fontStyle: currentAnswer.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Microphone button
          Center(
            child: GestureDetector(
              onTap: () => _startListening(questionId),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isCurrentlyListening
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCurrentlyListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1))
                              .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isCurrentlyListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              isCurrentlyListening
                  ? 'Recording... (Tap to stop)'
                  : 'Tap to record',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF5C6470).withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    // Normalize result data to feedback-style structure
    final Map<String, dynamic> res = _resultData ?? {};

    final int score = res['score'] is num ? (res['score'] as num).toInt() : 0;

    // Prefer explicit total points if provided, otherwise assume 5 points per question
    int totalPoints = 0;
    if (res['total_points'] is num) {
      totalPoints = (res['total_points'] as num).toInt();
    } else if (res['total_points_possible'] is num) {
      totalPoints = (res['total_points_possible'] as num).toInt();
    } else if (_questions.isNotEmpty) {
      totalPoints = _questions.length * 5;
    }

    final int percentage = (totalPoints > 0)
        ? ((score / totalPoints * 100).round())
        : 0;

    final String aiFeedback =
        (res['feedback_text'] ??
                res['overall_feedback'] ??
                res['feedback'] ??
                '')
            as String;

    // Test context
    String testTitle = '';
    String testText = '';
    if (res.containsKey('test') && res['test'] is Map<String, dynamic>) {
      final t = res['test'] as Map<String, dynamic>;
      testTitle = (t['title'] ?? t['test_name'] ?? '') as String;
      testText = (t['text'] ?? t['test_description'] ?? '') as String;
    } else if (_testData != null) {
      testTitle =
          (_testData!['test']?['title'] ?? _testData!['title'] ?? '')
              as String? ??
          '';
      testText =
          (_testData!['test']?['test_description'] ??
                  _testData!['test_description'] ??
                  '')
              as String? ??
          '';
    }

    // Detailed answers: prefer structured detailed_answers, fallback to results, otherwise build from _questions/_answers
    final List<dynamic> detailed =
        res['detailed_answers'] ?? res['detailedAnswers'] ?? [];
    List<Map<String, dynamic>> answersList = [];

    if (detailed.isNotEmpty) {
      answersList = detailed
          .map<Map<String, dynamic>>((d) => Map<String, dynamic>.from(d as Map))
          .toList();
    } else if (res['results'] != null) {
      final List<dynamic> old = res['results'] as List<dynamic>;
      for (var i = 0; i < old.length; i++) {
        final r = old[i] as Map<String, dynamic>;
        answersList.add({
          'question_num': i + 1,
          'question_text': r['question_text'] ?? 'Question ${i + 1}',
          'user_answer': r['user_answer'] ?? '',
          'is_correct': r['is_correct'] ?? false,
          'points_earned': r['points_earned'] ?? 0,
          'points_available': r['points_available'] ?? 5,
          'feedback': r['feedback'] ?? '',
        });
      }
    } else {
      for (var i = 0; i < _questions.length; i++) {
        final q = _questions[i] as Map<String, dynamic>;
        final qid = q['question_id'];
        final questionId = (qid is String)
            ? qid
            : (qid?.toString() ?? 'q${i + 1}');
        answersList.add({
          'question_num': i + 1,
          'question_text':
              q['question_text'] ?? q['text'] ?? 'Question ${i + 1}',
          'user_answer': _answers[questionId] ?? '',
          'is_correct': false,
          'points_earned': 0,
          'points_available': 5,
          'feedback': '',
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),

          // Score overview
          SkillGlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C8FFF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Points',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${percentage}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Percentage',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${answersList.where((a) => (a['is_correct'] ?? false)).length}/${answersList.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Correct',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // AI Analysis
          if (aiFeedback.isNotEmpty) ...[
            SkillGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0F9FF), Color(0xFFF0FDF4)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(.2),
                      ),
                    ),
                    child: Text(
                      aiFeedback,
                      style: const TextStyle(height: 1.6, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Test Context
          SkillGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFB78DFF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Test Context',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (testTitle.isNotEmpty)
                  Text(
                    testTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  testText.isNotEmpty ? testText : 'Local speaking evaluation',
                  style: const TextStyle(height: 1.6, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Question Breakdown
          SkillGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.format_list_numbered_rounded,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Question Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...answersList.map((a) {
                  final earned = a['points_earned'] is num
                      ? (a['points_earned'] as num).toInt()
                      : 0;
                  final avail = a['points_available'] is num
                      ? (a['points_available'] as num).toInt()
                      : 5;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Q${a['question_num']}: ${a['question_text'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((a['user_answer'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              Text((a['user_answer'] ?? '').toString()),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Score: $earned / $avail',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  (a['feedback'] ?? '').toString(),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          SkillPrimaryButton(
            label: 'Try Again',
            onPressed: _restartTest,
            icon: Icons.refresh,
          ),
          const SizedBox(height: 12),
          SkillSecondaryButton(
            label: 'Back to Home',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.home,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS
// ============================================================================

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
              colors: const [Color(0x28A78BFA), Color(0x288B5CF6)],
              size: 460,
            ),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _Blob(
              colors: const [Color(0x286366F1), Color(0x2806B6D4)],
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

class SkillPrimaryButton extends StatelessWidget {
  const SkillPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkillSecondaryButton extends StatelessWidget {
  const SkillSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
