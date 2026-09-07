import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Dans quel repas ranger ce qu'on vient d'ajouter.
///
/// Le parcours refait ne pose plus cette question — on part toujours d'un
/// repas — mais elle reste pour les chemins qui n'en ont pas : le widget iOS,
/// une recette ouverte depuis l'onglet Recettes, un aliment détecté sans
/// contexte. Deux rangées : rejoindre un repas ouvert, ou en commencer un.
class MealSelectionBottomSheet {
  MealSelectionBottomSheet._();

  static void show(
    BuildContext context, {
    String? titleKey,
    String? subtitleKey,
    String? foodName,
    required List<Meal> existingMeals,
    required Function(Meal meal) onExistingMealSelected,
    required VoidCallback onCreateNewMeal,
  }) {
    final lang = LocalizationService.instance.currentLanguageCode;
    final title = titleKey != null
        ? titleKey.tr(lang)
        : (foodName != null
            ? 'add_food_title'.tr(lang).replaceAll('{foodName}', foodName)
            : 'add_meal'.tr(lang));

    showRyzeSheet<void>(
      context,
      title: title,
      subtitle: subtitleKey != null ? subtitleKey.tr(lang) : 'where_add_food'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          if (existingMeals.isNotEmpty)
            RyzeSheetRow(
              first: true,
              icon: LucideIcons.utensils,
              label: 'add_to_existing_meal'.tr(lang),
              hint: _mealNames(existingMeals),
              onTap: () {
                Navigator.pop(sheet);
                _showExistingMeals(context, existingMeals: existingMeals, onMealSelected: onExistingMealSelected);
              },
            ),
          RyzeSheetRow(
            first: existingMeals.isEmpty,
            icon: LucideIcons.plus,
            label: 'create_new_meal'.tr(lang),
            hint: 'choose_meal_type_to_create'.tr(lang),
            onTap: () {
              Navigator.pop(sheet);
              onCreateNewMeal();
            },
          ),
        ],
      ),
    );
  }

  /// Les repas déjà ouverts aujourd'hui, chacun avec ce qu'il contient.
  static void _showExistingMeals(
    BuildContext context, {
    required List<Meal> existingMeals,
    required Function(Meal meal) onMealSelected,
  }) {
    final lang = LocalizationService.instance.currentLanguageCode;
    showRyzeSheet<void>(
      context,
      title: 'add_to_existing_meal'.tr(lang),
      subtitle: 'where_add_food'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          for (final meal in existingMeals)
            RyzeSheetRow(
              first: meal == existingMeals.first,
              icon: _mealIcon(meal.name),
              label: meal.name,
              hint: _itemCount(meal, lang),
              onTap: () {
                Navigator.pop(sheet);
                onMealSelected(meal);
              },
            ),
        ],
      ),
    );
  }

  static String _mealNames(List<Meal> meals) => meals.map((m) => m.name).join(' · ');

  static String _itemCount(Meal meal, String lang) {
    final count = meal.items.length;
    return 'food_item_count'
        .tr(lang)
        .replaceAll('{count}', '$count')
        .replaceAll('{plural}', count > 1 ? 's' : '');
  }

  /// L'icône d'un repas d'après son nom, numéro de suite compris :
  /// « Déjeuner 2 » reste un déjeuner.
  static IconData _mealIcon(String mealName) {
    final name = mealName.toLowerCase().replaceAll(RegExp(r'\s*\d+\s*$'), '').trim();
    if (name.contains('petit') && name.contains('déjeuner')) return LucideIcons.sunrise;
    if (name == 'breakfast' || name == 'frühstück') return LucideIcons.sunrise;
    if (name == 'déjeuner' || name == 'lunch' || name == 'mittagessen') return LucideIcons.sun;
    if (name == 'dîner' || name == 'diner' || name == 'dinner' || name == 'abendessen') return LucideIcons.sunset;
    if (name == 'collation' || name == 'snack' || name == 'zwischenmahlzeit') return LucideIcons.milk;
    return LucideIcons.utensils;
  }
}
