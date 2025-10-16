import 'dart:ui';

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.of(context).size.height;
    const topPad = 48.0; // breathing room top
    const bottomPad = 120.0; // keep clear of bottom bar

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
          // Soft radial blobs (static, no blur to avoid flicker)
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
          'AI Tutor & Examiner for high‑stakes English exams',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.06,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Practice reading, listening, writing, and speaking with real test logic. Get examiner‑style scoring, pinpoint weaknesses, and train micro‑skills that actually move your score.',
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF5C6470),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Chip('Band/Score aligned feedback'),
            _Chip('Liquid‑glass focus UI'),
            _Chip('Adaptive retests'),
            _Chip('Offline practice'),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PrimaryButton(
              label: 'Register',
              onTap: () =>
                  Navigator.of(context).pushNamed(RegisterScreen.routeName),
            ),
            _GlassButton(
              label: 'Login',
              onTap: () =>
                  Navigator.of(context).pushNamed(LoginScreen.routeName),
            ),
            _GlassButton(
              label: 'Take placement test (10–15 min)',
              onTap: () {},
              small: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Meta(
              text: 'Goal recommendation ready in under 60s',
              color: const Color(0xFF5C6470),
            ),
            Opacity(opacity: .4, child: Text('·', style: textTheme.bodyMedium)),
            _Meta(text: 'No ads', color: const Color(0xFF5C6470)),
            Opacity(opacity: .4, child: Text('·', style: textTheme.bodyMedium)),
            _Meta(
              text: 'Privacy‑first: your audio stays on device*',
              color: const Color(0xFF5C6470),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _FeatureStrip(),
        const SizedBox(height: 14),
        Text(
          '*Optional cloud sync for progress. You control data and exports.',
          style: textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6470)),
        ),
      ],
    );
  }
}

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

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return _GlassCapsule(
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2C8FFF),
        foregroundColor: Colors.white,
        shadowColor: const Color(0x302C8FFF),
        elevation: 6,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.onTap,
    this.small = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool small;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _GlassCapsule(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 14 : 18,
          vertical: small ? 10 : 14,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: small ? FontWeight.w600 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();
  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      (
        'Reading coach.',
        'Skimming, scanning, inference, and keyword mapping with instant rationales.',
      ),
      (
        'Listening like the real thing.',
        'Predict answers, take notes, avoid distractors. Strict/Coach modes.',
      ),
      (
        'Speaking & Writing rubrics.',
        'Examiner‑style scoring with rewrites, shadowing, and intonation coach.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 840;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (title, body) in items)
              SizedBox(
                width: isNarrow ? c.maxWidth : (c.maxWidth - 24) / 3,
                child: _GlassCapsule(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoGradientBox(size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
