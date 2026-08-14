import 'dart:async';

import 'package:flutter/material.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/app_shell.dart';
import 'package:peakform_ai/screens/auth_screen.dart';
import 'package:peakform_ai/screens/sports_selection_screen.dart';
import 'package:peakform_ai/services/auth_service.dart';
import 'package:peakform_ai/services/body_metrics_service.dart';
import 'package:peakform_ai/services/coach_feedback_service.dart';
import 'package:peakform_ai/services/game_schedule_service.dart';
import 'package:peakform_ai/services/nutrition_log_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/services/workout_log_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _authSub;
  bool _bootstrapping = true;
  bool _needsSportsSetup = false;

  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isConfigured) {
      _bootstrapping = false;
      return;
    }

    _session = AuthService.session;
    _authSub = AuthService.authStateChanges.listen(_onAuthState);
    _bootstrapForSession(_session);
  }

  Future<void> _onAuthState(AuthState state) async {
    final session = state.session ?? AuthService.session;
    if (!mounted) return;
    setState(() {
      _session = session;
      _bootstrapping = true;
    });
    await _bootstrapForSession(session);
  }

  Future<void> _bootstrapForSession(Session? session) async {
    if (session == null) {
      _clearUserData();
      if (!mounted) return;
      setState(() {
        _needsSportsSetup = false;
        _bootstrapping = false;
      });
      return;
    }

    await _loadUserData();
    final needsSetup =
        !TrainingPreferencesService.instance.sportsSetupCompleted.value;

    if (!mounted) return;
    setState(() {
      _needsSportsSetup = needsSetup;
      _bootstrapping = false;
    });
  }

  Future<void> _loadUserData() async {
    await UserProfileService.instance.loadCurrentProfile();
    await GameScheduleService.instance.loadGames();
    await NutritionLogService.instance.loadLogs();
    await TrainingPreferencesService.instance.load();
    await TrainingSessionOverrideService.instance.load();
    await BodyMetricsService.instance.load();
    await WorkoutLogService.instance.load();
    await CoachFeedbackService.instance.load();
  }

  void _clearUserData() {
    UserProfileService.instance.clear();
    GameScheduleService.instance.clear();
    NutritionLogService.instance.clear();
    TrainingPreferencesService.instance.clear();
    TrainingSessionOverrideService.instance.clear();
    BodyMetricsService.instance.clear();
    WorkoutLogService.instance.clear();
    CoachFeedbackService.instance.clearMemory();
  }

  void _onSportsSetupCompleted() {
    if (!mounted) return;
    setState(() => _needsSportsSetup = false);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const AppShell();
    }

    if (_session == null) {
      return const AuthScreen();
    }

    if (_bootstrapping) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_needsSportsSetup) {
      return SportsSelectionScreen(
        isOnboarding: true,
        onCompleted: _onSportsSetupCompleted,
      );
    }

    return const AppShell();
  }
}
