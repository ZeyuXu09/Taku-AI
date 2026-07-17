import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/static_pose_analyzer.dart';

class DownwardDogAnalyzer extends StaticPoseAnalyzer {
  @override
  ({
    bool formGood,
    List<Fault> faults,
    String phase,
    List<CoachJointAngle> angles,
  })? check(Pose pose) {
    final side = _clearerSide(pose);
    final (shoulder, elbow, wrist, hip, knee, ankle) = _joints(side);

    final elbowAngle = PoseMath.angle(pose, shoulder, elbow, wrist);
    final hipAngle = PoseMath.angle(pose, shoulder, hip, knee);
    final legAngle = PoseMath.angle(pose, hip, knee, ankle);

    if (elbowAngle == null || hipAngle == null || legAngle == null) return null;

    final armsStraight = elbowAngle >= 165;
    final legsStraight = legAngle >= 165;
    final hipInRange = hipAngle >= 52 && hipAngle <= 70;

    final formGood = armsStraight && legsStraight && hipInRange;

    final faults = [
      Fault('elbow', !armsStraight, 'Straighten your arms'),
      Fault('hipLow', hipAngle < 52, 'Push your hips up and back'),
      Fault('hipHigh', hipAngle > 70, 'Bring your hands and feet closer'),
      Fault('legs', !legsStraight, 'Straighten your legs'),
    ];

    return (
      formGood: formGood,
      faults: faults,
      phase: formGood ? 'Hold' : 'Fix form',
      angles: [
        CoachJointAngle('Elbow', elbowAngle, elbow),
        CoachJointAngle('Hip', hipAngle, hip),
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
