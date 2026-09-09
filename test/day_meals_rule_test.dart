import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/components/weekly_planner/week_strip.dart';
import 'package:ryze_app/home/home_slots.dart';
import 'package:ryze_app/models/weekly_planner_models.dart';

/// La règle qui vaut partout : le futur montre le plan, le passé montre ce
/// qui a eu lieu.
///
/// Les quatre écrans n'en disaient pas la même chose. La bande des jours
/// effaçait le prévu des jours passés, le panneau du jour le gardait, et
/// l'historique le montrait pour cette semaine et rien avant.
void main() {
  PlannedActivity repas({
    required PlannedStatus status,
    String nom = 'Saumon',
    int kcal = 400,
  }) =>
      PlannedActivity(
        id: 'a-$nom-${status.name}',
        userId: 'u',
        plannedDate: DateTime(2026, 9, 7),
        activityType: PlannedActivityType.lunch,
        status: status,
        activityData: {'dish_name': nom, 'calories': kcal},
        createdAt: DateTime(2026, 9, 6),
      );

  DayPlanData jour({required bool passe, required List<PlannedActivity> repas}) => DayPlanData(
        date: DateTime(2026, 9, 7),
        activities: repas,
        workouts: const [],
        isToday: !passe,
        isPast: passe,
      );

  List<PlannedLine> lignes(DayPlanData plan) => HomeSlots.linesOf(
        plan,
        slotLabel: (s) => s.name,
        kcal: 'kcal',
        exercises: 'exercices',
      );

  group('Un jour à venir', () {
    test('montre ce qui est prévu', () {
      final out = lignes(jour(passe: false, repas: [repas(status: PlannedStatus.planned)]));

      expect(out, hasLength(1));
      expect(out.single.state, SlotState.planned);
      expect(out.single.title, 'Saumon');
    });
  });

  group('Un jour passé', () {
    test('ne montre plus ce qui était prévu et n\'a pas eu lieu', () {
      final out = lignes(jour(passe: true, repas: [repas(status: PlannedStatus.planned)]));
      expect(out, isEmpty);
    });

    test('ni ce qui a été manqué', () {
      final out = lignes(jour(passe: true, repas: [repas(status: PlannedStatus.missed)]));
      expect(out, isEmpty);
    });

    test('mais garde ce qui a été fait', () {
      final out = lignes(jour(passe: true, repas: [repas(status: PlannedStatus.completed)]));

      expect(out, hasLength(1));
      expect(out.single.state, SlotState.done);
      expect(out.single.title, 'Saumon');
    });

    test('un jour mêlé ne garde que le fait', () {
      final out = lignes(jour(passe: true, repas: [
        repas(status: PlannedStatus.completed, nom: 'Poulet'),
        repas(status: PlannedStatus.planned, nom: 'Salade'),
      ]));

      expect(out.map((l) => l.title), ['Poulet']);
    });
  });
}
