import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/live_pose_overlay_painter.dart';

/// Live camera preview with on-device pose detection.
class LivePoseCamera extends StatefulWidget {
  const LivePoseCamera({
    super.key,
    required this.onPose,
    this.highlightTypes = const {},
  });

  final void Function(Pose? pose) onPose;
  final Set<PoseLandmarkType> highlightTypes;

  @override
  State<LivePoseCamera> createState() => _LivePoseCameraState();
}

class _LivePoseCameraState extends State<LivePoseCamera>
    with WidgetsBindingObserver {
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _busy = false;
  bool _disposed = false;

  Pose? _pose;
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    _cameras = await availableCameras();
    _cameraIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex < 0 && _cameras.isNotEmpty) _cameraIndex = 0;
    if (_cameras.isNotEmpty) await _startController();
  }

  Future<void> _startController() async {
    final camera = _cameras[_cameraIndex];
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
    if (_disposed) return;
    await controller.startImageStream(_processImage);
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startController();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_busy || _disposed) return;
    _busy = true;
    final input = _toInputImage(image);
    if (input == null) {
      _busy = false;
      return;
    }

    try {
      final poses = await _detector.processImage(input);
      final pose = poses.isEmpty ? null : poses.first;
      widget.onPose(pose);
      if (!_disposed && mounted) {
        setState(() => _pose = pose);
      }
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    if (controller == null || _cameraIndex < 0) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    _rotation = rotation;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: _imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed &&
        !controller.value.isStreamingImages) {
      controller.startImageStream(_processImage);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
        CustomPaint(
          painter: LivePoseOverlayPainter(
            pose: _pose,
            imageSize: _imageSize,
            rotation: _rotation,
            cameraLensDirection: _cameras[_cameraIndex].lensDirection,
            highlightTypes: widget.highlightTypes,
          ),
        ),
        if (_cameras.length > 1)
          Positioned(
            top: 48,
            right: 8,
            child: Material(
              color: AppColors.background.withValues(alpha: 0.75),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _switchCamera,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.cameraswitch_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
