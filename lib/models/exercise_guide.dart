class ExerciseGuide {
  const ExerciseGuide({
    required this.steps,
    required this.notes,
  });

  final List<String> steps;
  final String notes;

  static ExerciseGuide fallback(String name, {bool gym = false}) {
    if (gym) {
      return ExerciseGuide(
        steps: const [
          'Adjust the machine or load to a manageable starting weight.',
          'Move through the full range with control on every rep.',
          'Breathe steadily and stop if form breaks down.',
        ],
        notes:
            'Ask gym staff for a quick equipment demo if unsure. Prioritize form over weight.',
      );
    }
    return ExerciseGuide(
      steps: const [
        'Set up in a clear space with room to move safely.',
        'Move through the full range with control on every rep.',
        'Breathe steadily and stop if form breaks down.',
      ],
      notes:
          'Focus on quality over speed. Reduce volume or rest longer if you feel pain beyond normal muscle fatigue.',
    );
  }
}
