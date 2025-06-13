import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';

// Modèle de profil sport
class SportProfile {
  final int weeklyCalories;
  final int targetWeeklyCalories;
  final int dailyStreak;
  final int weeklyStreak;
  final int weeklyWorkouts;
  final int targetWeeklyWorkouts;
  final Duration weeklyDuration;

  const SportProfile({
    required this.weeklyCalories,
    required this.targetWeeklyCalories,
    required this.dailyStreak,
    required this.weeklyStreak,
    required this.weeklyWorkouts,
    required this.targetWeeklyWorkouts,
    required this.weeklyDuration,
  });

  // Calories moyennes par jour
  int get avgDailyCalories => (weeklyCalories / 7).round();

  // Progression des calories
  double get caloriesProgress => weeklyCalories / targetWeeklyCalories;
  int get caloriesProgressPercent => (caloriesProgress * 100).round();

  // Calories restantes
  int get remainingCalories => max(0, targetWeeklyCalories - weeklyCalories);

  // Progress des séances
  double get workoutsProgress => weeklyWorkouts / targetWeeklyWorkouts;
  String get workoutsProgressText => '$weeklyWorkouts/$targetWeeklyWorkouts';

  // Formattage du temps
  String get weeklyDurationText {
    final hours = weeklyDuration.inHours;
    final minutes = weeklyDuration.inMinutes % 60;
    return '${hours}h ${minutes}min';
  }

  // Message de status selon le progrès
  String get statusMessage {
    if (caloriesProgress >= 0.9) return 'Objectif presque atteint ! 🔥';
    if (caloriesProgress >= 0.7) return 'Excellent rythme ! 💪';
    if (caloriesProgress >= 0.5) return 'Bien parti ! 🚀';
    return 'C\'est parti ! ⭐';
  }

  // Couleur selon le progrès
  Color get progressColor {
    if (caloriesProgress >= 0.9) return const Color(0xFF22C55E);
    if (caloriesProgress >= 0.7) return const Color(0xFF0B132B);
    return const Color(0xFF1C2951);
  }

  // Streaks formatés
  String get dailyStreakText => '$dailyStreak jours';
  String get weeklyStreakText => '$weeklyStreak semaines consécutives';
}

// Modèle d'activité quotidienne
class DailyActivity {
  final String id;
  final String name;
  final String type; // 'musculation' ou 'cardio'
  final Duration duration;
  final int calories;
  final double progress; // 0.0 à 1.0
  final bool isCompleted;

  const DailyActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.calories,
    required this.progress,
    required this.isCompleted,
  });

  // Couleur selon le type
  Color get typeColor {
    switch (type) {
      case 'musculation':
        return const Color(0xFF0B132B);
      case 'cardio':
        return const Color(0xFF0B132B).withOpacity(0.7);
      default:
        return const Color(0xFF64748B);
    }
  }

  // Couleur de progression
  Color get progressColor => isCompleted ? typeColor : typeColor.withOpacity(0.3);

  // Formattage de la durée
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  // Texte des calories
  String get caloriesText => '$calories kcal';

  // Texte complet
  String get activityText => '$durationText • $caloriesText';

  // Icône selon le type
  IconData get icon {
    switch (type) {
      case 'musculation':
        return LucideIcons.dumbbell;
      case 'cardio':
        return LucideIcons.activity;
      default:
        return LucideIcons.zap;
    }
  }
}

// Modèle d'entraînement récent
class RecentWorkout {
  final String id;
  final String name;
  final String type;
  final DateTime date;
  final Duration duration;
  final int calories;
  final bool isCompleted;

  const RecentWorkout({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.duration,
    required this.calories,
    required this.isCompleted,
  });

  // Formattage de la date
  String get dateText {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    if (diff < 7) return 'Il y a $diff jours';
    return '${date.day}/${date.month}';
  }

  // Couleur selon le type
  Color get typeColor {
    switch (type) {
      case 'musculation':
        return const Color(0xFF0B132B);
      case 'cardio':
        return const Color(0xFF1C2951);
      default:
        return const Color(0xFF64748B);
    }
  }

  // Icône selon le type
  IconData get icon {
    switch (type) {
      case 'musculation':
        return LucideIcons.dumbbell;
      case 'cardio':
        return LucideIcons.activity;
      default:
        return LucideIcons.zap;
    }
  }

  // Durée formatée
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  // Informations combinées
  String get workoutInfo => '$durationText • $calories kcal';
}

// Modèle de jour d'activité (pour le calendrier compact)
class ActivityDay {
  final String dayLabel; // 'L', 'M', 'M', 'J', 'V', 'S', 'D'
  final bool hasWorkout;
  final String? workoutType; // 'musculation', 'cardio', null
  final DateTime date;

  const ActivityDay({
    required this.dayLabel,
    required this.hasWorkout,
    this.workoutType,
    required this.date,
  });

  // Couleur selon l'état
  Color get statusColor {
    if (!hasWorkout) return const Color(0xFFE2E8F0);
    
    switch (workoutType) {
      case 'musculation':
        return const Color(0xFF0B132B);
      case 'cardio':
        return const Color(0xFF1C2951);
      default:
        return const Color(0xFF64748B);
    }
  }

  // Gradient pour l'indicateur
  List<Color> get statusGradient {
    if (!hasWorkout) {
      return [const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)];
    }
    
