import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// A measured joint angle for live coach overlay labels.
class CoachJointAngle {
  const CoachJointAngle(this.label, this.degrees, this.vertex);

  final String label;
  final double degrees;
  final PoseLandmarkType vertex;
}
