import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/sport_models.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/localization_service.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../../services/weekly_planner_service.dart';
import '../../sport/sport_start.dart';

/// Le récapitulatif d'une séance de musculation prévue.
///
/// Le corps (exercices, séries) est le widget, pour que le chat du
/// planificateur puisse l'afficher en aperçu. La feuille est `show` :
/// `showRyzeSheet`, avec *Commencer* et *Supprimer* en actions quand la
/// date le permet. Même signature qu'avant pour ses appelants.
class WorkoutRecapBottomSheet extends StatelessWidget {
  const WorkoutRecapBottomSheet({
    super.key,
    required this.workout,
    this.onWorkoutStarted,
    this.onWorkoutDeleted,
    this.isPreview = false,
  });

  final PlannedWorkout workout;
  final VoidCallback? onWorkoutStarted;
  final VoidCallback? onWorkoutDeleted;

  /// En aperçu (le chat du planificateur), le corps porte son propre titre.
  final bool isPreview;

  static String _subtitle(PlannedWorkout w, String lang) => [
        RyzeDates.full(w.plannedDate, lang),
        if (w.isAiGenerated) 'sport_coach_ryze'.tr(lang),
        if (w.status == PlannedStatus.completed) 'planner_completed'.tr(lang),
      ].join(' · ');

  /// Ouvre la feuille. Rend la main quand elle est fermée.
  static Future<void> show(
    BuildContext context, {
    required PlannedWorkout workout,
    VoidCallback? onWorkoutStarted,
    VoidCallback? onWorkoutDeleted,
  }) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final completed = workout.status == PlannedStatus.completed;
    final editable = isDateEditable(workout.plannedDate) && !completed;
    final canStart = editable && isToday(workout.plannedDate);

    final action = await showRyzeSheet<_Action>(
      context,
      title: workout.workoutName,
      subtitle: _subtitle(workout, lang),
      builder: (_) => WorkoutRecapBottomSheet(workout: workout),
      actions: [
        if (editable)
          Row(
            children: [
              if (onWorkoutDeleted != null) ...[
                Expanded(
                  flex: canStart ? 1 : 2,
                  child: OnbButton(label: 'planner_delete'.tr(lang), ghost: true, icon: LucideIcons.trash2, onPressed: () => Navigator.pop(context, _Action.delete)),
                ),
                if (canStart) SizedBox(width: context.vw(2.6)),
              ],
              if (canStart)
                Expanded(
                  flex: 2,
                  child: OnbButton(label: 'planner_start_workout'.tr(lang), onPressed: () => Navigator.pop(context, _Action.start)),
                ),
            ],
          ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _Action.start:
        await SportStart.plannedWorkout(context, workout);
        onWorkoutStarted?.call();
      case _Action.delete:
        final sure = await _confirmDelete(context, lang);
        if (!sure || !context.mounted) return;
        final ok = await WeeklyPlannerService.deleteWorkoutWithSync(workout.id);
        if (!context.mounted) return;
        if (ok) {
          RyzeFeedback.removed();
          onWorkoutDeleted?.call();
        } else {
          RyzeUndo.failed(context, message: 'sport_delete_failed'.tr(lang));
        }
    }
  }

  static Future<bool> _confirmDelete(BuildContext context, String lang) async {
    final yes = await showRyzeSheet<bool>(
      context,
      title: 'planner_delete_workout_title'.tr(lang),
      subtitle: 'planner_delete_workout_message'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.trash2, label: 'planner_delete'.tr(lang), danger: true, onTap: () => Navigator.pop(sheet, true)),
          RyzeSheetRow(icon: LucideIcons.x, label: 'planner_cancel'.tr(lang), onTap: () => Navigator.pop(sheet, false)),
        ],
      ),
    );
    return yes ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final w = workout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPreview) ...[
          Text(w.workoutName, style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
          SizedBox(height: context.vw(0.5)),
          Text(_subtitle(w, lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
          SizedBox(height: context.vw(3.1)),
        ],
        Row(
          children: [
            if (w.durationMinutes != null && w.durationMinutes! > 0) Expanded(child: _Stat(value: '${w.durationMinutes}', label: 'minutes'.tr(lang))),
            Expanded(child: _Stat(value: '${w.exercises.length}', label: 'planner_exercises'.tr(lang))),
            Expanded(child: _Stat(value: '${w.totalSets}', label: 'planner_sets'.tr(lang))),
          ],
        ),
        SizedBox(height: context.vw(3.6)),
        Container(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < w.exercises.length; i++) _ExerciseLine(lang: lang, e: w.exercises[i], first: i == 0),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Action { start, delete }

class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.lang, required this.e, required this.first});

  final String lang;
  final WorkoutExercise e;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final min = e.suggestedRepsMin, max = e.suggestedRepsMax;
    final sets = (min != null && max != null)
        ? 'sport_sets_reps'.tr(lang).replaceAll('{sets}', '${e.sets.length}').replaceAll('{min}', '$min').replaceAll('{max}', '$max')
        : 'sport_sets_only'.tr(lang).replaceAll('{sets}', '${e.sets.length}');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
      decoration: BoxDecoration(border: first ? null : const Border(top: BorderSide(color: RyzeColors.line))),
      child: Row(
        children: [
          Icon(LucideIcons.dumbbell, size: context.vw(4.1), color: RyzeColors.mute),
          SizedBox(width: context.vw(2.6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                if (e.exercise.muscleGroup.isNotEmpty) Text(e.exercise.muscleGroup, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
              ],
            ),
          ),
          Text(sets, style: RyzeText.body(context, 3.4, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: RyzeText.display(context, 6.7, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        SizedBox(height: context.vw(0.5)),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
      ],
    );
  }
}
