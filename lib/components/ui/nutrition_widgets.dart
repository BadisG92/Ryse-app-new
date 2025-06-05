import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'nutrition_models.dart';
import 'nutrition_cards.dart';

// Section des actions rapides nutrition
class NutritionQuickActionsSection extends StatelessWidget {
  final List<NutritionQuickAction> actions;

  const NutritionQuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter rapidement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: actions.map((action) => 
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: actions.indexOf(action) < actions.length - 1 ? 12 : 0,
                    ),
                    child: NutritionQuickActionButton(action: action),
                  ),
                )
              ).toList(),
            ),
          ],
        ),
      ),
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
                  // TODO: Implémenter la logique d'ajout selon le type
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
                // TODO: Navigation vers l'écran de création de repas
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