import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cardio_session_models.dart';
import 'cardio_service.dart';
import 'sport_dashboard_service.dart';
import 'workout_cache_service.dart';

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

      final sessionData = {
        'user_id': userId,
        'activity_type': activityType,
        'activity_title': activityTitle,
        'format_title': formatTitle,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
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
}
