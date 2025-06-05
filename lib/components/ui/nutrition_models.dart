import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

// Modèle de profil nutritionnel
class NutritionProfile {
  final int targetCalories;
  final int currentCalories;
  final int targetProtein;
  final int currentProtein;
  final int targetCarbs;
  final int currentCarbs;
  final int targetFat;
  final int currentFat;
  final double waterLevel; // 0.0 à 1.0

  const NutritionProfile({
    required this.targetCalories,
    required this.currentCalories,
    required this.targetProtein,
    required this.currentProtein,
    required this.targetCarbs,
    required this.currentCarbs,
    required this.targetFat,
    required this.currentFat,
    required this.waterLevel,
  });

  // Calories restantes
  int get remainingCalories => max(0, targetCalories - currentCalories);

  // Pourcentage d'objectif atteint
  double get caloriesProgress => currentCalories / targetCalories;
  int get caloriesProgressPercent => (caloriesProgress * 100).round();

  // Progression pour chaque macro
  double get proteinProgress => currentProtein / targetProtein;
  double get carbsProgress => currentCarbs / targetCarbs;
  double get fatProgress => currentFat / targetFat;

  // Messages dynamiques
  String get progressMessage => '${caloriesProgressPercent}% de l\'objectif atteint';
  
  String get statusMessage {
    if (caloriesProgress >= 0.9) return 'Excellent travail ! 🎉';
    if (caloriesProgress >= 0.7) return 'Bien parti ! 💪';
    if (caloriesProgress >= 0.5) return 'À mi-chemin ! 🚀';
    return 'C\'est parti ! ⭐';
  }

  // Couleur selon le progrès
  Color get progressColor {
    if (caloriesProgress >= 0.9) return const Color(0xFF22C55E);
    if (caloriesProgress >= 0.7) return const Color(0xFF0B132B);
    if (caloriesProgress >= 0.5) return const Color(0xFF1C2951);
    return const Color(0xFF64748B);
  }

  // Water en millilitres
  int get waterMl => (waterLevel * 2000).round(); // 2L = 100%
  String get waterText => '${(waterMl / 1000).toStringAsFixed(1)}L';
}

// Modèle de macronutriment
class MacroNutrient {
  final String name;
  final String unit;
  final int current;
  final int target;
  final Color color;
  final IconData icon;

  const MacroNutrient({
    required this.name,
    required this.unit,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
  });

  // Pourcentage de progression
  double get progress => current / target;
  int get progressPercent => (progress * 100).round();

  // Texte formaté
  String get currentText => '$current$unit';
  String get targetText => '$target$unit';
  String get progressText => '$progressPercent%';

  // Quantité restante
  int get remaining => max(0, target - current);
  String get remainingText => '$remaining$unit restants';

  // Couleur de progression
  Color get progressColor {
    if (progress >= 0.9) return const Color(0xFF22C55E);
    if (progress >= 0.7) return color;
    return color.withOpacity(0.6);
  }
}

// Modèle de repas
class Meal {
  final String id;
  final String name;
  final String shortName;
  final int calories;
  final bool isCompleted;
  final TimeOfDay? time;

  const Meal({
    required this.id,
    required this.name,
    required this.shortName,
    required this.calories,
    required this.isCompleted,
    this.time,
  });

  // Couleur selon l'état
  Color get statusColor {
    return isCompleted 
        ? const Color(0xFF0B132B)
        : const Color(0xFFCCCCCC);
  }

  // Gradient pour l'indicateur
  List<Color> get statusGradient {
    return isCompleted
        ? [const Color(0xFF0B132B), const Color(0xFF1C2951)]
        : [const Color(0xFFCCCCCC), const Color(0xFFCCCCCC)];
  }

  // Texte des calories
  String get caloriesText => isCompleted ? calories.toString() : '—';

  // Icône selon le repas
  IconData get icon {
    switch (id) {
      case 'breakfast': return LucideIcons.sunrise;
      case 'lunch': return LucideIcons.sun;
      case 'snack': return LucideIcons.apple;
      case 'dinner': return LucideIcons.moon;
      default: return LucideIcons.utensils;
    }
  }
}

// Modèle d'action rapide nutrition
class NutritionQuickAction {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const NutritionQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    this.onTap,
  });

  // Couleurs pour l'UI
  List<Color> get colors => [const Color(0xFF0B132B), const Color(0xFF1C2951)];
  Color get backgroundColor => const Color(0xFFF8F8F8);
  Color get textColor => const Color(0xFF888888);
}

// Option d'ajout d'eau
class WaterOption {
  final String label;
  final String amount;
  final IconData icon;
  final int milliliters;

  const WaterOption({
    required this.label,
    required this.amount,
    required this.icon,
    required this.milliliters,
  });
}

// Conseil IA nutritionnel
class NutritionTip {
  final String content;
  final String category;
  final Color accentColor;

  const NutritionTip({
    required this.content,
    required this.category,
    required this.accentColor,
  });

