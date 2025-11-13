import 'dart:ui';
import 'package:flutter/material.dart';

class WritingMainScreen extends StatelessWidget {
  const WritingMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WritingModuleButton(
                  label: 'Essay Writing',
                  onTap: () => Navigator.of(context).pushNamed('/skills/writing/writing_module1'),
                  color1: const Color.fromARGB(255, 103, 58, 183).withOpacity(0.4),
                  color2: const Color.fromARGB(255, 63, 81, 181).withOpacity(0.4),
                  icon: Icons.article_outlined,
                ),
                const SizedBox(height: 16),
                _WritingModuleButton(
                  label: 'Paragraph Writing',
                  onTap: () => Navigator.of(context).pushNamed('/skills/writing/writing_module2'),
                  color1: const Color.fromARGB(255, 0, 150, 136).withOpacity(0.4),
                  color2: const Color.fromARGB(255, 0, 121, 107).withOpacity(0.4),
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 16),
                _WritingModuleButton(
                  label: 'Grammar Practice',
                  onTap: () => Navigator.of(context).pushNamed('/skills/writing/writing_module3'),
                  color1: const Color.fromARGB(255, 233, 30, 99).withOpacity(0.4),
                  color2: const Color.fromARGB(255, 192, 57, 43).withOpacity(0.4),
                  icon: Icons.spellcheck_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WritingModuleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color1;
  final Color color2;
  final IconData icon;

  const _WritingModuleButton({
    required this.label,
    required this.onTap,
    required this.color1,
    required this.color2,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, size: 36, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, 
                  size: 20, 
                  color: Colors.white.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}