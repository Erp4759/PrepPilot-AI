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

class SpeakingPart3Screen extends StatefulWidget {
  const SpeakingPart3Screen({super.key});

  static const routeName = '/speaking_part_3';

  @override
  State<SpeakingPart3Screen> createState() => _SpeakingPart3ScreenState();
}

class _SpeakingPart3ScreenState extends State<SpeakingPart3Screen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data
  static const int _totalSeconds = 300; // 5 minutes for Part 3 discussion
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
      final result = await StartTest().execute(
        difficulty: _selectedDifficulty,
        testType: TestType.speaking,
        moduleType: SpeakingModuleType.part_3,
      );

      if (!mounted) return;

      setState(() {
        _testData = result;
        _questions = result['questions'] as List<dynamic>? ?? [];
        _testState = TestState.test;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load test: $e')));
      setState(() {
        _testState = TestState.initial;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  Future<void> _startListening(String questionId) async {
    // Ensure recognizer is available; try to initialize if not
    if (!_speechToText.isAvailable) {
      try {
        final ok = await _speechToText.initialize(
          onError: (e) {},
          onStatus: (s) {},
        );
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
          return;
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition initialization failed'),
          ),
        );
        return;
      }
    }

    // Always attempt to stop any ongoing listening and give it a moment to release resources
    try {
      await _speechToText.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      _isListening = true;
      _currentQuestionId = questionId;
      _currentTranscript = _answers[questionId] ?? '';
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _currentTranscript = result.recognizedWords;
            _answers[questionId] = _currentTranscript;
          });
        },
        listenFor: const Duration(seconds: 90), // 90 seconds per question
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
      );
    } catch (e) {
      // If listen fails, clear listening state and notify user
      setState(() {
        _isListening = false;
        _currentQuestionId = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start recording: $e')));
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    // Give the plugin a brief moment to settle
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      setState(() {
        _isListening = false;
        _currentQuestionId = '';
      });
    }
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
      // Use local evaluation - no database
      final results = await LocalSpeakingEvaluator.evaluateLocal(
        testData: _testData!,
        answers: _answers,
      );

      setState(() {
        _resultData = results;
        _testState = TestState.results;
      });
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
      _remainingSeconds = _totalSeconds;
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer Card
                SkillGlassCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Time Remaining',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isLowTime
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLowTime
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Part 3 Instructions
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
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.forum_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Part 3: Discussion',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'In this part, the examiner will ask you more abstract and analytical questions related to the topic from Part 2. Provide detailed answers with explanations, examples, and your opinions.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF6366F1),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: Give longer, more developed answers with reasoning and examples',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Questions
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final qid = question['question_id'];
                  final questionId = (qid is String) ? qid : qid.toString();
                  final questionText =
                      question['question_text'] as String? ?? '';
                  final isCurrentlyListening =
                      _isListening && _currentQuestionId == questionId;
                  final hasAnswer =
                      _answers.containsKey(questionId) &&
                      _answers[questionId]!.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SkillGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
                                    color: Color(0xFF1E293B),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Answer status or transcript
                          if (hasAnswer && !isCurrentlyListening) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _answers[questionId]!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF047857),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isCurrentlyListening) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Recording...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_currentTranscript.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _currentTranscript,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.mic_none,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Click record to answer',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Record/Stop button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isCurrentlyListening
                                  ? _stopListening
                                  : () => _startListening(questionId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrentlyListening
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: Icon(
                                isCurrentlyListening
                                    ? Icons.stop_circle
                                    : Icons.mic,
                                size: 20,
                              ),
                              label: Text(
                                isCurrentlyListening
                                    ? 'Stop Recording'
                                    : (hasAnswer
                                          ? 'Re-record'
                                          : 'Record Answer'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _answers.isEmpty ? null : _submitTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Submit Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Test?'),
                  content: const Text(
                    'Are you sure you want to exit? Your progress will be lost.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Speaking Part 3',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    // Normalize result data to a common shape used by feedback UI
    final Map<String, dynamic> res = _resultData ?? {};

    final int score =
        (res['score'] ?? res['total_score'] ?? res['total_points_earned'] ?? 0)
            as int;
    final int totalPoints =
        (res['total_points'] ?? res['total_points_possible'] ?? 0) as int;
    final int percentage = totalPoints > 0
        ? ((score / totalPoints * 100).round())
        : 0;

    // AI feedback text
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

    // Detailed answers - support multiple keys (detailed_answers or results)
    final List<dynamic> detailed =
        res['detailed_answers'] ?? res['detailedAnswers'] ?? [];
    List<Map<String, dynamic>> answersList = [];
    if (detailed.isNotEmpty) {
      answersList = detailed
          .map<Map<String, dynamic>>((d) => Map<String, dynamic>.from(d as Map))
          .toList();
    } else if (res['results'] != null) {
      // convert older results format
      final List<dynamic> old = res['results'] as List<dynamic>;
      for (var i = 0; i < old.length; i++) {
        final r = old[i] as Map<String, dynamic>;
        final questionText = _questions.length > i
            ? (_questions[i]['question_text'] ?? '')
            : 'Question ${i + 1}';
        final qid = _questions.length > i ? _questions[i]['question_id'] : null;
        final questionId = qid is String ? qid : (qid?.toString() ?? '');
        answersList.add({
          'question_num': i + 1,
          'question_text': questionText,
          'user_answer': _answers[questionId] ?? '',
          'is_correct': r['is_correct'] ?? false,
          'points_earned': r['points_earned'] ?? 0,
          'points_available':
              r['points_available'] ??
              (_questions.length > i ? (_questions[i]['points'] ?? 1) : 1),
          'feedback': r['feedback'] ?? '',
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Test Results',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // Score overview (copy of feedback style)
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

          // AI Analysis (copied approach)
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
                const SizedBox(height: 16),
                ...answersList.map((answer) {
                  final isCorrect = (answer['is_correct'] ?? false) as bool;
                  final pointsEarned = (answer['points_earned'] ?? 0) as int;
                  final pointsAvailable =
                      (answer['points_available'] ?? 1) as int;
                  final questionText =
                      (answer['question_text'] ?? '') as String;
                  final userAnswer = (answer['user_answer'] ?? '') as String;
                  final feedback = (answer['feedback'] ?? '') as String;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF10B981).withOpacity(.2)
                              : const Color(0xFFEF4444).withOpacity(.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Question ${answer['question_num']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '$pointsEarned/$pointsAvailable pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            questionText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Your Answer:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  userAnswer,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Correct Answer:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              feedback,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4F46E5),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _restartTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
    );
  }
}
