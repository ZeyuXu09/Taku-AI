import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/rep_counter.dart';

class BicepCurlAnalyzer extends ExerciseAnalyzer {
  final _reps = RepCounter(enterTop: 80, enterBottom: 20);

  @override
  bool get isStatic => false;

  @override
  void reset() {
    _reps.reset();
  }

  @override
  AnalysisResult update(Pose pose, DateTime now) {
    final side = _clearerArm(pose);
    final (shoulder, elbow, wrist, hip) = _joints(side);

    final elbowAngle = PoseMath.angle(pose, shoulder, elbow, wrist);
    final upperArmAngle = PoseMath.angle(pose, hip, shoulder, elbow);

    if (elbowAngle == null) {
      return AnalysisResult(
        reps: _reps.reps,
        phase: 'Get into frame',
        poseVisible: false,
        formGood: false,
      );
    }

    final contraction = PoseMath.mapRange(elbowAngle, 30, 160, 100, 0);
    _reps.update(contraction);

    final armSwinging = upperArmAngle != null && upperArmAngle > 40;
    final faults = [
      Fault(
        'swing',
        armSwinging,
        'Keep your upper arm still',
        detail:
            'Your upper arm drifted forward, which turns the curl into a swing. Pin your elbow to your side and only hinge at the elbow so the biceps do the lifting.',
      ),
    ];

    return AnalysisResult(
      reps: _reps.reps,
      phase: contraction >= 50 ? 'Curl' : 'Extend',
      poseVisible: true,
      formGood: !armSwinging,
      faults: faults,
      angles: [
        CoachJointAngle('Elbow', elbowAngle, elbow),
        if (upperArmAngle != null)
          CoachJointAngle('Arm', upperArmAngle, shoulder),
      ],
    );
  }

  BodySide _clearerArm(Pose pose) {
    final left = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    ]);
    final right = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    ]);
    return right >= left ? BodySide.right : BodySide.left;
  }

  (PoseLandmarkType, PoseLandmarkType, PoseLandmarkType, PoseLandmarkType)
      _joints(BodySide side) {
    return side == BodySide.right
        ? (
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightElbow,
            PoseLandmarkType.rightWrist,
            PoseLandmarkType.rightHip,
          )
        : (
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.leftWrist,
            PoseLandmarkType.leftHip,
          );
  }
}
