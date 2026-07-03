import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:peakform_ai/models/scheduled_game.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:postgrest/postgrest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameScheduleService {
  GameScheduleService._();

  static final GameScheduleService instance = GameScheduleService._();
  static const _localStorageKey = 'local_scheduled_games';

  final ValueNotifier<List<ScheduledGame>> games = ValueNotifier([]);

  ScheduledGame? get nextGame {
    final now = DateTime.now();
    final upcoming = games.value
        .where((game) => game.gameAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<ScheduledGame> gamesOnDay(DateTime day) {
    return games.value.where((game) => game.isSameDay(day)).toList()
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
  }

  Set<int> gameDaysInMonth(DateTime month) {
    return games.value
        .where(
          (game) =>
              game.gameAt.year == month.year && game.gameAt.month == month.month,
        )
        .map((game) => game.gameAt.day)
        .toSet();
  }

  List<ScheduledGame> upcomingGames({DateTime? fromDay}) {
    final now = DateTime.now();
    final start = fromDay == null
        ? now
        : DateTime(fromDay.year, fromDay.month, fromDay.day);

    return games.value
        .where((game) => !game.gameAt.isBefore(start))
        .toList()
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
  }

  static String friendlyError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('scheduled_games') &&
          (message.contains('does not exist') || message.contains('schema cache'))) {
        return 'Games table missing. Run section 4 of supabase/schema.sql in Supabase.';
      }
      if (message.contains('foreign key') || message.contains('profiles')) {
        return 'Profile row missing. Sign out and sign back in, then retry.';
      }
      return error.message;
    }
    return error.toString();
  }

  Future<void> loadGames() async {
    if (SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.ensureProfileRow();
        final userId = SupabaseService.currentUser!.id;
        final rows = await SupabaseService.client
            .from('scheduled_games')
            .select()
            .eq('user_id', userId)
            .order('game_at', ascending: true);

        games.value = (rows as List)
            .cast<Map<String, dynamic>>()
            .map(ScheduledGame.fromMap)
            .toList();
        await _persistLocalGames();
        return;
      } catch (error) {
        debugPrint('GameScheduleService.loadGames supabase error: $error');
      }
    }

    await _loadLocalGames();
  }

  Future<void> addGame({
    required String opponentName,
    required DateTime gameAt,
    required bool isHome,
    String? userTeamName,
  }) async {
    final teamName = userTeamName ?? _defaultTeamName();

    if (SupabaseService.isSignedIn) {
      await UserProfileService.instance.ensureProfileRow();
      final userId = SupabaseService.currentUser!.id;

      final inserted = await SupabaseService.client
          .from('scheduled_games')
          .insert({
            'user_id': userId,
            'opponent_name': opponentName.trim(),
            'game_at': gameAt.toUtc().toIso8601String(),
            'is_home': isHome,
            'user_team_name': teamName.trim(),
          })
          .select()
          .single();

      final saved = ScheduledGame.fromMap(inserted);
      games.value = [...games.value, saved]
        ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
      await _persistLocalGames();
      return;
    }

    final localGame = ScheduledGame(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      opponentName: opponentName,
      gameAt: gameAt,
      isHome: isHome,
      userTeamName: teamName,
    );
    games.value = [...games.value, localGame]
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
    await _persistLocalGames();
  }

  Future<void> updateGame({
    required String id,
    required String opponentName,
    required DateTime gameAt,
    required bool isHome,
    String? userTeamName,
  }) async {
    final teamName = userTeamName ?? _defaultTeamName();

    if (SupabaseService.isSignedIn) {
      await UserProfileService.instance.ensureProfileRow();

      final updated = await SupabaseService.client
          .from('scheduled_games')
          .update({
            'opponent_name': opponentName.trim(),
            'game_at': gameAt.toUtc().toIso8601String(),
            'is_home': isHome,
            'user_team_name': teamName.trim(),
          })
          .eq('id', id)
          .select()
          .single();

      final saved = ScheduledGame.fromMap(updated);
      games.value = [
        for (final game in games.value) if (game.id == id) saved else game,
      ]..sort((a, b) => a.gameAt.compareTo(b.gameAt));
      await _persistLocalGames();
      return;
    }

    games.value = [
      for (final game in games.value)
        if (game.id == id)
          ScheduledGame(
            id: id,
            opponentName: opponentName,
            gameAt: gameAt,
            isHome: isHome,
            userTeamName: teamName,
          )
        else
          game,
    ]..sort((a, b) => a.gameAt.compareTo(b.gameAt));
    await _persistLocalGames();
  }

  Future<void> deleteGame(String id) async {
    if (SupabaseService.isSignedIn) {
      await SupabaseService.client
          .from('scheduled_games')
          .delete()
          .eq('id', id);
    }

    games.value = games.value.where((game) => game.id != id).toList();
    await _persistLocalGames();
  }

  void clear() {
    games.value = [];
  }

  String _defaultTeamName() {
    final profileName = UserProfileService.instance.displayName;
    if (profileName == 'Athlete') return 'My Team';
    return profileName.split(' ').first;
  }

  Future<void> _loadLocalGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStorageKey);
    if (raw == null || raw.isEmpty) {
      games.value = [];
      return;
    }

    final decoded = jsonDecode(raw) as List;
    games.value = decoded
        .cast<Map<String, dynamic>>()
        .map(ScheduledGame.fromLocalMap)
        .toList()
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));
  }

  Future<void> _persistLocalGames() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(games.value.map((g) => g.toLocalMap()).toList());
    await prefs.setString(_localStorageKey, encoded);
  }
}
