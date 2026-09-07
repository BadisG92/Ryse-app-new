import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../session_models.dart';

/// Ce que le ⋯ d'un exercice peut faire.
enum ExerciseMenuChoice { progression, info, replace, remove }

/// Le menu d'un exercice en séance.
///
/// Quatre rangées et un réglage : *Progression* (la page de détail, avec sa
/// courbe et l'analyse Coach Ryze), *Comment faire*, *Remplacer*,
/// *Supprimer* — et le repos par défaut, en trois pas, qui s'applique tout de
/// suite sans fermer la feuille.
class ExerciseMenuSheet {
  ExerciseMenuSheet._();

  static const List<int> restChoices = [60, 90, 120];

  static Future<ExerciseMenuChoice?> show(
    BuildContext context, {
    required String lang,
    required LiveExercise exercise,
    required int restSeconds,
    required ValueChanged<int> onRestChanged,
  }) {
    return showRyzeSheet<ExerciseMenuChoice>(
      context,
      title: exercise.exercise.name,
      subtitle: exercise.exercise.muscleGroup.isEmpty ? null : exercise.exercise.muscleGroup,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RyzeSheetGroup(
            children: [
              RyzeSheetRow(
                first: true,
                icon: LucideIcons.trendingUp,
                label: 'session_progression'.tr(lang),
                onTap: () => Navigator.pop(sheet, ExerciseMenuChoice.progression),
              ),
              RyzeSheetRow(
                icon: LucideIcons.info,
                label: 'session_info'.tr(lang),
                onTap: () => Navigator.pop(sheet, ExerciseMenuChoice.info),
              ),
              RyzeSheetRow(
                icon: LucideIcons.repeat,
                label: 'session_replace'.tr(lang),
                onTap: () => Navigator.pop(sheet, ExerciseMenuChoice.replace),
              ),
              RyzeSheetRow(
                icon: LucideIcons.trash2,
                label: 'session_remove'.tr(lang),
                danger: true,
                onTap: () => Navigator.pop(sheet, ExerciseMenuChoice.remove),
              ),
            ],
          ),
          SizedBox(height: context.vw(4.1)),
          Text('session_default_rest'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
          SizedBox(height: context.vw(2.1)),
          _RestPicker(initial: restSeconds, onChanged: onRestChanged),
        ],
      ),
    );
  }
}

class _RestPicker extends StatefulWidget {
  const _RestPicker({required this.initial, required this.onChanged});

  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_RestPicker> createState() => _RestPickerState();
}

class _RestPickerState extends State<_RestPicker> {
  late int _index = ExerciseMenuSheet.restChoices.indexOf(widget.initial).clamp(0, ExerciseMenuSheet.restChoices.length - 1);

  @override
  Widget build(BuildContext context) {
    return RyzeSegmented(
      labels: [for (final s in ExerciseMenuSheet.restChoices) '$s s'],
      index: _index,
      onChanged: (i) {
        setState(() => _index = i);
        widget.onChanged(ExerciseMenuSheet.restChoices[i]);
      },
    );
  }
}
