import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/coach_joint_angle.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/live_pose_overlay_painter.dart';

/// Live camera preview with on-device pose detection and pinch-to-zoom.
///
/// Preview uses [BoxFit.cover] so the image is never stretched — only cropped
/// to fill the available screen area in portrait or landscape.
class LivePoseCamera extends StatefulWidget {
  const LivePoseCamera({
    super.key,
    required this.onPose,
    this.formGood = true,
    this.angles = const [],
    this.highlightTypes = const {},
    this.showFlipButton = true,
  });

  final void Function(Pose? pose) onPose;
  final bool formGood;
  final List<CoachJointAngle> angles;
  final Set<PoseLandmarkType> highlightTypes;
  final bool showFlipButton;

  @override
  State<LivePoseCamera> createState() => LivePoseCameraState();
}

class LivePoseCameraState extends State<LivePoseCamera>
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

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _zoomAtScaleStart = 1.0;
  bool _showZoomHint = false;

  Orientation? _lastUiOrientation;

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

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) return;
      final orientation = MediaQuery.orientationOf(context);
      if (_lastUiOrientation == orientation) return;
      _lastUiOrientation = orientation;
      // Rebuild so CameraPreview / FittedBox pick up the new screen size.
      setState(() {});
    });
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
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
    if (_disposed) return;

    // Keep unlocked so CameraPreview can follow device rotation without
    // fighting a locked capture orientation (which caused wrong direction).
    try {
      await controller.unlockCaptureOrientation();
    } catch (_) {}

    await _initZoom(controller);
    if (_disposed) return;

    if (!controller.value.isStreamingImages) {
      await controller.startImageStream(_processImage);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initZoom(CameraController controller) async {
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom;
      _zoomAtScaleStart = _minZoom;
      await controller.setZoomLevel(_currentZoom);
    } catch (_) {
      _minZoom = 1.0;
      _maxZoom = 1.0;
      _currentZoom = 1.0;
    }
  }

  Future<void> switchCamera() => _switchCamera();

  bool get canSwitchCamera => _cameras.length > 1;

  bool get canZoom => _maxZoom > _minZoom + 0.01;

  Future<void> zoomIn() => _nudgeZoom(1.15);

  Future<void> zoomOut() => _nudgeZoom(1 / 1.15);

  Future<void> _nudgeZoom(double factor) async {
    if (!canZoom) return;
    await _setZoom((_currentZoom * factor).clamp(_minZoom, _maxZoom));
  }

  Future<void> _setZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = zoom.clamp(_minZoom, _maxZoom);
    if ((next - _currentZoom).abs() < 0.01) return;
    try {
      await controller.setZoomLevel(next);
      if (!_disposed && mounted) {
        setState(() {
          _currentZoom = next;
          _showZoomHint = true;
        });
      } else {
        _currentZoom = next;
      }
    } catch (_) {}
  }

  void _onScaleStart(ScaleStartDetails details) {
    _zoomAtScaleStart = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (!canZoom) return;
    if (details.pointerCount < 2 && (details.scale - 1).abs() < 0.02) {
      return;
    }
    await _setZoom(
      (_zoomAtScaleStart * details.scale).clamp(_minZoom, _maxZoom),
    );
  }

  void _onScaleEnd(ScaleEndDetails details) {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!_disposed && mounted) {
        setState(() => _showZoomHint = false);
      }
    });
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

    final previewSize = controller.value.previewSize!;
    final orientation = MediaQuery.orientationOf(context);

    // previewSize is reported in sensor/landscape coords. CameraPreview applies
    // its own rotation; we feed FittedBox the swapped size so BoxFit.cover fills
    // without stretching (same approach as the official camera examples).
    final previewWidth = previewSize.height;
    final previewHeight = previewSize.width;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: previewWidth,
                height: previewHeight,
                // Key forces CameraPreview to refresh after rotation.
                child: CameraPreview(
                  controller,
                  key: ValueKey(orientation),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: LivePoseOverlayPainter(
                pose: _pose,
                imageSize: _imageSize,
                rotation: _rotation,
                cameraLensDirection: _cameras[_cameraIndex].lensDirection,
                formGood: widget.formGood,
                angles: widget.angles,
                highlightTypes: widget.highlightTypes,
              ),
            ),
          ),
          if (_showZoomHint && canZoom)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showFlipButton && _cameras.length > 1)
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
      ),
    );
  }
}
