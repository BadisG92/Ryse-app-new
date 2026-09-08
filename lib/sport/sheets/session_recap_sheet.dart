import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/sport_models.dart';
import '../../screens/workout_edit_screen.dart';
import '../../services/sport_dashboard_service.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../sport_data.dart';
import '../widgets/session_timeline.dart';

/// Ce que la feuille de récap a décidé.
enum RecapAction { none, edited, delete }

/// Le récapitulatif d'une séance passée, sur une feuille.
///
/// Musculation : les exercices et leurs séries, lus dans
/// `workout_set_history`. Cardio : la ligne suffit. Deux actions en bas —
/// *Modifier* (musculation) et *Supprimer* — la suppression est rendue à
/// l'appelant, qui retire la rangée tout de suite et laisse la barre
/// d'annulation décider.
class SessionRecapSheet {
  SessionRecapSheet._();

  static Future<RecapAction> show(BuildContext context, {required String lang, required SportSessionRow row}) async {
    final action = await showRyzeSheet<RecapAction>(
      context,
      title: row.name,
      subtitle: SessionRow.meta(context, lang, row),
      builder: (sheet) => _Body(lang: lang, row: row),
      actions: [
        Row(
          children: [
            if (row.kind == SportKind.strength) ...[
              Expanded(
                child: OnbButton(
                  label: 'sport_edit'.tr(lang),
                  ghost: true,
                  onPressed: () => Navigator.pop(context, RecapAction.edited),
                ),
              ),
              SizedBox(width: context.vw(2.6)),
            ],
            Expanded(
              child: OnbButton(
                label: 'sport_delete'.tr(lang),
                ghost: true,
                icon: LucideIcons.trash2,
                onPressed: () => Navigator.pop(context, RecapAction.delete),
              ),
            ),
          ],
        ),
      ],
    );
    if (action == RecapAction.edited && context.mounted) {
      final ok = await _edit(context, row);
      return ok ? RecapAction.edited : RecapAction.none;
    }
    return action ?? RecapAction.none;
  }

  /// Ouvre l'écran d'édition avec les séries de la séance.
  static Future<bool> _edit(BuildContext context, SportSessionRow row) async {
    Map<String, dynamic> d;
    try {
      d = await SportDashboardService.getMusculationSessionDetails(row.id);
    } catch (_) {
      return false;
    }
    if (!context.mounted) return false;
    final groups = (d['exercises'] as Map?)?.cast<String, dynamic>() ?? const {};
    final exercises = <WorkoutExercise>[
      for (final entry in groups.entries)
        WorkoutExercise(
          exercise: Exercise(id: '', name: entry.key, muscleGroup: ''),
          sets: [
            for (final s in (entry.value as List))
              ExerciseSet(reps: (s['reps'] as num?)?.toInt() ?? 0, weight: (s['weight'] as num?)?.toDouble() ?? 0, isCompleted: true),
          ],
        ),
    ];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutEditScreen(
          sessionId: row.id,
          historySessionId: '${d['history_session_id'] ?? ''}',
          sessionName: row.name,
          exercises: exercises,
          durationMinutes: row.minutes,
          intensity: row.intensity,
          sessionDate: row.dayKey,
        ),
      ),
    );
    return true;
  }
}

/// La suppression différée : la rangée disparaît tout de suite, la barre
/// propose d'annuler, et la ligne n'est vraiment supprimée qu'après.
class SessionDeletion {
  SessionDeletion._();

  static void schedule(
    BuildContext context, {
    required String lang,
    required SportSessionRow row,
    required VoidCallback onRestore,
    required VoidCallback onDeleted,
  }) {
    var undone = false;
    RyzeFeedback.removed();
    RyzeUndo.show(
      context,
      message: 'sport_session_deleted'.tr(lang),
      undoLabel: 'undo'.tr(lang),
      onUndo: () {
        undone = true;
        onRestore();
      },
    );
    Timer(RyzeUndo.life + const Duration(milliseconds: 400), () async {
      if (undone) return;
      try {
        await SportData.delete(row);
        onDeleted();
      } catch (_) {
        onRestore();
        if (context.mounted) RyzeUndo.failed(context, message: 'sport_delete_failed'.tr(lang));
      }
    });
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.row});

  final String lang;
  final SportSessionRow row;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.row.kind == SportKind.strength) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    try {
      final d = await SportDashboardService.getMusculationSessionDetails(widget.row.id);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final row = widget.row;
    final units = UnitService.instance;

    if (row.kind == SportKind.cardio) {
      return Row(
        children: [
          Expanded(child: _Stat(value: '${row.minutes}', label: 'minutes'.tr(lang))),
          if (row.distanceKm != null && row.distanceKm! > 0)
            Expanded(child: _Stat(value: units.displayDistance(row.distanceKm!).toStringAsFixed(1), label: units.distanceUnit)),
          Expanded(child: _Stat(value: '${row.kcal}', label: 'nutri_kcal'.tr(lang), amber: true)),
        ],
      );
    }

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(8)),
        child: Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
      );
    }
    final groups = (_detail?['exercises'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (groups.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(6)),
        child: Center(child: Text('sport_recap_no_detail'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute))),
      );
    }
    var totalSets = 0;
    var volume = 0.0;
    for (final sets in groups.values) {
      for (final s in (sets as List)) {
        totalSets++;
        volume += ((s['weight'] as num?)?.toDouble() ?? 0) * ((s['reps'] as num?)?.toDouble() ?? 0);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _Stat(value: '$totalSets', label: 'session_sets_done'.tr(lang))),
            Expanded(child: _Stat(value: units.displayWeight(volume).round().toString(), label: '${'session_volume'.tr(lang)} · ${units.weightUnit}')),
            Expanded(child: _Stat(value: '${row.kcal}', label: 'nutri_kcal'.tr(lang), amber: true)),
          ],
        ),
        SizedBox(height: context.vw(4.1)),
        Text('sport_recap_exercises'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Container(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Column(
            children: [
              for (final (i, entry) in groups.entries.indexed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
                  decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: RyzeColors.line))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                      SizedBox(height: context.vw(1)),
                      Wrap(
                        spacing: context.vw(2.1),
                        runSpacing: context.vw(1),
                        children: [
                          for (final s in (entry.value as List))
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(0.8)),
                              decoration: BoxDecoration(
                                color: RyzeColors.ink,
                                borderRadius: BorderRadius.circular(RyzeRadius.pill),
                              ),
                              child: Text(
                                '${_w(units.displayWeight((s['weight'] as num?)?.toDouble() ?? 0))} ${units.weightUnit} × ${(s['reps'] as num?)?.toInt() ?? 0}',
                                style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.surf).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _w(double v) => v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.amber = false});

  final String value;
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: RyzeText.display(context, 7.2, weight: FontWeight.w600).copyWith(
            color: amber ? RyzeColors.accInk : RyzeColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
      ],
    );
  }
}
