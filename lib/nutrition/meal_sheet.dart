import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../models/weekly_planner_models.dart';
import '../services/day_meals.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';

/// Un repas, ouvert : ce qui a été mangé, ce qui était prévu, et le compte.
///
/// Voir le détail d'un repas n'était possible qu'à un seul endroit — la
/// journée de l'onglet Nutrition, en dépliant la rangée. Depuis l'accueil, un
/// créneau déjà noté renvoyait vers l'onglet Nutrition, ce qui est un saut, pas
/// une réponse ; une ligne du jour déplié n'était même pas cliquable. Et un
/// repas *prévu* ne s'ouvrait nulle part dans le journal : le tap y proposait
/// d'ajouter un aliment, sans jamais montrer le plat que Ryze avait prévu.
///
/// Une seule feuille pour les trois portes. Elle lit la journée demandée —
/// donc elle marche pour hier comme pour aujourd'hui — et n'invente rien : ce
/// qu'elle n'a pas, elle ne l'affiche pas.
class MealSheet {
  MealSheet._();

  /// Ouvre le repas [slot] du jour [day]. Rend vrai quand quelque chose a
  /// changé et que l'appelant doit se recharger.
  static Future<bool> show(
    BuildContext context, {
    required DateTime day,
    required WeekSlot slot,
    PlannedActivity? planned,
    VoidCallback? onAdd,
  }) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final meals = await DayMeals.forDate(day);
    if (!context.mounted) return false;

    final meal = meals[slot];
    final label = 'slot_${slot.name}'.tr(lang);
    final data = planned?.mealData;
    final dish = (data?.dishName?.isNotEmpty ?? false) ? data!.dishName! : meal.plannedName;

    final changed = await showRyzeSheet<bool>(
      context,
      title: label,
      subtitle: RyzeDates.full(day, lang),
      builder: (_) => _Body(lang: lang, meal: meal, dish: dish, data: data),
      actions: [
        if (onAdd != null)
          OnbButton(
            label: 'add_food'.tr(lang),
            ghost: true,
            icon: LucideIcons.plus,
            onPressed: () => Navigator.pop(context, true),
          ),
      ],
    );

    if (changed == true && onAdd != null) onAdd();
    return changed == true;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lang, required this.meal, required this.dish, required this.data});

  final String lang;
  final DayMeal meal;

  /// Le plat prévu, quel que soit l'endroit d'où il vient.
  final String? dish;
  final PlannedMealData? data;

  @override
  Widget build(BuildContext context) {
    final items = meal.logged?.items ?? const <nutrition.FoodItem>[];
    final eaten = items.isNotEmpty;

    // Ce qui est prévu ne sert de compte que tant que rien n'a été mangé :
    // après, c'est le journal qui fait foi.
    final kcal = eaten ? meal.calories : (data?.calories ?? 0);
    final proteins = eaten ? meal.proteins : (data?.proteins ?? 0);
    final carbs = eaten ? meal.carbs : (data?.carbs ?? 0);
    final fats = eaten ? meal.fats : (data?.fats ?? 0);

    final description = data?.dishDescription?.trim() ?? '';
    final reasoning = data?.aiReasoning?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!eaten && (dish?.isNotEmpty ?? false)) ...[
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(1.2)),
                decoration: BoxDecoration(color: RyzeColors.paper2, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                child: Text(
                  'planner_planned'.tr(lang),
                  style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.mute),
                ),
              ),
            ],
          ),
          SizedBox(height: context.vw(2.6)),
          Text(dish!, style: RyzeText.body(context, 4.6, weight: FontWeight.w600)),
          SizedBox(height: context.vw(3.6)),
        ],

        if (kcal > 0) ...[
          Row(
            children: [
              Expanded(child: _Stat(value: '$kcal', label: 'nutri_kcal'.tr(lang))),
              Expanded(child: _Stat(value: '${proteins.round()} g', label: 'proteins'.tr(lang))),
              Expanded(child: _Stat(value: '${carbs.round()} g', label: 'carbohydrates'.tr(lang))),
              Expanded(child: _Stat(value: '${fats.round()} g', label: 'fats'.tr(lang))),
            ],
          ),
          SizedBox(height: context.vw(4.6)),
        ],

        // Ce qui a vraiment été mangé, aliment par aliment. C'est la raison
        // d'être de cette feuille.
        if (eaten)
          for (final item in items) _Item(lang: lang, item: item),

        if (!eaten && (dish?.isEmpty ?? true))
          Text('nutri_nothing_logged'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),

        if (description.isNotEmpty) ...[
          SizedBox(height: context.vw(3.6)),
          Text(description, style: RyzeText.body(context, 3.6, height: 1.5)),
        ],

        // Le raisonnement vient de Ryze : il porte sa marque, comme partout
        // ailleurs où c'est lui qui parle.
        if (reasoning.isNotEmpty) ...[
          SizedBox(height: context.vw(4.1)),
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

/// Un aliment du journal : son nom, ce qu'il pesait, ce qu'il vaut.
class _Item extends StatelessWidget {
  const _Item({required this.lang, required this.item});

  final String lang;
  final nutrition.FoodItem item;

  @override
  Widget build(BuildContext context) {
    // `portion` porte deja la quantite telle qu'elle a ete saisie : « 120 g »,
    // « 1 bol ». On ne la recompose pas.
    final quantity = item.portion.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                if (quantity.isNotEmpty) ...[
                  SizedBox(height: context.vw(0.5)),
                  Text(quantity, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ],
            ),
          ),
          SizedBox(width: context.vw(3.1)),
          Text.rich(
            TextSpan(
              style: RyzeText.body(context, 3.5, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              children: [
                TextSpan(text: '${item.calories}'),
                TextSpan(text: ' ${'nutri_kcal'.tr(lang)}', style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
              ],
            ),
          ),
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
