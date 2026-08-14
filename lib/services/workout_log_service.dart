import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/utils/training_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutLogService {
  WorkoutLogService._();

  static final WorkoutLogService instance = WorkoutLogService._();
  static const _localStorageKey = 'local_workout_days';

  final ValueNotifier<List<DateTime>> completedDays = ValueNotifier([]);

  TrainingStreakStats streakFor({DateTime? now}) {
    final intensity =
        TrainingPreferencesService.instance.preferences.value.intensity;
    return computeTrainingStreak(
      completedDays: completedDays.value,
      weeklyGoal: intensity.sessionsPerWeek,
      now: now ?? DateTime.now(),
    );
  }

  Future<void> load() async {
    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        final userId = SupabaseService.currentUser!.id;
        final rows = await SupabaseService.client
            .from('workout_sessions')
            .select('started_at')
            .eq('user_id', userId);

        completedDays.value = (rows as List)
            .cast<Map<String, dynamic>>()
            .map((row) => DateTime.parse(row['started_at'] as String).toLocal())
            .map(trainingDateOnly)
            .toSet()
            .toList()
          ..sort();
        await _persistLocalDays();
        return;
      } catch (error) {
        debugPrint('WorkoutLogService.load supabase error: $error');
      }
    }

    await _loadLocalDays();
  }

  /// Records one training day. Extra finishes on the same day do not add a
  /// second session toward the weekly goal.
  Future<void> logCompletion({
    required String title,
    int? durationMinutes,
    DateTime? at,
  }) async {
    final day = trainingDateOnly(at ?? DateTime.now());
    final alreadyLogged = completedDays.value.any((logged) => logged == day);

    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        await SupabaseService.client.from('workout_sessions').insert({
          'user_id': SupabaseService.currentUser!.id,
          'title': title,
          'duration_minutes': durationMinutes,
          'started_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
        });
      } catch (error) {
        debugPrint('WorkoutLogService.logCompletion supabase error: $error');
      }
    }

    if (alreadyLogged) return;

    completedDays.value = [...completedDays.value, day]..sort();
    await _persistLocalDays();
  }

  void clear() {
    completedDays.value = [];
  }

  Future<void> _loadLocalDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStorageKey);
    if (raw == null || raw.isEmpty) {
      completedDays.value = [];
      return;
    }

    final decoded = jsonDecode(raw) as List;
    completedDays.value = decoded
        .cast<String>()
        .map(DateTime.parse)
        .map(trainingDateOnly)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _persistLocalDays() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      completedDays.value.map((day) => day.toIso8601String()).toList(),
    );
    await prefs.setString(_localStorageKey, encoded);
  }
}
