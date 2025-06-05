import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Modèle de session cardio
class CardioSession {
  final String id;
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final DateTime date;
  final Duration duration;
  final double? distance; // en km
  final int calories;
  final double? pace; // en min/km
  final Map<String, dynamic>? additionalData;

  const CardioSession({
    required this.id,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.date,
    required this.duration,
    this.distance,
    required this.calories,
    this.pace,
    this.additionalData,
  });

  // Formatte la durée en texte
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes} min';
    }
  }

  // Formatte la distance en texte
  String get distanceText {
    if (distance == null) return '';
    return '${distance!.toStringAsFixed(1)} km';
  }

  // Formatte l'allure en texte
  String get paceText {
    if (pace == null) return '';
    final minutes = pace!.floor();
    final seconds = ((pace! - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')} /km';
  }

  // Formatte les calories en texte
  String get caloriesText => '$calories kcal';

  // Calcule le temps écoulé depuis la session
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    }
  }

  // Obtient l'icône selon le type d'activité
  IconData get activityIcon {
    switch (activityType) {
      case 'running':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'walking':
        return LucideIcons.footprints;
      case 'hiit':
        return LucideIcons.flame;
      default:
        return LucideIcons.activity;
    }
  }
}

// Modèle de statistiques hebdomadaires
class WeeklyCardioStats {
  final double totalDistance; // en km
  final Duration totalDuration;
  final int totalCalories;

  const WeeklyCardioStats({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
  });

  // Formatte la distance avec gestion intelligente
  String get distanceText {
    if (totalDistance >= 100) {
      return '${totalDistance.round()} km';
    } else {
      return '${totalDistance.toStringAsFixed(1)} km';
    }
  }

  // Formatte la durée
  String get durationText {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes} min';
    }
  }

  // Formatte les calories
  String get caloriesText => totalCalories.toString();
}

// Format d'activité cardio
class ActivityFormat {
  final IconData icon;
  final String title;
  final String description;
  final bool trackable;
  final bool configurable;
  final String? configType;

  const ActivityFormat({
    required this.icon,
    required this.title,
    required this.description,
    required this.trackable,
    required this.configurable,
    this.configType,
  });

  factory ActivityFormat.fromMap(Map<String, dynamic> map) {
    return ActivityFormat(
      icon: map['icon'] as IconData,
      title: map['title'] as String,
      description: map['description'] as String,
      trackable: map['trackable'] as bool,
      configurable: map['configurable'] as bool,
      configType: map['configType'] as String?,
    );
  }
}

// Type d'activité cardio
class ActivityType {
  final String id;
  final String title;
  final IconData icon;
  final List<ActivityFormat> formats;

  const ActivityType({
    required this.id,
    required this.title,
    required this.icon,
    required this.formats,
  });
}

// Configuration d'activité
class ActivityConfig {
  final String type; // 'distance', 'duration', 'hiit'
  final String title;
  final String hint;
  final String unit;

  const ActivityConfig({
    required this.type,
    required this.title,
    required this.hint,
    required this.unit,
  });
}

// Données statiques pour les activités cardio
class CardioData {
  // Statistiques de la semaine example
  static const WeeklyCardioStats weeklyStats = WeeklyCardioStats(
    totalDistance: 90.5,
    totalDuration: Duration(hours: 10, minutes: 40),
    totalCalories: 1860,
  );

  // Dernière session example
  static final CardioSession lastSession = CardioSession(
    id: '1',
    activityType: 'running',
    activityTitle: 'Course à pied',
    formatTitle: 'Course libre',
    date: DateTime.now().subtract(const Duration(days: 2)),
    duration: const Duration(minutes: 28),
    distance: 5.2,
    calories: 312,
    pace: 5.38, // 5:23 /km
  );

  // Sessions de la semaine example
  static final List<CardioSession> weekSessions = [
    CardioSession(
      id: '1',
      activityType: 'running',
      activityTitle: 'Course à pied',
      formatTitle: 'Fractionné',
      date: DateTime.now().subtract(const Duration(days: 1)),
      duration: const Duration(minutes: 25),
      distance: 4.8,
      calories: 280,
    ),
    CardioSession(
      id: '2',
      activityType: 'bike',
      activityTitle: 'Vélo',
      formatTitle: 'Sortie libre',
      date: DateTime.now().subtract(const Duration(days: 3)),
      duration: const Duration(hours: 1, minutes: 15),
      distance: 28.5,
      calories: 420,
    ),
    CardioSession(
      id: '3',
      activityType: 'walking',
      activityTitle: 'Marche',
      formatTitle: 'Marche rapide',
      date: DateTime.now().subtract(const Duration(days: 5)),
      duration: const Duration(minutes: 45),
      distance: 5.2,
      calories: 180,
    ),
  ];

