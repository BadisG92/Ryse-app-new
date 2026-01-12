import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_planner_models.dart';
import '../models/sport_models.dart';
import 'global_state_manager.dart';

/// Service pour gérer le planificateur hebdomadaire
class WeeklyPlannerService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Cache en mémoire pour les données de la semaine
  static WeeklyPlannerData? _cachedWeekData;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 2);

  // =====================================================
  // FETCH DATA
  // =====================================================

  /// Récupérer les données du planner pour la semaine courante
  static Future<WeeklyPlannerData> getWeekData({bool forceRefresh = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ WeeklyPlannerService: No user logged in');
      return WeeklyPlannerData.empty();
    }

    // Vérifier le cache
    if (!forceRefresh && _cachedWeekData != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheTtl) {
        debugPrint('📦 WeeklyPlannerService: Returning cached data');
        return _cachedWeekData!;
      }
    }

    try {
      final weekStart = getCurrentWeekStart();
      final weekEnd = weekStart.add(const Duration(days: 6));

      debugPrint('📅 WeeklyPlannerService: Fetching week ${weekStart.toIso8601String()} to ${weekEnd.toIso8601String()}');

      // Fetch activities et workouts en parallèle
      final results = await Future.wait([
        _fetchActivities(userId, weekStart, weekEnd),
        _fetchWorkouts(userId, weekStart, weekEnd),
      ]);

      final activities = results[0] as List<PlannedActivity>;
      final workouts = results[1] as List<PlannedWorkout>;

      debugPrint('✅ WeeklyPlannerService: Fetched ${activities.length} activities, ${workouts.length} workouts');

      // Créer les données du planner
      final weekData = WeeklyPlannerData.fromLists(
        weekStart: weekStart,
        activities: activities,
        workouts: workouts,
      );

      // Mettre en cache
      _cachedWeekData = weekData;
      _cacheTimestamp = DateTime.now();

      return weekData;
    } catch (e) {
      debugPrint('❌ WeeklyPlannerService.getWeekData error: $e');
      return _cachedWeekData ?? WeeklyPlannerData.empty();
    }
  }

  /// Fetch les activités planifiées
  static Future<List<PlannedActivity>> _fetchActivities(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    try {
      final response = await _client
          .from('planned_activities')
          .select()
          .eq('user_id', userId)
          .gte('planned_date', weekStart.toIso8601String().split('T')[0])
          .lte('planned_date', weekEnd.toIso8601String().split('T')[0])
          .order('planned_date', ascending: true);

      return (response as List)
          .map((json) => PlannedActivity.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ _fetchActivities error: $e');
      return [];
    }
  }

  /// Fetch les workouts planifiés
  static Future<List<PlannedWorkout>> _fetchWorkouts(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    try {
      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('user_id', userId)
          .gte('planned_date', weekStart.toIso8601String().split('T')[0])
          .lte('planned_date', weekEnd.toIso8601String().split('T')[0])
          .order('planned_date', ascending: true);

      return (response as List)
          .map((json) => PlannedWorkout.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ _fetchWorkouts error: $e');
      return [];
    }
  }

  // =====================================================
  // CREATE
  // =====================================================

  /// Ajouter une activité planifiée (repas ou cardio)
  static Future<PlannedActivity?> addPlannedActivity({
    required DateTime plannedDate,
    required PlannedActivityType activityType,
    required Map<String, dynamic> activityData,
    bool isAiGenerated = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ addPlannedActivity: No user logged in');
      return null;
    }

    // Vérifier que la date est dans la semaine courante
    if (!isInCurrentWeek(plannedDate)) {
      debugPrint('❌ addPlannedActivity: Date not in current week');
      return null;
    }

    try {
      final data = {
        'user_id': userId,
        'planned_date': plannedDate.toIso8601String().split('T')[0],
        'activity_type': activityType.value,
        'activity_data': activityData,
        'status': 'planned',
        'is_ai_generated': isAiGenerated,
      };

      final response = await _client
          .from('planned_activities')
          .insert(data)
          .select()
          .single();

      final activity = PlannedActivity.fromJson(response);

      debugPrint('✅ addPlannedActivity: Created ${activityType.value} for ${plannedDate.toIso8601String().split('T')[0]}');

      // Invalider le cache et notifier
      _invalidateCache();
      _notifyPlannerUpdate();

      return activity;
    } catch (e) {
      debugPrint('❌ addPlannedActivity error: $e');
      return null;
    }
  }

  /// Ajouter un workout planifié
  static Future<PlannedWorkout?> addPlannedWorkout({
    required DateTime plannedDate,
    required String workoutName,
    required List<WorkoutExercise> exercises,
    int? durationMinutes,
    String? userPrompt,
    bool isAiGenerated = true,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ addPlannedWorkout: No user logged in');
      return null;
    }

    // Vérifier que la date est dans la semaine courante et pas dans le passé
    if (!isInCurrentWeek(plannedDate)) {
      debugPrint('❌ addPlannedWorkout: Date not in current week');
      return null;
    }

    if (!isDateEditable(plannedDate)) {
      debugPrint('❌ addPlannedWorkout: Cannot add workout to past date');
      return null;
    }

    try {
      final data = {
        'user_id': userId,
        'planned_date': plannedDate.toIso8601String().split('T')[0],
        'workout_name': workoutName,
        'duration_minutes': durationMinutes,
        'exercises_json': exercises.map((e) => e.toJson()).toList(),
        'user_prompt': userPrompt,
        'status': 'planned',
        'is_ai_generated': isAiGenerated,
      };

      final response = await _client
          .from('planned_workouts')
          .insert(data)
          .select()
          .single();

      final workout = PlannedWorkout.fromJson(response);

      debugPrint('✅ addPlannedWorkout: Created "$workoutName" for ${plannedDate.toIso8601String().split('T')[0]}');

      // Invalider le cache et notifier
      _invalidateCache();
      _notifyPlannerUpdate();

      return workout;
    } catch (e) {
      debugPrint('❌ addPlannedWorkout error: $e');
      return null;
    }
  }

  // =====================================================
  // UPDATE
  // =====================================================

  /// Mettre à jour le statut d'une activité
  static Future<bool> updateActivityStatus(String activityId, PlannedStatus status) async {
    try {
      await _client
          .from('planned_activities')
          .update({'status': status.value})
          .eq('id', activityId);

      debugPrint('✅ updateActivityStatus: $activityId -> ${status.value}');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ updateActivityStatus error: $e');
      return false;
    }
  }

  /// Mettre à jour le statut d'un workout
  static Future<bool> updateWorkoutStatus(
    String workoutId,
    PlannedStatus status, {
    String? linkedSessionId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
      };

      if (linkedSessionId != null) {
        updateData['linked_session_id'] = linkedSessionId;
      }

      await _client
          .from('planned_workouts')
          .update(updateData)
          .eq('id', workoutId);

      debugPrint('✅ updateWorkoutStatus: $workoutId -> ${status.value}');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ updateWorkoutStatus error: $e');
      return false;
    }
  }

  /// Déplacer un workout vers un autre jour (uniquement vers un jour futur)
  static Future<bool> movePlannedWorkout(String workoutId, DateTime newDate) async {
    // Vérifier que la nouvelle date est dans la semaine courante et pas dans le passé
    if (!isInCurrentWeek(newDate)) {
      debugPrint('❌ movePlannedWorkout: New date not in current week');
      return false;
    }

    if (!isDateEditable(newDate)) {
      debugPrint('❌ movePlannedWorkout: Cannot move workout to past date');
      return false;
    }

    try {
      await _client
          .from('planned_workouts')
          .update({'planned_date': newDate.toIso8601String().split('T')[0]})
          .eq('id', workoutId);

      debugPrint('✅ movePlannedWorkout: $workoutId -> ${newDate.toIso8601String().split('T')[0]}');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ movePlannedWorkout error: $e');
      return false;
    }
  }

  /// Déplacer une activité cardio vers un autre jour
  static Future<bool> movePlannedCardio(String activityId, DateTime newDate) async {
    if (!isInCurrentWeek(newDate)) {
      debugPrint('❌ movePlannedCardio: New date not in current week');
      return false;
    }

    if (!isDateEditable(newDate)) {
      debugPrint('❌ movePlannedCardio: Cannot move cardio to past date');
      return false;
    }

    try {
      await _client
          .from('planned_activities')
          .update({'planned_date': newDate.toIso8601String().split('T')[0]})
          .eq('id', activityId);

      debugPrint('✅ movePlannedCardio: $activityId -> ${newDate.toIso8601String().split('T')[0]}');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ movePlannedCardio error: $e');
      return false;
    }
  }

  // =====================================================
  // DELETE
  // =====================================================

  /// Supprimer une activité planifiée
  static Future<bool> deletePlannedActivity(String activityId) async {
    try {
      await _client
          .from('planned_activities')
          .delete()
          .eq('id', activityId);

      debugPrint('✅ deletePlannedActivity: $activityId');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ deletePlannedActivity error: $e');
      return false;
    }
  }

  /// Supprimer un workout planifié
  static Future<bool> deletePlannedWorkout(String workoutId) async {
    try {
      await _client
          .from('planned_workouts')
          .delete()
          .eq('id', workoutId);

      debugPrint('✅ deletePlannedWorkout: $workoutId');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ deletePlannedWorkout error: $e');
      return false;
    }
  }

  /// Supprimer TOUS les workouts planifiés de la semaine en cours
  static Future<bool> deleteAllWorkoutsThisWeek() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final weekStart = getCurrentWeekStart();
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      await _client
          .from('planned_workouts')
          .delete()
          .eq('user_id', userId)
          .gte('planned_date', weekStartStr)
          .lt('planned_date', weekEndStr);

      debugPrint('✅ deleteAllWorkoutsThisWeek: All workouts deleted for week starting $weekStartStr');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ deleteAllWorkoutsThisWeek error: $e');
      return false;
    }
  }

  /// Supprimer toutes les séances CARDIO de la semaine courante
  static Future<bool> deleteAllCardioThisWeek() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final weekStart = getCurrentWeekStart();
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      await _client
          .from('planned_activities')
          .delete()
          .eq('user_id', userId)
          .eq('activity_type', 'cardio')
          .gte('planned_date', weekStartStr)
          .lt('planned_date', weekEndStr);

      debugPrint('✅ deleteAllCardioThisWeek: All cardio deleted for week starting $weekStartStr');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ deleteAllCardioThisWeek error: $e');
      return false;
    }
  }

  // =====================================================
  // GET ALL (pour undo)
  // =====================================================

  /// Récupérer tous les workouts de la semaine courante
  static Future<List<PlannedWorkout>> getAllWorkoutsThisWeek() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final weekStart = getCurrentWeekStart();
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('user_id', userId)
          .gte('planned_date', weekStartStr)
          .lt('planned_date', weekEndStr);

      return (response as List)
          .map((json) => PlannedWorkout.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ getAllWorkoutsThisWeek error: $e');
      return [];
    }
  }

  /// Récupérer tous les cardios de la semaine courante
  static Future<List<PlannedActivity>> getAllCardioThisWeek() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final weekStart = getCurrentWeekStart();
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_activities')
          .select()
          .eq('user_id', userId)
          .eq('activity_type', 'cardio')
          .gte('planned_date', weekStartStr)
          .lt('planned_date', weekEndStr);

      return (response as List)
          .map((json) => PlannedActivity.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ getAllCardioThisWeek error: $e');
      return [];
    }
  }

  // =====================================================
  // RESTORE (pour undo)
  // =====================================================

  /// Restaurer un workout depuis ses données JSON
  static Future<bool> restorePlannedWorkout(Map<String, dynamic> workoutJson) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Recréer le workout avec les données originales (sauf timestamps)
      final insertData = {
        'user_id': userId,
        'planned_date': workoutJson['planned_date'],
        'workout_name': workoutJson['workout_name'],
        'duration_minutes': workoutJson['duration_minutes'],
        'exercises_json': workoutJson['exercises_json'],
        'user_prompt': workoutJson['user_prompt'],
        'status': workoutJson['status'] ?? 'planned',
        'is_ai_generated': workoutJson['is_ai_generated'] ?? true,
      };

      await _client.from('planned_workouts').insert(insertData);

      debugPrint('✅ restorePlannedWorkout: Workout restored');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ restorePlannedWorkout error: $e');
      return false;
    }
  }

  /// Restaurer une activité (cardio) depuis ses données JSON
  static Future<bool> restorePlannedActivity(Map<String, dynamic> activityJson) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Recréer l'activité avec les données originales (sauf timestamps)
      final insertData = {
        'user_id': userId,
        'planned_date': activityJson['planned_date'],
        'activity_type': activityJson['activity_type'],
        'activity_data': activityJson['activity_data'],
        'status': activityJson['status'] ?? 'planned',
        'is_ai_generated': activityJson['is_ai_generated'] ?? true,
      };

      await _client.from('planned_activities').insert(insertData);

      debugPrint('✅ restorePlannedActivity: Activity restored');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ restorePlannedActivity error: $e');
      return false;
    }
  }

  // =====================================================
  // CLEANUP (Reset hebdomadaire)
  // =====================================================

  /// Nettoyer les activités manquées des jours passés
  /// Appelé au lancement de l'app ou chaque lundi 00:01
  static Future<void> cleanupMissedActivities() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      // Marquer les activités passées comme "missed" si elles sont encore "planned"
      await _client
          .from('planned_activities')
          .update({'status': 'missed'})
          .eq('user_id', userId)
          .eq('status', 'planned')
          .lt('planned_date', todayStr);

      // Marquer les workouts passés comme "missed" si ils sont encore "planned"
      await _client
          .from('planned_workouts')
          .update({'status': 'missed'})
          .eq('user_id', userId)
          .eq('status', 'planned')
          .lt('planned_date', todayStr);

      debugPrint('✅ cleanupMissedActivities: Marked past items as missed');

      _invalidateCache();
    } catch (e) {
      debugPrint('❌ cleanupMissedActivities error: $e');
    }
  }

  /// Supprimer toutes les activités de la semaine précédente (reset complet)
  /// Appelé chaque lundi 00:01
  static Future<void> weeklyReset() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final weekStart = getCurrentWeekStart();
      final previousWeekEnd = weekStart.subtract(const Duration(days: 1));
      final previousWeekEndStr = previousWeekEnd.toIso8601String().split('T')[0];

      // Supprimer les activités de la semaine précédente
      await _client
          .from('planned_activities')
          .delete()
          .eq('user_id', userId)
          .lte('planned_date', previousWeekEndStr);

      // Supprimer les workouts de la semaine précédente
      await _client
          .from('planned_workouts')
          .delete()
          .eq('user_id', userId)
          .lte('planned_date', previousWeekEndStr);

      debugPrint('✅ weeklyReset: Deleted previous week items');

      _invalidateCache();
    } catch (e) {
      debugPrint('❌ weeklyReset error: $e');
    }
  }

  // =====================================================
  // SYNC avec food_entries
  // =====================================================

  /// Lier une activité repas planifiée à une food_entry existante
  static Future<bool> linkActivityToFoodEntry(
    String activityId,
    String foodEntryId,
  ) async {
    try {
      await _client
          .from('planned_activities')
          .update({
            'status': 'completed',
            'activity_data': {
              'linked_entry_id': foodEntryId,
            },
          })
          .eq('id', activityId);

      debugPrint('✅ linkActivityToFoodEntry: $activityId -> $foodEntryId');

      _invalidateCache();
      _notifyPlannerUpdate();

      return true;
    } catch (e) {
      debugPrint('❌ linkActivityToFoodEntry error: $e');
      return false;
    }
  }

  /// Trouver une activité repas planifiée pour un type de repas et une date
  static Future<PlannedActivity?> findPlannedMealForDate(
    String mealType,
    DateTime date,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_activities')
          .select()
          .eq('user_id', userId)
          .eq('activity_type', mealType)
          .eq('planned_date', dateStr)
          .eq('status', 'planned')
          .maybeSingle();

      if (response != null) {
        return PlannedActivity.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ findPlannedMealForDate error: $e');
      return null;
    }
  }

  /// Trouver une activité cardio planifiée pour une date
  static Future<PlannedActivity?> findPlannedCardioForDate(
    DateTime date, {
    String? activityType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      var query = _client
          .from('planned_activities')
          .select()
          .eq('user_id', userId)
          .eq('activity_type', 'cardio')
          .eq('planned_date', dateStr)
          .eq('status', 'planned');

      final response = await query.maybeSingle();

      if (response != null) {
        // Si un activityType spécifique est demandé, vérifier dans activity_data
        if (activityType != null) {
          final activityData = response['activity_data'] as Map<String, dynamic>?;
          if (activityData != null && activityData['cardio_type'] != activityType) {
            return null; // Ne correspond pas au type demandé
          }
        }
        return PlannedActivity.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ findPlannedCardioForDate error: $e');
      return null;
    }
  }

  /// Trouver un workout planifié pour une date
  static Future<PlannedWorkout?> findPlannedWorkoutForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .eq('status', 'planned')
          .maybeSingle();

      if (response != null) {
        return PlannedWorkout.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ findPlannedWorkoutForDate error: $e');
      return null;
    }
  }

  /// Trouver un workout planifié par nom ou type pour une date
  /// Si workoutName est fourni, cherche par correspondance partielle (case-insensitive)
  /// Si plusieurs matchent, retourne le premier
  static Future<PlannedWorkout?> findPlannedWorkoutByNameForDate(
    DateTime date, {
    String? workoutName,
    String? workoutType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .eq('status', 'planned');

      final workouts = (response as List)
          .map((json) => PlannedWorkout.fromJson(json))
          .toList();

      if (workouts.isEmpty) return null;

      // Si un seul workout, le retourner
      if (workouts.length == 1) return workouts.first;

      // Chercher par nom ou type (correspondance partielle case-insensitive)
      // Le workoutName contient souvent le type (ex: "Push", "Full Body", "Pecs")
      final searchTerm = workoutName ?? workoutType;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final termLower = searchTerm.toLowerCase();
        for (final w in workouts) {
          if (w.workoutName.toLowerCase().contains(termLower)) {
            return w;
          }
        }
      }

      // Si pas de match, retourner le premier par défaut
      return workouts.first;
    } catch (e) {
      debugPrint('❌ findPlannedWorkoutByNameForDate error: $e');
      return null;
    }
  }

  /// Lister tous les workouts planifiés pour une date
  static Future<List<PlannedWorkout>> listPlannedWorkoutsForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .eq('status', 'planned');

      return (response as List)
          .map((json) => PlannedWorkout.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ listPlannedWorkoutsForDate error: $e');
      return [];
    }
  }

  /// Trouver un cardio planifié par nom d'activité pour une date
  /// Si activityName est fourni, cherche par correspondance partielle (case-insensitive)
  static Future<PlannedActivity?> findPlannedCardioByNameForDate(
    DateTime date, {
    String? activityName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_activities')
          .select()
          .eq('user_id', userId)
          .eq('activity_type', 'cardio')
          .eq('planned_date', dateStr)
          .eq('status', 'planned');

      final cardios = (response as List)
          .map((json) => PlannedActivity.fromJson(json))
          .toList();

      if (cardios.isEmpty) return null;

      // Si un seul cardio, le retourner
      if (cardios.length == 1) return cardios.first;

      // Chercher par nom d'activité (correspondance partielle case-insensitive)
      if (activityName != null && activityName.isNotEmpty) {
        final nameLower = activityName.toLowerCase();
        for (final c in cardios) {
          final cardioName = c.cardioData?.activityName?.toLowerCase() ?? '';
          final cardioKey = c.cardioData?.activityKey?.toLowerCase() ?? '';
          if (cardioName.contains(nameLower) || cardioKey.contains(nameLower)) {
            return c;
          }
        }
      }

      // Si pas de match, retourner le premier par défaut
      return cardios.first;
    } catch (e) {
      debugPrint('❌ findPlannedCardioByNameForDate error: $e');
      return null;
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  /// Invalider le cache
  static void _invalidateCache() {
    _cachedWeekData = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ WeeklyPlannerService: Cache invalidated');
  }

  /// Notifier le GlobalStateManager d'une mise à jour
  static void _notifyPlannerUpdate() {
    // Invalider les données hebdomadaires pour forcer un refresh
    GlobalStateManager.instance.invalidateWeeklyData();
    debugPrint('✅ WeeklyPlannerService: GlobalState notified of planner update');
  }

  /// Récupérer un workout planifié par son ID
  static Future<PlannedWorkout?> getPlannedWorkoutById(String workoutId) async {
    try {
      final response = await _client
          .from('planned_workouts')
          .select()
          .eq('id', workoutId)
          .maybeSingle();

      if (response != null) {
        return PlannedWorkout.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ getPlannedWorkoutById error: $e');
      return null;
    }
  }

  /// Récupérer une activité planifiée par son ID
  static Future<PlannedActivity?> getPlannedActivityById(String activityId) async {
    try {
      final response = await _client
          .from('planned_activities')
          .select()
          .eq('id', activityId)
          .maybeSingle();

      if (response != null) {
        return PlannedActivity.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ getPlannedActivityById error: $e');
      return null;
    }
  }

  /// Vérifier si un workout est déjà planifié pour une date
  static Future<bool> hasWorkoutForDate(DateTime date) async {
    final workout = await findPlannedWorkoutForDate(date);
    return workout != null;
  }

  /// Compter les activités par type pour une date
  static Future<Map<PlannedActivityType, int>> countActivitiesForDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _client
          .from('planned_activities')
          .select('activity_type')
          .eq('user_id', userId)
          .eq('planned_date', dateStr);

      final counts = <PlannedActivityType, int>{};
      for (final row in (response as List)) {
        final type = PlannedActivityTypeExtension.fromString(row['activity_type']);
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('❌ countActivitiesForDate error: $e');
      return {};
    }
  }
}
