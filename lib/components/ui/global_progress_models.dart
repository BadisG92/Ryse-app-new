import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';

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
    return "${sign}${change.toStringAsFixed(1)} ${'kg'.tr(LocalizationService.instance.currentLanguageCode)} ${'this_month_short'.tr(LocalizationService.instance.currentLanguageCode)}";
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

  // Plage Y pour le graphique avec marge de 5%
  double get minY {
    final weights = entries.map((e) => e.weight).toList();
    weights.add(targetWeight); // Toujours inclure le target weight
    
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final margin = range * 0.05; // Marge de 5%
    
    return minWeight - (margin + 1.0); // +1.0 pour une marge minimum
  }
  
  double get maxY {
    final weights = entries.map((e) => e.weight).toList();
    weights.add(targetWeight); // Toujours inclure le target weight
    
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final margin = range * 0.05; // Marge de 5%
    
    return maxWeight + (margin + 1.0); // +1.0 pour une marge minimum
  }

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
    const months = ['', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 
                   'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return months[month].tr(LocalizationService.instance.currentLanguageCode);
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
    // Retourner une chaîne vide pour ne pas afficher de sous-titre
    return '';
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
    if (label == 'sport_sessions'.tr(LocalizationService.instance.currentLanguageCode)) {
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
        return 'weightlifting'.tr(LocalizationService.instance.currentLanguageCode);
      case SportActivity.cardio:
        return 'cardio'.tr(LocalizationService.instance.currentLanguageCode);
      case SportActivity.none:
        return 'rest'.tr(LocalizationService.instance.currentLanguageCode);
    }
  }

  bool get hasIcon => this != SportActivity.none;
}

// Modèle de légende pour le tracking
class TrackingLegend {
  final Color color;
  final List<Color>? gradientColors;
  final IconData? icon;
  final String label;

