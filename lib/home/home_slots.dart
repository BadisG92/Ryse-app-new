import '../components/weekly_planner/week_strip.dart';
import '../models/weekly_planner_models.dart';

/// Today's session as one item: the workout or cardio the page talks about,
/// opens, and draws. The first one still waiting wins; when every session of
/// the day is done, the first done one does.
typedef HomeSession = ({PlannedWorkout? workout, PlannedActivity? cardio, PlannedStatus status, String label});

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

    for (final slot in kFoodSlots) {
      final type = slot.name;
      final planned = day.meals.where((m) => m.activityType.value == type).toList();
      if (planned.isNotEmpty) {
        final done = planned.any((m) => m.status == PlannedStatus.completed);
        states[slot] = done ? SlotState.done : SlotState.planned;
        final name = planned.first.mealData?.dishName;
        if (name != null && name.isNotEmpty) labels[slot] = name;
      } else if (eatenTypes.contains(type)) {
        states[slot] = SlotState.done;
      }
    }

    final s = session(day);
    if (s != null) {
      states[WeekSlot.sport] = s.status == PlannedStatus.completed ? SlotState.done : SlotState.planned;
      if (s.label.isNotEmpty) labels[WeekSlot.sport] = s.label;
    }
    return DaySlots(states: states, labels: labels);
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
