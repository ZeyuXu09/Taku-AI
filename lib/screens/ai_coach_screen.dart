import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/utils/pose_geometry.dart';
import 'package:peakform_ai/widgets/live_pose_camera.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/pose_overlay_painter.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({
    super.key,
    this.onBack,
    this.onNavTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  static const _athleteUrl =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80';

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

enum _CoachInputMode { idle, photo, live }

class _AiCoachScreenState extends State<AiCoachScreen> {
  late final ImagePicker _picker;
  late final PoseDetector _poseDetector;

  File? _image;
  Pose? _pose;
  double _imageWidth = 0;
  double _imageHeight = 0;
  bool _processing = false;
  String? _errorMessage;
  _CoachInputMode _inputMode = _CoachInputMode.idle;

  bool get _isLiveMode => _inputMode == _CoachInputMode.live;

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _inputMode = _CoachInputMode.photo;
      _image = File(pickedFile.path);
      _pose = null;
      _errorMessage = null;
    });

    await _processImage();
  }

  void _startLiveMode() {
    setState(() {
      _inputMode = _CoachInputMode.live;
      _image = null;
      _pose = null;
      _errorMessage = null;
      _processing = false;
    });
  }

  void _stopLiveMode() {
    setState(() {
      _inputMode = _CoachInputMode.idle;
      _pose = null;
      _errorMessage = null;
    });
  }

  void _onLivePose(Pose? pose) {
    if (!mounted || !_isLiveMode) return;
    setState(() {
      _pose = pose;
      _errorMessage = pose == null
          ? 'No pose detected. Stand fully in frame with good lighting.'
          : null;
    });
  }

  Future<void> _processImage() async {
    final image = _image;
    if (image == null) return;

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decodedWidth = frame.image.width.toDouble();
      final decodedHeight = frame.image.height.toDouble();
      frame.image.dispose();

      final inputImage = InputImage.fromFilePath(image.path);
      final poses = await _poseDetector.processImage(inputImage);

      if (!mounted) return;

      if (poses.isEmpty) {
        setState(() {
          _pose = null;
          _imageWidth = decodedWidth;
          _imageHeight = decodedHeight;
          _errorMessage =
              'No pose detected. Try an image with a clearly visible person.';
        });
        return;
      }

      setState(() {
        _pose = poses.first;
        _imageWidth = decodedWidth;
        _imageHeight = decodedHeight;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred when processing the image.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when processing the image'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  double get _confidence => _pose == null ? 0 : averageLandmarkConfidence(_pose!);

  Set<PoseLandmarkType> get _highlightTypes {
    final leftKnee = _kneeAngles
        .where((angle) => angle.label == 'Left Knee' && angle.isWarning)
        .isNotEmpty;
    if (leftKnee) {
      return {
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      };
    }

    final rightKnee = _kneeAngles
        .where((angle) => angle.label == 'Right Knee' && angle.isWarning)
        .isNotEmpty;
    if (rightKnee) {
      return {
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
      };
    }

    return const {};
  }

  List<JointAngle> get _kneeAngles =>
      _pose == null ? const [] : kneeAnglesFromPose(_pose!);

  JointAngle? _jointAngle(String label) {
    for (final angle in _kneeAngles) {
      if (angle.label == label) return angle;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildFeaturedBadge(),
                    _buildTopBar(context),
                    const SizedBox(height: 8),
                    _buildCameraFeed(),
                    _buildMetrics(),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 2,
              onTap: widget.onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'FEATURED AI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.green,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _IconBoxButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 32,
            iconSize: 16,
            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'AI TRAINING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _pose == null ? AppColors.textSecondary : AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: _pose == null
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isLiveMode
                        ? (_pose == null ? 'SCAN' : 'LIVE')
                        : (_pose == null ? 'READY' : 'LIVE'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isLiveMode || _pose != null
                          ? AppColors.green
                          : AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (_isLiveMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'REC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isLiveMode)
                LivePoseCamera(
                  onPose: _onLivePose,
                  highlightTypes: _highlightTypes,
                )
              else if (_image != null)
                Image.file(
                  _image!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                Image.network(
                  AiCoachScreen._athleteUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.card),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              if (!_isLiveMode && _pose != null)
                CustomPaint(
                  painter: PoseOverlayPainter(
                    pose: _pose!,
                    imageWidth: _imageWidth,
                    imageHeight: _imageHeight,
                    highlightTypes: _highlightTypes,
                  ),
                )
              else if (!_isLiveMode && _inputMode == _CoachInputMode.idle)
                const CustomPaint(painter: _DemoPoseSkeletonPainter()),
              if (_processing)
                Container(
                  color: AppColors.background.withValues(alpha: 0.55),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: _feedBadge(
                  '${_pose?.landmarks.length ?? 0} KEYPOINTS',
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _feedBadge(
                  _pose == null
                      ? 'AWAITING INPUT'
                      : '${(_confidence * 100).round()}% CONFIDENCE',
                  color: _pose == null ? null : AppColors.green,
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.yellow,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'AI COACH: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: _errorMessage ??
                              (_isLiveMode && _pose == null
                                  ? 'Point the camera at yourself to analyze form in real time.'
                                  : coachFeedbackForPose(_pose)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _feedStat(
                      'Stability',
                      _pose == null ? '--' : '${(_confidence * 100).round()}%',
                    ),
                    _feedStat(
                      'People',
                      _pose == null ? '0' : '1',
                    ),
                  ],
                ),
              ),
              if (!_isLiveMode && _inputMode == _CoachInputMode.idle && !_processing)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PickerButton(
                        icon: Icons.videocam_rounded,
                        label: 'Live',
                        onTap: _startLiveMode,
                      ),
                      const SizedBox(height: 10),
                      _PickerButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => _getImage(ImageSource.gallery),
                      ),
                      const SizedBox(height: 10),
                      _PickerButton(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        onTap: () => _getImage(ImageSource.camera),
                      ),
                    ],
                  ),
                ),
              if (_isLiveMode)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PickerChip(
                      icon: Icons.close_rounded,
                      label: 'Exit Live',
                      onTap: _stopLiveMode,
                    ),
                  ),
                ),
              if (!_isLiveMode && _image != null && !_processing)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _PickerChip(
                          icon: Icons.videocam_rounded,
                          label: 'Live',
                          onTap: _startLiveMode,
                        ),
                        _PickerChip(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: () => _getImage(ImageSource.gallery),
                        ),
                        _PickerChip(
                          icon: Icons.photo_camera_rounded,
                          label: 'Camera',
                          onTap: () => _getImage(ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedBadge(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _feedStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final confidence = _confidence;
    final rating = _pose == null ? '--' : formRatingLabel(confidence);
    final progress = _pose == null ? 0.0 : confidence;
    final ringColor =
        confidence >= 0.75 ? AppColors.green : AppColors.yellow;

    final leftKnee = _jointAngle('Left Knee');
    final rightKnee = _jointAngle('Right Knee');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressRing(
            progress: progress,
            size: 100,
            strokeWidth: 8,
            color: ringColor,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _pose == null ? '--' : '${(confidence * 100).round()}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JOINT ANGLES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _jointCard(
                  'Left Knee',
                  leftKnee == null ? '--' : '${leftKnee.degrees.round()}°',
                  isWarning: leftKnee?.isWarning ?? false,
                ),
                const SizedBox(height: 8),
                _jointCard(
                  'Right Knee',
                  rightKnee == null ? '--' : '${rightKnee.degrees.round()}°',
                  isWarning: rightKnee?.isWarning ?? false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jointCard(String name, String angle, {required bool isWarning}) {
    final color = isWarning ? AppColors.yellow : AppColors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isWarning ? 0.3 : 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            angle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoPoseSkeletonPainter extends CustomPainter {
  const _DemoPoseSkeletonPainter();

  static const _viewWidth = 300.0;
  static const _viewHeight = 400.0;

  static const _lines = [
    (150.0, 95.0, 150.0, 185.0),
    (115.0, 105.0, 185.0, 105.0),
    (115.0, 105.0, 95.0, 155.0),
    (95.0, 155.0, 88.0, 200.0),
    (185.0, 105.0, 205.0, 155.0),
    (205.0, 155.0, 212.0, 200.0),
    (135.0, 185.0, 120.0, 260.0),
    (120.0, 260.0, 110.0, 340.0),
    (165.0, 185.0, 180.0, 260.0),
    (180.0, 260.0, 190.0, 340.0),
  ];

  static const _joints = [
    (150.0, 95.0, 5.0, false),
    (115.0, 105.0, 4.0, false),
    (185.0, 105.0, 4.0, false),
    (95.0, 155.0, 3.5, false),
    (205.0, 155.0, 3.5, false),
    (150.0, 185.0, 4.5, false),
    (120.0, 260.0, 6.0, true),
    (180.0, 260.0, 5.0, false),
    (110.0, 340.0, 4.0, false),
    (190.0, 340.0, 4.0, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _viewWidth;
    final scaleY = size.height / _viewHeight;

    Offset point(double x, double y) => Offset(x * scaleX, y * scaleY);

    final linePaint = Paint()
      ..color = AppColors.green.withValues(alpha: 0.45)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in _lines) {
      canvas.drawLine(
        point(line.$1, line.$2),
        point(line.$3, line.$4),
        linePaint,
      );
    }

    for (final joint in _joints) {
      final color = joint.$4
          ? AppColors.yellow.withValues(alpha: 0.45)
          : AppColors.green.withValues(alpha: 0.45);
      final paint = Paint()..color = color;
      canvas.drawCircle(
        point(joint.$1, joint.$2),
        joint.$3 * ((scaleX + scaleY) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IconBoxButton extends StatelessWidget {
  const _IconBoxButton({
    required this.icon,
    this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
