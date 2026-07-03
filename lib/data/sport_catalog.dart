/// Shared sport list for selection UI and training tag matching.
class SportCatalog {
  SportCatalog._();

  static const sports = [
    SportOption('assets/icons/sports/basketball.png', 'Basketball'),
    SportOption('assets/icons/sports/football.png', 'Football'),
    SportOption('assets/icons/sports/soccer.png', 'Soccer'),
    SportOption('assets/icons/sports/baseball.png', 'Baseball'),
    SportOption('assets/icons/sports/tennis.png', 'Tennis'),
    SportOption('assets/icons/sports/badminton.png', 'Badminton'),
    SportOption('assets/icons/sports/table_tennis.png', 'Table Tennis'),
    SportOption('assets/icons/sports/pickleball.png', 'Pickleball'),
    SportOption('assets/icons/sports/track_and_field.png', 'Track & Field'),
    SportOption('assets/icons/sports/volleyball.png', 'Volleyball'),
    SportOption('assets/icons/sports/other.png', 'Other'),
    SportOption('assets/icons/sports/basic_workout.png', 'Basic Workout'),
  ];

  static const defaultSport = 'Basic Workout';
}

class SportOption {
  const SportOption(this.assetPath, this.name);

  final String assetPath;
  final String name;
}

/// Tags used to prioritize exercises per sport (cross-sport library).
const sportPriorityTags = <String, List<String>>{
  'Basketball': ['plyometric', 'lateral', 'jumping', 'agility'],
  'Football': ['speed', 'power', 'change-direction', 'explosive'],
  'Soccer': ['endurance', 'agility', 'single-leg', 'conditioning'],
  'Baseball': ['rotational', 'power', 'shoulder', 'speed'],
  'Tennis': ['lateral', 'agility', 'rotational', 'single-leg'],
  'Badminton': ['agility', 'lateral', 'reaction', 'single-leg'],
  'Table Tennis': ['reaction', 'agility', 'core', 'footwork'],
  'Pickleball': ['lateral', 'agility', 'reaction', 'balance'],
  'Track & Field': ['speed', 'power', 'plyometric', 'endurance'],
  'Volleyball': ['jumping', 'plyometric', 'lateral', 'shoulder'],
  'Other': ['general', 'mobility', 'strength'],
  'Basic Workout': ['general', 'mobility', 'strength', 'conditioning'],
};
