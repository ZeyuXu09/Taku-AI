import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakform_ai/models/coach_feedback_entry.dart';
import 'package:peakform_ai/theme/app_colors.dart';

final coachFeedbackTimeFormat = DateFormat('MMM d · h:mm a');
final _todayTimeFormat = DateFormat.jm();

String formatCoachFeedbackTime(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) {
    return _todayTimeFormat.format(local);
  }
  return coachFeedbackTimeFormat.format(local);
}

class CoachFeedbackCard extends StatelessWidget {
  const CoachFeedbackCard({
    super.key,
    required this.entry,
    this.compact = false,
  });

  final CoachFeedbackEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = entry.isCorrection ? AppColors.yellow : AppColors.green;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.isCorrection ? 'FIX' : 'GOOD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.exercise,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                formatCoachFeedbackTime(entry.at),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.message,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: TextStyle(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
          if (!compact && entry.reps > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${entry.reps} reps',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
