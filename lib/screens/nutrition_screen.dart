import 'package:flutter/material.dart';
import 'package:peakform_ai/screens/nutrition_scanner_screen.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedDayIndex = 5;

  static const _weekDays = [
    ('Mon', 14),
    ('Tue', 15),
    ('Wed', 16),
    ('Thu', 17),
    ('Fri', 18),
    ('Sat', 19),
    ('Sun', 20),
  ];

  static const _meals = [
    _Meal(
      name: 'Oatmeal with Berries',
      meta: 'Breakfast · 8:30 AM',
      calories: '350 kcal',
      imageUrl:
          'https://images.unsplash.com/photo-1517673132405-a837a4fbf9bd?w=120&h=120&fit=crop',
    ),
    _Meal(
      name: 'Grilled Chicken Salad',
      meta: 'Lunch · 12:15 PM',
      calories: '480 kcal',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=120&h=120&fit=crop',
    ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildWeekPicker(),
                    const SizedBox(height: 24),
                    _buildCalorieSection(),
                    const SizedBox(height: 20),
                    _buildCalorieBreakdown(),
                    const SizedBox(height: 24),
                    _buildMacroRings(),
                    const SizedBox(height: 28),
                    _sectionTitle("Today's Meals"),
                    const SizedBox(height: 12),
                    ..._meals.map(_buildMealItem),
                  ],
                ),
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
        const Text(
          'Nutrition',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        _IconBoxButton(
          icon: Icons.camera_alt_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NutritionScannerScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekPicker() {
    return Row(
      children: List.generate(_weekDays.length, (index) {
        final (label, date) = _weekDays[index];
        final selected = index == _selectedDayIndex;

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
                    color: selected ? AppColors.accent : AppColors.navInactive,
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
                  ),
                  child: Text(
                    '$date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
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

  Widget _buildCalorieSection() {
    return Center(
      child: ProgressRing(
        progress: 1680 / 2400,
        size: 180,
        strokeWidth: 12,
        color: AppColors.accent,
        center: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '1,680',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '/ 2,400 kcal',
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

  Widget _buildCalorieBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _breakdownItem('1,680', 'Eaten', AppColors.accent),
        const SizedBox(width: 32),
        _breakdownItem('420', 'Burned', const Color(0xFFEF4444)),
        const SizedBox(width: 32),
        _breakdownItem('1,260', 'Net', AppColors.green),
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
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRings() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _macroRingItem('130g', 'Protein', 130 / 180, AppColors.accent),
        const SizedBox(width: 24),
        _macroRingItem('185g', 'Carbs', 185 / 250, AppColors.green),
        const SizedBox(width: 24),
        _macroRingItem('52g', 'Fat', 52 / 70, const Color(0xFFF97316)),
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
          progress: progress,
          size: 72,
          strokeWidth: 6,
          color: color,
          center: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMealItem(_Meal meal) {
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
                meal.imageUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.barTrack,
                  child: const Icon(
                    Icons.restaurant_rounded,
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
                    meal.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meal.meta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              meal.calories,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meal {
  const _Meal({
    required this.name,
    required this.meta,
    required this.calories,
    required this.imageUrl,
  });

  final String name;
  final String meta;
  final String calories;
  final String imageUrl;
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
        side: const BorderSide(color: AppColors.cardBorder),
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
