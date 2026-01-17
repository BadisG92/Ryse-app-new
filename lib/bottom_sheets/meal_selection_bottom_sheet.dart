import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/nutrition_models.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class MealSelectionBottomSheet {
  static void show(
    BuildContext context, {
    String? titleKey,
    String? subtitleKey,
    String? foodName, // Legacy support - sera remplacé graduellement par titleKey/subtitleKey
    required List<Meal> existingMeals,
    required Function(Meal meal) onExistingMealSelected,
    required VoidCallback onCreateNewMeal,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  String title;
                  if (titleKey != null) {
                    title = titleKey.tr(localizationService.currentLanguageCode);
                  } else if (foodName != null) {
                    title = 'add_food_title'.tr(localizationService.currentLanguageCode).replaceAll('{foodName}', foodName);
                  } else {
                    title = 'add_meal'.tr(localizationService.currentLanguageCode);
                  }

                  return Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),

              const SizedBox(height: 8),

              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  String subtitle;
                  if (subtitleKey != null) {
                    subtitle = subtitleKey.tr(localizationService.currentLanguageCode);
                  } else {
                    subtitle = 'where_add_food'.tr(localizationService.currentLanguageCode);
                  }

                  return Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Option 1: Repas existant
              if (existingMeals.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showExistingMealsBottomSheet(
                      context,
                      foodName: foodName,
                      existingMeals: existingMeals,
                      onMealSelected: onExistingMealSelected,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<LocalizationService>(
                            builder: (context, localizationService, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'add_to_existing_meal'.tr(localizationService.currentLanguageCode),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'choose_from_daily_meals'.tr(localizationService.currentLanguageCode),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
              ],
              
              // Option 2: Nouveau repas
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onCreateNewMeal();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0B132B).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<LocalizationService>(
                          builder: (context, localizationService, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'create_new_meal'.tr(localizationService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'meal_type_options'.tr(localizationService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static void _showExistingMealsBottomSheet(
    BuildContext context, {
    String? foodName,
    required List<Meal> existingMeals,
    required Function(Meal meal) onMealSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Header avec retour
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // Re-ouvrir le premier bottom sheet
                        show(
                          context,
                          foodName: foodName,
                          existingMeals: existingMeals,
                          onExistingMealSelected: onMealSelected,
                          onCreateNewMeal: () {}, // Pas utilisé dans ce contexte
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<LocalizationService>(
                        builder: (context, localizationService, _) {
                          return Text(
                            'choose_meal'.tr(localizationService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Liste des repas existants
                ...existingMeals.map((meal) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onMealSelected(meal);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getMealIcon(meal.name),
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<LocalizationService>(
                                  builder: (context, localizationService, _) {
                                    final count = meal.items.length;
                                    final plural = count > 1 ? 's' : '';
                                    final foodText = 'food_item_count'.tr(localizationService.currentLanguageCode)
                                        .replaceAll('{count}', count.toString())
                                        .replaceAll('{plural}', plural);
                                    return Text(
                                      foodText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _getMealIcon(String mealName) {
    // Normaliser le nom (enlever les numéros et espaces en trop)
    final normalizedName = mealName.toLowerCase()
        .replaceAll(RegExp(r'\s*\d+\s*$'), '') // Enlever les numéros à la fin (ex: "Petit-déjeuner 2" -> "Petit-déjeuner")
        .trim();

    // Vérifier les différentes variantes
    if (normalizedName.contains('petit') && normalizedName.contains('déjeuner')) {
      return LucideIcons.sunrise;
    } else if (normalizedName == 'breakfast') {
      return LucideIcons.sunrise;
    } else if (normalizedName == 'déjeuner' || normalizedName == 'lunch') {
      return LucideIcons.sun;
    } else if (normalizedName == 'dîner' || normalizedName == 'diner' || normalizedName == 'dinner') {
      return LucideIcons.sunset;
    } else if (normalizedName == 'collation' || normalizedName == 'snack') {
      return LucideIcons.milk;
    }

    return LucideIcons.utensils;
  }
} 
