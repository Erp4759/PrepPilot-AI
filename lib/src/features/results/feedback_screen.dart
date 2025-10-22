import 'dart:ui';
import 'package:flutter/material.dart';
import 'data/mock_feedback.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resultId = ModalRoute.of(context)!.settings.arguments as String;
    final feedback =
        MockFeedback.feedbackById[resultId] ?? MockFeedback.feedbackById['1']!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${feedback.testType.toUpperCase()} • Band ${feedback.score}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: const Color(0xFF2C8FFF),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    _GlassButton(
                      label: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _FeedbackCard(
                    question: feedback.question,
                    userAnswer: feedback.userAnswer,
                    aiAnalysis: feedback.aiAnalysis,
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

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: .06)),
              color: Colors.white.withValues(alpha: .72),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.question,
    required this.userAnswer,
    required this.aiAnalysis,
  });
  final String question;
  final String userAnswer;
  final String aiAnalysis;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .76),
            border: Border.all(color: Colors.black.withValues(alpha: .06)),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.quiz_rounded,
                title: 'Question',
                color: const Color(0xFF2C8FFF),
              ),
              const SizedBox(height: 12),
              Text(question, style: const TextStyle(height: 1.6, fontSize: 15)),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.edit_rounded,
                title: 'Your Answer',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: .04),
                  ),
                ),
                child: Text(
                  userAnswer,
                  style: const TextStyle(height: 1.6, fontSize: 15),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.psychology_rounded,
                title: 'AI Analysis',
                color: const Color(0xFF10B981),
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
                    color: const Color(0xFF10B981).withValues(alpha: .2),
                  ),
                ),
                child: Text(
                  aiAnalysis,
                  style: const TextStyle(height: 1.6, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}
