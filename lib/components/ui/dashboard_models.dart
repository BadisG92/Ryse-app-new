import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

// Modèle d'utilisateur gamifié
class UserProfile {
  final String name;
  final int streak;
  final int todayScore;
  final int todayXP;
  final bool isPremium;
  final int photosUsed;
  final int dailyCalories;
  final int currentCalories;

  const UserProfile({
    required this.name,
    required this.streak,
    required this.todayScore,
    required this.todayXP,
    required this.isPremium,
    required this.photosUsed,
    required this.dailyCalories,
    required this.currentCalories,
  });

  // Calcul du pourcentage de calories
  double get caloriesProgress => currentCalories / dailyCalories;

  // Formattage du streak
  String get streakText => '$streak jours';

  // Formattage des XP
  String get xpText => '+$todayXP XP aujourd\'hui';

  // Reste de calories
  int get remainingCalories => max(0, dailyCalories - currentCalories);

  // Message de salutation
  String get greetingMessage => 'Salut $name !';
}

// Modèle d'objectif journalier
class DailyGoal {
  final String id;
  final String label;
  final int progress;
  final int xp;
  final bool completed;
  final bool isPremium;

  const DailyGoal({
    required this.id,
    required this.label,
    required this.progress,
    required this.xp,
    required this.completed,
    this.isPremium = false,
  });

  // Progress en pourcentage (0.0 à 1.0)
  double get progressPercent => progress / 100.0;

  // Couleur de la barre de progression
  List<Color> get progressColors {
    if (completed) {
      return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
    } else if (isPremium) {
      return [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];
    } else {
      return [
        const Color(0xFF0B132B).withOpacity(0.8), 
        const Color(0xFF1C2951).withOpacity(0.8)
      ];
    }
  }

  // Badge XP texte
  String get xpBadgeText => '+$xp XP';
}

// Modèle d'action rapide
class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final String? reward;
  final bool isDisabled;
  final bool isPremiumRequired;
  final VoidCallback? onTap;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    this.reward,
    this.isDisabled = false,
    this.isPremiumRequired = false,
    this.onTap,
  });

  // Couleurs selon l'état
  List<Color> get colors {
    if (isDisabled || isPremiumRequired) {
      return [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)];
    }
    return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
  }

  // Couleur du texte
  Color get textColor {
    if (isDisabled || isPremiumRequired) {
      return const Color(0xFF94A3B8);
    }
    return Colors.white;
  }
}

// Modèle de preview de module
class ModulePreview {
  final String title;
  final IconData icon;
  final Map<String, String> stats;
  final List<Color> gradientColors;

  const ModulePreview({
    required this.title,
    required this.icon,
    required this.stats,
    required this.gradientColors,
  });
}

// Modèle de statistiques communautaires
class CommunityStats {
  final int activeUsers;
  final String topChallenge;
  final int completedGoalsToday;

  const CommunityStats({
    required this.activeUsers,
    required this.topChallenge,
    required this.completedGoalsToday,
  });

  // Formattage des utilisateurs actifs
  String get activeUsersText {
    if (activeUsers >= 1000) {
      return '${(activeUsers / 1000).toStringAsFixed(1)}k';
    }
    return activeUsers.toString();
  }
}

// Calculateur métabolique
class MetabolicCalculator {
  // Calcul BMR (Mifflin-St Jeor)
  static double calculateBMR(String gender, int age, double weight, double height) {
    if (gender == 'Homme') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  // Facteurs d'activité
  static const Map<String, double> activityFactors = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'very': 1.725,
    'extra': 1.9,
  };

  // Calcul TDEE
  static double calculateTDEE(double bmr, String activityLevel) {
    return bmr * (activityFactors[activityLevel] ?? 1.2);
  }

