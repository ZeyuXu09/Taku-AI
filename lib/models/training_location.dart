enum TrainingLocation {
  home,
  gym;

  String get label {
    switch (this) {
      case TrainingLocation.home:
        return 'Home';
      case TrainingLocation.gym:
        return 'Gym';
    }
  }

  static TrainingLocation fromLabel(String? value) {
    switch (value?.toLowerCase()) {
      case 'gym':
        return TrainingLocation.gym;
      case 'home':
      default:
        return TrainingLocation.home;
    }
  }
}
