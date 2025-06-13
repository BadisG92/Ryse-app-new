import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'recipe_models.dart';
import 'recipe_cards.dart';

// Section de recherche avec filtre
class RecipeSearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;

  const RecipeSearchSection({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              controller: searchController,
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
              onChanged: onSearchChanged,
            ),
          ),
        ),
        
        // Icône de filtre à l'extérieur
        const SizedBox(width: 12),
        IconButton(
          onPressed: onFilterPressed,
          icon: const Icon(
            LucideIcons.settings,
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
}

// Section des filtres actifs
class ActiveFiltersSection extends StatelessWidget {
  final List<Map<String, String>> activeFilters;
  final Function(Map<String, String>) onRemoveFilter;

  const ActiveFiltersSection({
    super.key,
    required this.activeFilters,
    required this.onRemoveFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: activeFilters.map((filterData) {
              return ActiveFilterChip(
                label: filterData['label']!,
                onRemove: () => onRemoveFilter(filterData),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Section carousel horizontal
class RecipeCarouselSection extends StatelessWidget {
  final List<Recipe> featuredRecipes;
  final Function(Recipe)? onRecipeTap;

  const RecipeCarouselSection({
    super.key,
    required this.featuredRecipes,
    this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recettes recommandées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Carousel horizontal
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: featuredRecipes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipe = featuredRecipes[index];
              return RecipeCarouselCard(
                recipe: recipe,
                onTap: onRecipeTap != null ? () => onRecipeTap!(recipe) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// Section liste des recettes
class RecipeListSection extends StatelessWidget {
  final List<Recipe> recipes;
  final bool hasActiveFilter;
  final Function(Recipe)? onRecipeTap;

  const RecipeListSection({
    super.key,
    required this.recipes,
    required this.hasActiveFilter,
    this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section avec compteur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasActiveFilter ? 'Résultats' : 'Toutes les recettes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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
                    '${recipes.length}',
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
        
        const SizedBox(height: 16),
        
        // Liste des recettes avec dividers
        ...recipes.asMap().entries.map((entry) {
          final int index = entry.key;
          final Recipe recipe = entry.value;
          
          return Column(
            children: [
              RecipeListCard(
                recipe: recipe,
                onTap: onRecipeTap != null ? () => onRecipeTap!(recipe) : null,
                useSimpleMacros: true, // Format simple pour la page des recettes
              ),
              if (index < recipes.length - 1)
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
}

// Widget de filtre modal (contenu seulement)
class FilterModalContent extends StatelessWidget {
  final Map<String, Set<String>> selectedFilters;
  final Function(String, String, bool) onFilterChanged;
  final VoidCallback onClearAll;
  final VoidCallback onApply;
  final int selectedCount;

  const FilterModalContent({
    super.key,
    required this.selectedFilters,
    required this.onFilterChanged,
    required this.onClearAll,
    required this.onApply,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onPressed: onClearAll,
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
              children: RecipeFilters.advancedFilters.entries.map((categoryEntry) {
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
                              final isSelected = selectedFilters[filterKey]?.contains(option) ?? false;
                              
                              return ChoiceChip(
                                label: Text(option),
                                selected: isSelected,
                                showCheckmark: false,
                                onSelected: (bool selected) => onFilterChanged(filterKey, option, selected),
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
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                selectedCount > 0 
                  ? 'Valider ($selectedCount)' 
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
    );
  }
} 
