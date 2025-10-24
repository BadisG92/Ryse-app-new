import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cardio_service.dart';
import 'workout_cache_service.dart';
import 'calorie_target_service.dart';
import 'streak_service.dart';
import 'global_state_manager.dart';

/// Service unifié pour les données du tableau de bord Sport
/// Combine les données cardio et musculation
class SportDashboardService {
  static final _client = Supabase.instance.client;
  
  // Cache simple pour éviter les appels répétés
  // OPTIMISATION: Pas de limite de temps - invalidation uniquement par événements
  // (pull-to-refresh, fin de séance, suppression, etc.)
  static Map<String, dynamic>? _cachedData;
  static DateTime? _cacheTimestamp; // Conservé pour les logs uniquement

  /// Récupère toutes les données du dashboard sport
  static Future<SportDashboardData> getDashboardData() async {
    debugPrint('📊 SportDashboardService.getDashboardData() appelé');

    // Vérifier le cache (pas de limite de temps - invalidation par événements uniquement)
    if (_cachedData != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      debugPrint('📊 SportDashboardService: Using cached data (age: ${cacheAge.inSeconds}s)');
      final cachedResult = SportDashboardData.fromJson(_cachedData!);
      debugPrint('📊 SportDashboardService: Cached data - ${cachedResult.totalSessions} sessions, ${cachedResult.totalCalories} kcal');
      return cachedResult;
    }

    debugPrint('📊 SportDashboardService: Fetching fresh data...');

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // OPTIMISATION: Réduire de 4 à 2 requêtes en fusionnant weekly + summary
      final futures = await Future.wait([
        _getWeeklyAndSummaryData(userId), // NOUVEAU: Combine requêtes 1 et 4
        _getDailyActivitiesData(userId),
        _getRecentWorkoutsData(userId),
      ]);

      final weeklyAndSummary = futures[0] as Map<String, dynamic>;
      final data = {
        'weeklyCalories': weeklyAndSummary['weeklyCalories'],
        'dailyActivities': futures[1],
        'recentWorkouts': futures[2],
        'weeklySummary': weeklyAndSummary['weeklySummary'],
      };

      // Mettre en cache
      _cachedData = data;
      _cacheTimestamp = DateTime.now();

      final result = SportDashboardData.fromJson(data);
      debugPrint('📊 SportDashboardService: Data cached - ${result.totalSessions} sessions, ${result.totalCalories} kcal');
      return result;
    } catch (e) {
      debugPrint('❌ Error loading sport dashboard data: $e');
      rethrow;
    }
  }

  /// NOUVEAU: Récupère weekly + summary en une seule passe (évite double appel)
  static Future<Map<String, dynamic>> _getWeeklyAndSummaryData(String userId) async {
    try {
      debugPrint('📊 _getWeeklyAndSummaryData: Récupération combinée weekly + summary...');

      // Récupérer les stats hebdomadaires UNE SEULE FOIS
      final cardioData = await CardioService.getWeeklyStats();
      final musculationData = await WorkoutCacheService.getWeeklyStats(userId);

      // Calculer les totaux
      final totalCalories = cardioData.totalCalories + (musculationData['total_calories'] ?? 0);
      final totalSessions = cardioData.sessionsCount + (musculationData['sessions'] ?? 0);
      final totalDuration = cardioData.totalDuration.inMinutes + (musculationData['total_duration_minutes'] ?? 0);

      debugPrint('📊 _getWeeklyAndSummaryData: TOTAUX - Sessions: $totalSessions, Calories: $totalCalories, Durée: ${totalDuration}min');

      // Calculer la streak sport
      final streak = await _calculateSportWeeklyStreak(userId);

      return {
        'weeklyCalories': {
          'totalCalories': totalCalories,
          'totalSessions': totalSessions,
          'totalDurationMinutes': totalDuration,
          'cardioCalories': cardioData.totalCalories,
          'musculationCalories': musculationData['total_calories'] ?? 0,
          'targetWeeklyCalories': await CalorieTargetService.calculateWeeklyTarget(userId),
        },
        'weeklySummary': {
          'totalSessions': totalSessions,
          'totalCalories': totalCalories,
          'totalDurationMinutes': totalDuration,
          'cardioSessions': cardioData.sessionsCount,
          'musculationSessions': musculationData['sessions'] ?? 0,
          'streak': streak,
        },
      };
    } catch (e) {
      debugPrint('❌ Error loading weekly and summary data: $e');
      return {
        'weeklyCalories': {
          'totalCalories': 0,
          'totalSessions': 0,
          'totalDurationMinutes': 0,
          'cardioCalories': 0,
          'musculationCalories': 0,
          'targetWeeklyCalories': 1500,
        },
        'weeklySummary': {
          'totalSessions': 0,
          'totalCalories': 0,
          'totalDurationMinutes': 0,
          'cardioSessions': 0,
          'musculationSessions': 0,
          'streak': 0,
        },
      };
    }
  }

  /// Récupère les données de calories hebdomadaires (cardio + musculation)
  /// DEPRECATED: Utiliser _getWeeklyAndSummaryData à la place
  static Future<Map<String, dynamic>> _getWeeklyCaloriesData(String userId) async {
    try {
      debugPrint('📊 _getWeeklyCaloriesData: Récupération des données hebdomadaires...');

      // Récupérer les données cardio de la semaine
      debugPrint('📊 _getWeeklyCaloriesData: Récupération cardio...');
      final cardioData = await CardioService.getWeeklyStats();
      debugPrint('📊 _getWeeklyCaloriesData: Cardio récupéré - ${cardioData.sessionsCount} sessions, ${cardioData.totalCalories} kcal');

      // Récupérer les données musculation de la semaine
      debugPrint('📊 _getWeeklyCaloriesData: Récupération musculation...');
      final musculationData = await WorkoutCacheService.getWeeklyStats(userId);
      debugPrint('📊 _getWeeklyCaloriesData: Musculation récupéré - ${musculationData}');

      // Calculer les totaux
      final totalCalories = cardioData.totalCalories + (musculationData['total_calories'] ?? 0);
      final totalSessions = cardioData.sessionsCount + (musculationData['sessions'] ?? 0);
      final totalDuration = cardioData.totalDuration.inMinutes + (musculationData['total_duration_minutes'] ?? 0);

      debugPrint('📊 _getWeeklyCaloriesData: TOTAUX - Sessions: $totalSessions, Calories: $totalCalories, Durée: ${totalDuration}min');

      return {
        'totalCalories': totalCalories,
        'totalSessions': totalSessions,
        'totalDurationMinutes': totalDuration,
        'cardioCalories': cardioData.totalCalories,
        'musculationCalories': musculationData['total_calories'] ?? 0,
        'targetWeeklyCalories': await CalorieTargetService.calculateWeeklyTarget(userId),
      };
    } catch (e) {
      debugPrint('❌ Error loading weekly calories: $e');
      return {
        'totalCalories': 0,
        'totalSessions': 0,
        'totalDurationMinutes': 0,
        'cardioCalories': 0,
        'musculationCalories': 0,
        'targetWeeklyCalories': 1500,
      };
    }
  }

  /// Récupère les activités du jour
  static Future<Map<String, dynamic>> _getDailyActivitiesData(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Sessions cardio du jour
      final cardioSessions = await _client
          .from('cardio_sessions')
          .select()
          .eq('user_id', userId)
          .gte('session_date', startOfDay.toIso8601String().split('T')[0])
          .eq('is_completed', true)
          .order('created_at', ascending: false);
      
      debugPrint('🏋️ DEBUG SportDashboard: ${cardioSessions.length} sessions cardio trouvées');
      for (int i = 0; i < cardioSessions.length; i++) {
        final session = cardioSessions[i];
        debugPrint('   [$i] ID: ${session['id']}, Type: ${session['activity_type']}, Date: ${session['session_date']}, Completed: ${session['is_completed']}');
      }

      // Sessions musculation du jour
      final musculationSessions = await _client
          .from('workout_session_summaries')
          .select()
          .eq('user_id', userId)
          .gte('session_date', startOfDay.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      return {
        'cardioSessions': cardioSessions,
        'musculationSessions': musculationSessions,
        'totalTodaySessions': cardioSessions.length + musculationSessions.length,
      };
    } catch (e) {
      debugPrint('❌ Error loading daily activities: $e');
      return {
        'cardioSessions': [],
        'musculationSessions': [],
        'totalTodaySessions': 0,
      };
    }
  }

  /// Récupère les séances récentes (7 derniers jours)
  static Future<Map<String, dynamic>> _getRecentWorkoutsData(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6)); // 6 jours + aujourd'hui = 7 jours

      debugPrint('📊 _getRecentWorkoutsData: Récupération séances récentes depuis ${sevenDaysAgo.toIso8601String().split('T')[0]}');

      // Sessions cardio récentes
      final recentCardio = await _client
          .from('cardio_sessions')
          .select('session_date, activity_type')
          .eq('user_id', userId)
          .gte('session_date', sevenDaysAgo.toIso8601String().split('T')[0])
          .eq('is_completed', true);

      debugPrint('📊 _getRecentWorkoutsData: ${recentCardio.length} sessions cardio récentes');

      // Sessions musculation récentes
      final recentMusculation = await _client
          .from('workout_session_summaries')
          .select('session_date')
          .eq('user_id', userId)
          .gte('session_date', sevenDaysAgo.toIso8601String().split('T')[0]);

      debugPrint('📊 _getRecentWorkoutsData: ${recentMusculation.length} sessions musculation récentes');

      // Créer la structure des 7 derniers jours (Lundi à Dimanche)
      final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
      final recentDays = <Map<String, dynamic>>[];

      // Trouver le lundi de cette semaine
      final today = DateTime.now();
      final mondayOfWeek = today.subtract(Duration(days: today.weekday - 1));

      for (int i = 0; i < 7; i++) {
        final date = mondayOfWeek.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];
        
        // Vérifier les activités de ce jour
        final cardioOfDay = recentCardio.where((session) => 
          session['session_date'] == dateStr).toList();
        final musculationOfDay = recentMusculation.where((session) => 
          session['session_date'] == dateStr).toList();

        final activities = <String>[];
        if (musculationOfDay.isNotEmpty) activities.add('musculation');
        if (cardioOfDay.isNotEmpty) activities.add('cardio');

        recentDays.add({
          'date': weekDays[i],
          'fullDate': dateStr,
          'hasWorkout': activities.isNotEmpty,
          'activities': activities,
          'cardioTypes': cardioOfDay.map((s) => s['activity_type']).toSet().toList(),
        });
      }

      return {
        'recentDays': recentDays,
      };
    } catch (e) {
      debugPrint('❌ Error loading recent workouts: $e');
      return {
        'recentDays': [],
      };
    }
  }

  /// Récupère le résumé hebdomadaire
  static Future<Map<String, dynamic>> _getWeeklySummaryData(String userId) async {
    try {
      final cardioStats = await CardioService.getWeeklyStats();
      final musculationStats = await WorkoutCacheService.getWeeklyStats(userId);
      
      debugPrint('📊 SportDashboard Weekly Summary:');
      debugPrint('   Cardio: ${cardioStats.sessionsCount} sessions, ${cardioStats.totalCalories} kcal');
      debugPrint('   Musculation: ${musculationStats['sessions'] ?? 0} sessions, ${musculationStats['total_calories'] ?? 0} kcal');
      
      final totalSessions = cardioStats.sessionsCount + (musculationStats['sessions'] ?? 0);
      debugPrint('   Total: $totalSessions sessions');
      
      return {
        'totalSessions': totalSessions,
        'totalCalories': cardioStats.totalCalories + (musculationStats['total_calories'] ?? 0),
        'totalDurationMinutes': cardioStats.totalDuration.inMinutes + (musculationStats['total_duration_minutes'] ?? 0),
        'cardioSessions': cardioStats.sessionsCount,
        'musculationSessions': musculationStats['sessions'] ?? 0,
        'streak': await _calculateSportWeeklyStreak(userId),
      };
    } catch (e) {
      debugPrint('❌ Error loading weekly summary: $e');
      return {
        'totalSessions': 0,
        'totalCalories': 0,
        'totalDurationMinutes': 0,
        'cardioSessions': 0,
        'musculationSessions': 0,
        'streak': 0,
      };
    }
  }

  /// Calcule le nombre de semaines consécutives avec au moins 1 activité sportive
  /// (différent de la streak globale qui compte les jours d'usage de l'app)
  static Future<int> _calculateSportWeeklyStreak(String userId) async {
    try {
      final now = DateTime.now();
      int consecutiveWeeks = 0;
      
      // D'abord vérifier la semaine actuelle
      final currentWeekStart = _getStartOfWeek(now);
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      debugPrint('🔍 Vérification semaine ACTUELLE ${currentWeekStart.toIso8601String().split('T')[0]} -> ${currentWeekEnd.toIso8601String().split('T')[0]}');
      
      final hasCurrentActivity = await _hasAnyActivityInWeek(userId, currentWeekStart, currentWeekEnd);
      
      if (hasCurrentActivity) {
        consecutiveWeeks = 1;
        debugPrint('✅ Activité trouvée cette semaine - Streak commence à: $consecutiveWeeks');
        
        // Continuer avec les semaines précédentes
        for (int i = 1; i <= 52; i++) {
          final weekStart = _getStartOfWeek(now.subtract(Duration(days: i * 7)));
          final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          
          debugPrint('🔍 Vérification semaine ${weekStart.toIso8601String().split('T')[0]} -> ${weekEnd.toIso8601String().split('T')[0]}');
          
          final hasActivity = await _hasAnyActivityInWeek(userId, weekStart, weekEnd);
          
          if (hasActivity) {
            consecutiveWeeks++;
            debugPrint('✅ Activité trouvée - Streak: $consecutiveWeeks');
          } else {
            debugPrint('❌ Pas d\'activité - Arrêt de la streak');
            break;
          }
        }
      } else {
        debugPrint('❌ Pas d\'activité cette semaine - Vérification des semaines précédentes');
        
        // Pas d'activité cette semaine, vérifier les semaines précédentes
        for (int i = 1; i <= 52; i++) {
          final weekStart = _getStartOfWeek(now.subtract(Duration(days: i * 7)));
          final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          
          debugPrint('🔍 Vérification semaine ${weekStart.toIso8601String().split('T')[0]} -> ${weekEnd.toIso8601String().split('T')[0]}');
          
          final hasActivity = await _hasAnyActivityInWeek(userId, weekStart, weekEnd);
          
          if (hasActivity) {
            consecutiveWeeks++;
            debugPrint('✅ Activité trouvée - Streak: $consecutiveWeeks');
          } else {
            debugPrint('❌ Pas d\'activité - Arrêt de la streak');
            break;
          }
        }
      }
      
      debugPrint('🔥 Sport weekly streak: $consecutiveWeeks semaines consécutives avec activité');
      return consecutiveWeeks;
    } catch (e) {
      debugPrint('❌ Error calculating sport weekly streak: $e');
      return 0;
    }
  }

  /// Vérifie s'il y a au moins une activité sportive dans la semaine donnée
  static Future<bool> _hasAnyActivityInWeek(String userId, DateTime weekStart, DateTime weekEnd) async {
    try {
      // Vérifier les séances de musculation
      final workoutResponse = await _client
          .from('workout_session_summaries')
          .select('id')
          .eq('user_id', userId)
          .gte('session_date', weekStart.toIso8601String().split('T')[0])
          .lte('session_date', weekEnd.toIso8601String().split('T')[0])
          .limit(1);
      
      if (workoutResponse.isNotEmpty) {
        return true;
      }

      // Vérifier les séances de cardio
      final cardioResponse = await _client
          .from('cardio_sessions')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte('session_date', weekStart.toIso8601String().split('T')[0])
          .lte('session_date', weekEnd.toIso8601String().split('T')[0])
          .limit(1);
      
      return cardioResponse.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking activity in week: $e');
      return false;
    }
  }

  /// Obtient le début de la semaine (lundi) pour une date donnée
  static DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  // Note: Cette streak sport (semaines consécutives avec activité) est différente de la streak globale StreakService (jours d'usage app)

  /// Invalide le cache
  static void invalidateCache() {
    debugPrint('🔄 SportDashboardService: Cache invalidated');
    _cachedData = null;
    _cacheTimestamp = null;
  }

  /// Force l'invalidation de tous les caches liés
  static void forceInvalidateAllCaches() {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      // Invalider tous les caches
      invalidateCache();
      WorkoutCacheService.invalidateUserCache(userId);
      CardioService.invalidateCache();
      debugPrint('🔄 All caches forcefully invalidated');
    }
  }

  /// Récupère les données des activités du jour depuis le cache
  static Map<String, dynamic> getCachedDailyActivities() {
    if (_cachedData != null) {
      return _cachedData!['dailyActivities'] as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  /// Récupère les données des séances récentes depuis le cache
  static Map<String, dynamic> getCachedRecentWorkouts() {
    if (_cachedData != null) {
      return _cachedData!['recentWorkouts'] as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  /// Récupère les données sportives pour un mois donné
  static Future<Map<String, dynamic>> getMonthSportData(DateTime month) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      // Sessions cardio du mois
      final cardioSessions = await _client
          .from('cardio_sessions')
          .select('session_date, activity_type')
          .eq('user_id', userId)
          .gte('session_date', startOfMonth.toIso8601String().split('T')[0])
          .lte('session_date', endOfMonth.toIso8601String().split('T')[0])
          .eq('is_completed', true);

      // Sessions musculation du mois
      final musculationSessions = await _client
          .from('workout_session_summaries')
          .select('session_date')
          .eq('user_id', userId)
          .gte('session_date', startOfMonth.toIso8601String().split('T')[0])
          .lte('session_date', endOfMonth.toIso8601String().split('T')[0]);

      // Structurer les données par jour
      final monthData = <String, Map<String, dynamic>>{};
      final daysInMonth = endOfMonth.day;

      for (int day = 1; day <= daysInMonth; day++) {
        final dateKey = "${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        
        final cardioOfDay = cardioSessions.where((s) => s['session_date'] == dateKey).toList();
        final musculationOfDay = musculationSessions.where((s) => s['session_date'] == dateKey).toList();

        final activities = <String>[];
        if (musculationOfDay.isNotEmpty) activities.add('musculation');
        if (cardioOfDay.isNotEmpty) activities.add('cardio');

        monthData[dateKey] = {
          'activities': activities,
          'cardioTypes': cardioOfDay.map((s) => s['activity_type']).toSet().toList(),
        };
      }

      // Calculer les stats du mois
      final activeDays = monthData.values.where((day) => 
        (day['activities'] as List).isNotEmpty).length;
      final musculationDays = monthData.values.where((day) => 
        (day['activities'] as List).contains('musculation')).length;
      final cardioDays = monthData.values.where((day) => 
        (day['activities'] as List).contains('cardio')).length;

      return {
        'monthData': monthData,
        'stats': {
          'activeDays': activeDays,
          'musculationDays': musculationDays,
          'cardioDays': cardioDays,
        }
      };
    } catch (e) {
      debugPrint('❌ Error loading month sport data: $e');
      return {
        'monthData': <String, Map<String, dynamic>>{},
        'stats': {
          'activeDays': 0,
          'musculationDays': 0,
          'cardioDays': 0,
        }
      };
    }
  }

  /// Récupère les détails des séances pour un jour spécifique
  static Future<Map<String, dynamic>> getDaySessionDetails(String date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('📅 Récupération des détails pour le $date');

      // Sessions cardio du jour
      final cardioSessions = await _client
          .from('cardio_sessions')
          .select('id, activity_type, activity_title, format_title, duration_seconds, calories, distance_km, intensity, session_date, created_at')
          .eq('user_id', userId)
          .eq('session_date', date)
          .eq('is_completed', true)
          .order('created_at', ascending: false);

      // Sessions musculation du jour
      final musculationSessions = await _client
          .from('workout_session_summaries')
          .select('id, session_name, duration_minutes, calories_burned, session_date, created_at')
          .eq('user_id', userId)
          .eq('session_date', date)
          .order('created_at', ascending: false);

      debugPrint('✅ Trouvé ${cardioSessions.length} sessions cardio et ${musculationSessions.length} sessions musculation');

      return {
        'cardio': cardioSessions,
        'musculation': musculationSessions,
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des détails: $e');
      return {
        'cardio': [],
        'musculation': [],
      };
    }
  }

  /// Supprime une séance de musculation par son ID
  static Future<void> deleteMusculationSession(String sessionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('🗑️ Suppression de la séance de musculation: $sessionId');
      debugPrint('🔍 User ID: $userId');

      // Récupérer le history_session_id depuis la table workout_session_summaries
      final sessionData = await _client
          .from('workout_session_summaries')
          .select('history_session_id, user_id')
          .eq('id', sessionId)
          .maybeSingle();

      debugPrint('🔍 Session data trouvée: $sessionData');

      if (sessionData == null) {
        throw Exception('Session not found - ID: $sessionId does not exist in workout_session_summaries');
      }

      // Vérifier que l'utilisateur est bien le propriétaire
      if (sessionData['user_id'] != userId) {
        throw Exception('Unauthorized - This session belongs to another user');
      }

      final historySessionId = sessionData['history_session_id'] as String;

      // Supprimer d'abord les détails des sets
      await _client
          .from('workout_set_history')
          .delete()
          .eq('history_session_id', historySessionId);

      // Puis supprimer le résumé de la séance
      await _client
          .from('workout_session_summaries')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', userId);

      debugPrint('✅ Séance de musculation supprimée avec succès');

      // Invalider TOUS les caches
      WorkoutCacheService.invalidateUserCache(userId);
      invalidateCache();
      GlobalStateManager.instance.invalidateWeeklyData();

      // Rafraîchir les données sport dans le GlobalState
      await GlobalStateManager.instance.refreshSportData();

      debugPrint('🔄 Caches invalidés et GlobalStateManager rafraîchi');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la séance de musculation: $e');
      rethrow;
    }
  }
}

