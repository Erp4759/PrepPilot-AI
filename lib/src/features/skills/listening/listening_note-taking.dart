import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_properties.dart';
import '../widgets/skill_settings_dialog.dart';
import '../widgets/skill_loading_screen.dart';
import '../widgets/skill_glass_card.dart';

class ListeningNoteTakingScreen extends StatefulWidget {
  const ListeningNoteTakingScreen({super.key});

  static const routeName = '/listening_note-taking';

  @override
  State<ListeningNoteTakingScreen> createState() =>
      _ListeningNoteTakingScreenState();
}

class _ListeningNoteTakingScreenState
    extends State<ListeningNoteTakingScreen> {
  TestState _testState = TestState.initial;
  Difficulty _selectedDifficulty = Difficulty.band_5;

  // Test data
  List<_BlankQuestion>? _questions;
  int? _totalSeconds = 0;
  int? _remainingSeconds = 0;
  bool _isPlaying = false;
  Timer? _timer;

  // User answers
  late Map<int, TextEditingController> _answerControllers;

  @override
  void initState() {
    super.initState();
    _answerControllers = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _answerControllers.values) {
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

    await Future.delayed(const Duration(seconds: 2));

    _generateMockTest();
    _startTimer();

    setState(() {
      _testState = TestState.test;
    });
  }

  void _generateMockTest() {
    _questions = [
      _BlankQuestion(
        text: 'The main topic of the passage is about ',
        blank: 'climate change',
        explanation: 'The speaker focuses on environmental issues.',
      ),
      _BlankQuestion(
        text: 'According to the speaker, the primary cause is ',
        blank: 'human activities',
        explanation: 'The passage emphasizes human responsibility.',
      ),
      _BlankQuestion(
        text: 'The solution proposed includes reducing ',
        blank: 'carbon emissions',
        explanation: 'This is mentioned as a key strategy.',
      ),
      _BlankQuestion(
        text: 'Scientists estimate that temperatures will rise by ',
        blank: '2-3 degrees',
        explanation: 'This data point is stated in the audio.',
      ),
      _BlankQuestion(
        text: 'The most urgent action needed is to promote ',
        blank: 'renewable energy',
        explanation: 'Renewable energy is highlighted as crucial.',
      ),
    ];

    // 컨트롤러 초기화
    _answerControllers.clear();
    for (int i = 0; i < _questions!.length; i++) {
      _answerControllers[i] = TextEditingController();
    }

    _totalSeconds = 300; // 5분
    _remainingSeconds = _totalSeconds;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
        } else {
          _timer?.cancel();
          _submitAnswers();
        }
      });
    });
  }

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
    });

    // 실제로는 여기서 LLM으로 생성된 오디오 파일을 재생
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isPlaying = false;
    });
  }

  void _submitAnswers() {
    _timer?.cancel();

    // 정답 확인
    int correctCount = 0;
    for (int i = 0; i < _questions!.length; i++) {
      if (_answerControllers[i]!.text.toLowerCase() ==
          _questions![i].blank.toLowerCase()) {
        correctCount++;
      }
    }

    setState(() {
      _testState = TestState.results;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You got $correctCount/${_questions!.length} correct!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _restartTest() {
    setState(() {
      _testState = TestState.initial;
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
                const SizedBox(height: 16),
                // 타이머
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
                                ? [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626)
                                  ]
                                : [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF8B5CF6)
                                  ],
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
                const SizedBox(height: 40),
                // 큰 스피커 아이콘
                Center(
                  child: GestureDetector(
                    onTap: _isPlaying ? null : _playAudio,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isPlaying
                            ? SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                Icons.volume_up_rounded,
                                size: 60,
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
                const SizedBox(height: 48),
                // 지시사항
                SkillGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fill in the blanks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Listen to the passage and complete the notes by filling in the missing words.',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF5C6470).withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 빈칸 채우기 문제들
                ..._buildBlankQuestions(),
                const SizedBox(height: 32),
                // 제출 버튼
                _buildSubmitButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBlankQuestions() {
    return List.generate(_questions!.length, (index) {
      final question = _questions![index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
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
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
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
                      question.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerControllers[index],
                decoration: InputDecoration(
                  hintText: 'Type your answer here',
                  hintStyle: TextStyle(
                    color: const Color(0xFF5C6470).withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6366F1),
                      width: 2,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    final isAnswered = _answerControllers.values.every((c) => c.text.isNotEmpty);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnswered ? _submitAnswers : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isAnswered
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFE2E8F0)],
                  ),
            boxShadow: isAnswered
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.send_rounded,
                color: isAnswered ? Colors.white : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isAnswered ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    int correctCount = 0;
    for (int i = 0; i < _questions!.length; i++) {
      if (_answerControllers[i]!.text.toLowerCase() ==
          _questions![i].blank.toLowerCase()) {
        correctCount++;
      }
    }

    final percentage = ((correctCount / _questions!.length) * 100).toInt();
    final isPassed = percentage >= 70;

    return Center(
      child: SkillGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPassed ? Icons.check_circle_outline : Icons.close,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: isPassed
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctCount/${_questions!.length} Correct',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5C6470),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions!.length,
              itemBuilder: (context, index) {
                final question = _questions![index];
                final userAnswer = _answerControllers[index]!.text;
                final isCorrect =
                    userAnswer.toLowerCase() == question.blank.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFEF4444).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Question ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!isCorrect) ...[
                          Text(
                            'Your answer: $userAnswer',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5C6470),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Correct answer: ${question.blank}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
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
            'Note-Taking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BlankQuestion {
  final String text;
  final String blank;
  final String explanation;

  _BlankQuestion({
    required this.text,
    required this.blank,
    required this.explanation,
  });
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

