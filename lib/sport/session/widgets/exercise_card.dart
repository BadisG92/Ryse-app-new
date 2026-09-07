import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../../../services/unit_service.dart';
import '../session_controller.dart';
import '../session_models.dart';
import 'set_row.dart';

/// Un exercice de la séance, sur le rail.
///
/// L'ancien écran ne montrait qu'un exercice à la fois, entre deux chevrons.
/// Ici la liste est la navigation : chaque exercice est une carte, l'anneau
/// du rail dit son état (libre, en cours, fait — le sport est un anneau, la
/// nourriture un carré), et une seule carte est ouverte à la fois. Repliée,
/// elle cite sa dernière série faite ; dépliée, elle montre ses séries.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.open,
    required this.lang,
    required this.controller,
    required this.onOpen,
    required this.onMenu,
    required this.onTitle,
  });

  final int index;
  final LiveExercise exercise;
  final bool open;
  final String lang;
  final SessionController controller;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  /// Le nom ouvre la progression de l'exercice : c'est là que l'analyse guide.
  final VoidCallback onTitle;

  @override
  Widget build(BuildContext context) {
    final done = exercise.allDone;
    final last = exercise.lastDone;
    final units = UnitService.instance;

    return Padding(
      padding: EdgeInsets.only(left: context.vw(9.2), bottom: context.vw(2.1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -context.vw(8.2),
            top: context.vw(4.6),
            child: _Ring(done: done, current: open),
          ),
          AnimatedContainer(
            duration: RyzeDurations.fill,
            curve: RyzeCurves.out,
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: open ? RyzeColors.ink : RyzeColors.line, width: open ? 1.4 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Pressable(
                  onTap: open ? null : onOpen,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.1), context.vw(2.6), context.vw(3.1)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Pressable(
                                onTap: onTitle,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        exercise.exercise.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: RyzeText.body(context, 4.1, weight: FontWeight.w600),
                                      ),
                                    ),
                                    SizedBox(width: context.vw(1.5)),
                                    Icon(LucideIcons.trendingUp, size: context.vw(3.6), color: RyzeColors.mute2),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.vw(0.5)),
                              Text(
                                _subtitle(context, last, units),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ],
                          ),
                        ),
                        if (open)
                          Pressable(
                            onTap: onMenu,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(LucideIcons.ellipsis, size: context.vw(4.6), color: RyzeColors.mute),
                            ),
                          )
                        else
                          Icon(LucideIcons.chevronDown, size: context.vw(4.6), color: RyzeColors.mute2),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: RyzeDurations.enter,
                  curve: RyzeCurves.out,
                  alignment: Alignment.topCenter,
                  child: !open
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(context.vw(2.6), 0, context.vw(2.6), context.vw(2.6)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < exercise.sets.length; i++)
                                SetRow(
                                  index: i,
                                  set: exercise.sets[i],
                                  ghost: controller.ghostFor(index, i),
                                  editing: controller.editingSet == i ? controller.editingField : null,
                                  buffer: controller.editingSet == i ? controller.buffer : '',
                                  onTapWeight: () => controller.edit(i, EditField.weight),
                                  onTapReps: () => controller.edit(i, EditField.reps),
                                  onCheck: () => exercise.sets[i].done ? controller.uncompleteSet(i) : controller.completeSet(i),
                                  onLongPress: exercise.sets.length > 1 ? () => controller.removeSet(i) : null,
                                ),
                              Pressable(
                                onTap: controller.addSet,
                                child: Container(
                                  height: context.vw(10.8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                                    border: Border.all(color: RyzeColors.idle),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.ink),
                                      SizedBox(width: context.vw(1.5)),
                                      Text('session_add_set'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context, LiveSet? last, UnitService units) {
    final progress = 'session_sets_progress'.tr(lang).replaceAll('{done}', '${exercise.doneCount}').replaceAll('{total}', '${exercise.sets.length}');
    if (last == null) return progress;
    final w = units.displayWeight(last.weightKg);
    final ws = w.truncateToDouble() == w ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
    return '$progress · $ws ${units.weightUnit} × ${last.reps}';
  }
}

/// L'anneau du rail : gris libre, bord navy en cours, navy plein fait.
class _Ring extends StatelessWidget {
  const _Ring({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: RyzeDurations.fill,
      curve: RyzeCurves.out,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : (current ? RyzeColors.surf : RyzeColors.idle),
        shape: BoxShape.circle,
        border: Border.all(color: done || current ? RyzeColors.ink : RyzeColors.idle, width: current && !done ? 2 : 1),
      ),
      child: done ? const Icon(LucideIcons.check, size: 10, color: RyzeColors.surf) : null,
    );
  }
}
