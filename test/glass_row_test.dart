import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

/// Un verre garde ses proportions, quel que soit leur nombre.
///
/// Seule la largeur s'adaptait : les verres se partagent la rangée, mais la
/// hauteur était fixe. À huit — deux litres — la silhouette est juste ; à
/// douze — trois litres — chacun devenait deux fois plus haut que large.
double glassWidth(double row, double gap, int count) => (row - gap * (count - 1)) / count;
double glassHeight(double width, double maxHeight) => math.min(width * 1.27, maxHeight);

void main() {
  // un iPhone : la rangée fait environ 90 % de la largeur, gouttières déduites
  const row = 351.0; // 390 - 2 x 19.5
  const gap = 7.0; // 1,8 vw
  const maxHeight = 48.0; // 12,3 vw

  double ratio(int count) {
    final w = glassWidth(row, gap, count);
    return glassHeight(w, maxHeight) / w;
  }

  test('à huit verres, rien ne change', () {
    final w = glassWidth(row, gap, 8);
    expect(glassHeight(w, maxHeight), closeTo(maxHeight, 0.5), reason: 'la hauteur d’avant est conservée');
  });

  test('à douze verres, le verre n’est plus une lamelle', () {
    // avant : hauteur fixe de 48 pour une largeur de 22 → deux fois plus haut
    final w = glassWidth(row, gap, 12);
    expect(maxHeight / w, greaterThan(1.9), reason: 'ce que ça donnait avant');
    expect(ratio(12), closeTo(1.27, 0.01), reason: 'ce que ça donne maintenant');
  });

  test('la proportion ne dépasse jamais celle de huit verres', () {
    for (final n in [4, 6, 8, 10, 12]) {
      expect(ratio(n), lessThanOrEqualTo(1.28), reason: '$n verres');
    }
  });
}
