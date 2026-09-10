import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/weekly_planner/week_strip.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../models/weekly_planner_models.dart';
import 'food_entries_service.dart';
import 'weekly_planner_service.dart';

/// One meal of one day, as the whole app should read it.
class DayMeal {
  const DayMeal({
    required this.slot,
    required this.state,
    required this.at,
    required this.plannedName,
    required this.logged,
    this.plannedCalories,
    this.plannedActivities = const [],
  });

  final WeekSlot slot;

  /// [SlotState.done] once something is in the journal for this slot, or once
  /// the planned meal is validated. [SlotState.planned] while the planner has
  /// something waiting. [SlotState.empty] otherwise.
  final SlotState state;

  /// When it was eaten, when it is known: the first food of the block. Null for
  /// a slot that is only planned or still free; the caller falls back on the
  /// hour the user set in their reminders.
  final DateTime? at;

  /// What the planner intends to be eaten, when it says so.
  ///
  /// Tous les plats du créneau, pas seulement le premier : deux collations
  /// prévues n'en montraient qu'une.
  final String? plannedName;

  /// Les repas prévus de ce créneau, tels quels.
  ///
  /// Seuls leurs noms étaient gardés : la feuille d'un repas ne pouvait donc
  /// ni valider ni retirer ce qui était prévu, faute d'avoir l'objet sous la
  /// main. L'accueil, lui, le passait — d'où deux écrans qui ouvraient la
  /// même feuille et n'y proposaient pas la même chose.
  final List<PlannedActivity> plannedActivities;

  /// Ce que le plan prévoit pour ce créneau, en calories.
  ///
  /// L'accueil les affichait, cette page non : le créneau annonçait « Prévu ·
  /// Saumon » sans dire ce que ça pesait dans la journée.
  final int? plannedCalories;

  /// The journal block, when there is one. Carries the items, so a row can
  /// open in place without a second query.
  final nutrition.Meal? logged;

  bool get isDone => state == SlotState.done;

  int get calories => logged?.items.fold<int>(0, (s, i) => s + i.calories) ?? 0;
  double get proteins => logged?.items.fold<double>(0, (s, i) => s + i.proteins) ?? 0;
  double get carbs => logged?.items.fold<double>(0, (s, i) => s + i.carbs) ?? 0;
  double get fats => logged?.items.fold<double>(0, (s, i) => s + i.fats) ?? 0;

  /// The two or three first foods, for the line under the meal's name.
  String get summary => logged == null ? '' : logged!.items.map((i) => i.name).join(', ');
}

/// The four meals of a day, read once, from the two places that know: the
/// journal and the week plan.
///
/// This is the single definition of "done" in the app. The home and the
/// Nutrition tab both read it, so a meal can never look eaten on one screen
/// and free on the other, which is exactly what happened when the home crossed
/// the plan with the journal and the Nutrition dashboard only asked whether
/// calories were above zero.
class DayMeals {
  const DayMeals._(this.date, this.meals);

  /// Une journée montée à la main. L'application passe toujours par
  /// [forDate] ; un test, lui, ne peut pas ouvrir Supabase.
  @visibleForTesting
  factory DayMeals.of(DateTime date, Map<WeekSlot, DayMeal> meals) => DayMeals._(date, meals);

  final DateTime date;
  final Map<WeekSlot, DayMeal> meals;

  DayMeal operator [](WeekSlot slot) =>
      meals[slot] ?? DayMeal(slot: slot, state: SlotState.empty, at: null, plannedName: null, logged: null);

  /// Meals in the order of a day. The snack is always present here: Nutrition
  /// is where one is added. A surface that only reports the day, like the
  /// home, hides it while it is empty.
  static const List<WeekSlot> order = [WeekSlot.breakfast, WeekSlot.lunch, WeekSlot.snack, WeekSlot.dinner];

  int get caloriesLogged => order.fold(0, (s, slot) => s + this[slot].calories);
  double get proteinsLogged => order.fold(0.0, (s, slot) => s + this[slot].proteins);
  double get carbsLogged => order.fold(0.0, (s, slot) => s + this[slot].carbs);
  double get fatsLogged => order.fold(0.0, (s, slot) => s + this[slot].fats);
  int get doneCount => order.where((slot) => this[slot].isDone).length;

