import 'dart:async';

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
  Session? _session;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isConfigured) return;

    _session = AuthService.session;
    _authSub = AuthService.authStateChanges.listen(_onAuthState);

    if (_session != null) {
      _loadUserData();
    }
  }

  void _onAuthState(AuthState state) {
    final session = state.session ?? AuthService.session;
    if (!mounted) return;

    setState(() => _session = session);

    if (session != null) {
      _loadUserData();
    } else {
      _clearUserData();
    }
  }

  void _loadUserData() {
    UserProfileService.instance.loadCurrentProfile();
    GameScheduleService.instance.loadGames();
    NutritionLogService.instance.loadLogs();
    TrainingPreferencesService.instance.load();
    TrainingSessionOverrideService.instance.load();
  }

  void _clearUserData() {
    UserProfileService.instance.clear();
    GameScheduleService.instance.clear();
    NutritionLogService.instance.clear();
    TrainingPreferencesService.instance.clear();
    TrainingSessionOverrideService.instance.clear();
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
    return const AppShell();
  }
}
