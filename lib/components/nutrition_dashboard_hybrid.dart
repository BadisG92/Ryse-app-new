import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'ui/nutrition_models.dart';
import 'ui/nutrition_cards.dart';
import 'ui/nutrition_widgets.dart';

class NutritionDashboardHybrid extends StatefulWidget {
  const NutritionDashboardHybrid({super.key});

  @override
  State<NutritionDashboardHybrid> createState() => _NutritionDashboardHybridState();
}

class _NutritionDashboardHybridState extends State<NutritionDashboardHybrid>
    with TickerProviderStateMixin {
  
  // State variables
  late NutritionProfile nutritionProfile;
  late List<Timer> _timers;
  
  // Animated counters
  int animatedCalories = 0;
  int animatedProtein = 0;
  int animatedCarbs = 0;
  int animatedFat = 0;

  @override
  void initState() {
    super.initState();
    nutritionProfile = NutritionData.profile;
    _timers = [];
    _startAnimations();
  }

  @override
  void dispose() {
    for (Timer timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _startAnimations() {
    // Animation calories
    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (animatedCalories >= nutritionProfile.currentCalories) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      } else {
        setState(() => animatedCalories = min(animatedCalories + 25, nutritionProfile.currentCalories));
      }
    });
    _timers.add(caloriesTimer);

    // Animation protéines
    Timer proteinTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (animatedProtein >= nutritionProfile.currentProtein) {
        timer.cancel();
        setState(() => animatedProtein = nutritionProfile.currentProtein);
      } else {
        setState(() => animatedProtein = min(animatedProtein + 2, nutritionProfile.currentProtein));
      }
    });
    _timers.add(proteinTimer);

    // Animation glucides
    Timer carbsTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (animatedCarbs >= nutritionProfile.currentCarbs) {
        timer.cancel();
        setState(() => animatedCarbs = nutritionProfile.currentCarbs);
      } else {
        setState(() => animatedCarbs = min(animatedCarbs + 3, nutritionProfile.currentCarbs));
      }
    });
    _timers.add(carbsTimer);

    // Animation lipides
    Timer fatTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (animatedFat >= nutritionProfile.currentFat) {
        timer.cancel();
        setState(() => animatedFat = nutritionProfile.currentFat);
      } else {
        setState(() => animatedFat = min(animatedFat + 1, nutritionProfile.currentFat));
      }
    });
    _timers.add(fatTimer);
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          child: Column(
            children: [
              const SizedBox(height: 40), // Safe area
              
              // Header avec statut et calories principales
              NutritionHeaderSection(
                profile: nutritionProfile,
                animatedCalories: animatedCalories,
              ),
              
              const SizedBox(height: 16),
              
              // Macronutriments avec animations
              MacronutrientsCard(
                macros: NutritionData.getMacros(nutritionProfile),
                animatedValues: {
                  'protéines': animatedProtein,
                  'glucides': animatedCarbs,
                  'lipides': animatedFat,
                },
              ),
              
              const SizedBox(height: 16),
              
              // Hydratation + Repas (2 colonnes)
              HydrationAndMealsSection(
                profile: nutritionProfile,
                meals: NutritionData.meals,
                onAddWater: _onAddWater,
                onAddMeal: _onAddMeal,
              ),
              
              const SizedBox(height: 16),
              
              // Conseil IA
              AITipCard(
                tip: NutritionData.tips.first, // TODO: Rotation intelligente
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              NutritionQuickActionsSection(
                actions: NutritionData.quickActions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event handlers - gardés intégrés pour la logique spécifique
  void _onAddWater() {
    NutritionBottomSheetHelper.showWaterSheet(context, _addWaterAmount);
  }

  void _onAddMeal() {
    NutritionBottomSheetHelper.showMealSheet(context, _addMeal);
  }

  void _addWaterAmount(int milliliters) {
    setState(() {
      // Convertir ml en pourcentage (2000ml = 100%)
      double additionalWater = milliliters / 2000.0;
      nutritionProfile = nutritionProfile.copyWith(
        waterLevel: min(1.0, nutritionProfile.waterLevel + additionalWater),
      );
    });

    // Feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${milliliters}ml d\'eau ajoutés ! 💧'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addMeal(String mealType, int calories) {
    setState(() {
      nutritionProfile = nutritionProfile.copyWith(
        currentCalories: nutritionProfile.currentCalories + calories,
      );
    });

    // Redémarrer l'animation des calories
    _restartCaloriesAnimation();

    // Feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repas ajouté : +${calories} kcal ! 🍽️'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restartCaloriesAnimation() {
    // Annuler l'animation en cours
    for (Timer timer in _timers) {
      if (timer.isActive) timer.cancel();
    }
    _timers.clear();

    // Redémarrer depuis la valeur actuelle
    int startValue = animatedCalories;
    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (animatedCalories >= nutritionProfile.currentCalories) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      } else {
        setState(() => animatedCalories = min(animatedCalories + 15, nutritionProfile.currentCalories));
      }
    });
    _timers.add(caloriesTimer);
  }
} 