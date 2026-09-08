import 'package:flutter/foundation.dart';

import 'mlkit_barcode_service.dart';

/// Lire un code-barres.
///
/// Il y avait ici un aiguillage entre deux méthodes : ML Kit, sur l'appareil,
/// gratuit et hors ligne, et Google Cloud Vision, dans le nuage et facturé.
/// L'aiguillage était sur ML Kit depuis le début et rien ne le rebasculait
/// nulle part ; la branche Vision ne servait plus qu'à garder une seconde clé
/// d'API vivante dans le binaire. Elle est partie, la clé avec.
///
/// Ce qui suit le code-barres, la recherche du produit, passe par
/// OpenFoodFacts, qui est public et ne demande aucune clé.
class UnifiedBarcodeService {
  UnifiedBarcodeService._();

  /// Détecter un code-barres dans une image, sur l'appareil.
  static Future<String?> detectBarcode(String imagePath) {
    if (kDebugMode) debugPrint('🔍 [BARCODE] Détection sur l\'appareil...');
    return MLKitBarcodeService.detectBarcode(imagePath);
  }

  /// Libérer les ressources
  static void dispose() => MLKitBarcodeService.dispose();
}
