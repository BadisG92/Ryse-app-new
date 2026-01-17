import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cardio_session_models.dart';
import 'cardio_service.dart';
import 'sport_dashboard_service.dart';
import 'workout_cache_service.dart';
import 'location_service.dart';
import 'cardio_calculator.dart';
import 'weekly_planner_service.dart';

/// Manager pour gérer le cycle de vie des séances cardio
/// S'assure que toutes les séances terminées sont bien historisées
class CardioSessionManager {
  static final SupabaseClient _client = Supabase.instance.client;
  
  /// Démarre une nouvelle séance cardio
  static Future<String> startCardioSession({
    required String activityType,
    required String activityTitle,
    required String formatTitle,
    double? targetDistance,
    Duration? targetDuration,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final sessionData = {
        'user_id': userId,
        'activity_type': activityType,
        'activity_title': activityTitle,
        'format_title': formatTitle,
        'start_time': DateTime.now().toIso8601String(),
        'target_distance_km': targetDistance,
        'target_duration_seconds': targetDuration?.inSeconds,
        'is_running': true,
        'is_paused': false,
        'is_completed': false,
      };

      final result = await _client
          .from('cardio_sessions')
          .insert(sessionData)
          .select()
          .single();

      final sessionId = result['id'] as String;
      debugPrint('✅ Cardio session started: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Error starting cardio session: $e');
      rethrow;
    }
  }

  /// Met à jour une séance cardio en cours
  static Future<void> updateCardioSession({
    required String sessionId,
    Duration? duration,
    double? distance,
    double? currentSpeed,
    double? averageSpeed,
    int? steps,
    int? calories,
    bool? isPaused,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updateData = <String, dynamic>{};
      
      if (duration != null) updateData['duration_seconds'] = duration.inSeconds;
      if (distance != null) updateData['distance_km'] = distance;
      if (currentSpeed != null) updateData['current_speed_kmh'] = currentSpeed;
      if (averageSpeed != null) updateData['average_speed_kmh'] = averageSpeed;
      if (steps != null) updateData['steps'] = steps;
      if (calories != null) updateData['calories'] = calories;
      if (isPaused != null) updateData['is_paused'] = isPaused;

      await _client
          .from('cardio_sessions')
          .update(updateData)
          .eq('id', sessionId)
          .eq('user_id', userId);

      debugPrint('✅ Cardio session updated: $sessionId');
    } catch (e) {
      debugPrint('❌ Error updating cardio session: $e');
      rethrow;
    }
  }

  /// Termine une séance cardio avec données GPS et s'assure qu'elle soit bien historisée
  /// Retourne l'ID de la session créée pour la synchronisation avec le planner
  static Future<String> completeCardioSessionWithGPS({
    required CardioSessionData sessionData,
    String? intensity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Récupérer les données GPS finales
      final gpsDistance = LocationService.calculateTotalDistance();
      final gpsAverageSpeed = LocationService.calculateAverageSpeed();
      final gpsRoute = LocationService.currentRoute;
      final gpsElevation = CardioCalculator.calculateElevationStats(gpsRoute);

      // Calculer les calories avec les vraies données
      final finalCalories = CardioCalculator.calculateCalories(
        activityType: sessionData.activityType,
        duration: sessionData.duration,
        averageSpeed: gpsAverageSpeed,
        distance: gpsDistance,
      );

      // Calculer l'allure pour la course
      final paceSeconds = LocationService.calculatePacePerKm();

      // Sauvegarder la session complète et récupérer l'ID
      final sessionId = await CardioService.saveCompletedCardioSession(
        sessionData: sessionData.copyWith(
          distance: gpsDistance > 0 ? gpsDistance : sessionData.distance,
          averageSpeed: gpsAverageSpeed > 0 ? gpsAverageSpeed : sessionData.averageSpeed,
          calories: finalCalories > 0 ? finalCalories : sessionData.calories,
          route: gpsRoute.isNotEmpty ? gpsRoute : sessionData.route,
          endTime: DateTime.now(),
        ),
        intensity: intensity ?? 'Modéré',
        notes: notes,
      );

      debugPrint('✅ Cardio session avec GPS terminée - ID: $sessionId, Distance: ${gpsDistance.toStringAsFixed(2)}km, Vitesse moy: ${gpsAverageSpeed.toStringAsFixed(1)}km/h');

      // Nettoyer les données GPS
      LocationService.clearRoute();

      // Invalider les caches (mais pas de mise à jour GlobalState ici pour éviter doublons)
      _invalidateAllCaches();

      // 🔄 Sync vers le planner
      await WeeklyPlannerService.syncCardioSessionToPlanner(
        sessionId: sessionId,
        activityType: sessionData.activityType,
        activityTitle: sessionData.activityTitle,
        sessionDate: sessionData.startTime,
        durationMinutes: sessionData.duration.inMinutes,
        distanceKm: gpsDistance > 0 ? gpsDistance : sessionData.distance,
      );

      return sessionId;
    } catch (e) {
      debugPrint('❌ Error completing cardio session with GPS: $e');
      rethrow;
    }
  }

