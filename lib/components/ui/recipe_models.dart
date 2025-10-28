// Modèles de données et logique pour les recettes
import 'package:flutter/foundation.dart';
import '../../services/recipe_service.dart';
import '../../services/content_tags_service.dart';
import '../../config/app_config.dart';
import '../../services/localization_service.dart';

// Modèle pour un ingrédient dans une recette
class RecipeIngredient {
  final String id;
  final String name;
  final double quantity; // Quantité pour la recette complète (base × servings)
  final String unit;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double carbsPer100g;
  final double fatsPer100g;

  RecipeIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
  });

  // Calculer les valeurs nutritionnelles pour cette quantité d'ingrédient
  double get totalCalories {
    final result = (caloriesPer100g * quantity) / 100;
    return result.isFinite ? result : 0;
  }

  double get totalProteins {
    final result = (proteinsPer100g * quantity) / 100;
    return result.isFinite ? result : 0;
  }

  double get totalCarbs {
    final result = (carbsPer100g * quantity) / 100;
    return result.isFinite ? result : 0;
  }

  double get totalFats {
    final result = (fatsPer100g * quantity) / 100;
    return result.isFinite ? result : 0;
  }

  // Créer une copie avec une nouvelle quantité
  RecipeIngredient copyWith({
    double? quantity,
  }) {
    return RecipeIngredient(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      unit: unit,
      caloriesPer100g: caloriesPer100g,
      proteinsPer100g: proteinsPer100g,
      carbsPer100g: carbsPer100g,
      fatsPer100g: fatsPer100g,
    );
  }

  // Formatter pour l'affichage (ex: "200 g - Poulet")
  String get displayText => "${quantity.toStringAsFixed(1)} $unit - $name";
}

// Modèle pour gérer l'état d'une recette avec portions modifiables
class RecipeDetailModel {
  final Recipe baseRecipe;
  List<RecipeIngredient> ingredients;
  int currentPortions;

  RecipeDetailModel({
    required this.baseRecipe,
    required this.ingredients,
    required this.currentPortions,
  });

  // Calcul des valeurs nutritionnelles pour 1 portion
  Map<String, int> get nutritionPer1Portion {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var ingredient in ingredients) {
      totalCalories += ingredient.totalCalories;
      totalProteins += ingredient.totalProteins;
      totalCarbs += ingredient.totalCarbs;
      totalFats += ingredient.totalFats;
    }

    // Protection contre la division par zéro
    final portions = currentPortions > 0 ? currentPortions : 1;

    // Diviser par le nombre de portions actuelles pour obtenir la valeur par portion
    return {
      'calories': (totalCalories / portions).round(),
      'proteins': (totalProteins / portions).round(),
      'carbs': (totalCarbs / portions).round(),
      'fats': (totalFats / portions).round(),
    };
  }

  // Changer le nombre de portions et ajuster les quantités d'ingrédients
  void updatePortions(int newPortions) {
    if (newPortions <= 0) return;
    
    double ratio = newPortions / currentPortions;
    
    ingredients = ingredients.map((ingredient) {
      return ingredient.copyWith(
        quantity: ingredient.quantity * ratio,
      );
    }).toList();
    
    currentPortions = newPortions;
  }

  // Modifier la quantité d'un ingrédient spécifique
  void updateIngredientQuantity(String ingredientId, double newQuantity) {
    final index = ingredients.indexWhere((ing) => ing.id == ingredientId);
    if (index != -1) {
      ingredients[index] = ingredients[index].copyWith(quantity: newQuantity);
    }
  }
}

class Recipe {
  final int id;
  final String name;
  final String image;
  final String duration;
  final int calories;
  final int servings;
  final List<String> tags;
  final int proteins;
  final int carbs;
  final int fats;
  final List<String> ingredients;
  final List<String> steps;
  final String difficulty;

