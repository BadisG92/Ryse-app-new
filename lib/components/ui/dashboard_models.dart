import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import '../../services/translations.dart';

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
  String streakText(String languageCode) => '$streak ${'days'.tr(languageCode)}';

  // Formattage des XP
  String xpText(String languageCode) => '+$todayXP XP ${'today'.tr(languageCode)}';

  // Reste de calories
  int get remainingCalories => max(0, dailyCalories - currentCalories);

  // Message de salutation engageant basé sur l'heure et le contexte
  String greetingMessage(String languageCode) {
    final hour = DateTime.now().hour;
    final isFrench = languageCode == 'fr';

    // Selon l'heure de la journée
    if (hour >= 5 && hour < 12) {
      // Matin
      return isFrench ? 'Bon retour $name !' : 'Welcome back $name!';
    } else if (hour >= 12 && hour < 18) {
      // Après-midi
      if (streak >= 7) {
        return isFrench ? 'Content de te revoir $name !' : 'Great to see you $name!';
      }
      return isFrench ? 'Salut $name !' : 'Hey $name!';
    } else if (hour >= 18 && hour < 22) {
      // Soirée
      return isFrench ? 'Bonsoir $name !' : 'Good evening $name!';
    } else {
      // Nuit
      return isFrench ? 'Bonsoir $name !' : 'Hey $name!';
    }
  }

  // Message contextuel CTA basé sur l'heure et l'état de l'utilisateur
  String contextualMessage(String languageCode) {
    final hour = DateTime.now().hour;
    final isFrench = languageCode == 'fr';
    final caloriesProgress = currentCalories / dailyCalories;
    final hasStartedDay = currentCalories > 0;

    // Note: mealsCount et sportSessions ne sont pas disponibles dans UserProfile
    // On utilise les données disponibles (calories, score) pour approximer

    // Si l'utilisateur a bien progressé aujourd'hui (≥ 70%)
    if (todayScore >= 70) {
      return isFrench
        ? 'Objectif presque atteint ! Finis ta journée en beauté.'
        : 'Almost there! Finish your day strong.';
    }

    // Messages selon l'heure et le contexte
    if (hour >= 5 && hour < 9) {
      // Matin (5h - 9h)
      if (!hasStartedDay) {
        return isFrench
          ? 'Enregistre ton petit-déjeuner pour bien démarrer.'
          : 'Log your breakfast to start strong.';
      } else {
        return isFrench
          ? 'Bon début ! N\'oublie pas de boire de l\'eau.'
          : 'Great start! Don\'t forget to hydrate.';
      }
    } else if (hour >= 9 && hour < 12) {
      // Milieu de matinée (9h - 12h)
      if (caloriesProgress < 0.1) {
        return isFrench
          ? 'Ajoute ton petit-déjeuner dans le journal.'
          : 'Add your breakfast to your journal.';
      } else {
        return isFrench
          ? 'Continue comme ça ! Prêt pour une séance de sport ?'
          : 'Keep it up! Ready for a workout?';
      }
    } else if (hour >= 12 && hour < 14) {
      // Midi (12h - 14h)
      if (caloriesProgress < 0.3) {
        return 'scan_lunch_with_coach'.tr(isFrench ? 'fr' : 'en');
      } else {
        return isFrench
          ? 'Déjeuner enregistré ! Pense à t\'hydrater.'
          : 'Lunch logged! Remember to drink water.';
      }
    } else if (hour >= 14 && hour < 18) {
      // Après-midi (14h - 18h)
      if (todayScore < 25) {
        // Pas de sport fait (approximation)
        return isFrench
          ? 'Besoin d\'énergie ? Lance une séance de sport.'
          : 'Need energy? Start a workout session.';
      } else {
        final remaining = dailyCalories - currentCalories;
        return isFrench
          ? 'Il te reste ${remaining} kcal à tracker.'
          : '${remaining} kcal left to track.';
      }
    } else if (hour >= 18 && hour < 21) {
      // Soirée (18h - 21h)
      if (caloriesProgress < 0.7) {
        return isFrench
          ? 'Dîner au programme ? Enregistre-le maintenant.'
          : 'Dinner planned? Log it now.';
      } else {
        return isFrench
          ? 'Tous tes repas tracés ! Vérifie ton bilan du jour.'
          : 'All meals logged! Check your daily summary.';
      }
    } else {
      // Nuit (21h - 5h)
      if (todayScore < 50) {
        return isFrench
          ? 'Demain est un nouveau jour ! Prépare ton planning.'
          : 'Tomorrow is a fresh start! Plan ahead.';
      } else {
        return isFrench
          ? 'Bonne journée ! Prends du repos, tu l\'as mérité.'
          : 'Great day! Rest well, you earned it.';
      }
    }
  }

  // Méthode copyWith pour créer une copie modifiée
  UserProfile copyWith({
    String? name,
    int? streak,
    int? todayScore,
    int? todayXP,
    bool? isPremium,
    int? photosUsed,
    int? dailyCalories,
    int? currentCalories,
  }) {
    return UserProfile(
      name: name ?? this.name,
      streak: streak ?? this.streak,
      todayScore: todayScore ?? this.todayScore,
      todayXP: todayXP ?? this.todayXP,
      isPremium: isPremium ?? this.isPremium,
      photosUsed: photosUsed ?? this.photosUsed,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      currentCalories: currentCalories ?? this.currentCalories,
    );
  }
}

