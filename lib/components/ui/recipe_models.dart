// Modèles de données et logique pour les recettes
import '../../services/recipe_service.dart';

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
    print('🔍 Recipe.fromJson - JSON reçu: ${json.keys.toList()}');
    print('🔍 Recipe.fromJson - Données complètes: $json');
    
    try {
      final id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
      print('🔍 Recipe.fromJson - ID: $id');
      
      final name = json['name_fr'] ?? json['name_en'] ?? '';
      print('🔍 Recipe.fromJson - Name: $name');
      
      final calories = json['calories per portion'] ?? 0;
      print('🔍 Recipe.fromJson - Calories: $calories');
      
      final tags = _parseTagsFromJson(json);
      print('🔍 Recipe.fromJson - Tags: $tags');
      
      final steps = _parseStepsFromJson(json);
      print('🔍 Recipe.fromJson - Steps: $steps');
      
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
      print('🔍 _parseTagsFromJson - tags_fr: ${json['tags_fr']} (type: ${json['tags_fr'].runtimeType})');
      print('🔍 _parseTagsFromJson - tags_en: ${json['tags_en']} (type: ${json['tags_en'].runtimeType})');
      
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
      print('❌ _parseTagsFromJson - Erreur: $e');
      return [];
    }
  }

  // Helper pour parser les étapes depuis JSON
  static List<String> _parseStepsFromJson(Map<String, dynamic> json) {
    try {
      print('🔍 _parseStepsFromJson - steps_fr: ${json['steps_fr']} (type: ${json['steps_fr'].runtimeType})');
      print('🔍 _parseStepsFromJson - steps_en: ${json['steps_en']} (type: ${json['steps_en'].runtimeType})');
      
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
      print('❌ _parseStepsFromJson - Erreur: $e');
      return [];
    }
  }

  // Helpers pour compatibilité avec l'écran de détails
  String get time => duration;
  int get portions => servings;

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
    if (filters != null) {
      // Filtre régime alimentaire avec mapping vers les tags de la base de données
      final regimeFilters = filters['regime'] ?? <String>{};
      if (regimeFilters.isNotEmpty) {
        bool hasMatchingTag = false;
        for (String regimeFilter in regimeFilters) {
          // Utiliser le mapping pour convertir le filtre français vers les tags anglais
          final mappedTags = RecipeFilters.regimeFilterMapping[regimeFilter] ?? [regimeFilter];
          if (mappedTags.any((mappedTag) => tags.contains(mappedTag))) {
            hasMatchingTag = true;
            break;
          }
        }
        if (!hasMatchingTag) {
          return false;
        }
      }

      // Filtre durée
      final dureeFilters = filters['duree'] ?? <String>{};
      if (dureeFilters.isNotEmpty) {
        if (!_matchesDurationFilter(dureeFilters)) {
          return false;
        }
      }

      // Filtre calories
      final caloriesFilters = filters['calories'] ?? <String>{};
      if (caloriesFilters.isNotEmpty) {
        if (!_matchesCaloriesFilter(caloriesFilters)) {
          return false;
        }
      }

      // Filtre difficulté (basé sur durée)
      final difficulteFilters = filters['difficulte'] ?? <String>{};
      if (difficulteFilters.isNotEmpty) {
        if (!_matchesDifficultyFilter(difficulteFilters)) {
          return false;
        }
      }
    }

    return true;
  }

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

// Filtres de recettes
class RecipeFilters {
  static const Map<String, Map<String, List<String>>> advancedFilters = {
    'Régime alimentaire': {
      'regime': ['Végétarien', 'Végan', 'Sans gluten', 'Keto', 'Paléo', 'Méditerranéen']
    },
    'Temps de préparation': {
      'duree': ['Moins de 15 min', '15-30 min', '30-45 min', 'Plus de 45 min']
    },
    'Calories': {
      'calories': ['Moins de 300 kcal', '300-500 kcal', '500-700 kcal', 'Plus de 700 kcal']
    },
    'Difficulté': {
      'difficulte': ['Facile', 'Moyen', 'Difficile']
    },
  };

  // Mapping des filtres de l'interface vers les tags français de la base de données
  static const Map<String, List<String>> regimeFilterMapping = {
    'Végétarien': ['Végétarien', 'À base de plantes'],
    'Végan': ['Végan', 'À base de plantes'],
    'Sans gluten': ['Sans gluten'],
    'Keto': ['Keto', 'Faible en glucides'],
    'Paléo': ['Paléo', 'Faible en glucides'],
    'Méditerranéen': ['Méditerranéen', 'Sain', 'Riche en oméga-3'],
  };

