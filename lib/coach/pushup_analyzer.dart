import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/rep_counter.dart';

class PushupAnalyzer extends ExerciseAnalyzer {
  final _reps = RepCounter(enterTop: 75, enterBottom: 25);
  final _feedback = FeedbackManager();

  @override
  bool get isStatic => false;

  @override
  void reset() {
    _reps.reset();
    _feedback.reset();
  }

  @override
  AnalysisResult update(Pose pose, DateTime now) {
    final side = _clearerSide(pose);
    final (shoulder, elbow, wrist, hip, knee, ankle) = _joints(side);

    final elbowAngle = PoseMath.angle(pose, shoulder, elbow, wrist);
    final backAngle = PoseMath.angle(pose, shoulder, hip, knee);
    final legAngle = PoseMath.angle(pose, hip, knee, ankle);

    if (elbowAngle == null || backAngle == null || legAngle == null) {
      return const AnalysisResult.waiting();
    }

    final contraction = PoseMath.mapRange(elbowAngle, 75, 165, 100, 0);
    _reps.update(contraction);

    final legsStraight = legAngle >= 160;
    final backStraight = backAngle >= 155;

    final decision = _feedback.evaluate([
      Fault('back', !backStraight, 'Keep your back straight'),
      Fault('legs', !legsStraight, 'Straighten your legs'),
    ], now);

    return AnalysisResult(
      reps: _reps.reps,
      phase: contraction >= 50 ? 'Down' : 'Up',
      poseVisible: true,
      formGood: legsStraight && backStraight,
      cue: decision.message,
      cueIsNew: decision.isNew,
      angles: [
        CoachJointAngle('Elbow', elbowAngle, elbow),
        CoachJointAngle('Back', backAngle, hip),
        CoachJointAngle('Leg', legAngle, knee),
      ],
    );
  }

  BodySide _clearerSide(Pose pose) {
    final left = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    ]);
    final right = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    ]);
    return right >= left ? BodySide.right : BodySide.left;
  }

  (
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
  ) _joints(BodySide side) {
    return side == BodySide.right
        ? (
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightElbow,
            PoseLandmarkType.rightWrist,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightKnee,
            PoseLandmarkType.rightAnkle,
          )
        : (
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.leftWrist,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
          );
  }
}
