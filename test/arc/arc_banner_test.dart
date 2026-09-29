import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/arc/arc_banner.dart';
import 'package:ryze_app/arc/arc_state.dart';

ArcState _state({String cells = 'hhp', int streak = 2, bool held = false, Map<String, dynamic>? grace, String today = '2026-10-12'}) =>
    ArcState.fromJson({
      'phase': 'open',
      'today': today,
      'streak': streak,
      'streak_start': '2026-10-10',
      'cells': cells,
      'eligible': true,
      'best': streak,
      'today_status': {'held': held, 'meals': held ? 2 : 1, 'water_ml': 2000, 'water_goal': 2000, 'trained': false},
      'grace': grace,
    });

const _grace = {'day': '2026-10-11', 'meals': 1, 'water_ml': 2000, 'water_goal': 2000, 'deadline': '2026-10-12T10:00:00Z'};

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('Le moment où la journée est validée', () {
    test("le repas qui manquait : aujourd'hui vient d'être validé", () {
      final before = _state();
      final after = _state(cells: 'hhh', streak: 3, held: true);
      expect(ArcBanner.detect(before, after), ArcValidated.today);
    });

    test('hier rattrapé avant midi', () {
      final before = _state(cells: 'hhpp', grace: _grace);
      final after = _state(cells: 'hhhp', streak: 3);
      expect(ArcBanner.detect(before, after), ArcValidated.yesterday);
    });

    test("rien à dire : déjà validée, premier état connu, ou un autre jour", () {
      final held = _state(cells: 'hhh', streak: 3, held: true);
      expect(ArcBanner.detect(held, held), isNull);
      expect(ArcBanner.detect(null, held), isNull);
      expect(ArcBanner.detect(_state(today: '2026-10-11'), held), isNull);
    });

    test('les mots : le jour, et ce qui reste', () {
      final after = _state(cells: 'hhh', streak: 3, held: true);
      expect(ArcBanner.words(ArcValidated.today, after, 'fr'), ('Jour 3 validé', 'Plus que 87 jours.'));
      expect(ArcBanner.words(ArcValidated.today, after, 'en'), ('Day 3 locked in', '87 days to go.'));
      expect(ArcBanner.words(ArcValidated.yesterday, _state(cells: 'hhhp', streak: 3), 'fr'), ('Hier validé', 'Ta série continue : 3 jours.'));
    });
  });

  testWidgets("le bandeau tient sur un petit téléphone et s'en va seul", (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    }))));
    final after = _state(cells: 'hhh', streak: 3, held: true);
    ArcBanner.show(ctx, ArcValidated.today, after);
    await tester.pump(const Duration(milliseconds: 400));
    // La langue de l'app, le français par défaut.
    expect(find.text('Jour 3 validé'), findsOneWidget);
    expect(find.text('Plus que 87 jours.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(ArcBanner.life);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Jour 3 validé'), findsNothing);
  });
}
