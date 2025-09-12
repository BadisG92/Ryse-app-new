import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../config/supabase_config.dart';
import '../components/ui/dashboard_models.dart';
import '../providers/goals_notifier.dart';
import 'progress_service_v2.dart';
import 'streak_service.dart';
import 'sport_dashboard_service.dart';
import 'localization_service.dart';
import 'translations.dart';

class DashboardService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // ==== CACHE DES OBJECTIFS JOURNALIERS ====
  static List<DailyGoal>? _cachedGoals;
  static DateTime? _cachedGoalsDate;
  
  // ==== CACHE DES MODULES PREVIEW ====
  static List<ModulePreview>? _cachedModules;
  static DateTime? _cachedModulesDate;

  /// Vider le cache des objectifs et modules (appelé quand la langue change)
  static void clearGoalsCache() {
    _cachedGoals = null;
    _cachedGoalsDate = null;
    _cachedModules = null;
    _cachedModulesDate = null;
    print('🧹 Cache dashboard vidé');
  }

  /// Forcer la suppression complète du cache
  static void clearAllCache() {
    clearGoalsCache();
  }

  /// Récupérer le profil utilisateur pour le dashboard
  static Future<UserProfile?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('first_name, daily_calories, daily_water_goal')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      // Récupérer les calories consommées aujourd'hui
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final caloriesResponse = await _supabase
          .from('food_entries')
          .select('calories')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());

      double currentCalories = 0;
      for (var entry in caloriesResponse) {
        currentCalories += (entry['calories'] as num).toDouble();
      }

      // Calculer la vraie streak avec le service optimisé
      print('🔥 DashboardService: Calcul de la streak');
      final realStreak = await StreakService.getCurrentStreak();
      print('🏆 DashboardService: Streak calculée = $realStreak jours');

      return UserProfile(
        name: response['first_name'] ?? 'Utilisateur',
        streak: realStreak, // Vraie streak calculée
        todayScore: 85, // TODO: Calculer le vrai score
        todayXP: 250, // TODO: Calculer les vrais XP
        isPremium: false, // TODO: Récupérer le statut premium
        photosUsed: 2, // TODO: Compter les photos utilisées
        dailyCalories: response['daily_calories'] ?? 2000,
        currentCalories: currentCalories.round(),
      );
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  /// Récupérer les objectifs journaliers avec données dynamiques
  static Future<List<DailyGoal>> getDailyGoals() async {
    try {
      final today = DateTime.now();
      // Utiliser le cache du même jour s'il existe
      if (_cachedGoals != null && _cachedGoalsDate != null) {
        final isSameDay = _cachedGoalsDate!.year == today.year &&
            _cachedGoalsDate!.month == today.month &&
            _cachedGoalsDate!.day == today.day;
        if (isSameDay) {
          // Mettre à jour le notifier avec les données en cache
          GoalsNotifier.instance.update(_cachedGoals!);
          return _cachedGoals!;
        }
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        final defaultGoals = DashboardData.dailyGoals;
        GoalsNotifier.instance.update(defaultGoals);
        return defaultGoals;
      }

      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Récupérer les données réelles pour calculer les objectifs
      final foodEntriesResponse = await _supabase
          .from('food_entries')
          .select('calories, meal_id')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());
        
      final waterEntries = await _supabase
          .from('water_entries')
          .select('amount')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());
        
      final userProfile = await _supabase
          .from('users')
          .select('daily_calories, daily_water_goal')
          .eq('id', user.id)
          .maybeSingle();

      // Calculer les totaux du jour
      double currentCalories = 0;
      for (var entry in foodEntriesResponse) {
        currentCalories += (entry['calories'] as num).toDouble();
      }

      // Compter les repas uniques (nombre de meal_id distincts)
      final uniqueMealIds = <String>{};
      for (var entry in foodEntriesResponse) {
        final mealId = entry['meal_id'] as String?;
        if (mealId != null && mealId.isNotEmpty) {
          uniqueMealIds.add(mealId);
        }
      }
      final mealsCount = uniqueMealIds.length;

      double currentWaterMl = 0;
      for (var entry in waterEntries) {
        currentWaterMl += (entry['amount'] as num).toDouble();
      }
      final currentWaterL = currentWaterMl / 1000.0;

      // Objectifs de l'utilisateur (ou valeurs par défaut)
      final dailyCaloriesGoal = userProfile?['daily_calories'] ?? 2000;
      final dailyWaterGoal = (userProfile?['daily_water_goal'] ?? 2000) / 1000.0; // En litres

      // Get language for translations
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      // Créer les objectifs avec les vraies données (avec workout goal)
      final workoutGoal = await _getWorkoutGoal(user.id);
      
      final result = [
        DailyGoal(
          id: 'meals',
          label: 'track_meals_today'.tr(languageCode),
          progress: ((mealsCount / 3) * 100).round(),
          xp: 25,
          completed: mealsCount >= 3,
          currentValue: mealsCount.toDouble(),
          targetValue: 3,
          unit: '',
        ),
        DailyGoal(
          id: 'water',
          label: languageCode == 'fr' 
            ? 'Boire ${dailyWaterGoal.toStringAsFixed(1)}L d\'eau'
            : 'Drink ${dailyWaterGoal.toStringAsFixed(1)}L of water',
          progress: ((currentWaterL / dailyWaterGoal) * 100).round().clamp(0, 100),
          xp: 15,
          completed: currentWaterL >= dailyWaterGoal,
          currentValue: currentWaterL,
          targetValue: dailyWaterGoal,
          unit: 'L',
        ),
        DailyGoal(
          id: 'calories',
          label: 'reach_calorie_goal'.tr(languageCode),
          progress: ((currentCalories / dailyCaloriesGoal) * 100).round().clamp(0, 100),
          xp: 25,
          completed: currentCalories >= dailyCaloriesGoal * 0.9, // 90% = complété
          currentValue: currentCalories,
          targetValue: dailyCaloriesGoal.toDouble(),
          unit: 'kcal',
        ),
        workoutGoal,
      ];

      // Mettre en cache
      _cachedGoals = result;
      _cachedGoalsDate = today;

      // Mettre à jour le notifier avec la liste finale
      GoalsNotifier.instance.update(result);
      print('GoalsNotifier mis à jour avec ${result.length} objectifs');
      for (var goal in result) {
        print('Objectif: ${goal.label}, completed: ${goal.completed}, progress: ${goal.progress}');
      }

      return result;
    } catch (e) {
      print('Erreur lors de la récupération des objectifs: $e');
      final defaultGoals = DashboardData.dailyGoals;
      GoalsNotifier.instance.update(defaultGoals);
      return defaultGoals;
    }
  }

  /// Récupérer les données des modules de prévisualisation
  static Future<List<ModulePreview>> getModulePreviews() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Cache quotidien pour les modules
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      if (_cachedModules != null && _cachedModulesDate?.toIso8601String().split('T')[0] == todayStr) {
        return _cachedModules!;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Récupérer les calories
      final caloriesResponse = await _supabase
          .from('food_entries')
          .select('calories')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());

      double currentCalories = 0;
      for (var entry in caloriesResponse) {
        currentCalories += (entry['calories'] as num).toDouble();
      }

      // Récupérer l'eau
      final waterResponse = await _supabase
          .from('water_entries')
          .select('amount')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());

      double currentWaterMl = 0;
      for (var entry in waterResponse) {
        currentWaterMl += (entry['amount'] as num).toDouble();
      }
      final currentWaterL = currentWaterMl / 1000.0;

      // Get language for translations
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      // Récupérer le module Sport avec vraies données
      final sportModule = await _getSportModulePreview();
      
      final result = [
        ModulePreview(
          title: 'nutrition'.tr(languageCode),
          icon: LucideIcons.apple,
          stats: {
            'calories'.tr(languageCode): '${currentCalories.round()} kcal',
            'water'.tr(languageCode): '${currentWaterL.toStringAsFixed(1)}L',
          },
          gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        sportModule,
      ];
      
      // Mettre en cache
      _cachedModules = result;
      _cachedModulesDate = today;
      
      return result;
    } catch (e) {
      print('Erreur lors de la récupération des aperçus modules: $e');
      return [];
    }
  }

  /// Compter les objectifs atteints pour le compteur
  static Future<int> getCompletedGoalsCount() async {
    final goals = await getDailyGoals();
    return goals.where((goal) => goal.completed).length;
  }

  /// Forcer la mise à jour du compteur d'objectifs (sans cache)
  static Future<void> refreshGoalsNotifier() async {
    print('🔄 Forçage de la mise à jour du GoalsNotifier...');
    
    // Récupérer les objectifs (qui mettra à jour le notifier)
    final goals = await getDailyGoals();
    print('✅ GoalsNotifier mis à jour avec ${goals.length} objectifs');
    
    // Le notifier est déjà mis à jour dans getDailyGoals()
  }

  /// Récupérer l'objectif workout avec les données du dashboard sport
  static Future<DailyGoal> _getWorkoutGoal(String userId) async {
    try {
      // Utiliser les données du dashboard sport (activités du jour)
      final sportData = await SportDashboardService.getDashboardData();
      final totalSessions = sportData.totalTodaySessions;
      final completed = totalSessions >= 1;
      
      print('🏋️ DEBUG Workout Goal (via SportDashboard): $totalSessions séances, completed: $completed');

      // Get language for translations
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      return DailyGoal(
        id: 'workout',
        label: 'complete_workout'.tr(languageCode),
        progress: completed ? 100 : 0,
        xp: 30,
        completed: completed,
        currentValue: totalSessions.toDouble(),
        targetValue: 1,
        unit: '',
      );
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'objectif workout: $e');
      // Get language for translations (fallback)
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      return DailyGoal(
        id: 'workout',
        label: 'complete_workout'.tr(languageCode),
        progress: 0,
        xp: 30,
        completed: false,
        currentValue: 0,
        targetValue: 1,
        unit: '',
      );
    }
  }

  /// Récupérer le module Sport avec les données du dashboard sport
  static Future<ModulePreview> _getSportModulePreview() async {
    try {
      // Get language for translations
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ModulePreview(
          title: 'sport'.tr(languageCode),
          icon: LucideIcons.dumbbell,
          stats: {
            'calories'.tr(languageCode): '0 kcal',
            'sessions'.tr(languageCode): languageCode == 'fr' ? '0 auj.' : '0 today',
          },
          gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
        );
      }

      final today = DateTime.now();
      final todayStr = DateTime(today.year, today.month, today.day).toIso8601String().split('T')[0];
      
      print('📊 DEBUG Module Sport - Récupération DIRECTE pour: ${user.id}, date: $todayStr');

      // Récupérer DIRECTEMENT les mêmes données que le bloc "activité du jour"
      final cardioSessions = await _supabase
          .from('cardio_sessions')
          .select('calories, activity_type, session_date')
          .eq('user_id', user.id)
          .gte('session_date', todayStr)
          .eq('is_completed', true)
          .order('created_at', ascending: false);

      final musculationSessions = await _supabase
          .from('workout_session_summaries')
          .select('calories_burned, session_name, session_date')
          .eq('user_id', user.id)
          .gte('session_date', todayStr)
          .order('created_at', ascending: false);
      
      print('📊 DEBUG Sessions trouvées:');
      print('   - Cardio: ${cardioSessions.length} sessions');
      print('   - Musculation: ${musculationSessions.length} sessions');
      
      // Calculer les calories EXACTEMENT comme le bloc activité du jour
      int totalCalories = 0;
      for (var session in cardioSessions) {
        final calories = (session['calories'] as int?) ?? 0;
        totalCalories += calories;
        print('     -> Cardio ${session['activity_type']} le ${session['session_date']}: ${calories}kcal');
      }
      for (var session in musculationSessions) {
        final calories = (session['calories_burned'] as int?) ?? 0;
        totalCalories += calories;
        print('     -> Musculation ${session['session_name']} le ${session['session_date']}: ${calories}kcal');
      }
      
      final totalSessions = cardioSessions.length + musculationSessions.length;
      
      print('📊 DEBUG Module Sport FINAL: $totalSessions séances, $totalCalories kcal (devrait être 251)');
      print('📊 DEBUG Comparaison: Bloc activité = 251kcal, Module = ${totalCalories}kcal');

      return ModulePreview(
        title: 'sport'.tr(languageCode),
        icon: LucideIcons.dumbbell,
        stats: {
          'calories'.tr(languageCode): '$totalCalories kcal',
          'sessions'.tr(languageCode): languageCode == 'fr' ? '$totalSessions auj.' : '$totalSessions today',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      );
    } catch (e) {
      print('❌ Erreur lors de la récupération du module Sport: $e');
      // Get language for translations (fallback)
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      return ModulePreview(
        title: 'sport'.tr(languageCode),
        icon: LucideIcons.dumbbell,
        stats: {
          'calories'.tr(languageCode): '0 kcal',
          'sessions'.tr(languageCode): languageCode == 'fr' ? '0 auj.' : '0 today',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      );
    }
  }

  /// Invalider le cache et mettre à jour les objectifs en temps réel
  /// Appelé après ajout/suppression de nourriture ou d'eau
  static Future<void> invalidateAndRefreshGoals() async {
    print('🔄 Invalidation du cache et mise à jour des objectifs...');
    
    // Vider le cache pour forcer une nouvelle récupération
    _cachedGoals = null;
    _cachedGoalsDate = null;
    
    // Récupérer les nouvelles données (qui mettra à jour le notifier)
    final goals = await getDailyGoals();
    print('✅ Objectifs mis à jour en temps réel avec ${goals.length} objectifs');
    
    // Afficher le détail pour debug
    for (var goal in goals) {
      print('   - ${goal.label}: ${goal.currentValue}/${goal.targetValue} ${goal.unit} (${goal.progress}%)');
    }
  }
  
  /// Invalider le cache après une séance sport
  /// Appelé après completion d'une séance cardio ou musculation
  static Future<void> invalidateAndRefreshAfterWorkout() async {
    print('🏋️ Invalidation du cache après séance sport...');
    
    // Vider le cache pour forcer une nouvelle récupération
    _cachedGoals = null;
    _cachedGoalsDate = null;
    
    // Invalider aussi le cache du sport dashboard service
    try {
      SportDashboardService.invalidateCache();
      print('🏋️ Cache SportDashboardService invalidé');
    } catch (e) {
      print('⚠️ Erreur lors de l\'invalidation du cache sport: $e');
    }
    
    // Récupérer les nouvelles données
    final goals = await getDailyGoals();
    print('✅ Dashboard mis à jour après séance avec ${goals.length} objectifs');
    
    // Afficher le détail pour debug
    for (var goal in goals) {
      print('   - ${goal.label}: ${goal.currentValue}/${goal.targetValue} ${goal.unit} (${goal.progress}%)');
    }
  }

} 