import 'package:flutter/material.dart';

/// Exercises the live AI coach can analyze.
enum CoachExercise { pushup, plank, bicepCurl, downwardDog }

extension CoachExerciseInfo on CoachExercise {
  String get title => switch (this) {
        CoachExercise.pushup => 'Push-ups',
        CoachExercise.plank => 'Plank',
        CoachExercise.bicepCurl => 'Bicep Curls',
        CoachExercise.downwardDog => 'Downward Dog',
      };

  String get description => switch (this) {
        CoachExercise.pushup => 'Counts reps and checks back & leg alignment.',
        CoachExercise.plank => 'Holds form on hips, shoulders and legs.',
        CoachExercise.bicepCurl => 'Counts curls and keeps your upper arm still.',
        CoachExercise.downwardDog => 'Guides you into the inverted-V hold.',
      };

  IconData get icon => switch (this) {
        CoachExercise.pushup => Icons.fitness_center,
        CoachExercise.plank => Icons.horizontal_rule,
        CoachExercise.bicepCurl => Icons.sports_mma,
        CoachExercise.downwardDog => Icons.self_improvement,
      };

  String get tag => isStatic ? 'Hold' : 'Reps';

  bool get isStatic =>
      this == CoachExercise.plank || this == CoachExercise.downwardDog;
}
