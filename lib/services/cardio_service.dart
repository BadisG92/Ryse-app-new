import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cardio_session_models.dart';
import 'translations.dart';
import 'localization_service.dart';
import 'sport_dashboard_service.dart';
import 'global_state_manager.dart';

/// Service pour gérer les activités cardio depuis Supabase
class CardioService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Cache en mémoire pour les activités cardio (par langue)
  static Map<String, List<CardioActivityType>> _cachedActivities = {};
  static Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheDuration = Duration(hours: 1);
  static String _lastLanguage = '';
  static bool _isListenerSetup = false;

  // Listener pour les changements de langue
  static void _setupLanguageListener() {
    if (!_isListenerSetup) {
      LocalizationService.instance.addListener(_onLanguageChanged);
      _isListenerSetup = true;
      _lastLanguage = LocalizationService.instance.currentLanguageCode;
      debugPrint('✅ CardioService: Language listener configuré');
    }
  }
  
  // Callback appelé lors du changement de langue
  static void _onLanguageChanged() {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;
    if (currentLanguage != _lastLanguage) {
      debugPrint('🔄 CardioService: Changement de langue détecté ($currentLanguage)');
      _lastLanguage = currentLanguage;
      invalidateCache();
    }
  }

  /// Récupère toutes les activités cardio avec leurs formats
  static Future<List<CardioActivityType>> getCardioActivities({String? language}) async {
    // Configurer le listener une seule fois
    _setupLanguageListener();
    
    // Utiliser la langue courante si aucune n'est spécifiée
    final targetLanguage = language ?? LocalizationService.instance.currentLanguageCode;
    // Vérifier le cache pour cette langue
    if (_cachedActivities.containsKey(targetLanguage) && 
        _cacheTimestamp.containsKey(targetLanguage) && 
        DateTime.now().difference(_cacheTimestamp[targetLanguage]!) < _cacheDuration) {
      return _cachedActivities[targetLanguage]!;
    }

    try {
      final result = await _client.rpc('get_cardio_activities', 
        params: {'language': targetLanguage});
      
      final activitiesJson = result as List<dynamic>;
      
      final activities = activitiesJson.map<CardioActivityType>((json) {
        return CardioActivityType.fromJson(json);
      }).toList();

      // Mettre en cache pour cette langue
      _cachedActivities[targetLanguage] = activities;
      _cacheTimestamp[targetLanguage] = DateTime.now();
      
      return activities;
    } catch (e) {
      debugPrint('❌ Error loading cardio activities: $e');
      return [];
    }
  }

  /// Récupère les formats d'une activité spécifique
  static Future<List<CardioActivityFormat>> getActivityFormats(String activityKey, {String? language}) async {
    // Configurer le listener une seule fois
    _setupLanguageListener();
    
    // Utiliser la langue courante si aucune n'est spécifiée
    final targetLanguage = language ?? LocalizationService.instance.currentLanguageCode;
    try {
      final result = await _client.rpc('get_cardio_activity_formats', 
        params: {'activity_key': activityKey, 'language': targetLanguage});
      
      final formatsJson = result as List<dynamic>;
      
      return formatsJson.map<CardioActivityFormat>((json) {
        return CardioActivityFormat.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading activity formats for $activityKey: $e');
      return [];
    }
  }

  /// Invalide le cache (à appeler lors de modifications)
  static void invalidateCache() {
    _cachedActivities.clear();
    _cacheTimestamp.clear();
  }

  /// Supprime une séance cardio par son ID
  static Future<void> deleteCardioSession(String sessionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('🗑️ Suppression de la séance cardio: $sessionId');

      await _client
          .from('cardio_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', userId);

      debugPrint('✅ Séance cardio supprimée avec succès');

      // Invalider les caches
      SportDashboardService.invalidateCache();
      GlobalStateManager.instance.invalidateWeeklyData();

      // Rafraîchir les données sport dans le GlobalState
      await GlobalStateManager.instance.refreshSportData();
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la séance cardio: $e');
      rethrow;
    }
  }

  /// Sauvegarde une séance cardio terminée
  static Future<String> saveCompletedCardioSession({
    required CardioSessionData sessionData,
    required String? intensity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final sessionId = const Uuid().v4();
      
      // Récupérer l'ID du format basé sur le nom et le type d'activité
      String? activityFormatId;
      try {
        final formatResult = await _client
            .from('cardio_activity_formats')
            .select('id')
            .or('name_fr.ilike.%${sessionData.formatTitle}%,name_en.ilike.%${sessionData.formatTitle}%')
            .eq('activity_type', sessionData.activityType)
            .maybeSingle();
        
        activityFormatId = formatResult?['id'];
        
        // Si pas trouvé avec le titre complet, essayer de trouver par type d'activité seulement
        if (activityFormatId == null && sessionData.activityType == 'hiit') {
          // Essayer plusieurs stratégies pour HIIT
          final fallbackResults = await _client
              .from('cardio_activity_formats')
              .select('id, name_fr, name_en')
              .eq('activity_type', 'hiit')
              .limit(5);
          
          if (fallbackResults.isNotEmpty) {
            // Prendre le premier format HIIT disponible
            activityFormatId = fallbackResults.first['id'];
            debugPrint('📍 Format HIIT trouvé par fallback: $activityFormatId (${fallbackResults.first['name_fr']} / ${fallbackResults.first['name_en']})');
            debugPrint('📍 Formats HIIT disponibles: ${fallbackResults.map((f) => '${f['name_fr']}/${f['name_en']}').join(', ')}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Format non trouvé pour: ${sessionData.formatTitle} (${sessionData.activityType})');
      }
      
      await _client.from('cardio_sessions').insert({
        'id': sessionId,
        'user_id': userId,
        'activity_type': sessionData.activityType,
        'activity_title': sessionData.activityTitle,
        'format_title': sessionData.formatTitle,
        'activity_format_id': activityFormatId, // Ajout de l'ID du format
        'start_time': sessionData.startTime.toIso8601String(),
        'end_time': sessionData.endTime?.toIso8601String(),
        'duration_seconds': sessionData.duration.inSeconds,
        'distance_km': sessionData.distance,
        'target_distance_km': sessionData.targetDistance,
        'target_duration_seconds': sessionData.targetDuration?.inSeconds,
        'average_speed_kmh': sessionData.averageSpeed,
        'current_speed_kmh': sessionData.currentSpeed,
        'steps': sessionData.steps,
        'calories': sessionData.calories,
        'intensity': intensity,
        'notes': notes,
        'is_completed': true,
      });

      debugPrint('✅ Cardio session saved: $sessionId (format_id: $activityFormatId)');

      // NOTE: Les mises à jour du GlobalStateManager sont gérées par l'appelant
      // pour éviter les doublons de validation

      return sessionId;
    } catch (e) {
      debugPrint('❌ Error saving cardio session: $e');
      rethrow;
    }
  }

  /// Récupère les données du dashboard cardio
  static Future<Map<String, dynamic>> getCardioDashboardData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Calculer la semaine courante (lundi-dimanche) en heure LOCALE de l'utilisateur
      final now = DateTime.now(); // Heure locale
      final weekday = now.weekday; // 1=Lundi, 7=Dimanche
      final mondayThisWeek = now.subtract(Duration(days: weekday - 1));
      final weekStart = DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      debugPrint('📅 Cardio: Semaine courante (locale utilisateur): $weekStartStr -> $weekEndStr');
      debugPrint('📅 Cardio: Appel RPC get_cardio_dashboard_data pour user: $userId');

      final result = await _client.rpc('get_cardio_dashboard_data',
        params: {
          'target_user_id': userId,
          'week_start_date': weekStartStr,
          'week_end_date': weekEndStr,
        });

      final data = result as Map<String, dynamic>;
      debugPrint('📊 Cardio: Résultat RPC reçu:');
      debugPrint('   - weekly_stats: ${data['weekly_stats']}');
      debugPrint('   - last_session: ${data['last_session'] != null ? "présente" : "null"}');
      debugPrint('   - week_sessions: ${(data['week_sessions'] as List?)?.length ?? 0} session(s)');

      return data;
    } catch (e) {
      debugPrint('❌ Error loading cardio dashboard data: $e');
      return {
        'weekly_stats': {'total_distance': 0, 'total_duration_minutes': 0, 'total_calories': 0, 'sessions_count': 0},
        'last_session': null,
        'week_sessions': [],
      };
    }
  }

  /// Récupère les statistiques hebdomadaires
  static Future<CardioWeeklyStats> getWeeklyStats() async {
    final dashboardData = await getCardioDashboardData();
    final stats = dashboardData['weekly_stats'] ?? {};
    
    return CardioWeeklyStats(
      totalDistance: (stats['total_distance'] as num?)?.toDouble() ?? 0.0,
      totalDuration: Duration(minutes: (stats['total_duration_minutes'] as num?)?.toInt() ?? 0),
      totalCalories: (stats['total_calories'] as num?)?.toInt() ?? 0,
      sessionsCount: (stats['sessions_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Récupère la dernière séance
  static Future<CompletedCardioSession?> getLastSession() async {
    final dashboardData = await getCardioDashboardData();
    final sessionData = dashboardData['last_session'];
    
    if (sessionData == null) return null;
    
    return CompletedCardioSession.fromJson(sessionData);
  }

  /// Récupère les séances de la semaine
  static Future<List<CompletedCardioSession>> getWeekSessions() async {
    final dashboardData = await getCardioDashboardData();
    final sessionsData = dashboardData['week_sessions'] as List? ?? [];
    
    return sessionsData.map<CompletedCardioSession>((data) {
      return CompletedCardioSession.fromJson(data);
    }).toList();
  }
}

/// Modèle pour un type d'activité cardio
class CardioActivityType {
  final String id;
  final String activityKey;
  final String name;
  final String iconName;
  final String? description;
  final int sortOrder;
  final List<CardioActivityFormat> formats;

  const CardioActivityType({
    required this.id,
    required this.activityKey,
    required this.name,
    required this.iconName,
    this.description,
    required this.sortOrder,
    required this.formats,
  });

  factory CardioActivityType.fromJson(Map<String, dynamic> json) {
    final formatsJson = json['formats'] as List<dynamic>? ?? [];
    
    return CardioActivityType(
      id: json['id'] as String,
      activityKey: json['activity_key'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int,
      formats: formatsJson.map<CardioActivityFormat>((formatJson) {
        return CardioActivityFormat.fromJson(formatJson);
      }).toList(),
    );
  }
}

/// Modèle pour un format d'activité cardio
class CardioActivityFormat {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final bool isTrackable;
  final bool isConfigurable;
  final String? configType;
  final int sortOrder;
  final int? defaultDurationMinutes;
  final double? defaultDistanceKm;
  final int? hiitWorkSeconds;
  final int? hiitRestSeconds;
  final int? hiitRounds;
  final int? hiitSets;

  const CardioActivityFormat({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.isTrackable,
    required this.isConfigurable,
    this.configType,
    required this.sortOrder,
    this.defaultDurationMinutes,
    this.defaultDistanceKm,
    this.hiitWorkSeconds,
    this.hiitRestSeconds,
    this.hiitRounds,
    this.hiitSets,
  });

  factory CardioActivityFormat.fromJson(Map<String, dynamic> json) {
    return CardioActivityFormat(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String,
      isTrackable: json['is_trackable'] as bool,
      isConfigurable: json['is_configurable'] as bool,
      configType: json['config_type'] as String?,
      sortOrder: json['sort_order'] as int,
      defaultDurationMinutes: json['default_duration_minutes'] as int?,
      defaultDistanceKm: (json['default_distance_km'] as num?)?.toDouble(),
      hiitWorkSeconds: json['hiit_work_seconds'] as int?,
      hiitRestSeconds: json['hiit_rest_seconds'] as int?,
      hiitRounds: json['hiit_rounds'] as int?,
      hiitSets: json['hiit_sets'] as int?,
    );
  }

  /// Formatte la durée HIIT en texte lisible
  String get hiitDurationText {
    if (hiitWorkSeconds != null && hiitRestSeconds != null && hiitRounds != null) {
      return '${hiitRounds}x ${hiitWorkSeconds}s / ${hiitRestSeconds}s';
    }
    return '';
  }

  /// Indique si c'est un format HIIT
  bool get isHiit => configType == 'hiit' || hiitWorkSeconds != null;
}

/// Modèle pour les statistiques hebdomadaires cardio
class CardioWeeklyStats {
  final double totalDistance; // en km
  final Duration totalDuration;
  final int totalCalories;
  final int sessionsCount;

  const CardioWeeklyStats({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.sessionsCount,
  });

  /// Formatte la distance totale
  String get distanceText => '${totalDistance.toStringAsFixed(1)} km';

  /// Formatte la durée totale
  String get durationText {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes} min';
    }
  }

  /// Formatte les calories
  String get caloriesText => '$totalCalories kcal';
}

/// Modèle pour une séance cardio terminée
class CompletedCardioSession {
  final String id;
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double? distance; // en km
  final int calories;
  final double? averageSpeed; // km/h
  final int? pacePerKmSeconds; // allure en secondes par km
  final int? steps;
  final String? intensity;
  final String? notes;

  const CompletedCardioSession({
    required this.id,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.distance,
    required this.calories,
    this.averageSpeed,
    this.pacePerKmSeconds,
    this.steps,
    this.intensity,
    this.notes,
  });

  factory CompletedCardioSession.fromJson(Map<String, dynamic> json) {
    return CompletedCardioSession(
      id: json['id'] as String,
      activityType: json['activity_type'] as String,
      activityTitle: json['activity_title'] as String,
      formatTitle: json['format_title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      duration: Duration(seconds: (json['duration_seconds'] as int?) ?? 0),
      distance: (json['distance_km'] as num?)?.toDouble(),
      calories: (json['calories'] as int?) ?? 0,
      averageSpeed: (json['average_speed_kmh'] as num?)?.toDouble(),
      pacePerKmSeconds: json['pace_per_km_seconds'] as int?,
      steps: json['steps'] as int?,
      intensity: json['intensity'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Formatte la durée en texte
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes} min';
    }
  }

  /// Formatte la distance en texte
  String get distanceText {
    if (distance == null) return '';
    return '${distance!.toStringAsFixed(1)} km';
  }

  /// Formatte l'allure en texte (min:sec /km)
  String get paceText {
    if (pacePerKmSeconds == null) return '';
    final totalSeconds = pacePerKmSeconds!;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')} /km';
  }

  /// Formatte les calories en texte
  String get caloriesText => '$calories kcal';

  /// Formatte la vitesse moyenne en texte
  String get speedText {
    if (averageSpeed == null) return '';
    return '${averageSpeed!.toStringAsFixed(1)} km/h';
  }

  /// Calcule le temps écoulé depuis la session
  String get timeAgo {
    final locService = LocalizationService.instance;
    return getTimeAgo(locService.currentLanguageCode);
  }

  String getTimeAgo(String languageCode) {
    final now = DateTime.now();
    final difference = now.difference(startTime);

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
}
