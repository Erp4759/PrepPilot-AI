import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:prep_pilot_ai/src/services/ai_agent.dart';
import 'dart:convert';
import '../../skills/actions/start_test.dart';
import '../../skills/actions/submit_answers_and_check_results.dart';
import '../../../library/results_notifier.dart';
import '../../skills/models/test_properties.dart' as skill_props;

enum TestState { initial, loading, test, results }

enum PassageLength { short, medium, long }

enum Difficulty { a1, a2, b1, b2, c1, c2, adaptive }

enum KeywordType {
  mainTopic,
  supportingDetail,
  technicalTerm,
  action,
  descriptive,
}

class ReadingKeywordsScreen extends StatefulWidget {
  const ReadingKeywordsScreen({super.key});

  static const routeName = '/reading-keywords';

  @override
  State<ReadingKeywordsScreen> createState() => _ReadingKeywordsScreenState();
}

class _ReadingKeywordsScreenState extends State<ReadingKeywordsScreen> {
  TestState _testState = TestState.initial;
  PassageLength _selectedLength = PassageLength.medium;
  Difficulty _selectedDifficulty = Difficulty.b1;

  // Test data
  String? _generatedPassage;
  List<String>? _passageWords;
  Set<int> _selectedWordIndices = {};
  List<Map<String, dynamic>>? _generatedQuestions;
  final Map<int, dynamic> _answers = {};
  // Server-backed test (if created)
  Map<String, dynamic>? _serverTest;
  int _scoreEarned = 0;
  int _pointsPossible = 0;
  String _overallFeedback = '';

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
          moduleType: skill_props.ReadingModuleType.keywords,
        );

        _serverTest = testMap;
        _generatedPassage =
            testMap['text'] ?? testMap['test_description'] ?? '';
        _passageWords = _splitIntoWords(_generatedPassage!);

        final serverQuestions = (testMap['questions'] as List<dynamic>?) ?? [];
        _generatedQuestions = serverQuestions
            .map((q) {
              final mq = Map<String, dynamic>.from(q as Map);
              mq['question_id'] = mq['question_id']?.toString() ?? '';
              mq['question'] =
                  mq['question_text']?.toString() ??
                  mq['question']?.toString() ??
                  '';
              if (mq.containsKey('options') &&
                  mq['options'] != null &&
                  mq['options'] is! List) {
                try {
                  mq['options'] = List<dynamic>.from(mq['options']);
                } catch (_) {
                  mq['options'] = <dynamic>[];
                }
              }
              if (mq.containsKey('targetCount') && mq['targetCount'] is num)
                mq['targetCount'] = (mq['targetCount'] as num).toInt();
              return mq;
            })
            .toList(growable: false);

        _selectedWordIndices.clear();
        _answers.clear();
        setState(() {
          _testState = TestState.test;
        });
        return;
      } catch (_) {
        _serverTest = null;
      }
      final difficultyLabel = _selectedDifficulty.name.toUpperCase();
      final lengthLabel = switch (_selectedLength) {
        PassageLength.short => 'short (40-80 words)',
        PassageLength.medium => 'medium (120-220 words)',
        PassageLength.long => 'long (300-450 words)',
      };

      final prompt =
          '''You are an exam item writer for KEYWORD IDENTIFICATION tasks.
Create a passage and keyword-based tasks.

Constraints:
- CEFR level: $difficultyLabel
- Passage length: $lengthLabel
- Return JSON only with this shape:
{"passage":"...","questions":[{"type":"keyword_selection|multiple_choice|categorize|open_ended","question":"...","options":[...],"targetCount":3}, ...]}
Do NOT reuse character names from examples (e.g. Sarah, Dr. Chen, Maria). Vary topic each time.
''';

      final parsed = await aiJson<Map<String, dynamic>>(
        userPrompt: prompt,
        system: 'Return JSON only. No prose. Use double quotes. Vary topics.',
        temperature: 0.8,
        maxTokens: 1200,
      );

      _generatedPassage = (parsed['passage'] as String).trim();
      _passageWords = _splitIntoWords(_generatedPassage!);

      final qRaw = (parsed['questions'] as List).cast<dynamic>();
      _generatedQuestions = qRaw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);

        // Ensure type is string and options is list when present
        if (m['type'] is! String) m['type'] = m['type'].toString();
        if (m.containsKey('options') &&
            m['options'] != null &&
            m['options'] is! List) {
          try {
            m['options'] = List<dynamic>.from(m['options']);
          } catch (_) {
            m['options'] = <dynamic>[];
          }
        }

        // Ensure numeric fields are ints
        if (m.containsKey('targetCount') && m['targetCount'] is num) {
          m['targetCount'] = (m['targetCount'] as num).toInt();
        }

        return m;
      }).toList();

      _selectedWordIndices.clear();
      _answers.clear();

      setState(() {
        _testState = TestState.test;
      });
    } catch (e) {
      _generateMockTest();
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
    _passageWords = _splitIntoWords(_generatedPassage!);
    _generatedQuestions = _getMockQuestions();
    _selectedWordIndices.clear();
    _answers.clear();
  }

  List<String> _splitIntoWords(String text) {
    // Split text into words while preserving punctuation
    final regex = RegExp(r"[\w']+|[.,!?;:]");
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  String _getMockPassage() {
    if (_selectedLength == PassageLength.short) {
      return '''Renewable energy sources, such as solar panels and wind turbines, are becoming increasingly important in the fight against climate change. Unlike fossil fuels, these sustainable alternatives produce minimal carbon emissions and can be replenished naturally.''';
    } else if (_selectedLength == PassageLength.medium) {
      return '''Artificial intelligence has revolutionized numerous industries through machine learning algorithms and neural networks. These sophisticated systems can analyze vast datasets, recognize complex patterns, and make autonomous decisions with remarkable accuracy. However, ethical concerns about bias, privacy, and accountability remain significant challenges that developers must address carefully.''';
    } else {
      return '''The human microbiome consists of trillions of microorganisms inhabiting various body sites, predominantly the gastrointestinal tract. These symbiotic bacteria play crucial roles in digestion, immune system regulation, and even mental health through the gut-brain axis. Recent research has revealed that dietary habits, antibiotic use, and environmental factors significantly influence microbiome composition. Scientists are now investigating probiotic interventions and fecal microbiota transplantation as potential therapeutic strategies for treating inflammatory bowel disease, obesity, and neurological disorders.''';
    }
  }

  List<Map<String, dynamic>> _getMockQuestions() {
    if (_selectedDifficulty == Difficulty.a1 ||
        _selectedDifficulty == Difficulty.a2) {
      return [
        {
          'type': 'multiple_choice',
          'question': 'What is the main topic of this passage?',
          'options': [
            'Renewable energy',
            'Climate change',
            'Fossil fuels',
            'Solar panels',
          ],
        },
        {
          'type': 'keyword_selection',
          'question':
              'Select THREE keywords that best represent the main topic',
          'targetCount': 3,
        },
        {
          'type': 'categorize',
          'question': 'Which words are examples of renewable energy sources?',
          'options': [
            'solar panels',
            'wind turbines',
            'fossil fuels',
            'carbon emissions',
          ],
          'correctIndices': [0, 1],
        },
      ];
    } else if (_selectedDifficulty == Difficulty.b1 ||
        _selectedDifficulty == Difficulty.b2) {
      return [
        {
          'type': 'keyword_selection',
          'question':
              'Select FIVE key technical terms related to artificial intelligence',
          'targetCount': 5,
        },
        {
          'type': 'multiple_choice',
          'question':
              'Which keyword best summarizes the main challenge mentioned?',
          'options': ['algorithms', 'ethical concerns', 'accuracy', 'datasets'],
        },
        {
          'type': 'categorize',
          'question': 'Identify words that describe AI capabilities:',
          'options': [
            'analyze',
            'recognize',
            'make decisions',
            'bias',
            'privacy',
            'developers',
          ],
          'correctIndices': [0, 1, 2],
        },
        {
          'type': 'open_ended',
          'question':
              'List three action verbs (keywords) that describe what AI systems do',
        },
      ];
    } else {
      return [
        {
          'type': 'keyword_selection',
          'question':
              'Select SEVEN scientific/technical keywords from the passage',
          'targetCount': 7,
        },
        {
          'type': 'categorize',
          'question':
              'Categorize these keywords - which are medical/therapeutic terms?',
          'options': [
            'microbiome',
            'probiotic',
            'fecal microbiota transplantation',
            'inflammatory bowel disease',
            'dietary habits',
            'gastrointestinal tract',
            'research',
            'obesity',
          ],
          'correctIndices': [1, 2, 3, 7],
        },
        {
          'type': 'multiple_choice',
          'question':
              'What is the central concept that connects all keywords in this passage?',
          'options': [
            'Human microbiome and health',
            'Bacteria and disease',
            'Diet and nutrition',
            'Medical research methods',
          ],
        },
        {
          'type': 'open_ended',
          'question':
              'Identify the relationship between these keywords: microbiome, gut-brain axis, mental health',
        },
      ];
    }
  }

  void _submitAnswers() {
    _analyzeKeywordAnswers();
  }

  Future<void> _analyzeKeywordAnswers() async {
    if (_generatedPassage == null || _generatedQuestions == null) return;

    setState(() {
      _testState = TestState.loading;
    });

    // If server-backed test exists, attempt server submission first
    if (_serverTest != null) {
      try {
        final answersMap = <String, dynamic>{};
        for (var i = 0; i < _generatedQuestions!.length; i++) {
          final q = _generatedQuestions![i];
          final qid = q['question_id']?.toString() ?? '';
          final type = q['type']?.toString() ?? '';
          if (qid.isEmpty) continue;

          if (type == 'keyword_selection') {
            final selectedWords = _selectedWordIndices
                .map((idx) => _passageWords![idx])
                .toList();
            answersMap[qid] = {
              'selected_keywords': selectedWords,
              'targetCount': q['targetCount'] ?? null,
            };
          } else if (type == 'categorize') {
            final ans = _answers.containsKey(i) ? _answers[i] : <int>{};
            if (ans is Set) {
              answersMap[qid] = {
                'selected_indices': (ans as Set<int>).toList(),
              };
            }
          } else if (type == 'multiple_choice' || type == 'open_ended') {
            answersMap[qid] = {
              'user_answer': _answers.containsKey(i) ? _answers[i] : null,
            };
          }
        }

        final testId = _serverTest!['test_id'] as String;
        final submission = await SubmitAnswersAndCheckResults().submitAnswers(
          testId: testId,
          // Convert values to strings where appropriate; backend expects Map<String,String>
          answers: answersMap.map(
            (k, v) => MapEntry(k.toString(), v is String ? v : jsonEncode(v)),
          ),
        );

        final resultId = submission['result_id'] as String;
        final fullResult = await SubmitAnswersAndCheckResults().fetchResult(
          resultId: resultId,
        );

        final detailed =
            (fullResult['detailed_answers'] as List<dynamic>?) ?? [];
        for (final d in detailed) {
          final m = Map<String, dynamic>.from(d as Map);
          final qNum = (m['question_num'] as num?)?.toInt() ?? -1;
          final idx = qNum > 0 ? qNum - 1 : -1;
          if (idx >= 0 && idx < _generatedQuestions!.length) {
            _generatedQuestions![idx]['_is_correct'] = m['is_correct'];
            _generatedQuestions![idx]['_expected'] = (m['correct_answer'] ?? '')
                .toString();
            _generatedQuestions![idx]['_feedback'] = (m['feedback'] ?? '')
                .toString();
            _generatedQuestions![idx]['_score'] =
                (m['points_earned'] as num?)?.toInt() ?? 0;
          }
        }

        _scoreEarned = fullResult['score'] is num
            ? (fullResult['score'] as num).toInt()
            : 0;
        _pointsPossible = fullResult['total_points'] is num
            ? (fullResult['total_points'] as num).toInt()
            : (_generatedQuestions?.length ?? 0);
        _overallFeedback = fullResult['feedback_text'] ?? '';

        ResultsNotifier.instance.notifyNewResult(resultId);

        if (!mounted) return;
        setState(() {
          _testState = TestState.results;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results saved to server'),
            backgroundColor: Color(0xFFFFA500),
          ),
        );

        return;
      } catch (_) {
        // fall back to local grading
      }
    }

    // Build payload
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _generatedQuestions!.length; i++) {
      final q = _generatedQuestions![i];
      final type = q['type'] as String;
      final Map<String, dynamic> item = {
        'index': i,
        'type': type,
        'question': q['question'],
        'options': q['options'] ?? [],
      };

      if (type == 'keyword_selection') {
        final selectedWords = _selectedWordIndices
            .map((idx) => _passageWords![idx])
            .toList();
        item['selected_keywords'] = selectedWords;
        item['targetCount'] = q['targetCount'] ?? null;
      } else if (type == 'categorize') {
        final ans = _answers.containsKey(i) ? _answers[i] : <int>{};
        if (ans is Set) {
          item['selected_indices'] = ans.toList();
          item['selected_words'] = (ans as Set<int>)
              .map((idx) => _passageWords![idx])
              .toList();
        }
      } else if (type == 'multiple_choice') {
        item['user_answer'] = _answers.containsKey(i) ? _answers[i] : null;
      } else if (type == 'open_ended') {
        item['user_answer'] = _answers.containsKey(i) ? _answers[i] : null;
      }

      items.add(item);
    }

    final prompt =
        '''You are an automated grader for KEYWORD IDENTIFICATION tasks.
Given the passage and submitted answers, evaluate each item. For keyword selection tasks, check whether the selected words correctly represent the main topics or requested categories. Return JSON array only: [{"index":0,"is_correct":true|false,"expected":"comma separated expected keywords","feedback":"brief feedback","score":0|1}, ...]

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
          backgroundColor: const Color(0xFFFFA500),
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
      _selectedWordIndices.clear();
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
                  colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
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
              'AI is creating a keyword challenge',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            _LoadingProgressIndicator(label: 'Selecting topic...', value: 0.33),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Generating passage with key terms...',
              value: 0.66,
            ),
            const SizedBox(height: 12),
            _LoadingProgressIndicator(
              label: 'Creating keyword tasks...',
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
                _buildInteractivePassageCard(),
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
                colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.key, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keyword Identification',
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
                  color: const Color(0xFFFFA500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFFA500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How to Identify Keywords',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InstructionItem(
            icon: Icons.star,
            text: 'Look for words that carry the main meaning',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.science,
            text: 'Identify technical terms and specialized vocabulary',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.repeat,
            text: 'Notice words that repeat or appear frequently',
          ),
          const SizedBox(height: 8),
          _InstructionItem(
            icon: Icons.category,
            text: 'Find words that represent main topics and concepts',
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePassageCard() {
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
                  color: const Color(0xFFFFA500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Interactive Passage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFA500),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C8FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: const Color(0xFF2C8FFF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap words to select',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C8FFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedWordIndices.length}',
                      style: const TextStyle(
                        fontSize: 12,
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
          _InteractivePassage(
            words: _passageWords!,
            selectedIndices: _selectedWordIndices,
            onWordTap: (index) {
              setState(() {
                if (_selectedWordIndices.contains(index)) {
                  _selectedWordIndices.remove(index);
                } else {
                  _selectedWordIndices.add(index);
                }
              });
            },
          ),
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
                'Keyword Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500),
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
            'Complete the tasks below to demonstrate keyword identification',
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
                colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA500).withOpacity(0.3),
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
                      '${_selectedWordIndices.length} keywords + ${_answers.length} tasks',
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
    final scoreSum =
        _generatedQuestions?.fold<int>(0, (acc, q) {
          final s = q['_score'];
          if (s is num) return acc + s.toInt();
          return acc + 0;
        }) ??
        0;

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
                  colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Results: $scoreSum / $total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Review the AI feedback and expected keywords below',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5C6470)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              width: 520,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _generatedQuestions?.length ?? 0,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, idx) {
                  final q = _generatedQuestions![idx];
                  final isCorrect = q['_is_correct'] == true;
                  final expected = q['_expected'] ?? '';
                  final feedback = q['_feedback'] ?? '';

                  String userAnswer;
                  final type = q['type'] as String;
                  if (type == 'keyword_selection') {
                    final selected = _selectedWordIndices
                        .map((i) => _passageWords![i])
                        .toList();
                    userAnswer = selected.join(', ');
                  } else if (_answers.containsKey(idx)) {
                    userAnswer = _answers[idx].toString();
                  } else {
                    userAnswer = '—';
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCorrect
                          ? const Color(0xFFFFA500)
                          : const Color(0xFFEF4444),
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(q['question'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Your answer: $userAnswer',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expected: $expected',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Feedback: $feedback',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5C6470),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
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
            'Keyword Identification',
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
              colors: const [Color(0x28FFA500), Color(0x28FF8C00)],
              size: 560,
            ),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _Blob(
              colors: const [Color(0x28FFD17C), Color(0x28FFA500)],
              size: 460,
            ),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _Blob(
              colors: const [Color(0x28FFBF69), Color(0x28FF8C00)],
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

class _InteractivePassage extends StatelessWidget {
  const _InteractivePassage({
    required this.words,
    required this.selectedIndices,
    required this.onWordTap,
  });

  final List<String> words;
  final Set<int> selectedIndices;
  final Function(int) onWordTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(words.length, (index) {
          final word = words[index];
          final isSelected = selectedIndices.contains(index);
          final isPunctuation = RegExp(r'^[.,!?;:]$').hasMatch(word);

          if (isPunctuation) {
            return Text(
              word,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF1E293B),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onWordTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFA500)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: const Color(0xFFFF8C00), width: 2)
                    : null,
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
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
        Icon(icon, size: 16, color: const Color(0xFFFFA500)),
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
    final questionType = question['type'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$questionNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFA500),
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
        if (questionType == 'multiple_choice')
          _MultipleChoiceOptions(
            options: question['options'],
            selectedOption: answer,
            onSelected: onAnswerChanged,
          )
        else if (questionType == 'categorize')
          _CategorizeOptions(
            options: question['options'],
            selectedIndices: answer ?? <int>{},
            onToggle: (index) {
              final current = (answer as Set<int>?) ?? <int>{};
              final updated = Set<int>.from(current);
              if (updated.contains(index)) {
                updated.remove(index);
              } else {
                updated.add(index);
              }
              onAnswerChanged(updated);
            },
          )
        else if (questionType == 'keyword_selection')
          _KeywordSelectionHint(targetCount: question['targetCount'])
        else if (questionType == 'open_ended')
          _OpenEndedAnswer(value: answer, onChanged: onAnswerChanged),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return const Color(0xFF2C8FFF);
      case 'categorize':
        return const Color(0xFF10B981);
      case 'keyword_selection':
        return const Color(0xFFFFA500);
      case 'open_ended':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF5C6470);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'categorize':
        return 'Categorize';
      case 'keyword_selection':
        return 'Select from Passage Above';
      case 'open_ended':
        return 'Open Response';
      default:
        return 'Question';
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
                      ? const Color(0xFFFFA500).withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFA500)
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
                              ? const Color(0xFFFFA500)
                              : const Color(0xFF5C6470),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFFFFA500)
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

class _CategorizeOptions extends StatelessWidget {
  const _CategorizeOptions({
    required this.options,
    required this.selectedIndices,
    required this.onToggle,
  });

  final List<dynamic> options;
  final Set<int> selectedIndices;
  final Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndices.contains(index);
        return GestureDetector(
          onTap: () => onToggle(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : Colors.black.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                Text(
                  options[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _KeywordSelectionHint extends StatelessWidget {
  const _KeywordSelectionHint({required this.targetCount});

  final int targetCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C8FFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C8FFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app, size: 20, color: Color(0xFF2C8FFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap $targetCount words in the passage above to select them as keywords',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenEndedAnswer extends StatelessWidget {
  const _OpenEndedAnswer({required this.value, required this.onChanged});

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
              color: const Color(0xFFFFA500).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            onChanged: onChanged,
            controller: TextEditingController(text: value),
            maxLines: 3,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Type your answer...',
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
              colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withOpacity(0.3),
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
            backgroundColor: const Color(0xFFFFA500).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
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
                          colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.key,
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
                            'Configure your keyword test',
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
                    colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
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
                  color: isSelected ? Colors.white : const Color(0xFFFFA500),
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
              color: const Color(0xFFFFA500).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFA500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
