class CoachFeedbackEntry {
  const CoachFeedbackEntry({
    required this.id,
    required this.message,
    required this.exercise,
    required this.at,
    required this.isCorrection,
    this.reps = 0,
  });

  final String id;
  final String message;
  final String exercise;
  final DateTime at;
  final bool isCorrection;
  final int reps;

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'exercise': exercise,
        'at': at.toUtc().toIso8601String(),
        'isCorrection': isCorrection,
        'reps': reps,
      };

  factory CoachFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return CoachFeedbackEntry(
      id: json['id'] as String,
      message: json['message'] as String,
      exercise: json['exercise'] as String,
      at: DateTime.parse(json['at'] as String).toLocal(),
      isCorrection: json['isCorrection'] as bool? ?? true,
      reps: json['reps'] as int? ?? 0,
    );
  }
}
