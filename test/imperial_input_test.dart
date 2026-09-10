import 'package:flutter_test/flutter_test.dart';

/// Ce qu'on tape est dans l'unité qu'on lit.
///
/// Le pavé de la séance écrivait le nombre tapé directement dans `weightKg` :
/// en impérial, 45 devenait 45 kilos, et la rangée réaffichait 99,2 lbs juste
/// au-dessus du pavé qui venait de recevoir 45.
const double kgPerLb = 2.20462;

double toKg(double shown, {required bool metric}) => metric ? shown : shown / kgPerLb;
double shownOf(double kg, {required bool metric}) => metric ? kg : kg * kgPerLb;
double roundShown(double v, {required bool metric}) => metric ? (v * 4).round() / 4 : (v * 2).round() / 2;

void main() {
  test('45 tapé en impérial, ce sont 45 livres', () {
    final kg = toKg(45, metric: false);
    expect(kg, closeTo(20.41, 0.01));
    expect(shownOf(kg, metric: false), closeTo(45, 0.01));
  });

  test('45 tapé en métrique, ce sont 45 kilos', () {
    expect(toKg(45, metric: true), 45);
  });

  test('« +5 » ajoute cinq livres, pas onze', () {
    final start = toKg(45, metric: false);
    final next = toKg(roundShown(shownOf(start, metric: false) + 5, metric: false), metric: false);
    expect(shownOf(next, metric: false), closeTo(50, 0.01));
  });

  test('« +2,5 » en métrique ajoute deux kilos et demi', () {
    final next = toKg(roundShown(shownOf(30, metric: true) + 2.5, metric: true), metric: true);
    expect(next, closeTo(32.5, 0.001));
  });

  test('un pouce vaut 2,54 cm : le pas de la taille bouge le chiffre lu', () {
    const cm = 175.0;
    expect(((cm + 2.54) / 2.54).round() - (cm / 2.54).round(), 1);
    // un pas d'un centimètre ne bougeait pas le pouce affiché
    expect(((cm + 1) / 2.54).round() - (cm / 2.54).round(), 0);
  });
}
