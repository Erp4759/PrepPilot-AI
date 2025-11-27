import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

class WritingLinkingDevicesScreen extends StatefulWidget {
  const WritingLinkingDevicesScreen({super.key});

  static const routeName = '/writing_linking_devices';

  @override
  State<WritingLinkingDevicesScreen> createState() =>
      _WritingLinkingDevicesScreenState();
}

enum TestState { initial, loading, test, results }

class _WritingLinkingDevicesScreenState
    extends State<WritingLinkingDevicesScreen> {
  TestState _testState = TestState.initial;
  bool _isSubmitting = false;

  // Problem 1: Choose the correct linking word
  final String _p1SentencePart1 = "The company's profits have increased significantly this year.";
  final String _p1SentencePart2 = "they are planning to expand into new markets.";
  final List<String> _p1Options = ["However", "Consequently", "In contrast", "Nevertheless"];
  String? _p1SelectedOption;

  // Problem 2: Combine sentences
  final String _p2Sentence1 = "The internet has revolutionized communication.";
  final String _p2Sentence2 = "It has created new privacy concerns.";
  final String _p2LinkingWord = "although";
  final TextEditingController _p2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _testState = TestState.test;
  }

  @override
  void dispose() {
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
      _p1SelectedOption = null;
      _p2Controller.clear();
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
            'Linking Devices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProblem1() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 1: Select the Connector',
              'Choose the most appropriate linking word to connect the ideas.'),
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
                  fontFamily: 'Inter', // Assuming default font
                ),
                children: [
                  TextSpan(text: "$_p1SentencePart1 "),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: const Color(0xFF6366F1), width: 2)),
                      ),
                      child: Text(
                        _p1SelectedOption ?? "_______",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _p1SelectedOption != null ? const Color(0xFF6366F1) : Colors.black26,
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: ", $_p1SentencePart2"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _p1Options.map((option) {
              final isSelected = _p1SelectedOption == option;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _p1SelectedOption = option;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProblem2() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Part 2: Sentence Combination',
              'Combine the two sentences using the given linking word.'),
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
                _buildSentenceRow('1.', _p2Sentence1),
                const SizedBox(height: 8),
                _buildSentenceRow('2.', _p2Sentence2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Link with: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5C6470),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _p2LinkingWord,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
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
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your combined sentence here...',
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

  Widget _buildSentenceRow(String prefix, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prefix,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
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

