import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/translations.dart';
import '../../services/cardio_service.dart';
import '../../services/localization_service.dart';
import '../../services/unit_service.dart';

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
    final locService = LocalizationService.instance;
    return getTimeAgo(locService.currentLanguageCode);
  }

  String getTimeAgo(String languageCode) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'cardio_today'.tr(languageCode);
    } else if (difference.inDays == 1) {
      return 'cardio_yesterday'.tr(languageCode);
    } else if (difference.inDays < 7) {
      return 'cardio_days_ago'.tr(languageCode).replaceAll('{count}', '${difference.inDays}');
    } else {
      final weeks = (difference.inDays / 7).floor();
      final plural = weeks > 1 ? 's' : '';
      return 'cardio_weeks_ago'.tr(languageCode)
          .replaceAll('{count}', '$weeks')
          .replaceAll('{plural}', plural);
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

  // Formatte la distance avec gestion intelligente et unités
  String get distanceText {
    final decimals = totalDistance >= 100 ? 0 : 1;
    return UnitService.instance.formatDistance(totalDistance, decimals: decimals);
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
  final CardioActivityFormat? supabaseFormat; // Référence au format Supabase

  const ActivityFormat({
    required this.icon,
    required this.title,
    required this.description,
    required this.trackable,
    required this.configurable,
    this.configType,
    this.supabaseFormat,
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
  // Variables pour le cache et le listener de langue
  static Map<String, Map<String, List<ActivityFormat>>> _cachedActivityFormats = {};
  static Map<String, List<ActivityType>> _cachedActivityTypes = {};
  static Map<String, Map<String, ActivityConfig>> _cachedActivityConfigs = {};
  static String _lastLanguage = '';
  static bool _lastIsImperial = false;
  static bool _isListenerSetup = false;

  // Listener pour les changements de langue et d'unités
  static void _setupLanguageListener() {
    if (!_isListenerSetup) {
      LocalizationService.instance.addListener(_onLanguageChanged);
      UnitService.instance.addListener(_onUnitChanged);
      _isListenerSetup = true;
      _lastLanguage = LocalizationService.instance.currentLanguageCode;
      _lastIsImperial = UnitService.instance.isImperial;
      debugPrint('✅ CardioData: Language & Unit listeners configurés');
    }
  }

  // Callback appelé lors du changement de langue
  static void _onLanguageChanged() {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;
    if (currentLanguage != _lastLanguage) {
      debugPrint('🔄 CardioData: Changement de langue détecté ($currentLanguage)');
      _lastLanguage = currentLanguage;
      _invalidateCache();
    }
  }

  // Callback appelé lors du changement d'unités
  static void _onUnitChanged() {
    final currentIsImperial = UnitService.instance.isImperial;
    if (currentIsImperial != _lastIsImperial) {
      debugPrint('🔄 CardioData: Changement d\'unité détecté (${currentIsImperial ? "Impérial" : "Métrique"})');
      _lastIsImperial = currentIsImperial;
      _invalidateCache();
    }
  }
  
  // Invalide le cache
  static void _invalidateCache() {
    _cachedActivityFormats.clear();
    _cachedActivityTypes.clear();
    _cachedActivityConfigs.clear();
  }

  // Méthode pour obtenir les formats d'activités localisés
  static Map<String, List<ActivityFormat>> getLocalizedActivityFormats([String? languageCode]) {
    _setupLanguageListener();
    final targetLanguage = languageCode ?? LocalizationService.instance.currentLanguageCode;
    
    // Vérifier le cache
    if (_cachedActivityFormats.containsKey(targetLanguage)) {
      return _cachedActivityFormats[targetLanguage]!;
    }
    
    // Générer les données localisées
    final result = _generateLocalizedActivityFormats(targetLanguage);
    _cachedActivityFormats[targetLanguage] = result;
    return result;
  }
  
  static Map<String, List<ActivityFormat>> _generateLocalizedActivityFormats(String languageCode) {
    return {
      'running': [
        ActivityFormat(
          icon: LucideIcons.activity,
          title: 'cardio_free_session'.tr(languageCode),
          description: 'cardio_free_session_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.target,
          title: 'cardio_distance_goal'.tr(languageCode),
          description: 'cardio_distance_goal_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'distance',
        ),
        ActivityFormat(
          icon: LucideIcons.clock,
          title: 'cardio_duration_goal'.tr(languageCode),
          description: 'cardio_duration_goal_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'duration',
        ),
        ActivityFormat(
          icon: LucideIcons.zap,
          title: 'cardio_interval_beginner'.tr(languageCode),
          description: 'cardio_interval_beginner_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.flame,
          title: 'cardio_interval_advanced'.tr(languageCode),
          description: 'cardio_interval_advanced_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
      ],
      'bike': [
        ActivityFormat(
          icon: LucideIcons.bike,
          title: 'cardio_bike_free'.tr(languageCode),
          description: 'cardio_bike_free_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.target,
          title: 'cardio_bike_distance'.tr(languageCode),
          description: 'cardio_bike_distance_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'distance',
        ),
        ActivityFormat(
          icon: LucideIcons.clock,
          title: 'cardio_bike_duration'.tr(languageCode),
          description: 'cardio_bike_duration_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'duration',
        ),
        ActivityFormat(
          icon: LucideIcons.mountain,
          title: 'cardio_hills'.tr(languageCode),
          description: 'cardio_hills_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
      ],
      'walking': [
        ActivityFormat(
          icon: LucideIcons.footprints,
          title: 'cardio_walking_free'.tr(languageCode),
          description: 'cardio_walking_free_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.target,
          title: 'cardio_walking_distance'.tr(languageCode),
          description: 'cardio_walking_distance_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'distance',
        ),
        ActivityFormat(
          icon: LucideIcons.clock,
          title: 'cardio_walking_duration'.tr(languageCode),
          description: 'cardio_walking_duration_desc'.tr(languageCode),
          trackable: true,
          configurable: true,
          configType: 'duration',
        ),
        ActivityFormat(
          icon: LucideIcons.trendingUp,
          title: 'cardio_fast_walking'.tr(languageCode),
          description: 'cardio_fast_walking_desc'.tr(languageCode),
          trackable: true,
          configurable: false,
        ),
      ],
      'hiit': [
        ActivityFormat(
          icon: LucideIcons.flame,
          title: 'cardio_hiit_beginner'.tr(languageCode),
          description: 'cardio_hiit_beginner_desc'.tr(languageCode),
          trackable: false,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.zap,
          title: 'cardio_hiit_intense'.tr(languageCode),
          description: 'cardio_hiit_intense_desc'.tr(languageCode),
          trackable: false,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.target,
          title: 'cardio_tabata'.tr(languageCode),
          description: 'cardio_tabata_desc'.tr(languageCode),
          trackable: false,
          configurable: false,
        ),
        ActivityFormat(
          icon: LucideIcons.timer,
          title: 'cardio_hiit_custom'.tr(languageCode),
          description: 'cardio_hiit_custom_desc'.tr(languageCode),
          trackable: false,
          configurable: true,
          configType: 'hiit',
        ),
      ],
    };
  }

  // Méthode pour obtenir les types d'activités localisés
  static List<ActivityType> getLocalizedActivityTypes([String? languageCode]) {
    _setupLanguageListener();
    final targetLanguage = languageCode ?? LocalizationService.instance.currentLanguageCode;
    
    // Vérifier le cache
    if (_cachedActivityTypes.containsKey(targetLanguage)) {
      return _cachedActivityTypes[targetLanguage]!;
    }
    
    // Générer les données localisées
    final result = _generateLocalizedActivityTypes(targetLanguage);
    _cachedActivityTypes[targetLanguage] = result;
    return result;
  }
  
  static List<ActivityType> _generateLocalizedActivityTypes(String languageCode) {
    return [
      ActivityType(
        id: 'running',
        title: 'activity_running'.tr(languageCode),
        icon: LucideIcons.activity,
        formats: [],
      ),
      ActivityType(
        id: 'bike',
        title: 'activity_bike'.tr(languageCode),
        icon: LucideIcons.bike,
        formats: [],
      ),
      ActivityType(
        id: 'walking',
        title: 'activity_walking'.tr(languageCode),
        icon: LucideIcons.footprints,
        formats: [],
      ),
      ActivityType(
        id: 'hiit',
        title: 'activity_hiit'.tr(languageCode),
        icon: LucideIcons.flame,
        formats: [],
      ),
    ];
  }
  // Statistiques de la semaine example
  static const WeeklyCardioStats weeklyStats = WeeklyCardioStats(
    totalDistance: 90.5,
    totalDuration: Duration(hours: 10, minutes: 40),
    totalCalories: 1860,
  );

  // Méthode pour obtenir la dernière session localisée
  static CardioSession getLocalizedLastSession(String languageCode) {
    return CardioSession(
      id: '1',
      activityType: 'running',
      activityTitle: 'activity_running'.tr(languageCode),
      formatTitle: 'cardio_free_session'.tr(languageCode),
      date: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(minutes: 28),
      distance: 5.2,
      calories: 312,
      pace: 5.38, // 5:23 /km
    );
  }

  // Méthode pour obtenir les sessions de la semaine localisées
  static List<CardioSession> getLocalizedWeekSessions(String languageCode) {
    return [
      CardioSession(
        id: '1',
        activityType: 'running',
        activityTitle: 'activity_running'.tr(languageCode),
        formatTitle: 'cardio_interval_beginner'.tr(languageCode),
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 25),
        distance: 4.8,
        calories: 280,
      ),
      CardioSession(
        id: '2',
        activityType: 'bike',
        activityTitle: 'activity_bike'.tr(languageCode),
        formatTitle: 'cardio_bike_free'.tr(languageCode),
        date: DateTime.now().subtract(const Duration(days: 3)),
        duration: const Duration(hours: 1, minutes: 15),
        distance: 28.5,
        calories: 420,
      ),
      CardioSession(
        id: '3',
        activityType: 'walking',
        activityTitle: 'activity_walking'.tr(languageCode),
        formatTitle: 'cardio_fast_walking'.tr(languageCode),
        date: DateTime.now().subtract(const Duration(days: 5)),
        duration: const Duration(minutes: 45),
        distance: 5.2,
        calories: 180,
      ),
    ];
  }

  // Dernière session example (conservée pour la compatibilité)
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

  // Sessions de la semaine example (conservées pour la compatibilité)
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



  // Méthode pour obtenir les configurations d'activités localisées
  static Map<String, ActivityConfig> getLocalizedActivityConfigs([String? languageCode]) {
    _setupLanguageListener();
    final targetLanguage = languageCode ?? LocalizationService.instance.currentLanguageCode;
    
    // Vérifier le cache
    if (_cachedActivityConfigs.containsKey(targetLanguage)) {
      return _cachedActivityConfigs[targetLanguage]!;
    }
    
    // Générer les données localisées
    final result = _generateLocalizedActivityConfigs(targetLanguage);
    _cachedActivityConfigs[targetLanguage] = result;
    return result;
  }

  static Map<String, ActivityConfig> _generateLocalizedActivityConfigs(String languageCode) {
    return {
      'distance': ActivityConfig(
        type: 'distance',
        title: 'cardio_distance_question'.tr(languageCode),
        hint: 'cardio_distance_hint'.tr(languageCode),
        unit: UnitService.instance.distanceUnit,
      ),
      'duration': ActivityConfig(
        type: 'duration',
        title: 'cardio_duration_question'.tr(languageCode),
        hint: 'cardio_duration_hint'.tr(languageCode),
        unit: 'cardio_min_unit'.tr(languageCode),
      ),
      'hiit': ActivityConfig(
        type: 'hiit',
        title: 'cardio_hiit_params'.tr(languageCode),
        hint: 'cardio_hiit_hint'.tr(languageCode),
        unit: 'cardio_min_unit'.tr(languageCode),
      ),
    };
  }

  // Configurations d'activités (conservées pour la compatibilité)
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
