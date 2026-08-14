import 'package:peakform_ai/models/training_exercise.dart';

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

/// Qualities a training focus is meant to build.
const focusBenefitTags = <TrainingFocus, List<String>>{
  TrainingFocus.power: ['plyometric', 'jumping', 'explosive', 'power'],
  TrainingFocus.agility: [
    'agility',
    'lateral',
    'change-direction',
    'footwork',
    'reaction',
  ],
  TrainingFocus.strength: ['strength', 'single-leg', 'shoulder', 'core'],
  TrainingFocus.speed: ['speed', 'explosive', 'change-direction'],
  TrainingFocus.endurance: ['endurance', 'conditioning'],
  TrainingFocus.recovery: ['mobility', 'general'],
  TrainingFocus.mixed: ['general', 'conditioning', 'strength', 'mobility'],
};

/// Sports that gain the most from this focus (not the user's selected sports).
List<String> sportsThatBenefitFrom(TrainingFocus focus, {int limit = 4}) {
  final tags = focusBenefitTags[focus] ?? const <String>[];
  final ranked = <MapEntry<String, int>>[];

  for (final entry in sportPriorityTags.entries) {
    if (entry.key == 'Other' || entry.key == 'Basic Workout') continue;
    var score = 0;
    for (final tag in entry.value) {
      if (tags.contains(tag)) score++;
    }
    if (score > 0) ranked.add(MapEntry(entry.key, score));
  }

  ranked.sort((a, b) => b.value.compareTo(a.value));
  return ranked.take(limit).map((entry) => entry.key).toList();
}

String formatSportList(Iterable<String> sports) {
  final list = sports.toList();
  if (list.isEmpty) return '';
  if (list.length == 1) return list.first;
  if (list.length == 2) return '${list[0]} & ${list[1]}';
  if (list.length == 3) return '${list[0]}, ${list[1]} & ${list[2]}';
  return '${list.take(3).join(', ')} +${list.length - 3}';
}
