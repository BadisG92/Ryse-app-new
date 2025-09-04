import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

// Modèle de progression de poids
class WeightProgress {
  final double currentWeight;
  final double previousWeight;
  final double initialWeight;
  final double targetWeight;
  final List<WeightEntry> entries;

  const WeightProgress({
    required this.currentWeight,
    required this.previousWeight,
    required this.initialWeight,
    required this.targetWeight,
    required this.entries,
  });

  // Changement de poids
  double get weightChange => currentWeight - previousWeight;
  double get totalWeightChange => currentWeight - initialWeight;

  // Progression vers l'objectif
  double get progressToTarget {
    final totalNeeded = (targetWeight - initialWeight).abs();
    final achieved = (currentWeight - initialWeight).abs();
    return totalNeeded > 0 ? achieved / totalNeeded : 0.0;
  }

  // Texte formaté du changement
  String get weightChangeText {
    final change = weightChange;
    final sign = change > 0 ? "+" : "";
    return "${sign}${change.toStringAsFixed(1)} kg ce mois";
  }

  // Couleur selon le changement (vert = perte, rouge = gain)
  Color get changeColor => weightChange < 0 ? Colors.green.shade700 : Colors.red.shade700;
  Color get changeBackgroundColor => weightChange < 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);

  // Données pour le graphique
  List<FlSpot> get chartSpots {
    return entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  // Plage Y pour le graphique
  double get minY => entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1.0;
  double get maxY => entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1.0;

  // Dates pour les axes
  List<String> get chartDates => entries.map((e) => e.formattedDate).toList();
}

// Entrée de poids
class WeightEntry {
  final DateTime date;
  final double weight;

  const WeightEntry({
    required this.date,
    required this.weight,
  });

  String get formattedDate {
    return '${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month];
  }
}

// Modèle de bilan global hebdomadaire
class WeeklyBalance {
  final List<BalanceItem> items;

  const WeeklyBalance({required this.items});

  // Score global (pourcentage de réussite)
  double get globalScore {
    if (items.isEmpty) return 0.0;
    final totalProgress = items.map((item) => item.progress).reduce((a, b) => a + b);
    return totalProgress / items.length;
  }

  // Message motivationnel selon le score
  String get motivationalMessage {
    if (globalScore >= 0.9) return 'Semaine parfaite !';
    if (globalScore >= 0.7) return 'Excellent travail !';
    if (globalScore >= 0.5) return 'Bon rythme !';
    return 'Continue tes efforts !';
  }

  // Couleur selon le score
  Color get scoreColor {
    if (globalScore >= 0.9) return const Color(0xFF22C55E);
    if (globalScore >= 0.7) return const Color(0xFF0B132B);
    return const Color(0xFF1C2951);
  }
}

// Item de bilan (calories, hydratation, etc.)
class BalanceItem {
  final IconData icon;
  final String label;
  final int achieved;
  final int target;
  final String unit;

  const BalanceItem({
    required this.icon,
    required this.label,
    required this.achieved,
    required this.target,
    required this.unit,
  });

  // Progression (0.0 à 1.0)
  double get progress => target > 0 ? achieved / target : 0.0;

  // Texte de valeur affiché
  String get valueText {
    // Cas spécial pour les séances de sport : n'afficher que le nombre achieved
    if (label == 'Séances de sport') {
      return '$achieved $unit';
    }
    return '$achieved / $target $unit';
  }

  // Couleur selon la progression
  Color get statusColor {
    if (progress >= 0.9) return const Color(0xFF22C55E);
    if (progress >= 0.7) return const Color(0xFF0B132B);
    return const Color(0xFF64748B);
  }

  // Indique si l'objectif est atteint
  bool get isCompleted => progress >= 1.0;
}

// Modèle de jour de tracking (nutrition/sport)
class TrackingDay {
  final String dayLabel; // 'L', 'M', etc.
  final DateTime date;
  final TrackingScore nutritionScore;
  final List<String> sportActivities; // ['musculation', 'cardio'] comme dans le calendrier sport

