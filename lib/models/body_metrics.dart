class BodyMetrics {
  const BodyMetrics({
    required this.heightInches,
    required this.weightLbs,
    required this.bodyFatPercent,
    required this.muscleMassLbs,
    this.previousHeightInches,
    this.previousWeightLbs,
    this.previousBodyFatPercent,
    this.previousMuscleMassLbs,
  });

  /// Stored in inches / pounds so display can convert for metric users.
  final double heightInches;
  final double weightLbs;
  final double bodyFatPercent;
  final double muscleMassLbs;

  final double? previousHeightInches;
  final double? previousWeightLbs;
  final double? previousBodyFatPercent;
  final double? previousMuscleMassLbs;

  static const defaults = BodyMetrics(
    heightInches: 70, // 5'10"
    weightLbs: 165,
    bodyFatPercent: 14.2,
    muscleMassLbs: 78.4,
  );

  double get bmi {
    if (heightInches <= 0) return 0;
    return (weightLbs / (heightInches * heightInches)) * 703;
  }

  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Underweight';
    if (value < 25) return 'Normal range';
    if (value < 30) return 'Overweight';
    return 'Obese';
  }

  BodyMetrics copyWith({
    double? heightInches,
    double? weightLbs,
    double? bodyFatPercent,
    double? muscleMassLbs,
    double? previousHeightInches,
    double? previousWeightLbs,
    double? previousBodyFatPercent,
    double? previousMuscleMassLbs,
  }) {
    return BodyMetrics(
      heightInches: heightInches ?? this.heightInches,
      weightLbs: weightLbs ?? this.weightLbs,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      muscleMassLbs: muscleMassLbs ?? this.muscleMassLbs,
      previousHeightInches:
          previousHeightInches ?? this.previousHeightInches,
      previousWeightLbs: previousWeightLbs ?? this.previousWeightLbs,
      previousBodyFatPercent:
          previousBodyFatPercent ?? this.previousBodyFatPercent,
      previousMuscleMassLbs:
          previousMuscleMassLbs ?? this.previousMuscleMassLbs,
    );
  }

  Map<String, dynamic> toJson() => {
        'heightInches': heightInches,
        'weightLbs': weightLbs,
        'bodyFatPercent': bodyFatPercent,
        'muscleMassLbs': muscleMassLbs,
        'previousHeightInches': previousHeightInches,
        'previousWeightLbs': previousWeightLbs,
        'previousBodyFatPercent': previousBodyFatPercent,
        'previousMuscleMassLbs': previousMuscleMassLbs,
      };

  factory BodyMetrics.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return BodyMetrics(
      heightInches: asDouble(json['heightInches']) ?? defaults.heightInches,
      weightLbs: asDouble(json['weightLbs']) ?? defaults.weightLbs,
      bodyFatPercent:
          asDouble(json['bodyFatPercent']) ?? defaults.bodyFatPercent,
      muscleMassLbs:
          asDouble(json['muscleMassLbs']) ?? defaults.muscleMassLbs,
      previousHeightInches: asDouble(json['previousHeightInches']),
      previousWeightLbs: asDouble(json['previousWeightLbs']),
      previousBodyFatPercent: asDouble(json['previousBodyFatPercent']),
      previousMuscleMassLbs: asDouble(json['previousMuscleMassLbs']),
    );
  }
}
