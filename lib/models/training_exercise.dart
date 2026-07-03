import 'package:peakform_ai/models/training_intensity.dart';

enum TrainingFocus {
  power,
  agility,
  strength,
  speed,
  endurance,
  recovery,
  mixed,
}

class TrainingExercise {
  const TrainingExercise({
    required this.id,
    required this.name,
    required this.focus,
    required this.focusTags,
    required this.sports,
    required this.casualPrescription,
    required this.seriousPrescription,
    required this.professionalPrescription,
    this.imageUrl,
    this.isWarmup = false,
    this.isCooldown = false,
  });

  final String id;
  final String name;
  final TrainingFocus focus;
  final List<String> focusTags;
  final List<String> sports;
  final String casualPrescription;
  final String seriousPrescription;
  final String professionalPrescription;
  final String? imageUrl;
  final bool isWarmup;
  final bool isCooldown;

  String prescriptionFor(TrainingIntensity intensity) {
    switch (intensity) {
      case TrainingIntensity.casual:
        return casualPrescription;
      case TrainingIntensity.serious:
        return seriousPrescription;
      case TrainingIntensity.professional:
        return professionalPrescription;
    }
  }
}

class ScheduledExercise {
  const ScheduledExercise({
    required this.exercise,
    required this.prescription,
  });

  final TrainingExercise exercise;
  final String prescription;

  String get name => exercise.name;
  String? get imageUrl => exercise.imageUrl;
}