// Modèle d'objectif journalier
class DailyGoal {
  final String id;
  final String label;
  final int progress;
  final int xp;
  final bool completed;
  final bool isPremium;
  final double? currentValue;
  final double? targetValue;
  final String? unit;

  const DailyGoal({
    required this.id,
    required this.label,
    required this.progress,
    required this.xp,
    required this.completed,
    this.isPremium = false,
    this.currentValue,
    this.targetValue,
    this.unit,
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

  // Texte de progression formaté (X/Y ou X%)
  String get progressText {
    if (currentValue != null && targetValue != null) {
      if (unit != null && unit!.isNotEmpty) {
        if (unit == 'L') {
          return '${currentValue!.toStringAsFixed(1)}${unit!}/${targetValue!.toStringAsFixed(0)}${unit!}';
        } else {
          return '${currentValue!.toInt()}/${targetValue!.toInt()} ${unit!}';
        }
      } else {
        return '${currentValue!.toInt()}/${targetValue!.toInt()}';
      }
    }
    return '$progress%';
  }

  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      id: map['id']?.toString() ?? 'unknown',
      label: map['label'] ?? 'Objectif',
      progress: (map['progress'] ?? 0) is double
          ? (map['progress'] as double).round()
          : (map['progress'] ?? 0),
      xp: map['xp'] ?? 0,
      completed: map['completed'] ?? false,
      isPremium: map['isPremium'] ?? false,
      currentValue: (map['currentValue'] as num?)?.toDouble(),
      targetValue: (map['targetValue'] as num?)?.toDouble(),
      unit: map['unit'],
    );
  }
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

  // Facteurs d'activité - synchronisé avec le frontend
  static const Map<String, double> activityFactors = {
    'low': 1.2,        // Peu actif (0-2 jours par semaine)
    'moderate': 1.55,   // Modérément actif (3-5 jours par semaine)
    'high': 1.8,       // Très actif (6+ jours par semaine)
  };

  // Calcul TDEE
  static double calculateTDEE(double bmr, String activityLevel) {
    return bmr * (activityFactors[activityLevel] ?? activityFactors['low']!);
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
    currentCalories: 0,
  );

