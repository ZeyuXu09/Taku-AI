import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/theme/app_colors.dart';

class PoseOverlayPainter extends CustomPainter {
  PoseOverlayPainter({
    required this.pose,
    required this.imageWidth,
    required this.imageHeight,
    this.highlightTypes = const {},
  });

  final Pose pose;
  final double imageWidth;
  final double imageHeight;
  final Set<PoseLandmarkType> highlightTypes;

  static const _connections = [
    (PoseLandmarkType.nose, PoseLandmarkType.leftShoulder),
    (PoseLandmarkType.nose, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final fittedSizes = applyBoxFit(
      BoxFit.contain,
      Size(imageWidth, imageHeight),
      size,
    );
    final dest = fittedSizes.destination;
    final scale = dest.width / imageWidth;
    final offset = Offset(
      (size.width - dest.width) / 2,
      (size.height - dest.height) / 2,
    );

    Offset mapPoint(PoseLandmark landmark) {
      return Offset(
        landmark.x * scale + offset.dx,
        landmark.y * scale + offset.dy,
      );
    }

    final linePaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final (startType, endType) in _connections) {
      final start = pose.landmarks[startType];
      final end = pose.landmarks[endType];
      if (start == null || end == null) continue;
      if (start.likelihood < 0.5 || end.likelihood < 0.5) continue;

      final isHighlighted =
          highlightTypes.contains(startType) || highlightTypes.contains(endType);
      linePaint.color = isHighlighted ? AppColors.yellow : AppColors.green;
      linePaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isHighlighted ? 3 : 2,
      );

      canvas.drawLine(mapPoint(start), mapPoint(end), linePaint);
    }

    for (final entry in pose.landmarks.entries) {
      final landmark = entry.value;
      if (landmark.likelihood < 0.5) continue;

      final isHighlighted = highlightTypes.contains(entry.key);
      final color = isHighlighted ? AppColors.yellow : AppColors.green;
      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isHighlighted ? 4 : 3,
        );

      canvas.drawCircle(mapPoint(landmark), isHighlighted ? 6 : 4.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.highlightTypes != highlightTypes;
  }
}
