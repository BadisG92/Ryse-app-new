import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/models/openfoodfacts_models.dart';

/// L'unité d'un produit scanné, ramenée à celles que l'app sait manipuler.
///
/// OpenFoodFacts écrit la quantité en toutes lettres. Seul « ml » était reconnu
/// comme un liquide : un lait d'amande vendu au litre revenait en grammes, et
/// partait dans les aliments personnels avec « l » comme unité de référence.
OpenFoodFactsProduct withQuantity(String? q) =>
    OpenFoodFactsProduct(status: 1, quantity: q);

void main() {
  test('un litre est un liquide', () {
    expect(withQuantity('1 l').unit, 'ml');
    expect(withQuantity('1l').unit, 'ml');
    expect(withQuantity('33 cl').unit, 'ml');
    expect(withQuantity('50 dl').unit, 'ml');
    expect(withQuantity('250 ml').unit, 'ml');
  });

  test('un solide reste en grammes', () {
    expect(withQuantity('170g').unit, 'g');
    expect(withQuantity('41,5 g e').unit, 'g');
    expect(withQuantity('1 kg').unit, 'g');
  });

  test('ce qu’on ne sait pas lire retombe sur le gramme', () {
    expect(withQuantity(null).unit, 'g');
    expect(withQuantity('6 pièces').unit, 'g');
    expect(withQuantity('').unit, 'g');
  });
}
