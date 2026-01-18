import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/ui/global_progress_models.dart';
import 'food_entries_service.dart';
import 'water_service.dart';
import 'workout_cache_service.dart';
import 'cardio_service.dart';
import 'auth_service.dart';
import 'streak_service.dart';
import 'translations.dart';
import 'localization_service.dart';

/// Service optimisé pour les données de progression avec cache hebdomadaire intelligent
class ProgressServiceV2 {
  static SupabaseClient get _client => Supabase.instance.client;
  
  // Cache hebdomadaire intelligent
  static final Map<String, dynamic> _weeklyCache = {};
  static DateTime? _cacheTimestamp;
  static int? _cachedWeekNumber;
  
  /// Vérifie si le cache est valide pour la semaine courante
  static bool get _isWeeklyCacheValid {
    if (_cacheTimestamp == null || _cachedWeekNumber == null) {
      return false;
    }
    
    final now = DateTime.now();
    final currentWeekNumber = _getWeekNumber(now);
    final currentYear = now.year;
    
    // Vérifier si on est encore dans la même semaine
    final cachedYear = _cacheTimestamp!.year;
    if (currentYear != cachedYear || currentWeekNumber != _cachedWeekNumber) {
      return false;
    }
    
    return true;
  }
  
  /// Calcule le numéro de semaine (1-53) selon la norme ISO 8601
  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.subtract(Duration(days: startOfYear.weekday - 1));
    final difference = date.difference(firstMonday).inDays;
    return (difference / 7).floor() + 1;
  }
  
  /// Calcule quand la semaine courante se termine (dimanche à 23:59:59)
  static DateTime _getEndOfCurrentWeek() {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    return startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
  
  /// Vérifie si on doit rafraîchir le cache (nouvelle semaine, données anciennes, ou si demandé)
  static Future<bool> _shouldRefreshCache({bool forceCheck = false}) async {
    if (!_isWeeklyCacheValid) {
      debugPrint('🔄 Cache invalide : nouvelle semaine détectée');
      return true;
    }
    
    // Rafraîchir si les données ont plus de 2 heures (pour les nouveaux enregistrements)
    if (_cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age.inHours >= 2) {
        debugPrint('🔄 Cache expiré : données de plus de 2h');
        return true;
      }
      
      // Vérification intelligente : si l'utilisateur consulte la page après une activité récente
      if (forceCheck && age.inMinutes >= 1) {
        final hasRecent = await hasRecentActivity();
        if (hasRecent) {
          debugPrint('🔄 Activité récente détectée, rafraîchissement du cache');
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Efface le cache et force un rechargement
  static void forceRefresh() {
    _weeklyCache.clear();
    _cacheTimestamp = null;
    _cachedWeekNumber = null;
    debugPrint('🗑️ Cache hebdomadaire effacé');
  }
  
  /// Force le rafraîchissement après une nouvelle activité
  static void refreshAfterActivity() {
    debugPrint('🔄 Rafraîchissement après nouvelle activité');
    forceRefresh();
  }
  
  /// Méthode publique pour calculer la streak - utilisable par tous les services
  static Future<int> calculateDailyStreak(String userId) async {
    // Utiliser le nouveau service de streak optimisé
    return await StreakService.getCurrentStreak();
  }
  
  /// Vérifie s'il y a une nouvelle activité récente (dernières 10 minutes)
  static Future<bool> hasRecentActivity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    
    try {
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String();
      
      // Vérifier les activités récentes
      final futures = await Future.wait([
        _client.from('cardio_sessions')
            .select('id')
            .eq('user_id', userId)
            .eq('is_completed', true)
            .gt('created_at', tenMinutesAgo)
            .limit(1),
        _client.from('workout_session_summaries')
            .select('id')
            .eq('user_id', userId)
            .gt('created_at', tenMinutesAgo)
            .limit(1),
        _client.from('food_entries')
            .select('id')
            .eq('user_id', userId)
            .gt('created_at', tenMinutesAgo)
            .limit(1),
      ]);
      
      return futures.any((result) => (result as List).isNotEmpty);
    } catch (e) {
      return false;
    }
  }
  
  /// Met à jour le cache avec un timestamp et le numéro de semaine
  static void _updateCacheTimestamp() {
    _cacheTimestamp = DateTime.now();
    _cachedWeekNumber = _getWeekNumber(_cacheTimestamp!);
  }

  /// Récupère le bilan hebdomadaire avec cache intelligent
  static Future<WeeklyBalance> getWeeklyBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return _getEmptyBalance();
    }

    final lang = LocalizationService.instance.currentLanguageCode;
    final cacheKey = 'weekly_balance_${userId}_$lang';
    
    // Vérifier si on doit rafraîchir le cache (avec vérification d'activité récente)
    if (!(await _shouldRefreshCache(forceCheck: true)) && _weeklyCache.containsKey(cacheKey)) {
      debugPrint('✅ Bilan hebdomadaire servi depuis le cache (semaine $_cachedWeekNumber)');
      return _weeklyCache[cacheKey] as WeeklyBalance;
    }

    try {
      debugPrint('🔄 Chargement du bilan hebdomadaire depuis la base...');
      
      // Période de la semaine actuelle (lundi à dimanche)
      final now = DateTime.now();
      final startOfWeek = _getStartOfWeek(now);
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // Récupérer toutes les données en parallèle
      final results = await Future.wait([
        _getNutritionWeeklyData(userId, startOfWeek, endOfWeek),
        _getHydrationWeeklyData(userId, startOfWeek, endOfWeek),
        _getSportWeeklyData(userId, startOfWeek, endOfWeek),
      ]);
      
      final nutritionData = results[0] as Map<String, int>;
      final hydrationData = results[1] as Map<String, int>;
      final sportData = results[2] as Map<String, int>;

      final items = <BalanceItem>[
        BalanceItem(
          icon: LucideIcons.flame,
          label: 'calorie_target_reached'.tr(LocalizationService.instance.currentLanguageCode),
          achieved: nutritionData['calorieTargetDays'] ?? 0,
          target: 7,
          unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
        ),
        BalanceItem(
          icon: LucideIcons.droplet,
          label: 'hydration_validated'.tr(LocalizationService.instance.currentLanguageCode),
          achieved: hydrationData['validatedDays'] ?? 0,
          target: 7,
          unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
        ),
        // MASQUÉ - Repas enregistrés (conservé pour réactivation future)
        // BalanceItem(
        //   icon: LucideIcons.utensils,
        //   label: 'meals_recorded'.tr(LocalizationService.instance.currentLanguageCode),
        //   achieved: nutritionData['totalMeals'] ?? 0,
        //   target: 21, // 3 repas par jour * 7 jours
        //   unit: 'meals'.tr(LocalizationService.instance.currentLanguageCode),
        // ),
        BalanceItem(
          icon: LucideIcons.dumbbell,
          label: 'sport_sessions'.tr(LocalizationService.instance.currentLanguageCode),
          achieved: sportData['completedSessions'] ?? 0,
          target: sportData['plannedSessions'] ?? 4,
          unit: 'sessions'.tr(LocalizationService.instance.currentLanguageCode),
        ),
      ];

      final balance = WeeklyBalance(items: items);
      _weeklyCache[cacheKey] = balance;
      _updateCacheTimestamp();
      debugPrint('✅ Bilan hebdomadaire mis en cache pour la semaine $_cachedWeekNumber');
      return balance;
    } catch (e) {
      debugPrint('❌ Erreur récupération bilan hebdomadaire: $e');
      return _getEmptyBalance();
    }
  }

  /// Récupère les données de tracking hebdomadaire avec cache intelligent
  static Future<List<TrackingDay>> getWeeklyTracking() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return _getEmptyTracking();
    }

    final lang = LocalizationService.instance.currentLanguageCode;
    final cacheKey = 'weekly_tracking_${userId}_$lang';
    if (!(await _shouldRefreshCache(forceCheck: true)) && _weeklyCache.containsKey(cacheKey)) {
      debugPrint('✅ Tracking hebdomadaire servi depuis le cache (semaine $_cachedWeekNumber)');
      return List<TrackingDay>.from(_weeklyCache[cacheKey]);
    }

    try {
      debugPrint('🔄 Chargement du tracking hebdomadaire depuis la base...');
      
      final now = DateTime.now();
      final startOfWeek = _getStartOfWeek(now);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      
      // Récupérer toutes les données d'un coup
      final futures = await Future.wait([
        _client.from('food_entries')
            .select('calories, consumed_at')
            .eq('user_id', userId)
            .gte('consumed_at', startOfWeek.toIso8601String())
            .lt('consumed_at', endOfWeek.toIso8601String()) as Future<List<Map<String, dynamic>>>,
        _client.from('cardio_sessions')
            .select('session_date, activity_type')
            .eq('user_id', userId)
            .eq('is_completed', true)
            .gte('session_date', startOfWeek.toIso8601String().split('T')[0])
            .lt('session_date', endOfWeek.toIso8601String().split('T')[0]) as Future<List<Map<String, dynamic>>>,
        _client.from('workout_session_summaries')
            .select('session_date')
            .eq('user_id', userId)
            .gte('session_date', startOfWeek.toIso8601String().split('T')[0])
            .lt('session_date', endOfWeek.toIso8601String().split('T')[0]) as Future<List<Map<String, dynamic>>>,
      ]);
      
      final userProfile = await _getUserProfileForDate(userId, startOfWeek);
      
      final foodEntries = futures[0] as List;
      final cardioSessions = futures[1] as List;
      final workoutSessions = futures[2] as List;
      final dailyCaloriesGoal = userProfile?['daily_calories'] ?? 2000;

      final List<TrackingDay> trackingDays = [];

      // Générer les 7 jours de la semaine
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dayLabel = _getDayLabel(date.weekday);
        final dateString = date.toIso8601String().split('T')[0];

        // Calculer le score nutrition
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        double dayCalories = 0;
        for (final entry in foodEntries) {
          final consumedAt = DateTime.parse(entry['consumed_at']);
          if (consumedAt.isAfter(startOfDay) && consumedAt.isBefore(endOfDay)) {
            dayCalories += (entry['calories'] as num).toDouble();
          }
        }
        
        TrackingScore nutritionScore;
        if (dailyCaloriesGoal <= 0) {
          nutritionScore = TrackingScore.missed;
        } else {
          final percentage = dayCalories / dailyCaloriesGoal;
          if (percentage >= 0.9) {
            nutritionScore = TrackingScore.achieved;
          } else if (dayCalories > 0) {
            nutritionScore = TrackingScore.partial;
          } else {
            nutritionScore = TrackingScore.missed;
          }
        }

        // Calculer les activités sport
        final activities = <String>[];
        final hasWorkout = workoutSessions.any((s) => s['session_date'] == dateString);
        final hasCardio = cardioSessions.any((s) => s['session_date'] == dateString);
        
        if (hasWorkout) activities.add('musculation');
        if (hasCardio) activities.add('cardio');

        trackingDays.add(TrackingDay(
          dayLabel: dayLabel,
          date: date,
          nutritionScore: nutritionScore,
          sportActivities: activities,
        ));
      }

      _weeklyCache[cacheKey] = trackingDays;
      _updateCacheTimestamp();
      debugPrint('✅ Tracking hebdomadaire mis en cache pour la semaine $_cachedWeekNumber');
      return trackingDays;
    } catch (e) {
      debugPrint('❌ Erreur récupération tracking hebdomadaire: $e');
      return _getEmptyTracking();
    }
  }

  /// Récupère les statistiques d'en-tête avec cache intelligent
  static Future<HeaderStats> getHeaderStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return HeaderStats(
        dailyStreak: '0 ${'days'.tr(LocalizationService.instance.currentLanguageCode)}',
        weeklyObjectives: '0/0 ${'objectives'.tr(LocalizationService.instance.currentLanguageCode)}',
        currentStatus: 'progression'.tr(LocalizationService.instance.currentLanguageCode),
      );
    }

    final lang = LocalizationService.instance.currentLanguageCode;
    final cacheKey = 'header_stats_${userId}_$lang';
    if (!(await _shouldRefreshCache(forceCheck: true)) && _weeklyCache.containsKey(cacheKey)) {
      debugPrint('✅ Stats d\'en-tête servies depuis le cache (semaine $_cachedWeekNumber)');
      return _weeklyCache[cacheKey] as HeaderStats;
    }

    try {
      debugPrint('🔄 Chargement des stats d\'en-tête depuis la base...');
      
      // Récupérer la streak quotidienne avec le service optimisé
      final streak = await StreakService.getCurrentStreak();
      
      // Récupérer les objectifs hebdomadaires
      final objectives = await _getWeeklyObjectives(userId);

      final stats = HeaderStats(
        dailyStreak: '$streak ${'day'.tr(LocalizationService.instance.currentLanguageCode)}${streak > 1 ? 's' : ''}',
        weeklyObjectives: '${objectives['completed']}/${objectives['total']} ${'objectives'.tr(LocalizationService.instance.currentLanguageCode)}',
        currentStatus: 'progression'.tr(LocalizationService.instance.currentLanguageCode), // Nom fixe de la page
      );
      
      _weeklyCache[cacheKey] = stats;
      _updateCacheTimestamp();
      debugPrint('✅ Stats d\'en-tête mises en cache pour la semaine $_cachedWeekNumber');
      return stats;
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques header: $e');
      return HeaderStats(
        dailyStreak: '0 ${'days'.tr(LocalizationService.instance.currentLanguageCode)}',
        weeklyObjectives: '0/0 ${'objectives'.tr(LocalizationService.instance.currentLanguageCode)}',
        currentStatus: 'progression'.tr(LocalizationService.instance.currentLanguageCode),
      );
    }
  }

  /// Récupère les recommandations IA avec cache intelligent
  static Future<List<AIRecommendation>> getAIRecommendations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final lang = LocalizationService.instance.currentLanguageCode;
    final cacheKey = 'ai_recommendations_${userId}_$lang';
    if (!(await _shouldRefreshCache(forceCheck: true)) && _weeklyCache.containsKey(cacheKey)) {
      debugPrint('✅ Recommandations IA servies depuis le cache (semaine $_cachedWeekNumber)');
      return List<AIRecommendation>.from(_weeklyCache[cacheKey]);
    }

    try {
      debugPrint('🔄 Génération des recommandations IA...');
      
      final recommendations = <AIRecommendation>[];
      
      // Analyser les données nutrition des 7 derniers jours
      final nutritionAnalysis = await _analyzeNutritionData(userId);
      
      // Analyser les données sport des 7 derniers jours
      final sportAnalysis = await _analyzeSportData(userId);
      
      // Analyser l'hydratation
      final hydrationAnalysis = await _analyzeHydrationData(userId);

      // Générer les recommandations basées sur l'analyse
      recommendations.addAll(_generateNutritionRecommendations(nutritionAnalysis));
      recommendations.addAll(_generateSportRecommendations(sportAnalysis));
      recommendations.addAll(_generateHydrationRecommendations(hydrationAnalysis));
      recommendations.addAll(_generateGeneralRecommendations(nutritionAnalysis, sportAnalysis));

      // Trier par priorité (priorité la plus élevée en premier)
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));
      
      // Limiter à 4 recommandations maximum
      final finalRecommendations = recommendations.take(4).toList();
      
      _weeklyCache[cacheKey] = finalRecommendations;
      _updateCacheTimestamp();
      debugPrint('✅ Recommandations IA mises en cache pour la semaine $_cachedWeekNumber');
      return finalRecommendations;
    } catch (e) {
      debugPrint('❌ Erreur génération recommandations IA: $e');
      return _getFallbackRecommendations();
    }
  }

  // MÉTHODES PRIVÉES RÉUTILISÉES DE L'ANCIEN SERVICE
  
  /// Calcule le début de la semaine (lundi à 00h00)
  static DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = lundi, 7 = dimanche
    final daysFromMonday = weekday - 1; // 0 pour lundi, 6 pour dimanche
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day); // 00h00 du lundi
  }

  static String _getDayLabel(int weekday) {
    const translationKeys = ['day_l', 'day_m', 'day_m2', 'day_j', 'day_v', 'day_s', 'day_d'];
    return translationKeys[weekday - 1].tr(LocalizationService.instance.currentLanguageCode);
  }

  // Reprendre toutes les méthodes privées de l'ancien service (simplifiées)
  static Future<Map<String, dynamic>?> _getUserProfileForDate(String userId, DateTime date) async {
    try {
      final userResponse = await _client
          .from('users')
          .select('daily_calories, daily_water_goal')
          .eq('id', userId)
          .maybeSingle();
      
      return userResponse;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, int>> _getNutritionWeeklyData(String userId, DateTime start, DateTime end) async {
    final cacheKey = 'nutrition_weekly_${userId}_${_getWeekNumber(start)}';
    if (_isWeeklyCacheValid && _weeklyCache.containsKey(cacheKey)) {
      return Map<String, int>.from(_weeklyCache[cacheKey]);
    }
    
    try {
      final userProfile = await _getUserProfileForDate(userId, start);
      final dailyCaloriesGoal = userProfile?['daily_calories'] ?? 2000;
      
      // Une seule requête pour toute la semaine
      final foodEntriesResponse = await _client
          .from('food_entries')
          .select('calories, meal_id, consumed_at')
          .eq('user_id', userId)
          .gte('consumed_at', start.toIso8601String())
          .lt('consumed_at', end.add(const Duration(days: 1)).toIso8601String());
      
      int calorieTargetDays = 0;
      int totalMeals = 0;
      
      for (int i = 0; i < 7; i++) {
        final currentDay = start.add(Duration(days: i));
        final startOfDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        double dayCalories = 0;
        final uniqueMealIds = <String>{};
        
        for (final entry in foodEntriesResponse) {
          final consumedAt = DateTime.parse(entry['consumed_at']);
          if (consumedAt.isAfter(startOfDay) && consumedAt.isBefore(endOfDay)) {
            dayCalories += (entry['calories'] as num).toDouble();
            
            final mealId = entry['meal_id'] as String?;
            if (mealId != null && mealId.isNotEmpty) {
              uniqueMealIds.add(mealId);
            }
          }
        }
        
        if (dayCalories >= dailyCaloriesGoal * 0.9) {
          calorieTargetDays++;
        }
        totalMeals += uniqueMealIds.length;
      }
      
      final result = {
        'calorieTargetDays': calorieTargetDays,
        'totalMeals': totalMeals,
      };
      
      _weeklyCache[cacheKey] = result;
      return result;
    } catch (e) {
      return {'calorieTargetDays': 0, 'totalMeals': 0};
    }
  }

  static Future<Map<String, int>> _getHydrationWeeklyData(String userId, DateTime start, DateTime end) async {
    final cacheKey = 'hydration_weekly_${userId}_${_getWeekNumber(start)}';
    if (_isWeeklyCacheValid && _weeklyCache.containsKey(cacheKey)) {
      return Map<String, int>.from(_weeklyCache[cacheKey]);
    }
    
    try {
      final userProfile = await _getUserProfileForDate(userId, start);
      final dailyWaterGoal = userProfile?['daily_water_goal'] ?? 2000;
      
      final waterEntriesResponse = await _client
          .from('water_entries')
          .select('amount, consumed_at')
          .eq('user_id', userId)
          .gte('consumed_at', start.toIso8601String())
          .lt('consumed_at', end.add(const Duration(days: 1)).toIso8601String());
      
      int validatedDays = 0;
      
      for (int i = 0; i < 7; i++) {
        final currentDay = start.add(Duration(days: i));
        final startOfDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        double dayWaterMl = 0;
        for (final entry in waterEntriesResponse) {
          final consumedAt = DateTime.parse(entry['consumed_at']);
          if (consumedAt.isAfter(startOfDay) && consumedAt.isBefore(endOfDay)) {
            dayWaterMl += (entry['amount'] as num).toDouble();
          }
        }
        
        if (dayWaterMl >= dailyWaterGoal) {
          validatedDays++;
        }
      }

      final result = {'validatedDays': validatedDays};
      _weeklyCache[cacheKey] = result;
      return result;
    } catch (e) {
      return {'validatedDays': 0};
    }
  }

  static Future<Map<String, int>> _getSportWeeklyData(String userId, DateTime start, DateTime end) async {
    try {
      final workoutSessions = await _getWorkoutSessionsForPeriod(userId, start, end);
      final cardioSessions = await _getCardioSessionsForPeriod(userId, start, end);
      
      final completedSessions = workoutSessions.length + cardioSessions.length;
      const plannedSessions = 4;
      
      return {
        'completedSessions': completedSessions,
        'plannedSessions': plannedSessions,
      };
    } catch (e) {
      return {'completedSessions': 0, 'plannedSessions': 4};
    }
  }

  static Future<List<Map<String, dynamic>>> _getWorkoutSessionsForPeriod(String userId, DateTime start, DateTime end) async {
    try {
      final rows = await _client
          .from('workout_session_summaries')
          .select('*')
          .eq('user_id', userId)
          .gte('session_date', start.toIso8601String().split('T')[0])
          .lte('session_date', end.toIso8601String().split('T')[0])
          .order('session_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getCardioSessionsForPeriod(String userId, DateTime start, DateTime end) async {
    try {
      final rows = await _client
          .from('cardio_sessions')
          .select('*')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .gte('session_date', start.toIso8601String().split('T')[0])
          .lte('session_date', end.toIso8601String().split('T')[0])
          .order('session_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      return [];
    }
  }

  // Note: L'ancienne logique de calcul de streak a été remplacée par StreakService

  static Future<Map<String, int>> _getWeeklyObjectives(String userId) async {
    try {
      final weeklyBalance = await getWeeklyBalance();
      
      int completed = 0;
      int total = weeklyBalance.items.length;
      
      for (final item in weeklyBalance.items) {
        if (item.progress >= 0.8) {
          completed++;
        }
      }
      
      return {'completed': completed, 'total': total};
    } catch (e) {
      return {'completed': 0, 'total': 0};
    }
  }


  // Méthodes d'analyse simplifiées
  static Future<Map<String, dynamic>> _analyzeNutritionData(String userId) async {
    return {
      'avgCalories': 1800.0,
      'avgProteins': 85.0,
      'avgCarbs': 220.0,
      'avgFats': 65.0,
      'consistency': 0.7,
    };
  }

  static Future<Map<String, dynamic>> _analyzeSportData(String userId) async {
    return {
      'workoutCount': 2,
      'cardioCount': 1,
      'totalSessions': 3,
      'consistency': 0.75,
    };
  }

  static Future<Map<String, dynamic>> _analyzeHydrationData(String userId) async {
    return {
      'consistency': 0.8,
      'validDays': 5,
    };
  }

  // Méthodes de génération de recommandations simplifiées
  static List<AIRecommendation> _generateNutritionRecommendations(Map<String, dynamic> analysis) {
    return [
      AIRecommendation(
        message: 'continue_nutrition_efforts'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.nutrition,
        priority: 3,
      ),
    ];
  }

  static List<AIRecommendation> _generateSportRecommendations(Map<String, dynamic> analysis) {
    return [
      AIRecommendation(
        message: 'excellent_rhythm_message'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.sport,
        priority: 4,
      ),
    ];
  }

  static List<AIRecommendation> _generateHydrationRecommendations(Map<String, dynamic> analysis) {
    return [
      AIRecommendation(
        message: 'good_hydration_continue'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.general,
        priority: 2,
      ),
    ];
  }

  static List<AIRecommendation> _generateGeneralRecommendations(Map<String, dynamic> nutritionAnalysis, Map<String, dynamic> sportAnalysis) {
    return [
      AIRecommendation(
        message: 'maintain_good_balance'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.general,
        priority: 3,
      ),
    ];
  }

  // Méthodes de fallback
  static WeeklyBalance _getEmptyBalance() {
    return WeeklyBalance(items: [
      BalanceItem(
        icon: LucideIcons.flame,
        label: 'calorie_target_reached'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 0,
        target: 7,
        unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
      ),
      BalanceItem(
        icon: LucideIcons.droplet,
        label: 'hydration_validated'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 0,
        target: 7,
        unit: 'days'.tr(LocalizationService.instance.currentLanguageCode),
      ),
      // MASQUÉ - Repas enregistrés (conservé pour réactivation future)
      // BalanceItem(
      //   icon: LucideIcons.utensils,
      //   label: 'meals_recorded'.tr(LocalizationService.instance.currentLanguageCode),
      //   achieved: 0,
      //   target: 21,
      //   unit: 'meals'.tr(LocalizationService.instance.currentLanguageCode),
      // ),
      BalanceItem(
        icon: LucideIcons.dumbbell,
        label: 'sport_sessions'.tr(LocalizationService.instance.currentLanguageCode),
        achieved: 0,
        target: 4,
        unit: 'sessions'.tr(LocalizationService.instance.currentLanguageCode),
      ),
    ]);
  }

  static List<TrackingDay> _getEmptyTracking() {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return TrackingDay(
        dayLabel: _getDayLabel(date.weekday),
        date: date,
        nutritionScore: TrackingScore.missed,
        sportActivities: [],
      );
    });
  }

  static List<AIRecommendation> _getFallbackRecommendations() {
    return [
      AIRecommendation(
        message: 'start_recording_meals'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.general,
        priority: 3,
      ),
      AIRecommendation(
        message: 'stay_hydrated_daily'.tr(LocalizationService.instance.currentLanguageCode),
        type: RecommendationType.general,
        priority: 2,
      ),
    ];
  }
}
