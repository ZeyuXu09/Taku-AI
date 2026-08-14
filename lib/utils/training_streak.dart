class TrainingStreakStats {
  const TrainingStreakStats({
    required this.dayStreak,
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    required this.totalSessions,
  });

  final int dayStreak;
  final int sessionsThisWeek;
  final int weeklyGoal;
  final int totalSessions;
}

DateTime trainingDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime mondayOf(DateTime value) {
  final day = trainingDateOnly(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

int sessionsInWeek(Iterable<DateTime> completedDays, DateTime monday) {
  final start = trainingDateOnly(monday);
  final end = start.add(const Duration(days: 6));
  return completedDays
      .map(trainingDateOnly)
      .toSet()
      .where((day) => !day.isBefore(start) && !day.isAfter(end))
      .length;
}

/// Day streak starts on the first completed workout and stays alive as long as
/// every *finished* week hit [weeklyGoal]. The current week can still be in
/// progress. Missing the weekly goal ends the streak at 0.
TrainingStreakStats computeTrainingStreak({
  required Iterable<DateTime> completedDays,
  required int weeklyGoal,
  required DateTime now,
}) {
  final goal = weeklyGoal < 1 ? 1 : weeklyGoal;
  final days = completedDays.map(trainingDateOnly).toSet();
  final today = trainingDateOnly(now);
  final currentMonday = mondayOf(today);
  final sessionsThisWeek = sessionsInWeek(days, currentMonday);

  if (days.isEmpty) {
    return TrainingStreakStats(
      dayStreak: 0,
      sessionsThisWeek: 0,
      weeklyGoal: goal,
      totalSessions: 0,
    );
  }

  final firstEver = days.reduce((a, b) => a.isBefore(b) ? a : b);
  final firstMonday = mondayOf(firstEver);

  DateTime? oldestSuccessfulMonday;
  var cursor = currentMonday.subtract(const Duration(days: 7));
  while (!cursor.isBefore(firstMonday)) {
    if (sessionsInWeek(days, cursor) >= goal) {
      oldestSuccessfulMonday = cursor;
      cursor = cursor.subtract(const Duration(days: 7));
    } else {
      break;
    }
  }

  final DateTime? streakStart;
  if (oldestSuccessfulMonday != null) {
    streakStart = _firstSessionInWeek(days, oldestSuccessfulMonday);
  } else if (sessionsThisWeek > 0) {
    streakStart = _firstSessionInWeek(days, currentMonday);
  } else {
    streakStart = null;
  }

  final dayStreak = streakStart == null
      ? 0
      : today.difference(streakStart).inDays + 1;

  return TrainingStreakStats(
    dayStreak: dayStreak,
    sessionsThisWeek: sessionsThisWeek,
    weeklyGoal: goal,
    totalSessions: days.length,
  );
}

DateTime? _firstSessionInWeek(Set<DateTime> days, DateTime monday) {
  final start = trainingDateOnly(monday);
  final end = start.add(const Duration(days: 6));
  final inWeek = days
      .where((day) => !day.isBefore(start) && !day.isAfter(end))
      .toList()
    ..sort();
  return inWeek.isEmpty ? null : inWeek.first;
}
