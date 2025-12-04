import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../library/test_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.of(context).size.height;
    const topPad = 48.0;
    const bottomPad = 120.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StaticBackdrop(),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, topPad, 16, bottomPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: _GlassCard(
                    child: SizedBox(
                      height: viewport - (topPad + bottomPad),
                      child: ScrollConfiguration(
                        behavior: const _NoGlowScrollBehavior(),
                        child: const SingleChildScrollView(
                          child: _CardScrollContent(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _StaticBackdrop extends StatelessWidget {
  const _StaticBackdrop();
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
            child: _blob(const [Color(0x2882CEFF), Color(0x28B78DFF)], 560),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _blob(const [Color(0x28FFD17C), Color(0x28B78DFF)], 460),
          ),
          Positioned(
            left: -140,
            bottom: 80,
            child: _blob(const [Color(0x2878C8FF), Color(0x28FFA078)], 680),
          ),
        ],
      ),
    );
  }

  Widget _blob(List<Color> colors, double size) {
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
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.black.withOpacity(.08)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xC8FFFFFF), Color(0xA0FFFFFF)],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(padding: const EdgeInsets.all(28), child: child),
          ),
        ),
      ),
    );
  }
}

class _CardScrollContent extends StatelessWidget {
  const _CardScrollContent();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Dot(),
            const SizedBox(width: 8),
            Text(
              'Welcome aboard',
              style: textTheme.labelSmall?.copyWith(
                letterSpacing: .6,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'AI Tutor & Examiner for IELTS',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.06,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Practice reading, listening, writing, and speaking with real test logic.',
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF5C6470),
          ),
        ),
        const SizedBox(height: 32),

        // User Stats Section
        const _UserStatsSection(),
      ],
    );
  }
}

// User Stats Section with FutureBuilder
class _UserStatsSection extends StatelessWidget {
  const _UserStatsSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TestHelper.fetchUserStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _GlassCapsule(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Unable to load stats',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final stats = snapshot.data!;
        final totalTests = stats['total_tests'] as int;

        // If no tests, show welcome message
        if (totalTests == 0) {
          return _NoTestsYet();
        }

        return Column(
          children: [
            // Quick Stats
            _QuickStatsCard(stats: stats),
            const SizedBox(height: 16),

            // Score Improvement
            _ScoreImprovementCard(),
            const SizedBox(height: 16),

            // Module Performance
            _ModulePerformanceCard(),
          ],
        );
      },
    );
  }
}

// No tests placeholder
class _NoTestsYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCapsule(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.assessment_outlined,
            size: 48,
            color: Color(0xFF2C8FFF),
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to start?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first test to see your stats here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5C6470)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Quick Stats Card
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final totalTests = stats['total_tests'] as int;
    final avgPercentage = stats['average_percentage'] as int;
    final scoreTrend = stats['score_trend'] as String;

    // Trend icon and color
    IconData trendIcon;
    Color trendColor;
    if (scoreTrend == 'improving') {
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
    } else if (scoreTrend == 'declining') {
      trendIcon = Icons.trending_down;
      trendColor = Colors.orange;
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.blue;
    }

    return _GlassCapsule(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LogoGradientBox(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(trendIcon, size: 16, color: trendColor),
                        const SizedBox(width: 4),
                        Text(
                          scoreTrend == 'improving'
                              ? 'Improving'
                              : scoreTrend == 'declining'
                              ? 'Needs work'
                              : 'Stable',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: trendColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(label: 'Tests', value: '$totalTests'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.black.withOpacity(.08),
              ),
              Expanded(
                child: _StatItem(label: 'Avg Score', value: '$avgPercentage%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Score Improvement Card
class _ScoreImprovementCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TestHelper.fetchScoreImprovement(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final improvement = snapshot.data!;
        final scores = improvement['scores'] as List;

        if (scores.isEmpty) return const SizedBox.shrink();

        final message = improvement['message'] as String;
        final improvementValue = improvement['improvement'] as int;

        return _GlassCapsule(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1F2C8FFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Color(0xFF2C8FFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last 5 Tests',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (improvementValue != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: improvementValue > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${improvementValue > 0 ? '+' : ''}$improvementValue%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: improvementValue > 0
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6470)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Module Performance Card
class _ModulePerformanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TestHelper.fetchModulePerformance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final perf = snapshot.data!;
        final modules = perf['modules'] as Map<String, dynamic>;

        if (modules.isEmpty) return const SizedBox.shrink();

        final strongestModule = perf['strongest_module'] as String?;
        final weakestModule = perf['weakest_module'] as String?;

        return _GlassCapsule(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1F2C8FFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFF2C8FFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Module Performance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...modules.entries.map((entry) {
                final module = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final percentage = data['average_percentage'] as int;
                final isStrongest = module == strongestModule;
                final isWeakest = module == weakestModule;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isStrongest
                              ? Colors.green
                              : isWeakest
                              ? Colors.orange
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isStrongest)
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.green,
                        )
                      else if (isWeakest)
                        const Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C8FFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6470)),
        ),
      ],
    );
  }
}

// Keep all your existing widget classes below
class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(.06)),
            color: Colors.white.withOpacity(.72),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LogoGradientBox extends StatelessWidget {
  const _LogoGradientBox({this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xD282CEFF), Color(0xD2B78DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3082CEFF),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.flight,
          color: Colors.white.withOpacity(.95),
          size: size * .6,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(.3, .3),
          colors: [Color(0xE0FFFFFF), Color(0xCC82CEFF)],
        ),
        boxShadow: [BoxShadow(color: Color(0xB382CEFF), blurRadius: 18)],
      ),
    );
  }
}
