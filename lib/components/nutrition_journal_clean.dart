import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../models/nutrition_models.dart';
import '../widgets/nutrition/meal_card.dart';
import '../widgets/nutrition/calendar_view.dart';
import '../bottom_sheets/add_food_bottom_sheet.dart';
import '../bottom_sheets/add_meal_bottom_sheet.dart';
import '../bottom_sheets/manual_entry_bottom_sheet.dart';
import '../bottom_sheets/food_details_bottom_sheet.dart';

class NutritionJournal extends StatefulWidget {
  const NutritionJournal({super.key});

  @override
  State<NutritionJournal> createState() => _NutritionJournalState();
}

class _NutritionJournalState extends State<NutritionJournal> {
  bool showCalendar = false;
  
  // Données statiques pour la démo
  final List<Meal> meals = [
    Meal(
      time: '8h00',
      name: 'Petit-déjeuner',
      items: [
        FoodItem(name: 'Flocons d\'avoine', calories: 300, portion: '80g'),
        FoodItem(name: 'Banane', calories: 95, portion: '1 moyenne'),
        FoodItem(name: 'Lait d\'amande', calories: 30, portion: '200ml'),
      ],
    ),
    Meal(
      time: '12h30',
      name: 'Déjeuner',
      items: [
        FoodItem(name: 'Salade de quinoa', calories: 220, portion: '150g'),
        FoodItem(name: 'Saumon grillé', calories: 280, portion: '120g'),
        FoodItem(name: 'Légumes vapeur', calories: 80, portion: '200g'),
      ],
    ),
    Meal(
      time: '16h00',
      name: 'Collation',
      items: [
        FoodItem(name: 'Pomme', calories: 80, portion: '1 moyenne'),
        FoodItem(name: 'Amandes', calories: 210, portion: '30g'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (showCalendar) {
      return CalendarView(
        onBack: () => setState(() => showCalendar = false),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Column(
        children: [
          // Header avec le résumé du jour
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                // Header avec date et calendrier
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'Mardi 15 janvier 2024',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showCalendar = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B132B).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.calendar,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bilan calorique du jour
                _buildDaySummary(),
              ],
            ),
          ),
          
          // Liste des repas (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Repas existants
                  ...meals.map((meal) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MealCard(
                      meal: meal,
                      onAddFood: () => AddFoodBottomSheet.show(context, _showManualEntryBottomSheet),
                    ),
                  )),
                  
                  // Ajouter un repas
                  GestureDetector(
                    onTap: () => AddMealBottomSheet.show(context, () => AddFoodBottomSheet.show(context, _showManualEntryBottomSheet)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ajouter un repas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary() {
    // Données caloriques
    const int currentCalories = 1295;
    const int targetCalories = 2500;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Ligne de titre avec icône
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.flame,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bilan calorique',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ligne de texte principale avec style bicolore
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: '$currentCalories kcal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  TextSpan(
                    text: ' / $targetCalories kcal consommées',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Barre de progression
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentCalories / targetCalories).clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0B132B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryBottomSheet() {
    ManualEntryBottomSheet.show(context, _showFoodDetailsBottomSheet);
  }

  void _showFoodDetailsBottomSheet(String name, int calories, int baseWeight) {
    FoodDetailsBottomSheet.show(context, name, calories, baseWeight);
  }
} 