  const TrackingDay({
    required this.dayLabel,
    required this.date,
    required this.nutritionScore,
    this.sportActivities = const [],
  });

  // Détermine si c'est un jour réussi globalement
  bool get isSuccessfulDay => nutritionScore != TrackingScore.missed && sportActivities.isNotEmpty;

  // Couleur principale pour l'affichage
  Color get primaryColor {
    if (nutritionScore == TrackingScore.achieved) return const Color(0xFF0B132B);
    if (nutritionScore == TrackingScore.partial) return const Color(0xFF64748B);
    return const Color(0xFFF1F5F9);
  }

  // Compatibilité avec l'ancien système SportActivity pour ne pas casser le code existant
  SportActivity? get sportActivity {
    if (sportActivities.contains('musculation') && sportActivities.contains('cardio')) {
      return SportActivity.musculation; // Prioriser musculation par défaut
    } else if (sportActivities.contains('musculation')) {
      return SportActivity.musculation;
    } else if (sportActivities.contains('cardio')) {
      return SportActivity.cardio;
    } else {
      return SportActivity.none;
    }
  }

  // Nouveaux getters pour correspondre au calendrier sport
  bool get hasMusculation => sportActivities.contains('musculation');
  bool get hasCardio => sportActivities.contains('cardio');
  bool get hasBothActivities => hasMusculation && hasCardio;
  bool get hasAnyActivity => sportActivities.isNotEmpty;
}

// Score de tracking (nutrition)
enum TrackingScore {
  achieved,  // Objectifs atteints
  partial,   // Partiellement atteint
  missed,    // Manqué
}

// Extension pour les couleurs et icônes du score
extension TrackingScoreExtension on TrackingScore {
  Color get color {
    switch (this) {
      case TrackingScore.achieved:
        return const Color(0xFF0B132B);
      case TrackingScore.partial:
        return const Color(0xFF64748B);
      case TrackingScore.missed:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TrackingScore.achieved:
        return Colors.transparent;
      case TrackingScore.partial:
        return Colors.transparent;
      case TrackingScore.missed:
        return const Color(0xFFF1F5F9);
    }
  }

  List<Color>? get gradient {
    switch (this) {
      case TrackingScore.achieved:
        return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
      case TrackingScore.partial:
        return [const Color(0xFF64748B), const Color(0xFF64748B)];
      case TrackingScore.missed:
        return null;
    }
  }

  bool get hasIcon => this != TrackingScore.missed;
  IconData get icon => LucideIcons.check;
}

// Activité sport pour le tracking
enum SportActivity {
  musculation,
  cardio,
  none,
}

// Extension pour les activités sport
extension SportActivityExtension on SportActivity {
  IconData get icon {
    switch (this) {
      case SportActivity.musculation:
        return LucideIcons.dumbbell;
      case SportActivity.cardio:
        return LucideIcons.activity;
      case SportActivity.none:
        return LucideIcons.x;
    }
  }

  Color get color {
    switch (this) {
      case SportActivity.musculation:
        return const Color(0xFF0B132B);
      case SportActivity.cardio:
        return const Color(0xFF1C2951);
      case SportActivity.none:
        return const Color(0xFFF1F5F9);
    }
  }

  List<Color> get gradient {
    switch (this) {
      case SportActivity.musculation:
        return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
      case SportActivity.cardio:
        return [const Color(0xFF0B132B), const Color(0xFF1C2951)];
      case SportActivity.none:
        return [const Color(0xFFF1F5F9), const Color(0xFFF1F5F9)];
    }
  }

  String get label {
    switch (this) {
      case SportActivity.musculation:
        return 'Musculation';
      case SportActivity.cardio:
        return 'Cardio';
      case SportActivity.none:
        return 'Repos';
    }
  }

  bool get hasIcon => this != SportActivity.none;
}

