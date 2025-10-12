import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/google_vision_config.dart';

/// Service de détection automatique de code-barres
/// Utilise Google Cloud Vision API pour extraire les codes-barres des images
class BarcodeDetectionService {

  /// Détecter un code-barres dans une image
  /// Retourne le code-barres (String) ou null si aucun trouvé
  static Future<String?> detectBarcode(Uint8List imageBytes) async {
    try {
      debugPrint('🔍 [BARCODE] Début détection code-barres...');

      // Vérifier la config
      if (!GoogleVisionConfig.isConfigured) {
        debugPrint('❌ [BARCODE] Google Vision API non configurée');
        return null;
      }

      // Redimensionner l'image pour optimiser la vitesse
      final resizedBytes = await _resizeImage(imageBytes);
      final base64Image = base64Encode(resizedBytes);

      // Préparer la requête Vision API avec TEXT_DETECTION
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION', 'maxResults': 1},
            ],
          }
        ],
      };

      // Appel API
      final response = await http.post(
        Uri.parse(GoogleVisionConfig.fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ [BARCODE] Erreur API ${response.statusCode}: ${response.body}');
        return null;
      }

      // Parser la réponse
      final data = json.decode(response.body);
      final responses = data['responses'] as List?;

      if (responses == null || responses.isEmpty) {
        debugPrint('⚠️ [BARCODE] Aucune réponse de l\'API');
        return null;
      }

      final firstResponse = responses[0] as Map<String, dynamic>;
      final textAnnotations = firstResponse['textAnnotations'] as List?;

      if (textAnnotations == null || textAnnotations.isEmpty) {
        debugPrint('⚠️ [BARCODE] Aucun texte détecté dans l\'image');
        return null;
      }

      // Le premier élément contient tout le texte détecté
      final fullText = textAnnotations[0]['description'] as String?;

      if (fullText == null) {
        debugPrint('⚠️ [BARCODE] Texte détecté vide');
        return null;
      }

      debugPrint('📝 [BARCODE] Texte détecté: $fullText');

      // Extraire un code-barres valide du texte
      final barcode = _extractBarcode(fullText);

      if (barcode != null) {
        debugPrint('✅ [BARCODE] Code-barres trouvé: $barcode');
      } else {
        debugPrint('⚠️ [BARCODE] Aucun code-barres valide trouvé dans le texte');
      }

      return barcode;

    } catch (e) {
      debugPrint('❌ [BARCODE] Erreur détection: $e');
      return null;
    }
  }

  /// Extraire un code-barres valide du texte détecté avec validation stricte
  /// Priorise les vrais codes-barres EAN-13/UPC en validant le checksum
  static String? _extractBarcode(String text) {
    debugPrint('🔍 [BARCODE] Analyse du texte pour extraction...');
    
    // Nettoyer le texte
    final cleanText = text.replaceAll(RegExp(r'\s+'), '');
    
    // Chercher toutes les séquences de chiffres de 8 à 13 caractères
    final digitSequences = RegExp(r'\d{8,13}').allMatches(cleanText);
    
    List<String> candidates = [];
    for (final match in digitSequences) {
      final sequence = match.group(0)!;
      debugPrint('  📋 Candidat trouvé: $sequence (${sequence.length} chiffres)');
      
      // Filtrer les séquences répétitives
      if (_isRepetitiveSequence(sequence)) {
        debugPrint('    ❌ Rejeté: séquence répétitive');
        continue;
      }
      
      candidates.add(sequence);
    }
    
    if (candidates.isEmpty) {
      debugPrint('⚠️ [BARCODE] Aucun candidat valide trouvé');
      return null;
    }
    
    // STRATÉGIE 1 : Chercher un EAN-13 valide avec checksum correct
    for (final candidate in candidates.where((c) => c.length == 13)) {
      if (_validateEAN13Checksum(candidate)) {
        debugPrint('✅ [BARCODE] EAN-13 valide trouvé avec checksum: $candidate');
        return candidate;
      } else {
        debugPrint('  ⚠️ Checksum invalide pour: $candidate');
      }
    }
    
    // STRATÉGIE 2 : Chercher un UPC-A (12 chiffres) valide
    for (final candidate in candidates.where((c) => c.length == 12)) {
      if (_validateUPCAChecksum(candidate)) {
        debugPrint('✅ [BARCODE] UPC-A valide trouvé: $candidate');
        return candidate;
      }
    }
    
    // STRATÉGIE 3 : Préférer la séquence la plus longue (probablement le vrai code)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    final longest = candidates.first;
    debugPrint('⚠️ [BARCODE] Aucun code valide, retour du plus long: $longest');
    return longest;
  }

  /// Vérifier si une séquence est répétitive (00000, 11111, etc.)
  static bool _isRepetitiveSequence(String sequence) {
    if (sequence.isEmpty) return false;
    final firstChar = sequence[0];
    return sequence.split('').every((char) => char == firstChar);
  }

  /// Valider le checksum d'un code EAN-13
  /// Algorithme : somme alternée * 1 et * 3, le dernier chiffre doit faire un total divisible par 10
  static bool _validateEAN13Checksum(String code) {
    if (code.length != 13) return false;

    try {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(code[i]);
        // Alterner entre *1 et *3 (positions impaires *1, paires *3)
        sum += (i % 2 == 0) ? digit : digit * 3;
      }

      int checkDigit = int.parse(code[12]);
      int calculatedCheck = (10 - (sum % 10)) % 10;

      bool isValid = checkDigit == calculatedCheck;
      if (!isValid) {
        debugPrint('    Checksum EAN-13: attendu=$checkDigit, calculé=$calculatedCheck');
      }
      return isValid;
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
        // UPC-A: positions impaires *3, paires *1
        sum += (i % 2 == 0) ? digit * 3 : digit;
      }

      int checkDigit = int.parse(code[11]);
      int calculatedCheck = (10 - (sum % 10)) % 10;

      bool isValid = checkDigit == calculatedCheck;
      if (!isValid) {
        debugPrint('    Checksum UPC-A: attendu=$checkDigit, calculé=$calculatedCheck');
      }
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Redimensionner l'image pour optimiser la vitesse de détection
  static Future<Uint8List> _resizeImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Réduire à 800x800 max pour la détection de code-barres
      // (plus petit = plus rapide, suffisant pour les codes-barres)
      const maxDimension = 800;
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > maxDimension || newHeight > maxDimension) {
        if (newWidth > newHeight) {
          newHeight = (newHeight * maxDimension / newWidth).round();
          newWidth = maxDimension;
        } else {
          newWidth = (newWidth * maxDimension / newHeight).round();
          newHeight = maxDimension;
        }

        final resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        // Encoder en JPEG avec qualité moyenne pour réduire la taille
        return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 70));
      }

      return imageBytes;
    } catch (e) {
      debugPrint('⚠️ [BARCODE] Erreur redimensionnement: $e');
      return imageBytes;
    }
  }
}
