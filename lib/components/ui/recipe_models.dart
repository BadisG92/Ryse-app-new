// Modèles de données et logique pour les recettes
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
  });

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
      // Filtre régime alimentaire
      final regimeFilters = filters['regime'] ?? <String>{};
      if (regimeFilters.isNotEmpty) {
        if (!regimeFilters.any((filter) => tags.contains(filter))) {
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

// Données exemple de recettes
class RecipeData {
  static const List<Recipe> featuredRecipes = [
    Recipe(
      id: 1,
      name: "Bowl protéiné post-workout",
      image: "/placeholder.svg?height=200&width=200",
      duration: "10 min",
      calories: 350,
      servings: 1,
      tags: ["Post-workout", "Rapide"],
      proteins: 28,
      carbs: 35,
      fats: 8,
    ),
    Recipe(
      id: 7,
      name: "Saumon teriyaki aux légumes",
      image: "/placeholder.svg?height=200&width=200",
      duration: "25 min",
      calories: 420,
      servings: 2,
      tags: ["Riche en protéines", "Équilibré"],
      proteins: 32,
      carbs: 18,
      fats: 22,
    ),
    Recipe(
      id: 8,
      name: "Overnight oats aux fruits",
      image: "/placeholder.svg?height=200&width=200",
      duration: "5 min",
      calories: 280,
      servings: 1,
      tags: ["Petit-déjeuner", "Préparation"],
      proteins: 12,
      carbs: 45,
      fats: 8,
    ),
  ];

  static const List<Recipe> allRecipes = [
    Recipe(
      id: 1,
      name: "Salade César rapide",
      image: "/placeholder.svg?height=200&width=200",
      duration: "15 min",
      calories: 320,
      servings: 2,
      tags: ["Végétarien", "Sans gluten"],
      proteins: 20,
      carbs: 15,
      fats: 18,
    ),
    Recipe(
      id: 2,
      name: "Saumon grillé aux épinards",
      image: "/placeholder.svg?height=200&width=200",
      duration: "20 min",
      calories: 380,
      servings: 1,
      tags: ["Riche en protéines"],
      proteins: 35,
      carbs: 8,
      fats: 22,
    ),
    Recipe(
      id: 3,
      name: "Smoothie protéiné banane",
      image: "/placeholder.svg?height=200&width=200",
      duration: "5 min",
      calories: 280,
      servings: 1,
      tags: ["Post-workout", "Végétarien"],
      proteins: 25,
      carbs: 30,
      fats: 8,
    ),
    Recipe(
      id: 4,
      name: "Bowl de quinoa aux légumes",
      image: "/placeholder.svg?height=200&width=200",
      duration: "25 min",
      calories: 420,
      servings: 2,
      tags: ["Végan", "Riche en fibres"],
      proteins: 15,
      carbs: 65,
      fats: 12,
    ),
    Recipe(
      id: 5,
      name: "Omelette aux champignons",
      image: "/placeholder.svg?height=200&width=200",
      duration: "12 min",
      calories: 260,
      servings: 1,
      tags: ["Rapide", "Keto"],
      proteins: 18,
      carbs: 5,
      fats: 20,
    ),
    Recipe(
      id: 6,
      name: "Pasta au pesto maison",
      image: "/placeholder.svg?height=200&width=200",
      duration: "18 min",
      calories: 450,
      servings: 2,
      tags: ["Végétarien", "Italien"],
      proteins: 12,
      carbs: 60,
      fats: 18,
    ),
    Recipe(
      id: 7,
      name: "Wrap végan aux légumes",
      image: "/placeholder.svg?height=200&width=200",
      duration: "10 min",
      calories: 280,
      servings: 1,
      tags: ["Végan", "Rapide"],
      proteins: 8,
      carbs: 45,
      fats: 12,
    ),
    Recipe(
      id: 8,
      name: "Curry de lentilles épicé",
      image: "/placeholder.svg?height=200&width=200",
      duration: "35 min",
      calories: 380,
      servings: 3,
      tags: ["Végan", "Riche en fibres"],
      proteins: 18,
      carbs: 52,
      fats: 10,
    ),
    Recipe(
      id: 9,
      name: "Steak grillé keto",
      image: "/placeholder.svg?height=200&width=200",
      duration: "15 min",
      calories: 520,
      servings: 1,
      tags: ["Keto", "Riche en protéines"],
      proteins: 45,
      carbs: 2,
      fats: 35,
    ),
    Recipe(
      id: 10,
      name: "Salade méditerranéenne",
      image: "/placeholder.svg?height=200&width=200",
      duration: "12 min",
      calories: 320,
      servings: 2,
      tags: ["Méditerranéen", "Sans gluten"],
      proteins: 12,
      carbs: 20,
      fats: 22,
    ),
  ];
} 