import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';

/// Per-frame output from an [ExerciseAnalyzer].
class AnalysisResult {
  const AnalysisResult({
    required this.reps,
    required this.phase,
    required this.poseVisible,
    required this.formGood,
    this.cue,
    this.cueIsNew = false,
    this.holdTime = Duration.zero,
    this.angles = const [],
    this.faults = const [],
  });

  const AnalysisResult.waiting()
      : reps = 0,
        phase = 'Get into frame',
        poseVisible = false,
        formGood = false,
        cue = null,
        cueIsNew = false,
        holdTime = Duration.zero,
        angles = const [],
        faults = const [];

  final int reps;
  final String phase;
  final bool poseVisible;
  final bool formGood;
  final String? cue;
  final bool cueIsNew;
  final Duration holdTime;
  final List<CoachJointAngle> angles;
  final List<Fault> faults;
}
