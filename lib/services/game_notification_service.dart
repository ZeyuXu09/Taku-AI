import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:peakform_ai/models/scheduled_game.dart';
import 'package:peakform_ai/services/game_lock_screen_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a phone notification one day before each upcoming game.
class GameNotificationService {
  GameNotificationService._();

  static final GameNotificationService instance = GameNotificationService._();

  static const _pushKey = 'push_notifications_enabled';
  static const _gameDayKey = 'game_day_alerts_enabled';
  static const _channelId = 'game_day_alerts';
  static const _idRange = 710000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<bool> pushEnabled = ValueNotifier(true);
  final ValueNotifier<bool> gameDayAlertsEnabled = ValueNotifier(true);

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      debugPrint('GameNotificationService timezone: $error');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
    } catch (error) {
      debugPrint('GameNotificationService init: $error');
    }

    final prefs = await SharedPreferences.getInstance();
    pushEnabled.value = prefs.getBool(_pushKey) ?? true;
    gameDayAlertsEnabled.value = prefs.getBool(_gameDayKey) ?? true;
    _ready = true;
  }

  Future<void> setPushEnabled(bool value) async {
    pushEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, value);
  }

  Future<void> setGameDayAlertsEnabled(bool value) async {
    gameDayAlertsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gameDayKey, value);
  }

  Future<void> sync(List<ScheduledGame> games) async {
    await initialize();
    await GameLockScreenService.sync(games);
    await _cancelGameAlerts();

    if (!pushEnabled.value || !gameDayAlertsEnabled.value) return;

    final now = DateTime.now();
    final upcoming =
        games.where((game) => game.gameAt.isAfter(now)).toList();
    if (upcoming.isEmpty) return;

    final allowed = await _requestPermission();
    if (!allowed) return;

    for (final game in upcoming) {
      final planned = game.gameAt.subtract(const Duration(days: 1));
      final late = !planned.isAfter(now);
      final fireAt =
          late ? now.add(const Duration(seconds: 3)) : planned;
      await _schedule(game, fireAt, late: late);
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await GameLockScreenService.sync(const []);
    await _cancelGameAlerts();
  }

  Future<bool> _requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      final canExact = await android.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        await android.requestExactAlarmsPermission();
      }
      return granted ?? true;
    }

    return true;
  }

  Future<void> _schedule(
    ScheduledGame game,
    DateTime fireAt, {
    required bool late,
  }) async {
    final time = DateFormat('h:mm a').format(game.gameAt.toLocal());
    final place = game.isHome ? 'home' : 'away';
    final when = tz.TZDateTime.from(fireAt.toLocal(), tz.local);

    try {
      await _plugin.zonedSchedule(
        id: _idFor(game.id),
        scheduledDate: when,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: late ? 'Game soon' : 'Game tomorrow',
        body: 'vs ${game.opponentName.trim()} at $time · $place',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Game day alerts',
            channelDescription: 'Reminders the day before a scheduled game',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: game.id,
      );
    } catch (error) {
      debugPrint('GameNotificationService schedule: $error');
    }
  }

  Future<void> _cancelGameAlerts() async {
    await _plugin.cancelAll();
  }

  int _idFor(String gameId) {
    return _idRange + (gameId.hashCode & 0x7ffff);
  }
}
