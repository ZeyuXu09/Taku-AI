import 'package:peakform_ai/data/day_templates.dart';
import 'package:peakform_ai/data/exercise_catalog.dart';
import 'package:peakform_ai/data/sport_catalog.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_intensity.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';

class TrainingPlanService {
  TrainingPlanService._();

  static final TrainingPlanService instance = TrainingPlanService._();

  TrainingSession todaySession() => sessionForDate(DateTime.now());

  TrainingSession sessionForDate(DateTime date) {
    final prefs = TrainingPreferencesService.instance.preferences.value;
    final sports = prefs.sports.isEmpty
        ? [SportCatalog.defaultSport]
        : prefs.sports;
    final intensity = prefs.intensity;
    final override =
        TrainingSessionOverrideService.instance.overrideFor(date);
    final scheduledFocus = focusForWeekday(date.weekday);
    final focus = override.focusOverride ?? scheduledFocus;
    final isFocusCustomized = override.focusOverride != null;
    final isRestDay = isFocusCustomized
        ? focus == TrainingFocus.recovery
        : !isTrainingDay(intensity, date.weekday);

    if (isRestDay) {
      return _applyRoutineOverride(
        base: _restDaySession(
          date: date,
          sports: sports,
          intensity: intensity,
          rotationOffset: override.rotationOffset,
          scheduledFocus: scheduledFocus,
          focus: focus,
          isFocusCustomized: isFocusCustomized,
        ),
        override: override,
        intensity: intensity,
      );
    }

    final exerciseCount = intensity.exerciseCount;
    final mainExercises = _pickExercises(
      focus: focus,
      sports: sports,
      intensity: intensity,
      date: date,
      count: exerciseCount,
      rotationOffset: override.rotationOffset,
    );

    final routines = _pickRoutines(
      sports: sports,
      intensity: intensity,
      date: date,
      count: 2,
      rotationOffset: override.rotationOffset,
    );

    final duration = baseDurationMinutes(intensity, isRestDay: false);
    final title = titleForFocus(focus);

    final base = TrainingSession(
      title: title,
      focus: focus,
      scheduledFocus: scheduledFocus,
      isFocusCustomized: isFocusCustomized,
      exercises: mainExercises,
      routines: routines,
      durationMinutes: duration,
      estimatedCalories: estimatedCalories(intensity, duration),
      programDescription: descriptionForFocus(focus),
      sportSummary: _sportSummary(sports),
      intensity: intensity,
    );

    return _applyFullOverride(
      base: base,
      override: override,
      intensity: intensity,
    );
  }