// Modèle de légende pour le tracking
class TrackingLegend {
  final Color color;
  final IconData? icon;
  final String label;

  const TrackingLegend({
    required this.color,
    this.icon,
    required this.label,
  });
}

// Modèle de recommandation IA
class AIRecommendation {
  final String message;
  final RecommendationType type;
  final int priority; // 1-5, 5 étant le plus important

  const AIRecommendation({
    required this.message,
    required this.type,
    required this.priority,
  });

  // Icône selon le type
  IconData get icon {
    switch (type) {
      case RecommendationType.nutrition:
        return LucideIcons.apple;
      case RecommendationType.sport:
        return LucideIcons.dumbbell;
      case RecommendationType.recovery:
        return LucideIcons.moon;
      case RecommendationType.general:
        return LucideIcons.brain;
    }
  }

  // Couleur selon le type
  Color get color {
    switch (type) {
      case RecommendationType.nutrition:
        return const Color(0xFF22C55E);
      case RecommendationType.sport:
        return const Color(0xFF0B132B);
      case RecommendationType.recovery:
        return const Color(0xFF8B5CF6);
      case RecommendationType.general:
        return const Color(0xFF1C2951);
    }
  }

  // Titre selon le type
  String get title {
    switch (type) {
      case RecommendationType.nutrition:
        return 'Conseil nutrition 🍎';
      case RecommendationType.sport:
        return 'Conseil sport 💪';
      case RecommendationType.recovery:
        return 'Conseil récupération 😴';
      case RecommendationType.general:
        return 'Recommandation intelligente 🧠';
    }
  }
}

// Types de recommandations
enum RecommendationType {
  nutrition,
  sport,
  recovery,
  general,
}

// Modèle des statistiques d'en-tête
class HeaderStats {
  final String dailyStreak;
  final String weeklyObjectives;
  final String currentStatus;

  const HeaderStats({
    required this.dailyStreak,
    required this.weeklyObjectives,
    required this.currentStatus,
  });

  // Items pour l'affichage
  List<HeaderStatItem> get items {
    return [
      HeaderStatItem(
        icon: LucideIcons.flame,
        text: dailyStreak,
        isBold: false,
      ),
      HeaderStatItem(
        icon: LucideIcons.target,
        text: weeklyObjectives,
        isBold: false,
      ),
      HeaderStatItem(
        icon: LucideIcons.target, // Temporaire, sera remplacé par le logo SVG
        text: currentStatus,
        isBold: true,
      ),
    ];
  }
}

// Item de statistique d'en-tête
class HeaderStatItem {
  final IconData icon;
  final String text;
  final bool isBold;

  const HeaderStatItem({
    required this.icon,
    required this.text,
    required this.isBold,
  });
}

// Données statiques pour le global progress
class GlobalProgressData {
  // Progression de poids exemple
  static final WeightProgress weightProgress = WeightProgress(
    currentWeight: 69.7,
    previousWeight: 72.0,
    initialWeight: 75.0,
    targetWeight: 68.0,
    entries: [
      WeightEntry(date: DateTime(2024, 1, 1), weight: 72.0),
      WeightEntry(date: DateTime(2024, 1, 8), weight: 71.2),
      WeightEntry(date: DateTime(2024, 1, 15), weight: 70.5),
      WeightEntry(date: DateTime(2024, 1, 22), weight: 69.8),
      WeightEntry(date: DateTime(2024, 1, 29), weight: 69.7),
    ],
  );

  // Bilan hebdomadaire
  static const WeeklyBalance weeklyBalance = WeeklyBalance(
    items: [
      BalanceItem(
        icon: LucideIcons.flame,
        label: 'Calories cibles atteintes',
        achieved: 5,
        target: 7,
        unit: 'jours',
      ),
      BalanceItem(
        icon: LucideIcons.droplet,
        label: 'Hydratation validée',
        achieved: 5,
        target: 7,
        unit: 'jours',
      ),
      BalanceItem(
        icon: LucideIcons.utensils,
        label: 'Repas enregistrés',
        achieved: 17,
        target: 21,
        unit: 'repas',
      ),
      BalanceItem(
        icon: LucideIcons.dumbbell,
        label: 'Séances de sport',
        achieved: 3,
        target: 4,
        unit: 'prévues',
      ),
    ],
  );

