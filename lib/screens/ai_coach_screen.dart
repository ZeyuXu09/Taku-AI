import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/coach_exercise.dart';
import 'package:peakform_ai/coach/coach_session.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
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
  final _cameraKey = GlobalKey<LivePoseCameraState>();
  final _session = CoachSession.instance;

  File? _image;
  Pose? _pose;
  double _imageWidth = 0;
  double _imageHeight = 0;
  bool _processing = false;
  String? _errorMessage;
  _CoachInputMode _inputMode = _CoachInputMode.idle;

  late CoachExercise _exercise;
  late ExerciseAnalyzer _analyzer;
  late AnalysisResult _liveResult;

  bool get _isLiveMode => _inputMode == _CoachInputMode.live;

  int get _displayedReps => _liveResult.reps;

  Duration get _displayedHold => _liveResult.holdTime;

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

    _exercise = _session.exercise;
    _analyzer = _session.analyzerFor(_exercise);
    _liveResult = _session.resultFor(_exercise);

    if (_session.preferLiveOnReturn) {
      _inputMode = _CoachInputMode.live;
      _enableLiveOrientations();
    }
  }

  @override
  void dispose() {
    _session.selectExercise(_exercise);
    _session.setResult(_exercise, _liveResult);
    _session.markLeftScreen(wasLive: _isLiveMode);
    _poseDetector.close();
    _lockPortraitOnly();
    super.dispose();
  }

  /// Landscape is allowed only while the live camera is open.
  void _enableLiveOrientations() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _lockPortraitOnly() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
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
    _enableLiveOrientations();
    setState(() {
      _inputMode = _CoachInputMode.live;
      _image = null;
      _pose = null;
      _errorMessage = null;
      _processing = false;
      _analyzer = _session.analyzerFor(_exercise);
      _liveResult = _session.resultFor(_exercise);
    });
  }

  void _stopLiveMode() {
    _session.setResult(_exercise, _liveResult);
    _lockPortraitOnly();
    setState(() {
      _inputMode = _CoachInputMode.idle;
      _pose = null;
      _errorMessage = null;
    });
  }

  void _selectExercise(CoachExercise exercise) {
    if (_exercise == exercise) return;
    _session.setResult(_exercise, _liveResult);
    _session.selectExercise(exercise);
    setState(() {
      _exercise = exercise;
      _analyzer = _session.analyzerFor(exercise);
      _liveResult = _session.resultFor(exercise);
    });
  }

  void _resetLiveSession() {
    _session.resetCurrent();
    setState(() {
      _analyzer = _session.analyzerFor(_exercise);
      _liveResult = const AnalysisResult.waiting();
    });
  }

  void _flipCamera() {
    _cameraKey.currentState?.switchCamera();
  }

  void _zoomIn() {
    _cameraKey.currentState?.zoomIn();
  }

  void _zoomOut() {
    _cameraKey.currentState?.zoomOut();
  }

  void _onLivePose(Pose? pose) {
    if (!mounted || !_isLiveMode) return;

    if (pose == null) {
      setState(() {
        _pose = null;
        _liveResult = AnalysisResult(
          reps: _displayedReps,
          phase: 'Get into frame',
          poseVisible: false,
          formGood: false,
          holdTime: _displayedHold,
        );
        _errorMessage =
            'No pose detected. Stand fully in frame with good lighting.';
      });
      _session.setResult(_exercise, _liveResult);
      return;
    }

    final result = _analyzer.update(pose, DateTime.now());

    if (result.reps > _liveResult.reps) {
      HapticFeedback.mediumImpact();
    }
    if (result.cueIsNew) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _pose = pose;
      _liveResult = result;
      _errorMessage = result.poseVisible
          ? null
          : 'Get into frame — keep your full body visible.';
    });
    _session.setResult(_exercise, _liveResult);
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

  String get _coachCueText {
    if (_errorMessage != null) return _errorMessage!;
    if (_isLiveMode) {
      if (!_liveResult.poseVisible) {
        return 'Point the camera at yourself — keep your full body in frame.';
      }
      return _liveResult.cue ??
          (_liveResult.formGood
              ? 'Strong form. Keep going.'
              : 'Adjust your position and hold steady.');
    }
    return coachFeedbackForPose(_pose);
  }

  String _formatHold(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLiveMode) {
      return _buildLiveFullscreen();
    }

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
                    _buildExercisePicker(),
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

  /// Live mode: camera fills the phone screen and follows orientation.
  Widget _buildLiveFullscreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          final camera = LivePoseCamera(
            key: _cameraKey,
            onPose: _onLivePose,
            formGood: _liveResult.formGood,
            angles: _liveResult.angles,
            highlightTypes: _highlightTypes,
            showFlipButton: false,
          );

          if (isLandscape) {
            return Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      camera,
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _liveControlChips(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: SafeArea(
                    child: ColoredBox(
                      color: AppColors.background.withValues(alpha: 0.92),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _IconBoxButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  size: 32,
                                  iconSize: 16,
                                  onTap: _stopLiveMode,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _exercise.title.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                _feedBadge(
                                  _exercise.isStatic
                                      ? _formatHold(_displayedHold)
                                      : '$_displayedReps REPS',
                                  color: AppColors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildExercisePicker(),
                            const Spacer(),
                            _liveCoachBanner(),
                            const SizedBox(height: 10),
                            _liveStatsRow(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              camera,
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          _IconBoxButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            size: 32,
                            iconSize: 16,
                            onTap: _stopLiveMode,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _exercise.title.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          _feedBadge(
                            _exercise.isStatic
                                ? _formatHold(_displayedHold)
                                : '$_displayedReps REPS',
                            color: AppColors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildExercisePicker(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _liveControlChips(),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          _liveCoachBanner(),
                          const SizedBox(height: 10),
                          _liveStatsRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _liveControlChips() {
    return [
      _PickerChip(
        icon: Icons.zoom_out_rounded,
        label: 'Zoom −',
        onTap: _zoomOut,
      ),
      _PickerChip(
        icon: Icons.zoom_in_rounded,
        label: 'Zoom +',
        onTap: _zoomIn,
      ),
      _PickerChip(
        icon: Icons.cameraswitch_rounded,
        label: 'Flip',
        onTap: _flipCamera,
      ),
      _PickerChip(
        icon: Icons.refresh_rounded,
        label: 'Reset',
        onTap: _resetLiveSession,
      ),
      _PickerChip(
        icon: Icons.close_rounded,
        label: 'Exit Live',
        onTap: _stopLiveMode,
      ),
    ];
  }

  Widget _liveCoachBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.45)),
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
            TextSpan(text: _coachCueText),
          ],
        ),
      ),
    );
  }

  Widget _liveStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _feedStat(
            _exercise.isStatic ? 'Hold' : 'Reps',
            _exercise.isStatic
                ? _formatHold(_displayedHold)
                : '$_displayedReps',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _feedStat('Phase', _liveResult.phase),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _feedStat(
            'Form',
            !_liveResult.poseVisible
                ? '--'
                : (_liveResult.formGood ? 'GOOD' : 'FIX'),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFeed() {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    // Fill most of the available phone screen for the idle/photo preview.
    final feedHeight = isLandscape ? size.height * 0.72 : size.height * 0.55;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 20 : 16),
      child: SizedBox(
        width: double.infinity,
        height: feedHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: _cameraFeedStackChildren(includeLive: false),
          ),
        ),
      ),
    );
  }

  List<Widget> _cameraFeedStackChildren({bool includeLive = true}) {
    return [
              if (includeLive && _isLiveMode)
                LivePoseCamera(
                  key: _cameraKey,
                  onPose: _onLivePose,
                  formGood: _liveResult.formGood,
                  angles: _liveResult.angles,
                  highlightTypes: _highlightTypes,
                  showFlipButton: false,
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
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.card),
                ),
              IgnorePointer(
                child: Container(
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
              IgnorePointer(
                ignoring: _isLiveMode,
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _feedBadge(
                        _isLiveMode
                            ? _liveResult.phase.toUpperCase()
                            : '${_pose?.landmarks.length ?? 0} KEYPOINTS',
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _feedBadge(
                        _exercise.isStatic
                            ? _formatHold(_displayedHold)
                            : '$_displayedReps REPS',
                        color: AppColors.green,
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
                              TextSpan(text: _coachCueText),
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
                            _exercise.isStatic ? 'Hold' : 'Reps',
                            _exercise.isStatic
                                ? _formatHold(_displayedHold)
                                : '$_displayedReps',
                          ),
                          _feedStat(
                            'Form',
                            _isLiveMode
                                ? (!_liveResult.poseVisible
                                    ? '--'
                                    : (_liveResult.formGood ? 'GOOD' : 'FIX'))
                                : (_displayedReps > 0 ||
                                        _displayedHold > Duration.zero
                                    ? 'SAVED'
                                    : '--'),
                          ),
                        ],
                      ),
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
    ];
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
                _pose == null ? 'READY' : 'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _pose == null
                      ? AppColors.textSecondary
                      : AppColors.green,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePicker() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: CoachExercise.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final exercise = CoachExercise.values[index];
          final selected = exercise == _exercise;
          return ChoiceChip(
            avatar: Icon(
              exercise.icon,
              size: 16,
              color: selected ? AppColors.background : AppColors.textSecondary,
            ),
            label: Text(exercise.title),
            selected: selected,
            onSelected: (_) => _selectExercise(exercise),
            selectedColor: AppColors.green,
            backgroundColor: AppColors.card,
            side: BorderSide(
              color: selected ? AppColors.green : AppColors.cardBorder,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.background : AppColors.textPrimary,
            ),
            showCheckmark: false,
          );
        },
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
    // Always show the persisted live session score for the selected exercise.
    return _buildLiveMetrics();
  }

  Widget _buildLiveMetrics() {
    final result = _liveResult;
    final ringColor = _isLiveMode && !result.poseVisible
        ? AppColors.textSecondary
        : (result.formGood || result.reps > 0 || result.holdTime > Duration.zero
            ? AppColors.green
            : AppColors.yellow);
    final progress = !_isLiveMode
        ? (result.reps > 0 || result.holdTime > Duration.zero ? 1.0 : 0.0)
        : (!result.poseVisible
            ? (result.reps > 0 || result.holdTime > Duration.zero ? 0.7 : 0.0)
            : (result.formGood ? 1.0 : 0.45));
    final centerValue = _exercise.isStatic
        ? _formatHold(result.holdTime)
        : '${result.reps}';
    final centerLabel = _exercise.isStatic ? 'HOLD' : 'REPS';

    final angleCards = (!_isLiveMode || result.angles.isEmpty)
        ? [
            if (!_isLiveMode)
              _jointCard(
                'Session',
                _exercise.isStatic
                    ? _formatHold(result.holdTime)
                    : '${result.reps} reps',
                isWarning: false,
              )
            else
              _jointCard('Waiting', '--', isWarning: false),
            if (!_isLiveMode) ...[
              const SizedBox(height: 8),
              _jointCard(
                'Tip',
                'Tap Live to continue',
                isWarning: false,
              ),
            ],
          ]
        : result.angles
            .map(
              (angle) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _jointCard(
                  angle.label,
                  '${angle.degrees.round()}°',
                  isWarning: !result.formGood,
                ),
              ),
            )
            .toList();

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
                  centerValue,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  centerLabel,
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
                Text(
                  '${_exercise.title.toUpperCase()} · ${result.phase.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ...angleCards,
                if (!_isLiveMode && _pose != null) ...[
                  const SizedBox(height: 8),
                  _jointCard(
                    'Left Knee',
                    _jointAngle('Left Knee') == null
                        ? '--'
                        : '${_jointAngle('Left Knee')!.degrees.round()}°',
                    isWarning: _jointAngle('Left Knee')?.isWarning ?? false,
                  ),
                  const SizedBox(height: 8),
                  _jointCard(
                    'Right Knee',
                    _jointAngle('Right Knee') == null
                        ? '--'
                        : '${_jointAngle('Right Knee')!.degrees.round()}°',
                    isWarning: _jointAngle('Right Knee')?.isWarning ?? false,
                  ),
                ],
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