  List<TrainingExercise> alternativesFor({
    required TrainingFocus focus,
    required Set<String> excludeIds,
    bool includeRecovery = false,
  }) {
    return activeExerciseLibrary().where((exercise) {
      if (excludeIds.contains(exercise.id)) return false;
      if (exercise.isWarmup || exercise.isCooldown) return false;
      if (!includeRecovery && exercise.focus == TrainingFocus.recovery) {
        return false;
      }
      if (focus == TrainingFocus.mixed) return true;
      return exercise.focus == focus || exercise.focus == TrainingFocus.mixed;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<TrainingExercise> routineAlternatives({required Set<String> excludeIds}) {
    return activeExerciseLibrary().where((exercise) {
      if (excludeIds.contains(exercise.id)) return false;
      return exercise.isCooldown || exercise.focus == TrainingFocus.recovery;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  TrainingSession _applyFullOverride({
    required TrainingSession base,
    required DailyWorkoutOverride override,
    required TrainingIntensity intensity,
  }) {
    var exercises = base.exercises;
    var routines = base.routines;

    if (override.exerciseIds.isNotEmpty) {
      final custom = _exercisesFromIds(override.exerciseIds, intensity);
      if (custom.isNotEmpty) {
        exercises = custom;
      }
    }
    if (override.routineIds.isNotEmpty) {
      final custom = _exercisesFromIds(override.routineIds, intensity);
      if (custom.isNotEmpty) {
        routines = custom;
      }
    }

    return TrainingSession(
      title: base.title,
      focus: base.focus,
      scheduledFocus: base.scheduledFocus,
      isFocusCustomized: base.isFocusCustomized,
      exercises: exercises,
      routines: routines,
      durationMinutes: base.durationMinutes,
      estimatedCalories: base.estimatedCalories,
      programDescription: base.programDescription,
      sportSummary: base.sportSummary,
      intensity: base.intensity,
      isRestDay: base.isRestDay,
    );
  }

  TrainingSession _applyRoutineOverride({
    required TrainingSession base,
    required DailyWorkoutOverride override,
    required TrainingIntensity intensity,
  }) {
    if (override.routineIds.isEmpty) return base;

    final routines = _exercisesFromIds(override.routineIds, intensity);
    if (routines.isEmpty) return base;

    return TrainingSession(
      title: base.title,
      focus: base.focus,
      scheduledFocus: base.scheduledFocus,
      isFocusCustomized: base.isFocusCustomized,
      exercises: base.exercises,
      routines: routines,
      durationMinutes: base.durationMinutes,
      estimatedCalories: base.estimatedCalories,
      programDescription: base.programDescription,
      sportSummary: base.sportSummary,
      intensity: base.intensity,
      isRestDay: base.isRestDay,
    );
  }

  List<ScheduledExercise> _exercisesFromIds(
    List<String> ids,
    TrainingIntensity intensity,
  ) {
    final activeIds =
        activeExerciseLibrary().map((exercise) => exercise.id).toSet();
    final result = <ScheduledExercise>[];
    for (final id in ids) {
      if (!activeIds.contains(id)) continue;
      final exercise = exerciseById(id);
      if (exercise == null) continue;
      result.add(
        ScheduledExercise(
          exercise: exercise,
          prescription: exercise.prescriptionFor(intensity),
        ),
      );
    }
    return result;
  }

  TrainingSession _restDaySession({
    required DateTime date,
    required List<String> sports,
    required TrainingIntensity intensity,
    required TrainingFocus scheduledFocus,
    required TrainingFocus focus,
    required bool isFocusCustomized,
    int rotationOffset = 0,
  }) {
    final routines = _pickRoutines(
      sports: sports,
      intensity: intensity,
      date: date,
      count: 3,
      rotationOffset: rotationOffset,
    );

    final duration = baseDurationMinutes(intensity, isRestDay: true);
    final title = isFocusCustomized
        ? titleForFocus(focus)
        : 'Rest & Recovery';
    final description = isFocusCustomized
        ? descriptionForFocus(focus)
        : 'Light mobility today. Your ${intensity.label.toLowerCase()} plan schedules rest — stay loose and recover.';

    return TrainingSession(
      title: title,
      focus: focus,
      scheduledFocus: scheduledFocus,
      isFocusCustomized: isFocusCustomized,
      exercises: const [],
      routines: routines,
      durationMinutes: duration,
      estimatedCalories: estimatedCalories(intensity, duration),
      programDescription: description,
      sportSummary: _sportSummary(sports),
      intensity: intensity,
      isRestDay: true,
    );
  }

  List<ScheduledExercise> _pickExercises({
    required TrainingFocus focus,
    required List<String> sports,
    required TrainingIntensity intensity,
    required DateTime date,
    required int count,
    int rotationOffset = 0,
  }) {
    final pool = activeExerciseLibrary()
        .where(
          (exercise) =>
              exercise.focus == focus &&
              !exercise.isWarmup &&
              !exercise.isCooldown,
        )
        .toList();

    if (pool.isEmpty) {
      return _pickFromMixed(
        sports,
        intensity,
        date,
        count,
        rotationOffset: rotationOffset,
      );
    }

    return _selectFromPool(
      pool,
      sports,
      intensity,
      date,
      count,
      rotationOffset: rotationOffset,
    );
  }

  List<ScheduledExercise> _pickFromMixed(
    List<String> sports,
    TrainingIntensity intensity,
    DateTime date,
    int count, {
    int rotationOffset = 0,
  }) {
    final pool = activeExerciseLibrary()
        .where((e) => !e.isWarmup && !e.isCooldown)
        .toList();
    return _selectFromPool(
      pool,
      sports,
      intensity,
      date,
      count,
      rotationOffset: rotationOffset,
    );
  }

  List<ScheduledExercise> _pickRoutines({
    required List<String> sports,
    required TrainingIntensity intensity,
    required DateTime date,
    required int count,
    int rotationOffset = 0,
  }) {
    final pool = activeExerciseLibrary()
        .where((e) => e.isCooldown || e.focus == TrainingFocus.recovery)
        .toList();
    return _selectFromPool(
      pool,
      sports,
      intensity,
      date,
      count,
      rotationOffset: rotationOffset,
    );
  }

  List<ScheduledExercise> _selectFromPool(
    List<TrainingExercise> pool,
    List<String> sports,
    TrainingIntensity intensity,
    DateTime date,
    int count, {
    int rotationOffset = 0,
  }) {
    if (pool.isEmpty) return const [];

    final scored = pool
        .map((exercise) => MapEntry(exercise, _scoreExercise(exercise, sports)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final week = _isoWeekNumber(date);
    final startIndex =
        (week * 7 + date.weekday + rotationOffset) % scored.length;
    final selected = <TrainingExercise>[];
    final usedIds = <String>{};

    for (var i = 0; selected.length < count && i < pool.length * 3; i++) {
      final index = (startIndex + i) % scored.length;
      final exercise = scored[index].key;
      if (usedIds.add(exercise.id)) {
        selected.add(exercise);
      }
    }

    return selected
        .map(
          (exercise) => ScheduledExercise(
            exercise: exercise,
            prescription: exercise.prescriptionFor(intensity),
          ),
        )
        .toList();
  }

  int _scoreExercise(TrainingExercise exercise, List<String> sports) {
    var score = 0;
    for (final sport in sports) {
      if (exercise.sports.contains(sport)) score += 3;
      for (final tag in sportPriorityTags[sport] ?? const []) {
        if (exercise.focusTags.contains(tag)) score += 1;
      }
    }
    return score;
  }

  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 4 - (date.weekday % 7)));
    final yearStart = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
  }

  String _sportSummary(List<String> sports) {
    if (sports.length == 1) return sports.first;
    if (sports.length == 2) return '${sports[0]} & ${sports[1]}';
    return '${sports.take(2).join(', ')} +${sports.length - 2}';
  }
}
