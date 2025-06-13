import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'recipe_details_screen.dart';
import '../components/ui/recipe_models.dart';
import '../components/ui/recipe_widgets.dart';
import '../components/ui/recipe_cards.dart';

class SelectRecipeScreen extends StatefulWidget {
  final bool isFromDashboard;
  
  const SelectRecipeScreen({super.key, this.isFromDashboard = false});

  @override
  State<SelectRecipeScreen> createState() => _SelectRecipeScreenState();
}

class _SelectRecipeScreenState extends State<SelectRecipeScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filtres avancés
  Map<String, Set<String>> selectedAdvancedFilters = {
    'regime': <String>{},
    'duree': <String>{},
    'calories': <String>{},
    'difficulte': <String>{},
  };

  List<Recipe> get recipes => RecipeData.allRecipes;

  List<Recipe> get filteredRecipes {
    // Vérifier si un filtre avancé est active
    final bool hasAdvancedFilters = selectedAdvancedFilters.values.any((set) => set.isNotEmpty);
    
    // Filtrer les recettes selon la recherche et les filtres
    return RecipeFilters.filterRecipes(
      recipes,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      selectedFilters: hasAdvancedFilters ? selectedAdvancedFilters : null,
    );
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: const Icon(
              LucideIcons.chevronLeft,
              size: 20,
              color: Color(0xFF0B132B),
            ),
          ),
        ),
        title: const Text(
          'Choisir une recette',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Section recherche et filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche avec bouton filtre
                RecipeSearchSection(
                  searchController: _searchController,
                  searchQuery: searchQuery,
                  onSearchChanged: _onSearchChanged,
                  onFilterPressed: _showFiltersModal,
                ),
                
                // Filtres actifs
                ActiveFiltersSection(
                  activeFilters: RecipeFilters.getActiveFilterTags(selectedAdvancedFilters),
                  onRemoveFilter: _removeSpecificFilter,
                ),
              ],
            ),
          ),
          
          // Liste des recettes
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre avec compteur
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasActiveFilter ? 'Résultats' : 'Toutes les recettes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (hasActiveFilter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filteredRecipes.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Liste des recettes
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => _openRecipeDetails(recipe),
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
                  LucideIcons.chefHat,
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
                  
                  // Résumé (durée, portions, calories)
                  Text(
                    '${recipe.duration} • ${recipe.servings} pers. • ${recipe.calories} kcal',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Ligne macros
                  Text(
                    'P : ${recipe.proteins}g • G : ${recipe.carbs}g • L : ${recipe.fats}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
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

  void _openRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          isFromDashboard: widget.isFromDashboard,
        ),
      ),
    );
  }
}
