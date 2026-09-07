import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/localization_service.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../../services/weekly_planner_service.dart';
import '../../sport/sport_start.dart';

/// Le récapitulatif d'une séance cardio ou HIIT prévue.
///
/// Le corps (objectifs, ou les trois chiffres du HIIT) est le widget, pour
/// l'aperçu du chat du planificateur. La feuille est `show`, avec
/// *Commencer* et *Supprimer* quand la date le permet. Même signature
/// qu'avant pour ses appelants ; les libellés en dur ont rejoint le
/// dictionnaire.
class CardioRecapBottomSheet extends StatelessWidget {
  const CardioRecapBottomSheet({
    super.key,
    required this.activity,
    this.onCardioStarted,
    this.onCardioDeleted,
    this.isPreview = false,
  });

  final PlannedActivity activity;
  final VoidCallback? onCardioStarted;
  final VoidCallback? onCardioDeleted;

  /// En aperçu (le chat du planificateur), le corps porte son propre titre.
  final bool isPreview;

  static String _title(PlannedActivity a, String lang) => a.cardioData?.activityName ?? 'sport_kind_cardio'.tr(lang);

  static String _subtitle(PlannedActivity a, String lang) => [
        RyzeDates.full(a.plannedDate, lang),
        if (a.isAiGenerated) 'sport_coach_ryze'.tr(lang),
        if (a.status == PlannedStatus.completed) 'planner_completed'.tr(lang),
      ].join(' · ');

  /// Ouvre la feuille. Rend la main quand elle est fermée.
  static Future<void> show(
    BuildContext context, {
    required PlannedActivity activity,
    VoidCallback? onCardioStarted,
    VoidCallback? onCardioDeleted,
  }) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final completed = activity.status == PlannedStatus.completed;
    final editable = isDateEditable(activity.plannedDate) && !completed;
    final canStart = editable && isToday(activity.plannedDate);

    final action = await showRyzeSheet<_Action>(
      context,
      title: _title(activity, lang),
      subtitle: _subtitle(activity, lang),
      builder: (_) => CardioRecapBottomSheet(activity: activity),
      actions: [
        if (editable)
          Row(
            children: [
              if (onCardioDeleted != null) ...[
                Expanded(
                  flex: canStart ? 1 : 2,
                  child: OnbButton(label: 'planner_delete'.tr(lang), ghost: true, icon: LucideIcons.trash2, onPressed: () => Navigator.pop(context, _Action.delete)),
                ),
                if (canStart) SizedBox(width: context.vw(2.6)),
              ],
              if (canStart)
                Expanded(
                  flex: 2,
                  child: OnbButton(label: 'planner_start_cardio'.tr(lang), onPressed: () => Navigator.pop(context, _Action.start)),
                ),
            ],
          ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _Action.start:
        await SportStart.plannedCardio(context, activity);
        onCardioStarted?.call();
      case _Action.delete:
        final sure = await _confirmDelete(context, lang);
        if (!sure || !context.mounted) return;
        final ok = await WeeklyPlannerService.deleteCardioWithSync(activity.id);
        if (!context.mounted) return;
        if (ok) {
          RyzeFeedback.removed();
          onCardioDeleted?.call();
        } else {
          RyzeUndo.failed(context, message: 'sport_delete_failed'.tr(lang));
        }
    }
  }

  static Future<bool> _confirmDelete(BuildContext context, String lang) async {
    final yes = await showRyzeSheet<bool>(
      context,
      title: 'planner_delete_cardio_title'.tr(lang),
      subtitle: 'planner_delete_cardio_message'.tr(lang),
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
    final data = activity.cardioData;
    final stats = <Widget>[];
    if (data != null && data.isHiit && data.hiitConfig != null) {
      final c = data.hiitConfig!;
      stats.addAll([
        _Stat(value: '${c.workSeconds} s', label: 'planner_hiit_work'.tr(lang)),
        _Stat(value: '${c.restSeconds} s', label: 'planner_hiit_rest'.tr(lang)),
        _Stat(value: '${c.rounds}', label: 'sport_hiit_rounds'.tr(lang)),
        _Stat(value: '${c.totalMinutes}', label: 'minutes'.tr(lang)),
      ]);
    } else if (data != null) {
      if (data.targetMinutes != null && data.targetMinutes! > 0) stats.add(_Stat(value: '${data.targetMinutes}', label: 'minutes'.tr(lang)));
      if (data.targetKm != null && data.targetKm! > 0) stats.add(_Stat(value: data.targetKm!.toStringAsFixed(1), label: 'cardio_km_unit'.tr(lang)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPreview) ...[
          Text(_title(activity, lang), style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
          SizedBox(height: context.vw(0.5)),
          Text(_subtitle(activity, lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
          SizedBox(height: context.vw(3.1)),
        ],
        if (stats.isEmpty)
          Text('sport_objective_free'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute))
        else
          Row(children: [for (final s in stats) Expanded(child: s)]),
      ],
    );
  }
}

enum _Action { start, delete }

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
