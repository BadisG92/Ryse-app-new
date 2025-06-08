import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import '../models/nutrition_models.dart';
import '../widgets/nutrition/meal_card.dart';
import '../widgets/nutrition/option_widgets.dart';
import '../widgets/nutrition/calendar_view.dart';
import '../screens/ai_scanner_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/select_recipe_screen.dart';
import '../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../bottom_sheets/manual_food_search_bottom_sheet.dart';

class NutritionJournalHybrid extends StatefulWidget {
  const NutritionJournalHybrid({super.key});

  @override
  State<NutritionJournalHybrid> createState() => _NutritionJournalHybridState();
}

class _NutritionJournalHybridState extends State<NutritionJournalHybrid> {
  bool showCalendar = false;
  int? _selectedMealIndex; // Pour savoir à quel repas ajouter l'aliment
  
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

  void _addFoodToSelectedMeal(FoodItem foodItem) {
    if (_selectedMealIndex != null && _selectedMealIndex! < meals.length) {
      setState(() {
        meals[_selectedMealIndex!].items.add(foodItem);
      });
      
      // Fermer le bottom sheet
      Navigator.pop(context);
      
      // Afficher le message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${foodItem.name} ajouté au ${meals[_selectedMealIndex!].name}'),
          backgroundColor: const Color(0xFF0B132B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.calendar,
                          size: 20,
                          color: Color(0xFF0B132B),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 140), // Ajout de padding bottom pour éviter la barre de navigation
              child: Column(
                children: [
                  // Repas existants
                  ...meals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MealCard(
                        meal: meal,
                        onAddFood: () {
                          _selectedMealIndex = index;
                          _showAddFoodBottomSheet();
                        },
                      ),
                    );
                  }),
                  
                  // Ajouter un repas
                  GestureDetector(
                    onTap: () => _showAddMealBottomSheet(),
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

  // ===== BOTTOM SHEETS INTÉGRÉS =====
  // ✅ Évite les problèmes de contexte en gardant les bottom sheets ici
  // ✅ Utilise les widgets factorés pour la cohérence et la réutilisabilité
  
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
              
              // ✅ Utilise les widgets factorés
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
                  // ✅ Navigation directe sans problème de contexte
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIScannerScreen(),
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
                      builder: (context) => const BarcodeScannerScreen(),
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
                      builder: (context) => const SelectRecipeScreen(),
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

  void _showAddMealBottomSheet() {
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Ajouter un repas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Choisissez le type de repas que vous souhaitez ajouter',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              MealOptionWidget(
                icon: LucideIcons.sunrise,
                title: 'Petit-déjeuner',
                subtitle: 'Repas du matin',
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              MealOptionWidget(
                icon: LucideIcons.sun,
                title: 'Déjeuner',
                subtitle: 'Repas du midi',
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              MealOptionWidget(
                icon: LucideIcons.milk,
                title: 'Collation',
                subtitle: 'En-cas entre les repas',
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodBottomSheet();
                },
              ),
              
              const SizedBox(height: 12),
              
              MealOptionWidget(
                icon: LucideIcons.sunset,
                title: 'Dîner',
                subtitle: 'Repas du soir',
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodBottomSheet();
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
      onFoodSelected: (name, calories, baseWeight) {
        _showFoodDetailsBottomSheet(name, calories, baseWeight);
      },
      onFoodCreated: _addFoodToSelectedMeal,
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
      onFoodAdded: _addFoodToSelectedMeal,
    );
  }
}

 