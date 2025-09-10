/// MÉTHODE SYSTÉMATIQUE POUR ÉVITER LES DOUBLONS DANS LES TRADUCTIONS
/// 
/// Utilisation :
/// 1. Copier ce fichier dans votre projet
/// 2. Avant d'ajouter une nouvelle traduction, utiliser findExistingTranslation()
/// 3. Si une clé existe déjà, l'utiliser au lieu d'en créer une nouvelle

import 'package:ryze_app/services/translations.dart';

class TranslationChecker {
  // Index de toutes les traductions existantes pour recherche rapide
  static final Map<String, List<String>> _frenchToKeys = {};
  static final Map<String, List<String>> _englishToKeys = {};
  static bool _initialized = false;

  /// Initialise l'index de recherche
  static void _initializeIndex() {
    if (_initialized) return;

    // Parcourir toutes les traductions pour créer l'index
    AppTranslations._translations.forEach((key, translations) {
      final frenchText = translations['fr']?.toLowerCase().trim();
      final englishText = translations['en']?.toLowerCase().trim();

      if (frenchText != null) {
        _frenchToKeys.putIfAbsent(frenchText, () => []).add(key);
      }
      
      if (englishText != null) {
        _englishToKeys.putIfAbsent(englishText, () => []).add(key);
      }
    });

    _initialized = true;
  }

  /// Recherche une traduction existante pour un texte français
  /// 
  /// Exemple :
  /// ```dart
  /// final result = TranslationChecker.findExistingTranslation(
  ///   frenchText: "Annuler",
  ///   englishText: "Cancel"
  /// );
  /// 
  /// if (result.hasExisting) {
  ///   print("Utiliser la clé existante: ${result.existingKey}");
  /// } else {
  ///   print("Créer une nouvelle clé: ${result.suggestedKey}");
  /// }
  /// ```
  static TranslationSearchResult findExistingTranslation({
    String? frenchText,
    String? englishText,
    String? context, // Contexte pour suggérer un nom de clé
  }) {
    _initializeIndex();

    final foundKeys = <String>{};

    // Rechercher par texte français
    if (frenchText != null) {
      final normalizedFrench = frenchText.toLowerCase().trim();
      final matches = _frenchToKeys[normalizedFrench];
      if (matches != null) {
        foundKeys.addAll(matches);
      }
    }

    // Rechercher par texte anglais
    if (englishText != null) {
      final normalizedEnglish = englishText.toLowerCase().trim();
      final matches = _englishToKeys[normalizedEnglish];
      if (matches != null) {
        foundKeys.addAll(matches);
      }
    }

    if (foundKeys.isNotEmpty) {
      return TranslationSearchResult.existing(
        existingKey: foundKeys.first,
        allMatches: foundKeys.toList(),
        frenchText: frenchText,
        englishText: englishText,
      );
    }

    // Si aucune traduction trouvée, suggérer une clé
    final suggestedKey = _suggestKeyName(
      frenchText: frenchText,
      englishText: englishText,
      context: context,
    );

    return TranslationSearchResult.new_(
      suggestedKey: suggestedKey,
      frenchText: frenchText,
      englishText: englishText,
    );
  }

  /// Recherche par similarité (pour détecter les doublons potentiels)
  static List<String> findSimilarTranslations(String text, {double threshold = 0.8}) {
    _initializeIndex();
    
    final normalizedText = text.toLowerCase().trim();
    final similar = <String>[];
    
    // Recherche de mots similaires dans les traductions françaises
    _frenchToKeys.keys.forEach((existing) {
      if (_calculateSimilarity(normalizedText, existing) >= threshold) {
        similar.addAll(_frenchToKeys[existing]!);
      }
    });
    
    // Recherche de mots similaires dans les traductions anglaises
    _englishToKeys.keys.forEach((existing) {
      if (_calculateSimilarity(normalizedText, existing) >= threshold) {
        similar.addAll(_englishToKeys[existing]!);
      }
    });
    
    return similar.toSet().toList();
  }

  /// Calcule la similarité entre deux chaînes (algorithme de Levenshtein simplifié)
  static double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    if (longer.contains(shorter)) return 0.9;
    if (shorter.contains(longer.substring(0, (longer.length * 0.7).round()))) return 0.8;
    
