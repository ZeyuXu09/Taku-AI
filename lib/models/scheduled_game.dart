import 'package:flutter/material.dart';
import 'package:peakform_ai/theme/app_colors.dart';

class ScheduledGame {
  const ScheduledGame({
    required this.id,
    required this.opponentName,
    required this.gameAt,
    required this.isHome,
    this.userTeamName = 'My Team',
  });

  final String id;
  final String opponentName;
  final DateTime gameAt;
  final bool isHome;
  final String userTeamName;

  String get opponentLetter {
    final trimmed = opponentName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String get userTeamLetter {
    final trimmed = userTeamName.trim();
    if (trimmed.isEmpty) return 'M';
    return trimmed[0].toUpperCase();
  }

  List<Color> get opponentGradient => _gradientForName(opponentName);

  List<Color> get userTeamGradient => _gradientForName(userTeamName);

  bool isSameDay(DateTime day) {
    return gameAt.year == day.year &&
        gameAt.month == day.month &&
        gameAt.day == day.day;
  }

  factory ScheduledGame.fromMap(Map<String, dynamic> map) {
    return ScheduledGame(
      id: map['id'] as String,
      opponentName: map['opponent_name'] as String,
      gameAt: DateTime.parse(map['game_at'] as String).toLocal(),
      isHome: map['is_home'] as bool? ?? true,
      userTeamName: map['user_team_name'] as String? ?? 'My Team',
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'opponent_name': opponentName.trim(),
      'game_at': gameAt.toUtc().toIso8601String(),
      'is_home': isHome,
      'user_team_name': userTeamName.trim(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'opponent_name': opponentName,
      'game_at': gameAt.toIso8601String(),
      'is_home': isHome,
      'user_team_name': userTeamName,
    };
  }

  factory ScheduledGame.fromLocalMap(Map<String, dynamic> map) {
    return ScheduledGame(
      id: map['id'] as String,
      opponentName: map['opponent_name'] as String,
      gameAt: DateTime.parse(map['game_at'] as String),
      isHome: map['is_home'] as bool? ?? true,
      userTeamName: map['user_team_name'] as String? ?? 'My Team',
    );
  }

  static List<Color> _gradientForName(String name) {
    const palettes = [
      [Color(0xFFF97316), Color(0xFFFB923C)],
      [Color(0xFF6366F1), Color(0xFF818CF8)],
      [Color(0xFFEF4444), Color(0xFFF87171)],
      [AppColors.accent, Color(0xFF8183F4)],
      [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
    ];
    final index = name.trim().isEmpty
        ? 0
        : name.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % palettes.length;
    return palettes[index];
  }
}
