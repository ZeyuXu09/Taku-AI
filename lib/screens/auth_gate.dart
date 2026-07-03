import 'package:flutter/material.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/app_shell.dart';
import 'package:peakform_ai/screens/auth_screen.dart';
import 'package:peakform_ai/services/auth_service.dart';
import 'package:peakform_ai/services/game_schedule_service.dart';
import 'package:peakform_ai/services/nutrition_log_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isConfigured) return;

    AuthService.authStateChanges.listen((state) {
      if (state.session != null) {
        UserProfileService.instance.loadCurrentProfile();
        GameScheduleService.instance.loadGames();
        NutritionLogService.instance.loadLogs();
        TrainingPreferencesService.instance.load();
        TrainingSessionOverrideService.instance.load();
      } else {
        UserProfileService.instance.clear();
        GameScheduleService.instance.clear();
        NutritionLogService.instance.clear();
        TrainingPreferencesService.instance.clear();
        TrainingSessionOverrideService.instance.clear();
      }
    });

    if (AuthService.session != null) {
      UserProfileService.instance.loadCurrentProfile();
      GameScheduleService.instance.loadGames();
      NutritionLogService.instance.loadLogs();
      TrainingPreferencesService.instance.load();
      TrainingSessionOverrideService.instance.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const AppShell();
    }

    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? AuthService.session;
        if (session == null) {
          return const AuthScreen();
        }
        return const AppShell();
      },
    );
  }
}
