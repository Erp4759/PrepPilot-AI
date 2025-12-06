import 'dart:async';
import 'package:flutter/material.dart';
import '../features/auth/presentation/chatgpt_test_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/results/results_screen.dart';
import '../features/results/feedback_screen.dart';
import '../features/results/past_mistakes_screen.dart';
import '../features/results/vocabulary_mistakes_screen.dart';
import '../features/profile_setting/profile.dart';
import '../features/profile_setting/edit_profile.dart';
import '../features/setting_folder/setting.dart';
import '../features/setting_folder/get_setting.dart';
import '../core/app_state.dart';
import '../services/supabase.dart';
import '../features/skills/index.dart';
import 'main_shell.dart';
import '../core/theme/app_theme.dart';

class PrepPilotApp extends StatefulWidget {
  const PrepPilotApp({super.key});

  @override
  State<PrepPilotApp> createState() => _PrepPilotAppState();
}

class _PrepPilotAppState extends State<PrepPilotApp> {
  // Stored app-wide font size loaded from DB (default 16)
  int appFontSize = 16;
  int isDark = 0;
  String _initialRoute = '/home';

  // MediaQuery scale from this value so existing UX is preserved.
  // Keep previous default (fontSize 16 -> scale 1.2). Compute proportional
  // scale and clamp to a reasonable range to avoid layout breakage.
  double get _computedScale => (appFontSize / 16.0);

  @override
  void initState() {
    super.initState();

    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      _initialRoute = LoginScreen.routeName;
    } else {
      _initialRoute = '/home';
    }

    _loadFontSize();
    // Listen for changes made in settings and update scale live
    appFontSizeNotifier.addListener(_onAppFontSizeChanged);
    // Listen for theme changes and apply dark mode immediately
    appThemeNotifier.addListener(_onAppThemeChanged);
    // Listen for auth state changes so we can load user settings immediately after login
    try {
      _authSub = supabase.auth.onAuthStateChange.listen((event) {
        // When authentication state changes (e.g., signed in), reload font size
        // We don't inspect event details here; simply attempt to refresh settings.
        _loadFontSize();

        // If the user signs out, navigate to the LoginScreen.
        // If the user is signed out/expired, 'event.session' is null.
        if (event.session == null && mounted) {
          // Use a small delay to ensure the MaterialApp is fully built before navigating
          Future.delayed(Duration.zero, () {
            // Check if the current route is not already the login screen to avoid errors
            if (ModalRoute.of(context)?.settings.name !=
                LoginScreen.routeName) {
              // Push the login screen and remove all other routes below it (like the home page)
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            }
          });
        }
      });
    } catch (_) {
      // ignore if listener API is not available
    }
  }

  void _onAppFontSizeChanged() {
    if (!mounted) return;
    setState(() {
      appFontSize = appFontSizeNotifier.value;
    });
  }

  void _onAppThemeChanged() {
    if (!mounted) return;
    setState(() {
      isDark = appThemeNotifier.value;
    });
  }

  Future<void> _loadFontSize() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;
      final font = await fetchUserFontSize(authUser.id);
      final theme = await fetchUserThemeColor(authUser.id);
      if (!mounted) return;
      setState(() {
        appFontSize = font;
        isDark = theme;
        // ensure notifier is in sync
        appFontSizeNotifier.value = appFontSize;
      });
    } catch (_) {
      // ignore and keep default
    }
  }

  @override
  void dispose() {
    appFontSizeNotifier.removeListener(_onAppFontSizeChanged);
    appThemeNotifier.removeListener(_onAppThemeChanged);
    try {
      _authSub?.cancel();
    } catch (_) {}
    super.dispose();
  }

  StreamSubscription<dynamic>? _authSub;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        // 앱 설정에 따른 다크모드 사용 여부 (0 = light, 1 = dark)
        final isDarkMode = this.isDark == 1;

        // 기본 MediaQuery 래퍼
        final wrappedChild = MediaQuery(
          data: mediaQueryData.copyWith(textScaleFactor: _computedScale),
          child: child!,
        );
        // 앱 설정에서 다크 모드가 켜져 있지 않으면 원래 child 반환
        if (!isDarkMode) return wrappedChild;

        // 앱 설정에서 다크 모드라면 색상 반전 필터 적용
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -0.8,
            0,
            0,
            0,
            235,
            0,
            -0.8,
            0,
            0,
            235,
            0,
            0,
            -0.8,
            0,
            235,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: wrappedChild,
        );
      },
      navigatorObservers: [routeObserver],
      title: 'PrepPilot AI',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: _initialRoute,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
        '/chatgpt-test': (_) => const ChatGPTTestScreen(),
        '/skills': (_) => const SkillsMainScreen(),
        '/skills/listening': (_) => const ListeningHomeScreen(),
        '/skills/listening/listening_focusing_on_disctractors.dart': (_) =>
            const ListeningGistListeningScreen(),
        '/skills/writing': (_) => const WritingHomeScreen(),
        WritingCoherenceAndCohesionScreen.routeName: (_) => 
            const WritingCoherenceAndCohesionScreen(),
        WritingTaskResponseScreen.routeName: (_) => 
            const WritingTaskResponseScreen(),
        WritingParaphrasingScreen.routeName: (_) => 
            const WritingParaphrasingScreen(),
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

// Global route observer used by screens that need to be aware of navigation events
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
