import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'recipe_cards.dart';
import 'recipe_models.dart';

/// Chercher une recette, et resserrer par étiquettes.
///
/// Le champ mène et se vide d'un geste ; le bouton à droite ouvre les filtres.
/// La lecture des `content_tags` et la façon de rendre les filtres choisis à
/// l'appelant sont inchangées : seule leur présentation a bougé.
class RecipeSearchSection extends StatelessWidget {
  const RecipeSearchSection({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFiltersApplied,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Function(Map<String, Set<String>>)? onFiltersApplied;

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.pill),
              border: Border.all(color: RyzeColors.line),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: RyzeText.body(context, 3.9),
              cursorColor: RyzeColors.ink,
              decoration: InputDecoration(
                hintText: 'search_recipe_placeholder'.tr(lang),
                hintStyle: RyzeText.body(context, 3.9, color: RyzeColors.mute2),
                prefixIcon: Icon(LucideIcons.search, size: context.vw(4.6), color: RyzeColors.mute),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : Pressable(
                        onTap: () {
                          RyzeFeedback.tap();
                          searchController.clear();
                          onSearchChanged('');
                        },
                        child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.mute),
                      ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
              ),
            ),
          ),
        ),
        SizedBox(width: context.vw(2.6)),
        Pressable(
          onTap: () {
            RyzeFeedback.select();
            _openFilters(context);
          },
          child: Container(
            width: context.vw(12.3),
            height: context.vw(12.3),
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              shape: BoxShape.circle,
              border: Border.all(color: RyzeColors.line),
            ),
            child: Icon(LucideIcons.slidersHorizontal, size: context.vw(4.6), color: RyzeColors.ink),
          ),
        ),
      ],
    );
  }

  /// Les étiquettes disponibles viennent des `content_tags` ; ce qui est coché
  /// repart à l'appelant rangé par catégorie, exactement comme avant.
  void _openFilters(BuildContext context) {
    final availableFilters = RecipeFilters.advancedFilters;
    final selected = <String, bool>{};
    for (final category in availableFilters.entries) {
      for (final tag in category.value.values.first) {
        selected[tag] = false;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: RyzeColors.ink.withValues(alpha: 0.34),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setModalState) {
          final lang = LocalizationService.instance.currentLanguageCode;
          final count = selected.values.where((v) => v).length;
          final gutter = sheet.vw(5.1);

          return Container(
            height: sheet.vh(78),
            decoration: BoxDecoration(
              color: RyzeColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
            ),
            child: Column(
              children: [
                SizedBox(height: sheet.vw(2.6)),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                ),
                SizedBox(height: sheet.vw(4.1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('filters'.tr(lang), style: RyzeText.body(sheet, 5.1, weight: FontWeight.w600)),
                      ),
                      if (count > 0)
                        Pressable(
                          onTap: () {
                            RyzeFeedback.removed();
                            setModalState(() => selected.updateAll((_, __) => false));
                          },
                          child: Text(
                            'clear_filters'.tr(lang),
                            style: RyzeText.body(sheet, 3.4, weight: FontWeight.w600, color: RyzeColors.mute),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: sheet.vw(4.1)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    children: [
                      for (final category in availableFilters.entries) ...[
                        Text(
                          category.key,
                          style: RyzeText.body(sheet, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
                        ),
                        SizedBox(height: sheet.vw(2.3)),
                        Wrap(
                          spacing: sheet.vw(2.1),
                          runSpacing: sheet.vw(2.1),
                          children: [
                            for (final tag in category.value.values.first)
                              Pressable(
                                onTap: () {
                                  RyzeFeedback.tap();
                                  setModalState(() => selected[tag] = !(selected[tag] ?? false));
                                },
                                child: AnimatedContainer(
                                  duration: RyzeDurations.tap,
                                  curve: RyzeCurves.out,
                                  padding: EdgeInsets.symmetric(horizontal: sheet.vw(3.6), vertical: sheet.vw(2.3)),
                                  decoration: BoxDecoration(
                                    color: (selected[tag] ?? false) ? RyzeColors.ink : RyzeColors.surf,
                                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                                    border: Border.all(color: (selected[tag] ?? false) ? RyzeColors.ink : RyzeColors.line),
                                  ),
                                  child: Text(
                                    tag,
                                    style: RyzeText.body(
                                      sheet,
                                      3.3,
                                      weight: FontWeight.w600,
                                      color: (selected[tag] ?? false) ? RyzeColors.surf : RyzeColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: sheet.vw(5.6)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, sheet.vw(2.6), gutter, sheet.vw(4.6)),
                  child: Pressable(
                    onTap: () {
                      final byCategory = <String, Set<String>>{};
                      for (final category in availableFilters.entries) {
                        final chosen = category.value.values.first.where((tag) => selected[tag] == true).toSet();
                        if (chosen.isNotEmpty) byCategory[category.key] = chosen;
                      }
                      try {
                        onFiltersApplied?.call(byCategory);
                      } catch (e) {
                        debugPrint('❌ filtres: $e');
                      }
                      RyzeFeedback.confirm();
                      Navigator.pop(sheet);
                    },
                    child: Container(
                      height: sheet.vw(13.3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RyzeColors.ink,
                        borderRadius: BorderRadius.circular(RyzeRadius.sm),
                        boxShadow: RyzeShadow.soft,
                      ),
                      child: Text(
                        count == 0 ? 'apply_filters'.tr(lang) : '${'apply_filters'.tr(lang)} ($count)',
                        style: RyzeText.body(sheet, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Les filtres retenus, chacun avec sa croix.
class ActiveFiltersSection extends StatelessWidget {
  const ActiveFiltersSection({super.key, required this.activeFilters, required this.onRemoveFilter});

  final List<Map<String, String>> activeFilters;
  final Function(Map<String, String>) onRemoveFilter;

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: context.vw(2.6)),
      child: Wrap(
        spacing: context.vw(2.1),
        runSpacing: context.vw(2.1),
        children: [
          for (final filter in activeFilters)
            ActiveFilterChip(label: filter['label']!, onRemove: () => onRemoveFilter(filter)),
        ],
      ),
    );
  }
}

/// Ce que Ryze met en avant : une rangée de photos qu'on fait défiler.
class RecipeCarouselSection extends StatelessWidget {
  const RecipeCarouselSection({super.key, required this.featuredRecipes, this.onRecipeTap});

  final List<Recipe> featuredRecipes;
  final Function(Recipe)? onRecipeTap;

  @override
  Widget build(BuildContext context) {
    if (featuredRecipes.isEmpty) return const SizedBox.shrink();
    final lang = LocalizationService.instance.currentLanguageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recommended_recipes'.tr(lang),
          style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
        ),
        SizedBox(height: context.vw(2.6)),
        SizedBox(
          height: context.vw(41),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: featuredRecipes.length,
            separatorBuilder: (_, __) => SizedBox(width: context.vw(2.6)),
            itemBuilder: (_, i) => RecipeCarouselCard(
              recipe: featuredRecipes[i],
              onTap: onRecipeTap == null ? null : () => onRecipeTap!(featuredRecipes[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toutes les recettes, ou celles qui restent une fois filtré.
class RecipeListSection extends StatelessWidget {
  const RecipeListSection({
    super.key,
    required this.recipes,
    required this.hasActiveFilter,
    this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final bool hasActiveFilter;
  final Function(Recipe)? onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasActiveFilter ? 'results'.tr(lang) : 'all_recipes'.tr(lang),
              style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
            ),
            Text('${recipes.length}', style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
          ],
        ),
        SizedBox(height: context.vw(2.6)),
        if (recipes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(10)),
            child: Column(
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
          )
        else
          for (final recipe in recipes)
            Padding(
              padding: EdgeInsets.only(bottom: context.vw(2.1)),
              child: RecipeListCard(
                recipe: recipe,
                onTap: onRecipeTap == null ? null : () => onRecipeTap!(recipe),
                useSimpleMacros: true,
              ),
            ),
      ],
    );
  }
}
