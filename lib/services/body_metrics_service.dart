import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/models/body_metrics.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyMetricsService {
  BodyMetricsService._();

  static final BodyMetricsService instance = BodyMetricsService._();

  static const _localKey = 'body_metrics';

  final ValueNotifier<BodyMetrics> metrics =
      ValueNotifier(BodyMetrics.defaults);

  Future<void> load() async {
    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        final userId = SupabaseService.currentUser!.id;
        final row = await SupabaseService.client
            .from('profiles')
            .select(
              'height_inches, weight_lbs, body_fat_percent, muscle_mass_lbs, '
              'prev_height_inches, prev_weight_lbs, prev_body_fat_percent, '
              'prev_muscle_mass_lbs',
            )
            .eq('id', userId)
            .maybeSingle();

        if (row != null && row['height_inches'] != null) {
          final loaded = BodyMetrics(
            heightInches: _asDouble(row['height_inches'])!,
            weightLbs: _asDouble(row['weight_lbs']) ?? BodyMetrics.defaults.weightLbs,
            bodyFatPercent: _asDouble(row['body_fat_percent']) ??
                BodyMetrics.defaults.bodyFatPercent,
            muscleMassLbs: _asDouble(row['muscle_mass_lbs']) ??
                BodyMetrics.defaults.muscleMassLbs,
            previousHeightInches: _asDouble(row['prev_height_inches']),
            previousWeightLbs: _asDouble(row['prev_weight_lbs']),
            previousBodyFatPercent: _asDouble(row['prev_body_fat_percent']),
            previousMuscleMassLbs: _asDouble(row['prev_muscle_mass_lbs']),
          );
          metrics.value = loaded;
          await _saveLocal(loaded);
          return;
        }
      } catch (_) {
        // Columns may be missing — fall back to local.
      }
    }

    await _loadLocal();
  }

  Future<void> save(BodyMetrics next) async {
    final current = metrics.value;
    final withHistory = next.copyWith(
      previousHeightInches: current.heightInches,
      previousWeightLbs: current.weightLbs,
      previousBodyFatPercent: current.bodyFatPercent,
      previousMuscleMassLbs: current.muscleMassLbs,
    );

    metrics.value = withHistory;
    await _saveLocal(withHistory);
    await _syncRemote(withHistory);
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) {
      metrics.value = BodyMetrics.defaults;
      return;
    }
    try {
      metrics.value =
          BodyMetrics.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      metrics.value = BodyMetrics.defaults;
    }
  }

  Future<void> _saveLocal(BodyMetrics value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(value.toJson()));
  }

  Future<void> _syncRemote(BodyMetrics value) async {
    if (!SupabaseService.isSignedIn) return;

    try {
      await UserProfileService.instance.ensureProfileRow();
      final userId = SupabaseService.currentUser!.id;
      await SupabaseService.client.from('profiles').upsert({
        'id': userId,
        'height_inches': value.heightInches,
        'weight_lbs': value.weightLbs,
        'body_fat_percent': value.bodyFatPercent,
        'muscle_mass_lbs': value.muscleMassLbs,
        'prev_height_inches': value.previousHeightInches,
        'prev_weight_lbs': value.previousWeightLbs,
        'prev_body_fat_percent': value.previousBodyFatPercent,
        'prev_muscle_mass_lbs': value.previousMuscleMassLbs,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Local metrics still apply.
    }
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void clear() {
    metrics.value = BodyMetrics.defaults;
  }
}
