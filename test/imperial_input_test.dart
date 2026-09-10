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

  _gym();
}

/// Les poids que Ryze propose doivent exister sur des disques.
///
/// L'arrondi se faisait au multiple de 2,5 kg quelle que soit l'unité : une
/// suggestion tombait donc sur 5,5 ou 16,5 livres. Dans une salle américaine,
/// la barre fait 45 livres et les disques 45, 35, 25, 10, 5 et 2,5.
double gymWeight(double kg, {required bool metric}) {
  if (kg <= 0) return 0;
  if (metric) return (kg / 2.5).round() * 2.5;
  final pounds = (kg * kgPerLb / 5).round() * 5;
  return pounds / kgPerLb;
}

String weightText(double kg, {required bool metric, String lang = 'fr'}) {
  final shown = metric ? kg : kg * kgPerLb;
  final rounded = (shown * 10).round() / 10;
  final text = rounded.truncateToDouble() == rounded ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1);
  return lang == 'en' ? text : text.replaceAll('.', ',');
}

void _gym() {
  group('les poids proposés', () {
    test('en impérial, ils tombent sur des multiples de cinq livres', () {
      for (final kg in [10.0, 16.4, 20.0, 42.0, 60.0]) {
        final snapped = gymWeight(kg, metric: false);
        expect((snapped * kgPerLb / 5) % 1, closeTo(0, 0.0001), reason: '$kg kg');
      }
    });

    test('vingt kilos proposés se chargent en 45 livres', () {
      expect(weightText(gymWeight(20, metric: false), metric: false), '45');
    });

    test('en métrique, le pas reste le disque de 2,5 kg', () {
      expect(gymWeight(16.4, metric: true), 17.5);
      expect(gymWeight(19.0, metric: true), 20.0);
    });

    test('plus de décimale qui ne dit rien', () {
      // 45 livres rangées en kilos puis relues donnent 44,99999
      expect(weightText(45 / kgPerLb, metric: false), '45');
      expect(weightText(30, metric: true), '30');
      expect(weightText(62.5, metric: true), '62,5');
      expect(weightText(62.5, metric: true, lang: 'en'), '62.5');
    });
  });
}
