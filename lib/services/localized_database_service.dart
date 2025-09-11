import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';

/// Service utilitaire pour gérer les requêtes de base de données localisées
/// 
/// Ce service fournit des méthodes pour récupérer des données depuis la base 
/// en utilisant les colonnes appropriées selon la langue sélectionnée (_fr ou _en)
class LocalizedDatabaseService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Récupère des données avec colonnes localisées
  /// 
  /// [tableName] - nom de la table
  /// [baseColumns] - colonnes de base (non localisées) 
  /// [localizedColumns] - colonnes qui ont des variantes _fr/_en
  /// [filter] - fonction optionnelle pour ajouter des filtres
  static Future<List<Map<String, dynamic>>> getLocalizedData({
    required String tableName,
    List<String> baseColumns = const [],
    List<String> localizedColumns = const [],
    PostgrestFilterBuilder Function(PostgrestQueryBuilder)? filter,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    // Construire la liste des colonnes à sélectionner
    List<String> allColumns = [...baseColumns];
    
    // Ajouter les colonnes localisées avec le bon suffixe
    for (String column in localizedColumns) {
      allColumns.add('$column$suffix');
    }
    
    var query = _supabase.from(tableName).select(allColumns.join(','));
    
    // Appliquer le filtre si fourni
    if (filter != null) {
      query = filter(query) as PostgrestQueryBuilder;
    }
    
    return await query;
  }

  /// Exemple : Récupérer les aliments avec nom et description localisés
  static Future<List<Map<String, dynamic>>> getFoods({
    String? searchTerm,
    int? limit,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    var query = _supabase
        .from('foods')
        .select('''
          id,
          code,
          name$suffix,
          description$suffix,
          calories_per_100g,
          proteins_per_100g,
          carbs_per_100g,
          fats_per_100g,
          category_id
        ''');
    
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // Rechercher dans la colonne nom appropriée selon la langue
      query = query.ilike('name$suffix', '%$searchTerm%');
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query;
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
    
    var query = _supabase
        .from('exercises')
        .select('''
          id,
          name$suffix,
          instructions$suffix,
          muscle_group_fr,
          muscle_group_en,
          difficulty_level,
          equipment_needed
        ''');
    
    if (muscleGroup != null) {
      // Filtrer par le groupe musculaire dans la langue appropriée
      query = query.eq('muscle_group$suffix', muscleGroup);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query.order('name$suffix');
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