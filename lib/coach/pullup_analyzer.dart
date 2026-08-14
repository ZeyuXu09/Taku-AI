import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/feedback_manager.dart';
import 'package:peakform_ai/coach/pose_math.dart';
import 'package:peakform_ai/coach/rep_counter.dart';

/// Counts pull-ups from a hang (bottom) to head-over-hands (top).
///
/// Top: nose at or above the wrists. Bottom: elbows straight and head under
/// the hands. A rep is top, then back to the hang — not every bent-elbow frame.
class PullupAnalyzer extends ExerciseAnalyzer {
  final _reps = RepCounter(enterTop: 80, enterBottom: 20);

  static const _elbowHang = 160.0;
  static const _elbowBent = 90.0;

  @override
  bool get isStatic => false;

  @override
  void reset() {
    _reps.reset();
  }

  @override
  AnalysisResult update(Pose pose, DateTime now) {
    final leftElbow = PoseMath.angle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final rightElbow = PoseMath.angle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    final elbowAngle = _mean(leftElbow, rightElbow);

    final nose = _landmark(pose, PoseLandmarkType.nose);
    final leftWrist = _landmark(pose, PoseLandmarkType.leftWrist);
    final rightWrist = _landmark(pose, PoseLandmarkType.rightWrist);
    final handY = _mean(leftWrist?.y, rightWrist?.y);

    if (elbowAngle == null || nose == null || handY == null) {
      return AnalysisResult(
        reps: _reps.reps,
        phase: 'Get into frame',
        poseVisible: false,
        formGood: false,
      );
    }

    final scale = _verticalScale(pose, handY);
    final headOffset = (nose.y - handY) / scale;
    final headOverHands = headOffset <= 0.08;
    final headUnderHands = headOffset >= 0.18;
    final elbowsStraight = elbowAngle >= _elbowHang;
    final elbowsBent = elbowAngle <= _elbowBent;

    final atTop = headOverHands;
    final atBottom = headUnderHands && elbowsStraight;
    final contraction = atTop
        ? 100.0
        : atBottom
            ? 0.0
            : 50.0;
    _reps.update(contraction);

    final decisionFaults = [
      Fault(
        'chin',
        !headOverHands && elbowAngle < 140,
        'Pull until your head is over your hands',
        detail:
            'You did not finish over the bar on some reps. Pull until your head clears your hands, pause for a beat, then lower with control so every rep is complete.',
      ),
      Fault(
        'hang',
        headUnderHands && !elbowsStraight,
        'Straighten your arms at the bottom',
        detail:
            'You were not reaching a full hang. Straighten your arms fully at the bottom so each pull-up uses a full range instead of staying short.',
      ),
    ];

    final overlayElbow = _clearerElbow(pose);

    return AnalysisResult(
      reps: _reps.reps,
      phase: atTop
          ? 'Top'
          : atBottom
              ? 'Hang'
              : 'Pull',
      poseVisible: true,
      formGood: atTop || atBottom || elbowsBent,
      faults: decisionFaults,
      angles: [
        CoachJointAngle('Elbow', elbowAngle, overlayElbow),
      ],
    );
  }

  PoseLandmarkType _clearerElbow(Pose pose) {
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
    return right >= left
        ? PoseLandmarkType.rightElbow
        : PoseLandmarkType.leftElbow;
  }

  double _verticalScale(Pose pose, double handY) {
    final hipY = _mean(
      _landmark(pose, PoseLandmarkType.leftHip)?.y,
      _landmark(pose, PoseLandmarkType.rightHip)?.y,
    );
    if (hipY != null) {
      final span = (hipY - handY).abs();
      if (span > 40) return span;
    }

    final shoulderY = _mean(
      _landmark(pose, PoseLandmarkType.leftShoulder)?.y,
      _landmark(pose, PoseLandmarkType.rightShoulder)?.y,
    );
    if (shoulderY != null) {
      final span = (shoulderY - handY).abs();
      if (span > 24) return span * 2;
    }

    return 200;
  }

  PoseLandmark? _landmark(Pose pose, PoseLandmarkType type) {
    final landmark = pose.landmarks[type];
    if (landmark == null || landmark.likelihood < PoseMath.minLikelihood) {
      return null;
    }
    return landmark;
  }

  double? _mean(double? a, double? b) {
    if (a != null && b != null) return (a + b) / 2;
    return a ?? b;
  }
}
