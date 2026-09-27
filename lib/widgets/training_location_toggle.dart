import 'package:flutter/material.dart';
import 'package:peakform_ai/models/training_location.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';

class TrainingLocationToggle extends StatelessWidget {
  const TrainingLocationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TrainingPreferences>(
      valueListenable: TrainingPreferencesService.instance.preferences,
      builder: (context, prefs, _) {
        final location = prefs.location;

        final narrow = MediaQuery.sizeOf(context).width < 390;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                label: 'Home',
                icon: Icons.home_rounded,
                selected: location == TrainingLocation.home,
                compact: narrow,
                onTap: () => _select(TrainingLocation.home),
              ),
              _Segment(
                label: 'Gym',
                icon: Icons.fitness_center_rounded,
                selected: location == TrainingLocation.gym,
                compact: narrow,
                onTap: () => _select(TrainingLocation.gym),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _select(TrainingLocation location) async {
    await TrainingPreferencesService.instance.saveLocation(location);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.45))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
