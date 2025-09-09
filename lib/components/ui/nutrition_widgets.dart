import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'nutrition_models.dart';
import 'nutrition_cards.dart';
import '../../screens/ai_scanner_screen.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../screens/select_recipe_screen.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../widgets/nutrition/option_widgets.dart';
import '../../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../../models/nutrition_models.dart' as nutrition_models;
import '../../services/food_entries_service.dart';
import '../../services/auth_service.dart';

// Section des actions rapides nutrition
class NutritionQuickActionsSection extends StatelessWidget {
  final List<NutritionQuickAction> actions;

  const NutritionQuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // Ordre exact du bottomsheet : saisie manuelle, IA, code-barres, recettes
    final quickActions = [
      {'id': 'manual', 'icon': LucideIcons.pencil},
      {'id': 'camera', 'icon': LucideIcons.camera},
      {'id': 'barcode', 'icon': LucideIcons.scan},
      {'id': 'recipe', 'icon': LucideIcons.chefHat},
    ];

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la section
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                'add_quickly'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Boutons d'action rapide
            Row(
              children: quickActions.map((action) {
                final isLast = action == quickActions.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 12),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _handleQuickAction(context, action['id'] as String),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(BuildContext context, String actionId) {
    switch (actionId) {
      case 'manual':
        // Utilise exactement le même flux que dans le journal
        _showManualEntryBottomSheet(context);
        break;
      case 'camera':
        // Navigation directe vers AIScannerScreen avec flag dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIScannerScreen(isFromDashboard: true),
          ),
        );
        break;
      case 'barcode':
        // Flux direct vers sélection de repas pour scanner (éviter double bottom sheet)
        _showDirectMealSelectionForScanner(context);
        break;
      case 'recipe':
        // Flux direct vers sélection de repas pour recettes (même principe que scanner)
        _showDirectMealSelectionForRecipe(context);
        break;
    }
  }

  void _showManualEntryBottomSheet(BuildContext context) {
    // Depuis le dashboard, on doit d'abord demander de sélectionner le repas
    showMealSelectionForDashboard(context);
  }

  // Méthode statique publique pour être appelée depuis le dashboard (recherche manuelle)
  static void showMealSelectionForDashboard(BuildContext context) {
    _showMealSelectionFirst(context);
  }

  // Méthode statique pour les aliments déjà détectés (scanner IA, code-barres)
  static void showMealSelectionWithDetectedFood(BuildContext context, nutrition_models.FoodItem detectedFood) {
    _showMealSelectionForDetectedFood(context, detectedFood);
  }

  // Méthodes publiques pour accéder aux flux de sélection depuis le dashboard
  static Future<void> showMealSelectionForScanner(BuildContext context) async {
    await _showDirectMealSelectionForScanner(context);
  }

  static Future<void> showMealSelectionForRecipe(BuildContext context) async {
    await _showDirectMealSelectionForRecipe(context);
  }

  // Méthodes publiques pour ajouter des aliments depuis le dashboard
  static Future<void> addFoodToSelectedMeal(BuildContext context, nutrition_models.FoodItem foodItem, nutrition_models.Meal selectedMeal) async {
    await _addFoodToSelectedMeal(context, foodItem, selectedMeal);
  }

  static Future<void> addRecipeToNewMealJournalStyle(BuildContext context, nutrition_models.FoodItem foodItem, String mealType) async {
    await _addRecipeToNewMealJournalStyle(context, foodItem, mealType);
  }

  static Future<void> addFoodToNewMealJournalStyle(BuildContext context, nutrition_models.FoodItem foodItem, String mealType) async {
    await _addFoodToNewMealJournalStyle(context, foodItem, mealType);
  }