  // Types d'activités et leurs formats
  static final Map<String, List<ActivityFormat>> activityFormats = {
    'running': [
      const ActivityFormat(
        icon: LucideIcons.activity,
        title: 'Course libre',
        description: 'Séance libre sans contrainte',
        trackable: true,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.target,
        title: 'Objectif distance',
        description: 'Atteindre une distance que tu définis',
        trackable: true,
        configurable: true,
        configType: 'distance',
      ),
      const ActivityFormat(
        icon: LucideIcons.clock,
        title: 'Objectif durée',
        description: 'Courir pendant une durée que tu choisis',
        trackable: true,
        configurable: true,
        configType: 'duration',
      ),
      const ActivityFormat(
        icon: LucideIcons.zap,
        title: 'Fractionné débutant',
        description: '4x 1min rapide / 2min récup',
        trackable: true,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.flame,
        title: 'Fractionné avancé',
        description: '6x 2min rapide / 1min récup',
        trackable: true,
        configurable: false,
      ),
    ],
    'bike': [
      const ActivityFormat(
        icon: LucideIcons.bike,
        title: 'Vélo libre',
        description: 'Sortie vélo libre',
        trackable: true,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.target,
        title: 'Objectif distance',
        description: 'Distance à atteindre que tu définis',
        trackable: true,
        configurable: true,
        configType: 'distance',
      ),
      const ActivityFormat(
        icon: LucideIcons.clock,
        title: 'Objectif durée',
        description: 'Durée que tu choisis',
        trackable: true,
        configurable: true,
        configType: 'duration',
      ),
      const ActivityFormat(
        icon: LucideIcons.mountain,
        title: 'Côtes',
        description: 'Entraînement en dénivelé',
        trackable: true,
        configurable: false,
      ),
    ],
    'walking': [
      const ActivityFormat(
        icon: LucideIcons.footprints,
        title: 'Marche libre',
        description: 'Promenade libre',
        trackable: true,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.target,
        title: 'Objectif distance',
        description: 'Distance à parcourir que tu définis',
        trackable: true,
        configurable: true,
        configType: 'distance',
      ),
      const ActivityFormat(
        icon: LucideIcons.clock,
        title: 'Objectif durée',
        description: 'Durée que tu choisis',
        trackable: true,
        configurable: true,
        configType: 'duration',
      ),
      const ActivityFormat(
        icon: LucideIcons.trendingUp,
        title: 'Marche rapide',
        description: 'Allure soutenue',
        trackable: true,
        configurable: false,
      ),
    ],
    'hiit': [
      const ActivityFormat(
        icon: LucideIcons.flame,
        title: 'HIIT débutant',
        description: '15 min - 30s effort / 30s repos',
        trackable: false,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.zap,
        title: 'HIIT intense',
        description: '20 min - 45s effort / 15s repos',
        trackable: false,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.target,
        title: 'Tabata',
        description: '4 min - 20s effort / 10s repos',
        trackable: false,
        configurable: false,
      ),
      const ActivityFormat(
        icon: LucideIcons.timer,
        title: 'HIIT personnalisé',
        description: 'Créer son propre timing',
        trackable: false,
        configurable: true,
        configType: 'hiit',
      ),
    ],
  };

  // Types d'activités principaux
  static const List<ActivityType> activityTypes = [
    ActivityType(
      id: 'running',
      title: 'Course à pied',
      icon: LucideIcons.activity,
      formats: [],
    ),
    ActivityType(
      id: 'bike',
      title: 'Vélo',
      icon: LucideIcons.bike,
      formats: [],
    ),
    ActivityType(
      id: 'walking',
      title: 'Marche',
      icon: LucideIcons.footprints,
      formats: [],
    ),
    ActivityType(
      id: 'hiit',
      title: 'HIIT',
      icon: LucideIcons.flame,
      formats: [],
    ),
  ];

  // Configurations d'activités
  static const Map<String, ActivityConfig> activityConfigs = {
    'distance': ActivityConfig(
      type: 'distance',
      title: 'Quelle distance veux-tu parcourir ?',
      hint: 'Ex: 5',
      unit: 'km',
    ),
    'duration': ActivityConfig(
      type: 'duration',
      title: 'Combien de temps veux-tu t\'entraîner ?',
      hint: 'Ex: 30',
      unit: 'min',
    ),
    'hiit': ActivityConfig(
      type: 'hiit',
      title: 'Paramètres de ton HIIT',
      hint: 'Durée totale en minutes',
      unit: 'min',
    ),
  };
} 