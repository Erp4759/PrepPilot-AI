import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_properties.dart';
import '../widgets/skill_settings_dialog.dart';
import '../widgets/skill_loading_screen.dart';
import '../widgets/skill_glass_card.dart';

class ListeningPredictingAnswersScreen extends StatefulWidget {
  const ListeningPredictingAnswersScreen({super.key});

  static const routeName = '/listening_predicting_answers';

  @override
  State<ListeningPredictingAnswersScreen> createState() =>
      _ListeningPredictingAnswersScreenState();
}

class _ListeningPredictingAnswersScreenState
    extends State<ListeningPredictingAnswersScreen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.band_5;

  // Test data
  int? _totalSeconds = 0;
  int? _remainingSeconds = 0;
  bool _isPlaying = false;
  Timer? _timer;
  
  List<_Question> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _userAnswers = {}; // Index -> Answer (String or int)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    await Future.delayed(const Duration(seconds: 2));

    _generateMockTest();
    _startTimer();

    setState(() {
      _testState = TestState.test;
    });
  }

  void _generateMockTest() {
    // Mock data for Predicting Answers
    // Q1: Prediction (TextField), Q2: Multiple Choice
    _questions = [
      _Question(
        id: 1,
        type: _QuestionType.prediction,
        prompt: 'Predict what the speaker will say next about the climate policy.',
        correctAnswer: 'The government will introduce new carbon taxes.', // Mock answer for checking
      ),
      _Question(
        id: 2,
        type: _QuestionType.multipleChoice,
        prompt: 'What is the main reason for the policy change?',
        options: [
          'To reduce budget deficit',
          'To meet international agreements',
          'To encourage local industry',
          'To lower energy prices'
        ],
        correctAnswer: 1, // Index of correct option
      ),
    ];

    _totalSeconds = 300; // 5 minutes
    _remainingSeconds = _totalSeconds;
    _currentQuestionIndex = 0;
    _userAnswers.clear();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
        } else {
          _timer?.cancel();
          _submitTest();
        }
      });
    });
  }

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
    });

    // Mock audio playback
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isPlaying = false;
    });
  }

  void _submitTest() {
    _timer?.cancel();
    setState(() {
      _testState = TestState.results;
    });
  }

  void _restartTest() {
    setState(() {
      _testState = TestState.initial;
      _userAnswers.clear();
      _currentQuestionIndex = 0;
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_testState) {
      case TestState.initial:
        return const SizedBox();
      case TestState.loading:
        return const SkillLoadingScreen();
      case TestState.test:
        return _buildTestScreen();
      case TestState.results:
        return _buildResultsScreen();
    }
  }

  Widget _buildTestScreen() {
    final minutes = _remainingSeconds! ~/ 60;
    final seconds = _remainingSeconds! % 60;
    final progress = _remainingSeconds! / _totalSeconds!;
    final isLowTime = _remainingSeconds! < 30;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer
                SkillGlassCard(
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
                ),
                const SizedBox(height: 32),
                
                // Audio Player
                Center(
                  child: GestureDetector(
                    onTap: _isPlaying ? null : _playAudio,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isPlaying
                            ? const SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.volume_up_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isPlaying ? 'Playing audio...' : 'Tap to listen',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF5C6470).withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Question Area
                _buildQuestionCard(),
                
                const SizedBox(height: 24),
                
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestionIndex > 0)
                      SkillSecondaryButton(
                        label: 'Previous',
                        onTap: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                      )
                    else
                      const SizedBox(),
                    
                    SkillPrimaryButton(
                      label: _currentQuestionIndex < _questions.length - 1
                          ? 'Next'
                          : 'Submit',
                      onTap: () {
                        if (_currentQuestionIndex < _questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          _submitTest();
                        }
                      },
                      icon: _currentQuestionIndex < _questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _questions[_currentQuestionIndex];
    
    return SkillGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type == _QuestionType.prediction
                      ? 'Prediction'
                      : 'Multiple Choice',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.prompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (question.type == _QuestionType.prediction)
            _buildPredictionInput(question)
          else
            _buildMultipleChoiceOptions(question),
        ],
      ),
    );
  }

  Widget _buildPredictionInput(_Question question) {
    return TextField(
      onChanged: (value) {
        _userAnswers[question.id] = value;
      },
      controller: TextEditingController(text: _userAnswers[question.id] as String?)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: (_userAnswers[question.id] as String? ?? '').length),
        ),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Type your prediction here...',
        hintStyle: TextStyle(
          color: const Color(0xFF5C6470).withOpacity(0.5),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E293B),
        height: 1.6,
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(_Question question) {
    return Column(
      children: List.generate(question.options!.length, (index) {
        final isSelected = _userAnswers[question.id] == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _userAnswers[question.id] = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF94A3B8),
                          width: 2,
                        ),
                        color: isSelected ? const Color(0xFF6366F1) : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options![index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultsScreen() {
    int correctCount = 0;
    for (var question in _questions) {
      if (question.type == _QuestionType.multipleChoice) {
        if (_userAnswers[question.id] == question.correctAnswer) {
          correctCount++;
        }
      }
      // For prediction, we can't auto-grade easily without LLM, so we'll just count it as done for now
      // or maybe just show the user's answer vs expected.
    }

    return Center(
      child: SkillGlassCard(
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
              'Test Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have finished the predicting answers exercise.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            SkillPrimaryButton(
              label: 'Try Another',
              onTap: _restartTest,
              icon: Icons.refresh,
            ),
          ],
        ),
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
            'Predicting Answers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODELS & ENUMS
// ============================================================================

enum _QuestionType { prediction, multipleChoice }

class _Question {
  final int id;
  final _QuestionType type;
  final String prompt;
  final List<String>? options;
  final dynamic correctAnswer; // String for prediction, int index for multiple choice

  _Question({
    required this.id,
    required this.type,
    required this.prompt,
    this.options,
    required this.correctAnswer,
  });
}

// ============================================================================
// CUSTOM WIDGETS (Reused from Distractors Screen style)
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


