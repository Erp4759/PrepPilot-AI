import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/reading_agent.dart';
import '../../skills/actions/start_test.dart';
import '../../skills/actions/submit_answers_and_check_results.dart';
import '../../../library/results_notifier.dart';
import '../../skills/models/test_properties.dart' as skill_props;

enum TestState { initial, loading, test, results }

enum PassageLength { short, medium, long }

enum Difficulty { a1, a2, b1, b2, c1, c2, adaptive }

class ReadingScanningScreen extends StatefulWidget {
  const ReadingScanningScreen({super.key});

  static const routeName = '/reading-scanning';

  @override
  State<ReadingScanningScreen> createState() => _ReadingScanningScreenState();
}

class _ReadingScanningScreenState extends State<ReadingScanningScreen> {
  TestState _testState = TestState.initial;
  PassageLength _selectedLength = PassageLength.medium;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data (will be generated later with LLM)
  String? _generatedPassage;
  List<Map<String, String>>? _generatedQuestions;
  final Map<int, TextEditingController> _answerControllers = {};

  // LLM agent and results
  final ReadingAgent _agent = ReadingAgent();
  List<ReadingCheckResult>? _checkResults;
  // Server-backed test (if created)
  Map<String, dynamic>? _serverTest;
  int _scoreEarned = 0;
  int _pointsPossible = 0;
  String _overallFeedback = '';