  /// How many meals the day holds: the three main ones, plus the snack when
  /// it is planned or eaten.
  int get total => 3 + (this[WeekSlot.snack].state == SlotState.empty ? 0 : 1);

  /// Reads one day. Never throws: a failure yields a day with nothing in it,
  /// and the caller shows its empty state rather than invented food.
  static Future<DayMeals> forDate(DateTime date) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final day = DateTime(date.year, date.month, date.day);

    List<nutrition.Meal> logged = const [];
    if (userId != null) {
      logged = await FoodEntriesService.getFoodEntriesForDate(userId, day);
    }

    DayPlanData? plan;
    try {
      final week = await WeeklyPlannerService.getWeekData();
      plan = week.getDayPlan(day);
    } catch (_) {
      plan = null;
    }

    final byType = <String, nutrition.Meal>{};
    for (final meal in logged) {
      final type = normalizeMealType(meal.mealType ?? meal.name);
      final existing = byType[type];
      // several blocks of the same type in one day: the earliest carries the
      // hour, and its items are joined so the row shows the whole meal
      if (existing == null) {
        byType[type] = meal;
      } else {
        final keepFirst = (existing.at ?? day).isBefore(meal.at ?? day);
        byType[type] = nutrition.Meal(
          id: keepFirst ? existing.id : meal.id,
          time: keepFirst ? existing.time : meal.time,
          name: keepFirst ? existing.name : meal.name,
          mealType: type,
          at: keepFirst ? existing.at : meal.at,
          items: [...existing.items, ...meal.items],
        );
      }
    }

    final out = <WeekSlot, DayMeal>{};
    for (final slot in order) {
      final type = slot.name;
      final block = byType[type];
      final planned = plan?.meals.where((m) => m.activityType.value == type).toList() ?? const <PlannedActivity>[];
      final plannedDone = planned.any((m) => m.status == PlannedStatus.completed);

      // Le journal fait foi. Un repas dont on a retiré le dernier aliment
      // n'est plus fait, même si le plan le croit encore terminé : le statut
      // du plan est posé à l'ajout et peut retarder d'un instant sur la
      // suppression. Sans ça, le créneau restait coché et vide, sans aucun
      // moyen d'y remettre quelque chose.
      final hasFood = block != null && block.items.isNotEmpty;

      // Le plan appartient au présent et à l'avenir. Un repas prévu et jamais
      // mangé, trois jours plus tard, n'est plus une information sur laquelle
      // on agit : la journée passée montre ce qui a eu lieu.
      final aVenir = plan == null || !plan.isPast;
      final visibles = aVenir ? planned : const <PlannedActivity>[];

      final SlotState state;
      if (hasFood) {
        state = SlotState.done;
      } else if (visibles.isNotEmpty || (plannedDone && aVenir)) {
        // Le créneau d'un jour passé dont le plan n'a pas été suivi restait
        // dessiné « prévu », avec « Rien d'enregistré » écrit dessous.
        state = SlotState.planned;
      } else {
        state = SlotState.empty;
      }

      final noms = [
        for (final m in visibles)
          if ((m.mealData?.dishName ?? '').trim().isNotEmpty) m.mealData!.dishName!.trim(),
      ];
      final kcal = visibles.fold<int>(0, (n, m) => n + (m.mealData?.calories ?? 0));

      out[slot] = DayMeal(
        slot: slot,
        state: state,
        at: hasFood ? block.at : null,
        plannedName: noms.isEmpty ? null : noms.join(', '),
        plannedCalories: kcal <= 0 ? null : kcal,
        plannedActivities: visibles,
        logged: hasFood ? block : null,
      );
    }
    return DayMeals._(day, out);
  }

  /// The journal stores a meal type in whatever the user's language called it;
  /// the plan and the strip use four fixed names.
  static String normalizeMealType(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'déjeuner' || lower == 'lunch') return 'lunch';
    if (lower.contains('breakfast') || lower.contains('petit') || lower.contains('frühstück')) return 'breakfast';
    if (lower.contains('lunch') || lower.contains('mittag')) return 'lunch';
    if (lower.contains('dinner') || lower.contains('diner') || lower.contains('dîner') || lower.contains('souper') || lower.contains('abend')) {
      return 'dinner';
    }
    if (lower.contains('snack') || lower.contains('collation') || lower.contains('goûter') || lower.contains('gouter') || lower.contains('zwischen')) {
      return 'snack';
    }
    return lower;
  }
}
