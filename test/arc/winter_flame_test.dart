import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ryze_app/arc/arc_state.dart';
import 'package:ryze_app/arc/streak_pill.dart';
import 'package:ryze_app/arc/winter_flame.dart';

void main() {
  testWidgets('la flamme se tient immobile quand le téléphone réduit les animations', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Center(child: WinterFlame(size: 120)),
    ));
    // Une flamme qui bougerait encore empêcherait tout calme.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('elle vit sinon, et se dessine à chaque instant de la boucle', (tester) async {
    await tester.pumpWidget(const Center(child: WinterFlame(size: 120)));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.hasRunningAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });

  group('Les deux flammes', () {
    final arc = ArcState.fromJson({'phase': 'open', 'today': '2026-10-10', 'streak': 3, 'cells': 'hhhp', 'eligible': true});

    Future<void> pump(WidgetTester tester, Widget pills) async {
      await tester.pumpWidget(MaterialApp(home: Center(child: pills)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('une flamme tenue avant le 1er octobre reste à côté de celle de l\'arc', (tester) async {
      await pump(tester, StreakPills(lang: 'fr', streak: 25, streakStart: DateTime(2026, 9, 16), arc: arc, today: DateTime(2026, 10, 10)));
      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.byType(WinterFlame), findsOneWidget);
      // Côte à côte, chacune ne montre que son nombre.
      expect(find.text('25'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('une flamme née pendant la saison ne s\'affiche pas : seule celle de l\'arc', (tester) async {
      await pump(tester, StreakPills(lang: 'fr', streak: 9, streakStart: DateTime(2026, 10, 2), arc: arc, today: DateTime(2026, 10, 10)));
      expect(find.byIcon(LucideIcons.flame), findsNothing);
      expect(find.byType(WinterFlame), findsOneWidget);
      expect(find.text('3 jours'), findsOneWidget);
    });

    testWidgets('avant la saison, la flamme normale seule, comme avant', (tester) async {
      await pump(tester, StreakPills(lang: 'fr', streak: 5, streakStart: DateTime(2026, 9, 25), today: DateTime(2026, 9, 29)));
      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.byType(WinterFlame), findsNothing);
      expect(find.text('5 jours'), findsOneWidget);
    });
  });
}
