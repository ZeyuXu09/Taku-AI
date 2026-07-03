import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/data/sport_catalog.dart';
import 'package:peakform_ai/models/training_intensity.dart';
import 'package:peakform_ai/models/training_location.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingPreferences {
  const TrainingPreferences({
    required this.sports,
    required this.intensity,
    required this.location,
  });

  final List<String> sports;
  final TrainingIntensity intensity;
  final TrainingLocation location;

  static const defaults = TrainingPreferences(
    sports: [SportCatalog.defaultSport],
    intensity: TrainingIntensity.serious,
    location: TrainingLocation.home,
  );

  TrainingPreferences copyWith({
    List<String>? sports,
    TrainingIntensity? intensity,
    TrainingLocation? location,
  }) {
    return TrainingPreferences(
      sports: sports ?? this.sports,
      intensity: intensity ?? this.intensity,
      location: location ?? this.location,
    );
  }
}

class TrainingPreferencesService {
  TrainingPreferencesService._();

  static final TrainingPreferencesService instance =
      TrainingPreferencesService._();

  static const _localSportsKey = 'training_sports';
  static const _localIntensityKey = 'training_intensity';
  static const _localLocationKey = 'training_location';

  final ValueNotifier<TrainingPreferences> preferences =
      ValueNotifier(TrainingPreferences.defaults);

  Future<void> load() async {
    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        final userId = SupabaseService.currentUser!.id;
        final row = await SupabaseService.client
            .from('profiles')
            .select('sports, training_intensity, training_location, sport')
            .eq('id', userId)
            .maybeSingle();

        if (row != null) {
          final sports = _parseSports(row);
          final intensity = TrainingIntensity.fromLabel(
            row['training_intensity'] as String?,
          );
          final location = TrainingLocation.fromLabel(
            row['training_location'] as String?,
          );
          preferences.value = TrainingPreferences(
            sports: sports,
            intensity: intensity,
            location: location,
          );
          await _saveLocal(sports, intensity, location);
          return;
        }
      } catch (_) {
        // Fall through to local cache.
      }
    }

    await _loadLocal();
  }

  Future<void> save({
    required List<String> sports,
    required TrainingIntensity intensity,
  }) async {
    final normalized = sports.isEmpty
        ? [SportCatalog.defaultSport]
        : sports.toList();

    preferences.value = preferences.value.copyWith(
      sports: normalized,
      intensity: intensity,
    );

    await _saveLocal(
      normalized,
      preferences.value.intensity,
      preferences.value.location,
    );

    await _syncRemote(
      sports: normalized,
      intensity: preferences.value.intensity,
      location: preferences.value.location,
    );
  }

  Future<void> saveLocation(TrainingLocation location) async {
    if (preferences.value.location == location) return;

    // Clear stale home/gym exercise overrides before switching libraries.
    TrainingSessionOverrideService.instance.resetSync(DateTime.now());

    preferences.value = preferences.value.copyWith(location: location);

    await _saveLocal(
      preferences.value.sports,
      preferences.value.intensity,
      location,
    );

    await TrainingSessionOverrideService.instance.persist();

    await _syncRemote(
      sports: preferences.value.sports,
      intensity: preferences.value.intensity,
      location: location,
    );
  }

  Future<void> _syncRemote({
    required List<String> sports,
    required TrainingIntensity intensity,
    required TrainingLocation location,
  }) async {
    if (!SupabaseService.isSignedIn) return;

    try {
      await UserProfileService.instance.ensureProfileRow();
      final userId = SupabaseService.currentUser!.id;
      await SupabaseService.client.from('profiles').upsert({
        'id': userId,
        'sports': sports,
        'sport': sports.first,
        'training_intensity': intensity.label,
        'training_location': location.label,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Local prefs still apply offline.
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final sportsJson = prefs.getString(_localSportsKey);
    final intensityLabel = prefs.getString(_localIntensityKey);
    final locationLabel = prefs.getString(_localLocationKey);

    List<String> sports = TrainingPreferences.defaults.sports;
    if (sportsJson != null) {
      try {
        final decoded = jsonDecode(sportsJson) as List;
        sports = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    preferences.value = TrainingPreferences(
      sports: sports.isEmpty ? TrainingPreferences.defaults.sports : sports,
      intensity: TrainingIntensity.fromLabel(intensityLabel),
      location: TrainingLocation.fromLabel(locationLabel),
    );
  }

  Future<void> _saveLocal(
    List<String> sports,
    TrainingIntensity intensity,
    TrainingLocation location,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localSportsKey, jsonEncode(sports));
    await prefs.setString(_localIntensityKey, intensity.label);
    await prefs.setString(_localLocationKey, location.label);
  }

  List<String> _parseSports(Map<String, dynamic> row) {
    final sportsField = row['sports'];
    if (sportsField is List && sportsField.isNotEmpty) {
      return sportsField.map((e) => e.toString()).toList();
    }
    final legacySport = row['sport'] as String?;
    if (legacySport != null && legacySport.trim().isNotEmpty) {
      return [legacySport.trim()];
    }
    return TrainingPreferences.defaults.sports;
  }

  void clear() {
    preferences.value = TrainingPreferences.defaults;
  }
}
