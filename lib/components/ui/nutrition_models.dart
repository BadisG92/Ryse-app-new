import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import '../../services/translations.dart';

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
  final int currentWaterMl;
  final int targetWaterMl;

  const NutritionProfile({
    required this.targetCalories,
    required this.currentCalories,
    required this.targetProtein,
    required this.currentProtein,
    required this.targetCarbs,
    required this.currentCarbs,
    required this.targetFat,
    required this.currentFat,
    required this.currentWaterMl,
    required this.targetWaterMl,
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

  // Hydratation - calculé dynamiquement
  double get waterLevel => targetWaterMl > 0 ? currentWaterMl / targetWaterMl : 0.0;
  double get waterProgressCapped => waterLevel > 1.0 ? 1.0 : waterLevel; // Pour la barre de progression
  int get waterProgressPercent => (waterLevel * 100).round();

  // Messages dynamiques
  String getProgressMessage([String? languageCode]) {
    final lang = languageCode ?? 'fr';
    return 'percent_of_goal_achieved'.tr(lang).replaceAll('{percent}', caloriesProgressPercent.toString());
  }
  
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

  // Méthode copyWith mise à jour
  NutritionProfile copyWith({
    int? targetCalories,
    int? currentCalories,
    int? targetProtein,
    int? currentProtein,
    int? targetCarbs,
    int? currentCarbs,
    int? targetFat,
    int? currentFat,
    int? currentWaterMl,
    int? targetWaterMl,
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
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      targetWaterMl: targetWaterMl ?? this.targetWaterMl,
    );
  }
}

// Modèle de macronutriment
class MacroNutrient {
  final String id;
  final String name;
  final String unit;
  final int current;
  final int target;
  final Color color;
  final IconData icon;

  const MacroNutrient({
    required this.id,
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

  // Méthode copyWith pour créer une copie modifiée
  Meal copyWith({
    String? id,
    String? name,
    String? shortName,
    int? calories,
    bool? isCompleted,
    TimeOfDay? time,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      calories: calories ?? this.calories,
      isCompleted: isCompleted ?? this.isCompleted,
      time: time ?? this.time,
    );
  }

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
      case 'hydration': return LucideIcons.brain;
      case 'timing': return LucideIcons.clock;
      case 'balance': return LucideIcons.scale;
      case 'energy': return LucideIcons.zap;
      default: return LucideIcons.brain;
    }
  }
}

// Données statiques de nutrition
class NutritionData {
  // Profil nutrition vide - les vraies données viennent de la base
  static const NutritionProfile profile = NutritionProfile(
    targetCalories: 0,
    currentCalories: 0,
    targetProtein: 0,
    currentProtein: 0,
    targetCarbs: 0,
    currentCarbs: 0,
    targetFat: 0,
    currentFat: 0,
    currentWaterMl: 0,
    targetWaterMl: 0,
  );

  // Macronutriments
  static List<MacroNutrient> getMacros(NutritionProfile profile, [String? languageCode]) {
    final lang = languageCode ?? 'fr'; // Default to French
    return [
      MacroNutrient(
        id: 'protein',
        name: 'proteins'.tr(lang),
        unit: 'g',
        current: profile.currentProtein,
        target: profile.targetProtein,
        color: const Color(0xFF0B132B),
        icon: LucideIcons.zap,
      ),
      MacroNutrient(
        id: 'carbs',
        name: 'carbohydrates'.tr(lang),
        unit: 'g',
        current: profile.currentCarbs,
        target: profile.targetCarbs,
        color: const Color(0xFF1C2951),
        icon: LucideIcons.wheat,
      ),
      MacroNutrient(
        id: 'fats',
        name: 'lipids'.tr(lang),
        unit: 'g',
        current: profile.currentFat,
        target: profile.targetFat,
        color: const Color(0xFF64748B),
        icon: LucideIcons.droplets,
      ),
    ];
  }

  // Repas vides - les vraies données viennent de la base
  static const List<Meal> meals = [];

  // Actions rapides
  static const List<NutritionQuickAction> quickActions = [
    NutritionQuickAction(
      id: 'chat',
      label: 'Chat IA',
      icon: LucideIcons.messageCircle,
    ),
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
    NutritionQuickAction(
      id: 'recipe',
      label: 'Recette',
      icon: LucideIcons.chefHat,
    ),
  ];

  // Options d'eau avec traductions
  static List<WaterOption> getWaterOptions([String? languageCode]) {
    final lang = languageCode ?? 'fr';
    return [
      WaterOption(
        label: 'one_glass'.tr(lang),
        amount: '250 ml',
        icon: LucideIcons.wine,
        milliliters: 250,
      ),
      WaterOption(
        label: 'one_bottle'.tr(lang),
        amount: '500 ml',
        icon: LucideIcons.cupSoda,
        milliliters: 500,
      ),
      WaterOption(
        label: 'one_liter'.tr(lang),
        amount: '1000 ml',
        icon: LucideIcons.milk,
        milliliters: 1000,
      ),
    ];
  }

  // Options d'eau constants pour compatibilité (deprecated)
  static const List<WaterOption> waterOptions = [];

  // Conseils IA avec traductions
  static List<NutritionTip> getTips([String? languageCode]) {
    final lang = languageCode ?? 'fr';
    return [
      NutritionTip(
        content: 'ai_tip_hydration'.tr(lang),
        category: 'hydration',
        accentColor: const Color(0xFF0B132B),
      ),
      NutritionTip(
        content: 'ai_tip_timing'.tr(lang),
        category: 'timing',
        accentColor: const Color(0xFF1C2951),
      ),
      NutritionTip(
        content: 'ai_tip_balance'.tr(lang),
        category: 'balance',
        accentColor: const Color(0xFF22C55E),
      ),
    ];
  }

  // Conseils IA constants pour compatibilité (deprecated)
  static const List<NutritionTip> tips = [];

  // Statistiques des repas - calculées dynamiquement depuis les vraies données
  static int get completedMeals => 0;
  static int get totalMeals => 0;
  static String get mealsProgress => '0/0';
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
    int? currentWaterMl,
    int? targetWaterMl,
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
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      targetWaterMl: targetWaterMl ?? this.targetWaterMl,
    );
  }
} 
