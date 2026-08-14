import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peakform_ai/models/nutrition_log.dart';
import 'package:peakform_ai/screens/nutrition_scanner_screen.dart';
import 'package:peakform_ai/services/nutrition_log_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/add_food_sheet.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late int _selectedDayIndex;
  late List<DateTime> _weekDates;

  final _numberFormat = NumberFormat('#,###');

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _selectedDate => _weekDates[_selectedDayIndex];

  String get _mealsSectionTitle {
    if (_isSameDay(_selectedDate, _today)) {
      return "Today's Meals";
    }
    return 'Meals on ${DateFormat('MMM d').format(_selectedDate)}';
  }

  @override
  void initState() {
    super.initState();
    _weekDates = _currentWeekDates();
    _selectedDayIndex = _weekDates.indexWhere((d) => _isSameDay(d, _today));
    if (_selectedDayIndex < 0) {
      _selectedDayIndex = 0;
    }
  }

  List<DateTime> _currentWeekDates() {
    final today = _today;
    final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
    return List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NutritionScannerScreen(logDate: _selectedDate),
      ),
    );
  }

  Future<void> _openManualAdd() async {
    final saved = await showAddFoodSheet(context, logDate: _selectedDate);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food added to your log')),
      );
    }
  }

  String _formatMacro(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}g';
    }
    return '${value.toStringAsFixed(1)}g';
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
              child: ValueListenableBuilder<List<NutritionLog>>(
                valueListenable: NutritionLogService.instance.logs,
                builder: (context, _, __) {
                  final dayLogs =
                      NutritionLogService.instance.logsForDay(_selectedDate);
                  final totals =
                      NutritionLogService.instance.totalsForDay(_selectedDate);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildWeekPicker(),
                        const SizedBox(height: 24),
                        _buildCalorieSection(totals),
                        const SizedBox(height: 20),
                        _buildCalorieBreakdown(totals),
                        const SizedBox(height: 24),
                        _buildMacroRings(totals),
                        const SizedBox(height: 28),
                        _sectionTitle(_mealsSectionTitle),
                        if (dayLogs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _openManualAdd,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Food'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (dayLogs.isEmpty)
                          _buildEmptyMeals()
                        else
                          ...dayLogs.map(_buildMealItem),
                      ],
                    ),
                  );
                },
              ),
            ),
            PeakBottomNav(
              currentIndex: 3,
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
        Text(
          'Nutrition',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            _IconBoxButton(
              icon: Icons.add_rounded,
              onTap: _openManualAdd,
            ),
            const SizedBox(width: 8),
            _IconBoxButton(
              icon: Icons.qr_code_scanner_rounded,
              onTap: _openScanner,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekPicker() {
    return Row(
      children: List.generate(_weekDates.length, (index) {
        final date = _weekDates[index];
        final label = DateFormat('EEE').format(date);
        final selected = index == _selectedDayIndex;
        final isToday = _isSameDay(date, _today);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.accent
                        : isToday
                            ? AppColors.green
                            : AppColors.navInactive,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: !selected && isToday
                        ? Border.all(color: AppColors.green, width: 2)
                        : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : isToday
                              ? AppColors.green
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalorieSection(NutritionDayTotals totals) {
    final progress = totals.calories / NutritionLogService.calorieGoal;

    return Center(
      child: ProgressRing(
        progress: progress.clamp(0, 1),
        size: 180,
        strokeWidth: 12,
        color: AppColors.accent,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _numberFormat.format(totals.calories.round()),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '/ ${_numberFormat.format(NutritionLogService.calorieGoal.round())} kcal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieBreakdown(NutritionDayTotals totals) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _breakdownItem(
          _numberFormat.format(totals.calories.round()),
          'Eaten',
          AppColors.accent,
        ),
        const SizedBox(width: 32),
        _breakdownItem('0', 'Burned', const Color(0xFFEF4444)),
        const SizedBox(width: 32),
        _breakdownItem(
          _numberFormat.format(totals.calories.round()),
          'Net',
          AppColors.green,
        ),
      ],
    );
  }

  Widget _breakdownItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRings(NutritionDayTotals totals) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _macroRingItem(
          _formatMacro(totals.proteinG),
          'Protein',
          totals.proteinG / NutritionLogService.proteinGoalG,
          AppColors.accent,
        ),
        const SizedBox(width: 24),
        _macroRingItem(
          _formatMacro(totals.carbsG),
          'Carbs',
          totals.carbsG / NutritionLogService.carbsGoalG,
          AppColors.green,
        ),
        const SizedBox(width: 24),
        _macroRingItem(
          _formatMacro(totals.fatG),
          'Fat',
          totals.fatG / NutritionLogService.fatGoalG,
          const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _macroRingItem(
    String value,
    String label,
    double progress,
    Color color,
  ) {
    return Column(
      children: [
        ProgressRing(
          progress: progress.clamp(0, 1),
          size: 72,
          strokeWidth: 6,
          color: color,
          center: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 36,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan a barcode or add food manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _openManualAdd,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Add Manually'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan Barcode'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(NutritionLog log) {
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
              child: log.imageUrl != null
                  ? Image.network(
                      log.imageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _mealPlaceholder(),
                    )
                  : _mealPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    log.metaLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_numberFormat.format(log.totalCalories.round())} kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (log.servings > 1)
                  Text(
                    '${_formatNumber(log.servings)} servings',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: () => _confirmDelete(log),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<void> _confirmDelete(NutritionLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remove meal?'),
        content: Text('Remove ${log.productName} from this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NutritionLogService.instance.deleteLog(log.id);
    }
  }

  Widget _mealPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.barTrack,
      child: Icon(
        Icons.restaurant_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _IconBoxButton extends StatelessWidget {
  const _IconBoxButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

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
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
