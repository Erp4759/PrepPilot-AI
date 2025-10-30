import 'dart:ui';
import 'package:flutter/material.dart';

enum TestState { initial, loading, test, results }

enum PassageLength { short, medium, long }

enum Difficulty { a1, a2, b1, b2, c1, c2, adaptive }

enum InferenceType {
  tone,
  impliedMeaning,
  characterMotivation,
  causeEffect,
  prediction,
  assumption
}

class ReadingInferenceScreen extends StatefulWidget {
  const ReadingInferenceScreen({super.key});

  static const routeName = '/reading-inference';

  @override
  State<ReadingInferenceScreen> createState() => _ReadingInferenceScreenState();
}

class _ReadingInferenceScreenState extends State<ReadingInferenceScreen> {
  TestState _testState = TestState.initial;
  PassageLength _selectedLength = PassageLength.medium;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data
  String? _generatedPassage;
  List<Map<String, dynamic>>? _generatedQuestions;
  final Map<int, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog();
    });
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

    await Future.delayed(const Duration(seconds: 2));

    _generateMockTest();

    setState(() {
      _testState = TestState.test;
    });
  }

  void _generateMockTest() {
    _generatedPassage = _getMockPassage();
    _generatedQuestions = _getMockQuestions();
    _answers.clear();
  }

  String _getMockPassage() {
    if (_selectedLength == PassageLength.short) {
      return '''Sarah glanced at her watch for the third time in five minutes. The café was nearly empty now, with only the barista wiping down tables in the corner. She stirred her cold coffee absently, her eyes fixed on the door. When her phone buzzed, she grabbed it eagerly, but her face fell as she read the message. She left a few bills on the table—more than enough to cover her drink—and walked out without looking back.''';
    } else if (_selectedLength == PassageLength.medium) {
      return '''The old lighthouse keeper had lived alone for fifteen years, ever since his wife passed away. Visitors to the small coastal town would often see him walking along the shore at dawn, collecting pieces of driftwood and sea glass. He never spoke much to anyone, but every evening, without fail, he would climb the spiral stairs to light the beacon, even though the lighthouse had been officially decommissioned a decade ago.

The townspeople had grown accustomed to his routine. Some called him eccentric; others thought he was stuck in the past. But on stormy nights, fishing boats still looked for that familiar light cutting through the fog, and more than one captain had quietly admitted that it had guided them safely home.''';
    } else {
      return '''Dr. Chen had spent three years developing the algorithm, working late into the night while her colleagues pursued more conventional research paths. When she finally presented her findings at the conference, the room fell silent. Some scientists shifted uncomfortably in their seats; others leaned forward with intense interest. The moderator's hand trembled slightly as he asked the first question.

In the weeks that followed, Dr. Chen's inbox overflowed with emails. Half were from researchers requesting collaboration; the other half were thinly veiled criticisms questioning her methodology. She noticed that her department head, who had initially dismissed her project as "too ambitious," now mentioned it frequently in grant applications. Meanwhile, a major tech company had quietly hired two of her former research assistants.

Dr. Chen continued her work, but she stopped sharing preliminary results at lab meetings. She began arriving at the office earlier than anyone else and leaving after the building was empty. Her closest colleague remarked that she seemed different—more guarded, less willing to engage in the casual brainstorming sessions they once enjoyed.''';
    }
  }

  List<Map<String, dynamic>> _getMockQuestions() {
    if (_selectedDifficulty == Difficulty.a1 ||
        _selectedDifficulty == Difficulty.a2) {
      return [
        {
          'type': InferenceType.impliedMeaning,
          'question':
              'Was Sarah meeting someone at the café? What makes you think so?',
          'hint': 'Think about why she kept checking her watch and watching the door',
        },
        {
          'type': InferenceType.tone,
          'question': 'How did Sarah feel when she read the message?',
          'options': ['Happy', 'Disappointed', 'Excited', 'Angry'],
          'hint': 'Notice what happened to her face',
        },
        {
          'type': InferenceType.causeEffect,
          'question': 'Why did Sarah leave extra money?',
          'hint':
              'Consider how she might have felt and what she was thinking about',
        },
      ];
    } else if (_selectedDifficulty == Difficulty.b1 ||
        _selectedDifficulty == Difficulty.b2) {
      return [
        {
          'type': InferenceType.characterMotivation,
          'question':
              'Why does the lighthouse keeper continue to light the beacon?',
          'options': [
            'He is paid by the town',
            'He feels a sense of duty and purpose',
            'He wants to attract tourists',
            'He is afraid of the dark',
          ],
          'hint': 'Think about his routine and what the light means to others',
        },
        {
          'type': InferenceType.impliedMeaning,
          'question':
              'What does the phrase "stuck in the past" suggest about how some townspeople view him?',
          'hint': 'Consider the context and why they might say this',
        },
        {
          'type': InferenceType.tone,
          'question': 'What is the overall tone of this passage?',
          'options': [
            'Humorous and lighthearted',
            'Reflective and bittersweet',
            'Angry and critical',
            'Mysterious and suspenseful',
          ],
        },
        {
          'type': InferenceType.causeEffect,
          'question':
              'Based on the passage, what can you infer about the relationship between the keeper and the fishing captains?',
          'hint': 'Notice that they still look for his light but stay quiet about it',
        },
      ];
    } else {
      return [
        {
          'type': InferenceType.tone,
          'question':
              'How did the scientific community initially react to Dr. Chen\'s presentation?',
          'options': [
            'Uniformly supportive',
            'Divided and uncertain',
            'Completely dismissive',
            'Enthusiastically excited',
          ],
          'hint': 'Look at the different reactions described in the room',
        },
        {
          'type': InferenceType.characterMotivation,
          'question':
              'Why did Dr. Chen\'s department head suddenly start mentioning her project in grant applications?',
          'hint':
              'Think about what changed and what motivates academics seeking funding',
        },
        {
          'type': InferenceType.impliedMeaning,
          'question':
              'What does the hiring of Dr. Chen\'s research assistants by a tech company suggest?',
          'options': [
            'The company wants to support academic research',
            'The assistants were unhappy with Dr. Chen',
            'The company sees commercial value in her work',
            'The assistants were looking for better pay',
          ],
        },
        {
          'type': InferenceType.assumption,
          'question':
              'What can you infer about why Dr. Chen became more guarded and secretive?',
          'hint':
              'Consider the different reactions to her work and what happened after she shared it',
        },
        {
          'type': InferenceType.prediction,
          'question':
              'Based on the passage, what is likely to happen to Dr. Chen\'s research in the future?',
          'hint':
              'Think about the interest from companies, the mixed academic reception, and her changed behavior',
        },
        {
          'type': InferenceType.causeEffect,
          'question':
              'What does the moderator\'s trembling hand suggest about the significance of Dr. Chen\'s findings?',
          'options': [
            'The findings were expected and routine',
            'The findings were controversial or groundbreaking',
            'The moderator was nervous about public speaking',
            'The room temperature was too cold',
          ],
        },
      ];
    }
  }

  void _submitAnswers() {
    setState(() {
      _testState = TestState.results;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Analyzing your inferences...'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
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
              'AI is creating an inference challenge',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            _LoadingProgressIndicator(
              label: 'Analyzing difficulty...',
              value: 0.33,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Creating nuanced passage...',
              value: 0.66,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Generating inference questions...',
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
                _buildInstructionCard(),
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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inference Test',
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

  Widget _buildInstructionCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How to Make Inferences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InstructionItem(
            icon: Icons.search,
            text: 'Look for clues in the text (actions, descriptions, dialogue)',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.connect_without_contact,
            text: 'Connect clues with your own knowledge and experience',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.psychology,
            text: 'Think about what is implied but not directly stated',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.emoji_objects,
            text: 'Consider tone, mood, and underlying meanings',
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reading Passage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.visibility, size: 12, color: Color(0xFFFFA500)),
                    SizedBox(width: 4),
                    Text(
                      'Read carefully!',
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
                'Inference Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
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
            'Read between the lines and make logical deductions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C6470),
                ),
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
              'Your inferences are being analyzed...',
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
          _SmallBackButton(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 12),
          const Text(
            'Inference Test',
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
              colors: const [Color(0x2810B981), Color(0x28059669)],
              size: 560,
            ),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _Blob(
              colors: const [Color(0x28FFD17C), Color(0x2834D399)],
              size: 460,
            ),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _Blob(
              colors: const [Color(0x2810B981), Color(0x286EE7B7)],
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

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5C6470),
              height: 1.4,
            ),
          ),
        ),
      ],
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
    final inferenceType = question['type'] as InferenceType;
    final hasOptions = question.containsKey('options');
    final hasHint = question.containsKey('hint');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$questionNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
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
                      color: _getTypeColor(inferenceType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(inferenceType),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(inferenceType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasHint) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA500).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFA500).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates,
                  size: 16,
                  color: Color(0xFFFFA500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question['hint'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C6470),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (hasOptions)
          _MultipleChoiceOptions(
            options: question['options'],
            selectedOption: answer,
            onSelected: onAnswerChanged,
          )
        else
          _OpenEndedAnswer(
            value: answer,
            onChanged: onAnswerChanged,
          ),
      ],
    );
  }

  Color _getTypeColor(InferenceType type) {
    switch (type) {
      case InferenceType.tone:
        return const Color(0xFF8B5CF6);
      case InferenceType.impliedMeaning:
        return const Color(0xFF10B981);
      case InferenceType.characterMotivation:
        return const Color(0xFF2C8FFF);
      case InferenceType.causeEffect:
        return const Color(0xFFEF4444);
      case InferenceType.prediction:
        return const Color(0xFFFFA500);
      case InferenceType.assumption:
        return const Color(0xFF06B6D4);
    }
  }

  String _getTypeLabel(InferenceType type) {
    switch (type) {
      case InferenceType.tone:
        return 'Tone & Mood';
      case InferenceType.impliedMeaning:
        return 'Implied Meaning';
      case InferenceType.characterMotivation:
        return 'Character Motivation';
      case InferenceType.causeEffect:
        return 'Cause & Effect';
      case InferenceType.prediction:
        return 'Prediction';
      case InferenceType.assumption:
        return 'Assumptions';
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
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
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
                              ? const Color(0xFF10B981)
                              : const Color(0xFF5C6470),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF10B981)
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

class _OpenEndedAnswer extends StatelessWidget {
  const _OpenEndedAnswer({
    required this.value,
    required this.onChanged,
  });

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
              color: const Color(0xFF10B981).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            onChanged: onChanged,
            controller: TextEditingController(text: value),
            maxLines: 3,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Explain your inference...',
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
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
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
            backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
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
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
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
                            'Configure your inference test',
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                  color: isSelected ? Colors.white : const Color(0xFF10B981),
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
              color: const Color(0xFF10B981).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
