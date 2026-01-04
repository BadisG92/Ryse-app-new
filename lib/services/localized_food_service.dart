import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';

/// Service pour récupérer les aliments avec localisation
/// 
/// Utilise les colonnes name_fr/name_en de la table food_database
class LocalizedFoodService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Recherche d'aliments avec nom localisé
  static Future<List<Map<String, dynamic>>> searchFoods({
    required String searchTerm,
    int limit = 50,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix(); // '_fr' ou '_en'
    
    try {
      if (searchTerm.isEmpty) {
        // Si pas de terme de recherche, retourner les aliments populaires
        return await _supabase
            .from('food_database')
            .select('''
              id,
              name$suffix,
              calories,
              proteins,
              carbs,
              fats,
              base_quantity,
              reference_unit$suffix,
              category
            ''')
            .limit(limit);
      }
      
      // Recherche dans la colonne appropriée selon la langue
      return await _supabase
          .from('food_database')
          .select('''
            id,
            name$suffix,
            calories,
            proteins,
            carbs,
            fats,
            base_quantity,
            reference_unit$suffix,
            category
          ''')
          .ilike('name$suffix', '%$searchTerm%')
          .limit(limit)
          .order('name$suffix');
      
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'aliments: $e');
      return [];
    }
  }

  /// Récupère les aliments d'une catégorie avec noms localisés
  static Future<List<Map<String, dynamic>>> getFoodsByCategory({
    required String category,
    int limit = 100,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      return await _supabase
          .from('food_database')
          .select('''
            id,
            name$suffix,
            calories,
            proteins,
            carbs,
            fats,
            base_quantity,
            reference_unit$suffix,
            category
          ''')
          .eq('category', category)
          .limit(limit)
          .order('name$suffix');
      
    } catch (e) {
      debugPrint('Erreur lors de la récupération des aliments par catégorie: $e');
      return [];
    }
  }

  /// Récupère les détails d'un aliment avec nom et unité localisés
  static Future<Map<String, dynamic>?> getFoodDetails(int foodId) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      final result = await _supabase
          .from('food_database')
          .select('''
            id,
            name$suffix,
            calories,
            proteins,
            carbs,
            fats,
            base_quantity,
            reference_unit$suffix,
            source,
            category,
            created_at
          ''')
          .eq('id', foodId)
          .maybeSingle();
      
      if (result != null) {
        // Ajouter des informations de localisation
        result['localized_name'] = getLocalizedText(result, 'name');
        result['localized_unit'] = getLocalizedText(result, 'reference_unit');
        result['current_language'] = locService.currentLanguageCode;
      }
      
      return result;
      
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails de l\'aliment: $e');
      return null;
    }
  }

  /// Récupère les recettes avec noms localisés
  static Future<List<Map<String, dynamic>>> getRecipes({
    String? searchTerm,
    int limit = 50,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      var query = _supabase
          .from('recipes_database')
          .select('''
            id,
            name$suffix,
            steps$suffix,
            portions_initial,
            duration,
            "calories per portion",
            "proteins per portion",
            "carbs per portion",
            "fat per portion",
            tags$suffix,
            servings,
            image_url,
            is_public
          ''')
          .eq('is_public', true);
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.ilike('name$suffix', '%$searchTerm%');
      }
      
      return await query
          .limit(limit)
          .order('name$suffix');
      
    } catch (e) {
      debugPrint('Erreur lors de la récupération des recettes: $e');
      return [];
    }
  }

  /// Récupère les ingrédients d'une recette avec noms d'aliments localisés
  static Future<List<Map<String, dynamic>>> getRecipeIngredients(int recipeId) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      return await _supabase
          .from('recipe_ingredient_database')
          .select('''
            id,
            recipe_id,
            food_id,
            item,
            unite,
            quantity_original,
            quantity,
            display_order,
            food_database!recipe_ingredient_database_food_id_fkey(
              id,
              name$suffix,
              calories,
              proteins,
              carbs,
              fats,
              reference_unit$suffix
            )
          ''')
          .eq('recipe_id', recipeId)
          .order('display_order');
      
    } catch (e) {
      debugPrint('Erreur lors de la récupération des ingrédients de la recette: $e');
      return [];
    }
  }

  /// Récupère les aliments personnalisés de l'utilisateur
  static Future<List<Map<String, dynamic>>> getUserCustomFoods(String userId) async {
    try {
      return await _supabase
          .from('custom_foods')
          .select('''
            id,
            name,
            calories,
            proteins,
            carbs,
            fats,
            reference_quantity,
            reference_unit_fr,
            reference_unit_en,
            origin,
            barcode,
            created_at
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
    } catch (e) {
      debugPrint('Erreur lors de la récupération des aliments personnalisés: $e');
      return [];
    }
  }

  /// Méthode utilitaire pour récupérer le texte localisé
  static String getLocalizedText(Map<String, dynamic> data, String baseColumnName) {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    return data['$baseColumnName$suffix'] as String? ?? 
           data['${baseColumnName}_fr'] as String? ?? 
           data['${baseColumnName}_en'] as String? ?? 
           'Non disponible';
  }

  /// Récupère les statistiques nutritionnelles avec unités localisées  
  static Future<Map<String, dynamic>> getNutritionStats(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      // Définir la période par défaut (7 derniers jours)
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 7));
      
      // Récupérer les entrées alimentaires avec les données des aliments localisées
      final entries = await _supabase
          .from('food_entries')
          .select('''
            id,
            quantity,
            unit,
            meal_type,
            consumed_at,
            calories,
            proteins,
            carbs,
            fats,
            food_id,
            custom_food_id,
            scanned_food_name,
            food_database!food_entries_food_id_fkey(
              name$suffix,
              reference_unit$suffix
            ),
            custom_foods!food_entries_custom_food_id_fkey(
              name,
              reference_unit_fr,
              reference_unit_en
            )
          ''')
          .eq('user_id', userId)
          .gte('consumed_at', start.toIso8601String())
          .lte('consumed_at', end.toIso8601String())
          .order('consumed_at', ascending: false);
      
      // Calculer les totaux
      double totalCalories = 0;
      double totalProteins = 0;
      double totalCarbs = 0;
      double totalFats = 0;
      int totalMeals = entries.length;
      
      for (final entry in entries) {
        totalCalories += (entry['calories'] as num?)?.toDouble() ?? 0;
        totalProteins += (entry['proteins'] as num?)?.toDouble() ?? 0;
        totalCarbs += (entry['carbs'] as num?)?.toDouble() ?? 0;
        totalFats += (entry['fats'] as num?)?.toDouble() ?? 0;
      }
      
      return {
        'period_start': start.toIso8601String(),
        'period_end': end.toIso8601String(),
        'total_entries': totalMeals,
        'total_calories': totalCalories,
        'total_proteins': totalProteins,
        'total_carbs': totalCarbs,
        'total_fats': totalFats,
        'average_calories_per_day': totalCalories / 7,
        'current_language': locService.currentLanguageCode,
        'entries': entries,
      };
      
    } catch (e) {
      debugPrint('Erreur lors du calcul des statistiques nutritionnelles: $e');
      return {
        'error': 'Impossible de récupérer les statistiques',
        'current_language': LocalizationService.instance.currentLanguageCode,
      };
    }
  }
}