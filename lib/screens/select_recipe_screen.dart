import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'recipe_details_screen.dart';
import 'test_filter_screen.dart';
import '../components/ui/recipe_models.dart';
import '../components/ui/recipe_widgets.dart';
import '../components/ui/recipe_cards.dart';
import '../components/ui/working_filter_modal.dart';
import '../models/nutrition_models.dart';
import '../services/recipe_image_service.dart';

class SelectRecipeScreen extends StatefulWidget {
  final bool isFromDashboard;
  final Function(FoodItem)? onRecipeSelected; // Callback pour ajouter la recette au journal
  final String? mealName;
  final String? mealId;

  const SelectRecipeScreen({
    super.key,
    this.isFromDashboard = false,
    this.onRecipeSelected,
    this.mealName,
    this.mealId,
  });

  @override
  State<SelectRecipeScreen> createState() => _SelectRecipeScreenState();
}

class _SelectRecipeScreenState extends State<SelectRecipeScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filtres avancés - synchronisés avec content_tags
  Map<String, Set<String>> selectedAdvancedFilters = {};

  List<Recipe> get recipes => RecipeData.allRecipes;

  List<Recipe> get filteredRecipes {
    final bool hasAdvancedFilters = selectedAdvancedFilters.values.any((set) => set.isNotEmpty);
    
    if (hasAdvancedFilters) {
      debugPrint('🎯 FILTRAGE ACTIF dans l\'UI');
      debugPrint('🎯 Filtres sélectionnés: $selectedAdvancedFilters');
    }
    
    final result = RecipeFilters.filterRecipes(
      recipes,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      selectedFilters: hasAdvancedFilters ? selectedAdvancedFilters : null,
    );
    
    if (hasAdvancedFilters) {
      debugPrint('🎯 UI: ${result.length} recettes après filtrage');
    }
    
    return result;
  }

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _initializeRecipes();
  }

  // Initialise les recettes et écoute les changements
  void _initializeRecipes() async {
    // Forcer l'initialisation
    RecipeData.initialize();

    // Attendre le chargement initial
    await Future.delayed(const Duration(milliseconds: 100));

    // Vérifier périodiquement si le chargement est terminé
    int attempts = 0;
    while (RecipeData.isLoading && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Forcer un setState pour rafraîchir l'UI
    if (mounted) {
      setState(() {
        debugPrint('✅ Recettes chargées: ${RecipeData.allRecipes.length}');
      });
    }
  }

  // Initialise les filtres depuis RecipeFilters.advancedFilters
  void _initializeFilters() async {
    debugPrint('🔍 INIT: Initialisation des filtres depuis RecipeFilters');

    // Forcer l'initialisation de RecipeFilters
    RecipeFilters.initialize();

    // Attendre un peu que les filtres se chargent
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      // Créer un Set vide pour chaque catégorie disponible
      for (final category in RecipeFilters.advancedFilters.keys) {
        selectedAdvancedFilters[category] = <String>{};
      }
      debugPrint('🔍 INIT: Categories disponibles = ${selectedAdvancedFilters.keys.toList()}');
      debugPrint('🔍 INIT: RecipeFilters.advancedFilters = ${RecipeFilters.advancedFilters}');
    });
  }

  // Plus besoin de _loadDynamicFilters, supprimé

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
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Choisir une recette' : 'Choose a recipe',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
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
                  onFiltersApplied: (Map<String, Set<String>> filters) {
                    debugPrint('🔥🔥🔥 onFiltersApplied APPELÉ avec: $filters');
                    setState(() {
                      selectedAdvancedFilters = filters;
                    });
                    debugPrint('🔥🔥🔥 selectedAdvancedFilters mis à jour: $selectedAdvancedFilters');
                  },
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
                        Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            hasActiveFilter ? 
                              (locService.currentLanguageCode == 'fr' ? 'Résultats' : 'Results') : 
                              (locService.currentLanguageCode == 'fr' ? 'Toutes les recettes' : 'All recipes'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
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
                    child: RecipeData.isLoading
                        ? _buildLoadingPlaceholder()
                        : filteredRecipes.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RecipeImageService.buildRecipeImage(
                imageUrl: recipe.image,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
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
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' 
                        ? '${recipe.duration} min • ${recipe.servings} pers. • ${recipe.calories} kcal'
                        : '${recipe.duration} min • ${recipe.servings} servings • ${recipe.calories} kcal',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Ligne macros
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' 
                        ? 'P : ${recipe.proteins}g • G : ${recipe.carbs}g • L : ${recipe.fats}g'
                        : 'P: ${recipe.proteins}g • C: ${recipe.carbs}g • F: ${recipe.fats}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
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


  void _removeSpecificFilter(Map<String, String> filterData) {
    setState(() {
      if (filterData['type'] == 'advanced') {
        selectedAdvancedFilters[filterData['key']]?.remove(filterData['label']);
      }
    });
  }

  Widget _buildLoadingPlaceholder() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              // Placeholder image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              // Placeholder texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Consumer<LocalizationService>(
          builder: (context, locService, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.chefHat,
                size: 64,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              Text(
                locService.currentLanguageCode == 'fr'
                    ? 'Aucune recette trouvée'
                    : 'No recipes found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locService.currentLanguageCode == 'fr'
                    ? 'Essayez de modifier vos filtres'
                    : 'Try adjusting your filters',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          isFromDashboard: widget.isFromDashboard,
          onRecipeSelected: widget.onRecipeSelected, // Passer le callback
        ),
      ),
    );
  }
}
