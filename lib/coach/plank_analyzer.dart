import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/static_pose_analyzer.dart';

class PlankAnalyzer extends StaticPoseAnalyzer {
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

    final elbowStacked = elbowAngle >= 75 && elbowAngle <= 105;
    final bodyStraight = hipAngle >= 160;
    final hipsPiked = hipAngle > 195;
    final legsStraight = legAngle > 160;

    final formGood = elbowStacked && bodyStraight && legsStraight;

    final faults = [
      Fault(
        'hipSag',
        hipAngle < 150,
        'Straighten your body — hips in line',
        detail:
            'Your hips sagged, which loads the lower back. Squeeze your glutes and pull your belly in so shoulders, hips, and heels stay in one long line.',
      ),
      Fault(
        'elbow',
        !elbowStacked,
        'Stack your shoulders over your elbows',
        detail:
            'Your shoulders drifted off your elbows. Stack shoulders over elbows and press the floor away so the plank stays stable instead of collapsing forward.',
      ),
      Fault(
        'legs',
        !legsStraight,
        'Straighten your legs',
        detail:
            'Your legs softened during the hold. Straighten them and press your heels back so the plank is a full-body brace, not just an upper-body hold.',
      ),
      Fault(
        'pike',
        hipsPiked,
        'Lower your hips',
        detail:
            'Your hips were too high, more like a pike than a plank. Lower them until your body is a long line from head to heels.',
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
