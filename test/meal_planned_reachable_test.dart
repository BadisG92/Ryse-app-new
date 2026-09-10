import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/components/weekly_planner/week_strip.dart';
import 'package:ryze_app/design/meal_timeline.dart';
import 'package:ryze_app/models/nutrition_models.dart' as nutrition;
import 'package:ryze_app/services/day_meals.dart';

/// Un repas noté garde une porte vers ce qui était prévu.
///
/// La rangée s'est mise à distinguer deux gestes — le « + » ajoute, la ligne
/// ouvre le plat prévu — mais le repas une fois noté, la ligne entière passait
/// à déplier le journal : « Prévu · Bol d'avoine et fruits » restait écrit
/// sous le repas sans mener nulle part.
void main() {
  DayMeals journee({required bool fait, String? prevu}) {
    final repas = DayMeal(
      slot: WeekSlot.breakfast,
      state: fait ? SlotState.done : (prevu == null ? SlotState.empty : SlotState.planned),
      at: DateTime(2026, 9, 10, 17, 3),
      plannedName: prevu,
      logged: fait
          ? nutrition.Meal(
              time: '17 h 03',
              name: 'Petit-déj',
              items: [nutrition.FoodItem(name: 'Poke bowl au saumon', calories: 934, portion: '780 g')],
            )
          : null,
    );
    return DayMeals.of(DateTime(2026, 9, 10), {WeekSlot.breakfast: repas});
  }

  Future<List<String>> gestes(WidgetTester tester, {required bool fait, String? prevu, bool porte = true}) async {
    final out = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MealTimeline(
              day: journee(fait: fait, prevu: prevu),
              labelOf: (slot) => 'repas-${slot.name}',
              hourOf: (_) => '8 h',
              plannedPrefix: 'Prévu',
              nothingLogged: 'Rien d’enregistré',
              addLabel: 'Ajouter un aliment',
              open: const {},
              onToggle: (_) => out.add('toggle'),
              onAdd: (_) => out.add('add'),
              onOpen: porte ? (_) => out.add('open') : null,
              onRemoveItem: (_, __) {},
            ),
          ),
        ),
      ),
    );
    return out;
  }

  testWidgets('un repas noté qui suivait un plan ouvre encore le plan', (tester) async {
    final out = await gestes(tester, fait: true, prevu: 'Bol d’avoine et fruits');

    await tester.tap(find.text('Prévu · Bol d’avoine et fruits'));
    await tester.pump();

    expect(out, ['open'], reason: 'la ligne du prévu ouvre la feuille, elle ne déplie pas le journal');
  });

  testWidgets('le reste de la rangée déplie toujours le repas', (tester) async {
    final out = await gestes(tester, fait: true, prevu: 'Bol d’avoine et fruits');

    await tester.tap(find.text('repas-breakfast'));
    await tester.pump();

    expect(out, ['toggle']);
  });

  testWidgets('sans plan, rien ne change', (tester) async {
    final out = await gestes(tester, fait: true);

    await tester.tap(find.text('repas-breakfast'));
    await tester.pump();

    expect(out, ['toggle']);
    expect(find.textContaining('Prévu'), findsNothing);
  });

  testWidgets('sans porte, la ligne du prévu ne prend pas le tap', (tester) async {
    // L'historique n'ouvrait pas de feuille : la rangée doit rester entière.
    final out = await gestes(tester, fait: true, prevu: 'Bol d’avoine et fruits', porte: false);

    await tester.tap(find.text('Prévu · Bol d’avoine et fruits'));
    await tester.pump();

    expect(out, ['toggle']);
  });

  testWidgets('un repas seulement prévu ouvre par sa ligne', (tester) async {
    final out = await gestes(tester, fait: false, prevu: 'Bol d’avoine et fruits');

    await tester.tap(find.text('repas-breakfast'));
    await tester.pump();

    expect(out, ['open']);
  });
}
