import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/components/weekly_planner/week_strip.dart';
import 'package:ryze_app/models/nutrition_models.dart' as nutrition;
import 'package:ryze_app/services/day_meals.dart';

/// Valider un repas prévu ne l'écrit pas deux fois.
///
/// La validation note exactement le plat prévu : la rangée affichait
/// « Protein Power Oats », puis « Prévu · Protein Power Oats » juste en
/// dessous. Le même plat, deux lignes, comme si le plan restait à faire.
void main() {
  DayMeal repas({String? prevu, List<String> notes = const []}) => DayMeal(
        slot: WeekSlot.breakfast,
        state: notes.isEmpty ? (prevu == null ? SlotState.empty : SlotState.planned) : SlotState.done,
        at: DateTime(2026, 9, 10, 8),
        plannedName: prevu,
        logged: notes.isEmpty
            ? null
            : nutrition.Meal(
                time: '8 h',
                name: 'Petit-déj',
                items: [for (final n in notes) nutrition.FoodItem(name: n, calories: 300, portion: '100 g')],
              ),
      );

  test('validé : le plan ne se répète pas', () {
    expect(repas(prevu: 'Protein Power Oats', notes: const ['Protein Power Oats']).plannedApart, isFalse);
  });

  test('mangé autre chose : le plan reste une chose à part', () {
    expect(repas(prevu: 'Protein Power Oats', notes: const ['Poke bowl au saumon']).plannedApart, isTrue);
  });

  test('rien de noté : le plan est tout ce qu’il y a', () {
    expect(repas(prevu: 'Protein Power Oats').plannedApart, isTrue);
  });

  test('pas de plan, rien à part', () {
    expect(repas(notes: const ['Poke bowl']).plannedApart, isFalse);
    expect(repas().plannedApart, isFalse);
    expect(repas(prevu: '   ').plannedApart, isFalse);
  });

  test('plusieurs aliments notés : la liste fait le nom', () {
    expect(repas(prevu: 'Poulet, riz', notes: const ['Poulet', 'riz']).plannedApart, isFalse);
    expect(repas(prevu: 'Poulet, riz', notes: const ['Poulet']).plannedApart, isTrue);
  });
}
