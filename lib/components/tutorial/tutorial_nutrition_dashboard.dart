import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/nutrition_models.dart';
import '../ui/nutrition_cards.dart';
import '../ui/nutrition_widgets.dart';
import '../ui/custom_card.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

/// Page Nutrition Dashboard mockée pour le tutorial
/// Affiche des données vierges (0 calories, 0 repas) pour guider l'utilisateur
class TutorialNutritionDashboard extends StatelessWidget {
  final GlobalKey caloriesKey;
  final GlobalKey macrosKey;
  final GlobalKey hydrationMealsKey;
  final GlobalKey quickActionsKey;
  final ScrollController? scrollController;

  const TutorialNutritionDashboard({
    super.key,
    required this.caloriesKey,
    required this.macrosKey,
    required this.hydrationMealsKey,
    required this.quickActionsKey,
    this.scrollController,
  });

  /// Données mockées vierges pour le tutorial
  NutritionProfile _getMockProfile() {
    return NutritionProfile(
      targetCalories: 2000,
      currentCalories: 0,
      targetProtein: 150,
      currentProtein: 0,
      targetCarbs: 200,
      currentCarbs: 0,
      targetFat: 67,
      currentFat: 0,
      currentWaterMl: 0,
      targetWaterMl: 2000,
    );
  }

  /// Repas vides mockés
  List<Meal> _getMockMeals(String languageCode) {
    return [
      Meal(
        id: 'breakfast',
        name: languageCode == 'fr' ? 'Petit-déjeuner' : 'Breakfast',
        shortName: languageCode == 'fr' ? 'P-déj' : 'Break',
        calories: 0,
        isCompleted: false,
      ),
      Meal(
        id: 'lunch',
        name: languageCode == 'fr' ? 'Déjeuner' : 'Lunch',
        shortName: languageCode == 'fr' ? 'Déj' : 'Lunch',
        calories: 0,
        isCompleted: false,
      ),
      Meal(
        id: 'dinner',
        name: languageCode == 'fr' ? 'Dîner' : 'Dinner',
        shortName: languageCode == 'fr' ? 'Dîner' : 'Dinner',
        calories: 0,
        isCompleted: false,
      ),
      Meal(
        id: 'snack',
        name: languageCode == 'fr' ? 'Collations' : 'Snacks',
        shortName: languageCode == 'fr' ? 'Snack' : 'Snack',
        calories: 0,
        isCompleted: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        final profile = _getMockProfile();
        final meals = _getMockMeals(locService.currentLanguageCode);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                ],
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
              child: Column(
                children: [
                  // 1. Carte des calories
                  MainCaloriesCard(
                    key: caloriesKey,
                    profile: profile,
                    animatedCalories: 0,
                  ),

                  const SizedBox(height: 16),

                  // 2. Macronutriments
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => MacronutrientsCard(
                      key: macrosKey,
                      macros: NutritionData.getMacros(profile, locService.currentLanguageCode),
                      animatedValues: {
                        'protein': 0,
                        'carbs': 0,
                        'fats': 0,
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Hydratation + Repas
                  HydrationAndMealsSection(
                    key: hydrationMealsKey,
                    profile: profile,
                    meals: meals,
                    onAddWater: () {}, // Désactivé en mode tutorial
                    onAddMeal: () {}, // Désactivé en mode tutorial
                  ),

                  const SizedBox(height: 16),

                  // 4. Quick Actions
                  NutritionQuickActionsSection(
                    key: quickActionsKey,
                    actions: NutritionData.quickActions,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