  // Tracking hebdomadaire
  static final List<TrackingDay> weeklyTracking = [
    TrackingDay(
      dayLabel: 'L',
      date: DateTime.now().subtract(const Duration(days: 6)),
      nutritionScore: TrackingScore.achieved,
      sportActivities: ['musculation'],
    ),
    TrackingDay(
      dayLabel: 'M',
      date: DateTime.now().subtract(const Duration(days: 5)),
      nutritionScore: TrackingScore.partial,
      sportActivities: [],
    ),
    TrackingDay(
      dayLabel: 'M',
      date: DateTime.now().subtract(const Duration(days: 4)),
      nutritionScore: TrackingScore.achieved,
      sportActivities: ['cardio'],
    ),
    TrackingDay(
      dayLabel: 'J',
      date: DateTime.now().subtract(const Duration(days: 3)),
      nutritionScore: TrackingScore.achieved,
      sportActivities: [],
    ),
    TrackingDay(
      dayLabel: 'V',
      date: DateTime.now().subtract(const Duration(days: 2)),
      nutritionScore: TrackingScore.partial,
      sportActivities: ['musculation'],
    ),
    TrackingDay(
      dayLabel: 'S',
      date: DateTime.now().subtract(const Duration(days: 1)),
      nutritionScore: TrackingScore.missed,
      sportActivities: ['cardio'],
    ),
    TrackingDay(
      dayLabel: 'D',
      date: DateTime.now(),
      nutritionScore: TrackingScore.missed,
      sportActivities: ['musculation', 'cardio'], // Exemple d'une journée avec les deux
    ),
  ];

  // Statistiques d'en-tête
  static const HeaderStats headerStats = HeaderStats(
    dailyStreak: '7 jours',
    weeklyObjectives: '3/4 objectifs',
    currentStatus: 'Progression',
  );

  // Recommandations IA
  static const List<AIRecommendation> aiRecommendations = [
    AIRecommendation(
      message: "Tu es très régulier, mais ton apport en protéines est trop faible pour soutenir tes objectifs de tonification.",
      type: RecommendationType.nutrition,
      priority: 4,
    ),
    AIRecommendation(
      message: "Ton activité physique est en hausse 📈, continue comme ça pour booster ton métabolisme.",
      type: RecommendationType.sport,
      priority: 3,
    ),
    AIRecommendation(
      message: "Pense à varier tes sources de glucides pour un apport énergétique plus stable.",
      type: RecommendationType.nutrition,
      priority: 2,
    ),
    AIRecommendation(
      message: "N'oublie pas tes jours de repos, ils sont cruciaux pour la récupération et la progression !",
      type: RecommendationType.recovery,
      priority: 5,
    ),
  ];

  // Légendes pour le tracking
  static final List<TrackingLegend> nutritionLegends = [
    const TrackingLegend(
      color: Color(0xFF0B132B),
      label: 'Atteint',
    ),
    const TrackingLegend(
      color: Color(0xFF64748B),
      label: 'Partiel',
    ),
    const TrackingLegend(
      color: Color(0xFFE5E7EB),
      label: 'Manqué',
    ),
  ];

  static final List<TrackingLegend> sportLegends = [
    const TrackingLegend(
      color: Color(0xFF0B132B),
      icon: LucideIcons.dumbbell,
      label: 'Musculation',
    ),
    const TrackingLegend(
      color: Color(0xFF0B132B), // Même couleur de base que le gradient cardio
      icon: LucideIcons.activity,
      label: 'Cardio',
    ),
    const TrackingLegend(
      color: Color(0xFFE5E7EB),
      label: 'Repos',
    ),
  ];
} 
