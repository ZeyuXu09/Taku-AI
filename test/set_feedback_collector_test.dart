import 'package:flutter_test/flutter_test.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/set_feedback_collector.dart';

void main() {
  late SetFeedbackCollector collector;

  setUp(() {
    collector = SetFeedbackCollector();
  });

  test('does not finish before the set has real work', () {
    collector.observeFrame(
      formGood: false,
      faults: [
        const Fault('back', true, 'Keep your back straight', detail: 'Hips dropped.'),
      ],
      reps: 0,
      hold: Duration.zero,
    );

    expect(
      collector.finish(exerciseTitle: 'Push-ups', isStatic: false),
      isNull,
    );
  });

  test('one detailed note per set, then nothing until the next set', () {
    for (var i = 0; i < 8; i++) {
      collector.observeFrame(
        formGood: false,
        faults: [
          const Fault(
            'back',
            true,
            'Keep your back straight',
            detail:
                'Your hips dropped on several reps. Brace your core before you lower.',
          ),
        ],
        reps: i >= 3 ? 8 : 0,
        hold: Duration.zero,
      );
    }

    final first = collector.finish(exerciseTitle: 'Push-ups', isStatic: false);
    expect(first, isNotNull);
    expect(first!.message, contains('Set of 8 push-ups.'));
    expect(first.message, contains('hips dropped'));
    expect(first.isCorrection, isTrue);
    expect(first.reps, 8);

    expect(
      collector.finish(exerciseTitle: 'Push-ups', isStatic: false, force: true),
      isNull,
    );

    collector.observeFrame(
      formGood: true,
      faults: const [],
      reps: 8,
      hold: Duration.zero,
    );
    for (var i = 0; i < 5; i++) {
      collector.observeFrame(
        formGood: true,
        faults: const [],
        reps: 13,
        hold: Duration.zero,
      );
    }

    final second = collector.finish(exerciseTitle: 'Push-ups', isStatic: false);
    expect(second, isNotNull);
    expect(second!.message, contains('Set of 5 push-ups.'));
    expect(second.message, contains('Overall form looked strong'));
    expect(second.isCorrection, isFalse);
  });

  test('hold sets use time and longer coaching', () {
    for (var i = 0; i < 30; i++) {
      collector.observeFrame(
        formGood: false,
        faults: [
          const Fault(
            'hipSag',
            true,
            'Hips in line',
            detail:
                'Your hips sagged, which loads the lower back. Squeeze your glutes.',
          ),
        ],
        reps: 0,
        hold: const Duration(seconds: 32),
      );
    }

    final note = collector.finish(exerciseTitle: 'Plank', isStatic: true);
    expect(note, isNotNull);
    expect(note!.message, contains('Plank hold: 0:32.'));
    expect(note.message, contains('hips sagged'));
    expect(note.isCorrection, isTrue);
  });
}
