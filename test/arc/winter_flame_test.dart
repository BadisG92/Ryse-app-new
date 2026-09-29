import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  testWidgets('la pastille prend la flamme de glace pendant la saison, l\'ambre sinon', (tester) async {
    Widget pill(bool winter) => MaterialApp(home: Center(child: StreakPill(lang: 'fr', streak: 12, winter: winter)));

    await tester.pumpWidget(pill(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(WinterFlame), findsOneWidget);
    expect(find.text('12 jours'), findsOneWidget);

    await tester.pumpWidget(pill(false));
    expect(find.byType(WinterFlame), findsNothing);
    expect(find.byIcon(LucideIcons.flame), findsOneWidget);
  });
}
