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
      Fault(
        'elbow',
        !armsStraight,
        'Straighten your arms',
        detail:
            'Your arms bent, which collapses the pose. Press the floor away and straighten the elbows so your shoulders can open and the stretch reaches the back of the legs.',
      ),
      Fault(
        'hipLow',
        hipAngle < 52,
        'Push your hips up and back',
        detail:
            'Your hips sat too low. Push your hips up and back to make a tall upside-down V, even if the heels stay light off the floor.',
      ),
      Fault(
        'hipHigh',
        hipAngle > 70,
        'Bring your hands and feet closer',
        detail:
            'The V was too tight, with hips stacking too high over the hands. Step your feet back a little so the hips can sit high without rounding your spine.',
      ),
      Fault(
        'legs',
        !legsStraight,
        'Straighten your legs',
        detail:
            'Your knees bent a lot. Straighten your legs as much as your hamstrings allow — a soft bend is fine, but keep reaching the heels toward the floor.',
      ),
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
