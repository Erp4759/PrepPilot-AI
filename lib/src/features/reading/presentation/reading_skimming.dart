import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prep_pilot_ai/src/services/ai_agent.dart';
import 'dart:convert';

enum TestState { initial, loading, test, results }

enum PassageLength { short, medium, long }

enum Difficulty { a1, a2, b1, b2, c1, c2, adaptive }

enum QuestionType { multipleChoice, shortAnswer, trueFalse }

class ReadingSkimmingScreen extends StatefulWidget {
  const ReadingSkimmingScreen({super.key});

  static const routeName = '/reading-skimming';

  @override
  State<ReadingSkimmingScreen> createState() => _ReadingSkimmingScreenState();
}

class _ReadingSkimmingScreenState extends State<ReadingSkimmingScreen> {
  TestState _testState = TestState.initial;
  PassageLength _selectedLength = PassageLength.medium;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data
  String? _generatedPassage;
  List<Map<String, dynamic>>? _generatedQuestions;
  final Map<int, dynamic> _answers = {};

  // Timer
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;

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
      builder: (context) => _SettingsDialog(
        selectedLength: _selectedLength,
        selectedDifficulty: _selectedDifficulty,
        onStart: (length, difficulty) {
          setState(() {
            _selectedLength = length;
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
      final difficultyLabel = _selectedDifficulty.name.toUpperCase();
      final lengthLabel = switch (_selectedLength) {
        PassageLength.short => 'short (100-150 words)',
        PassageLength.medium => 'medium (250-350 words)',
        PassageLength.long => 'long (450-650 words)',
      };

      final prompt =
          '''You are an exam item writer for SKIMMING reading tasks.
Create a passage and quick skimming questions.

Constraints:
- CEFR level: $difficultyLabel
- Passage length: $lengthLabel
- Return JSON only with this shape:
{"passage":"...","questions":[{"type":"multipleChoice|shortAnswer|trueFalse","question":"...","options":["..."],"correctAnswer": index_or_value}, ...]}
''';

      final parsed = await aiJson<Map<String, dynamic>>(
        userPrompt: prompt,
        system: 'Return JSON only. No prose. Use double quotes.',
        temperature: 0.6,
        maxTokens: 1200,
      );

      _generatedPassage = (parsed['passage'] as String).trim();
      final qRaw = (parsed['questions'] as List).cast<dynamic>();
      _generatedQuestions = qRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _totalSeconds = _getTimeLimit();
      _remainingSeconds = _totalSeconds;
      _answers.clear();
      _startTimer();

      setState(() {
        _testState = TestState.test;
      });
    } catch (e) {
      // Fallback to mock test if generation fails
      _generateMockTest();
      _startTimer();
      if (!mounted) return;
      setState(() {
        _testState = TestState.test;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI generation failed, using mock test: $e'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _generateMockTest() {
    _generatedPassage = _getMockPassage();
    _generatedQuestions = _getMockQuestions();
    _totalSeconds = _getTimeLimit();
    _remainingSeconds = _totalSeconds;
    _answers.clear();
  }

  int _getTimeLimit() {
    // Time limits based on passage length (in seconds)
    switch (_selectedLength) {
      case PassageLength.short:
        return 180; // 3 minutes
      case PassageLength.medium:
        return 300; // 5 minutes
      case PassageLength.long:
        return 420; // 7 minutes
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitAnswers();
        }
      });
    });
  }

  String _getMockPassage() {
    if (_selectedLength == PassageLength.short) {
      return '''The Great Wall of China is one of the most impressive architectural feats in human history. Construction began in the 7th century BC and continued for over 2,000 years. The wall stretches approximately 21,196 kilometers across northern China. Originally built to protect against invasions, it now serves as a major tourist attraction, drawing millions of visitors annually.''';
    } else if (_selectedLength == PassageLength.medium) {
      return '''Photosynthesis is the process by which plants convert light energy into chemical energy. This occurs primarily in the leaves, where chlorophyll absorbs sunlight. The process uses carbon dioxide from the air and water from the soil to produce glucose and oxygen. The glucose provides energy for plant growth, while oxygen is released into the atmosphere.

This process is crucial for life on Earth, as it produces the oxygen that most organisms need to survive. Additionally, plants form the base of most food chains, making photosynthesis essential for the entire ecosystem. Scientists estimate that photosynthesis produces about 330 billion tons of organic matter annually.''';
    } else {
      return '''The Internet of Things (IoT) refers to the network of physical devices embedded with sensors, software, and connectivity that enables them to collect and exchange data. These devices range from everyday household items like refrigerators and thermostats to sophisticated industrial equipment. By 2025, experts predict there will be over 75 billion IoT devices worldwide.

IoT technology has transformed numerous industries. In healthcare, wearable devices monitor patient vitals in real-time. Smart cities use IoT sensors to optimize traffic flow and reduce energy consumption. In agriculture, IoT devices monitor soil conditions and weather patterns to improve crop yields.

However, IoT also presents significant challenges. Security concerns are paramount, as each connected device represents a potential entry point for cyberattacks. Privacy issues arise from the massive amounts of personal data these devices collect. Additionally, the lack of standardization across different IoT platforms makes integration difficult.

Despite these challenges, the IoT market continues to grow rapidly. The technology promises to increase efficiency, reduce costs, and create new business opportunities across virtually every sector of the economy.''';
    }
  }

  List<Map<String, dynamic>> _getMockQuestions() {
    if (_selectedDifficulty == Difficulty.a1 ||
        _selectedDifficulty == Difficulty.a2) {
      return [
        {
          'type': QuestionType.multipleChoice,
          'question': 'When did construction of the Great Wall begin?',
          'options': [
            '5th century BC',
            '7th century BC',
            '9th century BC',
            '11th century BC',
          ],
          'correctAnswer': 1,
        },
        {
          'type': QuestionType.trueFalse,
          'question': 'The Great Wall was built to attract tourists.',
          'correctAnswer': false,
        },
        {
          'type': QuestionType.shortAnswer,
          'question':
              'How long is the Great Wall? (give approximate number in km)',
          'correctAnswer': '21196',
        },
      ];
    } else if (_selectedDifficulty == Difficulty.b1 ||
        _selectedDifficulty == Difficulty.b2) {
      return [
        {
          'type': QuestionType.multipleChoice,
          'question': 'What is the primary purpose of photosynthesis?',
          'options': [
            'To produce water',
            'To convert light into chemical energy',
            'To absorb carbon dioxide',
            'To release nitrogen',
          ],
          'correctAnswer': 1,
        },
        {
          'type': QuestionType.trueFalse,
          'question': 'Photosynthesis occurs mainly in plant roots.',
          'correctAnswer': false,
        },
        {
          'type': QuestionType.shortAnswer,
          'question': 'Name the green pigment that absorbs sunlight.',
          'correctAnswer': 'chlorophyll',
        },
        {
          'type': QuestionType.multipleChoice,
          'question':
              'How much organic matter does photosynthesis produce annually?',
          'options': [
            '100 billion tons',
            '200 billion tons',
            '330 billion tons',
            '500 billion tons',
          ],
          'correctAnswer': 2,
        },
      ];
    } else {
      return [
        {
          'type': QuestionType.multipleChoice,
          'question':
              'According to the passage, how many IoT devices are predicted by 2025?',
          'options': ['50 billion', '75 billion', '100 billion', '125 billion'],
          'correctAnswer': 1,
        },
        {
          'type': QuestionType.trueFalse,
          'question': 'IoT devices are only used in household applications.',
          'correctAnswer': false,
        },
        {
          'type': QuestionType.shortAnswer,
          'question': 'Name one major challenge mentioned for IoT technology.',
          'correctAnswer': 'security',
        },
        {
          'type': QuestionType.multipleChoice,
          'question': 'In which sector does IoT help monitor patient vitals?',
          'options': [
            'Agriculture',
            'Healthcare',
            'Transportation',
            'Manufacturing',
          ],
          'correctAnswer': 1,
        },
        {
          'type': QuestionType.trueFalse,
          'question':
              'The passage states that IoT platforms are well standardized.',
          'correctAnswer': false,
        },
      ];
    }
  }

  void _submitAnswers() {
    _timer?.cancel();
    setState(() {
      _testState = TestState.loading;
    });

    _analyzeAnswers();
  }

  Future<void> _analyzeAnswers() async {
    if (_generatedPassage == null || _generatedQuestions == null) return;

    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _generatedQuestions!.length; i++) {
      final q = _generatedQuestions![i];
      items.add({
        'index': i,
        'type': q['type'],
        'question': q['question'],
        'options': q['options'] ?? [],
        'correctAnswer': q['correctAnswer'],
        'user_answer': _answers.containsKey(i) ? _answers[i] : null,
      });
    }

    final prompt =
        '''You are an automated grader for SKIMMING reading tasks.
Given the passage and the list of questions with user answers, grade each item as correct or incorrect.

Return JSON array only: [{"index":0,"is_correct":true|false,"expected":"short expected answer","feedback":"brief feedback","score":0|1}, ...]

Passage:\n${_generatedPassage}\n\nData:${jsonEncode(items)}
''';

    try {
      final parsed = await aiJson<List<dynamic>>(
        userPrompt: prompt,
        system: 'Return JSON only. No prose. Use double quotes.',
        temperature: 0.0,
        maxTokens: 1200,
      );

      final results = parsed
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Convert results into simple feedback UI: store expected/feedback in _generatedQuestions
      for (final r in results) {
        final idx = (r['index'] as num).toInt();
        if (idx >= 0 && idx < _generatedQuestions!.length) {
          _generatedQuestions![idx]['_is_correct'] = r['is_correct'];
          _generatedQuestions![idx]['_expected'] = r['expected'] ?? '';
          _generatedQuestions![idx]['_feedback'] = r['feedback'] ?? '';
          _generatedQuestions![idx]['_score'] =
              r['score'] ?? (r['is_correct'] == true ? 1 : 0);
        }
      }

      if (!mounted) return;
      setState(() {
        _testState = TestState.results;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Analysis complete!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _testState = TestState.test);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze answers: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _restartTest() {
    setState(() {
      _testState = TestState.initial;
      _answers.clear();
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
        return _buildLoadingScreen();
      case TestState.test:
        return _buildTestScreen();
      case TestState.results:
        return _buildResultsScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preparing your test...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'AI is creating a skimming challenge',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            _LoadingProgressIndicator(
              label: 'Setting difficulty...',
              value: 0.33,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Generating passage...',
              value: 0.66,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Creating quick questions...',
              value: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestScreen() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildTestHeader(),
                const SizedBox(height: 16),
                _buildTimerCard(),
                const SizedBox(height: 16),
                _buildPassageCard(),
                const SizedBox(height: 20),
                _buildQuestionsCard(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestHeader() {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skimming Test',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getDifficultyLabel(_selectedDifficulty)} • ${_getLengthLabel(_selectedLength)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5C6470),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _remainingSeconds / _totalSeconds;
    final isLowTime = _remainingSeconds < 60;

    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
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
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Time Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C6470).withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reading Passage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.flash_on, size: 12, color: Color(0xFFFFA500)),
                    SizedBox(width: 4),
                    Text(
                      'Read quickly!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFA500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ScrollableTextArea(text: _generatedPassage!),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_generatedQuestions!.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Answer all questions based on the passage above',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6470)),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _generatedQuestions!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final question = _generatedQuestions![index];
              return _QuestionWidget(
                questionNumber: index + 1,
                question: question,
                answer: _answers[index],
                onAnswerChanged: (answer) {
                  setState(() {
                    _answers[index] = answer;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitAnswers,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit Answers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_answers.length}/${_generatedQuestions!.length} answered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Center(
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Submitted!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your skimming skills are being analyzed...',
              style: TextStyle(fontSize: 14, color: Color(0xFF5C6470)),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Take Another Test',
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
            'Skimming Test',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.a1:
        return 'A1 Beginner';
      case Difficulty.a2:
        return 'A2 Elementary';
      case Difficulty.b1:
        return 'B1 Intermediate';
      case Difficulty.b2:
        return 'B2 Upper-Intermediate';
      case Difficulty.c1:
        return 'C1 Advanced';
      case Difficulty.c2:
        return 'C2 Proficiency';
      case Difficulty.adaptive:
        return 'Adaptive';
    }
  }

  String _getLengthLabel(PassageLength length) {
    switch (length) {
      case PassageLength.short:
        return 'Short';
      case PassageLength.medium:
        return 'Medium';
      case PassageLength.long:
        return 'Long';
    }
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScrollableTextArea extends StatelessWidget {
  const _ScrollableTextArea({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}

class _QuestionWidget extends StatelessWidget {
  const _QuestionWidget({
    required this.questionNumber,
    required this.question,
    required this.answer,
    required this.onAnswerChanged,
  });

  final int questionNumber;
  final Map<String, dynamic> question;
  final dynamic answer;
  final Function(dynamic) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final questionType = question['type'] as QuestionType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$questionNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(questionType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(questionType),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(questionType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (questionType == QuestionType.multipleChoice)
          _MultipleChoiceOptions(
            options: question['options'],
            selectedOption: answer,
            onSelected: onAnswerChanged,
          )
        else if (questionType == QuestionType.trueFalse)
          _TrueFalseOptions(selectedValue: answer, onSelected: onAnswerChanged)
        else if (questionType == QuestionType.shortAnswer)
          _ShortAnswerInput(value: answer, onChanged: onAnswerChanged),
      ],
    );
  }

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return const Color(0xFF6366F1);
      case QuestionType.trueFalse:
        return const Color(0xFF10B981);
      case QuestionType.shortAnswer:
        return const Color(0xFF2C8FFF);
    }
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
    }
  }
}

class _MultipleChoiceOptions extends StatelessWidget {
  const _MultipleChoiceOptions({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final List<dynamic> options;
  final int? selectedOption;
  final Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final isSelected = selectedOption == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.black.withOpacity(0.08),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF5C6470),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: const Color(0xFF1E293B),
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
}

class _TrueFalseOptions extends StatelessWidget {
  const _TrueFalseOptions({
    required this.selectedValue,
    required this.onSelected,
  });

  final bool? selectedValue;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedValue == true
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedValue == true
                        ? const Color(0xFF10B981)
                        : Colors.black.withOpacity(0.08),
                    width: selectedValue == true ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: selectedValue == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFF5C6470),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'True',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selectedValue == true
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selectedValue == true
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedValue == false
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedValue == false
                        ? const Color(0xFFEF4444)
                        : Colors.black.withOpacity(0.08),
                    width: selectedValue == false ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel,
                      color: selectedValue == false
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF5C6470),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'False',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selectedValue == false
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selectedValue == false
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShortAnswerInput extends StatelessWidget {
  const _ShortAnswerInput({required this.value, required this.onChanged});

  final String? value;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2C8FFF).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            onChanged: onChanged,
            controller: TextEditingController(text: value),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Type your short answer...',
              hintStyle: TextStyle(
                color: const Color(0xFF5C6470).withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                  fontSize: 15,
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

class _LoadingProgressIndicator extends StatelessWidget {
  const _LoadingProgressIndicator({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5C6470),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.selectedLength,
    required this.selectedDifficulty,
    required this.onStart,
    required this.onCancel,
  });

  final PassageLength selectedLength;
  final Difficulty selectedDifficulty;
  final Function(PassageLength, Difficulty) onStart;
  final VoidCallback onCancel;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late PassageLength _length;
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    _length = widget.selectedLength;
    _difficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.5),
                ],
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Test?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure your skimming test',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5C6470),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Passage Length',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SettingChip(
                      label: 'Short (3 min)',
                      isSelected: _length == PassageLength.short,
                      onTap: () =>
                          setState(() => _length = PassageLength.short),
                    ),
                    _SettingChip(
                      label: 'Medium (5 min)',
                      isSelected: _length == PassageLength.medium,
                      onTap: () =>
                          setState(() => _length = PassageLength.medium),
                    ),
                    _SettingChip(
                      label: 'Long (7 min)',
                      isSelected: _length == PassageLength.long,
                      onTap: () => setState(() => _length = PassageLength.long),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Difficulty Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SettingChip(
                      label: 'A1',
                      isSelected: _difficulty == Difficulty.a1,
                      onTap: () => setState(() => _difficulty = Difficulty.a1),
                    ),
                    _SettingChip(
                      label: 'A2',
                      isSelected: _difficulty == Difficulty.a2,
                      onTap: () => setState(() => _difficulty = Difficulty.a2),
                    ),
                    _SettingChip(
                      label: 'B1',
                      isSelected: _difficulty == Difficulty.b1,
                      onTap: () => setState(() => _difficulty = Difficulty.b1),
                    ),
                    _SettingChip(
                      label: 'B2',
                      isSelected: _difficulty == Difficulty.b2,
                      onTap: () => setState(() => _difficulty = Difficulty.b2),
                    ),
                    _SettingChip(
                      label: 'C1',
                      isSelected: _difficulty == Difficulty.c1,
                      onTap: () => setState(() => _difficulty = Difficulty.c1),
                    ),
                    _SettingChip(
                      label: 'C2',
                      isSelected: _difficulty == Difficulty.c2,
                      onTap: () => setState(() => _difficulty = Difficulty.c2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SettingChip(
                  label: 'Adaptive (Based on your results)',
                  icon: Icons.auto_awesome,
                  isSelected: _difficulty == Difficulty.adaptive,
                  onTap: () =>
                      setState(() => _difficulty = Difficulty.adaptive),
                  fullWidth: true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        label: 'Cancel',
                        onTap: widget.onCancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _PrimaryButton(
                        label: 'Start Test',
                        onTap: () => widget.onStart(_length, _difficulty),
                        icon: Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  const _SettingChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.5),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.6),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
