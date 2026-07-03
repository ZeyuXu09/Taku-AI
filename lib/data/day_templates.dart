import 'package:flutter/material.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_intensity.dart';

/// Focus options users can pick for today (includes endurance; not in weekday rotation).
const selectableTrainingFocuses = <TrainingFocus>[
  TrainingFocus.power,
  TrainingFocus.agility,
  TrainingFocus.strength,
  TrainingFocus.speed,
  TrainingFocus.endurance,
  TrainingFocus.mixed,
  TrainingFocus.recovery,
];

IconData iconForFocus(TrainingFocus focus) {
  switch (focus) {
    case TrainingFocus.power:
      return Icons.bolt_rounded;
    case TrainingFocus.agility:
      return Icons.directions_run_rounded;
    case TrainingFocus.strength:
      return Icons.fitness_center_rounded;
    case TrainingFocus.speed:
      return Icons.speed_rounded;
    case TrainingFocus.endurance:
      return Icons.favorite_outline_rounded;
    case TrainingFocus.recovery:
      return Icons.self_improvement_rounded;
    case TrainingFocus.mixed:
      return Icons.shuffle_rounded;
  }
}

/// Weekday focus rotation (Mon=1 … Sun=7).
TrainingFocus focusForWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return TrainingFocus.power;
    case DateTime.tuesday:
      return TrainingFocus.agility;
    case DateTime.wednesday:
      return TrainingFocus.strength;
    case DateTime.thursday:
      return TrainingFocus.recovery;
    case DateTime.friday:
      return TrainingFocus.speed;
    case DateTime.saturday:
      return TrainingFocus.mixed;
    case DateTime.sunday:
    default:
      return TrainingFocus.recovery;
  }
}

String titleForFocus(TrainingFocus focus) {
  switch (focus) {
    case TrainingFocus.power:
      return 'Explosive Power';
    case TrainingFocus.agility:
      return 'Pre-Game Agility';
    case TrainingFocus.strength:
      return 'Strength Foundation';
    case TrainingFocus.speed:
      return 'Speed & Conditioning';
    case TrainingFocus.endurance:
      return 'Endurance Boost';
    case TrainingFocus.recovery:
      return 'Active Recovery';
    case TrainingFocus.mixed:
      return 'Mixed Session';
  }
}

String descriptionForFocus(TrainingFocus focus) {
  switch (focus) {
    case TrainingFocus.power:
      return 'Power & explosiveness. Build force for your next game.';
    case TrainingFocus.agility:
      return 'Agility & speed. Quick feet and sharp direction changes.';
    case TrainingFocus.strength:
      return 'Strength & stability. Support joints and power output.';
    case TrainingFocus.speed:
      return 'Speed & conditioning. Raise your engine for match day.';
    case TrainingFocus.endurance:
      return 'Endurance work. Sustain effort through long sessions.';
    case TrainingFocus.recovery:
      return 'Mobility & recovery. Reset and stay ready to train.';
    case TrainingFocus.mixed:
      return 'Mixed training. A balanced blend of strength and conditioning.';
  }
}

bool isTrainingDay(TrainingIntensity intensity, int weekday) {
  switch (intensity) {
    case TrainingIntensity.casual:
      return weekday == DateTime.monday ||
          weekday == DateTime.wednesday ||
          weekday == DateTime.friday;
    case TrainingIntensity.serious:
      return weekday != DateTime.thursday && weekday != DateTime.sunday;
    case TrainingIntensity.professional:
      return weekday != DateTime.sunday;
  }
}

int baseDurationMinutes(TrainingIntensity intensity, {required bool isRestDay}) {
  if (isRestDay) {
    switch (intensity) {
      case TrainingIntensity.casual:
        return 15;
      case TrainingIntensity.serious:
        return 20;
      case TrainingIntensity.professional:
        return 25;
    }
  }
  switch (intensity) {
    case TrainingIntensity.casual:
      return 30;
    case TrainingIntensity.serious:
      return 45;
    case TrainingIntensity.professional:
      return 60;
  }
}

int estimatedCalories(TrainingIntensity intensity, int durationMinutes) {
  final rate = switch (intensity) {
    TrainingIntensity.casual => 7,
    TrainingIntensity.serious => 8,
    TrainingIntensity.professional => 10,
  };
  return durationMinutes * rate;
}
