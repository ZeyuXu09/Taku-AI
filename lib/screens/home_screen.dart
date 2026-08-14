import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakform_ai/models/nutrition_log.dart';
import 'package:peakform_ai/models/scheduled_game.dart';
import 'package:peakform_ai/services/game_schedule_service.dart';
import 'package:peakform_ai/services/nutrition_log_service.dart';
import 'package:peakform_ai/services/training_plan_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/services/workout_log_service.dart';
import 'package:peakform_ai/utils/training_streak.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/utils/game_format.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/profile_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onStartTraining,
    this.onNavTap,
  });

  final VoidCallback? onStartTraining;
  final ValueChanged<int>? onNavTap;

  static const _workoutImageUrl =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80';

  static final _numberFormat = NumberFormat('#,###');

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatMacro(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}g';
    }
    return '${value.toStringAsFixed(1)}g';
  }

  static String _formatCaloriesShort(double calories) {
    if (calories >= 1000) {
      final k = calories / 1000;
      return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
    }
    return calories.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _sectionTitle("Today's Training"),
                    const SizedBox(height: 12),
                    _buildWorkoutCard(),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<List<NutritionLog>>(
                      valueListenable: NutritionLogService.instance.logs,
                      builder: (context, _, __) {
                        final totals =
                            NutritionLogService.instance.totalsForDay(_today());
                        return ValueListenableBuilder(
                          valueListenable:
                              TrainingPreferencesService.instance.preferences,
                          builder: (context, _, __) {
                            return ValueListenableBuilder<List<DateTime>>(
                              valueListenable:
                                  WorkoutLogService.instance.completedDays,
                              builder: (context, _, __) {
                                final streak =
                                    WorkoutLogService.instance.streakFor();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatsRow(totals, streak),
                                    const SizedBox(height: 24),
                                    _sectionTitle('Nutrition Today'),
                                    const SizedBox(height: 12),
                                    _buildNutritionCard(totals),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Next Game'),
                    const SizedBox(height: 12),
                    _buildNextGameCard(),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 0,
              onTap: onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder(
          valueListenable: UserProfileService.instance.profile,
          builder: (context, _, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  UserProfileService.instance.displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            );
          },
        ),
        ProfileAvatar(
          radius: 22,
          onTap: () => onNavTap?.call(4),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard() {
    return ValueListenableBuilder(
      valueListenable: TrainingSessionOverrideService.instance.changes,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: TrainingPreferencesService.instance.preferences,
          builder: (context, _, __) {
            final session = TrainingPlanService.instance.todaySession();
        final exerciseLabel = session.isRestDay
            ? '${session.routines.length} recovery'
            : '${session.exerciseCount} exercises';

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _workoutImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.card),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xF2000000),
                        Color(0x99000000),
                        Color(0x33000000),
                      ],
                      stops: [0.15, 0.55, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          session.isRestDay
                              ? 'Recovery day · ${session.sportSummary}'
                              : '${session.title} for ${session.sportSummary}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _metaItem(
                            Icons.schedule_rounded,
                            '${session.durationMinutes} min',
                          ),
                          const SizedBox(width: 14),
                          _metaItem(
                            Icons.local_fire_department_rounded,
                            '${session.estimatedCalories} cal',
                          ),
                          const SizedBox(width: 14),
                          _metaItem(Icons.fitness_center_rounded, exerciseLabel),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: onStartTraining,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            session.isRestDay ? 'View' : 'Start',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(NutritionDayTotals totals, TrainingStreakStats streak) {
    return Row(
      children: [
        Expanded(child: _statCard('${streak.dayStreak}', 'Day Streak')),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '${streak.sessionsThisWeek}/${streak.weeklyGoal}',
            'This Week',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            _formatCaloriesShort(totals.calories),
            'Calories',
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(NutritionDayTotals totals) {
    final calorieProgress =
        (totals.calories / NutritionLogService.calorieGoal).clamp(0.0, 1.0);
    final proteinProgress =
        (totals.proteinG / NutritionLogService.proteinGoalG).clamp(0.0, 1.0);
    final carbsProgress =
        (totals.carbsG / NutritionLogService.carbsGoalG).clamp(0.0, 1.0);
    final fatProgress =
        (totals.fatG / NutritionLogService.fatGoalG).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: _CalorieRing(
              progress: calorieProgress,
              caloriesLabel: _numberFormat.format(totals.calories.round()),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _macroRow(
                  'Protein',
                  '${_formatMacro(totals.proteinG)} / ${_formatMacro(NutritionLogService.proteinGoalG)}',
                  proteinProgress,
                  AppColors.accent,
                ),
                const SizedBox(height: 12),
                _macroRow(
                  'Carbs',
                  '${_formatMacro(totals.carbsG)} / ${_formatMacro(NutritionLogService.carbsGoalG)}',
                  carbsProgress,
                  AppColors.green,
                ),
                const SizedBox(height: 12),
                _macroRow(
                  'Fat',
                  '${_formatMacro(totals.fatG)} / ${_formatMacro(NutritionLogService.fatGoalG)}',
                  fatProgress,
                  AppColors.yellow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(
    String name,
    String amount,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.barTrack,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNextGameCard() {
    return ValueListenableBuilder<List<ScheduledGame>>(
      valueListenable: GameScheduleService.instance.games,
      builder: (context, _, __) {
        final nextGame = GameScheduleService.instance.nextGame;
        if (nextGame == null) {
          return _buildEmptyNextGameCard();
        }
        return _buildNextGameCardContent(nextGame);
      },
    );
  }

  Widget _buildEmptyNextGameCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nextGameStart, AppColors.nextGameEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 32,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming games',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a game in Schedule',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => onNavTap?.call(1),
            child: const Text(
              'Go to Schedule',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextGameCardContent(ScheduledGame game) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nextGameStart, AppColors.nextGameEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            GameFormat.countdownLabel(game.gameAt),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _teamBadge(
                game.userTeamLetter,
                game.userTeamName,
                game.userTeamGradient,
              ),
              const SizedBox(width: 16),
              Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navInactive,
                ),
              ),
              const SizedBox(width: 16),
              _teamBadge(
                game.opponentLetter,
                game.opponentName,
                game.opponentGradient,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            GameFormat.shortDateTime(game.gameAt),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              game.isHome ? 'Home game — prep starts today' : 'Away game — travel ready',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamBadge(String letter, String name, List<Color> gradientColors) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.progress,
    required this.caloriesLabel,
  });

  final double progress;
  final String caloriesLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(100, 100),
          painter: _RingPainter(progress: progress),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caloriesLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'calories',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;
  static const _strokeWidth = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.barTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final progressPaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
