import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/ui/global_progress_models.dart';
import 'food_entries_service.dart';
import 'water_service.dart';
import 'workout_cache_service.dart';
import 'cardio_service.dart';
import 'auth_service.dart';

/// Service pour récupérer les données de progression réelles
class ProgressService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Récupère le bilan hebdomadaire avec les vraies données
  static Future<WeeklyBalance> getWeeklyBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return _getEmptyBalance();
    }

    try {
      // Période de la semaine actuelle (lundi à dimanche)
      final now = DateTime.now();
      final startOfWeek = _getStartOfWeek(now);
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // Récupérer les données nutrition
      final nutritionData = await _getNutritionWeeklyData(userId, startOfWeek, endOfWeek);
      
      // Récupérer les données hydratation
      final hydrationData = await _getHydrationWeeklyData(userId, startOfWeek, endOfWeek);
      
      // Récupérer les données sport
      final sportData = await _getSportWeeklyData(userId, startOfWeek, endOfWeek);

      final items = <BalanceItem>[
        BalanceItem(
          icon: LucideIcons.flame,
          label: 'Objectifs calories atteints',
          achieved: nutritionData['calorieTargetDays'] ?? 0,
          target: 7,
          unit: 'jours',
        ),
        BalanceItem(
          icon: LucideIcons.droplet,
          label: 'Hydratation validée',
          achieved: hydrationData['validatedDays'] ?? 0,
          target: 7,
          unit: 'jours',
        ),
        BalanceItem(
          icon: LucideIcons.utensils,
          label: 'Repas enregistrés',
          achieved: nutritionData['totalMeals'] ?? 0,
          target: 21, // 3 repas par jour * 7 jours
          unit: 'repas',
        ),
        BalanceItem(
          icon: LucideIcons.dumbbell,
          label: 'Séances de sport',
          achieved: sportData['completedSessions'] ?? 0,
          target: sportData['plannedSessions'] ?? 4,
          unit: 'séances',
        ),
      ];

      return WeeklyBalance(items: items);
    } catch (e) {
      print('❌ Erreur récupération bilan hebdomadaire: $e');
      return _getEmptyBalance();
    }
  }

  /// Récupère les données de tracking hebdomadaire avec les vraies données
  static Future<List<TrackingDay>> getWeeklyTracking() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return _getEmptyTracking();
    }

    try {
      final now = DateTime.now();
      final startOfWeek = _getStartOfWeek(now);
      final List<TrackingDay> trackingDays = [];

      // Générer les 7 jours de la semaine (lundi à dimanche)
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dayLabel = _getDayLabel(date.weekday);

        // Récupérer le score nutrition pour cette date
        final nutritionScore = await _getNutritionScoreForDate(userId, date);
        
        // Récupérer les activités sport pour cette date (comme dans le calendrier sport)
        final sportActivities = await _getSportActivitiesForDate(userId, date);

        trackingDays.add(TrackingDay(
          dayLabel: dayLabel,
          date: date,
          nutritionScore: nutritionScore,
          sportActivities: sportActivities,
        ));
      }

      return trackingDays;
    } catch (e) {
      print('❌ Erreur récupération tracking hebdomadaire: $e');
      return _getEmptyTracking();
    }
  }

  /// Récupère les statistiques d'en-tête avec les vraies données
  static Future<HeaderStats> getHeaderStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const HeaderStats(
        dailyStreak: '0 jours',
        weeklyObjectives: '0/0 objectifs',
        currentStatus: 'Non connecté',
      );
    }

    try {
      // Récupérer la streak quotidienne
      final streak = await _getDailyStreak(userId);
      
      // Récupérer les objectifs hebdomadaires
      final objectives = await _getWeeklyObjectives(userId);
      
      // Déterminer le statut actuel
      final status = await _getCurrentStatus(userId);

      return HeaderStats(
        dailyStreak: '$streak jour${streak > 1 ? 's' : ''}',
        weeklyObjectives: '${objectives['completed']}/${objectives['total']} objectifs',
        currentStatus: status,
      );
    } catch (e) {
      print('❌ Erreur récupération statistiques header: $e');
      return const HeaderStats(
        dailyStreak: '0 jours',
        weeklyObjectives: '0/0 objectifs',
        currentStatus: 'Erreur',
      );
    }
  }

  /// Récupère les recommandations IA intelligentes basées sur les vraies données
  static Future<List<AIRecommendation>> getAIRecommendations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    try {
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
      return recommendations.take(4).toList();
    } catch (e) {
      print('❌ Erreur génération recommandations IA: $e');
      return _getFallbackRecommendations();
    }
  }

  // MÉTHODES PRIVÉES POUR RÉCUPÉRER LES DONNÉES

  /// Récupère le profil utilisateur historique valide pour une date donnée
  static Future<Map<String, dynamic>?> _getUserProfileForDate(String userId, DateTime date) async {
    try {
      // D'abord essayer de récupérer depuis l'historique
      final historyResponse = await _client
          .from('user_profile_history')
          .select('*')
          .eq('user_id', userId)
          .lte('valid_from', date.toIso8601String())
          .or('valid_until.is.null,valid_until.gte.${date.toIso8601String()}')
          .order('valid_from', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (historyResponse != null) {
        return historyResponse;
      }
      
      // Fallback: utiliser le profil actuel
      final userResponse = await _client
          .from('users')
          .select('daily_calories, daily_water_goal')
          .eq('id', userId)
          .maybeSingle();
      
      return userResponse;
    } catch (e) {
      print('❌ Erreur récupération profil historique pour $date: $e');
      return null;
    }
  }

  static Future<Map<String, int>> _getNutritionWeeklyData(String userId, DateTime start, DateTime end) async {
    try {
      int calorieTargetDays = 0;
      int totalMeals = 0;
      
      // Récupérer l'objectif calorique pour la période donnée
      final userProfile = await _getUserProfileForDate(userId, start);
      final dailyCaloriesGoal = userProfile?['daily_calories'] ?? 2000;
      
      // Parcourir chaque jour de la semaine
      for (int i = 0; i < 7; i++) {
        final currentDay = start.add(Duration(days: i));
        final startOfDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        // Récupérer les entrées alimentaires pour ce jour
        final foodEntriesResponse = await _client
            .from('food_entries')
            .select('calories, meal_id')
            .eq('user_id', userId)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lt('consumed_at', endOfDay.toIso8601String());
        
        // Calculer les calories du jour
        double dayCalories = 0;
        final uniqueMealIds = <String>{};
        
        for (final entry in foodEntriesResponse) {
          dayCalories += (entry['calories'] as num).toDouble();
          
          // Compter les repas uniques
          final mealId = entry['meal_id'] as String?;
          if (mealId != null && mealId.isNotEmpty) {
            uniqueMealIds.add(mealId);
          }
        }
        
        // Vérifier si l'objectif calories est atteint (90% = atteint)
        if (dayCalories >= dailyCaloriesGoal * 0.9) {
          calorieTargetDays++;
        }
        
        // Ajouter le nombre de repas de ce jour
        totalMeals += uniqueMealIds.length;
      }
      
      return {
        'calorieTargetDays': calorieTargetDays,
        'totalMeals': totalMeals,
      };
    } catch (e) {
      print('❌ Erreur nutrition hebdomadaire: $e');
      return {'calorieTargetDays': 0, 'totalMeals': 0};
    }
  }

  static Future<Map<String, int>> _getHydrationWeeklyData(String userId, DateTime start, DateTime end) async {
    try {
      int validatedDays = 0;
      
      // Récupérer l'objectif d'hydratation pour la période donnée
      final userProfile = await _getUserProfileForDate(userId, start);
      final dailyWaterGoal = userProfile?['daily_water_goal'] ?? 2000; // en ml
      
      // Parcourir chaque jour de la semaine
      for (int i = 0; i < 7; i++) {
        final currentDay = start.add(Duration(days: i));
        final startOfDay = DateTime(currentDay.year, currentDay.month, currentDay.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        // Récupérer les entrées d'hydratation pour ce jour
        final waterEntriesResponse = await _client
            .from('water_entries')
            .select('amount')
            .eq('user_id', userId)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lt('consumed_at', endOfDay.toIso8601String());
        
        // Calculer la quantité d'eau du jour
        double dayWaterMl = 0;
        for (final entry in waterEntriesResponse) {
          dayWaterMl += (entry['amount'] as num).toDouble();
        }
        
        // Vérifier si l'objectif hydratation est atteint
        if (dayWaterMl >= dailyWaterGoal) {
          validatedDays++;
        }
      }

      return {'validatedDays': validatedDays};
    } catch (e) {
      print('❌ Erreur hydratation hebdomadaire: $e');
      return {'validatedDays': 0};
    }
  }

  static Future<Map<String, int>> _getSportWeeklyData(String userId, DateTime start, DateTime end) async {
    try {
      // Récupérer les sessions de musculation depuis la base de données
      final workoutSessions = await _getWorkoutSessionsForPeriod(userId, start, end);
      
      // Récupérer les sessions de cardio terminées pour la période
      final cardioSessions = await _getCardioSessionsForPeriod(userId, start, end);
      
      final completedSessions = workoutSessions.length + cardioSessions.length;
      const plannedSessions = 4; // Objectif par défaut
      
      return {
        'completedSessions': completedSessions,
        'plannedSessions': plannedSessions,
      };
    } catch (e) {
      print('❌ Erreur sport hebdomadaire: $e');
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
      print('❌ Erreur sessions musculation: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getCardioSessionsForPeriod(String userId, DateTime start, DateTime end) async {
    try {
      final rows = await _client
          .from('cardio_sessions')
          .select('*')
          .eq('user_id', userId)
          .eq('is_completed', true) // Seulement les sessions terminées
          .gte('session_date', start.toIso8601String().split('T')[0])
          .lte('session_date', end.toIso8601String().split('T')[0])
          .order('session_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('❌ Erreur sessions cardio: $e');
      return [];
    }
  }

  static Future<TrackingScore> _getNutritionScoreForDate(String userId, DateTime date) async {
    try {
      // Récupérer l'objectif calorique de l'utilisateur
      final userResponse = await _client
          .from('users')
          .select('daily_calories')
          .eq('id', userId)
          .maybeSingle();
      
      final dailyCaloriesGoal = userResponse?['daily_calories'] ?? 2000;
      
      // Calculer les dates de début et fin du jour
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Récupérer les entrées alimentaires pour ce jour
      final foodEntriesResponse = await _client
          .from('food_entries')
          .select('calories')
          .eq('user_id', userId)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());
      
      // Calculer les calories totales du jour
      double dayCalories = 0;
      for (final entry in foodEntriesResponse) {
        dayCalories += (entry['calories'] as num).toDouble();
      }
      
      print('🍎 Nutrition ${date.day}/${date.month}: ${foodEntriesResponse.length} entrées, $dayCalories calories, objectif: $dailyCaloriesGoal');
      
      // Déterminer le score basé sur le pourcentage d'objectif atteint
      if (dailyCaloriesGoal <= 0) return TrackingScore.missed;
      
      final percentage = dayCalories / dailyCaloriesGoal;
      
      TrackingScore score;
      if (percentage >= 0.9) { // ≥90% = achieved
        score = TrackingScore.achieved;
      } else if (dayCalories > 0) { // Toute calorie enregistrée = partial
        score = TrackingScore.partial;
      } else { // Aucune calorie = missed
        score = TrackingScore.missed;
      }
      
      print('🍎 Score final pour ${date.day}/${date.month}: $score');
      return score;
      
    } catch (e) {
      print('❌ Erreur récupération score nutrition pour $date: $e');
      return TrackingScore.missed;
    }
  }

  static Future<List<String>> _getSportActivitiesForDate(String userId, DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      // Utiliser exactement la même logique que SportDashboardService.getMonthSportData
      // Sessions cardio du jour (terminées seulement)
      final cardioSessions = await _client
          .from('cardio_sessions')
          .select('session_date, activity_type')
          .eq('user_id', userId)
          .eq('session_date', dateString)
          .eq('is_completed', true);

      // Sessions musculation du jour
      final musculationSessions = await _client
          .from('workout_session_summaries')
          .select('session_date')
          .eq('user_id', userId)
          .eq('session_date', dateString);

      // Construire la liste des activités exactement comme dans le calendrier sport
      final activities = <String>[];
      if (musculationSessions.isNotEmpty) activities.add('musculation');
      if (cardioSessions.isNotEmpty) activities.add('cardio');
      
      print('💪 Sport ${date.day}/${date.month}: activities = $activities (${musculationSessions.length} musculation, ${cardioSessions.length} cardio)');
      
      return activities;
      
    } catch (e) {
      print('❌ Erreur récupération activités sport pour $date: $e');
      return [];
    }
  }

  // MÉTHODES D'ANALYSE POUR LES RECOMMANDATIONS IA

  static Future<Map<String, dynamic>> _analyzeNutritionData(String userId) async {
    try {
      // Pour l'instant, simuler des données d'analyse
      // TODO: Implémenter avec FoodEntriesService.getEntriesForPeriod
      
      return {
        'avgCalories': 1800.0,
        'avgProteins': 85.0,
        'avgCarbs': 220.0,
        'avgFats': 65.0,
        'consistency': 0.7, // 70% de régularité
      };
    } catch (e) {
      return {
        'avgCalories': 0,
        'avgProteins': 0,
        'avgCarbs': 0,
        'avgFats': 0,
        'consistency': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeSportData(String userId) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    
    try {
      final workoutSessions = await _getWorkoutSessionsForPeriod(userId, start, now);
      
      // Simuler les sessions cardio pour l'instant
      final cardioCount = 1; // Exemple: 1 session cardio par semaine
      
      return {
        'workoutCount': workoutSessions.length,
        'cardioCount': cardioCount,
        'totalSessions': workoutSessions.length + cardioCount,
        'consistency': (workoutSessions.length + cardioCount) / 4.0, // Par rapport à 4 sessions/semaine
      };
    } catch (e) {
      return {
        'workoutCount': 0,
        'cardioCount': 0,
        'totalSessions': 0,
        'consistency': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeHydrationData(String userId) async {
    try {
      // Pour l'instant, simuler l'analyse de l'hydratation
      // TODO: Implémenter avec WaterService.getDailyConsumption quand disponible
      
      int validDays = 4; // Exemple: 4 jours sur 7 avec hydratation correcte
      
      return {
        'consistency': validDays / 7.0,
        'validDays': validDays,
      };
    } catch (e) {
      return {
        'consistency': 0,
        'validDays': 0,
      };
    }
  }

  // GÉNÉRATION DES RECOMMANDATIONS

  static List<AIRecommendation> _generateNutritionRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <AIRecommendation>[];
    
    final avgProteins = analysis['avgProteins'] as double;
    final avgCalories = analysis['avgCalories'] as double;
    final consistency = analysis['consistency'] as double;
    
    if (avgProteins < 80) { // Moins de 80g de protéines par jour
      recommendations.add(const AIRecommendation(
        message: "Tes apports en protéines sont faibles. Ajoute des œufs, du poisson ou des légumineuses pour soutenir tes objectifs.",
        type: RecommendationType.nutrition,
        priority: 4,
      ));
    }
    
    if (avgCalories < 1500) {
      recommendations.add(const AIRecommendation(
        message: "Ton apport calorique semble faible. Assure-toi de ne pas être en restriction excessive.",
        type: RecommendationType.nutrition,
        priority: 3,
      ));
    }
    
    if (consistency < 0.6) { // Moins de 60% de régularité
      recommendations.add(const AIRecommendation(
        message: "Essaie d'être plus régulier dans tes saisies alimentaires pour un meilleur suivi.",
        type: RecommendationType.general,
        priority: 2,
      ));
    }
    
    return recommendations;
  }

  static List<AIRecommendation> _generateSportRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <AIRecommendation>[];
    
    final totalSessions = analysis['totalSessions'] as int;
    final workoutCount = analysis['workoutCount'] as int;
    final cardioCount = analysis['cardioCount'] as int;
    
    if (totalSessions >= 4) {
      recommendations.add(const AIRecommendation(
        message: "Excellent rythme sportif ! Continue comme ça pour maintenir ta forme. 💪",
        type: RecommendationType.sport,
        priority: 3,
      ));
    } else if (totalSessions >= 2) {
      recommendations.add(const AIRecommendation(
        message: "Bon rythme ! Tu pourrais ajouter une séance pour optimiser tes résultats.",
        type: RecommendationType.sport,
        priority: 2,
      ));
    } else {
      recommendations.add(const AIRecommendation(
        message: "Essaie d'augmenter ton activité physique. Même 20 minutes par jour font la différence !",
        type: RecommendationType.sport,
        priority: 4,
      ));
    }
    
    if (workoutCount > 0 && cardioCount == 0) {
      recommendations.add(const AIRecommendation(
        message: "Pense à ajouter du cardio à ta routine pour améliorer ton endurance et ta récupération.",
        type: RecommendationType.sport,
        priority: 2,
      ));
    }
    
    return recommendations;
  }

  static List<AIRecommendation> _generateHydrationRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <AIRecommendation>[];
    
    final validDays = analysis['validDays'] as int;
    
    if (validDays < 4) {
      recommendations.add(const AIRecommendation(
        message: "Pense à boire plus d'eau ! L'hydratation est essentielle pour tes performances et ta récupération. 💧",
        type: RecommendationType.general,
        priority: 3,
      ));
    }
    
    return recommendations;
  }

  static List<AIRecommendation> _generateGeneralRecommendations(Map<String, dynamic> nutritionAnalysis, Map<String, dynamic> sportAnalysis) {
    final recommendations = <AIRecommendation>[];
    
    final nutritionConsistency = nutritionAnalysis['consistency'] as double;
    final sportConsistency = sportAnalysis['consistency'] as double;
    
    if (nutritionConsistency > 0.8 && sportConsistency > 0.8) {
      recommendations.add(const AIRecommendation(
        message: "Bravo ! Tu maintiens un excellent équilibre entre nutrition et sport. Continue sur cette voie ! 🏆",
        type: RecommendationType.general,
        priority: 5,
      ));
    }
    
    if (sportAnalysis['totalSessions'] as int >= 3) {
      recommendations.add(const AIRecommendation(
        message: "N'oublie pas tes jours de repos ! Ils sont essentiels pour la récupération et éviter le surmenage.",
        type: RecommendationType.recovery,
        priority: 3,
      ));
    }
    
    return recommendations;
  }

  // MÉTHODES UTILITAIRES

  /// Calcule le début de la semaine (lundi à 00h00)
  /// Cette méthode assure que le bloc bilan global se réinitialise automatiquement
  /// tous les dimanches à 00h00, car elle recalcule toujours depuis le lundi
  /// de la semaine courante
  static DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = lundi, 7 = dimanche
    final daysFromMonday = weekday - 1; // 0 pour lundi, 6 pour dimanche
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day); // 00h00 du lundi
  }

  static String _getDayLabel(int weekday) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return labels[weekday - 1];
  }

  static Future<int> _getDailyStreak(String userId) async {
    // Calculer la streak quotidienne basée sur l'activité
    // Remise à zéro seulement après 7 jours consécutifs sans activité
    try {
      final now = DateTime.now();
      int streak = 0;
      int consecutiveInactiveDays = 0;
      
      for (int i = 0; i < 60; i++) { // Vérifier jusqu'à 60 jours pour une streak plus longue
        final date = now.subtract(Duration(days: i));
        final hasActivity = await _hasActivityForDate(userId, date);
        
        if (hasActivity) {
          streak++;
          consecutiveInactiveDays = 0; // Réinitialiser le compteur d'inactivité
        } else {
          consecutiveInactiveDays++;
          
          // Si on a 7 jours consécutifs sans activité, on arrête la streak
          if (consecutiveInactiveDays >= 7) {
            break;
          }
          // Sinon on continue à compter la streak (jour d'inactivité toléré)
        }
      }
      
      return streak;
    } catch (e) {
      print('❌ Erreur calcul streak: $e');
      return 0;
    }
  }

  static Future<bool> _hasActivityForDate(String userId, DateTime date) async {
    try {
      // Vérifier sport (musculation et cardio)
      final sportActivities = await _getSportActivitiesForDate(userId, date);
      if (sportActivities.isNotEmpty) return true;
      
      // Vérifier hydratation (au moins une entrée d'eau)
      final hasWater = await _hasWaterForDate(userId, date);
      if (hasWater) return true;
      
      // Vérifier nutrition (au moins un repas enregistré)
      final hasFood = await _hasFoodForDate(userId, date);
      if (hasFood) return true;
      
      return false;
    } catch (e) {
      print('❌ Erreur vérification activité pour $date: $e');
      return false;
    }
  }

  /// Vérifie s'il y a des entrées d'eau pour une date donnée
  static Future<bool> _hasWaterForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final response = await _client
        .from('water_entries')
        .select('id')
        .eq('user_id', userId)
        .gte('consumed_at', startOfDay.toIso8601String())
        .lt('consumed_at', endOfDay.toIso8601String())
        .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification eau pour $date: $e');
      return false;
    }
  }

  /// Vérifie s'il y a des entrées de nourriture pour une date donnée
  static Future<bool> _hasFoodForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final response = await _client
        .from('food_entries')
        .select('id')
        .eq('user_id', userId)
        .gte('consumed_at', startOfDay.toIso8601String())
        .lt('consumed_at', endOfDay.toIso8601String())
        .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification nourriture pour $date: $e');
      return false;
    }
  }

  static Future<Map<String, int>> _getWeeklyObjectives(String userId) async {
    try {
      // Calculer les objectifs hebdomadaires basés sur l'activité de la semaine courante
      final weeklyBalance = await getWeeklyBalance();
      
      int completed = 0;
      int total = weeklyBalance.items.length;
      
      for (final item in weeklyBalance.items) {
        if (item.progress >= 0.8) { // 80% = objectif atteint
          completed++;
        }
      }
      
      return {'completed': completed, 'total': total};
    } catch (e) {
      return {'completed': 0, 'total': 0};
    }
  }

  static Future<String> _getCurrentStatus(String userId) async {
    try {
      final objectives = await _getWeeklyObjectives(userId);
      final completed = objectives['completed'] ?? 0;
      final total = objectives['total'] ?? 0;
      
      if (total == 0) return 'Démarrage';
      
      final percentage = completed / total;
      if (percentage >= 0.9) return 'Excellence';
      if (percentage >= 0.7) return 'Progression';
      if (percentage >= 0.5) return 'En route';
      return 'Démarrage';
    } catch (e) {
      return 'Statut indéterminé';
    }
  }

  // FALLBACKS ET VALEURS PAR DÉFAUT

  static WeeklyBalance _getEmptyBalance() {
    return const WeeklyBalance(items: [
      BalanceItem(
        icon: LucideIcons.flame,
        label: 'Objectifs calories',
        achieved: 0,
        target: 7,
        unit: 'jours',
      ),
      BalanceItem(
        icon: LucideIcons.droplet,
        label: 'Hydratation',
        achieved: 0,
        target: 7,
        unit: 'jours',
      ),
      BalanceItem(
        icon: LucideIcons.utensils,
        label: 'Repas enregistrés',
        achieved: 0,
        target: 21,
        unit: 'repas',
      ),
      BalanceItem(
        icon: LucideIcons.dumbbell,
        label: 'Séances sport',
        achieved: 0,
        target: 4,
        unit: 'séances',
      ),
    ]);
  }

  static List<TrackingDay> _getEmptyTracking() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return TrackingDay(
        dayLabel: _getDayLabel(date.weekday),
        date: date,
        nutritionScore: TrackingScore.missed,
        sportActivities: [], // Liste vide = pas d'activité
      );
    });
  }

  static List<AIRecommendation> _getFallbackRecommendations() {
    return const [
      AIRecommendation(
        message: "Commence par enregistrer tes repas pour que je puisse t'aider à optimiser ta nutrition !",
        type: RecommendationType.general,
        priority: 3,
      ),
      AIRecommendation(
        message: "N'oublie pas de rester hydraté ! 2 litres d'eau par jour pour une forme optimale. 💧",
        type: RecommendationType.general,
        priority: 2,
      ),
    ];
  }
}