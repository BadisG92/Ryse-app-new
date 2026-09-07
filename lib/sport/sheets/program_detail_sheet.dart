import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/sport_models.dart';
import '../../services/translations.dart';

/// Un programme, avant de le lancer : ses exercices, séries × reps, et un
/// seul bouton. Rend `true` si l'utilisateur commence.
class ProgramDetailSheet {
  ProgramDetailSheet._();

  static Future<bool> show(BuildContext context, {required String lang, required WorkoutProgram program}) async {
    final start = await showRyzeSheet<bool>(
      context,
      title: program.name,
      subtitle: [
        if (program.type.isNotEmpty) program.type,
        'sport_program_exercises'.tr(lang).replaceAll('{n}', '${program.exercises.length}'),
        if (program.estimatedDuration > 0) 'sport_program_minutes'.tr(lang).replaceAll('{n}', '${program.estimatedDuration}'),
      ].join(' · '),
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (program.description.trim().isNotEmpty) ...[
            Text(program.description, style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
            SizedBox(height: context.vw(3.1)),
          ],
          Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < program.exercises.length; i++) _ExerciseLine(lang: lang, e: program.exercises[i], first: i == 0),
              ],
            ),
          ),
        ],
      ),
      actions: [
        OnbButton(
          label: 'sport_planned_start'.tr(lang),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    return start ?? false;
  }
}

class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.lang, required this.e, required this.first});

  final String lang;
  final ProgramExercise e;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final min = e.suggestedRepsMin, max = e.suggestedRepsMax;
    final String sets;
    if (min != null && max != null) {
      sets = 'sport_sets_reps'.tr(lang).replaceAll('{sets}', '${e.sets}').replaceAll('{min}', '$min').replaceAll('{max}', '$max');
    } else {
      sets = 'sport_sets_only'.tr(lang).replaceAll('{sets}', '${e.sets}');
    }
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
