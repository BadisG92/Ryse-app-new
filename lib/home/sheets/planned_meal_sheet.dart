import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/translations.dart';
import '../../services/weekly_planner_service.dart';

/// Un repas prévu, tel que le planificateur l'a écrit : le plat, ce qu'il y a
/// dedans, ses macros, et de quoi le retirer.
///
/// La séance et le cardio avaient chacun leur feuille depuis la refonte du
/// sport ; le repas n'en avait aucune. Le seul endroit où voir ce que Ryze
/// avait prévu pour jeudi soir était la conversation du planificateur, où il
/// faut d'abord déplier la semaine. C'est la porte qui manquait.
class PlannedMealSheet {
  PlannedMealSheet._();

  /// Rend vrai quand le repas a été supprimé, pour que l'appelant recharge.
  static Future<bool> show(BuildContext context, {required PlannedActivity meal, required String lang}) async {
    final data = meal.mealData;
    final title = (data?.dishName?.isNotEmpty ?? false) ? data!.dishName! : 'meal_name_${meal.activityType.value}'.tr(lang);
    final done = meal.status == PlannedStatus.completed;

    final remove = await showRyzeSheet<bool>(
      context,
      title: title,
      subtitle: 'slot_${meal.activityType.value}'.tr(lang),
      builder: (_) => _Body(lang: lang, data: data, done: done),
      actions: [
        // Un repas déjà validé n'est plus du planifié : il est dans le
        // journal, et c'est là qu'on le retire.
        if (!done)
          OnbButton(
            label: 'planner_delete_meal'.tr(lang),
            ghost: true,
            icon: LucideIcons.trash2,
            onPressed: () => Navigator.pop(context, true),
          ),
      ],
    );
    if (remove != true || !context.mounted) return false;

    final ok = await WeeklyPlannerService.deletePlannedActivity(meal.id);
    if (!context.mounted) return ok;
    if (ok) {
      RyzeFeedback.removed();
    } else {
      RyzeUndo.failed(context, message: 'error_generic'.tr(lang));
    }
    return ok;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lang, required this.data, required this.done});

  final String lang;
  final PlannedMealData? data;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final description = data?.dishDescription?.trim() ?? '';
    final reasoning = data?.aiReasoning?.trim() ?? '';
    final kcal = data?.calories ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (done) ...[
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(1.2)),
                decoration: BoxDecoration(color: RyzeColors.ink, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                child: Text(
                  'planner_completed'.tr(lang),
                  style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.surf),
                ),
              ),
            ],
          ),
          SizedBox(height: context.vw(4.1)),
        ],
        if (kcal > 0) ...[
          Row(
            children: [
              Expanded(child: _Stat(value: '$kcal', label: 'nutri_kcal'.tr(lang))),
              Expanded(child: _Stat(value: '${(data?.proteins ?? 0).round()} g', label: 'proteins'.tr(lang))),
              Expanded(child: _Stat(value: '${(data?.carbs ?? 0).round()} g', label: 'carbohydrates'.tr(lang))),
              Expanded(child: _Stat(value: '${(data?.fats ?? 0).round()} g', label: 'fats'.tr(lang))),
            ],
          ),
          SizedBox(height: context.vw(4.6)),
        ],
        if (description.isNotEmpty)
          RecipeView(lang: lang, recipe: RecipeText.parse(description)),
        // Le raisonnement vient de Ryze : il porte sa marque, comme partout
        // ailleurs où c'est lui qui parle.
        if (reasoning.isNotEmpty) ...[
          SizedBox(height: context.vw(4.6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: context.vw(0.8), right: context.vw(2.6)),
                child: RyzeMark(size: context.vw(4.1), color: RyzeColors.accInk),
              ),
              Expanded(
                child: Text(reasoning, style: RyzeText.body(context, 3.2, color: RyzeColors.mute, height: 1.45)),
              ),
            ],
          ),
        ],
      ],
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
        Text(
          value,
          maxLines: 1,
          style: RyzeText.display(context, 5.1, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RyzeText.body(context, 2.6, color: RyzeColors.mute),
        ),
      ],
    );
  }
}
