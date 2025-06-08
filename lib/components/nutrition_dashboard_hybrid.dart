import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/nutrition_models.dart';
import 'ui/nutrition_cards.dart';
import 'ui/nutrition_widgets.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../models/nutrition_models.dart';

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
              // Suppression du header avec "C'est parti" - on passe directement aux calories
              MainCaloriesCard(
                profile: nutritionProfile,
                animatedCalories: animatedCalories,
              ),
              
              const SizedBox(height: 16),
              
              // Macronutriments avec animations - sans pourcentages et sans icônes
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
              
              // Conseil IA - avec icône IA
              AITipCard(
                tip: NutritionData.tips.first, // TODO: Rotation intelligente
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions - avec recette et swipe
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
    // Reproduire exactement le même comportement que le bouton "Ajouter un aliment" du journal
    _showAddFoodBottomSheet();
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

  void _showAddFoodBottomSheet() {
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
              
              // Titre
              const Text(
                'Ajouter un aliment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Choisissez comment vous souhaitez ajouter votre aliment',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Options d'ajout d'aliment
              FoodOptionWidget(
                icon: LucideIcons.edit3,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  Navigator.pop(context);
                  _showManualEntryBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  Navigator.pop(context);
                  // Navigation directe comme dans les boutons rapides - simple et efficace
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(isFromDashboard: true),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerScreen(isFromDashboard: true),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectRecipeScreen(isFromDashboard: true),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntryBottomSheet() {
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodSelected: (name, calories, baseWeight) {
        _showFoodDetailsBottomSheet(name, calories, baseWeight);
      },
      onFoodCreated: (foodItem) {
        // Quand on crée un aliment depuis le dashboard → afficher sélection de repas
        NutritionQuickActionsSection.handleDashboardFoodCreation(context, foodItem);
      },
    );
  }

  void _showFoodDetailsBottomSheet(String name, int calories, int baseWeight) {
    EditableFoodDetailsBottomSheet.show(
      context,
      name: name,
      calories: calories,
      proteins: 0,
      glucides: 0,
      lipides: 0,
      quantity: baseWeight.toDouble(),
      isModified: false,
      onFoodAdded: (foodItem) {
        // Quand on ajoute un aliment depuis le dashboard → afficher sélection de repas
        Navigator.pop(context);
        NutritionQuickActionsSection.handleDashboardFoodCreation(context, foodItem);
      },
    );
  }
} 