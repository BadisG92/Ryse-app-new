import '../services/localization_service.dart';

/// Service pour gérer la traduction automatique des colonnes Supabase
/// en fonction de la langue active (_en/_fr)
class SupabaseLocalizationService {
  static const String _englishSuffix = '_en';
  static const String _frenchSuffix = '_fr';

  /// Obtient le suffixe de colonne basé sur la langue actuelle
  static String getColumnSuffix() {
    final locService = LocalizationService.instance;
    final isFrench = locService.isFrench;
    
    // Utiliser isFrench au lieu de comparer la string, plus fiable
    return isFrench ? _frenchSuffix : _englishSuffix;
  }

  /// Obtient le suffixe opposé pour les fallbacks
  static String getFallbackColumnSuffix() {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;
    return currentLanguage == 'fr' ? _englishSuffix : _frenchSuffix;
  }

  /// Génère automatiquement la liste des colonnes à sélectionner pour une requête
  /// en incluant les colonnes traduites et leurs fallbacks
  static String generateSelectColumns(List<String> baseColumns) {
    final currentSuffix = getColumnSuffix();
    final fallbackSuffix = getFallbackColumnSuffix();
    
    final columns = <String>[];
    
    for (final column in baseColumns) {
      // Si c'est une colonne traduite (name, title, description, etc.)
      if (_isTranslatableColumn(column)) {
        // Ajouter la colonne avec le suffixe de la langue actuelle
        columns.add('$column$currentSuffix');
        // Ajouter aussi le fallback au cas où la traduction n'existe pas
        columns.add('$column$fallbackSuffix');
      } else {
        // Colonne normale, l'ajouter telle quelle
        columns.add(column);
      }
    }
    
    return columns.join(', ');
  }

  /// Vérifie si une colonne est traduisible (a des variantes _en/_fr)
  static bool _isTranslatableColumn(String column) {
    const translatableColumns = [
      'name',
      'title', 
      'description',
      'instructions',
      'category',
      'steps',
      'tags',
      'notes',
    ];
    return translatableColumns.contains(column);
  }

  /// Extrait la valeur traduite d'un résultat de requête Supabase
  /// Utilise la langue actuelle avec fallback vers l'autre langue
  static String? getLocalizedValue(Map<String, dynamic> data, String baseColumn) {
    if (!_isTranslatableColumn(baseColumn)) {
      return data[baseColumn]?.toString();
    }

    final currentSuffix = getColumnSuffix();
    final fallbackSuffix = getFallbackColumnSuffix();
    
    // Essayer d'abord la langue actuelle
    final currentValue = data['$baseColumn$currentSuffix'];
    if (currentValue != null && currentValue.toString().isNotEmpty) {
      return currentValue.toString();
    }
    
    // Fallback vers l'autre langue
    final fallbackValue = data['$baseColumn$fallbackSuffix'];
    if (fallbackValue != null && fallbackValue.toString().isNotEmpty) {
      return fallbackValue.toString();
    }
    
    return null;
  }

  /// Helper pour obtenir directement la colonne de nom traduite
  static String? getLocalizedName(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'name');
  }

  /// Helper pour obtenir directement le titre traduit
  static String? getLocalizedTitle(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'title');
  }

  /// Helper pour obtenir directement la description traduite
  static String? getLocalizedDescription(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'description');
  }

  /// Helper pour obtenir directement les instructions traduites
  static String? getLocalizedInstructions(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'instructions');
  }

  /// Helper pour obtenir directement la catégorie traduite
  static String? getLocalizedCategory(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'category');
  }

  /// Helper pour obtenir directement les notes traduites
  static String? getLocalizedNotes(Map<String, dynamic> data) {
    return getLocalizedValue(data, 'notes');
  }

  /// Génère la clause SELECT complète pour une table avec des colonnes traduites
  static String buildSelectQuery({
    required List<String> standardColumns,
    required List<String> translatableColumns,
  }) {
    final allColumns = <String>[];
    
    // Ajouter les colonnes standard
    allColumns.addAll(standardColumns);
    
    // Ajouter les colonnes traduites avec leurs variantes
    final currentSuffix = getColumnSuffix();
    final fallbackSuffix = getFallbackColumnSuffix();
    
    for (final column in translatableColumns) {
      allColumns.add('$column$currentSuffix');
      allColumns.add('$column$fallbackSuffix');
    }
    
    return allColumns.join(', ');
  }

  /// Debug: affiche les colonnes qui seraient sélectionnées
  static void debugColumns(List<String> baseColumns) {
    print('🌐 Supabase Localization Debug:');
    print('Current language: ${LocalizationService.instance.currentLanguageCode}');
    print('Column suffix: ${getColumnSuffix()}');
    print('Generated SELECT: ${generateSelectColumns(baseColumns)}');
  }
}