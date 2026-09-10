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

/// Un repas, ouvert : ce qui a été mangé d'un côté, ce qui était prévu de
/// l'autre, et le compte de chacun.
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
///
/// Le repas noté et le plat prévu sont deux choses, pas deux moitiés d'une
/// page : ils ont chacun leur page, on passe de l'une à l'autre d'un
/// balayage, et les boutons du bas suivent celle qu'on regarde.
class MealSheet {
  MealSheet._();

  /// Le plat prévu dit-il autre chose que ce qui a été noté ?
  ///
  /// Noter un aliment sur un créneau prévu coche le plat prévu et le relie à
  /// l'aliment. Quand les deux portent le même nom, il n'y a qu'un repas :
  /// l'afficher une deuxième fois sous l'étiquette « Prévu » n'apprend rien,
  /// et proposer de « retirer le repas prévu » là où il n'y en a pas est un
  /// bouton qui ne veut rien dire. Quand ils diffèrent, le plan est une chose
  /// à part : il a sa page, et on peut l'enlever.
  @visibleForTesting
  static bool plannedApart(String? dish, List<String> logged) {
    if (dish == null || dish.trim().isEmpty) return false;
    if (logged.isEmpty) return true;
    return dish != logged.join(', ');
  }

  /// Les pages d'un créneau, dans l'ordre de la journée.
  ///
  /// Le repas noté d'abord, puis un plat prévu par page. Un créneau peut en
  /// prévoir plusieurs — deux collations, une entrée et un plat — et ils
  /// étaient réduits au premier. Un créneau vide garde la page du journal :
  /// c'est elle qui dit qu'il n'y a rien.
  @visibleForTesting
  static List<MealPage> pagesFor({required bool eaten, required int planned}) => [
        if (eaten || planned == 0) MealPage.logged,
        for (var i = 0; i < planned; i++) MealPage.planned,
      ];

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

    // Tous les plats prévus du créneau, que l'appelant les connaisse ou non.
    //
    // Il fallait les lui passer : l'accueil le faisait, l'onglet Nutrition et
    // le calendrier du planificateur non. La même feuille proposait donc de
    // valider et de retirer d'un côté, et seulement d'ajouter de l'autre. Elle
    // les trouve maintenant dans la journée qu'elle vient de lire, sans
    // requête de plus — et tous, pas seulement le premier : un créneau peut en
    // annoncer deux, et le second n'était visible nulle part.
    final tous = meal.plannedActivities.isNotEmpty
        ? meal.plannedActivities
        : (planned == null ? const <PlannedActivity>[] : [planned]);

    final items = meal.logged?.items ?? const <nutrition.FoodItem>[];
    final eaten = items.isNotEmpty;
    final noms = [for (final i in items) i.name];

    // Un plat prévu n'a sa page que s'il dit autre chose que ce qui a été
    // noté : celui qu'on a vraiment mangé est déjà la page du journal.
    final prevus = [for (final a in tous) if (plannedApart(_dishOf(a, meal), noms)) a];

    // Les pages, dans l'ordre de la journée : ce qu'on a mangé, puis chaque
    // plat prévu. Un créneau vide n'en a qu'une, celle du journal, qui dira
    // qu'il n'y a rien.
    final pages = pagesFor(eaten: eaten, planned: prevus.length);

