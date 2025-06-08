import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'nutrition_models.dart';
import 'nutrition_cards.dart';
import '../../screens/ai_scanner_screen.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../screens/select_recipe_screen.dart';
import '../../widgets/nutrition/option_widgets.dart';
import '../../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../../models/nutrition_models.dart' as nutrition_models;

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
      {'id': 'manual', 'icon': LucideIcons.edit3},
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
            const Text(
              'Ajouter rapidement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
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
        // Navigation directe vers BarcodeScannerScreen avec flag dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BarcodeScannerScreen(isFromDashboard: true),
          ),
        );
        break;
      case 'recipe':
        // Navigation directe vers SelectRecipeScreen avec flag dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectRecipeScreen(isFromDashboard: true),
          ),
        );
        break;
    }
  }

  void _showManualEntryBottomSheet(BuildContext context) {
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodSelected: (name, calories, baseWeight) {
        _showFoodDetailsBottomSheet(context, name, calories, baseWeight);
      },
      onFoodCreated: (foodItem) {
        // Quand on crée un aliment depuis le dashboard → afficher sélection de repas
        _handleDashboardFoodSelectionFromDetails(context, foodItem);
      },
    );
  }

  // Fonction statique pour être appelée depuis manual_food_search_bottom_sheet.dart
  static void handleDashboardFoodCreation(BuildContext context, nutrition_models.FoodItem foodItem) {
    // Pour l'exemple, on simule des repas existants
    // TODO: Récupérer les vrais repas du jour depuis la base de données
    final existingMeals = <nutrition_models.Meal>[
      nutrition_models.Meal(
        name: 'Petit-déjeuner',
        time: '08:30',
        items: [
          nutrition_models.FoodItem(
            name: 'Café',
            calories: 5,
            portion: '1 tasse',
          ),
        ],
      ),
      nutrition_models.Meal(
        name: 'Déjeuner',
        time: '12:45',
        items: [
          nutrition_models.FoodItem(
            name: 'Salade',
            calories: 150,
            portion: '200g',
          ),
        ],
      ),
    ];

    MealSelectionBottomSheet.show(
      context,
      foodName: foodItem.name,
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
        // TODO: Ajouter l'aliment créé au repas sélectionné
        print('Ajouter ${foodItem.name} au repas ${meal.name}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${foodItem.name} ajouté au ${meal.name}')),
          );
        }
      },
      onCreateNewMeal: () {
        NewMealTypeBottomSheet.show(
          context,
          onMealTypeSelected: (mealType, time) {
            // TODO: Créer un nouveau repas avec l'aliment créé
            print('Créer un nouveau repas $mealType à $time avec ${foodItem.name}');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${foodItem.name} ajouté au nouveau $mealType')),
              );
            }
          },
        );
      },
    );
  }

  void _showFoodDetailsBottomSheet(BuildContext context, String name, int calories, int baseWeight) {
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
      // Fermer le bottom sheet actuel et ouvrir directement le suivant (comme dans MealSelectionBottomSheet)
      Navigator.pop(context);
      _handleDashboardFoodSelectionFromDetails(context, foodItem);
    },
  );
}

void _handleDashboardFoodSelectionFromDetails(BuildContext context, nutrition_models.FoodItem foodItem) {
  print('DEBUG: _handleDashboardFoodSelectionFromDetails appelée avec ${foodItem.name}');
  // Pour l'exemple, on simule des repas existants
  // TODO: Récupérer les vrais repas du jour depuis la base de données
  final existingMeals = <nutrition_models.Meal>[
    nutrition_models.Meal(
      name: 'Petit-déjeuner',
      time: '08:30',
      items: [
        nutrition_models.FoodItem(
          name: 'Café',
          calories: 5,
          portion: '1 tasse',
        ),
      ],
    ),
    nutrition_models.Meal(
      name: 'Déjeuner',
      time: '12:45',
      items: [
        nutrition_models.FoodItem(
          name: 'Salade',
          calories: 150,
          portion: '200g',
        ),
      ],
    ),
  ];

  // Vérifier que le contexte est monté avant d'afficher le bottom sheet
  if (!context.mounted) {
    print('DEBUG: Contexte non monté, impossible d\'afficher MealSelectionBottomSheet');
    return;
  }
  
  print('DEBUG: Affichage de MealSelectionBottomSheet pour ${foodItem.name}');
  MealSelectionBottomSheet.show(
    context,
    foodName: foodItem.name,
    existingMeals: existingMeals,
    onExistingMealSelected: (meal) {
      // TODO: Ajouter l'aliment au repas sélectionné
      print('Ajouter ${foodItem.name} au repas ${meal.name}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${foodItem.name} ajouté au ${meal.name}')),
        );
      }
    },
    onCreateNewMeal: () {
      NewMealTypeBottomSheet.show(
        context,
        onMealTypeSelected: (mealType, time) {
          // TODO: Créer un nouveau repas avec l'aliment
          print('Créer un nouveau repas $mealType à $time avec ${foodItem.name}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${foodItem.name} ajouté au nouveau $mealType')),
            );
          }
        },
      );
    },
  );
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
class WaterBottomSheet extends StatelessWidget {
  final Function(int milliliters)? onWaterAdded;

  const WaterBottomSheet({
    super.key,
    this.onWaterAdded,
  });

  @override
  Widget build(BuildContext context) {
    final customAmountController = TextEditingController();
    
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
                  LucideIcons.droplets,
                  size: 24,
                  color: Color(0xFF0B132B),
                ),
                SizedBox(width: 12),
                Text(
                  'Ajouter de l\'eau',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Options prédéfinies
            ...NutritionData.waterOptions.map((option) =>
              WaterOptionItem(
                option: option,
                onTap: () {
                  onWaterAdded?.call(option.milliliters);
                  Navigator.of(context).pop();
                },
              )
            ).toList(),
            
            const SizedBox(height: 24),
            
            // Quantité personnalisée
            _buildCustomAmountSection(context, customAmountController),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAmountSection(BuildContext context, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantité personnalisée',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Entrez une quantité en ml',
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
              text: 'Ajouter',
              onPressed: () {
                final amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  onWaterAdded?.call(amount);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
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
          icon: LucideIcons.edit3,
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
                  const Text('Calories'),
                  Text('$_selectedCalories kcal'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Protéines'),
                  Text('25g'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Glucides'),
                  Text('5g'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lipides'),
                  Text('15g'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                ),
                child: const Text('Continuer', style: TextStyle(color: Colors.white)),
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
      _selectedFood = 'Saumon grillé';
      _selectedCalories = 280;
    });
  }



  void _createMealAndAdd(String mealType) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nouveau repas "$mealType" créé avec ${_selectedFood}')),
    );
  }
}

 