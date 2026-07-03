import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyWorkoutOverride {
  const DailyWorkoutOverride({
    this.exerciseIds = const [],
    this.routineIds = const [],
    this.rotationOffset = 0,
    this.focusName,
  });

  final List<String> exerciseIds;
  final List<String> routineIds;
  final int rotationOffset;
  final String? focusName;

  bool get hasCustomList => exerciseIds.isNotEmpty || routineIds.isNotEmpty;

  TrainingFocus? get focusOverride {
    if (focusName == null) return null;
    for (final focus in TrainingFocus.values) {
      if (focus.name == focusName) return focus;
    }
    return null;
  }

  DailyWorkoutOverride copyWith({
    List<String>? exerciseIds,
    List<String>? routineIds,
    int? rotationOffset,
    String? focusName,
    bool clearFocusName = false,
  }) {
    return DailyWorkoutOverride(
      exerciseIds: exerciseIds ?? this.exerciseIds,
      routineIds: routineIds ?? this.routineIds,
      rotationOffset: rotationOffset ?? this.rotationOffset,
      focusName: clearFocusName ? null : (focusName ?? this.focusName),
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseIds': exerciseIds,
        'routineIds': routineIds,
        'rotationOffset': rotationOffset,
        if (focusName != null) 'focusName': focusName,
      };

  factory DailyWorkoutOverride.fromJson(Map<String, dynamic> json) {
    return DailyWorkoutOverride(
      exerciseIds: (json['exerciseIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      routineIds: (json['routineIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      rotationOffset: json['rotationOffset'] as int? ?? 0,
      focusName: json['focusName'] as String?,
    );
  }
}

class TrainingSessionOverrideService {
  TrainingSessionOverrideService._();

  static final TrainingSessionOverrideService instance =
      TrainingSessionOverrideService._();

  static const _storageKey = 'training_daily_overrides';

  final ValueNotifier<int> changes = ValueNotifier(0);

  Map<String, DailyWorkoutOverride> _overrides = {};

  DailyWorkoutOverride overrideFor(DateTime date) {
    return _overrides[_dateKey(date)] ?? const DailyWorkoutOverride();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _overrides = {};
      _notify();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _overrides = decoded.map(
        (key, value) => MapEntry(
          key,
          DailyWorkoutOverride.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      _overrides = {};
    }
    _notify();
  }

  Future<void> saveCustomLists({
    required DateTime date,
    required List<String> exerciseIds,
    required List<String> routineIds,
  }) async {
    final existing = overrideFor(date);
    _overrides[_dateKey(date)] = existing.copyWith(
      exerciseIds: exerciseIds,
      routineIds: routineIds,
    );
    _notify();
    await _persist();
  }

  Future<void> saveFocus({
    required DateTime date,
    required TrainingFocus focus,
  }) async {
    final existing = overrideFor(date);
    _overrides[_dateKey(date)] = existing.copyWith(
      focusName: focus.name,
      exerciseIds: const [],
      routineIds: const [],
    );
    _notify();
    await _persist();
  }

  Future<void> clearFocus(DateTime date) async {
    final existing = overrideFor(date);
    if (!existing.hasCustomList && existing.rotationOffset == 0) {
      _overrides.remove(_dateKey(date));
    } else {
      _overrides[_dateKey(date)] = existing.copyWith(clearFocusName: true);
    }
    _notify();
    await _persist();
  }

  Future<void> incrementRotation(DateTime date) async {
    final existing = overrideFor(date);
    _overrides[_dateKey(date)] = existing.copyWith(
      exerciseIds: const [],
      routineIds: const [],
      rotationOffset: existing.rotationOffset + 1,
    );
    _notify();
    await _persist();
  }

  /// Clears in-memory override and notifies listeners immediately.
  void resetSync(DateTime date) {
    _overrides.remove(_dateKey(date));
    _notify();
  }

  Future<void> reset(DateTime date) async {
    resetSync(date);
    await _persist();
  }

  Future<void> persist() => _persist();

  void clear() {
    _overrides = {};
    _notify();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _overrides.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  void _notify() {
    changes.value++;
  }

  String _dateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
