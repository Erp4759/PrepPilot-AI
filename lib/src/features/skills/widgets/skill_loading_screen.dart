import 'package:flutter/material.dart';
import 'skill_glass_card.dart';

class SkillLoadingScreen extends StatelessWidget {
  const SkillLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SkillGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
              'AI is creating a challenge',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF5C6470).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            const SkillLoadingProgressIndicator(label: 'Setting difficulty...', value: 0.33),
            const SizedBox(height: 12),
            const SkillLoadingProgressIndicator(label: 'Generating content...', value: 0.66),
            const SizedBox(height: 12),
            const SkillLoadingProgressIndicator(label: 'Finalizing...', value: 1.0),
          ],
        ),
      ),
    );
  }
}

class SkillLoadingProgressIndicator extends StatelessWidget {
  const SkillLoadingProgressIndicator({super.key, required this.label, required this.value});

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
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
