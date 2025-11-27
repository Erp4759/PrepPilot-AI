import 'dart:ui';
import 'package:flutter/material.dart';
import '../../library/test_helper.dart';
import 'models/feedback_data.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  FeedbackData? _feedback;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resultId = ModalRoute.of(context)!.settings.arguments as String;
    _loadFeedback(resultId);
  }

  Future<void> _loadFeedback(String resultId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final completeResult = await TestHelper.fetchCompleteResult(
        resultId: resultId,
      );

      setState(() {
        _feedback = FeedbackData.fromCompleteResult(completeResult);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load feedback: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    if (_feedback != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feedback',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_feedback!.testType.toUpperCase()} • ${_feedback!.moduleType} • ${_feedback!.percentage}%',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFF2C8FFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Feedback',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    _GlassButton(
                      label: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final resultId =
                                      ModalRoute.of(context)!.settings.arguments
                                          as String;
                                  _loadFeedback(resultId);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            // Score Overview Card
                            _ScoreOverviewCard(feedback: _feedback!),
                            const SizedBox(height: 16),

                            // AI Feedback Card
                            _AIFeedbackCard(feedback: _feedback!),
                            const SizedBox(height: 16),

                            // Test Context Card
                            _TestContextCard(feedback: _feedback!),
                            const SizedBox(height: 16),

                            // Detailed Answers
                            _DetailedAnswersCard(feedback: _feedback!),
                          ],
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

class _ScoreOverviewCard extends StatelessWidget {
  const _ScoreOverviewCard({required this.feedback});
  final FeedbackData feedback;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          _SectionHeader(
            icon: Icons.emoji_events_rounded,
            title: 'Your Score',
            color: const Color(0xFF2C8FFF),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreStat(
                label: 'Points',
                value: '${feedback.score}/${feedback.totalPoints}',
                color: const Color(0xFF2C8FFF),
              ),
              _ScoreStat(
                label: 'Percentage',
                value: '${feedback.percentage}%',
                color: const Color(0xFF8B5CF6),
              ),
              _ScoreStat(
                label: 'Correct',
                value: '${feedback.correctCount}/${feedback.totalQuestions}',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _AIFeedbackCard extends StatelessWidget {
  const _AIFeedbackCard({required this.feedback});
  final FeedbackData feedback;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              feedback.feedbackText,
              style: const TextStyle(height: 1.6, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestContextCard extends StatelessWidget {
  const _TestContextCard({required this.feedback});
  final FeedbackData feedback;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.description_rounded,
            title: 'Test Context',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          Text(
            feedback.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            feedback.text,
            style: const TextStyle(height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DetailedAnswersCard extends StatelessWidget {
  const _DetailedAnswersCard({required this.feedback});
  final FeedbackData feedback;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.format_list_numbered_rounded,
            title: 'Question Breakdown',
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          ...feedback.detailedAnswers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AnswerItem(answer: answer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerItem extends StatelessWidget {
  const _AnswerItem({required this.answer});
  final DetailedAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isCorrect
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer.isCorrect
              ? const Color(0xFF10B981).withValues(alpha: .2)
              : const Color(0xFFEF4444).withValues(alpha: .2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: answer.isCorrect
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  answer.isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Question ${answer.questionNum}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${answer.pointsEarned}/${answer.pointsAvailable} pts',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer.questionText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _AnswerRow(
            label: 'Your Answer',
            answer: answer.userAnswer,
            isCorrect: answer.isCorrect,
          ),
          const SizedBox(height: 4),
          _AnswerRow(
            label: 'Correct Answer',
            answer: answer.correctAnswer,
            isCorrect: true,
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.answer,
    required this.isCorrect,
  });
  final String label;
  final String answer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCorrect
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

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
          child: child,
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