  /// Termine une séance cardio et s'assure qu'elle soit bien historisée
  static Future<void> completeCardioSession({
    required String sessionId,
    String? intensity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 1. Marquer la séance comme terminée dans la base
      await _client
          .from('cardio_sessions')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'is_running': false,
            'is_paused': false,
            'is_completed': true, // S'assurer explicitement que c'est marqué comme terminé
            'intensity': intensity,
            'notes': notes,
          })
          .eq('id', sessionId)
          .eq('user_id', userId);

      debugPrint('✅ Cardio session completed: $sessionId');

      // 2. Invalider le cache pour forcer le rechargement des données
      _invalidateAllCaches();

      // 3. 🔄 Sync vers le planner - récupérer les données de la session
      final sessionData = await _client
          .from('cardio_sessions')
          .select('activity_type, activity_title, session_date, duration_seconds, distance_km, calories')
          .eq('id', sessionId)
          .maybeSingle();

      if (sessionData != null) {
        await WeeklyPlannerService.syncCardioSessionToPlanner(
          sessionId: sessionId,
          activityType: sessionData['activity_type'] as String? ?? 'running',
          activityTitle: sessionData['activity_title'] as String? ?? 'Cardio',
          sessionDate: DateTime.parse(sessionData['session_date'] as String),
          durationMinutes: sessionData['duration_seconds'] != null
              ? ((sessionData['duration_seconds'] as int) / 60).round()
              : null,
          distanceKm: (sessionData['distance_km'] as num?)?.toDouble(),
        );
      }

    } catch (e) {
      debugPrint('❌ Error completing cardio session: $e');
      rethrow;
    }
  }

  /// Récupère une séance cardio active (en cours)
  static Future<Map<String, dynamic>?> getActiveCardioSession() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final result = await _client
          .from('cardio_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_running', true)
          .eq('is_completed', false)
          .order('start_time', ascending: false)
          .limit(1);

      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      debugPrint('❌ Error getting active cardio session: $e');
      return null;
    }
  }

  /// Annule une séance cardio en cours
  static Future<void> cancelCardioSession(String sessionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('cardio_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', userId)
          .eq('is_completed', false);

      debugPrint('✅ Cardio session cancelled: $sessionId');
    } catch (e) {
      debugPrint('❌ Error cancelling cardio session: $e');
      rethrow;
    }
  }

  /// Méthode utilitaire pour créer une séance cardio complète d'un coup
  /// (utile pour l'entrée manuelle de données)
  static Future<String> createCompletedCardioSession({
    required String activityType,
    required String activityTitle,
    required String formatTitle,
    required DateTime startTime,
    required Duration duration,
    double? distance,
    int? calories,
    int? steps,
    String? intensity,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final endTime = startTime.add(duration);
      final averageSpeed = (distance != null && distance > 0 && duration.inSeconds > 0)
          ? (distance * 3600 / duration.inSeconds)
          : null;

      // session_date = date locale de la session (sans heure) pour les filtres SQL
      final sessionDate = DateTime(startTime.year, startTime.month, startTime.day);

      final sessionData = {
        'user_id': userId,
        'activity_type': activityType,
        'activity_title': activityTitle,
        'format_title': formatTitle,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'session_date': sessionDate.toIso8601String().split('T')[0], // Date pour filtres SQL
        'duration_seconds': duration.inSeconds,
        'distance_km': distance,
        'average_speed_kmh': averageSpeed,
        'steps': steps,
        'calories': calories,
        'intensity': intensity,
        'notes': notes,
        'is_running': false,
        'is_paused': false,
        'is_completed': true,
      };

      final result = await _client
          .from('cardio_sessions')
          .insert(sessionData)
          .select()
          .single();

      final sessionId = result['id'] as String;
      debugPrint('✅ Completed cardio session created: $sessionId');

      // Invalider le cache
      CardioService.invalidateCache();
      SportDashboardService.invalidateCache();
      
      // Aussi invalider WorkoutCacheService pour le dashboard unifié
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          WorkoutCacheService.invalidateUserCache(userId);
        }
      } catch (e) {
        debugPrint('⚠️ Could not invalidate WorkoutCacheService: $e');
      }

      return sessionId;
    } catch (e) {
      debugPrint('❌ Error creating completed cardio session: $e');
      rethrow;
    }
  }

  /// Invalide tous les caches après une séance cardio
  static void _invalidateAllCaches() {
    CardioService.invalidateCache();
    SportDashboardService.invalidateCache();
    
    // Aussi invalider WorkoutCacheService pour le dashboard unifié
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        WorkoutCacheService.invalidateUserCache(userId);
      }
    } catch (e) {
      debugPrint('⚠️ Could not invalidate WorkoutCacheService: $e');
    }
  }
}
