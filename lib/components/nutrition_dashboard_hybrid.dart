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
import '../services/water_service.dart';
import '../services/food_entries_service.dart';
import '../services/auth_service.dart';
import '../models/nutrition_models.dart' as nutrition_models;
import '../screens/select_recipe_screen.dart';

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
  bool isLoading = true;
  late StreamSubscription _nutritionUpdateSubscription;
  
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
    _loadNutritionData();
    _setupNutritionUpdateListener();
  }

  Future<void> _loadNutritionData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('🔧 Dashboard: userId = $userId');
      if (userId == null) {
        debugPrint('⚠️ Dashboard: Aucun utilisateur connecté, utilisation des données par défaut');
        setState(() {
          nutritionProfile = NutritionData.profile;
          isLoading = false;
        });
        _startAnimations();
        return;
      }

      debugPrint('🔧 Dashboard: Récupération des données...');
      // Récupérer les données du tableau de bord
      final dashboardData = await DatabaseService.getNutritionDashboardData(userId);
      
      debugPrint('🔧 Dashboard: Données reçues = $dashboardData');
      
      // Créer le profil nutrition avec les vraies données
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

      debugPrint('🔧 Dashboard: Profil nutrition créé = ${nutritionProfile.currentCalories}/${nutritionProfile.targetCalories} kcal');

      // Créer les repas avec les vraies calories
      final mealCalories = dashboardData['mealCalories'] as Map<String, double>;
      debugPrint('🔧 Dashboard: Calories par repas = $mealCalories');
      
      realMeals = [
        const Meal(
          id: 'breakfast',
          name: 'Petit-déjeuner',
          shortName: 'P.déj',
          calories: 0,
          isCompleted: false,
          time: TimeOfDay(hour: 8, minute: 0),
        ).copyWith(
          calories: mealCalories['breakfast']?.round() ?? 0,
          isCompleted: (mealCalories['breakfast'] ?? 0) > 0,
        ),
        const Meal(
          id: 'lunch',
          name: 'Déjeuner',
          shortName: 'Déj',
          calories: 0,
          isCompleted: false,
          time: TimeOfDay(hour: 12, minute: 30),
        ).copyWith(
          calories: mealCalories['lunch']?.round() ?? 0,
          isCompleted: (mealCalories['lunch'] ?? 0) > 0,
        ),
        const Meal(
          id: 'snack',
          name: 'Collation',
          shortName: 'Coll',
          calories: 0,
          isCompleted: false,
          time: TimeOfDay(hour: 16, minute: 0),
        ).copyWith(
          calories: mealCalories['snack']?.round() ?? 0,
          isCompleted: (mealCalories['snack'] ?? 0) > 0,
        ),
        const Meal(
          id: 'dinner',
          name: 'Dîner',
          shortName: 'Dîner',
          calories: 0,
          isCompleted: false,
          time: TimeOfDay(hour: 20, minute: 0),
        ).copyWith(
          calories: mealCalories['dinner']?.round() ?? 0,
          isCompleted: (mealCalories['dinner'] ?? 0) > 0,
        ),
      ];

      debugPrint('🔧 Dashboard: ${realMeals.length} repas créés');
      for (final meal in realMeals) {
        debugPrint('   - ${meal.name}: ${meal.calories} kcal (${meal.isCompleted ? "✅" : "❌"})');
      }

      setState(() {
        isLoading = false;
      });
      _startAnimations();
    } catch (e) {
      debugPrint('❌ Dashboard: Erreur lors du chargement des données nutrition: $e');
      setState(() {
        nutritionProfile = NutritionData.profile;
        isLoading = false;
      });
    _startAnimations();
    }
  }

  @override
  void dispose() {
    for (Timer timer in _timers) {
      timer.cancel();
    }
    _nutritionUpdateSubscription.cancel();
    super.dispose();
  }

  // Écouter les mises à jour nutritionnelles en temps réel
  void _setupNutritionUpdateListener() {
    _nutritionUpdateSubscription = FoodEntriesService.nutritionUpdates.listen((update) {
      final updateUserId = update['user_id'] as String?;
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      // Recharger seulement si c'est pour l'utilisateur actuel et pour aujourd'hui
      if (currentUser != null && updateUserId == currentUser.id) {
        debugPrint('🔔 Dashboard: Rechargement automatique des données nutritionnelles');
        _reloadNutritionDataWithoutAnimation();
      }
    });
  }

  // Recharger les données sans relancer les animations
  Future<void> _reloadNutritionDataWithoutAnimation() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('🔄 Dashboard: Mise à jour en temps réel...');
      final dashboardData = await DatabaseService.getNutritionDashboardData(userId);
      
      // Mettre à jour seulement les données, pas les animations
      final newProfile = NutritionProfile(
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

      // Mettre à jour les calories des repas
      final mealCalories = dashboardData['mealCalories'] as Map<String, double>;
      final updatedMeals = realMeals.map((meal) {
        final newCalories = mealCalories[meal.id]?.round() ?? 0;
        return meal.copyWith(
          calories: newCalories,
          isCompleted: newCalories > 0,
        );
      }).toList();

      setState(() {
        nutritionProfile = newProfile;
        realMeals = updatedMeals;
        // Mettre à jour directement les valeurs animées (sans animation)
        animatedCalories = newProfile.currentCalories;
        animatedProtein = newProfile.currentProtein;
        animatedCarbs = newProfile.currentCarbs;
        animatedFat = newProfile.currentFat;
      });
      
      debugPrint('✅ Dashboard: Données mises à jour en temps réel');
    } catch (e) {
      debugPrint('❌ Dashboard: Erreur lors de la mise à jour: $e');
    }
  }

  void _startAnimations() {
    // Animation des calories avec durée fixe de 3 secondes
    const animationDuration = 3000; // 3 secondes en millisecondes
    const updateInterval = 20; // Mise à jour toutes les 20ms
    final totalSteps = animationDuration ~/ updateInterval; // Nombre total d'étapes
    final caloriesIncrement = (nutritionProfile.currentCalories / totalSteps).ceil(); // Incrément par étape
    
    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      if (animatedCalories >= nutritionProfile.currentCalories) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      } else {
        setState(() => animatedCalories = min(animatedCalories + caloriesIncrement, nutritionProfile.currentCalories));
      }
    });
    _timers.add(caloriesTimer);

    // Animation protéines (plus lente pour étaler dans le temps)
    Timer proteinTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
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
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
              
              // Hydratation + Repas (2 colonnes) - utiliser les vrais repas
              HydrationAndMealsSection(
                profile: nutritionProfile,
                meals: realMeals,
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

  void _addWaterAmount(int milliliters) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour enregistrer l\'hydratation'),
          duration: Duration(seconds: 2),
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

      // Feedback visuel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$milliliters ml d\'eau ajoutés ! 💧'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0B132B),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout d\'eau: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ajout d\'eau'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
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

    // Redémarrer avec durée fixe de 3 secondes
    const animationDuration = 3000; // 3 secondes en millisecondes
    const updateInterval = 20; // Mise à jour toutes les 20ms
    final totalSteps = animationDuration ~/ updateInterval; // Nombre total d'étapes
    final caloriesIncrement = (nutritionProfile.currentCalories / totalSteps).ceil(); // Incrément par étape

    Timer caloriesTimer = Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      if (animatedCalories >= nutritionProfile.currentCalories) {
        timer.cancel();
        setState(() => animatedCalories = nutritionProfile.currentCalories);
      } else {
        setState(() => animatedCalories = min(animatedCalories + caloriesIncrement, nutritionProfile.currentCalories));
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
                icon: LucideIcons.pencil,
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
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  Navigator.pop(context);
                  // Utiliser EXACTEMENT le même flux que la saisie manuelle
                  _showScannerEntryBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              FoodOptionWidget(
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  Navigator.pop(context);
                  // Utiliser EXACTEMENT le même flux que la saisie manuelle
                  _showRecipeEntryBottomSheet();
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
              const Text(
                'Ajouter une recette',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Voulez-vous ajouter à un repas existant ou créer un nouveau repas ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ajouter à un repas existant',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                'Choisir parmi vos repas d\'aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Créer un nouveau repas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                            Text(
                              'Choisir le type de repas à créer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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
                  const Expanded(
                    child: Text(
                      'Choisir un repas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
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
                              Text(
                                '${meal.time} • ${meal.items.length} aliment(s)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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

        // Mettre à jour les repas
        final mealCalories = dashboardData['mealCalories'] as Map<String, double>;
        realMeals = [
          const Meal(
            id: 'breakfast',
            name: 'Petit-déjeuner',
            shortName: 'P.déj',
            calories: 0,
            isCompleted: false,
            time: TimeOfDay(hour: 8, minute: 0),
          ).copyWith(
            calories: mealCalories['breakfast']?.round() ?? 0,
            isCompleted: (mealCalories['breakfast'] ?? 0) > 0,
          ),
          const Meal(
            id: 'lunch',
            name: 'Déjeuner',
            shortName: 'Déj',
            calories: 0,
            isCompleted: false,
            time: TimeOfDay(hour: 12, minute: 30),
          ).copyWith(
            calories: mealCalories['lunch']?.round() ?? 0,
            isCompleted: (mealCalories['lunch'] ?? 0) > 0,
          ),
          const Meal(
            id: 'snack',
            name: 'Collation',
            shortName: 'Coll',
            calories: 0,
            isCompleted: false,
            time: TimeOfDay(hour: 16, minute: 0),
          ).copyWith(
            calories: mealCalories['snack']?.round() ?? 0,
            isCompleted: (mealCalories['snack'] ?? 0) > 0,
          ),
          const Meal(
            id: 'dinner',
            name: 'Dîner',
            shortName: 'Dîner',
            calories: 0,
            isCompleted: false,
            time: TimeOfDay(hour: 20, minute: 0),
          ).copyWith(
            calories: mealCalories['dinner']?.round() ?? 0,
            isCompleted: (mealCalories['dinner'] ?? 0) > 0,
          ),
        ];
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
              const Text(
                'Scanner un code-barres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Voulez-vous ajouter à un repas existant ou créer un nouveau repas ?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ajouter à un repas existant',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                'Choisir parmi vos repas d\'aujourd\'hui',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Créer un nouveau repas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                            Text(
                              'Choisir le type de repas à créer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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
                  const Expanded(
                    child: Text(
                      'Choisir un repas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
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
                              Text(
                                '${meal.time} • ${meal.items.length} aliment(s)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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
