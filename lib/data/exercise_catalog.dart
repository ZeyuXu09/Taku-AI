import 'package:peakform_ai/data/gym_exercise_library.dart';
import 'package:peakform_ai/data/home_exercise_library.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_location.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';

/// Active library based on user preference.
List<TrainingExercise> activeExerciseLibrary() {
  return exerciseLibraryFor(
    TrainingPreferencesService.instance.preferences.value.location,
  );
}

List<TrainingExercise> exerciseLibraryFor(TrainingLocation location) {
  switch (location) {
    case TrainingLocation.home:
      return homeExerciseLibrary;
    case TrainingLocation.gym:
      return gymExerciseLibrary;
  }
}

TrainingExercise? exerciseById(String id) {
  for (final exercise in homeExerciseLibrary) {
    if (exercise.id == id) return exercise;
  }
  for (final exercise in gymExerciseLibrary) {
    if (exercise.id == id) return exercise;
  }
  return null;
}

/// Backward-compatible alias for the home library.
const exerciseLibrary = homeExerciseLibrary;
