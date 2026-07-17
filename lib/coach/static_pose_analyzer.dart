import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';

abstract class StaticPoseAnalyzer extends ExerciseAnalyzer {
  final _feedback = FeedbackManager();
  Duration _hold = Duration.zero;
  DateTime? _lastGoodFrame;

  @override
  bool get isStatic => true;

  ({
    bool formGood,
    List<Fault> faults,
    String phase,
    List<CoachJointAngle> angles,
  })? check(Pose pose);

  @override
  AnalysisResult update(Pose pose, DateTime now) {
    final result = check(pose);
    if (result == null) {
      _lastGoodFrame = null;
      return const AnalysisResult.waiting();
    }

    if (result.formGood) {
      final last = _lastGoodFrame;
      if (last != null) _hold += now.difference(last);
      _lastGoodFrame = now;
    } else {
      _lastGoodFrame = null;
    }

    final decision = _feedback.evaluate(result.faults, now);

    return AnalysisResult(
      reps: 0,
      phase: result.phase,
      poseVisible: true,
      formGood: result.formGood,
      cue: decision.message,
      cueIsNew: decision.isNew,
      holdTime: _hold,
      angles: result.angles,
    );
  }

  @override
  void reset() {
    _feedback.reset();
    _hold = Duration.zero;
    _lastGoodFrame = null;
  }
}