    return 0.0; // Implémentation basique, peut être améliorée
  }

  /// Suggère un nom de clé basé sur le texte et le contexte
  static String _suggestKeyName({
    String? frenchText,
    String? englishText,
    String? context,
  }) {
    // Utiliser le texte anglais comme base (convention)
    String baseText = englishText?.toLowerCase() ?? frenchText?.toLowerCase() ?? 'unknown';
    
    // Nettoyer le texte
    baseText = baseText
        .replaceAll(RegExp(r'[^\w\s]'), '') // Enlever la ponctuation
        .replaceAll(RegExp(r'\s+'), '_')    // Remplacer espaces par _
        .toLowerCase();

    // Ajouter le contexte si fourni
    if (context != null && context.isNotEmpty) {
      final cleanContext = context.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      return '${cleanContext}_$baseText';
    }

    return baseText;
  }

  /// Affiche un rapport des doublons potentiels
  static void generateDuplicateReport() {
    _initializeIndex();
    
    print('=== RAPPORT DES DOUBLONS POTENTIELS ===\n');
    
    final duplicates = <String, List<String>>{};
    
    // Identifier les doublons exacts en français
    _frenchToKeys.forEach((frenchText, keys) {
      if (keys.length > 1) {
        duplicates[frenchText] = keys;
      }
    });
    
    if (duplicates.isNotEmpty) {
      print('DOUBLONS EXACTS (même texte français):');
      duplicates.forEach((text, keys) {
        print('  "$text" → ${keys.join(", ")}');
      });
    } else {
      print('Aucun doublon exact détecté ✓');
    }
    
    print('\n=== FIN DU RAPPORT ===');
  }
}

/// Résultat de la recherche de traduction
class TranslationSearchResult {
  final bool hasExisting;
  final String? existingKey;
  final List<String> allMatches;
  final String? suggestedKey;
  final String? frenchText;
  final String? englishText;

  TranslationSearchResult.existing({
    required this.existingKey,
    required this.allMatches,
    this.frenchText,
    this.englishText,
  }) : hasExisting = true, suggestedKey = null;

  TranslationSearchResult.new_({
    required this.suggestedKey,
    this.frenchText,
    this.englishText,
  }) : hasExisting = false, existingKey = null, allMatches = [];

  @override
  String toString() {
    if (hasExisting) {
      return '✓ Utiliser clé existante: "$existingKey"';
    } else {
      return '→ Créer nouvelle clé: "$suggestedKey"';
    }
  }
}

/// Extension pour faciliter l'utilisation
extension TranslationValidation on String {
  /// Vérifie si ce texte existe déjà dans les traductions
  TranslationSearchResult checkForExistingTranslation({String? context}) {
    return TranslationChecker.findExistingTranslation(
      frenchText: this,
      context: context,
    );
  }
}

/// EXEMPLES D'UTILISATION:

void exempleUtilisation() {
  // Exemple 1: Vérifier avant d'ajouter une traduction
  final result1 = TranslationChecker.findExistingTranslation(
    frenchText: "Annuler",
    englishText: "Cancel"
  );
  print(result1); // ✓ Utiliser clé existante: "cancel"

  // Exemple 2: Pour un nouveau texte
  final result2 = TranslationChecker.findExistingTranslation(
    frenchText: "Sauvegarder les modifications",
    englishText: "Save changes",
    context: "settings"
  );
  print(result2); // → Créer nouvelle clé: "settings_save_changes"

  // Exemple 3: Recherche de similarités
  final similar = TranslationChecker.findSimilarTranslations("Annulation");
  print("Traductions similaires: $similar");

  // Exemple 4: Rapport des doublons
  TranslationChecker.generateDuplicateReport();
}

/// PROCESS RECOMMANDÉ POUR CHAQUE NOUVELLE TRADUCTION:
/// 
/// 1. **TOUJOURS** utiliser TranslationChecker.findExistingTranslation() d'abord
/// 2. Si hasExisting = true → utiliser la clé existante
/// 3. Si hasExisting = false → créer une nouvelle clé avec le nom suggéré
/// 4. Éviter les variantes inutiles (ex: "cancel_btn", "cancel_action" si "cancel" existe déjà)
/// 5. Grouper par contexte (ex: "workout_", "nutrition_", "cardio_")