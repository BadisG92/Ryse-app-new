import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'dart:math';
import 'ui/custom_card.dart';

class NutritionDashboard extends StatefulWidget {
  const NutritionDashboard({super.key});

  @override
  State<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard>
    with TickerProviderStateMixin {
  // Compteurs animés
  int caloriesCount = 0;
  int proteinCount = 0;
  int carbsCount = 0;
  int fatCount = 0;
  double waterLevel = 0.48;

  // Données cibles
  final int targetCalories = 2500;
  final int currentCalories = 1247;
  final int targetProtein = 150;
  final int currentProtein = 85;
  final int targetCarbs = 250;
  final int currentCarbs = 120;
  final int targetFat = 80;
  final int currentFat = 45;

  late List<Timer> _timers;

  @override
  void initState() {
    super.initState();
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
      if (caloriesCount >= currentCalories) {
        timer.cancel();
        setState(() => caloriesCount = currentCalories);
      } else {
        setState(() => caloriesCount = min(caloriesCount + 25, currentCalories));
      }
    });
    _timers.add(caloriesTimer);

    // Animation protéines
    Timer proteinTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (proteinCount >= currentProtein) {
        timer.cancel();
        setState(() => proteinCount = currentProtein);
      } else {
        setState(() => proteinCount = min(proteinCount + 2, currentProtein));
      }
    });
    _timers.add(proteinTimer);

    // Animation glucides
    Timer carbsTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (carbsCount >= currentCarbs) {
        timer.cancel();
        setState(() => carbsCount = currentCarbs);
      } else {
        setState(() => carbsCount = min(carbsCount + 3, currentCarbs));
      }
    });
    _timers.add(carbsTimer);

    // Animation lipides
    Timer fatTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (fatCount >= currentFat) {
        timer.cancel();
        setState(() => fatCount = currentFat);
      } else {
        setState(() => fatCount = min(fatCount + 1, currentFat));
      }
    });
    _timers.add(fatTimer);
  }

  void addWater() {
    setState(() {
      waterLevel = min(waterLevel + 0.1, 1.0);
    });
  }

  void _onAddWater() {
    _showWaterBottomSheet();
  }

  void _showWaterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWaterBottomSheet(),
    );
  }

  Widget _buildWaterBottomSheet() {
    final TextEditingController customAmountController = TextEditingController();
    
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
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.droplets,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
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
            _buildWaterOption(
              '1 verre',
              '250 ml',
              LucideIcons.wine,
              () => _addWaterAmount(250),
            ),
            
            const SizedBox(height: 12),
            
            _buildWaterOption(
              '1 gourde',
              '500 ml',
              LucideIcons.cupSoda,
              () => _addWaterAmount(500),
            ),
            
            const SizedBox(height: 24),
            
            // Quantité personnalisée
            const Text(
              'Autre quantité',
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: customAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Quantité en ml',
                        hintStyle: TextStyle(color: Color(0xFF888888)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    final amount = int.tryParse(customAmountController.text);
                    if (amount != null && amount > 0) {
                      _addWaterAmount(amount);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFF0B132B),
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.add_circle,
              size: 24,
              color: Color(0xFF0B132B),
            ),
          ],
        ),
      ),
    );
  }

  void _addWaterAmount(int milliliters) {
    Navigator.of(context).pop(); // Fermer le bottom sheet
    
    setState(() {
      // Convertir en litres et ajouter à waterLevel
      final litersToAdd = milliliters / 1000.0;
      final newLevel = (waterLevel * 2.5 + litersToAdd) / 2.5; // 2.5L = objectif total
      waterLevel = min(newLevel, 1.0);
    });
    
    // Afficher le feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.droplets, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('${milliliters}ml ajoutés ! 💧'),
          ],
        ),
        backgroundColor: const Color(0xFF0B132B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onAddMeal() {
    // Logic pour ajouter un repas
    // Pour l'instant, on peut juste afficher un feedback visuel
    setState(() {
      // On pourrait mettre à jour un compteur de repas ici
    });
    // Animation légère - vibration courte
    // HapticFeedback.lightImpact(); // Si vous voulez ajouter une vibration
  }

  LinearGradient getProgressColor(int current, int target) {
    final percentage = (current / target) * 100;
    if (percentage >= 90) {
      return const LinearGradient(
        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
      );
    } else if (percentage >= 70) {
      return LinearGradient(
        colors: [Color(0xFF0B132B).withOpacity(0.8), Color(0xFF1C2951).withOpacity(0.8)],
      );
    } else if (percentage >= 50) {
      return LinearGradient(
        colors: [Color(0xFF0B132B).withOpacity(0.6), Color(0xFF1C2951).withOpacity(0.6)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF888888), Color(0xFFAAAAAA)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          children: [
            // Calories principales avec animation
            _buildMainCaloriesCard(),
            
            const SizedBox(height: 16),
            
            // Macronutriments
            _buildMacronutrientsCard(),
            
            const SizedBox(height: 16),
            
            // Hydratation + Repas (2 colonnes)
            _buildHydrationAndMealsRow(),
            
            const SizedBox(height: 16),
            
            // Conseil IA
            _buildAITipCard(),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            _buildQuickActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCaloriesCard() {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Cercle principal avec compteur animé
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Effet de flou en arrière-plan
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Cercle principal
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            caloriesCount.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statistiques en 3 colonnes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCaloriesStat('Consommées', currentCalories, const Color(0xFF0B132B)),
                  _buildCaloriesStat('Restantes', targetCalories - currentCalories, const Color(0xFF1C2951)),
                  _buildCaloriesStat('Objectif', targetCalories, const Color(0xFF888888)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barre de progression principale
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: min((currentCalories / targetCalories), 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF0B132B),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '${((currentCalories / targetCalories) * 100).round()}% de l\'objectif atteint',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientsCard() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Macronutriments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Protéines
            _buildMacronutrientRow(
              'Protéines',
              proteinCount,
              targetProtein,
              const LinearGradient(colors: [Color(0xFF0B132B), Color(0xFF1C2951)]),
              const Color(0xFF0B132B),
            ),
            
            const SizedBox(height: 16),
            
            // Glucides
            _buildMacronutrientRow(
              'Glucides',
              carbsCount,
              targetCarbs,
              LinearGradient(colors: [Color(0xFF0B132B).withOpacity(0.7), Color(0xFF1C2951).withOpacity(0.7)]),
              Color(0xFF0B132B).withOpacity(0.7),
            ),
            
            const SizedBox(height: 16),
            
            // Lipides
            _buildMacronutrientRow(
              'Lipides',
              fatCount,
              targetFat,
              const LinearGradient(colors: [Color(0xFF888888), Color(0xFFAAAAAA)]),
              const Color(0xFF888888),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacronutrientRow(String name, int current, int target, LinearGradient gradient, Color dotColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${current}g',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  ' / ${target}g',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
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
              value: min((current / target), 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(dotColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHydrationAndMealsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hydratation
        Expanded(
          child: CustomCard(
            child: Container(
              height: 160, // Hauteur fixe pour égaliser les cartes
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12), // Réduction du padding droit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.droplets,
                              size: 16,
                              color: Color(0xFF0B132B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Hydratation',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _onAddWater,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(waterLevel * 2.5).toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        const Text(
                          '/ 2.5L',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                              value: waterLevel,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Repas
        Expanded(
          child: CustomCard(
            child: Container(
              height: 160, // Hauteur fixe pour égaliser les cartes
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12), // Réduction du padding droit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 16,
                              color: Color(0xFF0B132B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Repas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '3/4',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _onAddMeal,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMealRow('P.déj', 320, true),
                        _buildMealRow('Déj', 450, true),
                        _buildMealRow('Coll', 180, true),
                        _buildMealRow('Dîner', 0, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealRow(String name, int calories, bool done) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: done 
                    ? const LinearGradient(colors: [Color(0xFF0B132B), Color(0xFF1C2951)])
                    : null,
                color: done ? null : const Color(0xFFCCCCCC),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        Text(
          done ? calories.toString() : '—',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
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
              children: [
                _buildQuickActionButton(LucideIcons.camera, 'Photo'),
                const SizedBox(width: 12),
                _buildQuickActionButton(LucideIcons.scan, 'Code-barres'),
                const SizedBox(width: 12),
                _buildQuickActionButton(LucideIcons.search, 'Rechercher'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAITipCard() {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  LucideIcons.sparkles,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: 'Conseil : ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: 'Votre apport en protéines est optimal ! Ajoutez une source de glucides complexes au dîner.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 