import 'package:flutter_test/flutter_test.dart';
import 'package:peakform_ai/utils/training_streak.dart';

void main() {
  const goal = 3;
  // Week of 10–16 Aug 2026 (Mon–Sun).
  final monday = DateTime(2026, 8, 10);
  final wednesday = DateTime(2026, 8, 12);
  final friday = DateTime(2026, 8, 14);
  final sunday = DateTime(2026, 8, 16);
  final nextMonday = DateTime(2026, 8, 17);

  test('streak is zero until the first training', () {
    final stats = computeTrainingStreak(
      completedDays: const [],
      weeklyGoal: goal,
      now: friday,
    );
    expect(stats.dayStreak, 0);
    expect(stats.sessionsThisWeek, 0);
  });

  test('streak starts the day you train', () {
    final stats = computeTrainingStreak(
      completedDays: [wednesday],
      weeklyGoal: goal,
      now: wednesday,
    );
    expect(stats.dayStreak, 1);
    expect(stats.sessionsThisWeek, 1);
  });

  test('keeps counting rest days during a week still in progress', () {
    final stats = computeTrainingStreak(
      completedDays: [monday, wednesday, friday],
      weeklyGoal: goal,
      now: sunday,
    );
    expect(stats.sessionsThisWeek, 3);
    expect(stats.dayStreak, sunday.difference(monday).inDays + 1);
  });

  test('ends the streak after a finished week that missed the goal', () {
    final stats = computeTrainingStreak(
      completedDays: [monday, wednesday],
      weeklyGoal: goal,
      now: nextMonday,
    );
    expect(stats.dayStreak, 0);
    expect(stats.sessionsThisWeek, 0);
  });

  test('starts a new streak after a missed week when you train again', () {
    final thisWednesday = DateTime(2026, 8, 19);
    final stats = computeTrainingStreak(
      completedDays: [monday, wednesday, thisWednesday],
      weeklyGoal: goal,
      now: thisWednesday,
    );
    expect(stats.dayStreak, 1);
    expect(stats.sessionsThisWeek, 1);
  });

  test('continues across weeks that hit the goal', () {
    final nextWednesday = DateTime(2026, 8, 19);
    final nextFriday = DateTime(2026, 8, 21);
    final stats = computeTrainingStreak(
      completedDays: [
        monday,
        wednesday,
        friday,
        nextMonday,
        nextWednesday,
        nextFriday,
      ],
      weeklyGoal: goal,
      now: nextFriday,
    );
    expect(stats.sessionsThisWeek, 3);
    expect(stats.dayStreak, nextFriday.difference(monday).inDays + 1);
  });
}