    // Un repas prevu qu'on n'a pas encore mange : le valider en un geste est
    // la facon la plus rapide de noter un repas, et elle n'existait nulle
    // part. Le service savait pourtant le faire depuis toujours.
    //
    // Pas pour un jour à venir : valider, c'est dire « je l'ai mangé », et le
    // calendrier ouvre aussi bien demain qu'hier.
    final aujourdhui = DateTime.now();
    final passe = !DateTime(day.year, day.month, day.day)
        .isAfter(DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day));

    // Le plat prévu sur lequel le bouton du bas vient d'agir : chaque page a
    // le sien.
    PlannedActivity? cible;

    // Ce que la feuille a changé pendant qu'elle était ouverte : une portion
    // refixée, un aliment retiré. L'appelant doit se recharger même si elle
    // se ferme sans bouton.
    bool touche = false;

    // La page regardée, partagée entre le corps et les boutons du bas : ce
    // qu'on peut faire dépend de ce qu'on a sous les yeux.
    final page = ValueNotifier<int>(0);

    final action = await showRyzeSheet<_Action>(
      context,
      title: label,
      subtitle: RyzeDates.full(day, lang),
      builder: (_) => _Body(
        lang: lang,
        day: day,
        slot: slot,
        meal: meal,
        plans: prevus,
        pages: pages,
        page: page,
        onChanged: () => touche = true,
      ),
      actions: [
        _Actions(
          lang: lang,
          page: page,
          pages: pages,
          plans: prevus,
          eaten: eaten,
          canValidate: !eaten && passe,
          canAdd: onAdd != null,
          onAct: (plan, act) {
            cible = plan;
            Navigator.pop(context, act);
          },
        ),
      ],
    );

    page.dispose();

    if (action == null || !context.mounted) return touche;

    switch (action) {
      case _Action.add:
        onAdd?.call();
        return true;
      case _Action.validate:
        // La cible et non « le premier plat prévu » : l'onglet Nutrition et
        // le calendrier ne passent rien, la feuille les trouve elle-même, et
        // un créneau peut en prévoir plusieurs.
        if (cible == null) return touche;
        final id = await MealPlannerSyncService.validateMeal(cible!);
        if (!context.mounted) return id != null;
        if (id == null) {
          RyzeUndo.failed(context, message: 'error_generic'.tr(lang));
          return false;
        }
        RyzeFeedback.success();
        RyzeUndo.note(
          context,
          message: 'meal_logged_kcal'.tr(lang).replaceAll('{m}', label).replaceAll('{n}', '${cible!.mealData?.calories ?? 0}'),
        );
        return true;
      case _Action.remove:
        if (cible == null) return touche;
        final ok = await WeeklyPlannerService.deletePlannedActivity(cible!.id, evenIfCompleted: true);
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

/// Les faces d'un créneau : ce qu'on a mangé, et chaque plat prévu.
enum MealPage { logged, planned }

/// Le nom d'un plat prévu. Le plan porte le sien ; à défaut, la journée sait
/// ce que le créneau annonçait.
String? _dishOf(PlannedActivity plan, DayMeal meal) {
  final name = plan.mealData?.dishName?.trim() ?? '';
  return name.isNotEmpty ? name : meal.plannedName;
}

class _Body extends StatefulWidget {
  const _Body({
    required this.lang,
    required this.day,
    required this.slot,
    required this.meal,
    required this.plans,
    required this.pages,
    required this.page,
    required this.onChanged,
  });

  final String lang;
  final DateTime day;
  final WeekSlot slot;
  final DayMeal meal;

  /// Les plats prévus qui disent autre chose que ce qui a été noté, dans
  /// l'ordre où ils ont été prévus. Un par page.
  final List<PlannedActivity> plans;

  final List<MealPage> pages;
  final ValueNotifier<int> page;

  /// Quelque chose a bougé : l'écran qui a ouvert la feuille devra relire.
  final VoidCallback onChanged;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late DayMeal _meal = widget.meal;
  int _index = 0;

  String get lang => widget.lang;
  DayMeal get meal => _meal;

  /// De combien la première page décale les plats : elle est celle du journal,
  /// sauf quand il n'y a rien de noté.
  int get _offset => widget.pages.first == MealPage.logged ? 1 : 0;

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

  void _goTo(int i) {
    if (i == _index || i < 0 || i >= widget.pages.length) return;
    RyzeFeedback.select();
    setState(() => _index = i);
    widget.page.value = i;
  }

  /// Un balayage horizontal passe d'une face à l'autre.
  ///
  /// À deux pages, le sens n'a pas à être appris : le doigt part à gauche ou à
  /// droite, on arrive sur l'autre. Au-delà, il compte.
  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 120) return;
    if (widget.pages.length == 2) {
      _goTo(_index == 0 ? 1 : 0);
      return;
    }
    _goTo(v < 0 ? _index + 1 : _index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final several = widget.pages.length > 1;
    final index = _index.clamp(0, widget.pages.length - 1);
    final page = widget.pages[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: several ? _swipe : null,
          child: AnimatedSize(
            duration: RyzeDurations.enter,
            curve: RyzeCurves.out,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: RyzeDurations.tap,
              switchInCurve: RyzeCurves.out,
              // Les pages n'ont pas la même hauteur : elles se croisent par le
              // haut, sinon la sortante tire la feuille vers le bas.
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(index),
                child: page == MealPage.logged
                    ? _logged(context, several)
                    : _planned(context, widget.plans[index - _offset], index - _offset),
              ),
            ),
          ),
        ),
        if (several) ...[
          SizedBox(height: context.vw(4.1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.pages.length; i++) ...[
                if (i > 0) SizedBox(width: context.vw(1.5)),
                Pressable(
                  onTap: () => _goTo(i),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.vw(2)),
                    child: AnimatedContainer(
                      duration: RyzeDurations.tap,
                      curve: RyzeCurves.out,
                      width: i == index ? context.vw(4.6) : context.vw(1.8),
                      height: context.vw(1.8),
                      decoration: BoxDecoration(
                        // La page du journal est l'encre, celles du plan sont
                        // l'ambre : la couleur dit déjà de quel côté on est.
                        color: i == index
                            ? (widget.pages[i] == MealPage.logged ? RyzeColors.ink : RyzeColors.acc)
                            : RyzeColors.idle,
                        borderRadius: BorderRadius.circular(RyzeRadius.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Ce qu'il y a eu dans l'assiette : le compte du journal, puis les aliments
  /// un par un, chacun corrigeable.
  Widget _logged(BuildContext context, bool several) {
    final items = meal.logged?.items ?? const <nutrition.FoodItem>[];
    final eaten = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (several) ...[
          _Tag(label: 'meal_page_logged'.tr(lang), done: true),
          SizedBox(height: context.vw(3.1)),
        ],
        if (meal.calories > 0) ...[
          _Stats(
            lang: lang,
            kcal: meal.calories,
            proteins: meal.proteins,
            carbs: meal.carbs,
            fats: meal.fats,
          ),
          SizedBox(height: context.vw(4.6)),
        ],
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
            )
        else
          Text('nutri_nothing_logged'.tr(lang), style: RyzeText.body(context, 3.6, color: RyzeColors.mute)),
      ],
    );
  }

  /// Ce que Ryze avait prévu : le plat, ce qu'il pèse, sa recette, et la
  /// raison qui l'a fait choisir.
  ///
  /// [rank] situe ce plat parmi les plats prévus du créneau, quand il y en a
  /// plusieurs : une collation peut en annoncer deux.
  Widget _planned(BuildContext context, PlannedActivity plan, int rank) {
    final data = plan.mealData;
    final description = data?.dishDescription?.trim() ?? '';
    final reasoning = data?.aiReasoning?.trim() ?? '';
    final kcal = data?.calories ?? 0;
    final total = widget.plans.length;
    final label = 'meal_page_planned'.tr(lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tag(label: total > 1 ? '$label · ${rank + 1}/$total' : label, done: false),
        SizedBox(height: context.vw(2.6)),
        Text(_dishOf(plan, meal) ?? '', style: RyzeText.body(context, 4.6, weight: FontWeight.w600)),
        if (kcal > 0) ...[
          SizedBox(height: context.vw(3.6)),
          _Stats(
            lang: lang,
            kcal: kcal,
            proteins: data?.proteins ?? 0,
            carbs: data?.carbs ?? 0,
            fats: data?.fats ?? 0,
          ),
        ],
        if (description.isNotEmpty) ...[
          SizedBox(height: context.vw(4.1)),
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

/// Les boutons du bas suivent la page regardée : on ne valide pas un plat
/// prévu depuis la page du repas noté, et on n'ajoute pas un aliment depuis
/// une recette.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.lang,
    required this.page,
    required this.pages,
    required this.plans,
    required this.eaten,
    required this.canValidate,
    required this.canAdd,
    required this.onAct,
  });

  final String lang;
  final ValueNotifier<int> page;
  final List<MealPage> pages;
  final List<PlannedActivity> plans;
  final bool eaten;

  /// Rien n'est noté sur le créneau et le jour n'est pas à venir : valider un
  /// plat prévu a un sens.
  final bool canValidate;

  final bool canAdd;

  /// Le plat prévu concerné, et ce qu'on en fait. Nul pour la page du journal.
  final void Function(PlannedActivity? plan, _Action action) onAct;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: page,
      builder: (context, value, _) {
        final index = value.clamp(0, pages.length - 1);
        final planned = pages[index] == MealPage.planned;
        final offset = pages.first == MealPage.logged ? 1 : 0;
        final plan = planned ? plans[index - offset] : null;

        final boutons = <Widget>[
          if (plan != null && canValidate && plan.status != PlannedStatus.completed)
            OnbButton(
              label: 'planner_validate_meal'.tr(lang),
              icon: LucideIcons.check,
              onPressed: () => onAct(plan, _Action.validate),
            ),
          if (canAdd && (!planned || !eaten))
            OnbButton(
              label: 'add_food'.tr(lang),
              ghost: true,
              icon: LucideIcons.plus,
              onPressed: () => onAct(null, _Action.add),
            ),
          if (plan != null)
            OnbButton(
              // « Supprimer ce repas » à côté d'un repas noté se lirait comme
              // « supprime ce que j'ai mangé ». C'est le plan qu'on retire.
              label: (eaten ? 'planner_remove_planned' : 'planner_delete_meal').tr(lang),
              ghost: true,
              icon: LucideIcons.trash2,
              onPressed: () => onAct(plan, _Action.remove),
            ),
        ];

        return AnimatedSize(
          duration: RyzeDurations.tap,
          curve: RyzeCurves.out,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < boutons.length; i++) ...[
                if (i > 0) SizedBox(height: context.vw(2.4)),
                boutons[i],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// L'étiquette d'une page : ce qu'on regarde, et de quel côté c'est.
///
/// Le journal et le plan se ressemblaient trop : même gris, même place, on ne
/// savait pas lequel des deux on lisait. Ce que l'utilisateur a noté porte
/// l'encre, ce que Ryze a prévu porte l'ambre — la règle de couleur du reste
/// de l'application, mise ici au service de la seule question de la feuille.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final teinte = done ? RyzeColors.ink : RyzeColors.accInk;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(2.9), vertical: context.vw(1.4)),
          decoration: BoxDecoration(
            color: teinte.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(RyzeRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? LucideIcons.check : LucideIcons.calendar, size: context.vw(3.1), color: teinte),
              SizedBox(width: context.vw(1.5)),
              Text(
                label,
                style: RyzeText.body(context, 2.9, weight: FontWeight.w700, color: teinte),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Les quatre chiffres d'un repas, toujours dans le même ordre.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.lang,
    required this.kcal,
    required this.proteins,
    required this.carbs,
    required this.fats,
  });

  final String lang;
  final int kcal;
  final double proteins;
  final double carbs;
  final double fats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(value: '$kcal', label: 'nutri_kcal'.tr(lang))),
        Expanded(child: _Stat(value: '${proteins.round()} g', label: 'proteins'.tr(lang))),
        Expanded(child: _Stat(value: '${carbs.round()} g', label: 'carbohydrates'.tr(lang))),
        Expanded(child: _Stat(value: '${fats.round()} g', label: 'fats'.tr(lang))),
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
