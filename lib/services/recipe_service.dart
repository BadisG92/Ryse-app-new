import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/supabase_config.dart';
import '../components/ui/recipe_models.dart';
import 'localization_service.dart';

class RecipeService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // Clés de cache
  static const String _cacheKeyAllRecipes = 'recipes_all_cache';
  static const String _cacheKeyFeaturedRecipes = 'recipes_featured_cache';
  static const String _cacheKeyTimestamp = 'recipes_cache_timestamp';
  static const String _cacheKeyVersion = 'recipes_cache_version';
  static const int _currentCacheVersion = 2; // Incrémenté pour forcer le rechargement avec ingredientNames
  static const Duration _cacheValidDuration = Duration(hours: 24); // Cache valide 24h

  /// Récupère toutes les recettes - AVEC CACHE LOCAL
  static Future<List<Recipe>> getAllRecipes() async {
    try {
      // 1. Essayer de charger depuis le cache
      final cachedRecipes = await _loadRecipesFromCache(_cacheKeyAllRecipes);
      if (cachedRecipes != null && cachedRecipes.isNotEmpty) {
        debugPrint('⚡ RecipeService: ${cachedRecipes.length} recettes chargées depuis le cache');

        // Lancer le rechargement en arrière-plan pour mettre à jour le cache
        _refreshRecipesInBackground();

        return cachedRecipes;
      }

      // 2. Si pas de cache, charger depuis Supabase
      debugPrint('🔄 RecipeService: Chargement des recettes depuis Supabase...');
      final recipes = await _fetchAllRecipesFromDB();

      // 3. Sauvegarder dans le cache pour la prochaine fois
      if (recipes.isNotEmpty) {
        await _saveRecipesToCache(_cacheKeyAllRecipes, recipes);
      }

      return recipes;
    } catch (e) {
      debugPrint('❌ RecipeService: Erreur lors de la récupération des recettes: $e');

      // En cas d'erreur, essayer de charger le cache même expiré
      final cachedRecipes = await _loadRecipesFromCache(_cacheKeyAllRecipes, ignoreExpiry: true);
      return cachedRecipes ?? [];
    }
  }

  /// Recharge les recettes en arrière-plan sans bloquer l'UI
  static Future<void> _refreshRecipesInBackground() async {
    try {
      // Vérifier si le cache est encore valide
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheKeyTimestamp);

      if (timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        final isExpired = cacheAge > _cacheValidDuration.inMilliseconds;

        if (!isExpired) {
          debugPrint('✅ RecipeService: Cache encore valide, pas de refresh');
          return;
        }
      }

      debugPrint('🔄 RecipeService: Rafraîchissement en arrière-plan...');
      final freshRecipes = await _fetchAllRecipesFromDB();

      if (freshRecipes.isNotEmpty) {
        await _saveRecipesToCache(_cacheKeyAllRecipes, freshRecipes);
        debugPrint('✅ RecipeService: Cache mis à jour avec ${freshRecipes.length} recettes');
      }
    } catch (e) {
      debugPrint('⚠️ RecipeService: Erreur refresh arrière-plan (non-bloquant): $e');
    }
  }

  /// Charge les recettes depuis Supabase (méthode interne)
  static Future<List<Recipe>> _fetchAllRecipesFromDB() async {
    final recipesResponse = await _supabase
        .from('recipes_database')
        .select('*')
        .eq('is_public', true);

    // Charger tous les ingrédients avec leurs noms pour la recherche
    final ingredientsResponse = await _supabase
        .from('recipe_ingredient_database')
        .select('recipe_id, food_database!inner(name_fr, name_en, name_de)');

    // Créer un map recipe_id -> liste de noms d'ingrédients
    final locService = LocalizationService.instance;
    Map<int, List<String>> recipeIngredientNames = {};
    for (var ing in ingredientsResponse) {
      final recipeId = ing['recipe_id'] as int;
      final food = ing['food_database'];
      if (food != null) {
        final ingredientName = locService.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']);
        if (ingredientName.isNotEmpty) {
          recipeIngredientNames.putIfAbsent(recipeId, () => []);
          recipeIngredientNames[recipeId]!.add(ingredientName);
        }
      }
    }

    debugPrint('📦 RecipeService: Chargé ingrédients pour ${recipeIngredientNames.length} recettes');

    List<Recipe> recipes = [];

    for (int i = 0; i < recipesResponse.length; i++) {
      var recipeData = recipesResponse[i];
      try {
        // Ajouter les noms d'ingrédients au JSON avant de créer la Recipe
        final recipeId = recipeData['id'] as int;
        recipeData['ingredient_names'] = recipeIngredientNames[recipeId] ?? [];

        final recipe = Recipe.fromJson(recipeData);
        recipes.add(recipe);
      } catch (e) {
        debugPrint('❌ Erreur pour recette $i (${recipeData['name_fr'] ?? recipeData['name_en'] ?? 'Nom inconnu'}): $e');
      }
    }

    return recipes;
  }

  /// Sauvegarde les recettes dans le cache local
  static Future<void> _saveRecipesToCache(String key, List<Recipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir les recettes en JSON
      final recipesJson = recipes.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(recipesJson);

      // Sauvegarder avec la version actuelle
      await prefs.setString(key, jsonString);
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_cacheKeyVersion, _currentCacheVersion);

      debugPrint('💾 RecipeService: ${recipes.length} recettes sauvegardées en cache (v$_currentCacheVersion)');
    } catch (e) {
      debugPrint('⚠️ RecipeService: Erreur sauvegarde cache: $e');
    }
  }

  /// Charge les recettes depuis le cache local
  static Future<List<Recipe>?> _loadRecipesFromCache(String key, {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier la version du cache - si différente, invalider
      final cacheVersion = prefs.getInt(_cacheKeyVersion) ?? 0;
      if (cacheVersion < _currentCacheVersion) {
        debugPrint('🔄 RecipeService: Cache obsolète (v$cacheVersion -> v$_currentCacheVersion), rechargement...');
        return null;
      }

      // Vérifier l'expiration du cache
      if (!ignoreExpiry) {
        final timestamp = prefs.getInt(_cacheKeyTimestamp);
        if (timestamp != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge > _cacheValidDuration.inMilliseconds) {
            debugPrint('⏰ RecipeService: Cache expiré (${(cacheAge / 3600000).toStringAsFixed(1)}h)');
            return null;
          }
        }
      }

      // Charger depuis le cache
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final recipesJson = jsonDecode(jsonString) as List;
      final recipes = recipesJson.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();

      return recipes;
    } catch (e) {
      debugPrint('⚠️ RecipeService: Erreur chargement cache: $e');
      return null;
    }
  }

  /// Force le rafraîchissement du cache (utilisé lors du changement de langue)
  static Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyAllRecipes);
      await prefs.remove(_cacheKeyFeaturedRecipes);
      await prefs.remove(_cacheKeyTimestamp);
      debugPrint('🗑️ RecipeService: Cache invalidé');
    } catch (e) {
      debugPrint('⚠️ RecipeService: Erreur invalidation cache: $e');
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
          .select('id, recipe_id, food_id, quantity, display_order, unite_fr, unite_en, unite_de, food_database!inner(*)')
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
          name: locService.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']),
          quantity: baseQuantity * servings, // Quantité totale pour toute la recette
          unit: locService.getTextFromColumns(ing['unite_fr'], ing['unite_en'], ing['unite_de']),
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
      debugPrint('Erreur lors de la récupération du détail de recette: $e');
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
      name: locService.getTextFromColumns(recipeData['name_fr'], recipeData['name_en'], recipeData['name_de']),
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
      name: locService.getTextFromColumns(recipeData['name_fr'], recipeData['name_en'], recipeData['name_de']),
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
    // Utiliser les tags français, anglais ou allemand selon la langue actuelle
    final locService = LocalizationService.instance;
    String tagsString = locService.getTextFromColumns(recipeData['tags_fr'], recipeData['tags_en'], recipeData['tags_de']);
    dynamic tags = tagsString.isEmpty ? recipeData['tags'] : tagsString;

    if (tags == null) return [];
    if (tags is List) return tags.cast<String>();
    return [];
  }

  static List<String> _formatIngredientsFromData(List<dynamic> ingredients) {
    final locService = LocalizationService.instance;
    return ingredients.map((ing) {
      final food = ing['food_database'];
      final foodName = locService.getTextFromColumns(food['name_fr'], food['name_en'], food['name_de']);
      final quantity = ing['quantity'].toString();
      final unit = locService.getTextFromColumns(ing['unite_fr'], ing['unite_en'], ing['unite_de']);
      return "$quantity $unit - $foodName";
    }).cast<String>().toList();
  }

  static List<String> _getStepsFromData(Map<String, dynamic> recipeData) {
    final locService = LocalizationService.instance;
    final stepsString = locService.getTextFromColumns(recipeData['steps_fr'], recipeData['steps_en'], recipeData['steps_de']);

    if (stepsString.isNotEmpty) {
      // Les étapes sont séparées par des "|" - utiliser la même logique que recipe_models.dart
      final stepsList = stepsString.split('|').map((step) {
        String cleanedStep = step.trim();
        // Enlever la numérotation au début (ex: "1. ", "2. ") car il y a déjà les icônes numérotées
        cleanedStep = cleanedStep.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        return cleanedStep;
      }).toList();
      return stepsList.where((step) => step.isNotEmpty).toList();
    }
    return [];
  }

  static String _translateDifficulty(String? difficulty) {
    if (difficulty == null) return "Facile";

    final locService = LocalizationService.instance;
    final translations = {
      'easy': locService.isFrench ? 'Facile' : locService.isGerman ? 'Einfach' : 'Easy',
      'medium': locService.isFrench ? 'Moyen' : locService.isGerman ? 'Mittel' : 'Medium',
      'hard': locService.isFrench ? 'Difficile' : locService.isGerman ? 'Schwer' : 'Hard',
      'spicy': locService.isFrench ? 'Épicé' : locService.isGerman ? 'Scharf' : 'Spicy',
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
      debugPrint('🔍 RecipeService.getAllUniqueTags - Récupération des tags...');

      // Récupérer toutes les recettes
      final recipesResponse = await _supabase
          .from('recipes_database')
          .select('tags_fr, tags_en, tags_de')
          .eq('is_public', true);

      debugPrint('🔍 Found ${recipesResponse.length} recipes to extract tags from');

      final locService = LocalizationService.instance;
      Set<String> allTags = {};

      for (var recipe in recipesResponse) {
        // Récupérer les tags selon la langue actuelle
        String tagsString = locService.getTextFromColumns(recipe['tags_fr'], recipe['tags_en'], recipe['tags_de']);

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

      debugPrint('✅ Extracted ${allTags.length} unique tags: ${allTags.take(10).toList()}...');
      return allTags;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des tags: $e');
      return {};
    }
  }
} 