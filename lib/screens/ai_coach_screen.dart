import 'package:flutter/material.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/progress_ring.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({
    super.key,
    this.onBack,
    this.onNavTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  static const _athleteUrl =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&q=80';

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
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildFeaturedBadge(),
                    _buildTopBar(context),
                    const SizedBox(height: 8),
                    _buildCameraFeed(),
                    _buildMetrics(),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 2,
              onTap: onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'FEATURED AI',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.green,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _IconBoxButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 32,
            iconSize: 16,
            onTap: onBack ?? () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'AI TRAINING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'REC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _athleteUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.card),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              const CustomPaint(painter: _PoseSkeletonPainter()),
              Positioned(
                top: 12,
                left: 12,
                child: _feedBadge('17 KEYPOINTS'),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _feedBadge('98% CONFIDENCE', color: AppColors.green),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.45),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.yellow,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'AI COACH: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: 'Keep your left knee outward.'),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _feedStat('Stability', '95%'),
                    _feedStat('Rep Count', '5 / 12'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedBadge(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _feedStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressRing(
            progress: 0.92,
            size: 100,
            strokeWidth: 8,
            color: AppColors.green,
            center: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '92',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'EXCELLENT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JOINT ANGLES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _jointCard('Left Knee', '78°', isWarning: true),
                const SizedBox(height: 8),
                _jointCard('Right Knee', '92°', isWarning: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jointCard(String name, String angle, {required bool isWarning}) {
    final color = isWarning ? AppColors.yellow : AppColors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isWarning ? 0.3 : 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            angle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseSkeletonPainter extends CustomPainter {
  const _PoseSkeletonPainter();

  static const _viewWidth = 300.0;
  static const _viewHeight = 400.0;

  static const _lines = [
    (150.0, 95.0, 150.0, 185.0),
    (115.0, 105.0, 185.0, 105.0),
    (115.0, 105.0, 95.0, 155.0),
    (95.0, 155.0, 88.0, 200.0),
    (185.0, 105.0, 205.0, 155.0),
    (205.0, 155.0, 212.0, 200.0),
    (135.0, 185.0, 120.0, 260.0),
    (120.0, 260.0, 110.0, 340.0),
    (165.0, 185.0, 180.0, 260.0),
    (180.0, 260.0, 190.0, 340.0),
  ];

  static const _joints = [
    (150.0, 95.0, 5.0, false),
    (115.0, 105.0, 4.0, false),
    (185.0, 105.0, 4.0, false),
    (95.0, 155.0, 3.5, false),
    (205.0, 155.0, 3.5, false),
    (150.0, 185.0, 4.5, false),
    (120.0, 260.0, 6.0, true),
    (180.0, 260.0, 5.0, false),
    (110.0, 340.0, 4.0, false),
    (190.0, 340.0, 4.0, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _viewWidth;
    final scaleY = size.height / _viewHeight;

    Offset point(double x, double y) => Offset(x * scaleX, y * scaleY);

    final linePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (final line in _lines) {
      canvas.drawLine(
        point(line.$1, line.$2),
        point(line.$3, line.$4),
        linePaint,
      );
    }

    for (final joint in _joints) {
      final color = joint.$4 ? AppColors.yellow : AppColors.green;
      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          joint.$4 ? 4 : 3,
        );
      canvas.drawCircle(
        point(joint.$1, joint.$2),
        joint.$3 * ((scaleX + scaleY) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
