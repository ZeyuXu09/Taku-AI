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
  static const _historyKey = 'body_metrics_history';

  final ValueNotifier<BodyMetrics> metrics =
      ValueNotifier(BodyMetrics.defaults);
  final ValueNotifier<List<BodyMetricSnapshot>> history = ValueNotifier([]);
  final ValueNotifier<bool> hasUserMetrics = ValueNotifier(false);

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

        if (row != null && row['weight_lbs'] != null) {
          final loaded = BodyMetrics(
            heightInches:
                _asDouble(row['height_inches']) ?? BodyMetrics.defaults.heightInches,
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
          hasUserMetrics.value = true;
          await _saveLocal(loaded);
          await _loadHistory(loaded);
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
    hasUserMetrics.value = true;
    await _saveLocal(withHistory);
    await _appendHistory(withHistory);
    await _syncRemote(withHistory);
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) {
      metrics.value = BodyMetrics.defaults;
      hasUserMetrics.value = false;
      history.value = [];
      return;
    }
    try {
      final loaded =
          BodyMetrics.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      metrics.value = loaded;
      hasUserMetrics.value = true;
      await _loadHistory(loaded);
    } catch (_) {
      metrics.value = BodyMetrics.defaults;
      hasUserMetrics.value = false;
      history.value = [];
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

  Future<void> _loadHistory(BodyMetrics loaded) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((item) =>
                BodyMetricSnapshot.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
        if (list.isNotEmpty) {
          history.value = list;
          return;
        }
      } catch (_) {
        // Fall through and rebuild from current / previous values.
      }
    }
    history.value = _synthesizeHistory(loaded);
  }

  Future<void> _appendHistory(BodyMetrics value) async {
    final now = DateTime.now();
    final snap = BodyMetricSnapshot(
      at: now,
      weightLbs: value.weightLbs,
      bodyFatPercent: value.bodyFatPercent,
      muscleMassLbs: value.muscleMassLbs,
    );

    var list = [...history.value];
    if (list.isEmpty && value.previousWeightLbs != null) {
      list = _synthesizeHistory(value);
    }

    if (list.isNotEmpty && _sameDay(list.last.at, now)) {
      list[list.length - 1] = snap;
    } else {
      list.add(snap);
    }

    history.value = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(list.map((item) => item.toJson()).toList()),
    );
  }

  List<BodyMetricSnapshot> _synthesizeHistory(BodyMetrics metrics) {
    if (!hasUserMetrics.value) return [];
    final now = DateTime.now();
    final points = <BodyMetricSnapshot>[];
    if (metrics.previousWeightLbs != null) {
      points.add(
        BodyMetricSnapshot(
          at: now.subtract(const Duration(days: 7)),
          weightLbs: metrics.previousWeightLbs!,
          bodyFatPercent:
              metrics.previousBodyFatPercent ?? metrics.bodyFatPercent,
          muscleMassLbs:
              metrics.previousMuscleMassLbs ?? metrics.muscleMassLbs,
        ),
      );
    }
    points.add(
      BodyMetricSnapshot(
        at: now,
        weightLbs: metrics.weightLbs,
        bodyFatPercent: metrics.bodyFatPercent,
        muscleMassLbs: metrics.muscleMassLbs,
      ),
    );
    return points;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void clear() {
    metrics.value = BodyMetrics.defaults;
    history.value = [];
    hasUserMetrics.value = false;
  }
}
