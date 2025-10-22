import 'dart:ui';
import 'package:flutter/material.dart';
import 'data/mock_vocabulary.dart';

class VocabularyMistakesScreen extends StatelessWidget {
  const VocabularyMistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final words = MockVocabulary.words;

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vocabulary',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    _GlassButton(
                      label: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      for (var word in words) ...[
                        _VocabCard(
                          word: word.word,
                          definition: word.definition,
                          onArchive: () {
                            // Handle archive
                          },
                          onRepeat: () {
                            // Handle repeat
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                      _ActionButton(
                        label: 'Start vocabulary test',
                        onTap: () {},
                      ),
                    ],
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

class _VocabCard extends StatelessWidget {
  const _VocabCard({
    required this.word,
    required this.definition,
    required this.onArchive,
    required this.onRepeat,
  });
  final String word;
  final String definition;
  final VoidCallback onArchive;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .76),
            border: Border.all(color: Colors.black.withValues(alpha: .06)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(definition, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      label: 'Archive',
                      icon: Icons.archive_rounded,
                      onTap: onArchive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallButton(
                      label: 'Repeat',
                      icon: Icons.replay_rounded,
                      onTap: onRepeat,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: .06)),
              color: Colors.white.withValues(alpha: .82),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: .06)),
              color: Colors.white.withValues(alpha: .72),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