  // Logique de filtrage pure
  static List<Recipe> filterRecipes(
    List<Recipe> recipes, {
    String? searchQuery,
    Map<String, Set<String>>? selectedFilters,
  }) {
    return recipes.where((recipe) => recipe.matchesFilters(
      searchQuery: searchQuery,
      filters: selectedFilters,
    )).toList();
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
    // Données par défaut au cas où Supabase ne répond pas
    Recipe(
      id: 1,
      name: "Bowl protéiné post-workout",
      image: "/placeholder.svg?height=200&width=200",
      duration: "10 min",
      calories: 350,
      servings: 1,
      tags: ["Riche en protéines", "Rapide"],
      proteins: 28,
      carbs: 35,
      fats: 8,
      difficulty: "Facile",
      ingredients: [
        "200g - Yaourt grec nature",
        "1 - Banane mûre",
        "30g - Flocons d'avoine",
        "1 cuillère - Miel",
        "10g - Amandes effilées",
      ],
      steps: [
        "Dans un bol, versez le yaourt grec.",
        "Coupez la banane en rondelles et ajoutez-la au yaourt.",
        "Saupoudrez les flocons d'avoine par-dessus.",
        "Arrosez d'une cuillère de miel.",
        "Terminez en parsemant d'amandes effilées.",
      ],
    ),
    Recipe(
      id: 2,
      name: "Salade de quinoa aux légumes",
      image: "/placeholder.svg?height=200&width=200",
      duration: "15 min",
      calories: 280,
      servings: 1,
      tags: ["Végétarien", "Sain", "À base de plantes"],
      proteins: 12,
      carbs: 35,
      fats: 8,
      difficulty: "Facile",
      ingredients: [
        "100g - Quinoa cuit",
        "50g - Tomates cerises",
        "50g - Concombre",
        "30g - Feta",
        "1 cuillère - Huile d'olive",
      ],
      steps: [
        "Coupez les tomates cerises en deux.",
        "Découpez le concombre en dés.",
        "Mélangez le quinoa avec les légumes.",
        "Ajoutez la feta émiettée.",
        "Assaisonnez avec l'huile d'olive.",
      ],
    ),
    Recipe(
      id: 3,
      name: "Smoothie protéiné banane",
      image: "/placeholder.svg?height=200&width=200",
      duration: "5 min",
      calories: 320,
      servings: 1,
      tags: ["Riche en protéines", "Rapide", "Boisson"],
      proteins: 25,
      carbs: 30,
      fats: 6,
      difficulty: "Facile",
      ingredients: [
        "1 - Banane",
        "200ml - Lait d'amande",
        "30g - Protéine en poudre",
        "1 cuillère - Beurre d'amande",
        "1/2 cuillère - Cannelle",
      ],
      steps: [
        "Pelez et coupez la banane.",
        "Versez tous les ingrédients dans un blender.",
        "Mixez pendant 1 minute.",
        "Servez immédiatement.",
      ],
    ),
    Recipe(
      id: 4,
      name: "Wrap au poulet grillé",
      image: "/placeholder.svg?height=200&width=200",
      duration: "12 min",
      calories: 420,
      servings: 1,
      tags: ["Riche en protéines", "Rapide"],
      proteins: 35,
      carbs: 25,
      fats: 18,
      difficulty: "Facile",
      ingredients: [
        "1 - Tortilla complète",
        "120g - Blanc de poulet",
        "50g - Salade verte",
        "30g - Avocat",
        "2 cuillères - Sauce yaourt",
      ],
      steps: [
        "Faites griller le poulet et découpez-le.",
        "Étalez la sauce sur la tortilla.",
        "Ajoutez la salade et l'avocat.",
        "Disposez le poulet au centre.",
        "Roulez le wrap fermement.",
      ],
    ),
  ];
  
  static List<Recipe> _allRecipes = _featuredRecipes;
  static bool _isLoaded = false;

  // INTERFACE PUBLIQUE IDENTIQUE - getters synchrones
  static List<Recipe> get featuredRecipes => _featuredRecipes;
  static List<Recipe> get allRecipes => _allRecipes;

  // Initialisation - charge les données Supabase en arrière-plan
  static void initialize() {
    _loadRecipesFromSupabase();
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
