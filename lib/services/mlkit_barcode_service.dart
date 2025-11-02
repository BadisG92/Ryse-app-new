import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Service de détection de code-barres avec ML Kit (on-device)
/// Remplace barcode_detection_service.dart (Google Vision API cloud)
///
/// AVANTAGES:
/// - 100% gratuit (pas de coût API)
/// - Fonctionne offline
/// - Plus rapide (< 0.5s vs 2-3s)
/// - Plus précis pour les codes-barres
///
/// ROLLBACK: Si ce service ne fonctionne pas, voir barcode_detection_service.dart (ancien)
class MLKitBarcodeService {

  /// Scanner configuré pour les codes-barres alimentaires
  static BarcodeScanner? _scanner;

  /// Obtenir l'instance du scanner (lazy initialization)
  static BarcodeScanner get scanner {
    _scanner ??= BarcodeScanner(
      formats: [
        BarcodeFormat.ean13,    // Europe (standard)
        BarcodeFormat.ean8,     // Europe (petit format)
        BarcodeFormat.upca,     // USA/Canada (minuscule dans v0.14)
        BarcodeFormat.upce,     // USA/Canada compact (minuscule dans v0.14)
      ],
    );
    return _scanner!;
  }

  /// Détecter un code-barres dans une image (path)
  /// Retourne le code-barres (String) ou null si aucun trouvé
  static Future<String?> detectBarcode(String imagePath) async {
    try {
      if (kDebugMode) debugPrint('🔍 [ML KIT] Début détection code-barres...');

      // Créer InputImage depuis le path
      final inputImage = InputImage.fromFilePath(imagePath);

      // Scanner l'image
      final List<Barcode> barcodes = await scanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        if (kDebugMode) debugPrint('⚠️ [ML KIT] Aucun code-barres détecté');
        return null;
      }

      // Prendre le premier code-barres trouvé
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null) {
        if (kDebugMode) {
          debugPrint('✅ [ML KIT] Code-barres trouvé: $code (type: ${barcode.format.name})');
        }

        // Validation optionnelle du checksum
        if (_isValidBarcode(code, barcode.format)) {
          if (kDebugMode) debugPrint('✓ Checksum valide');
        } else {
          if (kDebugMode) debugPrint('⚠️ Checksum invalide (retourné quand même)');
          // Retourner quand même, OpenFoodFacts validera
        }

        return code;
      }

      return null;

    } catch (e) {
      if (kDebugMode) debugPrint('❌ [ML KIT] Erreur détection: $e');
      rethrow; // Propager l'erreur pour que le service unifié puisse faire un fallback
    }
  }

  /// Valider le checksum d'un code-barres
  static bool _isValidBarcode(String code, BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return _validateEAN13Checksum(code);
      case BarcodeFormat.ean8:
        return _validateEAN8Checksum(code);
      case BarcodeFormat.upca:
        return _validateUPCAChecksum(code);
      default:
        return true; // Pas de validation pour les autres formats
    }
  }

  /// Valider le checksum d'un code EAN-13
  /// Algorithme : somme alternée * 1 et * 3, le dernier chiffre doit faire un total divisible par 10
  static bool _validateEAN13Checksum(String code) {
    if (code.length != 13) return false;
    try {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(code[i]);
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      int checkDigit = int.parse(code[12]);
      int calculatedCheck = (10 - (sum % 10)) % 10;
      return checkDigit == calculatedCheck;
    } catch (e) {
      return false;
    }
  }

  /// Valider le checksum d'un code EAN-8
  static bool _validateEAN8Checksum(String code) {
    if (code.length != 8) return false;
    try {
      int sum = 0;
      for (int i = 0; i < 7; i++) {
        int digit = int.parse(code[i]);
        sum += (i % 2 == 0) ? digit * 3 : digit;
      }
      int checkDigit = int.parse(code[7]);
      int calculatedCheck = (10 - (sum % 10)) % 10;
      return checkDigit == calculatedCheck;
    } catch (e) {
      return false;
    }
  }

  /// Valider le checksum d'un code UPC-A (12 chiffres)
  static bool _validateUPCAChecksum(String code) {
    if (code.length != 12) return false;
    try {
      int sum = 0;
      for (int i = 0; i < 11; i++) {
        int digit = int.parse(code[i]);
        sum += (i % 2 == 0) ? digit * 3 : digit;
      }
      int checkDigit = int.parse(code[11]);
      int calculatedCheck = (10 - (sum % 10)) % 10;
      return checkDigit == calculatedCheck;
    } catch (e) {
      return false;
    }
  }

  /// Libérer les ressources
  static void dispose() {
    _scanner?.close();
    _scanner = null;
  }
}
