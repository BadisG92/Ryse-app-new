// Modèles de données et logique pour les recettes
import '../../services/recipe_service.dart';
import '../../services/content_tags_service.dart';
import '../../config/app_config.dart';

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
  double get totalCalories => (caloriesPer100g * quantity) / 100;
  double get totalProteins => (proteinsPer100g * quantity) / 100;
  double get totalCarbs => (carbsPer100g * quantity) / 100;
  double get totalFats => (fatsPer100g * quantity) / 100;

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

    // Diviser par le nombre de portions actuelles pour obtenir la valeur par portion
    return {
      'calories': (totalCalories / currentPortions).round(),
      'proteins': (totalProteins / currentPortions).round(),
      'carbs': (totalCarbs / currentPortions).round(),
      'fats': (totalFats / currentPortions).round(),
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
  });

  // Factory pour créer une Recipe depuis JSON (base de données)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      final name = json['name_fr'] ?? json['name_en'] ?? '';
      final calories = json['calories per portion'] ?? 0;
      final tags = _parseTagsFromJson(json);
      final steps = _parseStepsFromJson(json);
      
      return Recipe(
        id: id,
        name: name,
        image: json['image_url'] ?? "/placeholder.svg?height=200&width=200",
        duration: json['duration']?.toString() ?? "0 min",
        calories: calories,
        servings: json['servings'] ?? 1,
        tags: tags,
        proteins: json['proteins per portion'] ?? 0,
        carbs: json['carbs per portion'] ?? 0,
        fats: json['fat per portion'] ?? 0,
        ingredients: [], // Les ingrédients seront chargés séparément
        steps: steps,
        difficulty: json['difficulty'] ?? 'Facile',
      );
    } catch (e) {
      print('❌ Recipe.fromJson - Erreur: $e');
      rethrow;
    }
  }

  // Helper pour parser les tags depuis JSON
  static List<String> _parseTagsFromJson(Map<String, dynamic> json) {
    try {
      // Gérer les tags français en priorité
      if (json['tags_fr'] != null) {
        if (json['tags_fr'] is String && json['tags_fr'].toString().isNotEmpty) {
          final tagsList = json['tags_fr'].toString().split(',').map((tag) => tag.trim()).toList();
          return tagsList.where((tag) => tag.isNotEmpty).toList();
        } else if (json['tags_fr'] is List) {
          return List<String>.from(json['tags_fr']);
        }
      }
      
      // Sinon utiliser les tags anglais
      if (json['tags_en'] != null) {
        if (json['tags_en'] is String && json['tags_en'].toString().isNotEmpty) {
          final tagsList = json['tags_en'].toString().split(',').map((tag) => tag.trim()).toList();
          return tagsList.where((tag) => tag.isNotEmpty).toList();
        } else if (json['tags_en'] is List) {
          return List<String>.from(json['tags_en']);
        }
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Helper pour parser les étapes depuis JSON
  static List<String> _parseStepsFromJson(Map<String, dynamic> json) {
    try {
      // Gérer les étapes françaises en priorité
      if (json['steps_fr'] != null) {
        if (json['steps_fr'] is String && json['steps_fr'].toString().isNotEmpty) {
          // D'après les logs, les étapes sont séparées par des "|", pas des points
          final stepsList = json['steps_fr'].toString().split('|').map((step) => step.trim()).toList();
          return stepsList.where((step) => step.isNotEmpty).toList();
        } else if (json['steps_fr'] is List) {
          return List<String>.from(json['steps_fr']);
        }
      }
      
      // Sinon utiliser les étapes anglaises
      if (json['steps_en'] != null) {
        if (json['steps_en'] is String && json['steps_en'].toString().isNotEmpty) {
          final stepsList = json['steps_en'].toString().split('|').map((step) => step.trim()).toList();
          return stepsList.where((step) => step.isNotEmpty).toList();
        } else if (json['steps_en'] is List) {
          return List<String>.from(json['steps_en']);
        }
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Helpers pour compatibilité avec l'écran de détails
  String get time => duration;
  int get portions => servings;
  
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
        print('\n📋 Test de "$name"');
        print('   Tags recette: $tags');
      }
      
      // Pour chaque catégorie de filtre actif
      for (final filterEntry in filters.entries) {
        final categoryName = filterEntry.key;
        final selectedOptions = filterEntry.value;
        
        if (selectedOptions.isNotEmpty) {
          bool hasMatch = false;
          
          if (shouldLog) {
            print('   Catégorie "$categoryName": cherche ${selectedOptions.toList()}');
          }
          
          // Vérifier chaque option sélectionnée
          for (String selectedOption in selectedOptions) {
            // Vérifier chaque tag de la recette
            for (String recipeTag in tags) {
              // Comparaison exacte ET insensible à la casse
              if (recipeTag.toLowerCase().trim() == selectedOption.toLowerCase().trim()) {
                hasMatch = true;
                if (shouldLog) {
                  print('   ✅ MATCH: "$recipeTag" == "$selectedOption"');
                }
                break;
              }
            }
            
            if (hasMatch) break;
          }
          
          // Si aucun match pour cette catégorie, exclure
          if (!hasMatch) {
            if (shouldLog) {
              print('   ❌ Pas de match pour "$categoryName"');
            }
            return false;
          }
        }
      }
      
      if (shouldLog) {
        print('   ✅ Recette acceptée!');
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

  // Interface publique - retourne les filtres (vides au début, chargés dynamiquement)
  static Map<String, Map<String, List<String>>> get advancedFilters => _advancedFilters;
  static Map<String, List<String>> get regimeFilterMapping => _regimeFilterMapping;

  // Initialisation - charge les catégories dynamiquement depuis Supabase
  static void initialize() {
    print('🟡 RecipeFilters.initialize() called');
    print('🟡 _isLoaded = $_isLoaded');
    if (!_isLoaded) {
      print('🟡 Starting _loadFiltersFromSupabase()...');
      _loadFiltersFromSupabase();
    } else {
      print('🟡 Filters already loaded: $_advancedFilters');
    }
  }

  // Charge les filtres depuis content_tags
  static Future<void> _loadFiltersFromSupabase() async {
    try {
      print('🔄 Chargement des filtres depuis content_tags...');
      
      // Récupérer les tags organisés depuis content_tags
      final organizedTags = await ContentTagsService.getOrganizedTagsForFilters();
      
      if (organizedTags.isEmpty) {
        print('⚠️ Aucun tag trouvé dans content_tags, utilisation des filtres par défaut');
        _useDefaultFilters();
        _isLoaded = true;
        return;
      }
      
      print('✅ Tags trouvés dans content_tags: ${organizedTags.keys.length} catégories');
      
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
          print('   - Catégorie "$categoryName": ${tags.length} tags');
        }
      }
      
      print('✅ Filtres chargés depuis content_tags: ${_advancedFilters.keys.toList()}');
      _isLoaded = true;
      
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
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
      print('🔍 === DÉBUT FILTRAGE ===');
      print('🔍 Nombre de recettes: ${recipes.length}');
      print('🔍 Filtres actifs:');
      for (var entry in selectedFilters.entries) {
        if (entry.value.isNotEmpty) {
          print('   - ${entry.key}: ${entry.value.toList()}');
        }
      }
    }
    
    final filtered = recipes.where((recipe) => recipe.matchesFilters(
      searchQuery: searchQuery,
      filters: selectedFilters,
    )).toList();
    
    if (selectedFilters != null && selectedFilters.isNotEmpty) {
      print('✅ === FIN FILTRAGE ===');
      print('✅ Résultat: ${filtered.length} recettes trouvées');
      if (filtered.isNotEmpty) {
        print('✅ Exemples: ${filtered.take(3).map((r) => r.name).toList()}');
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
  static List<Recipe> _featuredRecipes = [
    // Pas de données par défaut - utiliser uniquement Supabase
  ];
  
  static List<Recipe> _allRecipes = _featuredRecipes;
  static bool _isLoaded = false;

  // INTERFACE PUBLIQUE IDENTIQUE - getters synchrones
  static List<Recipe> get featuredRecipes => _featuredRecipes;
  static List<Recipe> get allRecipes => _allRecipes;

  // Initialisation - charge les données Supabase en arrière-plan
  static void initialize() {
    _loadRecipesFromSupabase();
    // Aussi initialiser les filtres dynamiques
    RecipeFilters.initialize();
  }

  // Charge les données depuis Supabase et met à jour les listes
  static Future<void> _loadRecipesFromSupabase() async {
    try {
      final supabaseAllRecipes = await RecipeService.getAllRecipes();
      final supabaseFeaturedRecipes = await RecipeService.getFeaturedRecipes();
      
      // Mettre à jour les listes avec les données Supabase
      _allRecipes = supabaseAllRecipes.isNotEmpty ? supabaseAllRecipes : _allRecipes;
      
      // S'assurer qu'il y a au moins 3 recettes featured pour le défilement
      if (supabaseFeaturedRecipes.length >= 3) {
        _featuredRecipes = supabaseFeaturedRecipes;
      } else {
        // Utiliser les données par défaut si pas assez de recettes Supabase
        print('⚠️ Pas assez de recettes Supabase (${supabaseFeaturedRecipes.length}), utilisation des données par défaut');
      }
      
      _isLoaded = true;
      
      print('✅ Recettes chargées: ${_allRecipes.length} recettes, ${_featuredRecipes.length} featured');
    } catch (e) {
      print('⚠️ Erreur Supabase, utilisation des données par défaut: $e');
      // Garde les données par défaut en cas d'erreur
    }
  }

  // Méthode pour forcer le rechargement (optionnel)
  static Future<void> refresh() async {
    await _loadRecipesFromSupabase();
  }

} 
