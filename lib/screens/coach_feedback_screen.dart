import 'package:flutter/material.dart';
import 'package:peakform_ai/models/coach_feedback_entry.dart';
import 'package:peakform_ai/services/coach_feedback_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/coach_feedback_card.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';

void openCoachFeedbackScreen(
  BuildContext context, {
  ValueChanged<int>? onNavTap,
  int navIndex = 0,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) => CoachFeedbackScreen(
        onBack: () => Navigator.of(routeContext).pop(),
        onNavTap: (index) {
          Navigator.of(routeContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNavTap?.call(index);
          });
        },
        navIndex: navIndex,
      ),
    ),
  );
}

class CoachFeedbackScreen extends StatelessWidget {
  const CoachFeedbackScreen({
    super.key,
    this.onBack,
    this.onNavTap,
    this.navIndex = 4,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;
  final int navIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<CoachFeedbackEntry>>(
                valueListenable: CoachFeedbackService.instance.entries,
                builder: (context, items, _) {
                  return Column(
                    children: [
                      _buildHeader(context, items.isNotEmpty),
                      Expanded(
                        child: items.isEmpty
                            ? _emptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  24,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  return CoachFeedbackCard(entry: items[index]);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            PeakBottomNav(
              currentIndex: navIndex,
              onTap: onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canClear) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Coach Feedback',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (canClear)
            TextButton(
              onPressed: () => CoachFeedbackService.instance.clear(),
              child: Text(
                'Clear',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No feedback yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Live AI Coach saves one detailed note per set so you can read it after you rest.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