  const TrackingLegend({
    required this.color,
    this.gradientColors,
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
        return 'nutrition_advice'.tr(LocalizationService.instance.currentLanguageCode);
      case RecommendationType.sport:
        return 'sport_advice'.tr(LocalizationService.instance.currentLanguageCode);
      case RecommendationType.recovery:
        return 'recovery_advice'.tr(LocalizationService.instance.currentLanguageCode);
      case RecommendationType.general:
        return 'smart_recommendation'.tr(LocalizationService.instance.currentLanguageCode);
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

// Données statiques pour le global progress (garde seulement les données non-poids)
class GlobalProgressData {

  // Bilan hebdomadaire
  static WeeklyBalance get weeklyBalance => WeeklyBalance(
    items: [
      BalanceItem(
        icon: LucideIcons.flame,
        label: 'calorie_target_reached'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 5,
        target: 7,
        unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
      ),
      BalanceItem(
        icon: LucideIcons.droplet,
        label: 'hydration_validated'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 5,
        target: 7,
        unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
      ),
      // MASQUÉ - Repas enregistrés (conservé pour réactivation future)
      // BalanceItem(
      //   icon: LucideIcons.utensils,
      //   label: 'meals_recorded'.tr(LocalizationService.instance.currentLanguageCode),
      //   achieved: 17,
      //   target: 21,
      //   unit: 'meals'.tr(LocalizationService.instance.currentLanguageCode),
      // ),
      BalanceItem(
        icon: LucideIcons.dumbbell,
        label: 'sport_sessions'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 3,
        target: 4,
        unit: 'sessions'.tr(LocalizationService.instance.currentLanguageCode),
      ),
    ],
  );

  // Helper function to get day label by weekday
  static String _getDayLabel(int weekday) {
    const translationKeys = ['day_l', 'day_m', 'day_m2', 'day_j', 'day_v', 'day_s', 'day_d'];
    return translationKeys[weekday - 1].tr(LocalizationService.instance.currentLanguageCode);
  }

  // Tracking hebdomadaire
  static List<TrackingDay> get weeklyTracking {
    final now = DateTime.now();
    return [
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 6))).weekday),
        date: now.subtract(const Duration(days: 6)),
        nutritionScore: TrackingScore.achieved,
        sportActivities: ['musculation'],
      ),
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 5))).weekday),
        date: now.subtract(const Duration(days: 5)),
        nutritionScore: TrackingScore.partial,
        sportActivities: [],
      ),
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 4))).weekday),
        date: now.subtract(const Duration(days: 4)),
        nutritionScore: TrackingScore.achieved,
        sportActivities: ['cardio'],
      ),
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 3))).weekday),
        date: now.subtract(const Duration(days: 3)),
        nutritionScore: TrackingScore.achieved,
        sportActivities: [],
      ),
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 2))).weekday),
        date: now.subtract(const Duration(days: 2)),
        nutritionScore: TrackingScore.partial,
        sportActivities: ['musculation'],
      ),
      TrackingDay(
        dayLabel: _getDayLabel((now.subtract(const Duration(days: 1))).weekday),
        date: now.subtract(const Duration(days: 1)),
        nutritionScore: TrackingScore.missed,
        sportActivities: ['cardio'],
      ),
      TrackingDay(
        dayLabel: _getDayLabel(now.weekday),
        date: now,
        nutritionScore: TrackingScore.missed,
        sportActivities: ['musculation', 'cardio'], // Exemple d'une journée avec les deux
      ),
    ];
  }

  // Statistiques d'en-tête
  static HeaderStats get headerStats => HeaderStats(
    dailyStreak: '7 ${'days'.tr(LocalizationService.instance.currentLanguageCode)}',
    weeklyObjectives: '2/3 ${'objectives'.tr(LocalizationService.instance.currentLanguageCode)}',
    currentStatus: 'progression'.tr(LocalizationService.instance.currentLanguageCode),
  );

  // Recommandations IA
  static List<AIRecommendation> get aiRecommendations => [
    AIRecommendation(
      message: 'increase_protein_intake'.tr(LocalizationService.instance.currentLanguageCode),
      type: RecommendationType.nutrition,
      priority: 4,
    ),
    AIRecommendation(
      message: 'excellent_rhythm_continue'.tr(LocalizationService.instance.currentLanguageCode),
      type: RecommendationType.sport,
      priority: 3,
    ),
    AIRecommendation(
      message: 'distribute_meals_advice'.tr(LocalizationService.instance.currentLanguageCode),
      type: RecommendationType.nutrition,
      priority: 2,
    ),
    AIRecommendation(
      message: 'sleep_recovery_importance'.tr(LocalizationService.instance.currentLanguageCode),
      type: RecommendationType.recovery,
      priority: 5,
    ),
  ];

  // Légendes pour le tracking
  static List<TrackingLegend> get nutritionLegends => [
    TrackingLegend(
      color: const Color(0xFF0B132B),
      label: 'achieved'.tr(LocalizationService.instance.currentLanguageCode),
    ),
    TrackingLegend(
      color: const Color(0xFF64748B),
      label: 'partial'.tr(LocalizationService.instance.currentLanguageCode),
    ),
    TrackingLegend(
      color: const Color(0xFFE5E7EB),
      label: 'missed'.tr(LocalizationService.instance.currentLanguageCode),
    ),
  ];

  static List<TrackingLegend> get sportLegends => [
    TrackingLegend(
      color: const Color(0xFF0B132B),
      icon: LucideIcons.dumbbell,
      label: 'weightlifting'.tr(LocalizationService.instance.currentLanguageCode),
    ),
    TrackingLegend(
      color: const Color(0xFF1C2951), // Couleur cardio du dashboard sport
      gradientColors: [
        const Color(0xFF0B132B).withOpacity(0.7),
        const Color(0xFF1C2951).withOpacity(0.7),
      ],
      icon: LucideIcons.activity,
      label: 'cardio'.tr(LocalizationService.instance.currentLanguageCode),
    ),
    TrackingLegend(
      color: const Color(0xFFE5E7EB),
      label: 'rest'.tr(LocalizationService.instance.currentLanguageCode),
    ),
  ];
} 
