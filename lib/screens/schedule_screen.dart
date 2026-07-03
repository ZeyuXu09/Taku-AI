import 'package:flutter/material.dart';
import 'package:peakform_ai/models/scheduled_game.dart';
import 'package:peakform_ai/services/game_schedule_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/utils/game_format.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _visibleMonth;
  late int _selectedDay;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = now.day;
    _selectedDate = DateTime(now.year, now.month, now.day);
    GameScheduleService.instance.loadGames();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
              child: ValueListenableBuilder<List<ScheduledGame>>(
                valueListenable: GameScheduleService.instance.games,
                builder: (context, _, __) {
                  final gameDays =
                      GameScheduleService.instance.gameDaysInMonth(_visibleMonth);
                  final selectedDayGames =
                      GameScheduleService.instance.gamesOnDay(_selectedDate);
                  final listGames = _isSameDay(_selectedDate, _today)
                      ? GameScheduleService.instance.upcomingGames()
                      : selectedDayGames;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildCalendarCard(gameDays),
                        const SizedBox(height: 24),
                        _sectionTitle(
                          _isSameDay(_selectedDate, _today)
                              ? 'Upcoming Games'
                              : 'Games on ${_monthName(_selectedDate.month)} ${_selectedDate.day}',
                        ),
                        const SizedBox(height: 12),
                        if (listGames.isEmpty)
                          _buildEmptyState()
                        else
                          ...listGames.map(_buildGameItem),
                        const SizedBox(height: 24),
                        _sectionTitle("This Week's Plan"),
                        const SizedBox(height: 12),
                        _buildPlanRow(),
                      ],
                    ),
                  );
                },
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
        _IconBoxButton(
          icon: Icons.add_rounded,
          onTap: _showAddGameSheet,
        ),
      ],
    );
  }

  Widget _buildCalendarCard(Set<int> gameDays) {
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
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final isToday = _isSameDay(date, _today);
              final isSelected = _isSameDay(date, _selectedDate);
              final isGameDay = gameDays.contains(day);

              return _DayCell(
                day: day,
                isToday: isToday,
                isSelected: isSelected,
                isGameDay: isGameDay,
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _selectedDate = date;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            Icons.event_busy_rounded,
            size: 36,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'No games scheduled',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first game',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showAddGameSheet,
            icon: const Icon(Icons.add_rounded, color: AppColors.accent),
            label: const Text(
              'Add Game',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGameSheet() => _showGameFormSheet();

  Future<void> _showEditGameSheet(ScheduledGame game) =>
      _showGameFormSheet(existing: game);

  Future<void> _showGameFormSheet({ScheduledGame? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GameFormSheet(
        initialDate: existing?.gameAt ?? _selectedDate,
        existing: existing,
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Game added' : 'Game updated'),
        ),
      );
    }
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      _syncSelectedDayForVisibleMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      _syncSelectedDayForVisibleMonth();
    });
  }

  void _syncSelectedDayForVisibleMonth() {
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final day = _selectedDay.clamp(1, daysInMonth);
    _selectedDay = day;
    _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, day);
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

  Widget _buildGameItem(ScheduledGame game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: InkWell(
          onTap: () => _showEditGameSheet(game),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                      colors: game.opponentGradient,
                    ),
                  ),
                  child: Text(
                    game.opponentLetter,
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
                        'vs ${game.opponentName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        GameFormat.metaLine(game.gameAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      color: game.isHome
                          ? AppColors.accentLight
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditGameSheet(game),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.navInactive,
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteGame(game),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.navInactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGame(ScheduledGame game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Delete game?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove vs ${game.opponentName} on ${GameFormat.metaLine(game.gameAt)}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GameScheduleService.instance.deleteGame(game.id);
    }
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

class _GameFormSheet extends StatefulWidget {
  const _GameFormSheet({
    required this.initialDate,
    this.existing,
  });

  final DateTime initialDate;
  final ScheduledGame? existing;

  @override
  State<_GameFormSheet> createState() => _GameFormSheetState();
}

class _GameFormSheetState extends State<_GameFormSheet> {
  final _opponentController = TextEditingController();
  late DateTime _gameDate;
  late TimeOfDay _gameTime;
  late bool _isHome;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _opponentController.text = existing.opponentName;
      _gameDate = DateTime(
        existing.gameAt.year,
        existing.gameAt.month,
        existing.gameAt.day,
      );
      _gameTime = TimeOfDay.fromDateTime(existing.gameAt);
      _isHome = existing.isHome;
    } else {
      _gameDate = widget.initialDate;
      _gameTime = const TimeOfDay(hour: 19, minute: 0);
      _isHome = true;
    }
  }

  @override
  void dispose() {
    _opponentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _gameDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _gameDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _gameTime,
    );
    if (picked != null) {
      setState(() => _gameTime = picked);
    }
  }

  Future<void> _saveGame() async {
    final opponent = _opponentController.text.trim();
    if (opponent.isEmpty) {
      setState(() => _errorMessage = 'Enter an opponent name');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final gameAt = DateTime(
      _gameDate.year,
      _gameDate.month,
      _gameDate.day,
      _gameTime.hour,
      _gameTime.minute,
    );

    try {
      if (_isEditing) {
        await GameScheduleService.instance.updateGame(
          id: widget.existing!.id,
          opponentName: opponent,
          gameAt: gameAt,
          isHome: _isHome,
        );
      } else {
        await GameScheduleService.instance.addGame(
          opponentName: opponent,
          gameAt: gameAt,
          isHome: _isHome,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = GameScheduleService.friendlyError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.navInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'Edit Game' : 'Add Game',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _opponentController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Opponent',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.barTrack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    '${_gameDate.month}/${_gameDate.day}/${_gameDate.year}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: Text(_gameTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Home'),
                  selected: _isHome,
                  onSelected: (selected) {
                    if (selected) setState(() => _isHome = true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Away'),
                  selected: !_isHome,
                  onSelected: (selected) {
                    if (selected) setState(() => _isHome = false);
                  },
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFF764BA2)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : _saveGame,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Update Game' : 'Save Game',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isGameDay,
    required this.onTap,
  });

  final int day;
  final bool isToday;
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
                )
              else if (isToday)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green, width: 2),
                  ),
                ),
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected || isToday || isGameDay
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : isToday
                          ? AppColors.green
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
