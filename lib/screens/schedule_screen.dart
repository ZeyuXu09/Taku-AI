import 'package:flutter/material.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _gameDays = {20, 23, 25};

  DateTime _visibleMonth = DateTime(2025, 2);
  int _selectedDay = 18;

  static const _games = [
    _Game(
      letter: 'P',
      opponent: 'vs Panthers',
      meta: 'Feb 20 · 7:00 PM',
      isHome: false,
      gradient: [Color(0xFFF97316), Color(0xFFFB923C)],
    ),
    _Game(
      letter: 'W',
      opponent: 'vs Wolves',
      meta: 'Feb 23 · 6:30 PM',
      isHome: true,
      gradient: [Color(0xFF6366F1), Color(0xFF818CF8)],
    ),
    _Game(
      letter: 'H',
      opponent: 'vs Hawks',
      meta: 'Feb 25 · 5:15 PM',
      isHome: false,
      gradient: [Color(0xFFEF4444), Color(0xFFF87171)],
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
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildCalendarCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('Upcoming Games'),
                    const SizedBox(height: 12),
                    ..._games.map(_buildGameItem),
                    const SizedBox(height: 24),
                    _sectionTitle("This Week's Plan"),
                    const SizedBox(height: 12),
                    _buildPlanRow(),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 1,
              onTap: widget.onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Game Schedule',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        Row(
          children: [
            _IconBoxButton(icon: Icons.search_rounded, onTap: () {}),
            const SizedBox(width: 8),
            _IconBoxButton(icon: Icons.notifications_none_rounded, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final monthLabel =
        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _CalendarNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _previousMonth,
                  ),
                  const SizedBox(width: 6),
                  _CalendarNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navInactive,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                return const SizedBox.shrink();
              }

              final day = index - leadingEmpty + 1;
              final isSelected = _visibleMonth.year == 2025 &&
                  _visibleMonth.month == 2 &&
                  day == _selectedDay;
              final isGameDay = _visibleMonth.year == 2025 &&
                  _visibleMonth.month == 2 &&
                  _gameDays.contains(day);

              return _DayCell(
                day: day,
                isSelected: isSelected,
                isGameDay: isGameDay,
                onTap: () => setState(() => _selectedDay = day),
              );
            },
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
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

  Widget _buildGameItem(_Game game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: game.gradient,
                ),
              ),
              child: Text(
                game.letter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.opponent,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    game.meta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: game.isHome
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                game.isHome ? 'Home' : 'Away',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: game.isHome ? AppColors.accentLight : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRow() {
    return Row(
      children: [
        Expanded(
          child: _PlanCard(
            label: 'Game Day Prep',
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.accent,
            iconBackground: AppColors.accent.withValues(alpha: 0.3),
            gradient: [
              AppColors.accent.withValues(alpha: 0.25),
              AppColors.accent.withValues(alpha: 0.08),
            ],
            borderColor: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            label: 'Recovery',
            icon: Icons.spa_outlined,
            iconColor: AppColors.green,
            iconBackground: AppColors.green.withValues(alpha: 0.2),
            gradient: [
              AppColors.green.withValues(alpha: 0.2),
              AppColors.green.withValues(alpha: 0.06),
            ],
            borderColor: AppColors.green.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            label: 'Strength',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF97316),
            iconBackground: const Color(0xFFF97316).withValues(alpha: 0.3),
            gradient: [
              const Color(0xFFF97316).withValues(alpha: 0.25),
              const Color(0xFFF97316).withValues(alpha: 0.08),
            ],
            borderColor: const Color(0xFFF97316).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isGameDay,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isGameDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected || isGameDay
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : isGameDay
                          ? AppColors.textTertiary
                          : AppColors.textSecondary,
                ),
              ),
              if (isGameDay)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.barTrack,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.gradient,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final List<Color> gradient;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Game {
  const _Game({
    required this.letter,
    required this.opponent,
    required this.meta,
    required this.isHome,
    required this.gradient,
  });

  final String letter;
  final String opponent;
  final String meta;
  final bool isHome;
  final List<Color> gradient;
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
