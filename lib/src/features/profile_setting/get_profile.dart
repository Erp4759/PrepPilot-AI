import 'package:flutter/foundation.dart';
import '../../services/supabase.dart';

class UserProfile {
  final String userId;
  final String username;
  final String email;
  final String password;
  final int fontSize;
  final int themeColor; // stored as int value
  final int readingDifficulty;
  final int listeningDifficulty;
  final int speakingDifficulty;
  final int scanningDifficulty;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.fontSize,
    required this.themeColor,
    required this.readingDifficulty,
    required this.listeningDifficulty,
    required this.speakingDifficulty,
    required this.scanningDifficulty,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    return UserProfile(
      userId: (m['user_id'] as String?) ?? '',
      username: (m['username'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      password: (m['password'] as String?) ?? '',
      fontSize: (m['font_size'] as int?) ?? 16,
      themeColor: (m['theme_color'] as int?) ?? 0,
      readingDifficulty: (m['reading_difficulty'] as int?) ?? 0,
      listeningDifficulty: (m['listening_difficulty'] as int?) ?? 0,
      speakingDifficulty: (m['speaking_difficulty'] as int?) ?? 0,
      scanningDifficulty: (m['scanning_difficulty'] as int?) ?? 0,
    );
  }
}

/// Fetch the user's profile from Supabase `users` table by `userId`.
/// Returns null if not found or on error.
Future<UserProfile?> fetchUserProfile(String userId) async {
  try {
    final res = await supabase
      .from('users')
      .select('user_id, username, email, password, font_size, theme_color, reading_difficulty, listening_difficulty, speaking_difficulty, scanning_difficulty')
      .eq('user_id', userId)
      .maybeSingle();

    if (res == null) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(res as Map);
    return UserProfile.fromMap(map);
  } catch (e) {
    if (kDebugMode) print('fetchUserProfile error: $e');
    return null;
  }
}
