import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/components/weekly_planner/week_strip.dart';
import 'package:ryze_app/home/home_slots.dart';
import 'package:ryze_app/models/weekly_planner_models.dart';

/// Sur l'accueil, la ligne d'un repas dit ce qui a été mangé.
///
/// Noter un aliment sur un créneau déjà prévu coche le plat prévu et le relie
/// à l'aliment. La ligne se construisait depuis le plan : l'accueil annonçait
/// « Bol d'avoine et fruits · 505 kcal » pour un poke bowl à 934, et le plat
/// vraiment mangé n'apparaissait nulle part.
void main() {
  PlannedActivity prevu({
    required String plat,
    required int kcal,
    required PlannedStatus status,
    String? lie,
  }) =>
      PlannedActivity(
        id: 'a-$plat',
        userId: 'u',
        plannedDate: DateTime(2026, 9, 10),
        activityType: PlannedActivityType.breakfast,
        status: status,
        activityData: {
          'dish_name': plat,
          'calories': kcal,
          if (lie != null) 'linked_food_entry_id': lie,
        },
        createdAt: DateTime(2026, 9, 9),
      );

  JournalFoodEntry mange({required String id, required String nom, required int kcal}) => JournalFoodEntry(
        id: id,
        name: nom,
        mealType: 'breakfast',
        calories: kcal,
        proteins: 0,
        carbs: 0,
        fats: 0,
        quantity: 780,
        unit: 'g',
        consumedAt: DateTime(2026, 9, 10, 17, 3),
      );

  DayPlanData jour({List<PlannedActivity> plans = const [], List<JournalFoodEntry> journal = const []}) => DayPlanData(
        date: DateTime(2026, 9, 10),
        activities: plans,
        workouts: const [],
        journalEntries: journal,
        eatenMealTypes: {for (final e in journal) e.mealType},
        isToday: true,
        isPast: false,
      );

  List<PlannedLine> lignes(DayPlanData plan) => HomeSlots.linesOf(
        plan,
        slotLabel: (s) => s.name,
        kcal: 'kcal',
        exercises: 'exercices',
        plannedPrefix: 'Prévu',
      );

  test('un repas mangé à côté du plan montre le repas, et le plan en dessous', () {
    final out = lignes(jour(
      plans: [prevu(plat: 'Bol d’avoine et fruits', kcal: 505, status: PlannedStatus.completed, lie: 'e1')],
      journal: [mange(id: 'e1', nom: 'Poke bowl au saumon', kcal: 934)],
    ));

    expect(out, hasLength(1), reason: 'un seul repas a été mangé, donc une seule ligne');
    expect(out.single.title, 'Poke bowl au saumon');
    expect(out.single.detail, '934 kcal', reason: 'les calories sont celles du journal, pas celles du plan');
    expect(out.single.note, 'Prévu · Bol d’avoine et fruits');
    expect(out.single.state, SlotState.done);
    expect(out.single.activity, isNotNull, reason: 'la ligne ouvre le plat prévu qu’elle a coché');
  });

  test('un repas conforme au plan ne se répète pas', () {
    final out = lignes(jour(
      plans: [prevu(plat: 'Bol d’avoine et fruits', kcal: 505, status: PlannedStatus.completed, lie: 'e1')],
      journal: [mange(id: 'e1', nom: 'Bol d’avoine et fruits', kcal: 505)],
    ));

    expect(out, hasLength(1));
    expect(out.single.title, 'Bol d’avoine et fruits');
    expect(out.single.note, isEmpty, reason: 'le plan dit la même chose : rien à ajouter');
  });

  test('un repas noté sans plan reste une seule ligne', () {
    // Le journal crée son reflet dans le planificateur : sans garde, le même
    // repas s'afficherait deux fois.
    final out = lignes(jour(
      plans: [prevu(plat: 'Poke bowl au saumon', kcal: 934, status: PlannedStatus.completed, lie: 'e1')],
      journal: [mange(id: 'e1', nom: 'Poke bowl au saumon', kcal: 934)],
    ));

    expect(out, hasLength(1));
    expect(out.single.detail, '934 kcal');
  });

  test('un repas prévu et pas encore mangé garde sa ligne', () {
    final out = lignes(jour(plans: [prevu(plat: 'Cabillaud', kcal: 600, status: PlannedStatus.planned)]));

    expect(out, hasLength(1));
    expect(out.single.title, 'Prévu · Cabillaud');
    expect(out.single.detail, '600 kcal');
    expect(out.single.state, SlotState.planned);
    expect(out.single.note, isEmpty);
  });

  test('mangé plus tôt, un autre plat prévu attend encore', () {
    final out = lignes(jour(
      plans: [
        prevu(plat: 'Bol d’avoine et fruits', kcal: 505, status: PlannedStatus.completed, lie: 'e1'),
        prevu(plat: 'Pancakes', kcal: 300, status: PlannedStatus.planned),
      ],
      journal: [mange(id: 'e1', nom: 'Poke bowl au saumon', kcal: 934)],
    ));

    expect(out, hasLength(2));
    expect(out.first.title, 'Poke bowl au saumon', reason: 'ce qui a eu lieu passe devant');
    expect(out.last.title, 'Prévu · Pancakes');
  });
}
