import 'package:flutter/material.dart';
import 'package:peakform_ai/data/day_templates.dart';
import 'package:peakform_ai/data/exercise_content.dart';
import 'package:peakform_ai/data/exercise_catalog.dart';
import 'package:peakform_ai/models/training_exercise.dart';
import 'package:peakform_ai/models/training_session.dart';
import 'package:peakform_ai/services/training_plan_service.dart';
import 'package:peakform_ai/services/training_session_override_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/change_focus_sheet.dart';

Future<void> showCustomizeWorkoutSheet(
  BuildContext context, {
  required TrainingSession session,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CustomizeWorkoutSheet(session: session),
  );
}

class CustomizeWorkoutSheet extends StatefulWidget {
  const CustomizeWorkoutSheet({super.key, required this.session});

  final TrainingSession session;

  @override
  State<CustomizeWorkoutSheet> createState() => _CustomizeWorkoutSheetState();
}

class _CustomizeWorkoutSheetState extends State<CustomizeWorkoutSheet> {
  late List<String> _exerciseIds;
  late List<String> _routineIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _exerciseIds = widget.session.exercises
        .map((exercise) => exercise.exercise.id)
        .toList();
    _routineIds = widget.session.routines
        .map((routine) => routine.exercise.id)
        .toList();
  }

  Set<String> get _usedIds => {..._exerciseIds, ..._routineIds};

  Future<void> _persist() async {
    setState(() => _saving = true);
    await TrainingSessionOverrideService.instance.saveCustomLists(
      date: DateTime.now(),
      exerciseIds: _exerciseIds,
      routineIds: _routineIds,
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _shuffle() async {
    await TrainingSessionOverrideService.instance.incrementRotation(DateTime.now());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await TrainingSessionOverrideService.instance.reset(DateTime.now());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _swapExercise(int index) async {
    final picked = await _pickExercise(
      title: 'Replace exercise',
      options: TrainingPlanService.instance.alternativesFor(
        focus: widget.session.focus,
        excludeIds: _usedIds,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _exerciseIds[index] = picked.id);
    await _persist();
  }

  Future<void> _addExercise() async {
    final picked = await _pickExercise(
      title: 'Add exercise',
      options: TrainingPlanService.instance.alternativesFor(
        focus: widget.session.focus,
        excludeIds: _usedIds,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _exerciseIds.add(picked.id));
    await _persist();
  }

  Future<void> _removeExercise(int index) async {
    setState(() => _exerciseIds.removeAt(index));
    await _persist();
  }

  Future<void> _swapRoutine(int index) async {
    final picked = await _pickExercise(
      title: 'Replace routine',
      options: TrainingPlanService.instance.routineAlternatives(
        excludeIds: _usedIds,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _routineIds[index] = picked.id);
    await _persist();
  }

  Future<void> _addRoutine() async {
    final picked = await _pickExercise(
      title: 'Add routine',
      options: TrainingPlanService.instance.routineAlternatives(
        excludeIds: _usedIds,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() => _routineIds.add(picked.id));
    await _persist();
  }

  Future<void> _removeRoutine(int index) async {
    setState(() => _routineIds.removeAt(index));
    await _persist();
  }

  Future<TrainingExercise?> _pickExercise({
    required String title,
    required List<TrainingExercise> options,
  }) {
    return showModalBottomSheet<TrainingExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExercisePickerSheet(title: title, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isRestDay = widget.session.isRestDay;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customize Workout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.session.title} · ${focusLabel(widget.session.focus)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _FocusSummaryCard(
                      session: widget.session,
                      onChangeFocus: () async {
                        await showChangeFocusSheet(context, session: widget.session);
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 20),
                    if (!isRestDay) ...[
                      _sectionLabel('Main exercises'),
                      const SizedBox(height: 8),
                      ...List.generate(_exerciseIds.length, (index) {
                        final exercise = exerciseById(_exerciseIds[index]);
                        if (exercise == null) return const SizedBox.shrink();

                        return _EditableRow(
                          name: exercise.name,
                          detail: exercise.prescriptionFor(widget.session.intensity),
                          onSwap: () => _swapExercise(index),
                          onRemove: _exerciseIds.length > 1
                              ? () => _removeExercise(index)
                              : null,
                        );
                      }),
                      _AddRowButton(
                        label: 'Add exercise',
                        onTap: _addExercise,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _sectionLabel(isRestDay ? 'Recovery' : "Today's routine"),
                    const SizedBox(height: 8),
                    ...List.generate(_routineIds.length, (index) {
                      final exercise = exerciseById(_routineIds[index]);
                      if (exercise == null) return const SizedBox.shrink();

                      return _EditableRow(
                        name: exercise.name,
                        detail: exercise.prescriptionFor(widget.session.intensity),
                        onSwap: () => _swapRoutine(index),
                        onRemove: _routineIds.length > 1
                            ? () => _removeRoutine(index)
                            : null,
                      );
                    }),
                    _AddRowButton(
                      label: 'Add routine',
                      onTap: _addRoutine,
                    ),
                    const SizedBox(height: 24),
                    _ActionButton(
                      icon: Icons.shuffle_rounded,
                      label: 'Shuffle to new set',
                      onTap: _shuffle,
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset to AI plan',
                      muted: true,
                      onTap: _reset,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FocusSummaryCard extends StatelessWidget {
  const _FocusSummaryCard({
    required this.session,
    required this.onChangeFocus,
  });

  final TrainingSession session;
  final VoidCallback onChangeFocus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onChangeFocus,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconForFocus(session.focus),
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's focus",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.name,
    required this.detail,
    required this.onSwap,
    this.onRemove,
  });

  final String name;
  final String detail;
  final VoidCallback onSwap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              color: AppColors.accent,
              tooltip: 'Swap',
            ),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: muted ? AppColors.background : AppColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: muted ? AppColors.cardBorder : AppColors.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: muted ? AppColors.textSecondary : AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: muted ? AppColors.textSecondary : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatelessWidget {
  const _ExercisePickerSheet({
    required this.title,
    required this.options,
  });

  final String title;
  final List<TrainingExercise> options;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: options.isEmpty
                  ? const Center(
                      child: Text(
                        'No other exercises available.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final exercise = options[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(exercise),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            focusLabel(exercise.focus),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textTertiary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
