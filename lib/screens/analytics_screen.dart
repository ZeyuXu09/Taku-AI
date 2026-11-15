import 'package:flutter/material.dart';
import 'package:peakform_ai/models/body_metrics.dart';
import 'package:peakform_ai/services/body_metrics_service.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/services/workout_log_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/utils/training_streak.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.onBack, this.onNavTap});

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _timeframeIndex = 0;
  int _metricTabIndex = 0;

  static const _timeframes = ['Week', 'Month', 'Season'];
  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthLabels = ['W1', 'W2', 'W3', 'W4'];
  static const _seasonLabels = ['M1', 'M2', 'M3', 'M4', 'M5', 'M6'];

  @override
  void initState() {
    super.initState();
    WorkoutLogService.instance.completedDays.addListener(_refresh);
    BodyMetricsService.instance.metrics.addListener(_refresh);
    BodyMetricsService.instance.history.addListener(_refresh);
    BodyMetricsService.instance.hasUserMetrics.addListener(_refresh);
    TrainingPreferencesService.instance.preferences.addListener(_refresh);
    UserProfileService.instance.profile.addListener(_refresh);
  }

  @override
  void dispose() {
    WorkoutLogService.instance.completedDays.removeListener(_refresh);
    BodyMetricsService.instance.metrics.removeListener(_refresh);
    BodyMetricsService.instance.history.removeListener(_refresh);
    BodyMetricsService.instance.hasUserMetrics.removeListener(_refresh);
    TrainingPreferencesService.instance.preferences.removeListener(_refresh);
    UserProfileService.instance.profile.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isMetric =>
      UserProfileService.instance.displayUnits.toLowerCase().contains('metric');

  List<DateTime> get _completedDays =>
      WorkoutLogService.instance.completedDays.value
          .map(trainingDateOnly)
          .toSet()
          .toList();

  int get _weeklyGoal {
    final goal = TrainingPreferencesService
        .instance.preferences.value.intensity.sessionsPerWeek;
    return goal < 1 ? 1 : goal;
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildTimeframeToggle(),
                    const SizedBox(height: 20),
                    _buildGaugeRow(),
                    const SizedBox(height: 16),
                    _buildActivityChart(),
                    const SizedBox(height: 20),
                    _buildBodyMetrics(),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 4,
              onTap: widget.onNavTap ?? (_) {},
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
        _IconBoxButton(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 32,
          iconSize: 16,
          onTap: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        Text(
          'Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildTimeframeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(_timeframes.length, (index) {
          final selected = index == _timeframeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeframeIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _timeframes[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  _LoadStats _loadStats() {
    final now = DateTime.now();
    final days = _completedDays;
    final goal = _weeklyGoal;

    late final int sessions;
    late final int target;
    switch (_timeframeIndex) {
      case 1:
        sessions = _sessionsInLastDays(days, now, 28);
        target = goal * 4;
      case 2:
        sessions = _sessionsInLastDays(days, now, 180);
        target = goal * 26;
      default:
        sessions = sessionsInWeek(days, mondayOf(now));
        target = goal;
    }

    if (sessions == 0) {
      return const _LoadStats(
        progress: 0,
        value: '0%',
        status: 'No sessions',
      );
    }

    final progress = (sessions / target).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final status = sessions >= target
        ? (sessions > target ? 'High' : 'On target')
        : 'Building';
    return _LoadStats(
      progress: progress,
      value: '$percent%',
      status: status,
    );
  }

  _RecoveryStats _recoveryStats() {
    final days = _completedDays;
    if (days.isEmpty) {
      return const _RecoveryStats(
        progress: 0,
        value: '0%',
        status: 'No sessions',
      );
    }

    final last = days.reduce((a, b) => a.isAfter(b) ? a : b);
    final restDays = trainingDateOnly(DateTime.now()).difference(last).inDays;

    if (restDays <= 0) {
      return const _RecoveryStats(
        progress: 0.45,
        value: '45%',
        status: 'Recovering',
      );
    }
    if (restDays == 1) {
      return const _RecoveryStats(
        progress: 0.70,
        value: '70%',
        status: 'Rebounding',
      );
    }
    if (restDays == 2) {
      return const _RecoveryStats(
        progress: 0.85,
        value: '85%',
        status: 'Rested',
      );
    }
    return const _RecoveryStats(
      progress: 1,
      value: '100%',
      status: 'Well Rested',
    );
  }

  Widget _buildGaugeRow() {
    final load = _loadStats();
    final recovery = _recoveryStats();

    return Row(
      children: [
        Expanded(
          child: _gaugeCard(
            label: 'Training Load',
            progress: load.progress,
            value: load.value,
            status: load.status,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _gaugeCard(
            label: 'Recovery',
            progress: recovery.progress,
            value: recovery.value,
            status: recovery.status,
            color: AppColors.accent,
            statusColor: AppColors.accentLight,
          ),
        ),
      ],
    );
  }

  Widget _gaugeCard({
    required String label,
    required double progress,
    required String value,
    required String status,
    required Color color,
    Color? statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ProgressRing(
            progress: progress,
            size: 90,
            strokeWidth: 8,
            color: color,
            center: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor ?? color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final now = DateTime.now();
    final days = _completedDays;
    late final String title;
    late final List<String> labels;
    late final List<double> heights;

    switch (_timeframeIndex) {
      case 1:
        title = 'Last 4 Weeks';
        labels = _monthLabels;
        heights = List.generate(4, (index) {
          final monday = mondayOf(now).subtract(Duration(days: (3 - index) * 7));
          return (sessionsInWeek(days, monday) / _weeklyGoal).clamp(0.0, 1.0);
        });
      case 2:
        title = 'Last 6 Months';
        labels = _seasonLabels;
        heights = List.generate(6, (index) {
          final month = DateTime(now.year, now.month - (5 - index), 1);
          return (_sessionsInMonth(days, month) / (_weeklyGoal * 4))
              .clamp(0.0, 1.0);
        });
      default:
        title = 'This Week';
        labels = _weekDays;
        final monday = mondayOf(now);
        heights = List.generate(7, (index) {
          final day = monday.add(Duration(days: index));
          return days.any((logged) => logged == day) ? 1.0 : 0.0;
        });
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (index) {
                final height = heights[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 28),
                              height: height <= 0 ? 6 : 100 * height,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                color: height <= 0 ? AppColors.barTrack : null,
                                gradient: height <= 0
                                    ? null
                                    : const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.accent,
                                          Color(0xFF00F5A0),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetrics() {
    const tabs = ['Weight', 'Body Fat', 'Muscle'];
    final hasMetrics = BodyMetricsService.instance.hasUserMetrics.value;
    final metrics = BodyMetricsService.instance.metrics.value;
    final snapshots = BodyMetricsService.instance.history.value;
    final points = snapshots.isNotEmpty
        ? snapshots.sublist(
            snapshots.length > 6 ? snapshots.length - 6 : 0,
          )
        : const <BodyMetricSnapshot>[];

    String currentLabel;
    String? changeLabel;
    switch (_metricTabIndex) {
      case 1:
        currentLabel = '${metrics.bodyFatPercent.toStringAsFixed(1)}%';
        changeLabel = _changeLabel(
          current: metrics.bodyFatPercent,
          previous: metrics.previousBodyFatPercent,
          format: (value) => '${value.abs().toStringAsFixed(1)}%',
        );
      case 2:
        currentLabel = _formatWeight(metrics.muscleMassLbs);
        changeLabel = _changeLabel(
          current: metrics.muscleMassLbs,
          previous: metrics.previousMuscleMassLbs,
          format: (value) => _formatWeight(value.abs()),
        );
      default:
        currentLabel = _formatWeight(metrics.weightLbs);
        changeLabel = _changeLabel(
          current: metrics.weightLbs,
          previous: metrics.previousWeightLbs,
          format: (value) => _formatWeight(value.abs()),
        );
    }

    final values = points.map((point) => point.valueFor(_metricTabIndex)).toList();
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final minValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final spread = (maxValue - minValue).abs();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Metrics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(tabs.length, (index) {
              final selected = index == _metricTabIndex;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _metricTabIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : AppColors.barTrack,
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.accentLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (!hasMetrics)
            _emptyMetricsHint()
          else ...[
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (changeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                changeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(points.length, (index) {
                  final value = values[index];
                  final height = spread < 0.05
                      ? 0.72
                      : 0.35 + 0.65 * ((value - minValue) / spread);
                  final label = points.length == 2
                      ? (index == 0 ? 'Last' : 'Now')
                      : 'W${index + 1}';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                height: 80 * height,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.35 + index * 0.08,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navInactive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyMetricsHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.barTrack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Add weight, body fat, and muscle in Growth Hub to track changes here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  String _formatWeight(double lbs) {
    if (_isMetric) {
      return '${(lbs * 0.45359237).toStringAsFixed(1)} kg';
    }
    return '${lbs % 1 == 0 ? lbs.toStringAsFixed(0) : lbs.toStringAsFixed(1)} lbs';
  }

  String? _changeLabel({
    required double current,
    required double? previous,
    required String Function(double) format,
  }) {
    if (previous == null) return 'From Growth Hub';
    final delta = current - previous;
    if (delta.abs() < 0.05) return 'No change since last update';
    final sign = delta > 0 ? '+' : '-';
    return '$sign${format(delta)} since last update';
  }

  static int _sessionsInLastDays(
    Iterable<DateTime> completedDays,
    DateTime now,
    int dayCount,
  ) {
    final end = trainingDateOnly(now);
    final start = end.subtract(Duration(days: dayCount - 1));
    return completedDays
        .map(trainingDateOnly)
        .where((day) => !day.isBefore(start) && !day.isAfter(end))
        .length;
  }

  static int _sessionsInMonth(Iterable<DateTime> completedDays, DateTime month) {
    return completedDays
        .map(trainingDateOnly)
        .where((day) => day.year == month.year && day.month == month.month)
        .length;
  }
}

class _LoadStats {
  const _LoadStats({
    required this.progress,
    required this.value,
    required this.status,
  });

  final double progress;
  final String value;
  final String status;
}

class _RecoveryStats {
  const _RecoveryStats({
    required this.progress,
    required this.value,
    required this.status,
  });

  final double progress;
  final String value;
  final String status;
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
        side: BorderSide(color: AppColors.cardBorder),
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