    switch (workoutType) {
      case 'musculation':
        return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
      case 'cardio':
        return [const Color(0xFF1C2951), const Color(0xFF0B132B)];
      default:
        return [const Color(0xFF64748B), const Color(0xFF64748B)];
    }
  }

  // Icône selon le type
  IconData? get icon {
    if (!hasWorkout) return null;
    
    switch (workoutType) {
      case 'musculation':
        return LucideIcons.dumbbell;
      case 'cardio':
        return LucideIcons.activity;
      default:
        return LucideIcons.zap;
    }
  }
}

// Modèle d'action rapide sport
class SportQuickAction {
  final String id;
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  const SportQuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  // Couleur de fond
  Color get backgroundColor => const Color(0xFFF8F8F8);
  Color get textColor => const Color(0xFF888888);
}

// Modèle de statistique hebdomadaire
class WeeklyStat {
  final String label;
  final String value;
  final IconData? icon;
  final Color accentColor;

  const WeeklyStat({
    required this.label,
    required this.value,
    this.icon,
    required this.accentColor,
  });
}

// Données statiques du sport dashboard
class SportDashboardData {
  // Profil sport exemple
  static const SportProfile profile = SportProfile(
    weeklyCalories: 1260,
    targetWeeklyCalories: 2000,
    dailyStreak: 7,
    weeklyStreak: 3,
    weeklyWorkouts: 4,
    targetWeeklyWorkouts: 5,
    weeklyDuration: Duration(hours: 4, minutes: 35),
  );

  // Activités quotidiennes
  static const List<DailyActivity> dailyActivities = [
    DailyActivity(
      id: 'push_workout',
      name: 'Push (Poitrine)',
      type: 'musculation',
      duration: Duration(hours: 1, minutes: 15),
      calories: 280,
      progress: 1.0,
      isCompleted: true,
    ),
    DailyActivity(
      id: 'cardio_run',
      name: 'Course',
      type: 'cardio',
      duration: Duration(minutes: 20),
      calories: 62,
      progress: 0.75,
      isCompleted: false,
    ),
  ];

  // Entraînements récents
  static final List<RecentWorkout> recentWorkouts = [
    RecentWorkout(
      id: 'workout_1',
      name: 'Push (Poitrine)',
      type: 'musculation',
      date: DateTime.now().subtract(const Duration(days: 1)),
      duration: const Duration(hours: 1, minutes: 15),
      calories: 280,
      isCompleted: true,
    ),
    RecentWorkout(
      id: 'workout_2',
      name: 'Cardio HIIT',
      type: 'cardio',
      date: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(minutes: 25),
      calories: 85,
      isCompleted: true,
    ),
    RecentWorkout(
      id: 'workout_3',
      name: 'Pull (Dos)',
      type: 'musculation',
      date: DateTime.now().subtract(const Duration(days: 3)),
      duration: const Duration(hours: 1, minutes: 20),
      calories: 295,
      isCompleted: true,
    ),
  ];

  // Jours d'activité (7 derniers jours)
  static final List<ActivityDay> activityDays = [
    ActivityDay(
      dayLabel: 'L',
      hasWorkout: true,
      workoutType: 'musculation',
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ActivityDay(
      dayLabel: 'M',
      hasWorkout: false,
      workoutType: null,
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ActivityDay(
      dayLabel: 'M',
      hasWorkout: true,
      workoutType: 'cardio',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ActivityDay(
      dayLabel: 'J',
      hasWorkout: true,
      workoutType: 'musculation',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ActivityDay(
      dayLabel: 'V',
      hasWorkout: false,
      workoutType: null,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ActivityDay(
      dayLabel: 'S',
      hasWorkout: true,
      workoutType: 'cardio',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityDay(
      dayLabel: 'D',
      hasWorkout: false,
      workoutType: null,
      date: DateTime.now(),
    ),
  ];

  // Actions rapides
  static const List<SportQuickAction> quickActions = [
    SportQuickAction(
      id: 'musculation',
      label: 'Musculation',
      icon: LucideIcons.dumbbell,
      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
    SportQuickAction(
      id: 'cardio',
      label: 'Cardio',
      icon: LucideIcons.activity,
      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
    ),
  ];

  // Statistiques hebdomadaires
  static List<WeeklyStat> getWeeklyStats(SportProfile profile) {
    return [
      WeeklyStat(
        label: 'Séances cette semaine',
        value: profile.workoutsProgressText,
        accentColor: const Color(0xFF0B132B),
      ),
      WeeklyStat(
        label: 'Semaines consécutives',
        value: profile.weeklyStreak.toString(),
        icon: LucideIcons.flame,
        accentColor: const Color(0xFF0B132B),
      ),
      WeeklyStat(
        label: 'Temps total cette semaine',
        value: profile.weeklyDurationText,
        accentColor: const Color(0xFF0B132B),
      ),
    ];
  }
}

// Extension pour la copie du profil sport
extension SportProfileCopyWith on SportProfile {
  SportProfile copyWith({
    int? weeklyCalories,
    int? targetWeeklyCalories,
    int? dailyStreak,
    int? weeklyStreak,
    int? weeklyWorkouts,
    int? targetWeeklyWorkouts,
    Duration? weeklyDuration,
  }) {
    return SportProfile(
      weeklyCalories: weeklyCalories ?? this.weeklyCalories,
      targetWeeklyCalories: targetWeeklyCalories ?? this.targetWeeklyCalories,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      weeklyStreak: weeklyStreak ?? this.weeklyStreak,
      weeklyWorkouts: weeklyWorkouts ?? this.weeklyWorkouts,
      targetWeeklyWorkouts: targetWeeklyWorkouts ?? this.targetWeeklyWorkouts,
      weeklyDuration: weeklyDuration ?? this.weeklyDuration,
    );
  }
} 