/// Modèle de données pour le dashboard sport
class SportDashboardData {
  final int totalCalories;
  final int totalSessions;
  final int totalDurationMinutes;
  final int cardioCalories;
  final int musculationCalories;
  final int targetWeeklyCalories;
  final int totalTodaySessions;
  final List<Map<String, dynamic>> recentSessions;
  final int streak;

  const SportDashboardData({
    required this.totalCalories,
    required this.totalSessions,
    required this.totalDurationMinutes,
    required this.cardioCalories,
    required this.musculationCalories,
    required this.targetWeeklyCalories,
    required this.totalTodaySessions,
    required this.recentSessions,
    required this.streak,
  });

  factory SportDashboardData.fromJson(Map<String, dynamic> json) {
    final weeklyCalories = json['weeklyCalories'] as Map<String, dynamic>;
    final dailyActivities = json['dailyActivities'] as Map<String, dynamic>;
    final recentWorkouts = json['recentWorkouts'] as Map<String, dynamic>;
    final weeklySummary = json['weeklySummary'] as Map<String, dynamic>;

    return SportDashboardData(
      totalCalories: weeklySummary['totalCalories'] ?? 0,
      totalSessions: weeklySummary['totalSessions'] ?? 0,
      totalDurationMinutes: weeklySummary['totalDurationMinutes'] ?? 0,
      cardioCalories: weeklyCalories['cardioCalories'] ?? 0,
      musculationCalories: weeklyCalories['musculationCalories'] ?? 0,
      targetWeeklyCalories: weeklyCalories['targetWeeklyCalories'] ?? 2500,
      totalTodaySessions: dailyActivities['totalTodaySessions'] ?? 0,
      recentSessions: List<Map<String, dynamic>>.from(
        recentWorkouts['recentSessions'] ?? []
      ),
      streak: weeklySummary['streak'] ?? 0,
    );
  }

  /// Calcule le pourcentage de progression vers l'objectif
  double get progressPercentage {
    if (targetWeeklyCalories == 0) return 0.0;
    return (totalCalories / targetWeeklyCalories).clamp(0.0, 1.0);
  }

  /// Calcule la moyenne quotidienne
  int get avgDailyCalories => (totalCalories / 7).round();
}
