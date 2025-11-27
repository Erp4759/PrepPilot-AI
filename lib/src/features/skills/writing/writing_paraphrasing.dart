import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

class WritingParaphrasingScreen extends StatefulWidget {
  const WritingParaphrasingScreen({super.key});

  static const routeName = '/writing_paraphrasing';

  @override
  State<WritingParaphrasingScreen> createState() =>
      _WritingParaphrasingScreenState();
}

enum TestState { initial, loading, test, results }

class _WritingParaphrasingScreenState extends State<WritingParaphrasingScreen> {
  TestState _testState = TestState.initial;
  bool _isSubmitting = false;

  // Problem 1: Synonym Replacement
  final String _p1SentencePart1 = "The ";
  final String _p1Word1 = "fundamental";
  final String _p1SentencePart2 = " principles of the theory are ";
  final String _p1Word2 = "complex";
  final String _p1SentencePart3 = ".";
  final TextEditingController _p1Controller1 = TextEditingController();
  final TextEditingController _p1Controller2 = TextEditingController();

  // Problem 2: Structural Change
  final String _p2OriginalSentence = "The researchers analyzed the data carefully.";
  final String _p2Instruction = "Rewrite the sentence in the passive voice.";
  final TextEditingController _p2Controller = TextEditingController();

  // Problem 3: Best Paraphrase
  final String _p3OriginalText = "Although the economy is recovering, unemployment rates remain high.";
  final List<String> _p3Options = [
    "The economy is recovering because unemployment rates are high.",
    "Despite the economic recovery, high unemployment rates persist.",
    "Unemployment rates are high, so the economy is recovering.",
    "The economy is not recovering, and unemployment rates are high."
  ];
  int? _p3SelectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _testState = TestState.test;
  }

  @override
  void dispose() {
    _p1Controller1.dispose();
    _p1Controller2.dispose();
    _p2Controller.dispose();
    super.dispose();
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
      _p1Controller1.clear();
      _p1Controller2.clear();
      _p2Controller.clear();
      _p3SelectedOptionIndex = null;
      _testState = TestState.test;
    });
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
            'Paraphrasing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 1: Synonym Replacement
  // ---------------------------------------------------------------------------
  Widget _buildProblem1() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 1: Synonym Replacement',
              'Replace the highlighted words with appropriate synonyms.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF334155),
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(text: _p1SentencePart1),
                  TextSpan(
                    text: _p1Word1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0x206366F1),
                    ),
                  ),
                  TextSpan(text: _p1SentencePart2),
                  TextSpan(
                    text: _p1Word2,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      backgroundColor: Color(0x206366F1),
                    ),
                  ),
                  TextSpan(text: _p1SentencePart3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSynonymInput("Synonym for '$_p1Word1'", _p1Controller1),
          const SizedBox(height: 12),
          _buildSynonymInput("Synonym for '$_p1Word2'", _p1Controller2),
        ],
      ),
    );
  }

  Widget _buildSynonymInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 2: Structural Change
  // ---------------------------------------------------------------------------
  Widget _buildProblem2() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 2: Structural Change',
              'Rewrite the sentence as instructed, keeping the same meaning.'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ORIGINAL SENTENCE:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _p2OriginalSentence,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF5C6470)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _p2Instruction,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF5C6470),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _p2Controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Type your rewritten sentence here...',
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
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROBLEM 3: Best Paraphrase
  // ---------------------------------------------------------------------------
  Widget _buildProblem3() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 3: Best Paraphrase',
              'Select the option that best preserves the original meaning.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
            ),
            child: Text(
              _p3OriginalText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_p3Options.length, (index) {
            final isSelected = _p3SelectedOptionIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _p3SelectedOptionIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _p3Options[index],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF5C6470),
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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

