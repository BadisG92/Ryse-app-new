import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/nutrition_models.dart';
import 'ui/nutrition_cards.dart';
import 'ui/nutrition_widgets.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../services/database_service.dart';
import '../services/dashboard_service.dart';
import '../services/water_service.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/global_state_manager.dart'; // NOUVEAU: GlobalStateManager
import '../models/nutrition_models.dart' as nutrition_models;
import '../screens/select_recipe_screen.dart';
import 'package:provider/provider.dart';

class NutritionDashboardHybrid extends StatefulWidget {
  const NutritionDashboardHybrid({super.key});

  @override
  State<NutritionDashboardHybrid> createState() => _NutritionDashboardHybridState();
}

class _NutritionDashboardHybridState extends State<NutritionDashboardHybrid>
    with TickerProviderStateMixin, GlobalStateListener {

  // State variables
  late NutritionProfile nutritionProfile;
  late List<Timer> _timers;
  bool isLoading = false; // Ne jamais bloquer - affichage immédiat

  // Animated counters
  int animatedCalories = 0;
  int animatedProtein = 0;
  int animatedCarbs = 0;
  int animatedFat = 0;

  // Real meal data
  List<Meal> realMeals = [];

  @override
  void initState() {
    super.initState();
    _timers = [];

    // OPTIMISATION: Chargement instantané depuis GlobalStateManager
    _loadInitialDataSync();

    // Puis charger les vraies données en arrière-plan
    _loadNutritionData();
  }

  /// Chargement synchrone instantané pour éviter tout flash
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;
    final locService = LocalizationService.instance;

    // Créer le profil nutrition instantanément avec les vraies données
    // Calculer les objectifs de macros basés sur l'objectif calorique (30% protéines, 40% glucides, 30% lipides)
    final calorieGoal = globalState.calorieGoal;
    final proteinGoal = (calorieGoal * 0.30 / 4).toInt(); // 4 kcal par gramme
    final carbsGoal = (calorieGoal * 0.40 / 4).toInt();   // 4 kcal par gramme
    final fatsGoal = (calorieGoal * 0.30 / 9).toInt();    // 9 kcal par gramme

    nutritionProfile = NutritionProfile(
      targetCalories: globalState.calorieGoal.toInt(),
      currentCalories: globalState.currentCalories.toInt(),
      targetProtein: proteinGoal,
      currentProtein: globalState.currentProteins.toInt(),
      targetCarbs: carbsGoal,
      currentCarbs: globalState.currentCarbs.toInt(),
      targetFat: fatsGoal,
      currentFat: globalState.currentFats.toInt(),
      currentWaterMl: (globalState.currentWaterL * 1000).toInt(),
      targetWaterMl: (globalState.waterGoalL * 1000).toInt(),
    );

    // Créer les repas avec les données de base
    realMeals = _createMealsWithTranslations({});

    // Démarrer les animations immédiatement
    _startAnimations();

    debugPrint('⚡ Nutrition Dashboard: Données initiales chargées en mode synchrone');
  }

  Future<void> _loadNutritionData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('🔧 Dashboard: userId = $userId');
      if (userId == null) {
        debugPrint('⚠️ Dashboard: Aucun utilisateur connecté, garde les données GlobalState');
        return;
      }

      debugPrint('🔧 Dashboard: Enrichissement avec données DB...');
      // Récupérer les données du tableau de bord pour les objectifs macros
      final dashboardData = await DatabaseService.getNutritionDashboardData(userId);

      debugPrint('🔧 Dashboard: Données DB reçues');

      // Mettre à jour seulement les objectifs (pas les valeurs actuelles - déjà dans GlobalState)
      if (mounted) {
        setState(() {
          nutritionProfile = NutritionProfile(
            targetCalories: dashboardData['targetCalories'],
            currentCalories: GlobalStateManager.instance.currentCalories.toInt(), // Toujours depuis GlobalState
            targetProtein: dashboardData['targetProtein'],
            currentProtein: GlobalStateManager.instance.currentProteins.toInt(), // Toujours depuis GlobalState
            targetCarbs: dashboardData['targetCarbs'],
            currentCarbs: GlobalStateManager.instance.currentCarbs.toInt(), // Toujours depuis GlobalState
            targetFat: dashboardData['targetFat'],
            currentFat: GlobalStateManager.instance.currentFats.toInt(), // Toujours depuis GlobalState
            currentWaterMl: (GlobalStateManager.instance.currentWaterL * 1000).toInt(), // Toujours depuis GlobalState
            targetWaterMl: dashboardData['targetWaterMl'],
          );

          // Mettre à jour les repas avec les calories de la DB
          final mealCalories = dashboardData['mealCalories'] as Map<String, double>;
          realMeals = _createMealsWithTranslations(mealCalories);
        });
      }

      debugPrint('✅ Dashboard: Enrichissement terminé avec ${realMeals.length} repas');
    } catch (e) {
      debugPrint('❌ Dashboard: Erreur enrichissement (non-bloquant): $e');
      // On garde les données GlobalState - pas d'erreur
    }
  }

  @override
  void dispose() {
    for (Timer timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  // Implémentation requise par GlobalStateListener
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    debugPrint('🔔 Nutrition Dashboard: Mise à jour reçue du GlobalState - ${event.type}');

    // Mettre à jour instantanément depuis GlobalState
    final globalState = GlobalStateManager.instance;

    if (mounted) {
      setState(() {
        // Si les objectifs ont changé, recalculer les macros
        if (event.type == ChangeType.goals || event.type == ChangeType.dayReset) {
          final calorieGoal = globalState.calorieGoal;
          final proteinGoal = (calorieGoal * 0.30 / 4).toInt();
          final carbsGoal = (calorieGoal * 0.40 / 4).toInt();
          final fatsGoal = (calorieGoal * 0.30 / 9).toInt();

          nutritionProfile = NutritionProfile(
            targetCalories: globalState.calorieGoal.toInt(),
            currentCalories: globalState.currentCalories.toInt(),
            targetProtein: proteinGoal,
            currentProtein: globalState.currentProteins.toInt(),
            targetCarbs: carbsGoal,
            currentCarbs: globalState.currentCarbs.toInt(),
            targetFat: fatsGoal,
            currentFat: globalState.currentFats.toInt(),
            currentWaterMl: (globalState.currentWaterL * 1000).toInt(),
            targetWaterMl: (globalState.waterGoalL * 1000).toInt(),
          );
        } else {
          // Mise à jour normale des valeurs actuelles
          nutritionProfile = NutritionProfile(
            targetCalories: nutritionProfile.targetCalories,
            currentCalories: globalState.currentCalories.toInt(),
            targetProtein: nutritionProfile.targetProtein,
            currentProtein: globalState.currentProteins.toInt(),
            targetCarbs: nutritionProfile.targetCarbs,
            currentCarbs: globalState.currentCarbs.toInt(),
            targetFat: nutritionProfile.targetFat,
            currentFat: globalState.currentFats.toInt(),
            currentWaterMl: (globalState.currentWaterL * 1000).toInt(),
            targetWaterMl: nutritionProfile.targetWaterMl,
          );
        }

        // Mettre à jour directement les valeurs animées (sans animation) pour réactivité
        animatedCalories = globalState.currentCalories.toInt();
        animatedProtein = globalState.currentProteins.toInt();
        animatedCarbs = globalState.currentCarbs.toInt();
        animatedFat = globalState.currentFats.toInt();
      });
    }

    debugPrint('✅ Nutrition Dashboard: Valeurs mises à jour instantanément');
  }

  void _startAnimations() {
    // 🎬 Animation des calories - 1000ms avec easeOutExpo
    const caloriesDuration = 1000; // 1 seconde
    const caloriesTickTime = 20; // 20ms
    final caloriesTotalTicks = caloriesDuration ~/ caloriesTickTime; // 50 ticks
    final caloriesIncrement = (nutritionProfile.currentCalories / caloriesTotalTicks).ceil();
    
    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: caloriesTickTime), (timer) {
      final elapsed = timer.tick * caloriesTickTime;
      final progress = (elapsed / caloriesDuration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final targetValue = (nutritionProfile.currentCalories * easedProgress).round();
      
      setState(() => animatedCalories = targetValue);
      
      if (progress >= 1.0) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      }
    });
    _timers.add(caloriesTimer);

    // 🥩 Animation protéines - 800ms avec easeOutExpo
    const proteinDuration = 800; // 800ms
    const proteinTickTime = 20; // 20ms
    
    Timer proteinTimer = Timer.periodic(const Duration(milliseconds: proteinTickTime), (timer) {
      final elapsed = timer.tick * proteinTickTime;
      final progress = (elapsed / proteinDuration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final targetValue = (nutritionProfile.currentProtein * easedProgress).round();
      
      setState(() => animatedProtein = targetValue);
      
      if (progress >= 1.0) {
        timer.cancel();
        setState(() => animatedProtein = nutritionProfile.currentProtein);
      }
    });
    _timers.add(proteinTimer);

    // 🍞 Animation glucides - 1000ms avec easeOutExpo
    const carbsDuration = 1000; // 1 seconde
    const carbsTickTime = 20; // 20ms
    
    Timer carbsTimer = Timer.periodic(const Duration(milliseconds: carbsTickTime), (timer) {
      final elapsed = timer.tick * carbsTickTime;
      final progress = (elapsed / carbsDuration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final targetValue = (nutritionProfile.currentCarbs * easedProgress).round();
      
      setState(() => animatedCarbs = targetValue);
      
      if (progress >= 1.0) {
        timer.cancel();
        setState(() => animatedCarbs = nutritionProfile.currentCarbs);
      }
    });
    _timers.add(carbsTimer);

    // 🥑 Animation lipides - 1200ms avec easeOutExpo
    const fatDuration = 1200; // 1.2 secondes
    const fatTickTime = 30; // 30ms
    
    Timer fatTimer = Timer.periodic(const Duration(milliseconds: fatTickTime), (timer) {
      final elapsed = timer.tick * fatTickTime;
      final progress = (elapsed / fatDuration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final targetValue = (nutritionProfile.currentFat * easedProgress).round();
      
      setState(() => animatedFat = targetValue);
      
      if (progress >= 1.0) {
        timer.cancel();
        setState(() => animatedFat = nutritionProfile.currentFat);
      }
    });
    _timers.add(fatTimer);
  }

  @override
  Widget build(BuildContext context) {
    // Plus de loading - affichage immédiat
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
              Consumer<LocalizationService>(
                builder: (context, locService, child) => MacronutrientsCard(
                  macros: NutritionData.getMacros(nutritionProfile, locService.currentLanguageCode),
                  animatedValues: {
                    'protein': animatedProtein,
                    'carbs': animatedCarbs,
                    'fats': animatedFat,
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hydratation + Repas (2 colonnes) - utiliser les vrais repas
              HydrationAndMealsSection(
                profile: nutritionProfile,
                meals: realMeals,
                onAddWater: _onAddWater,
                onAddMeal: _onAddMeal,
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
    // Utiliser le même flux que les boutons rapides : sélection de repas → 5 options
    NutritionQuickActionsSection.showMealSelectionForManualEntry(context);
  }

  // Méthode pour rafraîchir SEULEMENT les données d'hydratation (sans redémarrer les animations)
  Future<void> _refreshHydrationDataOnly() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final dashboardData = await DatabaseService.getNutritionDashboardData(userId);
      
      setState(() {
        // Mettre à jour SEULEMENT les données d'hydratation
        nutritionProfile = nutritionProfile.copyWith(
          currentWaterMl: dashboardData['currentWaterMl'],
          targetWaterMl: dashboardData['targetWaterMl'],
        );
        // NE PAS redémarrer les animations - garder les valeurs actuelles
      });
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des données d\'hydratation: $e');
    }
  }
  
  /// Force la mise à jour des objectifs du dashboard principal
  Future<void> _refreshMainDashboardGoals() async {
    try {
      // Importer le service dashboard et forcer un refresh des objectifs
      await DashboardService.invalidateAndRefreshGoals();
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des objectifs du dashboard principal: $e');
    }
  }

  void _addWaterAmount(int milliliters) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('must_be_logged_in_water'.tr(locService.currentLanguageCode)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      // Ajouter l'entrée d'eau en base de données
      final success = await WaterService.addWaterEntry(
        amount: milliliters,
        sourceType: _getSourceTypeFromAmount(milliliters),
      );

      if (!success) {
        throw Exception('Échec de l\'ajout d\'eau');
      }

      // Rafraîchir les données pour obtenir le nouveau niveau d'hydratation
      await _refreshHydrationDataOnly();
      
      // IMPORTANT: Forcer la mise à jour du dashboard principal
      await _refreshMainDashboardGoals();

      // Feedback visuel avec style app
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('water_added_success'.tr(locService.currentLanguageCode).replaceAll('{amount}', milliliters.toString())),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout d\'eau: $e');
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_adding_water'.tr(locService.currentLanguageCode)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Méthode utilitaire pour déterminer le type de source selon la quantité
  String _getSourceTypeFromAmount(int milliliters) {
    switch (milliliters) {
      case 250:
        return 'glass';
      case 500:
        return 'bottle';
      case 750:
        return 'sports_bottle';
      case 200:
        return 'cup';
      case 1000:
        return 'bottle';
      default:
        return 'manual';
    }
  }

  void _restartAllAnimations() {
    // Annuler toutes les animations en cours
    for (Timer timer in _timers) {
      if (timer.isActive) timer.cancel();
    }
    _timers.clear();

    // Redémarrer toutes les animations depuis 0
    animatedCalories = 0;
    animatedProtein = 0;
    animatedCarbs = 0;
    animatedFat = 0;
    
    _startAnimations();
  }

  void _restartCaloriesAnimation() {
    // Annuler l'animation en cours
    for (Timer timer in _timers) {
      if (timer.isActive) timer.cancel();
    }
    _timers.clear();

    // Redémarrer avec les nouveaux paramètres - 1000ms easeOutExpo
    const caloriesDuration = 1000; // 1 seconde
    const caloriesTickTime = 20; // 20ms

    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: caloriesTickTime), (timer) {
      final elapsed = timer.tick * caloriesTickTime;
      final progress = (elapsed / caloriesDuration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final targetValue = (nutritionProfile.currentCalories * easedProgress).round();
      
      setState(() => animatedCalories = targetValue);
      
      if (progress >= 1.0) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      }
    });
    _timers.add(caloriesTimer);
  }

  List<Meal> _createMealsWithTranslations(Map<String, double> mealCalories) {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final lang = locService.currentLanguageCode;
    
    return [
      Meal(
        id: 'breakfast',
        name: 'breakfast'.tr(lang),
        shortName: locService.isFrench ? 'P.déj' : 'Brkf',
        calories: mealCalories['breakfast']?.round() ?? 0,
        isCompleted: (mealCalories['breakfast'] ?? 0) > 0,
        time: const TimeOfDay(hour: 8, minute: 0),
      ),
      Meal(
        id: 'lunch',
        name: 'lunch'.tr(lang),
        shortName: locService.isFrench ? 'Déj' : 'Lnch',
        calories: mealCalories['lunch']?.round() ?? 0,
        isCompleted: (mealCalories['lunch'] ?? 0) > 0,
        time: const TimeOfDay(hour: 12, minute: 30),
      ),
      Meal(
        id: 'snack',
        name: 'snack'.tr(lang),
        shortName: locService.isFrench ? 'Coll' : 'Snck',
        calories: mealCalories['snack']?.round() ?? 0,
        isCompleted: (mealCalories['snack'] ?? 0) > 0,
        time: const TimeOfDay(hour: 16, minute: 0),
      ),
      Meal(
        id: 'dinner',
        name: 'dinner'.tr(lang),
        shortName: locService.isFrench ? 'Dîner' : 'Dnnr',
        calories: mealCalories['dinner']?.round() ?? 0,
        isCompleted: (mealCalories['dinner'] ?? 0) > 0,
        time: const TimeOfDay(hour: 20, minute: 0),
      ),
    ];
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
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'add_food'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'choose_how_to_add_food'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options d'ajout d'aliment
              Consumer<LocalizationService>(
                builder: (context, locService, child) => FoodOptionWidget(
                  icon: LucideIcons.pencil,
                  title: 'manual_entry'.tr(locService.currentLanguageCode),
                  subtitle: 'search_and_add_manually'.tr(locService.currentLanguageCode),
                  onTap: () {
                    Navigator.pop(context);
                    _showManualEntryBottomSheet();
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => FoodOptionWidget(
                  icon: LucideIcons.camera,
                  title: 'ai_scanner'.tr(locService.currentLanguageCode),
                  subtitle: 'take_photo_of_dish'.tr(locService.currentLanguageCode),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigation directe comme dans les boutons rapides - simple et efficace
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(isFromDashboard: true),
                    ),
                  );
                  // Rafraîchir les données au retour
                  _refreshNutritionData();
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => FoodOptionWidget(
                  icon: LucideIcons.scan,
                  title: 'barcode'.tr(locService.currentLanguageCode),
                  subtitle: 'scan_product_barcode'.tr(locService.currentLanguageCode),
                onTap: () {
                  Navigator.pop(context);
                  // Utiliser EXACTEMENT le même flux que la saisie manuelle
                  _showScannerEntryBottomSheet();
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => FoodOptionWidget(
                  icon: LucideIcons.chefHat,
                  title: 'my_recipes'.tr(locService.currentLanguageCode),
                  subtitle: 'choose_from_saved_recipes'.tr(locService.currentLanguageCode),
                  onTap: () {
                    Navigator.pop(context);
                    // Utiliser EXACTEMENT le même flux que la saisie manuelle
                    _showRecipeEntryBottomSheet();
                  },
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntryBottomSheet() {
    // Utiliser le nouveau flux avec sélection de repas depuis les boutons rapides
    NutritionQuickActionsSection.showMealSelectionForDashboard(context);
  }

  void _showScannerEntryBottomSheet() {
    // Utiliser EXACTEMENT le même flux que le manuel, mais pour le scanner
    _showMealSelectionFirstForScanner(context);
  }

  void _showRecipeEntryBottomSheet() {
    // Utiliser EXACTEMENT le même flux que le manuel, mais pour les recettes
    _showMealSelectionFirstForRecipe(context);
  }

  // COPIE EXACTE de _showMealSelectionFirst mais pour les recettes
  Future<void> _showMealSelectionFirstForRecipe(BuildContext context) async {
    // Récupérer les vrais repas du jour depuis la base de données
    final user = AuthService().currentUser;
    List<nutrition_models.Meal> existingMeals = [];
    
    if (user != null) {
      try {
        final meals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
        existingMeals = meals.where((meal) => meal.items.isNotEmpty).toList();
      } catch (e) {
        print('Erreur lors de la récupération des repas existants: $e');
      }
    }

    // Afficher le premier bottom sheet pour sélectionner repas nouveau/existant
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
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'add_recipe'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'add_to_existing_or_new_meal'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Option 1: Repas existant (si des repas existent)
              if (existingMeals.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Montrer la liste des repas existants avec possibilité d'en sélectionner un
                    _showExistingMealsSelectionForRecipe(context, existingMeals);
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'add_to_existing_meal'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'choose_from_todays_meals'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
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
                  // Montrer la sélection de type de nouveau repas
                  _showNewMealTypeSelectionForRecipe(context);
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'create_new_meal'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                            ),
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'choose_meal_type_to_create'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
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

  // Méthode pour afficher la liste des repas existants puis ouvrir la sélection de recettes
  void _showExistingMealsSelectionForRecipe(BuildContext context, List<nutrition_models.Meal> existingMeals) {
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
              
              // Titre avec bouton retour
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Retourner au premier écran
                      _showMealSelectionFirstForRecipe(context);
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
                      builder: (context, locService, _) => Text(
                        'choose_meal'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Liste des repas existants
              ...existingMeals.map((meal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Maintenant ouvrir la sélection de recettes avec le repas sélectionné
                    _openRecipeSelectionForMeal(context, meal);
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 16,
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
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  '${meal.time} • ${meal.items.length} ${'food_items'.tr(locService.currentLanguageCode)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
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
    );
  }

  // Méthode pour ouvrir la sélection de recettes avec un repas pré-sélectionné
  void _openRecipeSelectionForMeal(BuildContext context, nutrition_models.Meal selectedMeal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRecipeScreen(
          isFromDashboard: true,
          onRecipeSelected: (foodItem) {
            // Utiliser la méthode existante pour ajouter au repas sélectionné
            NutritionQuickActionsSection.addFoodToSelectedMeal(context, foodItem, selectedMeal);
          },
        ),
      ),
    );
  }

  // Méthode pour la sélection de nouveau type de repas puis ouvrir la sélection de recettes
  void _showNewMealTypeSelectionForRecipe(BuildContext context) {
    print('🔄 _showNewMealTypeSelectionForRecipe appelée');
    
    final navigator = Navigator.of(context);
    
    NewMealTypeBottomSheet.show(
      context,
      onMealTypeSelected: (mealType, time) {
        print('🎯 Type de repas sélectionné pour recettes: $mealType');
        
        // Attendre que l'animation se termine puis ouvrir la sélection de recettes
        Future.delayed(const Duration(milliseconds: 300), () {
          final newContext = navigator.context;
          if (newContext.mounted) {
            print('🔍 Ouverture sélection de recettes avec nouveau type de repas');
            // Ouvrir la sélection de recettes avec callback pour créer nouveau repas
            Navigator.push(
              newContext,
              MaterialPageRoute(
                builder: (context) => SelectRecipeScreen(
                  isFromDashboard: true,
                  onRecipeSelected: (foodItem) {
                    // Utiliser la même logique que le journal pour nouveau repas
                    NutritionQuickActionsSection.addRecipeToNewMealJournalStyle(context, foodItem, mealType);
                  },
                ),
              ),
            );
          } else {
            print('❌ Navigator context invalide pour recettes');
          }
        });
      },
    );
  }

  // Méthode pour rafraîchir les données après ajout d'un aliment (avec animations)
  Future<void> _refreshNutritionData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final dashboardData = await DatabaseService.getNutritionDashboardData(userId);
      
      setState(() {
        nutritionProfile = NutritionProfile(
          targetCalories: dashboardData['targetCalories'],
          currentCalories: dashboardData['currentCalories'],
          targetProtein: dashboardData['targetProtein'],
          currentProtein: dashboardData['currentProtein'],
          targetCarbs: dashboardData['targetCarbs'],
          currentCarbs: dashboardData['currentCarbs'],
          targetFat: dashboardData['targetFat'],
          currentFat: dashboardData['currentFat'],
          currentWaterMl: dashboardData['currentWaterMl'],
          targetWaterMl: dashboardData['targetWaterMl'],
        );

        // Mettre à jour les repas avec traductions
        final mealCalories = dashboardData['mealCalories'] as Map<String, double>;
        realMeals = _createMealsWithTranslations(mealCalories);
      });

      // Redémarrer les animations avec les nouvelles valeurs
      _restartAllAnimations();
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement des données: $e');
    }
  }

  // COPIE EXACTE de _showMealSelectionFirst mais pour le scanner
  Future<void> _showMealSelectionFirstForScanner(BuildContext context) async {
    // Récupérer les vrais repas du jour depuis la base de données
    final user = AuthService().currentUser;
    List<nutrition_models.Meal> existingMeals = [];
    
    if (user != null) {
      try {
        final meals = await FoodEntriesService.getFoodEntriesForDate(user.id, DateTime.now());
        existingMeals = meals.where((meal) => meal.items.isNotEmpty).toList();
      } catch (e) {
        print('Erreur lors de la récupération des repas existants: $e');
      }
    }

    // Afficher le premier bottom sheet pour sélectionner repas nouveau/existant
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
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'scan_barcode'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'add_to_existing_or_new_meal'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Option 1: Repas existant (si des repas existent)
              if (existingMeals.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Montrer la liste des repas existants avec possibilité d'en sélectionner un
                    _showExistingMealsSelectionForScanner(context, existingMeals);
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'add_to_existing_meal'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  'choose_from_todays_meals'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
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
                  // Montrer la sélection de type de nouveau repas
                  _showNewMealTypeSelectionForScanner(context);
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'create_new_meal'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                            ),
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'choose_meal_type_to_create'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
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

  // Méthode pour afficher la liste des repas existants puis ouvrir le scanner
  void _showExistingMealsSelectionForScanner(BuildContext context, List<nutrition_models.Meal> existingMeals) {
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
              
              // Titre avec bouton retour
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Retourner au premier écran
                      _showMealSelectionFirstForScanner(context);
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
                      builder: (context, locService, _) => Text(
                        'choose_meal'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Liste des repas existants
              ...existingMeals.map((meal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Maintenant ouvrir le scanner avec le repas sélectionné
                    _openScannerForMeal(context, meal);
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.utensils,
                            size: 16,
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
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, _) => Text(
                                  '${meal.time} • ${meal.items.length} ${'food_items'.tr(locService.currentLanguageCode)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
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
    );
  }

  // Méthode pour ouvrir le scanner avec un repas pré-sélectionné
  void _openScannerForMeal(BuildContext context, nutrition_models.Meal selectedMeal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          isFromDashboard: true,
          onFoodScanned: (foodItem) {
            // Utiliser la méthode existante pour ajouter au repas sélectionné
            NutritionQuickActionsSection.addFoodToSelectedMeal(context, foodItem, selectedMeal);
          },
        ),
      ),
    );
  }

  // Méthode pour la sélection de nouveau type de repas puis ouvrir le scanner
  void _showNewMealTypeSelectionForScanner(BuildContext context) {
    print('🔄 _showNewMealTypeSelectionForScanner appelée');
    
    final navigator = Navigator.of(context);
    
    NewMealTypeBottomSheet.show(
      context,
      onMealTypeSelected: (mealType, time) {
        print('🎯 Type de repas sélectionné pour scanner: $mealType');
        
        // Attendre que l'animation se termine puis ouvrir le scanner
        Future.delayed(const Duration(milliseconds: 300), () {
          final newContext = navigator.context;
          if (newContext.mounted) {
            print('🔍 Ouverture scanner avec nouveau type de repas');
            // Ouvrir le scanner avec callback pour créer nouveau repas
            Navigator.push(
              newContext,
              MaterialPageRoute(
                builder: (context) => BarcodeScannerScreen(
                  isFromDashboard: true,
                  onFoodScanned: (foodItem) {
                                          // Utiliser la même logique que le journal pour nouveau repas
                      NutritionQuickActionsSection.addFoodToNewMealJournalStyle(context, foodItem, mealType);
                  },
                ),
              ),
            );
          } else {
            print('❌ Navigator context invalide pour scanner');
          }
        });
      },
    );
  }
} 
