import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';

class NutritionRecipes extends StatefulWidget {
  const NutritionRecipes({super.key});

  @override
  State<NutritionRecipes> createState() => _NutritionRecipesState();
}

class _NutritionRecipesState extends State<NutritionRecipes> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  // Nouveaux filtres avancés
  Map<String, Set<String>> selectedAdvancedFilters = {
    'regime': <String>{},
    'duree': <String>{},
    'calories': <String>{},
    'difficulte': <String>{},
  };
  
  // Structure des filtres avancés
  final Map<String, Map<String, List<String>>> advancedFilters = {
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
  
  final List<Recipe> recipes = [
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

  // Recettes spécialement sélectionnées pour le carrousel
  final List<Recipe> featuredRecipes = [
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si un filtre ou une recherche est active
    final bool hasAdvancedFilters = selectedAdvancedFilters.values.any((set) => set.isNotEmpty);
    final bool hasActiveFilter = searchQuery.isNotEmpty || hasAdvancedFilters;
    
    // Filtrer les recettes selon la recherche et les filtres
    final filteredRecipes = _getFilteredRecipes();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Contenu principal avec carrousel conditionnel
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Carrousel horizontal (seulement si pas de filtre actif)
                  if (!hasActiveFilter) ...[
                    _buildCarouselSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Barre de recherche avec icône de filtre
                  _buildSearchSection(),
                  
                  // Filtres actifs (espacement réduit)
                  _buildActiveFiltersChips(),
                  
                  // Espacement conditionnel après les filtres
                  SizedBox(height: hasActiveFilter ? 16 : 24),
                  
                  // Liste verticale
                  _buildRecipesList(filteredRecipes, hasActiveFilter),
                  
                  // Padding bottom pour éviter la coupure
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        // Barre de recherche
        Expanded(
          child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: TextField(
              controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Rechercher une recette...',
          hintStyle: TextStyle(color: Color(0xFF888888)),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 20,
            color: Color(0xFF888888),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
                  ),
                ),
              ),
        
        // Icône de filtre à l'extérieur
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _showFiltersModal(),
          icon: const Icon(
            LucideIcons.filter,
            size: 20,
            color: Color(0xFF0B132B),
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFiltersChips() {
    List<Map<String, String>> activeFilters = _getActiveFilterTagsWithKeys();
    
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8), // Espacement réduit
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeFilters.map((filterData) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filterData['label']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSpecificFilter(filterData),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigation vers les détails de la recette
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            // Image carrée 64x64
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.image,
                  size: 24,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Contenu texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titre de la recette
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Résumé (calories, durée, portions)
                  Text(
                    '${recipe.calories} kcal • ${recipe.duration} • ${recipe.servings} pers.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Ligne macros
                  Text(
                    'P: ${recipe.proteins}g G: ${recipe.carbs}g L: ${recipe.fats}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bouton coeur
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Gérer les favoris
                },
                icon: const Icon(
                  LucideIcons.heart,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Recipe> _getFilteredRecipes() {
    List<Recipe> filtered = recipes;
    
    // Filtrage par recherche
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) =>
        recipe.name.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filtrage par filtres avancés
    selectedAdvancedFilters.forEach((filterKey, selectedValues) {
      if (selectedValues.isNotEmpty) {
        filtered = filtered.where((recipe) {
          return _matchesAdvancedFilter(recipe, filterKey, selectedValues);
        }).toList();
      }
    });
    
    return filtered;
  }

  bool _matchesAdvancedFilter(Recipe recipe, String filterKey, Set<String> selectedValues) {
    switch (filterKey) {
      case 'regime':
        // Vérifier si la recette correspond aux régimes sélectionnés
        return selectedValues.any((regime) => recipe.tags.contains(regime));
      
      case 'duree':
        // Logique pour la durée de préparation
        for (String dureeFilter in selectedValues) {
          if (_matchesDurationFilter(recipe.duration, dureeFilter)) {
            return true;
          }
        }
        return false;
      
      case 'calories':
        // Logique pour les calories
        for (String calorieFilter in selectedValues) {
          if (_matchesCalorieFilter(recipe.calories, calorieFilter)) {
            return true;
          }
        }
        return false;
      
      case 'difficulte':
        // Pour l'instant, on considère que toutes les recettes sont "Facile"
        return selectedValues.contains('Facile');
      
      default:
        return true;
    }
  }

  bool _matchesDurationFilter(String duration, String filter) {
    final int minutes = _extractMinutesFromDuration(duration);
    
    switch (filter) {
      case 'Moins de 15 min':
        return minutes < 15;
      case '15-30 min':
        return minutes >= 15 && minutes <= 30;
      case '30-45 min':
        return minutes > 30 && minutes <= 45;
      case 'Plus de 45 min':
        return minutes > 45;
      default:
        return false;
    }
  }

  bool _matchesCalorieFilter(int calories, String filter) {
    switch (filter) {
      case 'Moins de 300 kcal':
        return calories < 300;
      case '300-500 kcal':
        return calories >= 300 && calories <= 500;
      case '500-700 kcal':
        return calories > 500 && calories <= 700;
      case 'Plus de 700 kcal':
        return calories > 700;
      default:
        return false;
    }
  }

  int _extractMinutesFromDuration(String duration) {
    // Extraire les minutes d'une chaîne comme "15 min" ou "1h 30min"
    final RegExp minutesRegex = RegExp(r'(\d+)\s*min');
    final match = minutesRegex.firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Widget _buildCarouselSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la section
        const Text(
          'Recettes adaptées à vos objectifs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Carrousel horizontal
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = featuredRecipes[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < featuredRecipes.length - 1 ? 12 : 0,
                ),
                child: _buildCarouselCard(recipe),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipesList(List<Recipe> filteredRecipes, bool hasActiveFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre conditionnel
        if (!hasActiveFilter) ...[
          const Text(
            'Toutes les recettes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Liste des recettes avec dividers
        ...filteredRecipes.asMap().entries.map((entry) {
          final int index = entry.key;
          final Recipe recipe = entry.value;
          
          return Column(
            children: [
              _buildRecipeCard(recipe),
              if (index < filteredRecipes.length - 1)
                const Divider(
                  color: Color(0xFFE2E8F0),
                  height: 1,
                  thickness: 1,
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCarouselCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigation vers les détails de la recette
      },
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF8F8F8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
                ),
                child: Stack(
                  children: [
            // Image de fond (placeholder)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF0F0F0),
              ),
              child: const Center(
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
            ),
            
            // Badge calories en haut à droite
                    Positioned(
              top: 12,
              right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                        ),
                        child: Text(
                          '${recipe.calories} kcal',
                          style: const TextStyle(
                            fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ),
            ),
            
            // Titre en overlay en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                            Text(
                      '${recipe.duration} • ${recipe.servings} pers.',
                              style: const TextStyle(
                                fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle du modal
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
        decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF8F8F8),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          selectedAdvancedFilters.forEach((key, value) {
                            value.clear();
                          });
                        });
                      },
                      child: const Text(
                        'Effacer tout',
              style: TextStyle(
                fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Liste des filtres
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: advancedFilters.entries.map((categoryEntry) {
                      final categoryTitle = categoryEntry.key;
                      final categoryFilters = categoryEntry.value;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...categoryFilters.entries.map((filterEntry) {
                            final filterKey = filterEntry.key;
                            final filterOptions = filterEntry.value;
                            
                            return Column(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: filterOptions.map((option) {
                                    final isSelected = selectedAdvancedFilters[filterKey]?.contains(option) ?? false;
                                    
                                    return ChoiceChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setModalState(() {
                                          if (selected) {
                                            selectedAdvancedFilters[filterKey]?.add(option);
                                          } else {
                                            selectedAdvancedFilters[filterKey]?.remove(option);
                                          }
                                        });
                                      },
                                      backgroundColor: const Color(0xFFF8F8F8),
                                      selectedColor: const Color(0xFF0B132B),
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // Bouton Valider
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFF8F8F8),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Les filtres sont déjà mis à jour dans setModalState
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _getSelectedFiltersCount() > 0 
                        ? 'Valider (${_getSelectedFiltersCount()})' 
                        : 'Valider',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getSelectedFiltersCount() {
    return selectedAdvancedFilters.values
        .map((set) => set.length)
        .fold(0, (sum, count) => sum + count);
  }

  List<Map<String, String>> _getActiveFilterTagsWithKeys() {
    List<Map<String, String>> filters = [];
    
    // Filtres avancés
    selectedAdvancedFilters.forEach((filterKey, selectedValues) {
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

  void _removeSpecificFilter(Map<String, String> filterData) {
    setState(() {
      if (filterData['type'] == 'advanced') {
        selectedAdvancedFilters[filterData['key']]?.remove(filterData['label']);
      }
    });
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

  Recipe({
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
} 