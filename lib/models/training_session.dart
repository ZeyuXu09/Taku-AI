import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_intensity.dart';

class TrainingSession {
  const TrainingSession({
    required this.title,
    required this.focus,
    required this.exercises,
    required this.routines,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.programDescription,
    required this.sportSummary,
    required this.intensity,
    required this.scheduledFocus,
    this.isRestDay = false,
    this.isFocusCustomized = false,
  });

  final String title;
  final TrainingFocus focus;
  final TrainingFocus scheduledFocus;
  final bool isFocusCustomized;
  final List<ScheduledExercise> exercises;
  final List<ScheduledExercise> routines;
  final int durationMinutes;
  final int estimatedCalories;
  final String programDescription;
  final String sportSummary;
  final TrainingIntensity intensity;
  final bool isRestDay;

  int get exerciseCount => exercises.length;
}