  // Objectifs journaliers exemple
  static const List<DailyGoal> dailyGoals = [
    DailyGoal(
      id: 'meals',
      label: 'Suivre mes repas aujourd\'hui',
      progress: 0, // No meals
      xp: 25,
      completed: false,
      currentValue: 0,
      targetValue: 0,
      unit: '',
    ),
    DailyGoal(
      id: 'water',
      label: 'Boire 2L d\'eau',
      progress: 0, // 0L/0L
      xp: 15,
      completed: false,
      currentValue: 0.0,
      targetValue: 0.0,
      unit: 'L',
    ),
    DailyGoal(
      id: 'calories',
      label: 'Atteindre mes calories',
      progress: 0, // 0/0 kcal
      xp: 25,
      completed: false,
      currentValue: 0,
      targetValue: 0,
      unit: 'kcal',
    ),
    DailyGoal(
      id: 'workout',
      label: 'Faire une séance aujourd\'hui',
      progress: 0, // 0/0 séance
      xp: 30,
      completed: false,
      currentValue: 0,
      targetValue: 0,
      unit: '',
    ),
  ];

  // Actions rapides selon le profil utilisateur (version complète - conservée pour compatibilité)
  static List<QuickAction> getQuickActions(UserProfile profile, String languageCode) {
    return [
      QuickAction(
        id: 'add_meal',
        label: 'add_meal'.tr(languageCode),
        icon: LucideIcons.utensils,
      ),
      QuickAction(
        id: 'add_water',
        label: 'add_water'.tr(languageCode),
        icon: LucideIcons.droplets,
      ),
      QuickAction(
        id: 'ai_chat',
        label: 'ai_chat'.tr(languageCode),
        icon: LucideIcons.messageCircle,
      ),
      QuickAction(
        id: 'take_photo',
        label: 'take_photo'.tr(languageCode),
        icon: (!profile.isPremium && profile.photosUsed >= 3) 
            ? LucideIcons.lock 
            : LucideIcons.camera,
        isDisabled: !profile.isPremium && profile.photosUsed >= 3,
        isPremiumRequired: !profile.isPremium && profile.photosUsed >= 3,
      ),
      QuickAction(
        id: 'cardio',
        label: 'cardio'.tr(languageCode),
        icon: LucideIcons.activity,
      ),
      QuickAction(
        id: 'musculation',
        label: 'musculation'.tr(languageCode),
        icon: LucideIcons.dumbbell,
      ),
      QuickAction(
        id: 'weight_tracking',
        label: 'weight_tracking'.tr(languageCode),
        icon: LucideIcons.scale,
      ),
    ];
  }

  // Actions essentielles pour le nouveau dashboard (5 actions)
  static List<QuickAction> getEssentialActions(UserProfile profile, String languageCode) {
    return [
      QuickAction(
        id: 'add_meal',
        label: 'meals'.tr(languageCode),
        icon: LucideIcons.utensils,
      ),
      QuickAction(
        id: 'take_photo',
        label: 'scan_food'.tr(languageCode),
        icon: (!profile.isPremium && profile.photosUsed >= 3)
            ? LucideIcons.lock
            : LucideIcons.camera,
        isDisabled: !profile.isPremium && profile.photosUsed >= 3,
        isPremiumRequired: !profile.isPremium && profile.photosUsed >= 3,
      ),
      QuickAction(
        id: 'ai_chat',
        label: 'ai_chat'.tr(languageCode),
        icon: LucideIcons.messageCircle,
      ),
      QuickAction(
        id: 'add_water',
        label: 'hydration'.tr(languageCode),
        icon: LucideIcons.droplets,
      ),
      QuickAction(
        id: 'workout',
        label: 'start_workout'.tr(languageCode),
        icon: LucideIcons.dumbbell,
      ),
    ];
  }

  // Actions gamifiées avec pesée (6 actions)
  static List<QuickAction> getGamifiedActions(UserProfile profile, String languageCode) {
    return [
      QuickAction(
        id: 'add_meal',
        label: 'meals'.tr(languageCode),
        icon: LucideIcons.utensils,
      ),
      QuickAction(
        id: 'take_photo',
        label: 'scan_food'.tr(languageCode),
        icon: LucideIcons.camera,
        // Plus de limite Premium - fonctionnalité incluse de base
      ),
      QuickAction(
        id: 'ai_chat',
        label: 'ai_chat'.tr(languageCode),
        icon: LucideIcons.messageCircle,
      ),
      QuickAction(
        id: 'add_water',
        label: 'water'.tr(languageCode),
        icon: LucideIcons.droplets,
      ),
      QuickAction(
        id: 'workout',
        label: 'sport'.tr(languageCode),
        icon: LucideIcons.dumbbell,
      ),
      QuickAction(
        id: 'weight_tracking',
        label: 'weighing'.tr(languageCode),
        icon: LucideIcons.scale,
      ),
    ];
  }

