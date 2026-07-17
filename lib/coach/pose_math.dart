import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Geometry helpers for live coach analyzers.
class PoseMath {
  static const double minLikelihood = 0.5;

  PoseMath._();

  /// Interior angle (0–180°) at vertex [b]. Returns null if landmarks are weak.
  static double? angle(
    Pose pose,
    PoseLandmarkType a,
    PoseLandmarkType b,
    PoseLandmarkType c,
  ) {
    final la = pose.landmarks[a];
    final lb = pose.landmarks[b];
    final lc = pose.landmarks[c];
    if (la == null || lb == null || lc == null) return null;
    if (la.likelihood < minLikelihood ||
        lb.likelihood < minLikelihood ||
        lc.likelihood < minLikelihood) {
      return null;
    }

    final radians = math.atan2(lc.y - lb.y, lc.x - lb.x) -
        math.atan2(la.y - lb.y, la.x - lb.x);
    var deg = radians.abs() * 180.0 / math.pi;
    if (deg > 180.0) deg = 360.0 - deg;
    return deg;
  }

  static double averageLikelihood(Pose pose, List<PoseLandmarkType> types) {
    var sum = 0.0;
    var n = 0;
    for (final t in types) {
      final lm = pose.landmarks[t];
      if (lm != null) {
        sum += lm.likelihood;
        n++;
      }
    }
    return n == 0 ? 0.0 : sum / n;
  }

  static double mapRange(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (inMin == inMax) return outMin;
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + t * (outMax - outMin);
  }
}

enum BodySide { left, right }
