import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';
import 'mlkit_barcode_service.dart';
import 'barcode_detection_service.dart';

/// Service unifié de détection de code-barres avec switch ML Kit / Vision API
///
/// CONFIGURATION SIMPLE:
/// - Pour activer ML Kit (nouveau, recommandé): useMLKit = true
/// - Pour revenir à Vision API (ancien, stable): useMLKit = false
///
/// ROLLBACK: Si ML Kit ne fonctionne pas, changez simplement useMLKit à false
class UnifiedBarcodeService {
  /// ⚙️ CONFIGURATION PRINCIPALE - Changer cette valeur pour switch entre les deux méthodes
  ///
  /// true  = ML Kit (nouveau, gratuit, offline, rapide)
  /// false = Google Vision API (ancien, payant, cloud, stable)
  ///
  /// ROLLBACK: Mettre à false pour revenir à l'ancienne méthode
  static bool useMLKit = true; // ✅ ACTIVÉ - ML Kit est maintenant utilisé par défaut

  /// Détecter un code-barres (méthode unique avec switch)
  ///
  /// Paramètres:
  /// - imagePath: chemin vers l'image à scanner
  ///
  /// Retourne: le code-barres détecté ou null
  static Future<String?> detectBarcode(String imagePath) async {
    if (kDebugMode) {
      debugPrint('🔍 [BARCODE] Début détection...');
      debugPrint('   Méthode: ${useMLKit ? "ML Kit (nouveau)" : "Vision API (ancien)"}');
    }

    if (useMLKit) {
      // Nouvelle méthode : ML Kit
      return await _detectWithMlKit(imagePath);
    } else {
      // Ancienne méthode : Vision API (stable)
      return await _detectWithVisionApi(imagePath);
    }
  }

  /// Détecter avec ML Kit (on-device, gratuit, rapide)
  static Future<String?> _detectWithMlKit(String imagePath) async {
    if (kDebugMode) debugPrint('📱 [ML KIT] Détection en cours...');
    return await MLKitBarcodeService.detectBarcode(imagePath);
  }

  /// Détecter avec Vision API (cloud, payant, stable)
  static Future<String?> _detectWithVisionApi(String imagePath) async {
    try {
      if (kDebugMode) debugPrint('📡 [VISION API] Détection en cours...');

      // Lire l'image en bytes
      final imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Appeler l'ancien service
      final result = await BarcodeDetectionService.detectBarcode(imageBytes);

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [VISION API] Erreur: $e');
      return null;
    }
  }

  /// Libérer les ressources
  static void dispose() {
    MLKitBarcodeService.dispose();
  }
}
