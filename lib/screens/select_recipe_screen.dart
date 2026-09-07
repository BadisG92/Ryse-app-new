import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'recipe_details_screen.dart';
import '../components/ui/recipe_models.dart';
import '../components/ui/recipe_widgets.dart';
import '../design/design.dart';
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
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final filtered = selectedAdvancedFilters.values.any((set) => set.isNotEmpty);
    final narrowed = searchQuery.isNotEmpty || filtered;
    final recipes = filteredRecipes;
    final gutter = context.vw(5.1);

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, context.vw(2.6), gutter, context.vw(3.6)),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: context.vw(9.7),
                      height: context.vw(9.7),
                      decoration: BoxDecoration(
                        color: RyzeColors.surf,
                        shape: BoxShape.circle,
                        border: Border.all(color: RyzeColors.line),
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
                    ),
                  ),
                  SizedBox(width: context.vw(3.6)),
                  Expanded(
                    child: Text(
                      'add_recipe_meal_title'.tr(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 4.6, weight: FontWeight.w600),
                    ),
                  ),
                  if (narrowed)
                    Text(
                      '${recipes.length}',
                      style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.mute),
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Column(
                children: [
                  RecipeSearchSection(
                    searchController: _searchController,
                    searchQuery: searchQuery,
                    onSearchChanged: _onSearchChanged,
                    onFiltersApplied: (filters) => setState(() => selectedAdvancedFilters = filters),
                  ),
                  ActiveFiltersSection(
                    activeFilters: RecipeFilters.getActiveFilterTags(selectedAdvancedFilters),
                    onRemoveFilter: _removeSpecificFilter,
                  ),
                ],
              ),
            ),
            SizedBox(height: context.vw(2.6)),

            Expanded(
              child: RecipeData.isLoading
                  ? _buildLoadingPlaceholder()
                  : recipes.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(8)),
                          itemCount: recipes.length,
                          separatorBuilder: (_, __) => SizedBox(height: context.vw(2.1)),
                          itemBuilder: (_, i) => _buildRecipeCard(recipes[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecipeCard(Recipe recipe) {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        _openRecipeDetails(recipe);
      },
      child: Container(
        padding: EdgeInsets.all(context.vw(2.6)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              child: RecipeImageService.buildRecipeImage(
                imageUrl: recipe.image,
                width: context.vw(18.5),
                height: context.vw(18.5),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: context.vw(3.6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                  ),
                  SizedBox(height: context.vw(1)),
                  Text(
                    '${recipe.duration} ${'recipe_minutes'.tr(lang)} · ${recipe.safeServings} ${'recipe_servings'.tr(lang)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                  ),
                  SizedBox(height: context.vw(0.8)),
                  Text(
                    'P ${recipe.safeProteins} · G ${recipe.safeCarbs} · L ${recipe.safeFats}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.0, color: RyzeColors.mute2),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.vw(2.6)),
            Padding(
              padding: EdgeInsets.only(right: context.vw(1.5)),
              child: Text.rich(
                TextSpan(
                  style: RyzeText.body(context, 3.9, weight: FontWeight.w600).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: '${recipe.safeCalories}'),
                    TextSpan(text: ' kcal', style: RyzeText.body(context, 3.0, color: RyzeColors.mute)),
                  ],
                ),
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
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(context.vw(5.1), 0, context.vw(5.1), context.vw(8)),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: context.vw(2.1)),
      itemBuilder: (_, __) => Container(
        height: context.vw(23.6),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.vw(2.6)),
          child: Row(
            children: [
              Container(
                width: context.vw(18.5),
                height: context.vw(18.5),
                decoration: BoxDecoration(
                  color: RyzeColors.paper2,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                ),
              ),
              SizedBox(width: context.vw(3.6)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: context.vw(3.6), decoration: BoxDecoration(color: RyzeColors.paper2, borderRadius: BorderRadius.circular(4))),
                    SizedBox(height: context.vw(2.1)),
                    Container(width: context.vw(38), height: context.vw(3.1), decoration: BoxDecoration(color: RyzeColors.paper2, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.chefHat, size: context.vw(12.3), color: RyzeColors.mute2),
            SizedBox(height: context.vw(3.6)),
            Text(
              'recipe_none_found'.tr(lang),
              style: RyzeText.body(context, 4.1, weight: FontWeight.w600, color: RyzeColors.mute),
            ),
            SizedBox(height: context.vw(1.5)),
            Text(
              'recipe_adjust_filters'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.4, color: RyzeColors.mute2),
            ),
          ],
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
