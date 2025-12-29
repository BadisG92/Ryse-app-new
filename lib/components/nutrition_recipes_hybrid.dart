import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/recipe_models.dart';
import 'ui/recipe_cards.dart';
import 'ui/recipe_widgets.dart';
import '../screens/recipe_details_screen.dart';

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
  void initState() {
    super.initState();
    // Initialiser les données des recettes ET attendre le chargement
    _loadRecipes();

    // Tutorial Recettes désactivé - déjà expliqué dans le tutorial principal
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showRecipesTutorial();
    // });
  }

  /// Affiche le tutorial des Recettes lors de la première visite
  Future<void> _showRecipesTutorial() async {
    // Accéder au parent NutritionSection pour afficher le tutorial
    final nutritionSection = context.findAncestorStateOfType<State<StatefulWidget>>();
    if (nutritionSection != null && nutritionSection is State) {
      try {
        final method = nutritionSection.runtimeType.toString();
        if (method.contains('NutritionSection')) {
          final parent = nutritionSection as dynamic;
          await parent.showTabTutorial('recipes');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur lors de l\'affichage du tutorial Recettes: $e');
      }
    }
  }

  Future<void> _loadRecipes() async {
    // Initialiser (lance le chargement en arrière-plan)
    RecipeData.initialize();

    // Attendre 100ms pour laisser le temps au cache de se charger
    await Future.delayed(const Duration(milliseconds: 100));

    // Vérifier toutes les 50ms si les données sont arrivées
    int attempts = 0;
    while (RecipeData.allRecipes.isEmpty && attempts < 100 && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    // Forcer un rebuild quand les recettes sont chargées
    if (mounted && RecipeData.allRecipes.isNotEmpty) {
      setState(() {});
      debugPrint('✅ Recettes affichées: ${RecipeData.allRecipes.length} recettes');
    }
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

    // Filtrer les recettes selon la recherche et les filtres
    final filteredRecipes = RecipeFilters.filterRecipes(
      RecipeData.allRecipes,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      selectedFilters: hasAdvancedFilters ? selectedAdvancedFilters : null,
    );

    // Détecter si le clavier est visible pour ajouter un padding supplémentaire
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Contenu principal avec carrousel conditionnel
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                    onFiltersApplied: (Map<String, Set<String>> filters) {
                      setState(() {
                        selectedAdvancedFilters = filters;
                      });
                    },
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

                  // Padding bottom pour éviter la coupure (+ hauteur clavier si visible)
                  SizedBox(height: isKeyboardVisible ? keyboardHeight + 20 : 100),
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
    debugPrint('🔥 Clic sur recette: ${recipe.name}');
    // Navigation vers les détails de la recette depuis l'onglet recettes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          isFromDashboard: false, // L'onglet recettes affiche "Ajouter à un repas"
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
