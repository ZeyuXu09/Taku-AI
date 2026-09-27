import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/rep_counter.dart';

/// Counts squats from a stand (top) to a deep knee bend (bottom).
///
/// A rep is down, then back to standing. Knee angle drives the counter.
class SquatAnalyzer extends ExerciseAnalyzer {
  final _reps = RepCounter(enterTop: 75, enterBottom: 25);

  @override
  bool get isStatic => false;

  @override
  void reset() {
    _reps.reset();
  }

  @override
  AnalysisResult update(Pose pose, DateTime now) {
    final side = _clearerSide(pose);
    final (shoulder, hip, knee, ankle) = _joints(side);

    final kneeAngle = PoseMath.angle(pose, hip, knee, ankle);
    final hipAngle = PoseMath.angle(pose, shoulder, hip, knee);

    if (kneeAngle == null) {
      return AnalysisResult(
        reps: _reps.reps,
        phase: 'Get into frame',
        poseVisible: false,
        formGood: false,
      );
    }

    // 100 = deep squat, 0 = standing.
    final contraction = PoseMath.mapRange(kneeAngle, 85, 170, 100, 0);
    _reps.update(contraction);

    final atBottom = contraction >= 50;
    final chestCollapsed = hipAngle != null && hipAngle < 50 && atBottom;
    final kneesCaving = _kneesCaving(pose, atBottom);

    final faults = [
      Fault(
        'chest',
        chestCollapsed,
        'Keep your chest up',
        detail:
            'Your chest dropped toward your thighs on several reps. Sit the hips back, lift the chest, and keep a long spine so the squat stays in the legs instead of folding forward.',
      ),
      Fault(
        'knees',
        kneesCaving,
        'Keep your knees out',
        detail:
            'Your knees caved inward. Push them out over the toes as you sit down so the hips and glutes can share the load.',
      ),
    ];

    return AnalysisResult(
      reps: _reps.reps,
      phase: atBottom ? 'Down' : 'Stand',
      poseVisible: true,
      formGood: !chestCollapsed && !kneesCaving,
      faults: faults,
      angles: [
        CoachJointAngle('Knee', kneeAngle, knee),
        if (hipAngle != null) CoachJointAngle('Hip', hipAngle, hip),
      ],
    );
  }

  bool _kneesCaving(Pose pose, bool atBottom) {
    if (!atBottom) return false;
    final leftKnee = _point(pose, PoseLandmarkType.leftKnee);
    final rightKnee = _point(pose, PoseLandmarkType.rightKnee);
    final leftAnkle = _point(pose, PoseLandmarkType.leftAnkle);
    final rightAnkle = _point(pose, PoseLandmarkType.rightAnkle);
    if (leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      return false;
    }

    final ankleWidth = (leftAnkle.$1 - rightAnkle.$1).abs();
    final kneeWidth = (leftKnee.$1 - rightKnee.$1).abs();
    // Side view has a tiny ankle width — skip valgus there.
    if (ankleWidth < 40) return false;
    return kneeWidth < ankleWidth * 0.7;
  }

  (double, double)? _point(Pose pose, PoseLandmarkType type) {
    final landmark = pose.landmarks[type];
    if (landmark == null || landmark.likelihood < PoseMath.minLikelihood) {
      return null;
    }
    return (landmark.x, landmark.y);
  }

  BodySide _clearerSide(Pose pose) {
    final left = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    ]);
    final right = PoseMath.averageLikelihood(pose, const [
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    ]);
    return right >= left ? BodySide.right : BodySide.left;
  }

  (
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
    PoseLandmarkType,
  ) _joints(BodySide side) {
    return side == BodySide.right
        ? (
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightKnee,
            PoseLandmarkType.rightAnkle,
          )
        : (
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
          );
  }
}
