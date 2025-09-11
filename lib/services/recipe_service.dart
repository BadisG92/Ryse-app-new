import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../components/ui/recipe_models.dart';
import 'localization_service.dart';

class RecipeService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Récupère toutes les recettes depuis Supabase
  static Future<List<Recipe>> getAllRecipes() async {
    try {
      // Récupérer toutes les recettes avec leurs valeurs nutritionnelles directement
      final recipesResponse = await _supabase
          .from('recipes_database')
          .select('*')
          .eq('is_public', true);

      List<Recipe> recipes = [];
      
      for (int i = 0; i < recipesResponse.length; i++) {
        var recipeData = recipesResponse[i];
        try {
          // Utiliser directement Recipe.fromJson maintenant que la classe l'a
          final recipe = Recipe.fromJson(recipeData);
          recipes.add(recipe);
        } catch (e) {
          print('❌ Erreur pour recette $i: $e');
        }
      }
      
      
      return recipes;
    } catch (e) {
      print('Erreur lors de la récupération des recettes: $e');
      return [];
    }
  }

  /// Créé un RecipeDetailModel pour la gestion détaillée d'une recette
  static Future<RecipeDetailModel?> getRecipeDetailModel(String recipeId) async {
    try {
      // Récupérer la recette
      final recipeResponse = await _supabase
          .from('recipes_database')
          .select('*')
          .eq('id', recipeId)
          .single();

      // Convertir les ID entiers en string
      recipeResponse['id'] = recipeResponse['id']?.toString();

      // Récupérer les ingrédients avec les données nutritionnelles
      final ingredientsResponse = await _supabase
          .from('recipe_ingredient_database')
          .select('id, recipe_id, food_id, quantity, display_order, unite_fr, unite_en, food_database!inner(*)')
          .eq('recipe_id', recipeId)
          .order('display_order');

      // Créer les RecipeIngredient avec quantités pour la recette complète (1 portion × servings)
      List<RecipeIngredient> ingredients = [];
      for (var ing in ingredientsResponse) {
        // Convertir les ID entiers en string pour recipe_ingredient_database
        ing['id'] = ing['id']?.toString();
        ing['recipe_id'] = ing['recipe_id']?.toString();
        ing['food_id'] = ing['food_id']?.toString();
        
        final food = ing['food_database'];
        if (food != null) {
          // Convertir l'ID de food_database aussi
          food['id'] = food['id']?.toString();
        }
        
        final baseQuantity = double.parse(ing['quantity'].toString()); // Quantité pour 1 portion
        final servings = recipeResponse['servings'];
        
        final locService = LocalizationService.instance;
        ingredients.add(RecipeIngredient(
          id: ing['id'].toString(),
          name: locService.getTextFromColumns(food['name_fr'], food['name_en']),
          quantity: baseQuantity * servings, // Quantité totale pour toute la recette
          unit: locService.getTextFromColumns(ing['unite_fr'], ing['unite_en']) ?? '',
          caloriesPer100g: double.parse((food['calories'] ?? 0).toString()),
          proteinsPer100g: double.parse((food['proteins'] ?? 0).toString()),
          carbsPer100g: double.parse((food['carbs'] ?? 0).toString()),
          fatsPer100g: double.parse((food['fats'] ?? 0).toString()),
        ));
      }

      // Créer la Recipe de base avec les valeurs nutritionnelles de la table recipes
      final baseRecipe = Recipe.fromJson(recipeResponse);

      return RecipeDetailModel(
        baseRecipe: baseRecipe,
        ingredients: ingredients,
        currentPortions: recipeResponse['servings'],
      );
    } catch (e) {
      print('Erreur lors de la récupération du détail de recette: $e');
      return null;
    }
  }

  /// Version optimisée pour convertir les données Supabase en modèle Recipe sans ingrédients
  static Recipe _mapToRecipeFromDataOptimized(
    Map<String, dynamic> recipeData
  ) {
    final locService = LocalizationService.instance;
    return Recipe(
      id: int.parse(recipeData['id'].toString()),
      name: locService.getTextFromColumns(recipeData['name_fr'], recipeData['name_en']),
      image: recipeData['image_url'] ?? "/placeholder.svg?height=200&width=200",
      duration: _formatDuration(recipeData['duration']),
      // Utiliser les valeurs directement depuis la table recipes (déjà par portion)
      calories: (recipeData['calories per portion'] ?? 0).round(),
      servings: recipeData['servings'] ?? 1,
      tags: _convertTags(recipeData),
      proteins: (recipeData['proteins per portion'] ?? 0).round(),
      carbs: (recipeData['carbs per portion'] ?? 0).round(),
      fats: (recipeData['fat per portion'] ?? 0).round(),
      // Pour la liste, on peut utiliser des ingrédients vides (ils seront chargés dans les détails)
      ingredients: [],
      steps: _getStepsFromData(recipeData),
      difficulty: _translateDifficulty(recipeData['difficulty']),
    );
  }

  /// Convertit les données Supabase en modèle Recipe
  static Recipe _mapToRecipeFromData(
    Map<String, dynamic> recipeData, 
    List<dynamic> ingredients
  ) {
    final locService = LocalizationService.instance;
    return Recipe(
      id: int.parse(recipeData['id'].toString()),
      name: locService.getTextFromColumns(recipeData['name_fr'], recipeData['name_en']),
      image: recipeData['image_url'] ?? "/placeholder.svg?height=200&width=200",
      duration: _formatDuration(recipeData['duration']),
      // Utiliser les valeurs directement depuis la table recipes (déjà par portion)
      calories: (recipeData['calories per portion'] ?? 0).round(),
      servings: recipeData['servings'] ?? 1,
      tags: _convertTags(recipeData),
      proteins: (recipeData['proteins per portion'] ?? 0).round(),
      carbs: (recipeData['carbs per portion'] ?? 0).round(),
      fats: (recipeData['fat per portion'] ?? 0).round(),
      ingredients: _formatIngredientsFromData(ingredients),
      steps: _getStepsFromData(recipeData),
      difficulty: _translateDifficulty(recipeData['difficulty']),
    );
  }

  static String _formatDuration(String? duration) {
    if (duration == null) return "0 min";
    // Convertir "15 minutes" en "15 min" pour compatibilité UI
    return duration.replaceAll('minutes', 'min').replaceAll('minute', 'min');
  }

  static List<String> _convertTags(Map<String, dynamic> recipeData) {
    // Utiliser les tags français ou anglais selon la langue actuelle
    final locService = LocalizationService.instance;
    String tagsString = locService.getTextFromColumns(recipeData['tags_fr'], recipeData['tags_en']);
    dynamic tags = tagsString.isEmpty ? recipeData['tags'] : tagsString;
    
    if (tags == null) return [];
    if (tags is List) return tags.cast<String>();
    return [];
  }

  static List<String> _formatIngredientsFromData(List<dynamic> ingredients) {
    final locService = LocalizationService.instance;
    return ingredients.map((ing) {
      final food = ing['food_database'];
      final foodName = locService.getTextFromColumns(food['name_fr'], food['name_en']);
      final quantity = ing['quantity'].toString();
      final unit = locService.getTextFromColumns(ing['unite_fr'], ing['unite_en']) ?? '';
      return "$quantity $unit - $foodName";
    }).cast<String>().toList();
  }

  static List<String> _getStepsFromData(Map<String, dynamic> recipeData) {
    final locService = LocalizationService.instance;
    final stepsString = locService.getTextFromColumns(recipeData['steps_fr'], recipeData['steps_en']);
    if (stepsString.isNotEmpty) {
      return [stepsString]; // Les étapes sont stockées comme chaîne, pas comme liste
    }
    return [];
  }

  static String _translateDifficulty(String? difficulty) {
    if (difficulty == null) return "Facile";
    
    final locService = LocalizationService.instance;
    final translations = {
      'easy': locService.isFrench ? 'Facile' : 'Easy',
      'medium': locService.isFrench ? 'Moyen' : 'Medium', 
      'hard': locService.isFrench ? 'Difficile' : 'Hard',
      'spicy': locService.isFrench ? 'Épicé' : 'Spicy',
    };
    
    return translations[difficulty.toLowerCase()] ?? difficulty;
  }

  /// Récupère les recettes featured (les 5 premières par défaut)
  static Future<List<Recipe>> getFeaturedRecipes() async {
    final allRecipes = await getAllRecipes();
    // Prendre minimum 5 recettes, ou toutes si moins de 5
    return allRecipes.take(5).toList();
  }

  /// Récupère tous les tags uniques depuis les recettes pour les organiser dans content_tags
  static Future<Set<String>> getAllUniqueTags() async {
    try {
      print('🔍 RecipeService.getAllUniqueTags - Récupération des tags...');
      
      // Récupérer toutes les recettes
      final recipesResponse = await _supabase
          .from('recipes_database')
          .select('tags_fr, tags_en')
          .eq('is_public', true);

      print('🔍 Found ${recipesResponse.length} recipes to extract tags from');

      final locService = LocalizationService.instance;
      Set<String> allTags = {};
      
      for (var recipe in recipesResponse) {
        // Récupérer les tags selon la langue actuelle
        String tagsString = locService.getTextFromColumns(recipe['tags_fr'], recipe['tags_en']);
        
        if (tagsString.isNotEmpty) {
          // Séparer les tags par virgule et les nettoyer
          List<String> tags = tagsString
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
          
          allTags.addAll(tags);
        }
      }
      
      print('✅ Extracted ${allTags.length} unique tags: ${allTags.take(10).toList()}...');
      return allTags;
    } catch (e) {
      print('❌ Erreur lors de la récupération des tags: $e');
      return {};
    }
  }
} 