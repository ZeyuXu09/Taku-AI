import 'package:flutter/material.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/screens/active_workout_screen.dart';
import 'package:peakform_ai/screens/ai_coach_screen.dart';
import 'package:peakform_ai/screens/exercise_detail_screen.dart';
import 'package:peakform_ai/models/training_location.dart';
import 'package:peakform_ai/services/training_plan_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/change_focus_sheet.dart';
import 'package:peakform_ai/widgets/customize_workout_sheet.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/training_location_toggle.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({
    super.key,
    this.onBack,
    this.onNavTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TrainingSessionOverrideService.instance.changes,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: TrainingPreferencesService.instance.preferences,
          builder: (context, _, __) {
            final session = TrainingPlanService.instance.todaySession();
            final location =
                TrainingPreferencesService.instance.preferences.value.location;
            return _TrainingBody(
              session: session,
              location: location,
              onBack: onBack,
              onNavTap: onNavTap,
            );
          },
        );
      },
    );
  }
}

class _TrainingBody extends StatelessWidget {
  const _TrainingBody({
    required this.session,
    required this.location,
    this.onBack,
    this.onNavTap,
  });

  final TrainingSession session;
  final TrainingLocation location;
  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

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
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildFocusCard(context, session, location),
                    if (session.isRestDay) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        title: 'Recovery',
                      ),
                      const SizedBox(height: 12),
                      ...session.routines.map(
                        (routine) => _buildRoutineItem(context, routine),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      _buildExercisesHeader(context),
                      const SizedBox(height: 12),
                      ...session.exercises.map(
                        (exercise) => _buildExerciseItem(
                          context,
                          exercise,
                          key: ValueKey(exercise.exercise.id),
                        ),
                      ),
                      if (session.routines.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle("Today's Routine"),
                        const SizedBox(height: 12),
                        ...session.routines.map(
                          (routine) => _buildRoutineItem(context, routine),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if ((!session.isRestDay && _hasWorkoutItems(session)) ||
                (session.isRestDay && session.routines.isNotEmpty))
              _buildWorkoutActions(context),
            PeakBottomNav(
              currentIndex: 2,
              onTap: onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _IconBoxButton(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 32,
          iconSize: 16,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "Today's Training",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TrainingLocationToggle(),
              const SizedBox(width: 8),
              _IconBoxButton(
                icon: Icons.tune_rounded,
                onTap: () => _openCustomize(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openChangeFocus(BuildContext context) {
    showChangeFocusSheet(context, session: session);
  }

  Widget _buildFocusCard(
    BuildContext context,
    TrainingSession session,
    TrainingLocation location,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChangeFocus(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.isRestDay ? 'REST DAY' : "TODAY'S FOCUS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (session.isFocusCustomized)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.yellow,
                    ),
                  ),
                ),
              if (session.isFocusCustomized) const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      location == TrainingLocation.gym
                          ? Icons.fitness_center_rounded
                          : Icons.home_rounded,
                      size: 11,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location.label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _focusStat(Icons.schedule_rounded, '${session.durationMinutes} min'),
              _focusStat(
                Icons.local_fire_department_rounded,
                '${session.estimatedCalories} cal',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  session.intensity.effortBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: 'Program: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                TextSpan(text: session.programDescription),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: 'Your sports: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                TextSpan(text: session.sportSummary),
                if (session.focusBenefitsSummary.isNotEmpty) ...[
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: 'This focus helps most: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  TextSpan(text: session.focusBenefitsSummary),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: AppColors.accent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Change focus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _focusStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  void _openCustomize(BuildContext context) {
    showCustomizeWorkoutSheet(context, session: session);
  }

  Widget _buildExercisesHeader(BuildContext context) {
    return _buildSectionHeader(context, title: 'Exercises');
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Row(
      children: [
        Expanded(child: _sectionTitle(title)),
        TextButton.icon(
          onPressed: () => _openCustomize(context),
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('Customize'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  Widget _buildExerciseItem(
    BuildContext context,
    ScheduledExercise exercise, {
    Key? key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openExerciseDetail(context, exercise),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: exercise.imageUrl != null
                      ? Image.network(
                          exercise.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _exercisePlaceholder(),
                        )
                      : _exercisePlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.prescription,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                _InfoButton(
                  onTap: () => openExerciseDetail(context, exercise),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exercisePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.barTrack,
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildRoutineItem(BuildContext context, ScheduledExercise routine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openExerciseDetail(context, routine),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        routine.prescription,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _InfoButton(
                  onTap: () => openExerciseDetail(context, routine),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasWorkoutItems(TrainingSession session) {
    return session.exercises.isNotEmpty || session.routines.isNotEmpty;
  }

  Widget _buildWorkoutActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.green, Color(0xFF00C853)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openActiveWorkout(context, session: session),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: AppColors.background, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (routeContext) => AiCoachScreen(
                        onBack: () => Navigator.of(routeContext).pop(),
                        onNavTap: (index) {
                          Navigator.of(routeContext).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onNavTap?.call(index);
                          });
                        },
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Start with AI Coach',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBoxButton extends StatelessWidget {
  const _IconBoxButton({
    required this.icon,
    this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.info_outline_rounded,
            color: AppColors.accent,
            size: 20,
          ),
        ),
      ),
    );
  }
}