  // Icône selon la catégorie
  IconData get icon {
    switch (category) {
      case 'hydration': return LucideIcons.droplets;
      case 'timing': return LucideIcons.clock;
      case 'balance': return LucideIcons.scale;
      case 'energy': return LucideIcons.zap;
      default: return LucideIcons.lightbulb;
    }
  }
}

// Données statiques de nutrition
class NutritionData {
  // Profil nutrition exemple
  static const NutritionProfile profile = NutritionProfile(
    targetCalories: 2500,
    currentCalories: 1247,
    targetProtein: 150,
    currentProtein: 85,
    targetCarbs: 250,
    currentCarbs: 120,
    targetFat: 80,
    currentFat: 45,
    waterLevel: 0.48,
  );

  // Macronutriments
  static List<MacroNutrient> getMacros(NutritionProfile profile) {
    return [
      MacroNutrient(
        name: 'Protéines',
        unit: 'g',
        current: profile.currentProtein,
        target: profile.targetProtein,
        color: const Color(0xFF0B132B),
        icon: LucideIcons.zap,
      ),
      MacroNutrient(
        name: 'Glucides',
        unit: 'g',
        current: profile.currentCarbs,
        target: profile.targetCarbs,
        color: const Color(0xFF1C2951),
        icon: LucideIcons.wheat,
      ),
      MacroNutrient(
        name: 'Lipides',
        unit: 'g',
        current: profile.currentFat,
        target: profile.targetFat,
        color: const Color(0xFF64748B),
        icon: LucideIcons.droplets,
      ),
    ];
  }

  // Repas de la journée
  static const List<Meal> meals = [
    Meal(
      id: 'breakfast',
      name: 'Petit-déjeuner',
      shortName: 'P.déj',
      calories: 320,
      isCompleted: true,
      time: TimeOfDay(hour: 8, minute: 0),
    ),
    Meal(
      id: 'lunch',
      name: 'Déjeuner',
      shortName: 'Déj',
      calories: 450,
      isCompleted: true,
      time: TimeOfDay(hour: 12, minute: 30),
    ),
    Meal(
      id: 'snack',
      name: 'Collation',
      shortName: 'Coll',
      calories: 180,
      isCompleted: true,
      time: TimeOfDay(hour: 16, minute: 0),
    ),
    Meal(
      id: 'dinner',
      name: 'Dîner',
      shortName: 'Dîner',
      calories: 0,
      isCompleted: false,
      time: TimeOfDay(hour: 20, minute: 0),
    ),
  ];

  // Actions rapides
  static const List<NutritionQuickAction> quickActions = [
    NutritionQuickAction(
      id: 'photo',
      label: 'Photo',
      icon: LucideIcons.camera,
    ),
    NutritionQuickAction(
      id: 'barcode',
      label: 'Code-barres',
      icon: LucideIcons.scan,
    ),
    NutritionQuickAction(
      id: 'search',
      label: 'Rechercher',
      icon: LucideIcons.search,
    ),
  ];

  // Options d'eau
  static const List<WaterOption> waterOptions = [
    WaterOption(
      label: '1 verre',
      amount: '250 ml',
      icon: LucideIcons.wine,
      milliliters: 250,
    ),
    WaterOption(
      label: '1 gourde',
      amount: '500 ml',
      icon: LucideIcons.cupSoda,
      milliliters: 500,
    ),
    WaterOption(
      label: '1 litre',
      amount: '1000 ml',
      icon: LucideIcons.milk,
      milliliters: 1000,
    ),
  ];

  // Conseils IA
  static const List<NutritionTip> tips = [
    NutritionTip(
      content: '💡 Astuce : Buvez un verre d\'eau avant chaque repas pour une meilleure digestion et satiété.',
      category: 'hydration',
      accentColor: Color(0xFF0B132B),
    ),
    NutritionTip(
      content: '⏰ Timing parfait : Consommez vos protéines dans les 30 minutes après l\'entraînement.',
      category: 'timing',
      accentColor: Color(0xFF1C2951),
    ),
    NutritionTip(
      content: '⚖️ Équilibre : Votre ratio protéines/glucides est optimal pour votre objectif.',
      category: 'balance',
      accentColor: Color(0xFF22C55E),
    ),
  ];

  // Statistiques des repas
  static int get completedMeals => meals.where((meal) => meal.isCompleted).length;
  static int get totalMeals => meals.length;
  static String get mealsProgress => '$completedMeals/$totalMeals';
}

// Extension pour la copie du profil nutrition
extension NutritionProfileCopyWith on NutritionProfile {
  NutritionProfile copyWith({
    int? targetCalories,
    int? currentCalories,
    int? targetProtein,
    int? currentProtein,
    int? targetCarbs,
    int? currentCarbs,
    int? targetFat,
    int? currentFat,
    double? waterLevel,
  }) {
    return NutritionProfile(
      targetCalories: targetCalories ?? this.targetCalories,
      currentCalories: currentCalories ?? this.currentCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      currentProtein: currentProtein ?? this.currentProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      currentCarbs: currentCarbs ?? this.currentCarbs,
      targetFat: targetFat ?? this.targetFat,
      currentFat: currentFat ?? this.currentFat,
      waterLevel: waterLevel ?? this.waterLevel,
    );
  }
} 