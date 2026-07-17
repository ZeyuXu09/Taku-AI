import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/theme/app_colors.dart';

/// Skeleton overlay for a live camera preview (handles rotation and mirroring).
class LivePoseOverlayPainter extends CustomPainter {
  LivePoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    this.formGood = true,
    this.angles = const [],
    this.highlightTypes = const {},
  });

  final Pose? pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final bool formGood;
  final List<CoachJointAngle> angles;
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

    final baseColor = formGood ? AppColors.green : AppColors.yellow;

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
      linePaint.color = isHighlighted ? AppColors.yellow : baseColor;
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
      final color = isHighlighted ? AppColors.yellow : baseColor;
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

    for (final angle in angles) {
      final vertex = pose.landmarks[angle.vertex];
      if (vertex == null || vertex.likelihood < 0.5) continue;
      _drawAngleLabel(
        canvas,
        _project(vertex, size),
        '${angle.degrees.round()}°',
      );
    }
  }

  void _drawAngleLabel(Canvas canvas, Offset at, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final origin = at + const Offset(8, -8);
    final rect = Rect.fromLTWH(
      origin.dx - 4,
      origin.dy - 2,
      tp.width + 8,
      tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    tp.paint(canvas, origin);
  }

  Offset _project(PoseLandmark landmark, Size canvasSize) {
    return Offset(
      _translateX(landmark.x, canvasSize),
      _translateY(landmark.y, canvasSize),
    );
  }

  double _translateX(double x, Size canvasSize) {
    final isFront = cameraLensDirection == CameraLensDirection.front;

    switch (rotation) {
      case InputImageRotation.rotation90deg:
        {
          final scaled = x *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height);
          // Front preview is mirrored; match that so the skeleton lines up.
          return isFront ? canvasSize.width - scaled : scaled;
        }
      case InputImageRotation.rotation270deg:
        {
          final scaled = x *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height);
          return isFront ? scaled : canvasSize.width - scaled;
        }
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        {
          final scaled = x * canvasSize.width / imageSize.width;
          return isFront ? canvasSize.width - scaled : scaled;
        }
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
        oldDelegate.formGood != formGood ||
        oldDelegate.angles != angles ||
        oldDelegate.highlightTypes != highlightTypes;
  }
}