  // Nouvelle méthode statique pour d'abord sélectionner le repas depuis le dashboard
  static Future<void> _showMealSelectionFirst(BuildContext context) async {
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
                    _showExistingMealsSelection(context, existingMeals);
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
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, child) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'add_to_existing_meal'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, child) => Text(
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
                  _showNewMealTypeSelection(context);
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
                              builder: (context, locService, child) => Text(
                                'create_new_meal_title'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                            ),
                            Text(
                              'Petit-déjeuner, déjeuner, dîner ou collation',
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

  // Méthode statique pour sélection de repas avec aliment déjà détecté
  static Future<void> _showMealSelectionForDetectedFood(BuildContext context, nutrition_models.FoodItem detectedFood) async {
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

    // Afficher le bottom sheet pour sélectionner repas nouveau/existant
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                
                // Titre avec nom de l'aliment détecté
                Text(
                  'Ajouter "${detectedFood.name}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'À quel repas voulez-vous ajouter cet aliment ?',
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
                      // Montrer la liste des repas existants
                      _showExistingMealsSelectionForDetectedFood(context, existingMeals, detectedFood);
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
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, child) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'add_to_existing_meal'.tr(locService.currentLanguageCode),
                                    style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                Text(
                                  'Choisir parmi vos repas d\'aujourd\'hui',
                                    style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                ],
                              ),
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
                    _showNewMealTypeSelectionForDetectedFood(context, detectedFood);
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
                                  style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                'Petit-déjeuner, déjeuner, dîner ou collation',
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
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes auxiliaires pour aliments détectés
  static void _showExistingMealsSelectionForDetectedFood(BuildContext context, List<nutrition_models.Meal> existingMeals, nutrition_models.FoodItem detectedFood) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        _showMealSelectionForDetectedFood(context, detectedFood);
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
                        builder: (context, locService, child) => Text(
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
                      // Ajouter directement l'aliment au repas sélectionné
                      _addFoodToSelectedMeal(context, detectedFood, meal);
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
      ),
    );
  }

  static void _showNewMealTypeSelectionForDetectedFood(BuildContext context, nutrition_models.FoodItem detectedFood) {
        NewMealTypeBottomSheet.show(
          context,
          onMealTypeSelected: (mealType, time) {
        // Créer un meal temporaire avec le type sélectionné
        final newMeal = nutrition_models.Meal(
          name: mealType,
          time: time,
          items: [],
        );
        // Ajouter directement l'aliment au nouveau repas
        _addFoodToSelectedMeal(context, detectedFood, newMeal);
      },
    );
  }

  // Méthode statique pour afficher la sélection des repas existants puis la recherche d'aliments
  static void _showExistingMealsSelection(BuildContext context, List<nutrition_models.Meal> existingMeals) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        _showMealSelectionFirst(context);
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
                        builder: (context, locService, child) => Text(
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
                      // Aller directement à la recherche manuelle puisqu'on a déjà choisi "ajout manuel"
                      _showManualFoodSearchForMeal(context, meal);
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
      ),
    );
  }

  // Méthode statique pour afficher la sélection de nouveau type de repas - FLUX SIMPLIFIÉ COMME LE JOURNAL
  static void _showNewMealTypeSelection(BuildContext context) {
    print('🔄 _showNewMealTypeSelection appelée');
    
    // Stocker une référence au Navigator pour éviter les problèmes de context
    final navigator = Navigator.of(context);
    
    NewMealTypeBottomSheet.show(
      context,
      onMealTypeSelected: (mealType, time) {
        print('🎯 Type de repas sélectionné: $mealType');
        
        // Le NewMealTypeBottomSheet fait déjà Navigator.pop() dans ses options
        // Attendre que l'animation se termine puis ouvrir le nouvel écran
        Future.delayed(const Duration(milliseconds: 300), () {
          // Obtenir le context depuis le navigator stocké
          final newContext = navigator.context;
          if (newContext.mounted) {
            print('🔍 Ouverture recherche manuelle pour nouveau repas avec navigator context');
            _showManualFoodSearchForNewMeal(newContext, mealType);
          } else {
            print('❌ Navigator context invalide');
          }
        });
      },
    );
  }

  // Méthode directe pour sélection de repas recettes (même pattern que le flux manuel)
  static Future<void> _showDirectMealSelectionForRecipe(BuildContext context) async {
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

    // Utiliser directement MealSelectionBottomSheet pour éviter double bottom sheet
    MealSelectionBottomSheet.show(
      context,
      foodName: "recette",
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        print('🎯 Repas existant sélectionné pour recette: ${meal.id}');
        // Ouvrir directement la sélection de recettes avec le repas pré-sélectionné (comme le manuel)
        _showRecipeSelectionForMeal(context, meal);
      },
      onCreateNewMeal: () {
        print('🔄 Nouveau repas demandé pour recette');
        // Afficher la sélection de type de nouveau repas
        _showNewMealTypeSelectionForRecipe(context);
      },
    );
  }

  // Méthode directe pour sélection de repas scanner (même pattern que le flux manuel)
  static Future<void> _showDirectMealSelectionForScanner(BuildContext context) async {
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

    // Utiliser directement MealSelectionBottomSheet pour éviter double bottom sheet
    MealSelectionBottomSheet.show(
      context,
      foodName: "produit scanné",
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        print('🎯 Repas existant sélectionné pour scanner: ${meal.id}');
        // Ouvrir directement le scanner avec le repas pré-sélectionné (comme le manuel)
        _showScannerForMeal(context, meal);
      },
      onCreateNewMeal: () {
        print('🔄 Nouveau repas demandé pour scanner');
        // Afficher la sélection de type de nouveau repas
        _showNewMealTypeSelectionForScanner(context);
      },
    );
  }

  // Méthode pour sélection de repas spécifique au scanner (copie de _showMealSelectionFirst) - SUPPRIMÉE
  static Future<void> _showMealSelectionFirstForScanner_OLD(BuildContext context) async {
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
                'Scanner un code-barre',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
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
                    // Montrer la liste des repas existants puis ouvrir le scanner
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
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, child) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'add_to_existing_meal'.tr(locService.currentLanguageCode),
                                  style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Consumer<LocalizationService>(
                                builder: (context, locService, child) => Text(
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
                  // Montrer la sélection de type de nouveau repas puis ouvrir le scanner
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
                              builder: (context, locService, child) => Text(
                                'create_new_meal_title'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                            ),
                            Text(
                              'Petit-déjeuner, déjeuner, dîner ou collation',
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

  // Méthode pour afficher les repas existants et ouvrir le scanner après sélection
  static void _showExistingMealsSelectionForScanner(BuildContext context, List<nutrition_models.Meal> existingMeals) {
    MealSelectionBottomSheet.show(
      context,
      foodName: "produit scanné",
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        print('🎯 Repas existant sélectionné pour scanner: ${meal.id}');
        // Stocker l'ID du repas sélectionné
        _dashboardSelectedMealId = meal.id;
        _dashboardPendingMealType = null;
        _dashboardPendingMealId = null;
        
        // Ouvrir le scanner avec callback pour ajouter au repas sélectionné
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BarcodeScannerScreen(
              onFoodScanned: (foodItem) {
                // Ajouter à l'ID de repas stocké
                _addFoodToSelectedMealDashboard(context, foodItem, _dashboardSelectedMealId!);
              },
            ),
          ),
        );
      },
      onCreateNewMeal: () {
        print('🔄 Nouveau repas demandé depuis sélection existants');
        // Afficher la sélection de type de nouveau repas
        _showNewMealTypeSelectionForScanner(context);
      },
    );
  }

  // Méthode pour sélection de nouveau type de repas puis ouvrir les recettes
  static void _showNewMealTypeSelectionForRecipe(BuildContext context) {
    print('🔄 _showNewMealTypeSelectionForRecipe appelée');
    
    final navigator = Navigator.of(context);
    
    NewMealTypeBottomSheet.show(
      context,
      onMealTypeSelected: (mealType, time) {
        print('🎯 Type de repas sélectionné pour recette: $mealType');
        
        // Attendre que l'animation se termine puis ouvrir la sélection de recettes
        Future.delayed(const Duration(milliseconds: 300), () {
          final newContext = navigator.context;
          if (newContext.mounted) {
            print('🔍 Ouverture sélection recettes avec nouveau type de repas');
            // Ouvrir la sélection de recettes avec callback pour créer nouveau repas
            Navigator.push(
              newContext,
              MaterialPageRoute(
                builder: (context) => SelectRecipeScreen(
                  isFromDashboard: true,
                  onRecipeSelected: (recipe) {
                    // Utiliser la même logique que le journal pour nouveau repas
                    _addRecipeToNewMealJournalStyle(context, recipe, mealType);
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

  // Méthode pour sélection de nouveau type de repas puis ouvrir le scanner
  static void _showNewMealTypeSelectionForScanner(BuildContext context) {
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
                  onFoodScanned: (foodItem) {
                    // Utiliser la même logique que le journal pour nouveau repas
                    _addFoodToNewMealJournalStyle(context, foodItem, mealType);
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

  // Méthode statique pour afficher les options d'ajout pour le dashboard (comme dans le journal)
  static void _showAddFoodOptionsForDashboard(BuildContext context, nutrition_models.Meal selectedMeal) {
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
              
              // Options d'ajout (identiques au journal)
              _buildFoodOption(
                context,
                icon: LucideIcons.pencil,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  Navigator.pop(context);
                  _showManualFoodSearchForMeal(context, selectedMeal);
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(
                        isFromDashboard: true,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerScreen(
                        isFromDashboard: true,
                        onFoodScanned: (foodItem) {
                          _addFoodToSelectedMeal(context, foodItem, selectedMeal);
                        },
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectRecipeScreen(
                        isFromDashboard: true,
                        onRecipeSelected: (recipe) {
                          _addFoodToSelectedMeal(context, recipe, selectedMeal);
                        },
                      ),
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

  // Widget helper pour les options d'ajout
  static Widget _buildFoodOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
    );
  }

  // Méthode statique pour afficher la recherche d'aliments avec un repas existant pré-sélectionné
  static void _showManualFoodSearchForMeal(BuildContext context, nutrition_models.Meal selectedMeal) {
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodCreated: (foodItem) {
        // Maintenant qu'on a l'aliment et le repas, on peut les ajouter
        _addFoodToSelectedMeal(context, foodItem, selectedMeal);
      },
    );
  }

  // Méthode statique pour afficher le scanner avec un repas existant pré-sélectionné
  static void _showScannerForMeal(BuildContext context, nutrition_models.Meal selectedMeal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          isFromDashboard: true,
          onFoodScanned: (foodItem) {
            // Maintenant qu'on a l'aliment et le repas, on peut les ajouter
            _addFoodToSelectedMeal(context, foodItem, selectedMeal);
          },
        ),
      ),
    );
  }

  // Méthode statique pour afficher la sélection de recettes avec un repas existant pré-sélectionné
  static void _showRecipeSelectionForMeal(BuildContext context, nutrition_models.Meal selectedMeal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRecipeScreen(
          isFromDashboard: true,
          onRecipeSelected: (foodItem) {
            // Le callback reçoit déjà un FoodItem depuis RecipeDetailsScreen
            _addFoodToSelectedMeal(context, foodItem, selectedMeal);
          },
        ),
      ),
    );
  }

  // Méthode statique pour afficher les options d'ajout pour un nouveau repas (comme dans le journal)
  static void _showAddFoodOptionsForNewMeal(BuildContext context, String mealType) {
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
              
              // Options d'ajout pour nouveau repas
              _buildFoodOption(
                context,
                icon: LucideIcons.pencil,
                title: 'Saisie manuelle',
                subtitle: 'Rechercher et ajouter manuellement',
                onTap: () {
                  Navigator.pop(context);
                  _showManualFoodSearchForNewMeal(context, mealType);
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.camera,
                title: 'Scanner avec l\'IA',
                subtitle: 'Prenez une photo de votre plat',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(
                        isFromDashboard: true,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.scan,
                title: 'Code-barres',
                subtitle: 'Scanner le code-barres du produit',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerScreen(
                        isFromDashboard: true,
                        onFoodScanned: (foodItem) {
                          _addFoodToNewMealJournalStyle(context, foodItem, mealType);
                        },
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildFoodOption(
                context,
                icon: LucideIcons.chefHat,
                title: 'Mes recettes',
                subtitle: 'Choisir parmi vos recettes sauvegardées',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectRecipeScreen(
                        isFromDashboard: true,
                        onRecipeSelected: (recipe) {
                          _addFoodToNewMealJournalStyle(context, recipe, mealType);
                        },
                      ),
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

  // Méthode statique pour afficher la recherche d'aliments pour un nouveau repas - MÊME FLUX QUE LE JOURNAL
  static void _showManualFoodSearchForNewMeal(BuildContext context, String mealType) {
    print('🔍 _showManualFoodSearchForNewMeal appelée pour: $mealType');
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodCreated: (foodItem) {
        print('🍽️ Aliment créé: ${foodItem.name}');
        // MÊME FLUX QUE LE JOURNAL - Créer directement le nouveau repas avec l'aliment
        _addFoodToNewMealJournalStyle(context, foodItem, mealType);
      },
    );
  }

  // Variables statiques pour gérer les sélections de repas du dashboard
  static String? _dashboardSelectedMealId;
  static String? _dashboardPendingMealType;
  static String? _dashboardPendingMealId;

  // Méthode pour ajouter une recette à un repas existant depuis le dashboard
  static Future<void> _addRecipeToSelectedMealDashboard(BuildContext context, dynamic recipe, String mealId) async {
    print('🟢 _addRecipeToSelectedMealDashboard appelée');
    print('🟢 recipe: ${recipe.name}');
    print('🟢 mealId: $mealId');
    
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_connected'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('🔄 Ajout de la recette ${recipe.name} au repas ID: $mealId');

      // Extraire le nom du repas depuis l'ID (ex: "Collation 2" -> "Collation")
      final regex = RegExp(r'^(.+?)(?:\s+\d+)?$');
      final match = regex.firstMatch(mealId);
      final mealName = match?.group(1) ?? mealId;
      
      print('🔄 mealId: $mealId → mealName: $mealName');

      // Convertir la recette en FoodItem
      final foodItem = nutrition_models.FoodItem(
        id: recipe.id.toString(),
        name: recipe.name,
        calories: recipe.calories,
        proteins: recipe.proteins.toDouble(),
        carbs: recipe.carbs.toDouble(),
        fats: recipe.fats.toDouble(),
        portion: '1 portion',
        isRecipe: true,
      );

      // Ajouter la recette comme aliment au repas
      await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealId: mealId,
        foodItem: foodItem,
        mealName: mealName, // Utiliser le nom extrait
      );

      // Réinitialiser la sélection après ajout
      resetDashboardMealSelection();

      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recipe_added_success'.tr(locService.currentLanguageCode).replaceAll('{recipeName}', recipe.name)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ Recette ajoutée avec succès au repas');

    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la recette: $e');
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_adding_recipe'.tr(locService.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour ajouter une recette à un nouveau repas (style journal)
  static Future<void> _addRecipeToNewMealJournalStyle(BuildContext context, dynamic recipe, String mealType) async {
    print('🟠 _addRecipeToNewMealJournalStyle appelée');
    print('🟠 recipe: ${recipe.name}');
    print('🟠 mealType: $mealType');
    
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_connected'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('🔄 Création nouveau repas $mealType avec recette ${recipe.name}');

      // Convertir la recette en FoodItem
      final foodItem = nutrition_models.FoodItem(
        id: recipe.id.toString(),
        name: recipe.name,
        calories: recipe.calories,
        proteins: recipe.proteins.toDouble(),
        carbs: recipe.carbs.toDouble(),
        fats: recipe.fats.toDouble(),
        portion: '1 portion',
        isRecipe: true,
      );

      // Utiliser addFoodEntry qui s'occupe de la création automatique du repas
      await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealId: null, // null = création automatique d'un nouveau repas
        foodItem: foodItem,
        mealName: mealType,
      );

      // Les notifications se font automatiquement via FoodEntriesService
      
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('recipe_added_to_new_meal'.tr(locService.currentLanguageCode)
                .replaceAll('{recipeName}', recipe.name)
                .replaceAll('{mealType}', mealType)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ Recette ajoutée avec succès au nouveau repas');

    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la recette au nouveau repas: $e');
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_adding_recipe'.tr(locService.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode statique pour ajouter l'aliment au repas sélectionné (existant)
  static Future<void> _addFoodToSelectedMeal(BuildContext context, nutrition_models.FoodItem foodItem, nutrition_models.Meal selectedMeal) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_connected'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Extraire le type de repas de base depuis le nom (ex: "Dîner 2" -> "Dîner")
      String baseMealName = selectedMeal.name;
      
      // Retirer le numéro d'incrémentation s'il existe
      final regex = RegExp(r'^(.+?)\s+\d+$');
      final match = regex.firstMatch(selectedMeal.name);
      if (match != null && match.group(1) != null) {
        baseMealName = match.group(1)!;
      }
      
      print('🔄 Ajout de ${foodItem.name} au repas existant ${selectedMeal.name} (type: $baseMealName, ID: ${selectedMeal.id})');

      // Stocker l'ID du repas sélectionné pour les ajouts suivants
      _dashboardSelectedMealId = selectedMeal.id;
      _dashboardPendingMealType = null;
      _dashboardPendingMealId = null;

      // Ajouter l'aliment au repas existant en utilisant le meal_id
      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: baseMealName, // Nom de base du repas (ex: "Dîner")
        foodItem: foodItem,
        consumedAt: DateTime.now(),
        mealId: selectedMeal.id, // ID du repas existant pour l'ajouter au bon bloc
      );
      
      if (success) {
        print('✅ Aliment ${foodItem.name} ajouté au repas ${selectedMeal.name} avec succès');
        
        // Réinitialiser la sélection de repas après l'ajout
        resetDashboardMealSelection();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${foodItem.name} ajouté au ${selectedMeal.name}'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        }
      } else {
        throw Exception('Échec de l\'ajout à la base de données');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour ajouter un aliment à un repas existant par ID (dashboard)
  static Future<void> _addFoodToSelectedMealDashboard(BuildContext context, nutrition_models.FoodItem foodItem, String mealId) async {
    print('🔄 _addFoodToSelectedMealDashboard appelée avec mealId: $mealId');
    
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        print('❌ Utilisateur non authentifié');
        return;
      }

      // Extraire le nom du repas depuis l'ID (ex: "Dîner 2" -> "Dîner")
      final regex = RegExp(r'^(.+?)(?:\s+\d+)?$');
      final match = regex.firstMatch(mealId);
      final mealName = match?.group(1) ?? mealId;

      // Ajouter l'aliment directement avec l'ID du repas
      await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: mealName,
        mealId: mealId,
        foodItem: foodItem,
      );

      print('✅ Aliment ajouté avec succès au repas $mealId');
      
      // Réinitialiser la sélection dashboard après ajout
      resetDashboardMealSelection();
      
      // Afficher une notification de succès
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('food_added_success'.tr(locService.currentLanguageCode).replaceAll('{foodName}', foodItem.name)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de l\'aliment: $e');
      if (context.mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_adding_food'.tr(locService.currentLanguageCode).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Méthode statique qui utilise EXACTEMENT LE MÊME FLUX QUE LE JOURNAL
  static Future<void> _addFoodToNewMealJournalStyle(BuildContext context, nutrition_models.FoodItem foodItem, String mealType) async {
    // COPIE EXACTE DU CODE DU JOURNAL nutrition_journal_hybrid.dart
    final user = AuthService().currentUser;
    if (user != null) {
      final mealId = await FoodEntriesService.generateMealId(
        userId: user.id,
        mealName: mealType,
        forDate: DateTime.now(),
      );

      if (mealId != null) {
        // Ajouter l'aliment au nouveau repas avec l'ID pré-généré
        final success = await FoodEntriesService.addFoodEntry(
          userId: user.id,
          mealName: mealType,
          foodItem: foodItem,
          consumedAt: DateTime.now(),
          mealId: mealId,
        );

        if (success) {
          // La notification de mise à jour se fait automatiquement dans addFoodEntry()
          
          if (context.mounted) {
            final locService = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('food_added_to_new_meal'.tr(locService.currentLanguageCode)
                    .replaceAll('{foodName}', foodItem.name)
                    .replaceAll('{mealType}', mealType)),
                backgroundColor: const Color(0xFF0B132B),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (context.mounted) {
            final locService = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('error_creating_meal'.tr(locService.currentLanguageCode)),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_generating_meal_id'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Méthode statique pour ajouter un aliment suivant (en utilisant l'ID stocké)
  static Future<void> _addFoodToCurrentMeal(BuildContext context, nutrition_models.FoodItem foodItem) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (context.mounted) {
          final locService = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_user_not_connected'.tr(locService.currentLanguageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String? targetMealId;
      String? targetMealType;
      String? targetMealName;

      if (_dashboardSelectedMealId != null) {
        // Cas repas existant : utiliser l'ID stocké
        targetMealId = _dashboardSelectedMealId;
        targetMealName = 'repas sélectionné';
        
        // Récupérer le type de repas depuis le nom de l'ID (ex: "Dîner 2" -> "Dîner")
        final regex = RegExp(r'^(.+?)(?:\s+\d+)?$');
        final match = regex.firstMatch(_dashboardSelectedMealId!);
        targetMealType = match?.group(1) ?? _dashboardSelectedMealId!;
        
        print('🔄 Ajout de ${foodItem.name} au repas existant (ID: $targetMealId)');
      } else if (_dashboardPendingMealId != null && _dashboardPendingMealType != null) {
        // Cas nouveau repas : utiliser l'ID pré-généré
        targetMealId = _dashboardPendingMealId;
        targetMealType = _dashboardPendingMealType;
        targetMealName = _dashboardPendingMealId;
        
        print('🔄 Ajout de ${foodItem.name} au nouveau repas (ID: $targetMealId, type: $targetMealType)');
      } else {
        // Aucun repas sélectionné : demander la sélection
        print('⚠️ Aucun repas sélectionné, demande de sélection');
        showMealSelectionForDashboard(context);
        return;
      }

      // Ajouter l'aliment au repas
      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: targetMealType!,
        foodItem: foodItem,
        consumedAt: DateTime.now(),
        mealId: targetMealId!,
      );
      
      if (success) {
        print('✅ Aliment ${foodItem.name} ajouté avec succès');
        
        // Réinitialiser la sélection de repas après l'ajout
        resetDashboardMealSelection();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${foodItem.name} ajouté au $targetMealName'),
              backgroundColor: const Color(0xFF0B132B),
            ),
          );
        }
      } else {
        throw Exception('Échec de l\'ajout à la base de données');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour réinitialiser la sélection de repas
  static void resetDashboardMealSelection() {
    _dashboardSelectedMealId = null;
    _dashboardPendingMealType = null;
    _dashboardPendingMealId = null;
    print('🔄 Sélection de repas réinitialisée');
  }

  // Méthode publique pour ajouter un aliment au repas actuellement sélectionné depuis le dashboard
  static Future<void> addFoodToCurrentDashboardMeal(BuildContext context, nutrition_models.FoodItem foodItem) async {
    await _addFoodToCurrentMeal(context, foodItem);
  }
  
  // Méthode publique pour vérifier si un repas est actuellement sélectionné
  static bool hasDashboardMealSelected() {
    return _dashboardSelectedMealId != null || _dashboardPendingMealId != null;
  }
  
  // Méthode publique pour obtenir le nom du repas actuellement sélectionné  
  static String? getDashboardSelectedMealName() {
    if (_dashboardSelectedMealId != null) {
      return _dashboardSelectedMealId; // Nom du repas existant
    } else if (_dashboardPendingMealId != null) {
      return _dashboardPendingMealId; // Nom du nouveau repas
    }
    return null;
  }
}

// Bouton d'action rapide nutrition
class NutritionQuickActionButton extends StatelessWidget {
  final NutritionQuickAction action;

  const NutritionQuickActionButton({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: action.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: action.colors),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action.icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: action.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Section combinée hydratation et repas
class HydrationAndMealsSection extends StatelessWidget {
  final NutritionProfile profile;
  final List<Meal> meals;
  final VoidCallback? onAddWater;
  final VoidCallback? onAddMeal;

  const HydrationAndMealsSection({
    super.key,
    required this.profile,
    required this.meals,
    this.onAddWater,
    this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Hydratation
        Expanded(
          child: HydrationCard(
            profile: profile,
            onAddWater: onAddWater,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Repas
        Expanded(
          child: MealsCard(
            meals: meals,
            onAddMeal: onAddMeal,
          ),
        ),
      ],
    );
  }
}

// Bottom sheet pour ajouter de l'eau
class WaterBottomSheet extends StatefulWidget {
  final Function(int milliliters)? onWaterAdded;

  const WaterBottomSheet({super.key, this.onWaterAdded});

  @override
  State<WaterBottomSheet> createState() => _WaterBottomSheetState();
}

class _WaterBottomSheetState extends State<WaterBottomSheet> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // S'assurer que le champ est visible dès que le clavier sort
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _textKey.currentContext != null) {
            Scrollable.ensureVisible(
              _textKey.currentContext!,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeIn,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          reverse: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  return Row(
                    children: [
                      const Icon(
                        LucideIcons.droplets,
                        size: 24,
                        color: Color(0xFF0B132B),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'add_water'.tr(localizationService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Options prédéfinies
              Consumer<LocalizationService>(
                builder: (context, localizationService, _) {
                  final waterOptions = NutritionData.getWaterOptions(localizationService.currentLanguageCode);
                  return Column(
                    children: waterOptions.map((option) =>
                      WaterOptionItem(
                        option: option,
                        onTap: () {
                          widget.onWaterAdded?.call(option.milliliters);
                          Navigator.of(context).pop();
                        },
                      )
                    ).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quantité personnalisée
              _buildCustomAmountSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<LocalizationService>(
          builder: (context, localizationService, _) {
            return Text(
              'custom_amount'.tr(localizationService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        Consumer<LocalizationService>(
          builder: (context, localizationService, _) {
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    key: _textKey,
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'enter_amount_ml'.tr(localizationService.currentLanguageCode),
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0B132B)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                CustomButton(
                  text: 'add'.tr(localizationService.currentLanguageCode),
                  onPressed: () {
                    final amount = int.tryParse(_controller.text);
                    if (amount != null && amount > 0) {
                      widget.onWaterAdded?.call(amount);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Bottom sheet pour ajouter un repas
class MealBottomSheet extends StatelessWidget {
  final Function(String mealType, int calories)? onMealAdded;

  const MealBottomSheet({
    super.key,
    this.onMealAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Row(
              children: [
                Icon(
                  LucideIcons.utensils,
                  size: 24,
                  color: Color(0xFF0B132B),
                ),
                SizedBox(width: 12),
                Text(
                  'Ajouter un repas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Options d'ajout rapide
            ...NutritionData.quickActions.map((action) =>
              _buildMealOption(
                context,
                action.label,
                action.icon,
                () {
                  // Logique d'ajout selon le type de repas
                  Navigator.of(context).pop();
                },
              )
            ).toList(),
            
            const SizedBox(height: 16),
            
            // Bouton créer repas personnalisé
            CustomButton(
              text: 'Créer un repas personnalisé',
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: () {
                Navigator.of(context).pop();
                // Navigation vers l'écran de création de repas
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
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
    );
  }
}

// Section d'en-tête nutritionnel avec statistiques
class NutritionHeaderSection extends StatelessWidget {
  final NutritionProfile profile;
  final int animatedCalories;

  const NutritionHeaderSection({
    super.key,
    required this.profile,
    required this.animatedCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message de statut avec émoji
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                profile.progressColor.withOpacity(0.1),
                profile.progressColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            profile.statusMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: profile.progressColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Carte principale des calories
        MainCaloriesCard(
          profile: profile,
          animatedCalories: animatedCalories,
        ),
      ],
    );
  }
}

// Widget utilitaire pour afficher un modal bottom sheet
class NutritionBottomSheetHelper {
  static void showWaterSheet(BuildContext context, Function(int)? onWaterAdded) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WaterBottomSheet(onWaterAdded: onWaterAdded),
    );
  }

  static void showMealSheet(BuildContext context, Function(String, int)? onMealAdded) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MealBottomSheet(onMealAdded: onMealAdded),
    );
  }
}

// Bottom sheet pour les actions rapides avec sélection de repas
class AddFoodBottomSheetForQuickActions extends StatefulWidget {
  const AddFoodBottomSheetForQuickActions({super.key});

  @override
  State<AddFoodBottomSheetForQuickActions> createState() => _AddFoodBottomSheetForQuickActionsState();
}

class _AddFoodBottomSheetForQuickActionsState extends State<AddFoodBottomSheetForQuickActions> {
  int _currentStep = 0; // 0: choisir méthode, 1: détails aliment, 2: choisir repas
  String _selectedFood = '';
  int _selectedCalories = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            
            if (_currentStep == 0) _buildMethodSelection(),
            if (_currentStep == 1) _buildFoodDetails(),
            if (_currentStep == 2) _buildMealSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Column(
      children: [
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
        
        _buildFoodOption(
          icon: LucideIcons.pencil,
          title: 'Saisie manuelle',
          subtitle: 'Rechercher et ajouter manuellement',
          onTap: () => _goToFoodSearchScreen(),
        ),
        
        const SizedBox(height: 12),
        
        _buildFoodOption(
          icon: LucideIcons.camera,
          title: 'Scanner avec l\'IA',
          subtitle: 'Prenez une photo de votre plat',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIScannerScreen(isFromDashboard: true)),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildFoodOption(
          icon: LucideIcons.scan,
          title: 'Code-barres',
          subtitle: 'Scanner le code-barres du produit',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        _buildFoodOption(
          icon: LucideIcons.chefHat,
          title: 'Mes recettes',
          subtitle: 'Choisir parmi vos recettes sauvegardées',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SelectRecipeScreen()),
            );
          },
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodDetails() {
    return Column(
      children: [
        Text(
          _selectedFood,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Informations nutritionnelles pour 100g :',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text('calories'.tr(locService.currentLanguageCode)),
                  ),
                  Text('$_selectedCalories kcal'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text('proteins'.tr(locService.currentLanguageCode)),
                  ),
                  const Text('0g'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text('carbohydrates'.tr(locService.currentLanguageCode)),
                  ),
                  const Text('0g'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text('fats'.tr(locService.currentLanguageCode)),
                  ),
                  const Text('0g'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: Text('back'.tr(locService.currentLanguageCode)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                ),
                child: Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text('continue'.tr(locService.currentLanguageCode), style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMealSelection() {
    final existingMeals = [
      {'name': 'Petit-déjeuner', 'icon': LucideIcons.sunrise, 'time': '8h00'},
      {'name': 'Déjeuner', 'icon': LucideIcons.sun, 'time': '12h30'},
      {'name': 'Collation', 'icon': LucideIcons.milk, 'time': '16h00'},
    ];

    return Column(
      children: [
        const Text(
          'À quel repas voulez-vous ajouter cet aliment ?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Repas existants',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...existingMeals.map((meal) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildMealOption(
            icon: meal['icon'] as IconData,
            title: meal['name'] as String,
            subtitle: meal['time'] as String,
            onTap: () {
              // Ajouter à ce repas et fermer
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_selectedFood} ajouté au ${meal['name']}')),
              );
            },
          ),
        )),
        
        const SizedBox(height: 16),
        
        const Text(
          'Ou créer un nouveau repas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        
        const SizedBox(height: 12),
        
        _buildMealOption(
          icon: LucideIcons.sunrise,
          title: 'Petit-déjeuner',
          subtitle: 'Commencez bien votre journée',
          onTap: () => _createMealAndAdd('Petit-déjeuner'),
        ),
        
        const SizedBox(height: 8),
        
        _buildMealOption(
          icon: LucideIcons.sun,
          title: 'Déjeuner',
          subtitle: 'Votre repas principal de midi',
          onTap: () => _createMealAndAdd('Déjeuner'),
        ),
        
        const SizedBox(height: 8),
        
        _buildMealOption(
          icon: LucideIcons.sunset,
          title: 'Dîner',
          subtitle: 'Terminez la journée en beauté',
          onTap: () => _createMealAndAdd('Dîner'),
        ),
        
        const SizedBox(height: 8),
        
                        _buildMealOption(
                  icon: LucideIcons.milk,
                  title: 'Collation',
                  subtitle: 'En-cas entre les repas',
                  onTap: () => _createMealAndAdd('Collation'),
                ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0B132B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToFoodSearchScreen() {
    setState(() {
      _currentStep = 1;
      _selectedFood = '';
      _selectedCalories = 0;
    });
  }

  void _createMealAndAdd(String mealType) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nouveau repas "$mealType" créé avec ${_selectedFood}')),
    );
  }


}

 
