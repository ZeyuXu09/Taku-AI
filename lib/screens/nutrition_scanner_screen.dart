import 'package:flutter/material.dart';
import 'package:peakform_ai/theme/app_colors.dart';

class NutritionScannerScreen extends StatelessWidget {
  const NutritionScannerScreen({super.key});

  static const _cameraUrl =
      'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&q=80';

  static const _recentScans = [
    _RecentScan(
      label: 'Protein Bar',
      imageUrl:
          'https://images.unsplash.com/photo-1606313564200-e75d5ecf5249?w=160&h=160&fit=crop',
    ),
    _RecentScan(
      label: 'Banana',
      imageUrl:
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=160&h=160&fit=crop',
    ),
    _RecentScan(
      label: 'Chicken Breast',
      imageUrl:
          'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=160&h=160&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildViewfinder()),
                _buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _cameraUrl,
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.5),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0A0C0F)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.4),
                AppColors.background.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScannerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 16,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Scan Label',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          _ScannerIconButton(
            icon: Icons.bolt_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._cornerPositions.map(
                    (corner) => _ViewfinderCorner(
                      alignment: corner.alignment,
                      borders: corner.borders,
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.08,
                    right: constraints.maxWidth * 0.08,
                    top: constraints.maxHeight * 0.45,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.accent,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: -36,
                    child: Text(
                      'Align nutrition label within frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.98),
            AppColors.background.withValues(alpha: 0.98),
            Colors.transparent,
          ],
          stops: const [0.0, 0.8, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResultCard(),
          const SizedBox(height: 20),
          const Text(
            'Recent Scans',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentScans.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final scan = _recentScans[index];
                return SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          scan.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.barTrack,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scan.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🥛', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Greek Yogurt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scanned just now',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _nutritionStat('160', 'cal'),
              const SizedBox(width: 8),
              _nutritionStat('15g', 'protein'),
              const SizedBox(width: 8),
              _nutritionStat('0g', 'fat'),
              const SizedBox(width: 8),
              _nutritionStat('4g', 'sugar'),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Add to Today's Log",
                        style: TextStyle(
                          fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _nutritionStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.barTrack,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _cornerPositions = [
    _CornerSpec(Alignment.topLeft, [true, false, false, true]),
    _CornerSpec(Alignment.topRight, [true, true, false, false]),
    _CornerSpec(Alignment.bottomLeft, [false, false, true, true]),
    _CornerSpec(Alignment.bottomRight, [false, true, true, false]),
  ];
}

class _CornerSpec {
  const _CornerSpec(this.alignment, this.borders);

  final Alignment alignment;
  final List<bool> borders;
}

class _ViewfinderCorner extends StatelessWidget {
  const _ViewfinderCorner({
    required this.alignment,
    required this.borders,
  });

  final Alignment alignment;
  final List<bool> borders;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: borders[0]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            right: borders[1]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            bottom: borders[2]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            left: borders[3]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerIconButton extends StatelessWidget {
  const _ScannerIconButton({
    required this.icon,
    this.onTap,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: iconSize, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _RecentScan {
  const _RecentScan({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;
}
