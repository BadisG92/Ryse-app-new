import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import 'custom_card.dart';
import 'nutrition_models.dart';

// Carte principale des calories avec animation
class MainCaloriesCard extends StatelessWidget {
  final NutritionProfile profile;
  final int animatedCalories;

  const MainCaloriesCard({
    super.key,
    required this.profile,
    required this.animatedCalories,
  });

  @override
  Widget build(BuildContext context) {
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
                            animatedCalories.toString(),
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
                  CaloriesStatItem(
                    label: 'Consommées', 
                    value: profile.currentCalories, 
                    color: const Color(0xFF0B132B),
                  ),
                  CaloriesStatItem(
                    label: 'Restantes', 
                    value: profile.remainingCalories, 
                    color: const Color(0xFF1C2951),
                  ),
                  CaloriesStatItem(
                    label: 'Objectif', 
                    value: profile.targetCalories, 
                    color: const Color(0xFF888888),
                  ),
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
                    value: min(profile.caloriesProgress, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                profile.progressMessage,
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
}

// Item de statistique de calories
class CaloriesStatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const CaloriesStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

// Carte des macronutriments
class MacronutrientsCard extends StatelessWidget {
  final List<MacroNutrient> macros;
  final Map<String, int> animatedValues;

  const MacronutrientsCard({
    super.key,
    required this.macros,
    required this.animatedValues,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
                SizedBox(width: 8),
                Text(
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
            
            ...macros.map((macro) {
              final animatedValue = animatedValues[macro.name.toLowerCase()] ?? macro.current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MacroNutrientItem(
                  macro: macro.copyWith(current: animatedValue),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Item de macronutriment
class MacroNutrientItem extends StatelessWidget {
  final MacroNutrient macro;

  const MacroNutrientItem({
    super.key,
    required this.macro,
  });

  // Couleurs d'origine selon l'ancien fichier
  LinearGradient _getGradientColor(String macroName) {
    switch (macroName.toLowerCase()) {
      case 'protéines':
        return const LinearGradient(colors: [Color(0xFF0B132B), Color(0xFF1C2951)]);
      case 'glucides':
        return LinearGradient(colors: [Color(0xFF0B132B).withOpacity(0.7), Color(0xFF1C2951).withOpacity(0.7)]);
      case 'lipides':
        return const LinearGradient(colors: [Color(0xFF888888), Color(0xFFAAAAAA)]);
      default:
        return const LinearGradient(colors: [Color(0xFF888888), Color(0xFFAAAAAA)]);
    }
  }

  Color _getProgressColor(String macroName) {
    switch (macroName.toLowerCase()) {
      case 'protéines':
        return const Color(0xFF0B132B);
      case 'glucides':
        return Color(0xFF0B132B).withOpacity(0.7);
      case 'lipides':
        return const Color(0xFF888888);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Cercle coloré sans icône
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: _getGradientColor(macro.name),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  macro.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            // Suppression des pourcentages - seulement les valeurs
            Row(
              children: [
                Text(
                  '${macro.current}g',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  ' / ${macro.target}g',
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
        
        // Barre de progression avec couleurs d'origine
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
              value: min(macro.progress, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(macro.name)),
            ),
          ),
        ),
      ],
    );
  }
}

// Carte d'hydratation
class HydrationCard extends StatelessWidget {
  final NutritionProfile profile;
  final VoidCallback? onAddWater;

  const HydrationCard({
    super.key,
    required this.profile,
    this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
                  onTap: onAddWater,
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
                    '${(profile.waterLevel * 2.5).toStringAsFixed(1)}L',
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
                        value: profile.waterLevel,
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
    );
  }
}

// Carte des repas
class MealsCard extends StatelessWidget {
  final List<Meal> meals;
  final VoidCallback? onAddMeal;

  const MealsCard({
    super.key,
    required this.meals,
    this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: Color(0xFF0B132B),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Repas',
                          style: TextStyle(
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
                    Text(
                      NutritionData.mealsProgress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onAddMeal,
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
                children: meals.map((meal) => MealRowItem(meal: meal)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Item de repas
class MealRowItem extends StatelessWidget {
  final Meal meal;

  const MealRowItem({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: meal.isCompleted 
                    ? LinearGradient(colors: meal.statusGradient)
                    : null,
                color: meal.isCompleted ? null : meal.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              meal.shortName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        Text(
          meal.caloriesText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }
}

// Carte de conseil IA
class AITipCard extends StatelessWidget {
  final NutritionTip tip;

  const AITipCard({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tip.accentColor.withOpacity(0.05),
              tip.accentColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.brain,
                size: 20,
                color: const Color(0xFF0B132B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Astuce IA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Option d'eau pour le bottom sheet
class WaterOptionItem extends StatelessWidget {
  final WaterOption option;
  final VoidCallback? onTap;

  const WaterOptionItem({
    super.key,
    required this.option,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                option.icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    option.amount,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              LucideIcons.plus,
              size: 20,
              color: Color(0xFF0B132B),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour copier MacroNutrient avec valeur courante
extension MacroNutrientCopyWith on MacroNutrient {
  MacroNutrient copyWith({
    String? name,
    String? unit,
    int? current,
    int? target,
    Color? color,
    IconData? icon,
  }) {
    return MacroNutrient(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      current: current ?? this.current,
      target: target ?? this.target,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
} 
