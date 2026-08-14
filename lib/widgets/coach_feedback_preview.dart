import 'package:flutter/material.dart';
import 'package:peakform_ai/models/coach_feedback_entry.dart';
import 'package:peakform_ai/screens/coach_feedback_screen.dart';
import 'package:peakform_ai/services/coach_feedback_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/coach_feedback_card.dart';

/// Recent cues on Home, Training, and idle AI Coach — not only in live mode.
class CoachFeedbackPreview extends StatelessWidget {
  const CoachFeedbackPreview({
    super.key,
    this.onNavTap,
    this.navIndex = 0,
    this.maxItems = 3,
    this.padded = false,
  });

  final ValueChanged<int>? onNavTap;
  final int navIndex;
  final int maxItems;
  final bool padded;

  void _open(BuildContext context) {
    openCoachFeedbackScreen(
      context,
      onNavTap: onNavTap,
      navIndex: navIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CoachFeedbackEntry>>(
      valueListenable: CoachFeedbackService.instance.entries,
      builder: (context, items, _) {
        final preview = items.take(maxItems).toList();

        return Padding(
          padding: padded
              ? const EdgeInsets.symmetric(horizontal: 20)
              : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Coach Feedback',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _open(context),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      items.isEmpty ? 'Open' : 'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (preview.isEmpty)
                _EmptyPreview(onTap: () => _open(context))
              else
                for (var i = 0; i < preview.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _open(context),
                    child: CoachFeedbackCard(
                      entry: preview[i],
                      compact: true,
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.green,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'One detailed note per set from Live AI Coach will show up here after you rest.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
