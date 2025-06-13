import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'custom_badge.dart';
import 'scrollable_fade_container.dart';
import 'dashboard_models.dart';
import 'dashboard_cards.dart';
import 'global_progress_models.dart';
import 'nutrition_widgets.dart';
import '../shared/workout_actions.dart';
import '../../screens/ai_scanner_screen.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../screens/select_recipe_screen.dart';
import '../../screens/weight_evolution_screen.dart';
import '../../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../../models/nutrition_models.dart' as nutrition_models;

// Section des actions rapides
class QuickActionsSection extends StatefulWidget {
  final List<QuickAction> actions;

  const QuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Que faisons-nous aujourd\'hui ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions - Ligne horizontale scrollable avec effet fade
          SizedBox(
            height: 120, // Hauteur généreuse pour éviter tout overflow de texte
            child: ScrollableFadeContainer(
              controller: _scrollController,
              fadeWidth: 24.0,
              fadeColor: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: widget.actions.length,
                itemBuilder: (context, index) {
                  final action = widget.actions[index];
                  // Créer une copie de l'action avec le bon callback
                  final actionWithCallback = QuickAction(
                    id: action.id,
                    label: action.label,
                    icon: action.icon,
                    reward: action.reward,
                    isDisabled: action.isDisabled,
                    isPremiumRequired: action.isPremiumRequired,
                    onTap: () => _handleQuickAction(context, action),
                  );
                  return QuickActionButton(action: actionWithCallback);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _handleQuickAction(BuildContext context, QuickAction action) {
    if (action.isDisabled || action.isPremiumRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité disponible avec Premium'),
          backgroundColor: Color(0xFF0B132B),
        ),
      );
      return;
    }

    switch (action.id) {
      case 'add_meal':
        _showAddMealBottomSheet(context);
        break;
      case 'add_water':
        _handleAddWater(context);
        break;
      case 'take_photo':
        _navigateToAIScanner(context);
        break;
      case 'cardio':
        _showCardioOptions(context);
        break;
      case 'musculation':
        _showMusculationOptions(context);
        break;
      case 'weight_tracking':
        _navigateToWeightEvolution(context);
        break;
    }
  }

  void _handleAddWater(BuildContext context) {
    // Utiliser le même bottom sheet que le "+" d'hydratation du dashboard nutrition
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WaterBottomSheet(
        onWaterAdded: (milliliters) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💧 ${milliliters}ml d\'eau ajoutés !'),
              backgroundColor: const Color(0xFF0B132B),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showAddMealBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ajouter un aliment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildAddMealOption(
                      context,
                      LucideIcons.pencil,
                      'Saisie manuelle',
                      'Rechercher et ajouter manuellement',
                      () {
                        Navigator.pop(context);
                        _showManualEntryBottomSheet(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAddMealOption(
                      context,
                      LucideIcons.camera,
                      'Scanner avec l\'IA',
                      'Prenez une photo de votre plat',
                      () {
                        Navigator.pop(context);
                        _navigateToAIScanner(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAddMealOption(
                      context,
                      LucideIcons.scan,
                      'Code-barres',
                      'Scanner le code-barres du produit',
                      () {
                        Navigator.pop(context);
                        _navigateToBarcode(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAddMealOption(
                      context,
                      LucideIcons.chefHat,
                      'Mes recettes',
                      'Choisir parmi vos recettes',
                      () {
                        Navigator.pop(context);
                        _navigateToRecipes(context);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMealOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAIScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIScannerScreen(isFromDashboard: true),
      ),
    );
  }

  void _navigateToBarcode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(isFromDashboard: true),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectRecipeScreen(isFromDashboard: true),
      ),
    );
  }

  void _showCardioOptions(BuildContext context) {
    // Utiliser exactement le même bottom sheet que dans le dashboard sport
    _showCardioBottomSheet(context);
  }

  void _showMusculationOptions(BuildContext context) {
    // Utiliser exactement le même bottom sheet que dans le dashboard sport
    WorkoutActions.showMusculationBottomSheet(context);
  }

  void _showCardioBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              
              const Text(
                'Cardio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Choisissez votre activité cardio',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Grille 2x2 avec les 4 options cardio
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardioOption(
                          context,
                          icon: LucideIcons.bike,
                          title: 'Vélo',
                          onTap: () => _handleCardioSelection(context, 'Vélo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCardioOption(
                          context,
                          icon: LucideIcons.footprints,
                          title: 'Marche',
                          onTap: () => _handleCardioSelection(context, 'Marche'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCardioOption(
                          context,
                          icon: LucideIcons.zap,
                          title: 'Course',
                          onTap: () => _handleCardioSelection(context, 'Course'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCardioOption(
                          context,
                          icon: LucideIcons.timer,
                          title: 'HIIT',
                          onTap: () => _handleCardioSelection(context, 'HIIT'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardioOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardioSelection(BuildContext context, String cardioType) {
    Navigator.pop(context); // Fermer le bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Démarrage de la séance $cardioType'),
        backgroundColor: const Color(0xFF0B132B),
      ),
    );
  }

  void _navigateToWeightEvolution(BuildContext context) {
    final now = DateTime.now();
    final sampleEntries = [
      WeightEntry(date: now.subtract(const Duration(days: 30)), weight: 72.5),
      WeightEntry(date: now.subtract(const Duration(days: 25)), weight: 71.8),
      WeightEntry(date: now.subtract(const Duration(days: 20)), weight: 71.2),
      WeightEntry(date: now.subtract(const Duration(days: 15)), weight: 70.9),
      WeightEntry(date: now.subtract(const Duration(days: 10)), weight: 70.5),
      WeightEntry(date: now.subtract(const Duration(days: 5)), weight: 70.1),
      WeightEntry(date: now, weight: 69.8),
    ];

    final weightProgress = WeightProgress(
      currentWeight: 69.8,
      previousWeight: 72.5,
      initialWeight: 75.0,
      targetWeight: 68.0,
      entries: sampleEntries,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeightEvolutionScreen(progress: weightProgress),
      ),
    );
  }

  void _showManualEntryBottomSheet(BuildContext context) {
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodSelected: (name, calories, baseWeight) {
        _showFoodDetailsBottomSheet(context, name, calories, baseWeight);
      },
      onFoodCreated: (foodItem) {
        _handleDashboardFoodSelectionFromDetails(context, foodItem);
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
        Navigator.pop(context);
        _handleDashboardFoodSelectionFromDetails(context, foodItem);
      },
    );
  }

  void _handleDashboardFoodSelectionFromDetails(BuildContext context, nutrition_models.FoodItem foodItem) {
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

    if (!context.mounted) return;

    MealSelectionBottomSheet.show(
      context,
      foodName: foodItem.name,
      existingMeals: existingMeals,
      onExistingMealSelected: (meal) {
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

// Section des objectifs journaliers
class DailyGoalsSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final bool isPremium;

  const DailyGoalsSection({
    super.key,
    required this.goals,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les stats
    final completedGoals = goals.where((goal) => goal.completed).length;
    final totalGoals = goals.length;
    final completionRate = (completedGoals / totalGoals * 100).round();
    
    // Les objectifs sont considérés comme atteints si 3 sur 4 sont complétés
    final isGoalsAchieved = completedGoals >= 3;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.target, 
                      size: 20, 
                      color: Color(0xFF0B132B),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Objectifs du jour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$completedGoals/$totalGoals',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Goals list
            ...goals.map((goal) => DailyGoalItem(
              goal: goal,
              isPremium: isPremium,
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// Section preview nutrition & sport
class ModulesPreviewSection extends StatelessWidget {
  final List<ModulePreview> modules;
  final Function(String moduleTitle)? onModuleTap;

  const ModulesPreviewSection({
    super.key,
    required this.modules,
    this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: modules.map((module) => 
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: modules.indexOf(module) < modules.length - 1 ? 16 : 0,
            ),
            child: ModulePreviewCard(
              module: module,
              onTap: onModuleTap != null 
                ? () => onModuleTap!(module.title)
                : null,
            ),
          ),
        )
      ).toList(),
    );
  }
}

// Section statistiques communautaires
class CommunityStatsSection extends StatelessWidget {
  final CommunityStats stats;

  const CommunityStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.users, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Communauté Ryze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCommunityStat(
                  stats.activeUsersText,
                  'membres actifs',
                  LucideIcons.users,
                ),
                _buildCommunityStat(
                  stats.completedGoalsToday.toString(),
                  'objectifs atteints',
                  LucideIcons.target,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trendingUp, size: 16, color: Color(0xFF0B132B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔥 Challenge populaire : ${stats.topChallenge}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildCommunityStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// CTA Premium
class PremiumCTASection extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const PremiumCTASection({
    super.key,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.crown, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Débloquez votre potentiel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Photos illimitées + Coach IA personnel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: DashboardData.premiumFeatures.map((feature) =>
                PremiumFeatureItem(
                  value: feature['value']!,
                  label: feature['label']!,
                )
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Essayer 7 jours gratuits',
              icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: onUpgrade,
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Puis 15€/mois • Annulable à tout moment',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Section Premium Insights (pour utilisateurs premium)
class PremiumInsightsSection extends StatelessWidget {
  final VoidCallback? onViewAnalytics;

  const PremiumInsightsSection({
    super.key,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.sparkles, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach IA Personnel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                CustomBadge(
                  text: 'Premium',
                  backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                  textColor: const Color(0xFF0B132B),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎯 Analyse personnalisée : Votre métabolisme est optimal entre 14h-16h. C\'est le moment idéal pour votre collation protéinée !',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Voir mes analytics avancés',
              icon: const Icon(LucideIcons.trendingUp, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: onViewAnalytics,
            ),
          ],
        ),
      ),
    );
  }
} 
