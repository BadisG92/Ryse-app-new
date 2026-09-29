import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/arc/arc_grid.dart';
import 'package:ryze_app/arc/arc_home_card.dart';
import 'package:ryze_app/arc/arc_intro_sheet.dart';
import 'package:ryze_app/arc/arc_page.dart';
import 'package:ryze_app/arc/arc_state.dart';

/// L'écran et la carte de l'accueil, rendus sans base, du plus petit
/// téléphone au plus grand et dans la langue la plus longue : rien ne doit
/// déborder.
void main() {
  setUpAll(() async {
    for (final l in ['fr', 'en', 'de']) {
      await initializeDateFormatting(l);
    }
  });

  final states = <String, ArcState>{
    'en cours, hier à rattraper, un joker': ArcState.fromJson({
      'phase': 'open',
      'today': '2026-11-10',
      'streak': 38,
      'streak_start': '2026-10-02',
      'cells': '${'h' * 20}t${'h' * 9}j${'h' * 8}pp',
      'jokers': 1,
      'best': 38,
      'eligible': true,
      'last_valid': '2026-11-08',
      'today_status': {'held': false, 'meals': 0, 'water_ml': 250, 'water_goal': 2750, 'trained': false},
      'grace': {'day': '2026-11-09', 'meals': 1, 'water_ml': 900, 'water_goal': 2750, 'deadline': '2026-11-10T11:00:00Z'},
    }),
    'avant l\'ouverture': ArcState.fromJson({'phase': 'soon', 'today': '2026-09-29', 'streak': 0, 'cells': '', 'eligible': true}),
    'sans série': ArcState.fromJson({
      'phase': 'open',
      'today': '2026-10-03',
      'streak': 0,
      'cells': '',
      'eligible': true,
      'today_status': {'held': false, 'meals': 1, 'water_ml': 0, 'water_goal': 2000, 'trained': false},
    }),
    'gagné': ArcState.fromJson({
      'phase': 'open',
      'today': '2026-12-30',
      'streak': 91,
      'streak_start': '2026-10-01',
      'cells': 't' * 91,
      'jokers': 2,
      'best': 91,
      'won_on': '2026-12-29',
      'eligible': false,
      'today_status': {'held': true, 'meals': 3, 'water_ml': 2000, 'water_goal': 2000, 'trained': true},
    }),
  };

  for (final size in const [Size(320, 640), Size(430, 932)]) {
    for (final lang in const ['de', 'fr', 'en']) {
      for (final entry in states.entries) {
        testWidgets('${size.width.toInt()} pt, $lang, ${entry.key}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ArcHomeCard(state: entry.value, lang: lang),
                    const SizedBox(height: 24),
                    ArcPageBody(state: entry.value, lang: lang),
                    const SizedBox(height: 24),
                    ArcIntroSheet(state: entry.value, lang: lang, onRules: () {}, onCommitted: () {}),
                  ],
                ),
              ),
            ),
          ));
          // La flamme de glace vit en boucle : on avance le temps au-delà
          // des entrées de la page au lieu d'attendre un calme qui ne vient
          // jamais.
          await tester.pump(const Duration(seconds: 3));
          expect(tester.takeException(), isNull);
          expect(find.byType(ArcGrid), findsNWidgets(3));
          // Le retour haptique de fin d'entrée laisse un court délai derrière lui.
          await tester.pump(const Duration(milliseconds: 300));
        });
      }
    }
  }
}
