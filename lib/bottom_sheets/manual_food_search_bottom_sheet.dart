import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart';
import '../components/ui/nutrition_widgets.dart';

class ManualFoodSearchBottomSheet {
  static void show(
    BuildContext context, {
    required Function(String name, int calories, int baseWeight) onFoodSelected,
    required Function(FoodItem foodItem) onFoodCreated,
    bool isFromDashboard = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                        'Rechercher un aliment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un aliment...',
                    hintStyle: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Option "Créer un aliment"
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      if (isFromDashboard) {
                        EditableFoodDetailsBottomSheet.showCreateFood(
                          context,
                          onFoodCreated: (foodItem) {
                            // Import nécessaire en haut du fichier
                            NutritionQuickActionsSection.handleDashboardFoodCreation(
                              context,
                              foodItem,
                            );
                          },
                        );
                      } else {
                        EditableFoodDetailsBottomSheet.showCreateFood(
                          context,
                          onFoodCreated: onFoodCreated,
                        );
                      }
                    }
                  },
                  child: Container(
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
                                'Créer un aliment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                'Créez votre propre aliment personnalisé',
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
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final foods = [
                      {'name': 'Pomme', 'calories': 80, 'per': '100g'},
                      {'name': 'Banane', 'calories': 95, 'per': '100g'},
                      {'name': 'Riz blanc', 'calories': 130, 'per': '100g'},
                      {'name': 'Saumon', 'calories': 280, 'per': '100g'},
                      {'name': 'Avocat', 'calories': 160, 'per': '100g'},
                      {'name': 'Quinoa', 'calories': 120, 'per': '100g'},
                      {'name': 'Yaourt grec', 'calories': 59, 'per': '100g'},
                      {'name': 'Amandes', 'calories': 575, 'per': '100g'},
                      {'name': 'Brocolis', 'calories': 25, 'per': '100g'},
                      {'name': 'Poulet', 'calories': 165, 'per': '100g'},
                    ];
                    
                    final food = foods[index];
                    
                    return FoodSuggestionWidget(
                      name: food['name'] as String,
                      calories: food['calories'] as int,
                      per: food['per'] as String,
                      onTap: () {
                        Navigator.pop(context);
                        onFoodSelected(
                          food['name'] as String,
                          food['calories'] as int,
                          100,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


} 