  // Données brutes pour le cache (optionnelles - utilisées seulement pour la sérialisation)
  final String? nameFr;
  final String? nameEn;
  final String? tagsFr;
  final String? tagsEn;
  final String? stepsFr;
  final String? stepsEn;

  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.duration,
    required this.calories,
    required this.servings,
    required this.tags,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.ingredients,
    required this.steps,
    required this.difficulty,
    this.nameFr,
    this.nameEn,
    this.tagsFr,
    this.tagsEn,
    this.stepsFr,
    this.stepsEn,
  });

  // Factory pour créer une Recipe depuis JSON (base de données)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      final name = LocalizationService.instance.getTextFromColumns(json['name_fr'], json['name_en']);

      // Protection contre les valeurs infinies ou invalides
      int _safeInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) {
          if (value.isFinite) return value.round();
          return defaultValue;
        }
        final parsed = int.tryParse(value.toString());
        return parsed ?? defaultValue;
      }

      final calories = _safeInt(json['calories per portion'], 0);
      final servings = _safeInt(json['servings'], 1);
      final proteins = _safeInt(json['proteins per portion'], 0);
      final carbs = _safeInt(json['carbs per portion'], 0);
      final fats = _safeInt(json['fat per portion'], 0);

      final tags = _parseTagsFromJson(json);
      final steps = _parseStepsFromJson(json);

      return Recipe(
        id: id,
        name: name,
        image: json['image_url'] ?? "/placeholder.svg?height=200&width=200",
        duration: json['duration']?.toString() ?? "0 min",
        calories: calories,
        servings: servings > 0 ? servings : 1, // Assurer qu'on a au moins 1 portion
        tags: tags,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        ingredients: [], // Les ingrédients seront chargés séparément
        steps: steps,
        difficulty: json['difficulty'] ?? 'Facile',
        // Préserver les données brutes pour le cache
        nameFr: json['name_fr']?.toString(),
        nameEn: json['name_en']?.toString(),
        tagsFr: json['tags_fr']?.toString(),
        tagsEn: json['tags_en']?.toString(),
        stepsFr: json['steps_fr']?.toString(),
        stepsEn: json['steps_en']?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Recipe.fromJson - Erreur: $e');
      rethrow;
    }
  }

  // Helper pour parser les tags depuis JSON
  static List<String> _parseTagsFromJson(Map<String, dynamic> json) {
    try {
      // Utiliser LocalizationService pour sélectionner la bonne langue
      final locService = LocalizationService.instance;
      final tagsText = locService.getTextFromColumns(json['tags_fr'], json['tags_en']);
      
      if (tagsText.isNotEmpty) {
        final tagsList = tagsText.split(',').map((tag) => tag.trim()).toList();
        return tagsList.where((tag) => tag.isNotEmpty).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Helper pour parser les étapes depuis JSON
  static List<String> _parseStepsFromJson(Map<String, dynamic> json) {
    try {
      // Utiliser LocalizationService pour sélectionner la bonne langue
      final locService = LocalizationService.instance;
      final stepsText = locService.getTextFromColumns(json['steps_fr'], json['steps_en']);
      
      if (stepsText.isNotEmpty) {
        // D'après les logs, les étapes sont séparées par des "|", pas des points
        final stepsList = stepsText.split('|').map((step) {
          String cleanedStep = step.trim();
          // Enlever la numérotation au début (ex: "1. ", "2. ") car il y a déjà les icônes numérotées
          cleanedStep = cleanedStep.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          return cleanedStep;
        }).toList();
        return stepsList.where((step) => step.isNotEmpty).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Conversion en JSON pour le cache
  // IMPORTANT: On stocke les données brutes FR/EN pour préserver les deux langues
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_fr': nameFr ?? name, // Utiliser les données brutes si disponibles
      'name_en': nameEn ?? name,
      'image_url': image,
      'duration': duration,
      'calories per portion': calories,
      'servings': servings,
      'tags_fr': tagsFr ?? tags.join(', '),
      'tags_en': tagsEn ?? tags.join(', '),
      'proteins per portion': proteins,
      'carbs per portion': carbs,
      'fat per portion': fats,
      'steps_fr': stepsFr ?? steps.join(' | '),
      'steps_en': stepsEn ?? steps.join(' | '),
      'difficulty': difficulty,
    };
  }

  // Helpers pour compatibilité avec l'écran de détails
  String get time => duration;
  int get portions => servings;

  // Getters sûrs pour éviter les erreurs d'affichage avec Infinity
  int get safeCalories => calories.isFinite ? calories : 0;
  int get safeProteins => proteins.isFinite ? proteins : 0;
  int get safeCarbs => carbs.isFinite ? carbs : 0;
  int get safeFats => fats.isFinite ? fats : 0;
  int get safeServings => servings > 0 ? servings : 1;
  
  // Helper pour normaliser les strings pour comparaison
  static String _normalizeString(String str) {
    return str.toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i');
  }

  // Helper pour vérifier si la recette correspond aux filtres
  bool matchesFilters({
    String? searchQuery,
    Map<String, Set<String>>? filters,
  }) {
    // Recherche par nom
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (!name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
    }

    // Filtres avancés
    if (filters != null && filters.isNotEmpty) {
      // Log initial une fois par recette
      bool shouldLog = name.contains("Smoothie") || name.contains("Pancakes") || name.contains("Salade");
      
      if (shouldLog) {
        debugPrint('\n📋 Test de "$name"');
        debugPrint('   Tags recette: $tags');
      }
      
      // Pour chaque catégorie de filtre actif
      for (final filterEntry in filters.entries) {
        final categoryName = filterEntry.key;
        final selectedOptions = filterEntry.value;
        
        if (selectedOptions.isNotEmpty) {
          bool hasMatch = false;
          
          if (shouldLog) {
            debugPrint('   Catégorie "$categoryName": cherche ${selectedOptions.toList()}');
          }
          
          // Vérifier chaque option sélectionnée
          for (String selectedOption in selectedOptions) {
            // Vérifier chaque tag de la recette
            for (String recipeTag in tags) {
              // Comparaison exacte ET insensible à la casse
              if (recipeTag.toLowerCase().trim() == selectedOption.toLowerCase().trim()) {
                hasMatch = true;
                if (shouldLog) {
                  debugPrint('   ✅ MATCH: "$recipeTag" == "$selectedOption"');
                }
                break;
              }
            }
            
            if (hasMatch) break;
          }
          
          // Si aucun match pour cette catégorie, exclure
          if (!hasMatch) {
            if (shouldLog) {
              debugPrint('   ❌ Pas de match pour "$categoryName"');
            }
            return false;
          }
        }
      }
      
      if (shouldLog) {
        debugPrint('   ✅ Recette acceptée!');
      }
    }

    return true;
  }

  // Méthodes spéciales pour certains filtres (activées si nécessaire)

  bool _matchesDurationFilter(Set<String> filters) {
    final durationMinutes = _extractDurationMinutes();
    
    for (String filter in filters) {
      switch (filter) {
        case 'Moins de 15 min':
          if (durationMinutes < 15) return true;
          break;
        case '15-30 min':
          if (durationMinutes >= 15 && durationMinutes <= 30) return true;
          break;
        case '30-45 min':
          if (durationMinutes > 30 && durationMinutes <= 45) return true;
          break;
        case 'Plus de 45 min':
          if (durationMinutes > 45) return true;
          break;
      }
    }
    return false;
  }

  bool _matchesCaloriesFilter(Set<String> filters) {
    for (String filter in filters) {
      switch (filter) {
        case 'Moins de 300 kcal':
          if (calories < 300) return true;
          break;
        case '300-500 kcal':
          if (calories >= 300 && calories <= 500) return true;
          break;
        case '500-700 kcal':
          if (calories > 500 && calories <= 700) return true;
          break;
        case 'Plus de 700 kcal':
          if (calories > 700) return true;
          break;
      }
    }
    return false;
  }

  bool _matchesDifficultyFilter(Set<String> filters) {
    final durationMinutes = _extractDurationMinutes();
    
    for (String filter in filters) {
      switch (filter) {
        case 'Facile':
          if (durationMinutes <= 15) return true;
          break;
        case 'Moyen':
          if (durationMinutes > 15 && durationMinutes <= 30) return true;
          break;
        case 'Difficile':
          if (durationMinutes > 30) return true;
          break;
      }
    }
    return false;
  }

  int _extractDurationMinutes() {
    // Extraire les minutes depuis "X min"
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 0;
  }
}

// Filtres de recettes - Données dynamiques depuis Supabase
class RecipeFilters {
  // Variables privées pour stocker les catégories dynamiques
  static Map<String, Map<String, List<String>>> _advancedFilters = {};
  static Map<String, List<String>> _regimeFilterMapping = {};
  static bool _isLoaded = false;
  static String _lastLanguage = '';
  static bool _isListenerSetup = false;
  
  // Listener pour les changements de langue
  static void _setupLanguageListener() {
    if (!_isListenerSetup) {
      LocalizationService.instance.addListener(_onLanguageChanged);
      _isListenerSetup = true;
      _lastLanguage = LocalizationService.instance.currentLanguageCode;
      debugPrint('✅ RecipeFilters: Language listener configuré');
    }
  }
  
  // Callback appelé lors du changement de langue
  static void _onLanguageChanged() {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;
    if (currentLanguage != _lastLanguage) {
      debugPrint('🔄 RecipeFilters: Changement de langue détecté ($currentLanguage)');
      _lastLanguage = currentLanguage;
      _resetAndReload();
    }
  }
  
  // Réinitialise et recharge les filtres
  static void _resetAndReload() {
    _advancedFilters = {};
    _regimeFilterMapping = {};
    _isLoaded = false;
    _loadFiltersFromSupabase();
  }

  // Interface publique - retourne les filtres (vides au début, chargés dynamiquement)
  static Map<String, Map<String, List<String>>> get advancedFilters => _advancedFilters;
  static Map<String, List<String>> get regimeFilterMapping => _regimeFilterMapping;

  // Initialisation - charge les catégories dynamiquement depuis Supabase
  static void initialize() {
    debugPrint('🟡 RecipeFilters.initialize() called');
    debugPrint('🟡 _isLoaded = $_isLoaded');
    
    // Configurer le listener une seule fois
    _setupLanguageListener();
    
    if (!_isLoaded) {
      debugPrint('🟡 Starting _loadFiltersFromSupabase()...');
      _loadFiltersFromSupabase();
    } else {
      debugPrint('🟡 Filters already loaded: $_advancedFilters');
    }
  }

  // Charge les filtres depuis content_tags
  static Future<void> _loadFiltersFromSupabase() async {
    try {
      debugPrint('🔄 Chargement des filtres depuis content_tags...');
      
      // Récupérer les tags organisés depuis content_tags
      final organizedTags = await ContentTagsService.getOrganizedTagsForFilters();
      
      if (organizedTags.isEmpty) {
        debugPrint('⚠️ Aucun tag trouvé dans content_tags, utilisation des filtres par défaut');
        _useDefaultFilters();
        _isLoaded = true;
        return;
      }
      
      debugPrint('✅ Tags trouvés dans content_tags: ${organizedTags.keys.length} catégories');
      
      // Construire la structure de filtres pour l'UI
      _advancedFilters = {};
      
      for (final entry in organizedTags.entries) {
        final categoryName = entry.key;
        final tags = entry.value;
        
        if (tags.isNotEmpty) {
          // Structure: Map<categoryName, Map<categoryName, List<tags>>>
          _advancedFilters[categoryName] = {
            categoryName: tags
          };
          debugPrint('   - Catégorie "$categoryName": ${tags.length} tags');
        }
      }
      
      debugPrint('✅ Filtres chargés depuis content_tags: ${_advancedFilters.keys.toList()}');
      _isLoaded = true;
      
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement: $e');
      _useDefaultFilters();
      _isLoaded = true;
    }
  }

  // Génère une clé de filtre depuis le nom de catégorie
  static String _generateFilterKey(String categoryName) {
    // Convertir le nom français en clé simple
    return categoryName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('\'', '')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ù', 'u')
        .replaceAll('è', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i');
  }

  // Utilise des filtres par défaut en cas d'erreur
  static void _useDefaultFilters() {
    _advancedFilters = {
      'Calories': {
        'calories': ['Moins de 300 kcal', '300-500 kcal', '500-700 kcal', 'Plus de 700 kcal']
      },
      'Temps de préparation': {
        'duree': ['Moins de 15 min', '15-30 min', '30-45 min', 'Plus de 45 min']
      },
    };
    _regimeFilterMapping = {};
  }

  // Convertit le nom de catégorie en clé pour la logique
  static String _getCategoryKey(String category) {
    // Les catégories correspondent maintenant aux clés content_tags
    switch (category) {
      case 'type_alimentation':
        return 'regime';
      case 'moment_consommation':
        return 'moment';
      case 'type_plat':
        return 'type';
      case 'difficulte':
        return 'difficulte';
      case 'duree':
        return 'duree';
      case 'calories':
        return 'calories';
      default:
        return 'autres';
    }
  }

  // Convertit une clé de catégorie en nom d'affichage
  static String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'type_alimentation':
        return 'Type d\'alimentation';
      case 'moment_consommation':
        return 'Moment de consommation';
      case 'type_plat':
        return 'Type de plat';
      case 'difficulte':
        return 'Difficulté';
      case 'duree':
        return 'Durée';
      case 'calories':
        return 'Calories';
      case 'autres':
        return 'Autres';
      default:
        return categoryKey;
    }
  }

  // Extraire les tags relatifs au moment de consommation
  static List<String> _extractMomentTags(Set<String> allTags) {
    const momentKeywords = ['petit-déjeuner', 'breakfast', 'déjeuner', 'lunch', 'collation', 'snack', 'dîner', 'dinner', 'goûter', 'apéritif'];
    return allTags.where((tag) => 
      momentKeywords.any((keyword) => tag.toLowerCase().contains(keyword.toLowerCase()))
    ).toList()..sort();
  }

  // Extraire les tags relatifs au régime alimentaire
  static List<String> _extractRegimeTags(Set<String> allTags) {
    const regimeKeywords = ['végétarien', 'vegetarian', 'végan', 'vegan', 'gluten', 'keto', 'paléo', 'paleo', 'méditerranéen', 'mediterranean', 'bio', 'organic'];
    return allTags.where((tag) => 
      regimeKeywords.any((keyword) => tag.toLowerCase().contains(keyword.toLowerCase()))
    ).toList()..sort();
  }

  // Créer le mapping dynamique pour les régimes
  static Map<String, List<String>> _createRegimeMapping(Set<String> allTags) {
    Map<String, List<String>> mapping = {};
    
    // Grouper les tags similaires
    final regimeTags = _extractRegimeTags(allTags);
    for (final tag in regimeTags) {
      mapping[tag] = [tag]; // Mapping simple 1:1 pour commencer
    }
    
    return mapping;
  }

  // Logique de filtrage pure
  static List<Recipe> filterRecipes(
    List<Recipe> recipes, {
    String? searchQuery,
    Map<String, Set<String>>? selectedFilters,
  }) {
    if (selectedFilters != null && selectedFilters.isNotEmpty) {
      debugPrint('🔍 === DÉBUT FILTRAGE ===');
      debugPrint('🔍 Nombre de recettes: ${recipes.length}');
      debugPrint('🔍 Filtres actifs:');
      for (var entry in selectedFilters.entries) {
        if (entry.value.isNotEmpty) {
          debugPrint('   - ${entry.key}: ${entry.value.toList()}');
        }
      }
    }
    
    final filtered = recipes.where((recipe) => recipe.matchesFilters(
      searchQuery: searchQuery,
      filters: selectedFilters,
    )).toList();
    
    if (selectedFilters != null && selectedFilters.isNotEmpty) {
      debugPrint('✅ === FIN FILTRAGE ===');
      debugPrint('✅ Résultat: ${filtered.length} recettes trouvées');
      if (filtered.isNotEmpty) {
        debugPrint('✅ Exemples: ${filtered.take(3).map((r) => r.name).toList()}');
      }
    }
    
    return filtered;
  }

  // Obtenir les filtres actifs avec leurs clés
  static List<Map<String, String>> getActiveFilterTags(
    Map<String, Set<String>> selectedFilters,
  ) {
    List<Map<String, String>> filters = [];
    
    selectedFilters.forEach((filterKey, selectedValues) {
      for (String value in selectedValues) {
        filters.add({
          'label': value,
          'type': 'advanced',
          'key': filterKey,
        });
      }
    });
    
    return filters;
  }

  // Compter les filtres sélectionnés
  static int countSelectedFilters(Map<String, Set<String>> selectedFilters) {
    return selectedFilters.values
        .map((set) => set.length)
        .fold(0, (sum, count) => sum + count);
  }
}

// Données de recettes - INTERFACE IDENTIQUE pour l'UI
class RecipeData {
  // Variables privées pour stocker les données Supabase
  static List<Recipe> _featuredRecipes = [];
  static List<Recipe> _allRecipes = [];
  static bool _isLoaded = false;
  static bool _isLoading = false; // NOUVEAU: Pour tracking du chargement
  static String _lastLanguage = '';
  static bool _isListenerSetup = false;

  // INTERFACE PUBLIQUE IDENTIQUE - getters synchrones
  static List<Recipe> get featuredRecipes => _featuredRecipes;
  static List<Recipe> get allRecipes => _allRecipes;
  static bool get isLoading => _isLoading; // NOUVEAU: Pour afficher loader dans l'UI

  // Listener pour les changements de langue
  static void _setupLanguageListener() {
    if (!_isListenerSetup) {
      LocalizationService.instance.addListener(_onLanguageChanged);
      _isListenerSetup = true;
      _lastLanguage = LocalizationService.instance.currentLanguageCode;
      debugPrint('✅ RecipeData: Language listener configuré');
    }
  }
  
  // Callback appelé lors du changement de langue
  static void _onLanguageChanged() {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;
    if (currentLanguage != _lastLanguage) {
      debugPrint('🔄 RecipeData: Changement de langue détecté ($currentLanguage)');
      _lastLanguage = currentLanguage;
      _resetAndReload();
    }
  }

  // Réinitialise et recharge les données
  static void _resetAndReload() {
    _isLoaded = false;
    // Invalider le cache car la langue a changé
    RecipeService.invalidateCache();
    _loadRecipesFromSupabase();
  }

  // Initialisation - charge les données Supabase en arrière-plan
  static void initialize() {
    // Configurer le listener une seule fois
    _setupLanguageListener();
    
    _loadRecipesFromSupabase();
    // Aussi initialiser les filtres dynamiques
    RecipeFilters.initialize();
  }

  // Charge les données depuis Supabase et met à jour les listes
  static Future<void> _loadRecipesFromSupabase() async {
    if (_isLoading) {
      debugPrint('⏳ RecipeData: Chargement déjà en cours, skip...');
      return;
    }

    _isLoading = true;
    debugPrint('🔄 RecipeData: Début chargement des recettes...');

    try {
      // RecipeService.getAllRecipes() charge depuis cache ou DB
      final supabaseAllRecipes = await RecipeService.getAllRecipes();
      final supabaseFeaturedRecipes = await RecipeService.getFeaturedRecipes();

      debugPrint('📦 RecipeData: Reçu ${supabaseAllRecipes.length} recettes, ${supabaseFeaturedRecipes.length} featured');

      // Mettre à jour les listes avec les données Supabase
      _allRecipes = supabaseAllRecipes;
      _featuredRecipes = supabaseFeaturedRecipes.isNotEmpty ? supabaseFeaturedRecipes : supabaseAllRecipes.take(5).toList();

      _isLoaded = true;
      _isLoading = false;

      debugPrint('✅ RecipeData: ${_allRecipes.length} recettes chargées, ${_featuredRecipes.length} featured');
    } catch (e) {
      debugPrint('❌ RecipeData: Erreur chargement: $e');
      _isLoading = false;
      // Garder les listes vides en cas d'erreur
    }
  }

  // Méthode pour forcer le rechargement (optionnel)
  static Future<void> refresh() async {
    await _loadRecipesFromSupabase();
  }

} 