  // Calcul objectif journalier selon le but
  static int calculateDailyGoal(
    String gender, 
    int age, 
    double weight, 
    double height, 
    String activity, 
    String goal
  ) {
    final bmr = calculateBMR(gender, age, weight, height);
    final tdee = calculateTDEE(bmr, activity);

    switch (goal) {
      case 'lose':
        return (tdee - 500).round();
      case 'lose_fast':
        return (tdee - 750).round();
      case 'maintain':
        return tdee.round();
      case 'gain':
        return (tdee + 300).round();
      default:
        return tdee.round();
    }
  }
}

// Données statiques du dashboard
class DashboardData {
  // Profil utilisateur exemple
  static const UserProfile userProfile = UserProfile(
    name: 'Rihab',
    streak: 7,
    todayScore: 85,
    todayXP: 250,
    isPremium: false,
    photosUsed: 2,
    dailyCalories: 2500,
    currentCalories: 1247,
  );

  // Objectifs journaliers exemple
  static const List<DailyGoal> dailyGoals = [
    DailyGoal(
      id: 'calories',
      label: 'Atteindre mes calories',
      progress: 75,
      xp: 25,
      completed: false,
    ),
    DailyGoal(
      id: 'water',
      label: 'Boire 2L d\'eau',
      progress: 60,
      xp: 15,
      completed: false,
    ),
    DailyGoal(
      id: 'steps',
      label: '10 000 pas',
      progress: 100,
      xp: 20,
      completed: true,
    ),
    DailyGoal(
      id: 'workout',
      label: 'Séance de sport',
      progress: 100,
      xp: 30,
      completed: true,
    ),
    DailyGoal(
      id: 'meditation',
      label: '10 min de méditation',
      progress: 40,
      xp: 20,
      completed: false,
      isPremium: true,
    ),
  ];

  // Actions rapides selon le profil utilisateur
  static List<QuickAction> getQuickActions(UserProfile profile) {
    return [
      QuickAction(
        id: 'scan_meal',
        label: 'Scanner un repas',
        icon: (!profile.isPremium && profile.photosUsed >= 3) 
            ? LucideIcons.lock 
            : LucideIcons.camera,
        reward: (!profile.isPremium && profile.photosUsed >= 3) ? null : '+5',
        isDisabled: !profile.isPremium && profile.photosUsed >= 3,
        isPremiumRequired: !profile.isPremium && profile.photosUsed >= 3,
      ),
      const QuickAction(
        id: 'add_water',
        label: 'Ajouter de l\'eau',
        icon: LucideIcons.droplets,
        reward: '+2',
      ),
      const QuickAction(
        id: 'log_workout',
        label: 'Séance de sport',
        icon: LucideIcons.dumbbell,
        reward: '+10',
      ),
      const QuickAction(
        id: 'daily_checkin',
        label: 'Check-in quotidien',
        icon: LucideIcons.checkCircle,
        reward: '+5',
      ),
      const QuickAction(
        id: 'body_metrics',
        label: 'Poids & mesures',
        icon: LucideIcons.scale,
        reward: '+3',
      ),
    ];
  }

  // Previews des modules
  static const List<ModulePreview> modulePreviews = [
    ModulePreview(
      title: 'Nutrition',
      icon: LucideIcons.apple,
      stats: {
        'Calories': '1247 kcal',
        'Eau': '1.2L',
      },
      gradientColors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
    ModulePreview(
      title: 'Sport',
      icon: LucideIcons.dumbbell,
      stats: {
        'Calories': '342 kcal',
        'Séances': '1 / 3',
      },
      gradientColors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
  ];

  // Stats communautaires
  static const CommunityStats communityStats = CommunityStats(
    activeUsers: 2847,
    topChallenge: '30 jours sans sucre',
    completedGoalsToday: 1250,
  );

  // Features premium
  static const List<Map<String, String>> premiumFeatures = [
    {'value': '∞', 'label': 'Photos'},
    {'value': '24/7', 'label': 'Coach IA'},
    {'value': '0', 'label': 'Publicités'},
  ];
} 