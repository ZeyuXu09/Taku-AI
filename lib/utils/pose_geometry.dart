import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class JointAngle {
  const JointAngle({required this.label, required this.degrees});

  final String label;
  final double degrees;

  bool get isWarning => degrees < 85 || degrees > 175;
}

double? angleAtJoint(
  PoseLandmark? a,
  PoseLandmark? b,
  PoseLandmark? c,
) {
  if (a == null || b == null || c == null) return null;
  if (a.likelihood < 0.5 || b.likelihood < 0.5 || c.likelihood < 0.5) {
    return null;
  }

  final ba = Offset(a.x - b.x, a.y - b.y);
  final bc = Offset(c.x - b.x, c.y - b.y);
  final dot = ba.dx * bc.dx + ba.dy * bc.dy;
  final magBa = math.sqrt(ba.dx * ba.dx + ba.dy * ba.dy);
  final magBc = math.sqrt(bc.dx * bc.dx + bc.dy * bc.dy);
  if (magBa == 0 || magBc == 0) return null;

  final cosAngle = (dot / (magBa * magBc)).clamp(-1.0, 1.0);
  return math.acos(cosAngle) * 180 / math.pi;
}

List<JointAngle> kneeAnglesFromPose(Pose pose) {
  final landmarks = pose.landmarks;
  final left = angleAtJoint(
    landmarks[PoseLandmarkType.leftHip],
    landmarks[PoseLandmarkType.leftKnee],
    landmarks[PoseLandmarkType.leftAnkle],
  );
  final right = angleAtJoint(
    landmarks[PoseLandmarkType.rightHip],
    landmarks[PoseLandmarkType.rightKnee],
    landmarks[PoseLandmarkType.rightAnkle],
  );

  return [
    if (left != null) JointAngle(label: 'Left Knee', degrees: left),
    if (right != null) JointAngle(label: 'Right Knee', degrees: right),
  ];
}

double averageLandmarkConfidence(Pose pose) {
  if (pose.landmarks.isEmpty) return 0;
  final total = pose.landmarks.values
      .map((landmark) => landmark.likelihood)
      .fold<double>(0, (sum, value) => sum + value);
  return total / pose.landmarks.length;
}

String coachFeedbackForPose(Pose? pose) {
  if (pose == null) {
    return 'Select a photo with a clearly visible athlete to analyze form.';
  }

  final leftKnee = angleAtJoint(
    pose.landmarks[PoseLandmarkType.leftHip],
    pose.landmarks[PoseLandmarkType.leftKnee],
    pose.landmarks[PoseLandmarkType.leftAnkle],
  );

  if (leftKnee != null && leftKnee < 85) {
    return 'Keep your left knee tracking over your toes.';
  }

  final rightKnee = angleAtJoint(
    pose.landmarks[PoseLandmarkType.rightHip],
    pose.landmarks[PoseLandmarkType.rightKnee],
    pose.landmarks[PoseLandmarkType.rightAnkle],
  );

  if (rightKnee != null && rightKnee < 85) {
    return 'Drive through your right heel and keep the knee stable.';
  }

  return 'Strong posture detected. Maintain core tension through the rep.';
}

String formRatingLabel(double confidence) {
  if (confidence >= 0.9) return 'EXCELLENT';
  if (confidence >= 0.75) return 'GOOD';
  if (confidence >= 0.6) return 'FAIR';
  return 'LOW';
}
