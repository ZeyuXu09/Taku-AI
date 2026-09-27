import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:peakform_ai/models/scheduled_game.dart';

/// Pushes upcoming games to the iOS Lock Screen / Home Screen widget.
class GameLockScreenService {
  GameLockScreenService._();

  static const _channel = MethodChannel('peakform/lock_screen_games');

  static Future<void> sync(List<ScheduledGame> games) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    final now = DateTime.now();
    final upcoming = games.where((game) => game.gameAt.isAfter(now)).toList()
      ..sort((a, b) => a.gameAt.compareTo(b.gameAt));

    final payload = jsonEncode(
      upcoming.take(5).map((game) {
        return {
          'opponent': game.opponentName.trim(),
          'gameAtMs': game.gameAt.millisecondsSinceEpoch,
          'isHome': game.isHome,
        };
      }).toList(),
    );

    try {
      await _channel.invokeMethod('syncGames', payload);
    } catch (error) {
      debugPrint('GameLockScreenService: $error');
    }
  }
}
