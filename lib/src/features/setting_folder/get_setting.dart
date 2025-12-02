import 'package:flutter/foundation.dart';
import '../../services/supabase.dart';

/// Small DTO for per-user settings stored in the `users` table.
class UserSettings {
  final int fontSize;
  final int themeColor;

  UserSettings({required this.fontSize, required this.themeColor});

  factory UserSettings.fromMap(Map<String, dynamic> m) {
    return UserSettings(
      fontSize: (m['font_size'] as int?) ?? 16,
      themeColor: (m['theme_color'] as int?) ?? 0,
    );
  }
}

/// Fetches `font_size` and `theme_color` for the given `userId` from the
/// `users` table. Returns `null` on error or when no row exists.
Future<UserSettings?> fetchUserSettings(String userId) async {
  try {
    final res = await supabase
        .from('users')
        .select('font_size, theme_color')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(res as Map);
    return UserSettings.fromMap(map);
  } catch (e) {
    if (kDebugMode) print('fetchUserSettings error: $e');
    return null;
  }
}

/// Convenience: returns font size for the user or default 16 if not found.
Future<int> fetchUserFontSize(String userId) async {
  final s = await fetchUserSettings(userId);
  return s?.fontSize ?? 16;
}

/// Convenience: returns theme color int for the user or default 0 if not found.
Future<int> fetchUserThemeColor(String userId) async {
  final s = await fetchUserSettings(userId);
  return s?.themeColor ?? 0;
}

/// Update both `font_size` and `theme_color` for the user. Returns true on success.
Future<bool> updateUserSettings(String userId, {int? fontSize, int? themeColor}) async {
  try {
    final Map<String, dynamic> payload = {};
    if (fontSize != null) payload['font_size'] = fontSize;
    if (themeColor != null) payload['theme_color'] = themeColor;
    if (payload.isEmpty) return true;

    await supabase.from('users').update(payload).eq('user_id', userId);
    return true;
  } catch (e) {
    if (kDebugMode) print('updateUserSettings exception: $e');
    return false;
  }
}

/// Convenience single-field updaters
Future<bool> updateUserFontSize(String userId, int fontSize) => updateUserSettings(userId, fontSize: fontSize);
Future<bool> updateUserThemeColor(String userId, int themeColor) => updateUserSettings(userId, themeColor: themeColor);
