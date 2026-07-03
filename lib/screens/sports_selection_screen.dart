import 'package:flutter/material.dart';
import 'package:peakform_ai/data/sport_catalog.dart';
import 'package:peakform_ai/models/training_intensity.dart';
import 'package:peakform_ai/services/training_preferences_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';

class SportsSelectionScreen extends StatefulWidget {
  const SportsSelectionScreen({super.key, this.onBack, this.onNavTap});

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  @override
  State<SportsSelectionScreen> createState() => _SportsSelectionScreenState();
}

class _SportsSelectionScreenState extends State<SportsSelectionScreen> {
  final Set<int> _selectedSports = {0};
  int _selectedIntensity = 1;

  static const _sports = SportCatalog.sports;

  static const _intensityLevels = [
    ('🙂', 'Casual', Color(0xFF60A5FA)),
    ('🔥', 'Serious', Color(0xFFF97316)),
    ('🏆', 'Professional', Color(0xFFFFD600)),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    await TrainingPreferencesService.instance.load();
    final prefs = TrainingPreferencesService.instance.preferences.value;
    if (!mounted) return;

    final selected = <int>{};
    for (var i = 0; i < _sports.length; i++) {
      if (prefs.sports.contains(_sports[i].name)) {
        selected.add(i);
      }
    }

    setState(() {
      _selectedSports
        ..clear()
        ..addAll(selected.isEmpty ? {0} : selected);
      _selectedIntensity = switch (prefs.intensity) {
        TrainingIntensity.casual => 0,
        TrainingIntensity.serious => 1,
        TrainingIntensity.professional => 2,
      };
    });
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
                    _IconBoxButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      size: 32,
                      iconSize: 16,
                      onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 20),
                    _buildBrandHeader(),
                    const SizedBox(height: 24),
                    _sectionTitle('Choose Your Sport'),
                    const SizedBox(height: 12),
                    _buildSportsGrid(),
                    const SizedBox(height: 24),
                    _sectionTitle('Choose Your Intensity'),
                    const SizedBox(height: 12),
                    ...List.generate(_intensityLevels.length, _buildIntensityItem),
                    const SizedBox(height: 24),
                    _buildCta(context),
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

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFF764BA2)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 12),
        const Text(
          'PeakForm AI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your AI Performance Coach',
          style: TextStyle(
            fontSize: 12,
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

  Widget _buildSportsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _sports.length,
      itemBuilder: (context, index) {
        final sport = _sports[index];
        final selected = _selectedSports.contains(index);

        return Material(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? AppColors.accent
                  : AppColors.cardBorder,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedSports.remove(index);
                } else {
                  _selectedSports.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  sport.assetPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.sports_rounded,
                    size: 44,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    sport.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntensityItem(int index) {
    final (emoji, label, accentColor) = _intensityLevels[index];
    final selected = _selectedIntensity == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.cardBorder,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _selectedIntensity = index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.green : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.green : AppColors.navInactive,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.background,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return DecoratedBox(
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
          onTap: () async {
            final sports = _selectedSports.isEmpty
                ? [SportCatalog.defaultSport]
                : _selectedSports
                    .map((index) => _sports[index].name)
                    .toList();
            final intensity = switch (_selectedIntensity) {
              0 => TrainingIntensity.casual,
              2 => TrainingIntensity.professional,
              _ => TrainingIntensity.serious,
            };

            await TrainingPreferencesService.instance.save(
              sports: sports,
              intensity: intensity,
            );

            if (!context.mounted) return;

            if (widget.onNavTap != null) {
              widget.onNavTap!(0);
            } else {
              Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          child: Icon(icon, size: iconSize, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