  // Actions originales avec pesée pour le dashboard hybrid
  static List<QuickAction> getOriginalActionsWithWeight(UserProfile profile, String languageCode) {
    return [
      // 1. Prendre une photo
      QuickAction(
        id: 'take_photo',
        label: 'take_photo'.tr(languageCode),
        icon: (!profile.isPremium && profile.photosUsed >= 3)
            ? LucideIcons.lock
            : LucideIcons.camera,
        isDisabled: !profile.isPremium && profile.photosUsed >= 3,
        isPremiumRequired: !profile.isPremium && profile.photosUsed >= 3,
      ),
      // 2. AI Chat
      QuickAction(
        id: 'ai_chat',
        label: 'ai_chat'.tr(languageCode),
        icon: LucideIcons.messageCircle,
      ),
      // 3. Entraînement
      QuickAction(
        id: 'workout',
        label: 'start_workout'.tr(languageCode),
        icon: LucideIcons.dumbbell,
      ),
      // 4. Boire
      QuickAction(
        id: 'add_water',
        label: 'add_water'.tr(languageCode),
        icon: LucideIcons.droplets,
      ),
      // 5. Ajouter aliment
      QuickAction(
        id: 'add_meal',
        label: 'add_meal'.tr(languageCode),
        icon: LucideIcons.utensils,
      ),
    ];
  }

  // Previews des modules
  static List<ModulePreview> getModulePreviews(String languageCode) {
    return [
      ModulePreview(
        title: 'nutrition'.tr(languageCode),
        icon: LucideIcons.apple,
        stats: {
          'calories'.tr(languageCode): '0 kcal',
          'water'.tr(languageCode): '0L',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      ),
      ModulePreview(
        title: 'sport'.tr(languageCode),
        icon: LucideIcons.dumbbell,
        stats: {
          'calories'.tr(languageCode): '0 kcal',
          'sessions'.tr(languageCode): '0 / 0',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      ),
    ];
  }
  
  // Legacy constant for compatibility (will be removed)
  static const List<ModulePreview> modulePreviews = [
    ModulePreview(
      title: 'Nutrition',
      icon: LucideIcons.apple,
      stats: {
        'Calories': '0 kcal',
        'Eau': '0L',
      },
      gradientColors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
    ModulePreview(
      title: 'Sport',
      icon: LucideIcons.dumbbell,
      stats: {
        'Calories': '0 kcal',
        'Séances': '0 / 0',
      },
      gradientColors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
  ];

  // Stats communautaires
  static CommunityStats getCommunityStats(String languageCode) {
    return CommunityStats(
      activeUsers: 2847,
      topChallenge: 'sugar_free_challenge'.tr(languageCode),
      completedGoalsToday: 1250,
    );
  }
  
  // Legacy constant for compatibility (will be removed)
  static const CommunityStats communityStats = CommunityStats(
    activeUsers: 2847,
    topChallenge: '30 jours sans sucre',
    completedGoalsToday: 1250,
  );

  // Features premium
  static List<Map<String, String>> getPremiumFeatures(String languageCode) {
    return [
      {'value': '∞', 'label': 'photos'.tr(languageCode)},
      {'value': '24/7', 'label': 'ai_coach'.tr(languageCode)},
      {'value': '0', 'label': 'advertisements'.tr(languageCode)},
    ];
  }
  
  // Legacy constant for compatibility (will be removed)
  static const List<Map<String, String>> premiumFeatures = [
    {'value': '∞', 'label': 'Photos'},
    {'value': '24/7', 'label': 'Coach IA'},
    {'value': '0', 'label': 'Publicités'},
  ];
} 
