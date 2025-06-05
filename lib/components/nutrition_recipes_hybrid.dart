import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/recipe_models.dart';
import 'ui/recipe_cards.dart';
import 'ui/recipe_widgets.dart';

class NutritionRecipesHybrid extends StatefulWidget {
  const NutritionRecipesHybrid({super.key});

  @override
  State<NutritionRecipesHybrid> createState() => _NutritionRecipesHybridState();
}

class _NutritionRecipesHybridState extends State<NutritionRecipesHybrid> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  // Filtres avancés
  Map<String, Set<String>> selectedAdvancedFilters = {
    'regime': <String>{},
    'duree': <String>{},
    'calories': <String>{},
    'difficulte': <String>{},
  };

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
    final filteredRecipes = RecipeFilters.filterRecipes(
      RecipeData.allRecipes,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      selectedFilters: hasAdvancedFilters ? selectedAdvancedFilters : null,
    );
    
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
                    RecipeCarouselSection(
                      featuredRecipes: RecipeData.featuredRecipes,
                      onRecipeTap: _onRecipeTap,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Barre de recherche avec icône de filtre
                  RecipeSearchSection(
                    searchController: _searchController,
                    searchQuery: searchQuery,
                    onSearchChanged: _onSearchChanged,
                    onFilterPressed: _showFiltersModal,
                  ),
                  
                  // Filtres actifs (espacement réduit)
                  ActiveFiltersSection(
                    activeFilters: RecipeFilters.getActiveFilterTags(selectedAdvancedFilters),
                    onRemoveFilter: _removeSpecificFilter,
                  ),
                  
                  // Espacement conditionnel après les filtres
                  SizedBox(height: hasActiveFilter ? 16 : 24),
                  
                  // Liste verticale
                  RecipeListSection(
                    recipes: filteredRecipes,
                    hasActiveFilter: hasActiveFilter,
                    onRecipeTap: _onRecipeTap,
                  ),
                  
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

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  void _onRecipeTap(Recipe recipe) {
    // TODO: Navigation vers les détails de la recette
    print('Recipe tapped: ${recipe.name}');
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
          child: FilterModalContent(
            selectedFilters: selectedAdvancedFilters,
            onFilterChanged: (filterKey, option, selected) {
              setModalState(() {
                if (selected) {
                  selectedAdvancedFilters[filterKey]?.add(option);
                } else {
                  selectedAdvancedFilters[filterKey]?.remove(option);
                }
              });
            },
            onClearAll: () {
              setModalState(() {
                selectedAdvancedFilters.forEach((key, value) {
                  value.clear();
                });
              });
            },
            onApply: () {
              setState(() {
                // Les filtres sont déjà mis à jour dans setModalState
              });
              Navigator.pop(context);
            },
            selectedCount: RecipeFilters.countSelectedFilters(selectedAdvancedFilters),
          ),
        ),
      ),
    );
  }

  void _removeSpecificFilter(Map<String, String> filterData) {
    setState(() {
      if (filterData['type'] == 'advanced') {
        selectedAdvancedFilters[filterData['key']]?.remove(filterData['label']);
      }
    });
  }
} 