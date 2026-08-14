import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/screens/exercise_detail_screen.dart';
import 'package:peakform_ai/services/workout_log_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

void openActiveWorkout(BuildContext context, {required TrainingSession session}) {
  final items = _workoutItems(session);
  if (items.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ActiveWorkoutScreen(session: session),
    ),
  );
}

List<ScheduledExercise> _workoutItems(TrainingSession session) {
  if (session.isRestDay) return session.routines;
  return [...session.exercises, ...session.routines];
}

String formatWorkoutDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.session});

  final TrainingSession session;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  static const _defaultRestDuration = Duration(seconds: 60);

  late final List<ScheduledExercise> _items;

  Timer? _timer;
  int _currentIndex = 0;

  bool _isStarted = false;
  bool _isPaused = false;
  bool _isResting = false;
  bool _restComplete = false;

  Duration _totalExerciseElapsed = Duration.zero;
  Duration _restDuration = _defaultRestDuration;
  Duration _restRemaining = _defaultRestDuration;

  @override
  void initState() {
    super.initState();
    _items = _workoutItems(widget.session);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ScheduledExercise get _currentExercise => _items[_currentIndex];

  bool get _isExerciseTimerActive =>
      _isStarted && !_isPaused && !_isResting;

  bool get _isRestTimerActive => _isResting && !_isPaused && !_restComplete;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_isStarted) return;

    setState(() {
      if (_isExerciseTimerActive) {
        _totalExerciseElapsed += const Duration(seconds: 1);
      }

      if (_isRestTimerActive) {
        if (_restRemaining > Duration.zero) {
          _restRemaining -= const Duration(seconds: 1);
        }
        if (_restRemaining <= Duration.zero) {
          _completeRest();
        }
      }
    });
  }

  void _startWorkout() {
    setState(() {
      _isStarted = true;
      _isPaused = false;
      _isResting = false;
      _restComplete = false;
    });
  }

  void _startRest() {
    if (!_isStarted || _isPaused) return;
    setState(() {
      _isResting = true;
      _restComplete = false;
      _restRemaining = _restDuration;
    });
  }

  void _completeRest() {
    _isResting = false;
    _restComplete = true;
    _restRemaining = Duration.zero;
    HapticFeedback.mediumImpact();
  }

  void _dismissRestRecovery() {
    setState(() {
      _restComplete = false;
      _restRemaining = _restDuration;
    });
  }

  void _togglePause() {
    if (!_isStarted) return;

    setState(() {
      if (_isPaused) {
        _isPaused = false;
      } else {
        _isPaused = true;
        _resetRestTimer();
      }
    });
  }

  void _resetRestTimer() {
    _isResting = false;
    _restComplete = false;
    _restRemaining = _restDuration;
  }

  void _goToExercise(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _currentIndex = index;
      _resetRestTimer();
    });
  }

  Future<bool> _confirmExit() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Leave workout?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Your progress will not be saved if you leave now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();
    if (!mounted) return;

    await WorkoutLogService.instance.logCompletion(
      title: widget.session.title,
      durationMinutes: _totalExerciseElapsed.inMinutes,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.green),
            SizedBox(width: 10),
            Text(
              'Workout complete',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(
              'Exercise time',
              formatWorkoutDuration(_totalExerciseElapsed),
            ),
            const SizedBox(height: 8),
            _summaryRow('Exercises', '${_items.length}'),
            const SizedBox(height: 8),
            _summaryRow('Focus', widget.session.title),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _items.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      if (!_isStarted) ...[
                        _buildStartPrompt(),
                      ] else ...[
                        _buildTimerSection(),
                        const SizedBox(height: 20),
                        _buildProgressBar(progress),
                        const SizedBox(height: 24),
                        _buildExerciseCard(),
                        const SizedBox(height: 24),
                        _buildExerciseNav(),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isStarted) _buildFinishBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  _items.first.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_items.length} exercises · Tap start when you are ready',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startWorkout,
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text('Start Workout'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (await _confirmExit() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.isRestDay ? 'Recovery Session' : 'Active Workout',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.session.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isStarted)
            Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              child: InkWell(
                onTap: _togglePause,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    final restProgress = _restDuration.inSeconds == 0
        ? 0.0
        : _restRemaining.inSeconds / _restDuration.inSeconds;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildExerciseTimeCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildRestTimerCard(restProgress)),
          ],
        ),
        if (_restComplete) ...[
          const SizedBox(height: 12),
          _buildRestRecoveryBanner(),
        ],
      ],
    );
  }

  Widget _buildExerciseTimeCard() {
    final statusLabel = !_isStarted
        ? 'NOT STARTED'
        : _isPaused
            ? 'PAUSED'
            : _isResting
                ? 'RESTING'
                : 'EXERCISE TIME';

    final statusColor = _isPaused
        ? AppColors.yellow
        : _isResting
            ? AppColors.accentLight
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            formatWorkoutDuration(_totalExerciseElapsed),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total exercise',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(double restProgress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isResting
              ? AppColors.accent.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          ProgressRing(
            progress: restProgress.clamp(0.0, 1.0),
            size: 72,
            strokeWidth: 7,
            color: _restComplete ? AppColors.green : AppColors.accent,
            center: Text(
              formatWorkoutDuration(_restRemaining),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _restComplete
                ? 'RECOVERED'
                : _isResting
                    ? 'RESTING'
                    : 'REST TIMER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _restComplete ? AppColors.green : AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (_restComplete)
            TextButton(
              onPressed: _dismissRestRecovery,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else if (_isResting)
            TextButton(
              onPressed: _isPaused
                  ? null
                  : () {
                      setState(_resetRestTimer);
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Cancel rest',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            FilledButton(
              onPressed: _isPaused ? null : _startRest,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.barTrack,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Start rest',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestRecoveryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rest complete — ready for your next set',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercise ${_currentIndex + 1} of ${_items.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.barTrack,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard() {
    final exercise = _currentExercise;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: exercise.imageUrl != null
                ? Image.network(
                    exercise.imageUrl!,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _exercisePlaceholder(),
                  )
                : _exercisePlaceholder(),
          ),
          const SizedBox(height: 16),
          Text(
            exercise.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.prescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => openExerciseDetail(context, exercise),
            icon: const Icon(Icons.info_outline_rounded, size: 16),
            label: const Text('How to do it'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _exercisePlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      color: AppColors.barTrack,
      child: Icon(
        Icons.fitness_center_rounded,
        size: 48,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildExerciseNav() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex >= _items.length - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isFirst ? null : () => _goToExercise(_currentIndex - 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isLast ? null : () => _goToExercise(_currentIndex + 1),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(isLast ? 'Last one' : 'Next'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.barTrack,
              disabledForegroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _finishWorkout,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Finish Workout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
