import 'package:flutter/foundation.dart';
import '../services/translations.dart';

class TranslationChecker {
  static final Map<String, Map<String, String>> _translations = TranslationService._translations;

  static TranslationCheckResult findExistingTranslation({
    required String frenchText,
    String? englishText,
    String? context,
  }) {
    // Normaliser le texte pour la comparaison
    String normalizedFrench = _normalizeText(frenchText);
    String? normalizedEnglish = englishText != null ? _normalizeText(englishText) : null;

    // Chercher une traduction française existante
    for (var entry in _translations.entries) {
      String key = entry.key;
      Map<String, String> translations = entry.value;
      
      String? frenchValue = translations['fr'];
      String? englishValue = translations['en'];
      
      if (frenchValue != null) {
        String normalizedExistingFrench = _normalizeText(frenchValue);
        
        // Correspondance exacte en français
        if (normalizedExistingFrench == normalizedFrench) {
          return TranslationCheckResult(
            hasExisting: true,
            existingKey: key,
            frenchMatch: frenchValue,
            englishMatch: englishValue,
          );
        }
        
        // Correspondance partielle en français (80% de similitude)
        if (_calculateSimilarity(normalizedExistingFrench, normalizedFrench) > 0.8) {
          return TranslationCheckResult(
            hasExisting: true,
            existingKey: key,
            frenchMatch: frenchValue,
            englishMatch: englishValue,
            isSimilar: true,
          );
        }
      }
      
      // Vérifier aussi l'anglais si fourni
      if (normalizedEnglish != null && englishValue != null) {
        String normalizedExistingEnglish = _normalizeText(englishValue);
        if (normalizedExistingEnglish == normalizedEnglish) {
          return TranslationCheckResult(
            hasExisting: true,
            existingKey: key,
            frenchMatch: frenchValue,
            englishMatch: englishValue,
          );
        }
      }
    }

    // Aucune correspondance trouvée, suggérer une nouvelle clé
    String suggestedKey = _generateKeyName(frenchText, englishText, context);
    
    return TranslationCheckResult(
      hasExisting: false,
      suggestedKey: suggestedKey,
    );
  }

  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Enlever ponctuation
        .replaceAll(RegExp(r'\s+'), ' ')    // Normaliser espaces
        .trim();
  }

  static double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    int maxLength = [a.length, b.length].reduce((a, b) => a > b ? a : b);
    return (maxLength - _levenshteinDistance(a, b)) / maxLength;
  }

  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<List<int>> matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  static String _generateKeyName(String frenchText, String? englishText, String? context) {
    String baseText = englishText ?? frenchText;
    
    // Nettoyer et convertir en snake_case
    String cleaned = baseText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    
    // Ajouter le contexte si fourni
    if (context != null && context.isNotEmpty) {
      return '${context}_$cleaned';
    }
    
    return cleaned;
  }

  // Méthode helper pour afficher toutes les clés existantes
  static void printAllKeys() {
    debugPrint("=== TOUTES LES CLÉS DE TRADUCTION EXISTANTES ===");
    var sortedKeys = _translations.keys.toList()..sort();
    for (String key in sortedKeys) {
      var translations = _translations[key]!;
      debugPrint("$key → fr: '${translations['fr']}' | en: '${translations['en']}'");
    }
    debugPrint("=== TOTAL: ${_translations.length} clés ===");
  }

  // Méthode helper pour chercher par mot-clé
  static List<String> findKeysByKeyword(String keyword) {
    String normalizedKeyword = keyword.toLowerCase();
    return _translations.keys
        .where((key) => key.toLowerCase().contains(normalizedKeyword))
        .toList()..sort();
  }
}

class TranslationCheckResult {
  final bool hasExisting;
  final String? existingKey;
  final String? frenchMatch;
  final String? englishMatch;
  final String? suggestedKey;
  final bool isSimilar;

  TranslationCheckResult({
    required this.hasExisting,
    this.existingKey,
    this.frenchMatch,
    this.englishMatch,
    this.suggestedKey,
    this.isSimilar = false,
  });

  @override
  String toString() {
    if (hasExisting) {
      String similarity = isSimilar ? " (SIMILAIRE)" : "";
      return "✅ UTILISER clé existante: '$existingKey'$similarity\n"
             "   FR: $frenchMatch\n"
             "   EN: $englishMatch";
    } else {
      return "➕ CRÉER nouvelle clé: '$suggestedKey'";
    }
  }
}