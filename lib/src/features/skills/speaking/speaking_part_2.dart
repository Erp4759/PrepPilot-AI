import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/test_properties.dart';
import '../widgets/skill_settings_dialog.dart';
import '../widgets/skill_loading_screen.dart';
import '../widgets/skill_glass_card.dart';
import '../actions/start_test.dart';
import 'local_speaking_evaluator.dart';
import '../../../library/results_notifier.dart';
import '../actions/submit_answers_and_check_results.dart';

class SpeakingPart2Screen extends StatefulWidget {
  const SpeakingPart2Screen({super.key});

  static const routeName = '/speaking_part_2';

  @override
  State<SpeakingPart2Screen> createState() => _SpeakingPart2ScreenState();
}

class _SpeakingPart2ScreenState extends State<SpeakingPart2Screen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test phases
  TestPhase _currentPhase = TestPhase.preparation;

  // Timers
  static const int _preparationSeconds = 60; // 1 minute to prepare
  static const int _speakingSeconds = 120; // 2 minutes to speak
  int _remainingSeconds = _preparationSeconds;
  bool _isSubmitting = false;
  Timer? _timer;

  // Backend Data
  Map<String, dynamic>? _testData;
  String _topicCard = '';
  List<String> _bulletPoints = [];
  String _userResponse = '';
  Map<String, dynamic>? _resultData;

  // Speech Recognition
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

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
      onStatus: (status) {
        if (status == 'done' && mounted) {
          setState(() {
            _isListening = false;
          });
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
        moduleType: SpeakingModuleType.part_2,
      );

      setState(() {
        _testData = testMap;
        _topicCard = testMap['text'] ?? '';

        // Extract bullet points from questions (they're used as prompts)
        final questions = testMap['questions'] as List<dynamic>? ?? [];
        _bulletPoints = questions
            .map((q) => q['question_text'] as String)
            .toList();

        _testState = TestState.test;
        _currentPhase = TestPhase.preparation;
        _startPreparationTimer();
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

  void _startPreparationTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _preparationSeconds;
      _currentPhase = TestPhase.preparation;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _startSpeakingPhase();
        }
      });
    });
  }

  void _startSpeakingPhase() {
    setState(() {
      _currentPhase = TestPhase.speaking;
      _remainingSeconds = _speakingSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          if (_isListening) {
            _stopListening();
          }
          _submitTest();
        }
      });
    });
  }

  void _skipToSpeaking() {
    _timer?.cancel();
    _startSpeakingPhase();
  }

  Future<void> _startListening() async {
    if (!_speechToText.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _userResponse = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _userResponse = result.recognizedWords;
        });
      },
      listenFor: Duration(seconds: _speakingSeconds),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    if (_isListening) {
      await _speechToText.stop();
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final questions = _testData!['questions'] as List<dynamic>;

      // Build answers map for evaluation
      final answers = <String, String>{};
      if (questions.isNotEmpty) {
        final qid = questions[0]['question_id'];
        final questionId = (qid is String) ? qid : qid.toString();
        answers[questionId] = _userResponse;
      }

      final testId = _testData!['test_id'];

      try {
        final submission = await SubmitAnswersAndCheckResults().submitAnswers(
          testId: testId,
          answers: answers,
        );

        final resultId = submission['result_id'] as String;
        final fullResult = await SubmitAnswersAndCheckResults().fetchResult(
          resultId: resultId,
        );

        ResultsNotifier.instance.notifyNewResult(resultId);

        setState(() {
          _resultData = fullResult;
          _testState = TestState.results;
        });
      } catch (e) {
        // fallback to local evaluation if server submission fails
        final results = await LocalSpeakingEvaluator.evaluateLocal(
          testData: _testData!,
          answers: answers,
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
      _currentPhase = TestPhase.preparation;
      _userResponse = '';
      _topicCard = '';
      _bulletPoints = [];
      _testData = null;
      _resultData = null;
      _isListening = false;
      _isSubmitting = false;
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

    return _currentPhase == TestPhase.preparation
        ? _buildPreparationScreen()
        : _buildSpeakingScreen();
  }

  Widget _buildPreparationScreen() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / _preparationSeconds;
    final isLowTime = _remainingSeconds < 15;

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

                // Phase indicator
                _PhaseIndicator(
                  phase: 'Preparation Time',
                  icon: Icons.edit_note,
                  color: const Color(0xFF2C8FFF),
                ),

                const SizedBox(height: 24),

                // Timer
                _buildTimerCard(minutes, seconds, progress, isLowTime),

                const SizedBox(height: 24),

                // Topic Card
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
                                colors: [Color(0xFF2C8FFF), Color(0xFF06B6D4)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.article,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Your Topic Card',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C8FFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2C8FFF).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _topicCard,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                            ),
                            if (_bulletPoints.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'You should say:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C8FFF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._bulletPoints.map(
                                (point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C8FFF),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                SkillGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: const Color(0xFFFFA500),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Preparation Tips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TipItem('📝 Make notes on paper if you have any'),
                      const SizedBox(height: 8),
                      _TipItem('💭 Think about key points for each bullet'),
                      const SizedBox(height: 8),
                      _TipItem('📚 Plan examples to illustrate your points'),
                      const SizedBox(height: 8),
                      _TipItem('⏱️ You\'ll speak for 1-2 minutes after this'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Skip button
                SkillSecondaryButton(
                  label: 'Skip to Speaking',
                  onPressed: _skipToSpeaking,
                  icon: Icons.fast_forward,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingScreen() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / _speakingSeconds;
    final isLowTime = _remainingSeconds < 30;

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

                // Phase indicator
                _PhaseIndicator(
                  phase: 'Speaking Time',
                  icon: Icons.mic,
                  color: const Color(0xFF10B981),
                ),

                const SizedBox(height: 24),

                _buildTimerCard(minutes, seconds, progress, isLowTime),

                const SizedBox(height: 40),

                // Recording controls
                Center(
                  child: GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isListening
                              ? [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ]
                              : [
                                  const Color(0xFF10B981),
                                  const Color(0xFF14B8A6),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isListening
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981))
                                    .withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    _isListening
                        ? 'Recording... (Tap to stop)'
                        : 'Tap to start speaking',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF5C6470).withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Transcript
                if (_userResponse.isNotEmpty)
                  SkillGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.text_snippet,
                              color: const Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Your Response',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            _userResponse,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Submit button
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
          _SmallBackButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          const Text(
            'Speaking - Part 2',
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
                    : _currentPhase == TestPhase.preparation
                    ? [const Color(0xFF2C8FFF), const Color(0xFF06B6D4)]
                    : [const Color(0xFF10B981), const Color(0xFF14B8A6)],
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

  Widget _buildResultsScreen() {
    // Normalize result data to feedback-like shape
    final Map<String, dynamic> res = _resultData ?? {};

    final int score = res['score'] is num ? (res['score'] as num).toInt() : 0;
    final int totalPoints = res['total_points'] is num
        ? (res['total_points'] as num).toInt()
        : (res['total_points_possible'] is num
              ? (res['total_points_possible'] as num).toInt()
              : 0);

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

    // Detailed answers
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
      // Fallback: build from test data (Part 2 typically has 1 question)
      final questions = _testData?['questions'] as List<dynamic>? ?? [];
      if (questions.isNotEmpty) {
        final q = questions[0] as Map<String, dynamic>;
        final qid = q['question_id'];
        final questionId = (qid is String) ? qid : (qid?.toString() ?? 'q1');
        answersList.add({
          'question_num': 1,
          'question_text':
              q['question_text'] ?? q['text'] ?? 'Your long turn response',
          'user_answer': _userResponse,
          'is_correct': false,
          'points_earned':
              res['detailed_answers'] != null &&
                  (res['detailed_answers'] is List)
              ? ((res['detailed_answers'] as List).isNotEmpty
                    ? (res['detailed_answers'][0]['points_earned'] ?? 0)
                    : 0)
              : (res['points_earned'] ?? 0),
          'points_available': 5,
          'feedback':
              res['detailed_answers'] != null &&
                  (res['detailed_answers'] is List)
              ? ((res['detailed_answers'] as List).isNotEmpty
                    ? (res['detailed_answers'][0]['feedback'] ?? '')
                    : '')
              : (res['feedback_text'] ?? ''),
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

enum TestPhase { preparation, speaking }

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
              colors: const [Color(0x282C8FFF), Color(0x2806B6D4)],
              size: 560,
            ),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _Blob(
              colors: const [Color(0x2810B981), Color(0x2814B8A6)],
              size: 460,
            ),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _Blob(
              colors: const [Color(0x286366F1), Color(0x282C8FFF)],
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

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({
    required this.phase,
    required this.icon,
    required this.color,
  });

  final String phase;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SkillGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phase == 'Preparation Time'
                      ? 'Read the topic and make notes'
                      : 'Speak for 1-2 minutes on the topic',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5C6470).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF1E293B).withOpacity(0.9),
            ),
          ),
        ),
      ],
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
