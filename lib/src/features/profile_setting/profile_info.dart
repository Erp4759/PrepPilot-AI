import 'dart:ui';
import 'package:flutter/material.dart';
import 'get_profile.dart';
import 'get_feedback.dart';
import '../../services/supabase.dart';
import '../profile_setting/profile_notifier.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({Key? key}) : super(key: key);

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  bool _loading = true;
  UserProfile? _profile;
  // pain points removed — we only display difficulty levels

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // reload profile when external changes occur (e.g., email updated)
    profileRefreshCounter.addListener(_onProfileRefreshRequested);
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final p = await fetchUserProfile(authUser.id);
      // compute/refresh difficulty levels (kept) — ignore errors
      try {
        await computeLearningLevelAndPainPoints(authUser.id);
      } catch (_) {}

      // Re-fetch the profile after compute so UI reflects updated difficulties.
      final refreshed = await fetchUserProfile(authUser.id);
      setState(() {
        _profile = refreshed ?? p;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onProfileRefreshRequested() {
    // when notifier increments, reload profile
    _loadProfile();
  }


  @override
  Widget build(BuildContext context) {
    final name = _profile?.username ?? '';
    final email = _profile?.email ?? '';
    final reading = _profile?.readingDifficulty ?? 0;
    final speaking = _profile?.speakingDifficulty ?? 0;
    final listening = _profile?.listeningDifficulty ?? 0;
    final writing = _profile?.scanningDifficulty ?? 0;

    String readingLevelDisplay = _loading ? '' : (reading > 0 ? reading.toString() : '-');
    String speakingLevelDisplay = _loading ? '' : (speaking > 0 ? speaking.toString() : '-');
    String listeningLevelDisplay = _loading ? '' : (listening > 0 ? listening.toString() : '-');
    String writingLevelDisplay = _loading ? '' : (writing > 0 ? writing.toString() : '-');
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SmallBackButton(),
                      const SizedBox(width: 16),
                      const Text(
                        'Profile',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Info',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Name', value: _loading ? 'Loading...' : (name.isNotEmpty ? name : '-')),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Email', value: _loading ? 'Loading...' : (email.isNotEmpty ? email : '-')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Skill level',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        _SkillCard(title: 'Reading', level: readingLevelDisplay),
                        const SizedBox(height: 16),
                        _SkillCard(title: 'Speaking', level: speakingLevelDisplay),
                        const SizedBox(height: 16),
                        _SkillCard(title: 'Listening', level: listeningLevelDisplay),
                        const SizedBox(height: 16),
                        _SkillCard(title: 'Writing', level: writingLevelDisplay),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Score is computed based on your test result.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    profileRefreshCounter.removeListener(_onProfileRefreshRequested);
    super.dispose();
  }
}

class _SmallBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white.withOpacity(.78);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.black.withOpacity(.06)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String title;
  final String level;

  const _SkillCard({
    required this.title,
    required this.level,
  });

  String _labelForLevel(int l) {
    switch (l) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Novice';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? lvl = int.tryParse(level);
    final double fillFraction = (lvl != null && lvl > 0) ? (lvl.clamp(1, 5) / 5.0) : 0.0;
    final bool hasValidLevel = lvl != null && lvl > 0;
    final String label = hasValidLevel ? _labelForLevel(lvl!) : 'No valid results yet';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                lvl != null && lvl > 0 ? '$lvl / 5' : '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gradient bar
          LayoutBuilder(builder: (context, constraints) {
            final double width = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 14,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 14,
                  width: width * fillFraction,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF6EE7B7), Color(0xFF2C8FFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          // Label below the bar (or message when no valid results)
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasValidLevel ? FontWeight.w600 : FontWeight.w400,
              color: hasValidLevel ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
