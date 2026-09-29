import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/arc/arc_intro_sheet.dart';
import 'package:ryze_app/arc/arc_state.dart';
import 'package:ryze_app/onboarding/widgets/hold_to_sign.dart';

/// Qui vient de signer le pacte de l'onboarding n'a pas à maintenir un second
/// bouton une minute plus tard ; les abonnés existants, si.
void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  final state = ArcState.fromJson({'phase': 'open', 'today': '2026-10-09', 'streak': 0, 'cells': '', 'eligible': true});

  Future<void> pump(WidgetTester tester, {required bool alreadyCommitted, ArcState? of}) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ArcIntroSheet(state: of ?? state, lang: 'fr', onRules: () {}, onCommitted: () {}, alreadyCommitted: alreadyCommitted),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('abonné existant : le geste à maintenir', (tester) async {
    await pump(tester, alreadyCommitted: false);
    expect(find.byType(HoldToSign), findsOneWidget);
    expect(find.text("Maintiens pour t'engager"), findsOneWidget);
  });

  testWidgets('au sortir de l\'onboarding : un simple bouton', (tester) async {
    await pump(tester, alreadyCommitted: true);
    expect(find.byType(HoldToSign), findsNothing);
    expect(find.text("C'est parti"), findsOneWidget);
  });

  testWidgets("avant l'ouverture : le jour 1 annoncé, et on s'engage déjà", (tester) async {
    final soon = ArcState.fromJson({'phase': 'soon', 'today': '2026-09-29', 'streak': 0, 'cells': '', 'eligible': true});
    expect(ArcIntroSheet.caseOf(soon), ArcIntroCase.soon);
    await pump(tester, alreadyCommitted: false, of: soon);
    expect(find.byType(HoldToSign), findsOneWidget);
    expect(find.text('Ton jour 1 : jeudi 1 octobre.'), findsOneWidget);
    // La bande finit le 29 décembre, 90 jours après le 1er octobre.
    expect(find.textContaining('29 déc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
