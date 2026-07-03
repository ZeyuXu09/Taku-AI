import 'package:flutter/material.dart';
import 'package:peakform_ai/data/day_templates.dart';
import 'package:peakform_ai/data/exercise_content.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';

Future<void> showChangeFocusSheet(
  BuildContext context, {
  required TrainingSession session,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ChangeFocusSheet(session: session),
  );
}

class ChangeFocusSheet extends StatelessWidget {
  const ChangeFocusSheet({super.key, required this.session});

  final TrainingSession session;

  Future<void> _selectFocus(BuildContext context, TrainingFocus focus) async {
    final scheduled = session.scheduledFocus;
    if (focus == scheduled && !session.isFocusCustomized) {
      Navigator.of(context).pop();
      return;
    }

    if (focus == scheduled) {
      await TrainingSessionOverrideService.instance.clearFocus(DateTime.now());
    } else {
      await TrainingSessionOverrideService.instance.saveFocus(
        date: DateTime.now(),
        focus: focus,
      );
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Change Today's Focus",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.isFocusCustomized
                        ? 'Custom focus · scheduled ${titleForFocus(session.scheduledFocus)}'
                        : 'Scheduled for today: ${titleForFocus(session.scheduledFocus)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  ...selectableTrainingFocuses.map((focus) {
                    final isSelected = session.focus == focus;
                    final isScheduled = session.scheduledFocus == focus;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _selectFocus(context, focus),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    iconForFocus(focus),
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titleForFocus(focus),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        descriptionForFocus(focus),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.35,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isScheduled && !session.isFocusCustomized)
                                  _badge('Scheduled')
                                else if (isScheduled)
                                  _badge('Default')
                                else if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.accent,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (session.isFocusCustomized) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _selectFocus(context, session.scheduledFocus),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: Text(
                        'Use scheduled focus (${titleForFocus(session.scheduledFocus)})',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
