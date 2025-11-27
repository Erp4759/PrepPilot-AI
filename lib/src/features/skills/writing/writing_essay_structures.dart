import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

class WritingEssayStructuresScreen extends StatefulWidget {
  const WritingEssayStructuresScreen({super.key});

  static const routeName = '/writing_essay_structures';

  @override
  State<WritingEssayStructuresScreen> createState() =>
      _WritingEssayStructuresScreenState();
}

enum TestState { initial, loading, test, results }

class _WritingEssayStructuresScreenState
    extends State<WritingEssayStructuresScreen> {
  TestState _testState = TestState.initial;
  bool _isSubmitting = false;

  // Problem 1: Paragraph Reordering
  late List<String> _p1Paragraphs;
  final List<String> _p1CorrectOrder = [
    "Remote work has become increasingly popular in recent years, transforming the traditional office landscape.",
    "First, it offers significant flexibility, allowing employees to balance their professional and personal lives more effectively.",
    "However, remote work can also lead to feelings of isolation and a lack of immediate collaboration with colleagues.",
    "In conclusion, while remote work presents challenges, its benefits for work-life balance make it a valuable option for many."
  ];

  // Problem 2: Outline Filling
  final String _p2Topic = "The Impact of Technology on Education";
  final List<Map<String, dynamic>> _p2Outline = [
    {
      "type": "text",
      "content": "I. Introduction\n   A. Technology is transforming classrooms globally."
    },
    {"type": "input", "label": "B. Thesis Statement", "controller": TextEditingController()},
    {
      "type": "text",
      "content": "II. Benefits\n   A. Access to unlimited information."
    },
    {"type": "input", "label": "B. Supporting Detail (Interactive Learning)", "controller": TextEditingController()},
    {"type": "text", "content": "III. Conclusion\n   A. Summary of main points."}
  ];

  // Problem 3: Unnecessary Sentence
  final String _p3Text =
      "A balanced diet is crucial for maintaining good health. It provides the body with essential nutrients, vitamins, and minerals needed to function correctly. Cars require regular oil changes to run smoothly and avoid engine damage. Eating a variety of fruits and vegetables reduces the risk of chronic diseases and boosts the immune system.";
  final TextEditingController _p3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  @override
  void dispose() {
    for (var item in _p2Outline) {
      if (item['type'] == 'input') {
        (item['controller'] as TextEditingController).dispose();
      }
    }
    _p3Controller.dispose();
    super.dispose();
  }

  void _initializeTest() {
    // Shuffle paragraphs for Problem 1
    _p1Paragraphs = List.from(_p1CorrectOrder)..shuffle();
    // Ensure it's not in the correct order by chance (simple check)
    if (_p1Paragraphs.join() == _p1CorrectOrder.join()) {
      _p1Paragraphs.shuffle();
    }

    setState(() {
      _testState = TestState.test;
    });
  }

  Future<void> _submitTest() async {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate AI evaluation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
      _testState = TestState.results;
    });
  }

  void _restartTest() {
    setState(() {
      _testState = TestState.initial;
      _p3Controller.clear();
      for (var item in _p2Outline) {
        if (item['type'] == 'input') {
          (item['controller'] as TextEditingController).clear();
        }
      }
    });
    _initializeTest();
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
    if (_testState == TestState.results) {
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
                _buildProblem1(),
                const SizedBox(height: 32),
                _buildProblem2(),
                const SizedBox(height: 32),
                _buildProblem3(),
                const SizedBox(height: 40),
                _PrimaryButton(
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _SmallBackButton(
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Essay Structures',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 1: Reordering
  // ---------------------------------------------------------------------------
  Widget _buildProblem1() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 1: Paragraph Ordering',
              'Drag and drop the paragraphs to form a coherent essay.'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            clipBehavior: Clip.hardEdge,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _p1Paragraphs.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final String item = _p1Paragraphs.removeAt(oldIndex);
                  _p1Paragraphs.insert(newIndex, item);
                });
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(_p1Paragraphs[index]),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: index < _p1Paragraphs.length - 1
                          ? BorderSide(color: Colors.black.withOpacity(0.05))
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.drag_indicator,
                          color: Colors.black.withOpacity(0.2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _p1Paragraphs[index],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 2: Outline Filling
  // ---------------------------------------------------------------------------
  Widget _buildProblem2() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 2: Complete the Outline',
              'Fill in the missing parts of the outline for the topic: "$_p2Topic"'),
          const SizedBox(height: 16),
          ..._p2Outline.map((item) {
            if (item['type'] == 'text') {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item['content'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: item['controller'],
                  decoration: InputDecoration(
                    labelText: item['label'],
                    labelStyle: TextStyle(color: const Color(0xFF6366F1).withOpacity(0.8)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 3: Unnecessary Sentence
  // ---------------------------------------------------------------------------
  Widget _buildProblem3() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 3: Identify Irrelevant Info',
              'Read the text below and identify the sentence that does not belong.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Text(
              _p3Text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _p3Controller,
            decoration: InputDecoration(
              hintText: 'Type the unnecessary sentence here...',
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF6366F1)),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF5C6470).withOpacity(0.8),
          ),
        ),
      ],
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
              'Your answers have been analyzed.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: 'Try Again',
              onTap: _restartTest,
              icon: Icons.refresh,
            ),
            const SizedBox(height: 16),
            _SecondaryButton(
              label: 'Back to Menu',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS (Reused Theme)
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

