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
      difficulty: "Moyen",
      ingredients: [
        "300g - Filet de saumon",
        "3 cuillères - Sauce teriyaki",
        "1 - Courgette",
        "1 - Poivron rouge",
        "100g - Brocolis",
        "1 cuillère - Huile d'olive",
      ],
      steps: [
        "Préchauffez le four à 200°C.",
        "Coupez les légumes en morceaux uniformes.",
        "Placez le saumon dans un plat allant au four.",
        "Badigeonnez le saumon de sauce teriyaki.",
        "Disposez les légumes autour du saumon.",
        "Arrosez d'huile d'olive et enfournez 20 minutes.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "50g - Flocons d'avoine",
        "200ml - Lait d'amande",
        "1 cuillère - Graines de chia",
        "1 cuillère - Miel",
        "100g - Fruits rouges",
      ],
      steps: [
        "Mélangez les flocons d'avoine et le lait d'amande dans un bocal.",
        "Ajoutez les graines de chia et le miel.",
        "Mélangez bien tous les ingrédients.",
        "Placez au réfrigérateur toute la nuit.",
        "Le matin, ajoutez les fruits rouges et dégustez.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "2 - Cœurs de romaine",
        "50g - Parmesan râpé",
        "30g - Croûtons sans gluten",
        "3 cuillères - Sauce César",
        "1 - Citron",
      ],
      steps: [
        "Lavez et essorez la salade romaine.",
        "Coupez les feuilles en morceaux.",
        "Ajoutez les croûtons et le parmesan.",
        "Arrosez de sauce César et de jus de citron.",
        "Mélangez bien et servez immédiatement.",
      ],
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
      difficulty: "Moyen",
      ingredients: [
        "150g - Filet de saumon",
        "100g - Épinards frais",
        "1 cuillère - Huile d'olive",
        "1 gousse - Ail",
        "1/2 - Citron",
        "Sel et poivre - Au goût",
      ],
      steps: [
        "Chauffez une poêle avec l'huile d'olive.",
        "Assaisonnez le saumon avec sel et poivre.",
        "Faites griller le saumon 4 min de chaque côté.",
        "Dans la même poêle, faites revenir l'ail et les épinards.",
        "Servez le saumon sur les épinards avec du citron.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "1 - Banane mûre",
        "30g - Protéine en poudre vanille",
        "200ml - Lait d'amande",
        "1 cuillère - Beurre d'amande",
        "1 pincée - Cannelle",
      ],
      steps: [
        "Pelez et coupez la banane en morceaux.",
        "Mettez tous les ingrédients dans un blender.",
        "Mixez pendant 30 secondes jusqu'à consistance lisse.",
        "Ajustez la texture avec plus de lait si nécessaire.",
        "Versez dans un verre et dégustez immédiatement.",
      ],
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
      difficulty: "Moyen",
      ingredients: [
        "150g - Quinoa",
        "1 - Courgette",
        "1 - Poivron rouge",
        "100g - Tomates cerises",
        "2 cuillères - Huile d'olive",
        "1 cuillère - Vinaigre balsamique",
      ],
      steps: [
        "Rincez et faites cuire le quinoa selon les instructions.",
        "Coupez les légumes en dés.",
        "Faites revenir les légumes à l'huile d'olive.",
        "Mélangez le quinoa cuit avec les légumes.",
        "Assaisonnez avec le vinaigre balsamique.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "3 - Œufs",
        "100g - Champignons de Paris",
        "1 cuillère - Beurre",
        "30g - Gruyère râpé",
        "1 cuillère - Crème fraîche",
        "Sel et poivre - Au goût",
      ],
      steps: [
        "Battez les œufs avec la crème, sel et poivre.",
        "Émincez et faites revenir les champignons au beurre.",
        "Versez les œufs battus dans la poêle.",
        "Ajoutez les champignons et le fromage sur une moitié.",
        "Pliez l'omelette en deux et servez immédiatement.",
      ],
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
      difficulty: "Moyen",
      ingredients: [
        "200g - Penne",
        "50g - Basilic frais",
        "30g - Pignons de pin",
        "50g - Parmesan",
        "2 gousses - Ail",
        "80ml - Huile d'olive",
      ],
      steps: [
        "Faites cuire les pâtes selon les instructions.",
        "Mixez basilic, pignons, ail et parmesan.",
        "Ajoutez l'huile d'olive progressivement en mixant.",
        "Égouttez les pâtes en gardant un peu d'eau de cuisson.",
        "Mélangez les pâtes avec le pesto et l'eau de cuisson.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "1 - Tortilla de blé",
        "50g - Houmous",
        "1/2 - Avocat",
        "50g - Concombre",
        "50g - Tomate",
        "30g - Pousses d'épinards",
      ],
      steps: [
        "Étalez le houmous sur toute la tortilla.",
        "Émincez l'avocat, le concombre et la tomate.",
        "Disposez tous les légumes sur la moitié de la tortilla.",
        "Ajoutez les pousses d'épinards.",
        "Roulez fermement le wrap et coupez en deux.",
      ],
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
      difficulty: "Moyen",
      ingredients: [
        "200g - Lentilles rouges",
        "400ml - Lait de coco",
        "1 - Oignon",
        "2 gousses - Ail",
        "1 cuillère - Curry en poudre",
        "1 - Tomate",
      ],
      steps: [
        "Émincez l'oignon et l'ail, faites-les revenir.",
        "Ajoutez le curry et faites griller 1 minute.",
        "Incorporez les lentilles et la tomate coupée.",
        "Versez le lait de coco et laissez mijoter 25 min.",
        "Assaisonnez et servez avec du riz basmati.",
      ],
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
      difficulty: "Moyen",
      ingredients: [
        "200g - Steak de bœuf",
        "1 cuillère - Beurre",
        "1 gousse - Ail",
        "1 branche - Thym",
        "100g - Brocolis",
        "Sel et poivre - Au goût",
      ],
      steps: [
        "Sortez le steak 30 min avant cuisson.",
        "Assaisonnez généreusement avec sel et poivre.",
        "Chauffez une poêle à feu vif.",
        "Saisissez le steak 3-4 min de chaque côté.",
        "Ajoutez beurre, ail et thym, arrosez le steak.",
        "Servez avec les brocolis vapeur.",
      ],
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
      difficulty: "Facile",
      ingredients: [
        "150g - Tomates cerises",
        "1 - Concombre",
        "100g - Feta",
        "50g - Olives noires",
        "1/2 - Oignon rouge",
        "3 cuillères - Huile d'olive",
      ],
      steps: [
        "Coupez les tomates cerises en deux.",
        "Émincez le concombre et l'oignon rouge.",
        "Émiettez la feta en gros morceaux.",
        "Mélangez tous les ingrédients dans un saladier.",
        "Arrosez d'huile d'olive et mélangez délicatement.",
      ],
    ),
  ];
} 
