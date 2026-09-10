import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ryze_app/design/day_instrument.dart';

/// Le plus gros chiffre de l'écran et sa légende doivent parler la même langue.
///
/// L'instrument mettait son chiffre en forme d'après `Localizations.localeOf`,
/// c'est-à-dire d'après Flutter — et `MaterialApp` n'avait alors ni `locale` ni
/// `supportedLocales`, donc Flutter répondait `en_US` partout. En français on
/// lisait « 1,334 kcal » — une virgule décimale, soit 1,334 kilocalorie —
/// au-dessus d'« objectif 1 334 », mis en forme, lui, dans la bonne langue.
///
/// L'app a maintenant une locale, mais le chiffre ne doit toujours pas en
/// dépendre : c'est la langue du compte qui décide, pas celle du téléphone.
///
/// L'odomètre découpe le nombre en séries de chiffres et pose les séparateurs
/// entre elles, chacun dans son propre `Text` : c'est ce séparateur qu'on
/// interroge, parce que c'est lui qui portait le mensonge.
void main() {
  /// Ce que `NumberFormat` met entre les milliers et les centaines : virgule en
  /// anglais, point en allemand, espace insécable étroite en français.
  String separatorOf(String lang) => NumberFormat.decimalPattern(lang).format(1334).replaceAll(RegExp(r'\d'), '');

  Future<void> pump(WidgetTester tester, String lang) async {
    final numbers = NumberFormat.decimalPattern(lang);
    await tester.pumpWidget(
      MaterialApp(
        // Sans délégué ni locale : si quelqu'un rebranche le chiffre sur la
        // locale de Flutter, le test le dira.
        home: Scaffold(
          body: DayInstrument(
            lang: lang,
            lead: 'reste',
            unit: 'kcal',
            eatenLabel: 'mangé ${numbers.format(666)}',
            goalLabel: 'objectif ${numbers.format(2000)}',
            calories: 666,
            calorieGoal: 2000,
            shown: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('le chiffre suit la langue de l’app, pas celle de Flutter', (tester) async {
    await pump(tester, 'fr');
    final sep = separatorOf('fr');

    expect(find.text(sep), findsOneWidget, reason: 'le 1 et les 334 sont séparés à la française');
    expect(find.text(','), findsNothing, reason: 'une virgule ici se lirait comme une décimale');
    expect(find.textContaining('objectif'), findsOneWidget);
    // la légende et le chiffre portent le même séparateur : c'est tout le sujet
    expect(find.textContaining(sep), findsWidgets);
  });

  testWidgets('en anglais, la virgule des milliers reste la bonne', (tester) async {
    await pump(tester, 'en');
    expect(find.text(','), findsOneWidget);
  });

  testWidgets('en allemand, c’est un point', (tester) async {
    await pump(tester, 'de');
    expect(find.text('.'), findsOneWidget);
  });
}
