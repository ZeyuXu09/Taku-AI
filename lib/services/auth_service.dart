import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static Stream<AuthState> get authStateChanges =>
      SupabaseService.client.auth.onAuthStateChange;

  static Session? get session => SupabaseService.client.auth.currentSession;

  static Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'needs_sports_setup': true,
      },
    );

    // Require sports selection the first time this account enters the app.
    if (SupabaseService.currentUser != null) {
      await TrainingPreferencesService.instance.markSportsSetupPending();
    }
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = SupabaseService.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      throw AuthException('No email found for this account.');
    }

    await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    await SupabaseService.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
