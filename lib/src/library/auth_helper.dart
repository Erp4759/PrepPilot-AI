import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase.dart';

class AuthHelper {
  /// Register a new user
  static Future<AuthResponse?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Sign up with email + password
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return null;

      // Create user profile record
      await supabase.from('users').insert({
        'user_id': user.id,
        'username': username,
      });

      return response;
    } on AuthException catch (e) {
      print('Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  /// Login existing user
  static Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      print('Login failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  /// Get current user
  static User? get currentUser => supabase.auth.currentUser;

  /// Get user profile from `users` table
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('users')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }
}
