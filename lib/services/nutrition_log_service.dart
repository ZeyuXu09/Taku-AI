import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/models/nutrition_log.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:postgrest/postgrest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionLogService {
  NutritionLogService._();

  static final NutritionLogService instance = NutritionLogService._();
  static const _localStorageKey = 'local_nutrition_logs';

  static const double calorieGoal = 2400;
  static const double proteinGoalG = 180;
  static const double carbsGoalG = 250;
  static const double fatGoalG = 70;

  final ValueNotifier<List<NutritionLog>> logs = ValueNotifier([]);

  static String friendlyError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('nutrition_logs') &&
          (message.contains('does not exist') ||
              message.contains('schema cache'))) {
        return 'Nutrition table missing. Run section 5 of supabase/schema.sql in Supabase.';
      }
      return error.message;
    }
    return error.toString();
  }

  Future<void> loadLogs() async {
    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        final userId = SupabaseService.currentUser!.id;
        final rows = await SupabaseService.client
            .from('nutrition_logs')
            .select()
            .eq('user_id', userId)
            .order('logged_at', ascending: false);

        logs.value = (rows as List)
            .cast<Map<String, dynamic>>()
            .map(NutritionLog.fromMap)
            .toList();
        await _persistLocalLogs();
        return;
      } catch (error) {
        debugPrint('NutritionLogService.loadLogs supabase error: $error');
      }
    }

    await _loadLocalLogs();
  }

  List<NutritionLog> logsForDay(DateTime day) {
    return logs.value.where((log) => log.isSameDay(day)).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  NutritionDayTotals totalsForDay(DateTime day) {
    final dayLogs = logsForDay(day);
    return NutritionDayTotals(
      calories: dayLogs.fold(0, (sum, log) => sum + log.totalCalories),
      proteinG: dayLogs.fold(0, (sum, log) => sum + log.totalProteinG),
      fatG: dayLogs.fold(0, (sum, log) => sum + log.totalFatG),
      carbsG: dayLogs.fold(0, (sum, log) => sum + log.totalCarbsG),
    );
  }

  List<NutritionLog> recentScans({int limit = 10}) {
    final seen = <String>{};
    final recent = <NutritionLog>[];

    for (final log in logs.value) {
      final key = log.barcode ?? log.productName;
      if (seen.add(key)) {
        recent.add(log);
      }
      if (recent.length >= limit) break;
    }

    return recent;
  }

  Future<void> addLog({
    required String productName,
    required DateTime logDate,
    String? barcode,
    double? calories,
    double? proteinG,
    double? fatG,
    double? carbsG,
    String? servingSize,
    double servings = 1,
    String? imageUrl,
    String source = 'barcode',
  }) async {
    final loggedAt = _timestampForDay(logDate);

    if (SupabaseService.isSignedIn) {
      await UserProfileService.instance.ensureProfileRow();
      final userId = SupabaseService.currentUser!.id;

      final inserted = await SupabaseService.client
          .from('nutrition_logs')
          .insert({
            'user_id': userId,
            'logged_at': loggedAt.toUtc().toIso8601String(),
            'product_name': productName.trim(),
            'barcode': barcode,
            'calories': calories,
            'protein_g': proteinG,
            'fat_g': fatG,
            'carbs_g': carbsG,
            'serving_size': servingSize,
            'servings': servings,
            'source': source,
            'image_url': imageUrl,
          })
          .select()
          .single();

      final saved = NutritionLog.fromMap(inserted);
      logs.value = [saved, ...logs.value];
      await _persistLocalLogs();
      return;
    }

    final localLog = NutritionLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      productName: productName,
      loggedAt: loggedAt,
      barcode: barcode,
      calories: calories,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      servingSize: servingSize,
      servings: servings,
      source: source,
      imageUrl: imageUrl,
    );
    logs.value = [localLog, ...logs.value];
    await _persistLocalLogs();
  }

  Future<void> deleteLog(String id) async {
    if (SupabaseService.isSignedIn) {
      await SupabaseService.client.from('nutrition_logs').delete().eq('id', id);
    }

    logs.value = logs.value.where((log) => log.id != id).toList();
    await _persistLocalLogs();
  }

  void clear() {
    logs.value = [];
  }

  DateTime _timestampForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    if (target == today) return now;
    return DateTime(day.year, day.month, day.day, 12);
  }

  Future<void> _loadLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStorageKey);
    if (raw == null || raw.isEmpty) {
      logs.value = [];
      return;
    }

    final decoded = jsonDecode(raw) as List;
    logs.value = decoded
        .cast<Map<String, dynamic>>()
        .map(NutritionLog.fromLocalMap)
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  Future<void> _persistLocalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(logs.value.map((log) => log.toLocalMap()).toList());
    await prefs.setString(_localStorageKey, encoded);
  }
}
