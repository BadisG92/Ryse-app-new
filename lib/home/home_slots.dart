import '../components/weekly_planner/week_strip.dart';
import '../models/weekly_planner_models.dart';
import '../sport/sport_data.dart';

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

  /// Ce qui était prévu, sous ce qui a été mangé. Vide le reste du temps.
  String note,
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

  /// Le repas prevu d'un creneau, quand il y en a un : la feuille de detail
  /// en a besoin pour montrer le plat de Ryze a cote de ce qui a ete mange.
  static PlannedActivity? plannedMeal(DayPlanData? day, WeekSlot slot) {
    if (day == null) return null;
    for (final meal in day.meals) {
      if (meal.activityType.value == slot.name) return meal;
    }
    return null;
  }

  /// Toutes les séances d'une journée, musculation et cardio mêlées.
  ///
  /// Une journée en porte souvent plusieurs — une course le matin, le dos
  /// le soir — et l'app n'en montrait qu'une : [session] rendait la
  /// première à faire et l'onglet Sport n'affichait que celle-là. Les
  /// séances qui restent à faire passent devant, dans l'ordre où elles ont
  /// été prévues ; celles qui sont finies ferment la marche.
  static List<HomeSession> sessions(DayPlanData? day) {
    if (day == null) return const [];
    final items = <HomeSession>[
      for (final w in day.workouts) (workout: w, cardio: null, status: w.status, label: w.workoutName),
      for (final c in day.cardios) (workout: null, cardio: c, status: c.status, label: c.cardioData?.activityName ?? ''),
    ];
    items.sort((a, b) {
      final da = a.status == PlannedStatus.completed ? 1 : 0;
      final db = b.status == PlannedStatus.completed ? 1 : 0;
      return da.compareTo(db);
    });
    return items;
  }

  /// La séance qui mène la journée : la première à faire, sinon la
  /// première tout court. C'est ce que porte la marque unique d'un jour
  /// dans la bande de la semaine, qui n'a la place que pour une.
  static HomeSession? session(DayPlanData? day) {
    final all = sessions(day);
    return all.isEmpty ? null : all.first;
  }

  /// [done] : ce qui a vraiment eu lieu ce jour-la, lu dans l'historique du
  /// sport et non dans le plan.
  ///
  /// Une seance terminee est censee creer sa ligne dans le planificateur,
  /// mais cette synchronisation echoue en silence — un reseau qui tombe a la
  /// mauvaise seconde, et la seance existe dans l'historique sans jamais
  /// apparaitre dans la semaine. La nourriture avait deja ce garde-fou avec
  /// le journal ; le sport ne l'avait pas.
  static DaySlots ofDay(DayPlanData? day, {Set<SportKind>? done}) {
    if (day == null) {
      if (done == null || done.isEmpty) return const DaySlots();
      return DaySlots(states: {WeekSlot.sport: SlotState.done});
    }
    final states = <WeekSlot, SlotState>{};
    final labels = <WeekSlot, String>{};

    final eatenTypes = day.journalEntries.map((e) => normalizeMealType(e.mealType)).toSet();

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
    // Une seance reellement faite l'emporte sur ce que le plan croit savoir.
    if (done != null && done.isNotEmpty) states[WeekSlot.sport] = SlotState.done;
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
    String? plannedPrefix,
  }) {
    if (day == null) return const [];
    final lines = <PlannedLine>[];

    // Le plan appartient au présent et à l'avenir.
    //
    // La bande des jours effaçait déjà le prévu des jours passés ; le panneau,
    // lui, le gardait. Les deux racontaient donc le même mardi autrement. Un
    // repas prévu et jamais mangé, trois jours plus tard, n'est pas une
    // information sur laquelle on agit : la journée passée montre ce qui a eu
    // lieu, et rien d'autre.
    bool visible(PlannedStatus status) =>
        !day.isPast || status == PlannedStatus.completed;

    // Le journal fait foi, le plan est le contexte.
    //
    // Noter un aliment sur un créneau déjà prévu coche le plat prévu et le
    // relie à l'aliment. La ligne se construisait alors depuis le plan :
    // l'accueil annonçait « Bol d'avoine et fruits · 505 kcal » pour un poke
    // bowl à 934, et le plat réellement mangé n'apparaissait nulle part,
    // pendant que Nutrition affichait les deux correctement.
    for (final slot in kFoodSlots) {
      final plans = [for (final m in day.meals) if (m.activityType.value == slot.name) m];
      final eaten = [for (final e in day.journalEntries) if (normalizeMealType(e.mealType) == slot.name) e];

      // Ce qu'il y a eu dans l'assiette : une ligne, quoi que dise le plan.
      if (eaten.isNotEmpty) {
        final energy = eaten.fold<int>(0, (n, e) => n + e.calories);
        final title = eaten.map((e) => e.name).where((n) => n.isNotEmpty).join(', ');

        // Le plat prévu que ce repas a coché, quand il ne dit pas la même
        // chose : c'est le « Prévu · … » de la deuxième ligne.
        PlannedActivity? coche;
        for (final p in plans) {
          final id = p.mealData?.linkedFoodEntryId;
          if (id != null && eaten.any((e) => e.id == id)) {
            coche = p;
            break;
          }
        }
        final dish = coche?.mealData?.dishName ?? '';
        final note = dish.isEmpty || dish == title || plannedPrefix == null ? '' : '$plannedPrefix · $dish';

        lines.add((
          slot: slot,
          state: SlotState.done,
          title: title,
          detail: energy <= 0 ? '' : '$energy $kcal',
          note: note,
          workout: null,
          activity: coche,
        ));
      }

      // Ce qui reste prévu. Un plat coché dont le journal vient de parler
      // n'est pas une ligne de plus : il est déjà dit, au-dessus.
      for (final meal in plans) {
        if (!visible(meal.status)) continue;
        if (meal.status == PlannedStatus.completed && eaten.isNotEmpty) continue;
        final data = meal.mealData;
        final dish = (data?.dishName?.isNotEmpty ?? false) ? data!.dishName! : slotLabel(slot);
        final waiting = meal.status != PlannedStatus.completed;
        // « Prevu · Bol fromage blanc » : sans ce mot, la ligne du plan et
        // celle du journal se lisent comme deux repas contradictoires.
        final name = waiting && plannedPrefix != null ? '$plannedPrefix · $dish' : dish;
        final energy = data?.calories;
        lines.add((
          slot: slot,
          state: waiting ? SlotState.planned : SlotState.done,
          title: name,
          detail: energy == null || energy <= 0 ? '' : '$energy $kcal',
          note: '',
          workout: null,
          activity: meal,
        ));
      }
    }

    for (final w in day.workouts) {
      if (!visible(w.status)) continue;
      lines.add((
        slot: WeekSlot.sport,
        state: w.status == PlannedStatus.completed ? SlotState.done : SlotState.planned,
        title: w.workoutName,
        detail: w.exercises.isEmpty ? '' : '${w.exercises.length} $exercises',
        note: '',
        workout: w,
        activity: null,
      ));
    }
    for (final c in day.cardios) {
      if (!visible(c.status)) continue;
      final data = c.cardioData;
      lines.add((
        slot: WeekSlot.sport,
        state: c.status == PlannedStatus.completed ? SlotState.done : SlotState.planned,
        title: data?.activityName ?? '',
        detail: data?.targetMinutes == null ? '' : '${data!.targetMinutes} min',
        note: '',
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
