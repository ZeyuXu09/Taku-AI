import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/models/coach_feedback_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachFeedbackService {
  CoachFeedbackService._();

  static final CoachFeedbackService instance = CoachFeedbackService._();
  static const _storageKey = 'coach_feedback_log';
  static const _maxEntries = 200;

  final ValueNotifier<List<CoachFeedbackEntry>> entries = ValueNotifier([]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      entries.value = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List;
      entries.value = decoded
          .cast<Map<String, dynamic>>()
          .map(CoachFeedbackEntry.fromJson)
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (error) {
      debugPrint('CoachFeedbackService.load error: $error');
      entries.value = [];
    }
  }

  Future<void> add({
    required String message,
    required String exercise,
    required bool isCorrection,
    int reps = 0,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final entry = CoachFeedbackEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: trimmed,
      exercise: exercise,
      at: DateTime.now(),
      isCorrection: isCorrection,
      reps: reps,
    );
    entries.value = [entry, ...entries.value].take(_maxEntries).toList();
    await _persist();
  }

  Future<void> clear() async {
    entries.value = [];
    await _persist();
  }

  void clearMemory() {
    entries.value = [];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.value.map((entry) => entry.toJson()).toList()),
    );
  }
}
