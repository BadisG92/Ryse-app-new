import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../components/ui/recipe_models.dart';

class RecipeService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Récupère toutes les recettes depuis Supabase
  static Future<List<Recipe>> getAllRecipes({String language = 'fr'}) async {
    try {
      // Récupérer toutes les recettes avec leurs valeurs nutritionnelles directement
      final recipesResponse = await _supabase
          .from('recipes')
          .select('*')
          .eq('is_public', true);

      List<Recipe> recipes = [];
      
      for (var recipeData in recipesResponse) {
        // Pour la liste des recettes, on n'a plus besoin de charger les ingrédients
        // Les valeurs nutritionnelles sont déjà dans la table recipes
        recipes.add(_mapToRecipeFromDataOptimized(recipeData, language));
      }
      
      return recipes;
    } catch (e) {
      print('Erreur lors de la récupération des recettes: $e');
      return [];
    }
  }

  /// Créé un RecipeDetailModel pour la gestion détaillée d'une recette
  static Future<RecipeDetailModel?> getRecipeDetailModel(String recipeId, {String language = 'fr'}) async {
    try {
      // Récupérer la recette
      final recipeResponse = await _supabase
          .from('recipes')
          .select('*')
          .eq('id', recipeId)
          .single();

      // Récupérer les ingrédients avec les données nutritionnelles
      final ingredientsResponse = await _supabase
          .from('recipe_ingredients')
          .select('*, foods!inner(*)')
          .eq('recipe_id', recipeId)
          .order('display_order');

      // Créer les RecipeIngredient avec quantités pour la recette complète (1 portion × servings)
      List<RecipeIngredient> ingredients = [];
      for (var ing in ingredientsResponse) {
        final food = ing['foods'];
        final baseQuantity = double.parse(ing['quantity'].toString()); // Quantité pour 1 portion
        final servings = recipeResponse['servings'];
        
        ingredients.add(RecipeIngredient(
          id: ing['id'].toString(),
          name: language == 'fr' ? (food['name_fr'] ?? food['name_en']) : (food['name_en'] ?? food['name_fr']),
          quantity: baseQuantity * servings, // Quantité totale pour toute la recette
          unit: ing['unit'] ?? '',
          caloriesPer100g: double.parse((food['calories'] ?? 0).toString()),
          proteinsPer100g: double.parse((food['proteins'] ?? 0).toString()),
          carbsPer100g: double.parse((food['carbs'] ?? 0).toString()),
          fatsPer100g: double.parse((food['fats'] ?? 0).toString()),
        ));
      }

      // Créer la Recipe de base avec les valeurs nutritionnelles de la table recipes
      final baseRecipe = _mapToRecipeFromData(recipeResponse, ingredientsResponse, language);

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
    Map<String, dynamic> recipeData, 
    String language
  ) {
    return Recipe(
      id: recipeData['id'].hashCode,
      name: language == 'fr' ? (recipeData['name_fr'] ?? recipeData['name_en']) : (recipeData['name_en'] ?? recipeData['name_fr']),
      image: recipeData['image_url'] ?? "/placeholder.svg?height=200&width=200",
      duration: _formatDuration(recipeData['duration']),
      // Utiliser les valeurs directement depuis la table recipes (déjà par portion)
      calories: (recipeData['calories per portion'] ?? 0).round(),
      servings: recipeData['servings'] ?? 1,
      tags: _convertTags(recipeData, language),
      proteins: (recipeData['proteins per portion'] ?? 0).round(),
      carbs: (recipeData['carbs per portion'] ?? 0).round(),
      fats: (recipeData['fat per portion'] ?? 0).round(),
      // Pour la liste, on peut utiliser des ingrédients vides (ils seront chargés dans les détails)
      ingredients: [],
      steps: _getStepsFromData(recipeData, language),
      difficulty: _translateDifficulty(recipeData['difficulty'], language),
    );
  }

  /// Convertit les données Supabase en modèle Recipe
  static Recipe _mapToRecipeFromData(
    Map<String, dynamic> recipeData, 
    List<dynamic> ingredients, 
    String language
  ) {
    return Recipe(
      id: recipeData['id'].hashCode,
      name: language == 'fr' ? (recipeData['name_fr'] ?? recipeData['name_en']) : (recipeData['name_en'] ?? recipeData['name_fr']),
      image: recipeData['image_url'] ?? "/placeholder.svg?height=200&width=200",
      duration: _formatDuration(recipeData['duration']),
      // Utiliser les valeurs directement depuis la table recipes (déjà par portion)
      calories: (recipeData['calories per portion'] ?? 0).round(),
      servings: recipeData['servings'] ?? 1,
      tags: _convertTags(recipeData, language),
      proteins: (recipeData['proteins per portion'] ?? 0).round(),
      carbs: (recipeData['carbs per portion'] ?? 0).round(),
      fats: (recipeData['fat per portion'] ?? 0).round(),
      ingredients: _formatIngredientsFromData(ingredients, language),
      steps: _getStepsFromData(recipeData, language),
      difficulty: _translateDifficulty(recipeData['difficulty'], language),
    );
  }

  static String _formatDuration(String? duration) {
    if (duration == null) return "0 min";
    // Convertir "15 minutes" en "15 min" pour compatibilité UI
    return duration.replaceAll('minutes', 'min').replaceAll('minute', 'min');
  }

  static List<String> _convertTags(Map<String, dynamic> recipeData, String language) {
    // Utiliser les tags français ou anglais selon la langue
    dynamic tags;
    if (language == 'fr') {
      tags = recipeData['tags_fr'] ?? recipeData['tags_en'] ?? recipeData['tags'];
    } else {
      tags = recipeData['tags_en'] ?? recipeData['tags_fr'] ?? recipeData['tags'];
    }
    
    if (tags == null) return [];
    if (tags is List) return tags.cast<String>();
    return [];
  }

  static List<String> _formatIngredientsFromData(List<dynamic> ingredients, String language) {
    return ingredients.map((ing) {
      final food = ing['foods'];
      final foodName = language == 'fr' ? (food['name_fr'] ?? food['name_en']) : (food['name_en'] ?? food['name_fr']);
      final quantity = ing['quantity'].toString();
      final unit = ing['unit'] ?? '';
      return "$quantity $unit - $foodName";
    }).cast<String>().toList();
  }

  static List<String> _getStepsFromData(Map<String, dynamic> recipeData, String language) {
    if (language == 'fr') {
      return List<String>.from(recipeData['steps_fr'] ?? recipeData['steps_en'] ?? []);
    } else {
      return List<String>.from(recipeData['steps_en'] ?? recipeData['steps_fr'] ?? []);
    }
  }

  static String _translateDifficulty(String? difficulty, String language) {
    if (difficulty == null) return "Facile";
    
    final translations = {
      'easy': language == 'fr' ? 'Facile' : 'Easy',
      'medium': language == 'fr' ? 'Moyen' : 'Medium', 
      'hard': language == 'fr' ? 'Difficile' : 'Hard',
      'spicy': language == 'fr' ? 'Épicé' : 'Spicy',
    };
    
    return translations[difficulty.toLowerCase()] ?? difficulty;
  }

  /// Récupère les recettes featured (les 5 premières par défaut)
  static Future<List<Recipe>> getFeaturedRecipes({String language = 'fr'}) async {
    final allRecipes = await getAllRecipes(language: language);
    // Prendre minimum 5 recettes, ou toutes si moins de 5
    return allRecipes.take(5).toList();
  }
} 