  @override
  void initState() {
    super.initState();
    // Show settings dialog on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog();
    });
  }

  @override
  void dispose() {
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
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
          Navigator.of(context).pop(); // Go back to reading home
        },
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() {
      _testState = TestState.loading;
      _checkResults = null;
    });

    try {
      // Try to create a server-backed test first
      try {
        final skillDifficulty = skill_props.Difficulty.values.firstWhere(
          (d) => d.name == _selectedDifficulty.name,
          orElse: () => skill_props.Difficulty.b1,
        );

        final testMap = await StartTest().execute(
          difficulty: skillDifficulty,
          testType: skill_props.TestType.reading,
          moduleType: skill_props.ReadingModuleType.scanning,
        );

        _serverTest = testMap;
        _generatedPassage =
            testMap['text'] ?? testMap['test_description'] ?? '';
        final serverQuestions = (testMap['questions'] as List<dynamic>?) ?? [];
        _generatedQuestions = serverQuestions
            .map(
              (q) => {
                'question': (q as Map)['question_text']?.toString() ?? '',
                'question_id': (q as Map)['question_id']?.toString() ?? '',
              },
            )
            .toList(growable: false);

        // Initialize controllers
        _answerControllers.clear();
        for (int i = 0; i < _generatedQuestions!.length; i++) {
          _answerControllers[i] = TextEditingController();
        }

        setState(() {
          _testState = TestState.test;
        });
        return;
      } catch (_) {
        _serverTest = null;
      }
      final test = await _agent.generate(
        length: _mapLength(_selectedLength),
        difficulty: _mapDifficulty(_selectedDifficulty),
      );

      _generatedPassage = test.passage;
      _generatedQuestions = test.questions
          .map((q) => {'question': q})
          .toList(growable: false);

      _answerControllers.clear();
      for (int i = 0; i < _generatedQuestions!.length; i++) {
        _answerControllers[i] = TextEditingController();
      }

      setState(() {
        _testState = TestState.test;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = TestState.initial;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate test: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _generateMockTest() {
    // Mock passage based on difficulty
    _generatedPassage = _getMockPassage();
    _generatedQuestions = _getMockQuestions();

    // Initialize answer controllers
    _answerControllers.clear();
    for (int i = 0; i < _generatedQuestions!.length; i++) {
      _answerControllers[i] = TextEditingController();
    }
  }

  String _getMockPassage() {
    // Different passages for different difficulties/lengths
    if (_selectedLength == PassageLength.short) {
      return '''Climate change is one of the most pressing issues of our time. Rising global temperatures are causing ice caps to melt, sea levels to rise, and weather patterns to become more extreme. Scientists agree that human activities, particularly the burning of fossil fuels, are the primary cause of recent climate change.''';
    } else if (_selectedLength == PassageLength.medium) {
      return '''The invention of the printing press by Johannes Gutenberg in 1440 revolutionized the spread of information in Europe. Before this innovation, books were copied by hand, making them expensive and rare. The printing press allowed for mass production of books, which led to increased literacy rates and the rapid dissemination of new ideas during the Renaissance.

The impact of the printing press extended far beyond just making books more available. It played a crucial role in the Protestant Reformation, as Martin Luther's 95 Theses could be quickly reproduced and distributed throughout Europe. The technology also facilitated the Scientific Revolution by allowing scientists to share their discoveries more easily.''';
    } else {
      return '''The human brain is perhaps the most complex organ in the known universe, containing approximately 86 billion neurons. Each neuron can form thousands of connections with other neurons, creating an intricate network that enables thought, memory, emotion, and consciousness. Neuroscientists have made significant progress in understanding brain function, but many mysteries remain.

Recent advances in brain imaging technology, such as functional MRI and PET scans, have allowed researchers to observe the brain in action. These tools have revealed that different regions of the brain specialize in different functions. For example, the hippocampus is crucial for forming new memories, while the amygdala processes emotions, particularly fear and anxiety.

The concept of neuroplasticity has transformed our understanding of the brain. Previously, scientists believed that the adult brain was relatively fixed and unchangeable. However, research has shown that the brain can reorganize itself by forming new neural connections throughout life. This discovery has important implications for recovery from brain injuries and for learning new skills at any age.''';
    }
  }

  List<Map<String, String>> _getMockQuestions() {
    // Mock questions (will be generated by LLM later)
    if (_selectedDifficulty == Difficulty.a1 ||
        _selectedDifficulty == Difficulty.a2) {
      return [
        {'question': 'What year was the printing press invented?'},
        {'question': 'Who invented the printing press?'},
        {'question': 'What happened to book prices after the invention?'},
      ];
    } else if (_selectedDifficulty == Difficulty.b1 ||
        _selectedDifficulty == Difficulty.b2) {
      return [
        {
          'question':
              'According to the passage, what was the main limitation of books before the printing press?',
        },
        {
          'question':
              'How did the printing press contribute to the Protestant Reformation?',
        },
        {
          'question':
              'What role did the printing press play in the Scientific Revolution?',
        },
        {'question': 'What effect did the printing press have on literacy?'},
      ];
    } else {
      return [
        {
          'question':
              'Explain how the printing press transformed the dissemination of knowledge in Renaissance Europe.',
        },
        {
          'question':
              'Analyze the relationship between the printing press and religious reform movements.',
        },
        {
          'question':
              'What broader societal changes resulted from the mass production of printed materials?',
        },
        {
          'question':
              'How did the printing press facilitate scientific progress beyond simply publishing findings?',
        },
        {
          'question':
              'Compare the impact of the printing press to modern information technologies.',
        },
      ];
    }
  }

  Future<void> _submitAnswers() async {
    if (_generatedPassage == null || _generatedQuestions == null) return;

    final answers = List<String>.generate(
      _generatedQuestions!.length,
      (i) => _answerControllers[i]?.text.trim() ?? '',
    );

    setState(() {
      _testState = TestState.loading;
    });

    try {
      // If this test was created on the server, submit answers to backend
      if (_serverTest != null) {
        try {
          final answersMap = <String, String>{};
          for (var i = 0; i < _generatedQuestions!.length; i++) {
            final q = _generatedQuestions![i];
            final qid = q['question_id']?.toString() ?? '';
            final userAns = answers[i];
            if (qid.isNotEmpty) answersMap[qid] = userAns;
          }

          final testId = _serverTest!['test_id'] as String;
          final submission = await SubmitAnswersAndCheckResults().submitAnswers(
            testId: testId,
            answers: answersMap,
          );

          final resultId = submission['result_id'] as String;
          final fullResult = await SubmitAnswersAndCheckResults().fetchResult(
            resultId: resultId,
          );

          // Map detailed_answers to ReadingCheckResult list
          final detailed =
              (fullResult['detailed_answers'] as List<dynamic>?) ?? [];
          _checkResults = detailed.map((d) {
            final m = Map<String, dynamic>.from(d as Map);
            return ReadingCheckResult(
              index: (m['question_num'] as num).toInt() - 1,
              isCorrect: m['is_correct'] == true,
              expected: (m['correct_answer'] ?? '').toString(),
              feedback: (m['feedback'] ?? '').toString(),
              score: (m['points_earned'] as num?)?.toInt() ?? 0,
            );
          }).toList();

          _scoreEarned = fullResult['score'] is num
              ? (fullResult['score'] as num).toInt()
              : 0;
          _pointsPossible = fullResult['total_points'] is num
              ? (fullResult['total_points'] as num).toInt()
              : (_generatedQuestions?.length ?? 0);
          _overallFeedback = fullResult['feedback_text'] ?? '';

          // Notify results list
          ResultsNotifier.instance.notifyNewResult(resultId);

          setState(() {
            _testState = TestState.results;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Results saved to server'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );

          return;
        } catch (serverErr) {
          // fall back to local checking
        }
      }

      final results = await _agent.checkAnswers(
        passage: _generatedPassage!,
        questions: _generatedQuestions!.map((e) => e['question']!).toList(),
        answers: answers,
      );
      setState(() {
        _checkResults = results;
        _testState = TestState.results;
      });
      if (!mounted) return;
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
      setState(() {
        _testState = TestState.test;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check answers: $e'),
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
        return const SizedBox(); // Settings dialog shows automatically
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
                  colors: [Color(0xFF2C8FFF), Color(0xFF06B6D4)],
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
              'Generating your test...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'AI is creating a passage and questions',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            _LoadingProgressIndicator(
              label: 'Analyzing difficulty level...',
              value: 0.33,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Generating passage...',
              value: 0.66,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Creating questions...',
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
                colors: [Color(0xFF2C8FFF), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanning Test',
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
                  color: const Color(0xFF2C8FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reading Passage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C8FFF),
                  ),
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
                  color: const Color(0xFF2C8FFF),
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
              return _QuestionAnswerItem(
                questionNumber: index + 1,
                question: _generatedQuestions![index]['question']!,
                controller: _answerControllers[index]!,
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
                      '${_generatedQuestions!.length} question${_generatedQuestions!.length > 1 ? 's' : ''} ready',
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
    final total = _generatedQuestions?.length ?? 0;
    final correct = _checkResults?.where((r) => r.isCorrect).length ?? 0;
    return Center(
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$correct of $total correct',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5C6470),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_checkResults != null) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              ..._checkResults!.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (r.isCorrect
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          r.isCorrect ? Icons.check : Icons.close,
                          size: 16,
                          color: r.isCorrect
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${r.index + 1}: ${_generatedQuestions![r.index]['question']!}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (r.feedback.isNotEmpty)
                              Text(
                                r.feedback,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5C6470),
                                ),
                              ),
                            if (r.expected.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Expected: ${r.expected}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
          _SmallBackButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          const Text(
            'Scanning Test',
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

  ReadingLength _mapLength(PassageLength l) {
    switch (l) {
      case PassageLength.short:
        return ReadingLength.short;
      case PassageLength.medium:
        return ReadingLength.medium;
      case PassageLength.long:
        return ReadingLength.long;
    }
  }

  ReadingDifficulty _mapDifficulty(Difficulty d) {
    switch (d) {
      case Difficulty.a1:
        return ReadingDifficulty.a1;
      case Difficulty.a2:
        return ReadingDifficulty.a2;
      case Difficulty.b1:
        return ReadingDifficulty.b1;
      case Difficulty.b2:
        return ReadingDifficulty.b2;
      case Difficulty.c1:
        return ReadingDifficulty.c1;
      case Difficulty.c2:
        return ReadingDifficulty.c2;
      case Difficulty.adaptive:
        return ReadingDifficulty.adaptive;
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
              colors: const [Color(0x2882CEFF), Color(0x28B78DFF)],
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
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          // Scroll indicators
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C8FFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      size: 16,
                      color: Color(0xFF2C8FFF),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Scroll',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C8FFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C8FFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF2C8FFF),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C8FFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2C8FFF).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: const Color(0xFF5C6470).withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
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
              colors: [Color(0xFF2C8FFF), Color(0xFF1E6FD9)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C8FFF).withOpacity(0.3),
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onTap, required this.questionsCount});

  final VoidCallback onTap;
  final int questionsCount;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                      '$questionsCount question${questionsCount > 1 ? 's' : ''} ready',
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
}

class _QuestionItem extends StatelessWidget {
  const _QuestionItem({
    required this.question,
    required this.index,
    required this.onRemove,
  });

  final String question;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2C8FFF).withOpacity(0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C8FFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C8FFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2C8FFF).withOpacity(0.2),
                ),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF2C8FFF)),
            ),
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
                          colors: [Color(0xFF2C8FFF), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
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
                            'Configure your scanning test',
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
                      label: 'Short',
                      isSelected: _length == PassageLength.short,
                      onTap: () =>
                          setState(() => _length = PassageLength.short),
                    ),
                    _SettingChip(
                      label: 'Medium',
                      isSelected: _length == PassageLength.medium,
                      onTap: () =>
                          setState(() => _length = PassageLength.medium),
                    ),
                    _SettingChip(
                      label: 'Long',
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
                    colors: [Color(0xFF2C8FFF), Color(0xFF06B6D4)],
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
                  color: isSelected ? Colors.white : const Color(0xFF2C8FFF),
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
            backgroundColor: const Color(0xFF2C8FFF).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2C8FFF)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _QuestionAnswerItem extends StatelessWidget {
  const _QuestionAnswerItem({
    required this.questionNumber,
    required this.question,
    required this.controller,
  });

  final int questionNumber;
  final String question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C8FFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$questionNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C8FFF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
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
                controller: controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF5C6470).withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ),
      ],
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
              color: const Color(0xFF2C8FFF).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C8FFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
