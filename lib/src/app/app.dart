import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/results/results_screen.dart';
import '../features/results/feedback_screen.dart';
import '../features/results/past_mistakes_screen.dart';
import '../features/results/vocabulary_mistakes_screen.dart';
import '../features/profile_setting/profile.dart';
import '../features/profile_setting/edit_profile.dart';
import '../features/setting.dart';
import '../features/skills/index.dart';
import 'main_shell.dart';
import '../core/theme/app_theme.dart';

class PrepPilotApp extends StatelessWidget {
  const PrepPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrepPilot AI',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        '/skills': (_) => const SkillsMainScreen(),
        '/skills/listening': (_) => const ListeningMainScreen(),
        '/skills/listening/listeningmodule_1': (_) => const ListeningModule_1(),
        '/skills/writing': (_) => const WritingMainScreen(),
        '/skills/writing/writingmodule_1': (_) => const WritingModule_1(),
        '/profile': (_) => const ProfileScreen(),
        '/profile/edit': (_) => const EditProfileScreen(),
        '/settings': (_) => const SettingScreen(),
        '/results': (_) => const ResultsScreen(),
        '/feedback': (_) => const FeedbackScreen(),
        '/past-mistakes': (_) => const PastMistakesScreen(),
        '/vocabulary': (_) => const VocabularyMistakesScreen(),
      },
    );
  }
}

// class _ProfileScreen extends StatelessWidget {
//   const _ProfileScreen();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Profile')),
//       body: const Center(child: Text('Profile (placeholder)')),
//     );
//   }
// }/

// class _SettingsScreen extends StatelessWidget {
//   const _SettingsScreen();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Settings')),
//       body: const Center(child: Text('Settings (placeholder)')),
//     );
//   }
// }
