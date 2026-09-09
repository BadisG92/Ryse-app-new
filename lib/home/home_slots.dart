import '../components/weekly_planner/week_strip.dart';
import '../models/weekly_planner_models.dart';

/// Today's session as one item: the workout or cardio the page talks about,
/// opens, and draws. The first one still waiting wins; when every session of
/// the day is done, the first done one does.
typedef HomeSession = ({PlannedWorkout? workout, PlannedActivity? cardio, PlannedStatus status, String label});


/// Une ligne du jour déplié : ce qui est prévu, dit en toutes lettres.
///
/// La bande donne l'aperçu — sept jours, leurs marques — mais une marque dit
/// qu'il y a quelque chose, jamais quoi. Ouvrir un jour donne la largeur de
/// l'écran à ses lignes, et là on lit « Dîner · Saumon, riz · 620 kcal ».
typedef PlannedLine = ({
  WeekSlot slot,
  SlotState state,
  String title,
  String detail,
  PlannedWorkout? workout,
  PlannedActivity? activity,
});

/// Reads one day of the plan in the week strip's language: a state per slot.
///
/// A planned meal is `planned`; once one of its foods is validated, or once a
/// meal of that type was eaten outside the plan, it is `done`. A missed meal
/// stays drawn as planned: the day chip already dims what is past. The
/// session's state, label and target all come from the same item, so a done
/// cardio next to a waiting workout never reads as a done workout.
class HomeSlots {
  HomeSlots._();

  static HomeSession? session(DayPlanData? day) {
    if (day == null) return null;
    final items = <HomeSession>[
      for (final w in day.workouts) (workout: w, cardio: null, status: w.status, label: w.workoutName),
      for (final c in day.cardios) (workout: null, cardio: c, status: c.status, label: c.cardioData?.activityName ?? ''),
    ];
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.status != PlannedStatus.completed) return item;
    }
    return items.first;
  }

  static DaySlots ofDay(DayPlanData? day) {
    if (day == null) return const DaySlots();
    final states = <WeekSlot, SlotState>{};
    final labels = <WeekSlot, String>{};

    // journal entries already linked to a planned meal are that meal
    final linked = <String>{
      for (final m in day.meals)
        if (m.mealData?.linkedFoodEntryId != null) m.mealData!.linkedFoodEntryId!,
    };
    final eatenTypes = day.journalEntries.where((e) => !linked.contains(e.id)).map((e) => normalizeMealType(e.mealType)).toSet();

    // Le journal fait foi, exactement comme dans `DayMeals` : un créneau est
    // fait s'il y a quelque chose dans l'assiette, quoi que dise le plan.
    //
    // Le statut du plan décidait seul dès qu'un repas y était prévu. Deux
    // écarts en découlaient : un repas noté hors plan pendant que le plan
    // n'avait pas suivi restait « prévu » sur l'accueil alors que Nutrition le
    // donnait fait ; et un repas prévu coché puis vidé de son dernier aliment
    // gardait sa pastille pleine ici pendant que Nutrition rouvrait le créneau.
    for (final slot in kFoodSlots) {
      final type = slot.name;
      final planned = day.meals.where((m) => m.activityType.value == type).toList();
      final hasFood = day.eatenMealTypes.contains(type) || eatenTypes.contains(type);

      if (hasFood) {
        states[slot] = SlotState.done;
      } else if (planned.isNotEmpty) {
        states[slot] = SlotState.planned;
      }

      if (planned.isNotEmpty) {
        final name = planned.first.mealData?.dishName;
        if (name != null && name.isNotEmpty) labels[slot] = name;
      }
    }

    final s = session(day);
    if (s != null) {
      states[WeekSlot.sport] = s.status == PlannedStatus.completed ? SlotState.done : SlotState.planned;
      if (s.label.isNotEmpty) labels[WeekSlot.sport] = s.label;
    }
    return DaySlots(states: states, labels: labels);
  }

  /// Ce qu'un jour contient, une ligne par élément prévu, dans l'ordre de la
  /// journée. Un jour sans rien rend une liste vide, et la vue propose alors
  /// de le planifier.
  static List<PlannedLine> linesOf(
    DayPlanData? day, {
    required String Function(WeekSlot) slotLabel,
    required String kcal,
    required String exercises,
  }) {
    if (day == null) return const [];
    final lines = <PlannedLine>[];

    for (final slot in kFoodSlots) {
      for (final meal in day.meals) {
        if (meal.activityType.value != slot.name) continue;
        final data = meal.mealData;
        final name = (data?.dishName?.isNotEmpty ?? false) ? data!.dishName! : slotLabel(slot);
        final energy = data?.calories;
        lines.add((
          slot: slot,
          state: meal.status == PlannedStatus.completed ? SlotState.done : SlotState.planned,
          title: name,
          detail: energy == null || energy <= 0 ? '' : '$energy $kcal',
          workout: null,
          activity: meal,
        ));
      }
    }

    // Ce qui a ete mange hors plan. La bande le savait deja — un carre plein
    // sur le jour — mais le jour deplie, lui, ne lisait que le planifie : on
    // notait un repas, la marque se remplissait, et le detail restait vide.
    final linked = <String>{
      for (final m in day.meals)
        if (m.mealData?.linkedFoodEntryId != null) m.mealData!.linkedFoodEntryId!,
    };
    for (final slot in kFoodSlots) {
      final eaten = [
        for (final e in day.journalEntries)
          if (!linked.contains(e.id) && normalizeMealType(e.mealType) == slot.name) e,
      ];
      if (eaten.isEmpty) continue;
      final energy = eaten.fold<int>(0, (n, e) => n + e.calories);
      lines.add((
        slot: slot,
        state: SlotState.done,
        title: eaten.map((e) => e.name).where((n) => n.isNotEmpty).join(', '),
        detail: energy <= 0 ? '' : '$energy $kcal',
        workout: null,
        activity: null,
      ));
    }

    for (final w in day.workouts) {
      lines.add((
        slot: WeekSlot.sport,
        state: w.status == PlannedStatus.completed ? SlotState.done : SlotState.planned,
        title: w.workoutName,
        detail: w.exercises.isEmpty ? '' : '${w.exercises.length} $exercises',
        workout: w,
        activity: null,
      ));
    }
    for (final c in day.cardios) {
      final data = c.cardioData;
      lines.add((
        slot: WeekSlot.sport,
        state: c.status == PlannedStatus.completed ? SlotState.done : SlotState.planned,
        title: data?.activityName ?? '',
        detail: data?.targetMinutes == null ? '' : '${data!.targetMinutes} min',
        workout: null,
        activity: c,
      ));
    }
    return lines;
  }

  /// The journal stores meal types in whatever the user's language called
  /// them; the plan uses four fixed names.
  static String normalizeMealType(String mealType) {
    final lower = mealType.toLowerCase().trim();
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
