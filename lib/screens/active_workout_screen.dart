import 'dart:async';

import 'package:flutter/material.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/screens/exercise_detail_screen.dart';
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
  late final List<ScheduledExercise> _items;
  late final DateTime _workoutStartedAt;
  late DateTime _exerciseStartedAt;

  Timer? _timer;
  Duration _workoutElapsed = Duration.zero;
  Duration _exerciseElapsed = Duration.zero;
  int _currentIndex = 0;
  bool _isPaused = false;
  Duration _pausedAccumulated = Duration.zero;
  DateTime? _pauseStartedAt;

  @override
  void initState() {
    super.initState();
    _items = _workoutItems(widget.session);
    final now = DateTime.now();
    _workoutStartedAt = now;
    _exerciseStartedAt = now;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ScheduledExercise get _currentExercise => _items[_currentIndex];

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_isPaused) return;
    setState(() {
      _workoutElapsed = DateTime.now().difference(_workoutStartedAt) -
          _pausedAccumulated;
      _exerciseElapsed = DateTime.now().difference(_exerciseStartedAt);
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        if (_pauseStartedAt != null) {
          _pausedAccumulated += DateTime.now().difference(_pauseStartedAt!);
        }
        _pauseStartedAt = null;
        _isPaused = false;
        _exerciseStartedAt = DateTime.now().subtract(_exerciseElapsed);
      } else {
        _pauseStartedAt = DateTime.now();
        _isPaused = true;
      }
    });
  }

  void _goToExercise(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _currentIndex = index;
      _exerciseStartedAt = DateTime.now();
      _exerciseElapsed = Duration.zero;
    });
  }

  Future<bool> _confirmExit() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Leave workout?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
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
            _summaryRow('Total time', formatWorkoutDuration(_workoutElapsed)),
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
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
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
                      _buildWorkoutTimer(),
                      const SizedBox(height: 20),
                      _buildProgressBar(progress),
                      const SizedBox(height: 24),
                      _buildExerciseCard(),
                      const SizedBox(height: 24),
                      _buildExerciseTimer(),
                      const SizedBox(height: 24),
                      _buildExerciseNav(),
                    ],
                  ),
                ),
              ),
              _buildFinishBar(context),
            ],
          ),
        ),
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
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.isRestDay ? 'Recovery Session' : 'Active Workout',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.session.title,
                  style: const TextStyle(
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
          Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.cardBorder),
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

  Widget _buildWorkoutTimer() {
    return Column(
      children: [
        Text(
          formatWorkoutDuration(_workoutElapsed),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isPaused ? 'PAUSED' : 'WORKOUT TIME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _isPaused ? AppColors.yellow : AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
              style: const TextStyle(
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.prescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
      child: const Icon(
        Icons.fitness_center_rounded,
        size: 48,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildExerciseTimer() {
    return Column(
      children: [
        ProgressRing(
          progress: (_exerciseElapsed.inSeconds % 60) / 60,
          size: 100,
          strokeWidth: 8,
          color: AppColors.green,
          center: Text(
            formatWorkoutDuration(_exerciseElapsed),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'EXERCISE TIME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
              side: const BorderSide(color: AppColors.cardBorder),
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
      decoration: const BoxDecoration(
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
