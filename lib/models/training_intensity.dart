enum TrainingIntensity {
  casual,
  serious,
  professional;

  String get label {
    switch (this) {
      case TrainingIntensity.casual:
        return 'Casual';
      case TrainingIntensity.serious:
        return 'Serious';
      case TrainingIntensity.professional:
        return 'Professional';
    }
  }

  String get effortBadge {
    switch (this) {
      case TrainingIntensity.casual:
        return 'Light';
      case TrainingIntensity.serious:
        return 'Medium-High';
      case TrainingIntensity.professional:
        return 'High';
    }
  }

  int get exerciseCount {
    switch (this) {
      case TrainingIntensity.casual:
        return 4;
      case TrainingIntensity.serious:
        return 6;
      case TrainingIntensity.professional:
        return 8;
    }
  }

  /// Weekly training-day target used by the home streak.
  int get sessionsPerWeek {
    switch (this) {
      case TrainingIntensity.casual:
        return 3;
      case TrainingIntensity.serious:
        return 5;
      case TrainingIntensity.professional:
        return 6;
    }
  }

  String get weeklyGoalLabel =>
      '$sessionsPerWeek training${sessionsPerWeek == 1 ? '' : 's'} a week';

  static TrainingIntensity fromLabel(String? value) {
    switch (value?.toLowerCase()) {
      case 'casual':
        return TrainingIntensity.casual;
      case 'professional':
        return TrainingIntensity.professional;
      case 'serious':
      default:
        return TrainingIntensity.serious;
    }
  }
}
