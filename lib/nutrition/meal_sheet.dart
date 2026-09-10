import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../models/weekly_planner_models.dart';
import '../services/day_meals.dart';
import '../services/meal_planner_sync_service.dart';
import '../services/weekly_planner_service.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import 'food_item_actions.dart';

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

  /// Le plat prévu dit-il autre chose que ce qui a été noté ?
  ///
  /// Noter un aliment sur un créneau prévu coche le plat prévu et le relie à
  /// l'aliment. Quand les deux portent le même nom, il n'y a qu'un repas :
  /// l'afficher une deuxième fois sous l'étiquette « Prévu » n'apprend rien,
  /// et proposer de « retirer le repas prévu » là où il n'y en a pas est un
  /// bouton qui ne veut rien dire. Quand ils diffèrent, le plan est une chose
  /// à part : on le montre, et on peut l'enlever.
  @visibleForTesting
  static bool plannedApart(String? dish, List<String> logged) {
    if (dish == null || dish.trim().isEmpty) return false;
    if (logged.isEmpty) return true;
    return dish != logged.join(', ');
  }

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

    // Le repas prévu, que l'appelant le connaisse ou non.
    //
    // Il fallait le lui passer : l'accueil le faisait, l'onglet Nutrition et
    // le calendrier du planificateur non. La même feuille proposait donc de
    // valider et de retirer d'un côté, et seulement d'ajouter de l'autre.
    // Elle le trouve maintenant dans la journée qu'elle vient de lire, sans
    // requête de plus.
    final prevu = planned ?? (meal.plannedActivities.isEmpty ? null : meal.plannedActivities.first);
    final data = prevu?.mealData;
    final dish = (data?.dishName?.isNotEmpty ?? false) ? data!.dishName! : meal.plannedName;

    final items = meal.logged?.items ?? const [];
    final eaten = items.isNotEmpty;

    // Le plat prévu ne se distingue de ce qui a été mangé que s'il dit autre
    // chose. Noter un aliment sur un créneau prévu coche le plat prévu et le
    // relie à l'aliment ; quand les deux portent le même nom, il n'y a qu'un
    // repas, et l'afficher deux fois n'apprend rien.
    final aPart = plannedApart(dish, [for (final i in items) i.name]);

    // Un repas prevu qu'on n'a pas encore mange : le valider en un geste est
    // la facon la plus rapide de noter un repas, et elle n'existait nulle
    // part. Le service savait pourtant le faire depuis toujours.
    //
    // Pas pour un jour à venir : valider, c'est dire « je l'ai mangé », et le
    // calendrier ouvre aussi bien demain qu'hier.
    final aujourdhui = DateTime.now();
    final passe = !DateTime(day.year, day.month, day.day)
        .isAfter(DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day));
    final canValidate = prevu != null && prevu.status != PlannedStatus.completed && !eaten && passe;

    // Retirer, c'est autre chose que valider : un plat prévu qu'on n'a pas
    // suivi reste affiché sous le repas noté, et rien ne permettait de s'en
    // débarrasser. Partout où la feuille montre le plat prévu comme une chose
    // à part, elle propose de l'enlever.
    final canRemove = prevu != null && aPart;

    // Ce que la feuille a changé pendant qu'elle était ouverte : une portion
    // refixée, un aliment retiré. L'appelant doit se recharger même si elle
    // se ferme sans bouton.
    bool touche = false;

    final action = await showRyzeSheet<_Action>(
      context,
      title: label,
      subtitle: RyzeDates.full(day, lang),
      builder: (_) => _Body(
        lang: lang,
        day: day,
        slot: slot,
        meal: meal,
        dish: aPart ? dish : null,
        data: data,
        onChanged: () => touche = true,
      ),
      actions: [
        if (canValidate)
          OnbButton(
            label: 'planner_validate_meal'.tr(lang),
            icon: LucideIcons.check,
            onPressed: () => Navigator.pop(context, _Action.validate),
          ),
        if (onAdd != null)
          OnbButton(
            label: 'add_food'.tr(lang),
            ghost: true,
            icon: LucideIcons.plus,
            onPressed: () => Navigator.pop(context, _Action.add),
          ),
        if (canRemove)
          OnbButton(
            // « Supprimer ce repas » à côté d'un repas noté se lirait comme
            // « supprime ce que j'ai mangé ». C'est le plan qu'on retire.
            label: (eaten ? 'planner_remove_planned' : 'planner_delete_meal').tr(lang),
            ghost: true,
            icon: LucideIcons.trash2,
            onPressed: () => Navigator.pop(context, _Action.remove),
          ),
      ],
    );

    if (action == null || !context.mounted) return touche;

    switch (action) {
      case _Action.add:
        onAdd?.call();
        return true;
      case _Action.validate:
        // `prevu` et non `planned` : l'onglet Nutrition et le calendrier ne
        // passent pas le repas prévu, la feuille le trouve elle-même. Valider
        // depuis là tombait sur un null.
        final id = await MealPlannerSyncService.validateMeal(prevu!);
        if (!context.mounted) return id != null;
        if (id == null) {
          RyzeUndo.failed(context, message: 'error_generic'.tr(lang));
          return false;
        }
        RyzeFeedback.success();
        RyzeUndo.note(
          context,
          message: 'meal_logged_kcal'.tr(lang).replaceAll('{m}', label).replaceAll('{n}', '${data?.calories ?? 0}'),
        );
        return true;
      case _Action.remove:
        final ok = await WeeklyPlannerService.deletePlannedActivity(prevu!.id, evenIfCompleted: true);
        if (!context.mounted) return ok;
        if (ok) {
          RyzeFeedback.removed();
        } else {
          RyzeUndo.failed(context, message: 'error_generic'.tr(lang));
        }
        return ok;
    }
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.lang,
    required this.day,
    required this.slot,
    required this.meal,
    required this.dish,
    required this.data,
    required this.onChanged,
  });

  final String lang;
  final DateTime day;
  final WeekSlot slot;
  final DayMeal meal;

  /// Le plat prévu, quel que soit l'endroit d'où il vient.
  final String? dish;
  final PlannedMealData? data;

  /// Quelque chose a bougé : l'écran qui a ouvert la feuille devra relire.
  final VoidCallback onChanged;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late DayMeal _meal = widget.meal;

  String get lang => widget.lang;
  DayMeal get meal => _meal;
  String? get dish => widget.dish;
  PlannedMealData? get data => widget.data;

  /// Relire la journée après une correction. Une requête, et la feuille
  /// redit tout juste : les aliments, mais aussi le compte au-dessus.
  Future<void> _reload() async {
    widget.onChanged();
    final jour = await DayMeals.forDate(widget.day);
    if (mounted) setState(() => _meal = jour[widget.slot]);
  }

  Future<void> _edit(nutrition.FoodItem item) async {
    if (await FoodItemActions.editPortion(context, item: item, lang: lang)) await _reload();
  }

  Future<void> _remove(nutrition.FoodItem item) async {
    final ok = await FoodItemActions.remove(
      context,
      item: item,
      slot: widget.slot,
      day: widget.day,
      lang: lang,
      onUndone: _reload,
    );
    if (ok) await _reload();
  }

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
        // Un repas ouvert se corrige ici aussi. Les deux gestes n'existaient
        // que dans la ligne de temps de Nutrition : ouvrir le même repas
        // depuis l'accueil ou le planificateur, c'était le lire sans pouvoir
        // y toucher.
        if (eaten)
          for (final item in items)
            _Item(
              lang: lang,
              item: item,
              onEdit: item.id == null ? null : () => _edit(item),
              onRemove: item.id == null ? null : () => _remove(item),
            ),

        if (!eaten && (dish?.isEmpty ?? true))
          Text('nutri_nothing_logged'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),

        // Ce qui était prévu, quand on a mangé autre chose.
        //
        // Le plat prévu ne s'affichait que tant que rien n'était noté : ouvrir
        // « Prévu · … » sous un repas fait aurait montré le journal sans jamais
        // nommer le plat qu'on venait de toucher. Les comptes, eux, restent
        // ceux du journal : c'est lui qui fait foi.
        if (eaten && (dish?.isNotEmpty ?? false)) ...[
          SizedBox(height: context.vw(1)),
          Container(height: 1, color: RyzeColors.line),
          SizedBox(height: context.vw(3.6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(1.2)),
                decoration: BoxDecoration(color: RyzeColors.paper2, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                child: Text(
                  'planner_planned'.tr(lang),
                  style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: RyzeColors.mute),
                ),
              ),
              SizedBox(width: context.vw(2.6)),
              Expanded(
                child: Text(
                  dish!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.mute),
                ),
              ),
            ],
          ),
        ],

        if (description.isNotEmpty) ...[
          SizedBox(height: context.vw(3.6)),
          RecipeView(lang: lang, recipe: RecipeText.parse(description)),
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
  const _Item({required this.lang, required this.item, this.onEdit, this.onRemove});

  final String lang;
  final nutrition.FoodItem item;

  /// Refixer la portion, et enlever. Nuls pour un aliment sans identifiant :
  /// il n'y a rien à corriger dans la base.
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

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
            child: Pressable(
              onTap: onEdit,
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
          if (onRemove != null)
            Pressable(
              onTap: onRemove,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(LucideIcons.x, size: 15, color: RyzeColors.mute2),
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

/// Ce que la feuille rend a son appelant.
enum _Action { validate, add, remove }
