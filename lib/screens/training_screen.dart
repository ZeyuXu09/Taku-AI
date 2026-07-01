import 'package:flutter/material.dart';
import 'package:peakform_ai/screens/ai_coach_screen.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({
    super.key,
    this.onBack,
    this.onNavTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  static const _exercises = [
    _Exercise(
      name: 'Lateral Shuttle Runs',
      detail: '4 sets × 30 sec · 1 min rest',
      imageUrl:
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=120&h=120&fit=crop',
    ),
    _Exercise(
      name: 'Box Jumps',
      detail: '3 sets × 10 reps · 90 sec rest',
      imageUrl:
          'https://images.unsplash.com/photo-1574680096145-d05b474e2aae?w=120&h=120&fit=crop',
    ),
    _Exercise(
      name: 'Agility Ladder Drills',
      detail: '4 sets × 45 sec · 45 sec rest',
      imageUrl:
          'https://images.unsplash.com/photo-1599058945522-28d584b6f53f?w=120&h=120&fit=crop',
    ),
    _Exercise(
      name: 'Single-Leg Squats',
      detail: '3 sets × 12 reps · 60 sec rest',
      imageUrl:
          'https://images.unsplash.com/photo-1434682881345-18ba6925622a?w=120&h=120&fit=crop',
    ),
  ];

  static const _routines = [
    _Routine(name: 'Spinal Decompression Hang', duration: '2 min'),
    _Routine(name: 'Cobra Stretch', duration: '1 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildFocusCard(),
                        const SizedBox(height: 24),
                        _sectionTitle('Exercises'),
                        const SizedBox(height: 12),
                        ..._exercises.map(_buildExerciseItem),
                        const SizedBox(height: 24),
                        _sectionTitle("Today's Routine"),
                        const SizedBox(height: 12),
                        ..._routines.map(_buildRoutineItem),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildCoachCta(context),
                  ),
                ],
              ),
            ),
            PeakBottomNav(
              currentIndex: 2,
              onTap: onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _IconBoxButton(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 32,
              iconSize: 16,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            const Text(
              "Today's Training",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _IconBoxButton(icon: Icons.search_rounded, onTap: () {}),
            const SizedBox(width: 8),
            _IconBoxButton(icon: Icons.filter_list_rounded, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nextGameStart, AppColors.nextGameEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S FOCUS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pre-Game Agility',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _focusStat(Icons.schedule_rounded, '45 min'),
              _focusStat(Icons.local_fire_department_rounded, '350 cal'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Medium-High',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: 'Program: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                TextSpan(
                  text:
                      'Agility & Speed. An integrated boost to your next game.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildExerciseItem(_Exercise exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                exercise.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.barTrack,
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.detail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _PlayButton(onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(_Routine routine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    routine.duration,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _PlayButton(onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            Color(0xCC0B0E11),
            Colors.transparent,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, Color(0xFF764BA2)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => AiCoachScreen(
                    onBack: () => Navigator.of(routeContext).pop(),
                    onNavTap: (index) {
                      Navigator.of(routeContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onNavTap?.call(index);
                      });
                    },
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Start Workout with AI Coach',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Exercise {
  const _Exercise({
    required this.name,
    required this.detail,
    required this.imageUrl,
  });

  final String name;
  final String detail;
  final String imageUrl;
}

class _Routine {
  const _Routine({required this.name, required this.duration});

  final String name;
  final String duration;
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
          child: Icon(icon, size: iconSize, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.play_arrow_rounded,
            color: AppColors.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}
