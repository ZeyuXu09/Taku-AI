import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/theme/app_colors.dart';

/// Skeleton overlay for a live camera preview (handles rotation and mirroring).
class LivePoseOverlayPainter extends CustomPainter {
  LivePoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    this.highlightTypes = const {},
  });

  final Pose? pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
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
    final pose = this.pose;
    if (pose == null || imageSize.width <= 0 || imageSize.height <= 0) {
      return;
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

      canvas.drawLine(
        _project(start, size),
        _project(end, size),
        linePaint,
      );
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

      canvas.drawCircle(
        _project(landmark, size),
        isHighlighted ? 6 : 4.5,
        paint,
      );
    }
  }

  Offset _project(PoseLandmark landmark, Size canvasSize) {
    return Offset(
      _translateX(landmark.x, canvasSize),
      _translateY(landmark.y, canvasSize),
    );
  }

  double _translateX(double x, Size canvasSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x *
            canvasSize.width /
            (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation270deg:
        return canvasSize.width -
            x *
                canvasSize.width /
                (Platform.isIOS ? imageSize.width : imageSize.height);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        final scaled = x * canvasSize.width / imageSize.width;
        return cameraLensDirection == CameraLensDirection.back
            ? scaled
            : canvasSize.width - scaled;
    }
  }

  double _translateY(double y, Size canvasSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y *
            canvasSize.height /
            (Platform.isIOS ? imageSize.height : imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  @override
  bool shouldRepaint(covariant LivePoseOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.cameraLensDirection != cameraLensDirection ||
        oldDelegate.highlightTypes != highlightTypes;
  }
}
