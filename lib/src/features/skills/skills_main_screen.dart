import 'dart:ui';
import 'package:flutter/material.dart';
import '../reading/presentation/reading_home.dart';

class SkillsMainScreen extends StatelessWidget {
  const SkillsMainScreen({super.key});

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _SkillsButton(
                label: 'Reading',
                ontap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReadingHomeScreen(),
                    ),
                  );
                },
                color1: const Color.fromARGB(255, 241, 93, 82).withOpacity(0.4),
                color2: const Color.fromARGB(
                  255,
                  246,
                  172,
                  61,
                ).withOpacity(0.4),
                icon: Icons.book,
              ),
              const SizedBox(height: 40),
              _SkillsButton(
                label: 'Speaking',
                ontap: () {},
                color1: const Color.fromARGB(
                  255,
                  229,
                  105,
                  251,
                ).withOpacity(0.4),
                color2: const Color.fromARGB(
                  255,
                  109,
                  55,
                  202,
                ).withOpacity(0.4),
                icon: Icons.record_voice_over,
              ),
              const SizedBox(height: 40),
              _SkillsButton(
                label: 'Listening',
                ontap: () =>
                    Navigator.of(context).pushNamed('/skills/listening'),
                color1: const Color.fromARGB(255, 63, 225, 68).withOpacity(0.4),
                color2: const Color.fromARGB(255, 60, 91, 76).withOpacity(0.4),
                icon: Icons.hearing,
              ),
              const SizedBox(height: 40),
              _SkillsButton(
                label: 'Writing',
                ontap: () => Navigator.of(context).pushNamed('/skills/writing'),
                color1: const Color.fromARGB(
                  255,
                  99,
                  181,
                  248,
                ).withOpacity(0.4),
                color2: const Color.fromARGB(255, 1, 99, 89).withOpacity(0.4),
                icon: Icons.edit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillsButton extends StatelessWidget {
  final String label;
  final VoidCallback ontap;
  final Color color1;
  final Color color2;
  final IconData icon;

  const _SkillsButton({
    required this.label,
    required this.ontap,
    required this.color1,
    required this.color2,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      borderRadius: BorderRadius.circular(24),
      splashColor: Colors.white.withOpacity(0.7),
      child: Container(
        width: 200,
        height: 124,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x4082CEFF),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
