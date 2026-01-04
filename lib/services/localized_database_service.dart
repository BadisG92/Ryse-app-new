import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';

/// Service utilitaire pour gérer les requêtes de base de données localisées
/// 
/// Ce service fournit des méthodes pour récupérer des données depuis la base 
/// en utilisant les colonnes appropriées selon la langue sélectionnée (_fr ou _en)
class LocalizedDatabaseService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Récupère des données avec colonnes localisées
  /// 
  /// [tableName] - nom de la table
  /// [baseColumns] - colonnes de base (non localisées) 
  /// [localizedColumns] - colonnes qui ont des variantes _fr/_en
  static Future<List<Map<String, dynamic>>> getLocalizedData({
    required String tableName,
    List<String> baseColumns = const [],
    List<String> localizedColumns = const [],
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    // Construire la liste des colonnes à sélectionner
    List<String> allColumns = [...baseColumns];
    
    // Ajouter les colonnes localisées avec le bon suffixe
    for (String column in localizedColumns) {
      allColumns.add('$column$suffix');
    }
    
    final response = await _supabase.from(tableName).select(allColumns.join(','));
    
    return response;
  }

  /// Exemple : Récupérer les aliments avec nom et description localisés
  static Future<List<Map<String, dynamic>>> getFoods({
    String? searchTerm,
    int? limit,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    final selectQuery = '''
      id,
      code,
      name$suffix,
      description$suffix,
      calories_per_100g,
      proteins_per_100g,
      carbs_per_100g,
      fats_per_100g,
      category_id
    ''';
    
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // Rechercher dans la colonne nom appropriée selon la langue
      if (limit != null) {
        return await _supabase
            .from('foods')
            .select(selectQuery)
            .ilike('name$suffix', '%$searchTerm%')
            .limit(limit);
      } else {
        return await _supabase
            .from('foods')
            .select(selectQuery)
            .ilike('name$suffix', '%$searchTerm%');
      }
    }
    
    if (limit != null) {
      return await _supabase
          .from('foods')
          .select(selectQuery)
          .limit(limit);
    }
    
    return await _supabase.from('foods').select(selectQuery);
  }

  /// Exemple : Récupérer les catégories d'aliments localisées
  static Future<List<Map<String, dynamic>>> getFoodCategories() async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    return await _supabase
        .from('food_categories')
        .select('id, name$suffix, description$suffix')
        .order('name$suffix');
  }

  /// Exemple : Récupérer les exercices avec nom et instructions localisés
  static Future<List<Map<String, dynamic>>> getExercises({
    String? muscleGroup,
    int? limit,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    final selectQuery = '''
      id,
      name$suffix,
      instructions$suffix,
      muscle_group_fr,
      muscle_group_en,
      difficulty_level,
      equipment_needed
    ''';
    
    if (muscleGroup != null) {
      // Filtrer par le groupe musculaire dans la langue appropriée
      if (limit != null) {
        return await _supabase
            .from('exercises')
            .select(selectQuery)
            .eq('muscle_group$suffix', muscleGroup)
            .limit(limit)
            .order('name$suffix');
      } else {
        return await _supabase
            .from('exercises')
            .select(selectQuery)
            .eq('muscle_group$suffix', muscleGroup)
            .order('name$suffix');
      }
    }
    
    if (limit != null) {
      return await _supabase
          .from('exercises')
          .select(selectQuery)
          .limit(limit)
          .order('name$suffix');
    }
    
    return await _supabase
        .from('exercises')
        .select(selectQuery)
        .order('name$suffix');
  }

  /// Méthode générique pour récupérer du texte localisé depuis deux colonnes
  static String getLocalizedText(
    Map<String, dynamic> data,
    String baseColumnName,
  ) {
    final locService = LocalizationService.instance;
    if (locService.isFrench) {
      return data['${baseColumnName}_fr'] ?? data['${baseColumnName}_en'] ?? '';
    } else {
      return data['${baseColumnName}_en'] ?? data['${baseColumnName}_fr'] ?? '';
    }
  }

  /// Méthode utilitaire pour construire des colonnes select localisées
  static String buildLocalizedSelect(List<String> columns) {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    return columns.map((column) {
      // Si la colonne contient déjà _fr ou _en, la retourner telle quelle
      if (column.contains('_fr') || column.contains('_en')) {
        return column;
      }
      // Sinon, vérifier si c'est une colonne qui devrait être localisée
      if (_shouldLocalizeColumn(column)) {
        return '$column$suffix';
      }
      return column;
    }).join(', ');
  }

  /// Détermine si une colonne devrait être localisée
  /// Vous pouvez personnaliser cette logique selon vos besoins
  static bool _shouldLocalizeColumn(String columnName) {
    const localizedColumns = [
      'name',
      'description', 
      'instructions',
      'title',
      'content',
      'label',
      'category'
    ];
    
    return localizedColumns.contains(columnName);
  }
}