import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peakform_ai/data/day_templates.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_intensity.dart';
import 'package:peakform_ai/models/training_location.dart';
import 'package:peakform_ai/services/training_plan_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('casual plan trains Mon Wed Fri only', () {
    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Basketball'],
      intensity: TrainingIntensity.casual,
      location: TrainingLocation.home,
    );

    final monday = DateTime(2026, 6, 29);
    final tuesday = DateTime(2026, 6, 30);

    expect(
      TrainingPlanService.instance.sessionForDate(monday).isRestDay,
      isFalse,
    );
    expect(
      TrainingPlanService.instance.sessionForDate(tuesday).isRestDay,
      isTrue,
    );
  });

  test('weekday focus rotates through power agility strength', () {
    expect(focusForWeekday(DateTime.monday), TrainingFocus.power);
    expect(focusForWeekday(DateTime.tuesday), TrainingFocus.agility);
    expect(focusForWeekday(DateTime.wednesday), TrainingFocus.strength);
  });

  test('professional session includes more exercises than casual', () {
    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Soccer'],
      intensity: TrainingIntensity.professional,
      location: TrainingLocation.home,
    );
    final pro = TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Soccer'],
      intensity: TrainingIntensity.casual,
      location: TrainingLocation.home,
    );
    final casual =
        TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    expect(pro.exerciseCount, greaterThan(casual.exerciseCount));
  });

  test('focus override replaces scheduled weekday focus', () async {
    SharedPreferences.setMockInitialValues({});
    await TrainingSessionOverrideService.instance.load();

    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Basketball'],
      intensity: TrainingIntensity.serious,
      location: TrainingLocation.home,
    );

    await TrainingSessionOverrideService.instance.saveFocus(
      date: DateTime(2026, 6, 29),
      focus: TrainingFocus.agility,
    );

    final session =
        TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    expect(session.focus, TrainingFocus.agility);
    expect(session.scheduledFocus, TrainingFocus.power);
    expect(session.isFocusCustomized, isTrue);
    expect(session.title, 'Pre-Game Agility');
  });

  test('recovery focus override turns training day into rest day', () async {
    SharedPreferences.setMockInitialValues({});
    await TrainingSessionOverrideService.instance.load();

    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Basketball'],
      intensity: TrainingIntensity.serious,
      location: TrainingLocation.home,
    );

    await TrainingSessionOverrideService.instance.saveFocus(
      date: DateTime(2026, 6, 29),
      focus: TrainingFocus.recovery,
    );

    final session =
        TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    expect(session.isRestDay, isTrue);
    expect(session.exercises, isEmpty);
  });

  test('gym location uses gym exercise library', () async {
    SharedPreferences.setMockInitialValues({});
    await TrainingSessionOverrideService.instance.load();

    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Basic Workout'],
      intensity: TrainingIntensity.serious,
      location: TrainingLocation.gym,
    );

    final session =
        TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    expect(session.exercises, isNotEmpty);
    expect(
      session.exercises.every((e) => e.exercise.id.startsWith('gym_')),
      isTrue,
    );
  });

  test('home location uses home exercise library', () {
    TrainingPreferencesService.instance.preferences.value =
        const TrainingPreferences(
      sports: ['Basic Workout'],
      intensity: TrainingIntensity.serious,
      location: TrainingLocation.home,
    );

    final session =
        TrainingPlanService.instance.sessionForDate(DateTime(2026, 6, 29));

    expect(session.exercises, isNotEmpty);
    expect(
      session.exercises.any((e) => !e.exercise.id.startsWith('gym_')),
      isTrue,
    );
  });
}
