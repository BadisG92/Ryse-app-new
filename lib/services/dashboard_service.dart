import 'package:flutter/foundation.dart';
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
import 'fast_cache_service.dart';

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
    if (kDebugMode) debugPrint('🧹 Cache dashboard vidé');
  }

  /// Forcer la suppression complète du cache
  static void clearAllCache() {
    clearGoalsCache();
  }

  /// Récupérer le profil utilisateur pour le dashboard
  static Future<UserProfile?> getUserProfile() async {
    try {
      // OPTIMISATION: Cache rapide d'abord
      final cached = FastCacheService.getCachedUserProfile();
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Profil depuis cache rapide');
        return cached;
      }
      
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
      if (kDebugMode) debugPrint('🔥 DashboardService: Calcul de la streak');
      final realStreak = await StreakService.getCurrentStreak();
      if (kDebugMode) debugPrint('🏆 DashboardService: Streak calculée = $realStreak jours');

      // Capitaliser le nom automatiquement
      final rawName = response['first_name'] ?? 'Utilisateur';
      final capitalizedName = rawName.isEmpty ? rawName : rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();

      final profile = UserProfile(
        name: capitalizedName,
        streak: realStreak, // Vraie streak calculée
        todayScore: (realStreak * 10).clamp(0, 100), // Score basé sur la régularité
        isPremium: false, // Sera mis à jour par le provider
        photosUsed: 0, // Sera mis à jour par le provider
        dailyCalories: response['daily_calories'] ?? 2000,
        currentCalories: currentCalories.round(),
      );
      
      // OPTIMISATION: Mettre en cache
      FastCacheService.cacheUserProfile(profile);
      
      return profile;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Variable pour éviter les boucles infinies de rafraîchissement
  static bool _isRefreshingInBackground = false;

  /// Récupérer les objectifs journaliers avec données dynamiques
  static Future<List<DailyGoal>> getDailyGoals() async {
    try {
      // OPTIMISATION: D'abord vérifier le cache ultra-rapide
      final fastCached = FastCacheService.getCachedGoals();
      if (fastCached != null) {
        GoalsNotifier.instance.update(fastCached);
        // debugPrint('⚡ Goals depuis cache rapide'); // Commenté pour réduire les logs

        // Lancer une mise à jour en arrière-plan si le cache a plus de 10s ET si on n'est pas déjà en train de rafraîchir
        if (!_isRefreshingInBackground) {
          _refreshInBackground();
        }
        return fastCached;
      }
      
      final today = DateTime.now();
      // Utiliser le cache du même jour s'il existe
      if (_cachedGoals != null && _cachedGoalsDate != null) {
        final isSameDay = _cachedGoalsDate!.year == today.year &&
            _cachedGoalsDate!.month == today.month &&
            _cachedGoalsDate!.day == today.day;
        if (isSameDay) {
          // Mettre à jour le notifier avec les données en cache
          GoalsNotifier.instance.update(_cachedGoals!);
          FastCacheService.cacheGoals(_cachedGoals!); // Mettre dans le cache rapide
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

      // OPTIMISATION: Paralléliser toutes les requêtes Supabase
      final futures = await Future.wait<dynamic>([
        _supabase
            .from('food_entries')
            .select('calories, meal_id')
            .eq('user_id', user.id)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lt('consumed_at', endOfDay.toIso8601String()),
        
        _supabase
            .from('water_entries')
            .select('amount')
            .eq('user_id', user.id)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lt('consumed_at', endOfDay.toIso8601String()),
        
        _supabase
            .from('users')
            .select('daily_calories, daily_water_goal')
            .eq('id', user.id)
            .maybeSingle(),
      ]);
      
      final foodEntriesResponse = futures[0] as List;
      final waterEntries = futures[1] as List;
      final userProfile = futures[2] as Map<String, dynamic>?;

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
          completed: currentWaterL >= dailyWaterGoal,
          currentValue: currentWaterL,
          targetValue: dailyWaterGoal,
          unit: 'L',
        ),
        DailyGoal(
          id: 'calories',
          label: 'reach_calorie_goal'.tr(languageCode),
          progress: ((currentCalories / dailyCaloriesGoal) * 100).round().clamp(0, 100),
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
      
      // OPTIMISATION: Mettre dans le cache rapide aussi
      FastCacheService.cacheGoals(result);

      // Mettre à jour le notifier avec la liste finale
      GoalsNotifier.instance.update(result);
      if (kDebugMode) debugPrint('GoalsNotifier mis à jour avec ${result.length} objectifs');
      for (var goal in result) {
        if (kDebugMode) debugPrint('Objectif: ${goal.label}, completed: ${goal.completed}, progress: ${goal.progress}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de la récupération des objectifs: $e');
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
      if (kDebugMode) debugPrint('Erreur lors de la récupération des aperçus modules: $e');
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
    if (kDebugMode) debugPrint('🔄 Forçage de la mise à jour du GoalsNotifier...');
    
    // Récupérer les objectifs (qui mettra à jour le notifier)
    final goals = await getDailyGoals();
    if (kDebugMode) debugPrint('✅ GoalsNotifier mis à jour avec ${goals.length} objectifs');
    
    // Le notifier est déjà mis à jour dans getDailyGoals()
  }

  /// Récupérer l'objectif workout avec les données du dashboard sport
  static Future<DailyGoal> _getWorkoutGoal(String userId) async {
    try {
      // Utiliser les données du dashboard sport (activités du jour)
      final sportData = await SportDashboardService.getDashboardData();
      final totalSessions = sportData.totalTodaySessions;
      final completed = totalSessions >= 1;
      
      if (kDebugMode) debugPrint('🏋️ DEBUG Workout Goal (via SportDashboard): $totalSessions séances, completed: $completed');

      // Get language for translations
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      return DailyGoal(
        id: 'workout',
        label: 'complete_workout'.tr(languageCode),
        progress: completed ? 100 : 0,
        completed: completed,
        currentValue: totalSessions.toDouble(),
        targetValue: 1,
        unit: '',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lors de la récupération de l\'objectif workout: $e');
      // Get language for translations (fallback)
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      return DailyGoal(
        id: 'workout',
        label: 'complete_workout'.tr(languageCode),
        progress: 0,
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

      if (kDebugMode) debugPrint('📊 DEBUG Module Sport - Récupération DIRECTE pour: ${user.id}, date: $todayStr');

      // D'abord vérifier TOUTES les séances de l'utilisateur pour debug
      final allCardio = await _supabase
          .from('cardio_sessions')
          .select('session_date, calories')
          .eq('user_id', user.id)
          .eq('is_completed', true)
          .order('session_date', ascending: false)
          .limit(5);

      final allMuscu = await _supabase
          .from('workout_session_summaries')
          .select('session_date, calories_burned')
          .eq('user_id', user.id)
          .order('session_date', ascending: false)
          .limit(5);

      if (kDebugMode) debugPrint('🔍 DEBUG: Dernières 5 séances cardio dans la base:');
      for (var s in allCardio) {
        if (kDebugMode) debugPrint('   -> ${s['session_date']}: ${s['calories']}kcal');
      }
      if (kDebugMode) debugPrint('🔍 DEBUG: Dernières 5 séances muscu dans la base:');
      for (var s in allMuscu) {
        if (kDebugMode) debugPrint('   -> ${s['session_date']}: ${s['calories_burned']}kcal');
      }

      // Récupérer DIRECTEMENT les mêmes données que le bloc "activité du jour"
      // ⚡ FIX: Utiliser .eq() au lieu de .gte() pour chercher uniquement AUJOURD'HUI
      final cardioSessions = await _supabase
          .from('cardio_sessions')
          .select('calories, activity_type, session_date')
          .eq('user_id', user.id)
          .eq('session_date', todayStr)
          .eq('is_completed', true)
          .order('created_at', ascending: false);

      final musculationSessions = await _supabase
          .from('workout_session_summaries')
          .select('calories_burned, session_name, session_date')
          .eq('user_id', user.id)
          .eq('session_date', todayStr)
          .order('created_at', ascending: false);

      if (kDebugMode) debugPrint('📊 DEBUG Sessions trouvées pour TODAY ($todayStr):');
      if (kDebugMode) debugPrint('   - Cardio: ${cardioSessions.length} sessions');
      if (kDebugMode) debugPrint('   - Musculation: ${musculationSessions.length} sessions');
      
      // Calculer les calories EXACTEMENT comme le bloc activité du jour
      int totalCalories = 0;
      for (var session in cardioSessions) {
        final calories = (session['calories'] as int?) ?? 0;
        totalCalories += calories;
        if (kDebugMode) debugPrint('     -> Cardio ${session['activity_type']} le ${session['session_date']}: ${calories}kcal');
      }
      for (var session in musculationSessions) {
        final calories = (session['calories_burned'] as int?) ?? 0;
        totalCalories += calories;
        if (kDebugMode) debugPrint('     -> Musculation ${session['session_name']} le ${session['session_date']}: ${calories}kcal');
      }
      
      final totalSessions = cardioSessions.length + musculationSessions.length;
      
      if (kDebugMode) debugPrint('📊 DEBUG Module Sport FINAL: $totalSessions séances, $totalCalories kcal (devrait être 251)');
      if (kDebugMode) debugPrint('📊 DEBUG Comparaison: Bloc activité = 251kcal, Module = ${totalCalories}kcal');

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
      if (kDebugMode) debugPrint('❌ Erreur lors de la récupération du module Sport: $e');
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

  /// Récupérer les objectifs directement depuis Supabase (sans cache)
  /// Utilisé pour la sync backend optimiste
  static Future<List<DailyGoal>> getDailyGoalsFromSource() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Requête directe Supabase sans cache
      final futures = await Future.wait<dynamic>([
        _supabase.from('food_entries')
            .select('calories, meal_id')
            .eq('user_id', user.id)
            .gte('created_at', DateTime.now().toIso8601String().substring(0, 10)),
        
        _supabase.from('water_entries')
            .select('amount')
            .eq('user_id', user.id)
            .gte('consumed_at', DateTime.now().toIso8601String().substring(0, 10)),
        
        _supabase.from('users')
            .select('daily_calories, daily_water_goal')
            .eq('id', user.id)
            .single(),
        
        _supabase.from('workout_sessions')
            .select('id')
            .eq('user_id', user.id)
            .gte('created_at', DateTime.now().toIso8601String().substring(0, 10))
            .limit(1)
      ]);

      // Traitement des données
      final foodEntries = futures[0] as List;
      final waterEntries = futures[1] as List;  
      final userProfile = futures[2] as Map<String, dynamic>;
      final workoutSessions = futures[3] as List;

      final totalCalories = foodEntries.fold<double>(0, (sum, entry) => sum + (entry['calories'] ?? 0));
      final totalWaterMl = waterEntries.fold<int>(0, (sum, entry) => sum + ((entry['amount'] ?? 0) as int));
      final uniqueMeals = foodEntries.map((e) => e['meal_id']).toSet().length;
      final hasWorkout = workoutSessions.isNotEmpty;

      final targetCalories = (userProfile['daily_calories'] ?? 2000).toDouble();
      final targetWaterL = ((userProfile['daily_water_goal'] ?? 2000) / 1000.0);

      // Obtenir le code langue actuel
      final locService = LocalizationService.instance;
      final languageCode = locService.currentLanguageCode;
      
      // Construire la liste des objectifs directement
      final goals = <DailyGoal>[
        // Objectif calories
        DailyGoal(
          id: 'calories',
          label: 'reach_calorie_goal'.tr(languageCode),
          progress: ((totalCalories / targetCalories) * 100).round().clamp(0, 100),
          completed: totalCalories >= targetCalories * 0.9,
          currentValue: totalCalories,
          targetValue: targetCalories,
          unit: 'kcal',
        ),
        // Objectif eau
        DailyGoal(
          id: 'water',
          label: 'drink_water_goal'.tr(languageCode),
          progress: ((totalWaterMl / 1000.0 / targetWaterL) * 100).round().clamp(0, 100),
          completed: totalWaterMl / 1000.0 >= targetWaterL,
          currentValue: totalWaterMl / 1000.0,
          targetValue: targetWaterL,
          unit: 'L',
        ),
        // Objectif repas
        DailyGoal(
          id: 'meals',
          label: 'track_meals_today'.tr(languageCode),
          progress: ((uniqueMeals / 3) * 100).round().clamp(0, 100),
          completed: uniqueMeals >= 3,
          currentValue: uniqueMeals.toDouble(),
          targetValue: 3,
          unit: 'repas',
        ),
        // Objectif workout
        DailyGoal(
          id: 'workout',
          label: 'complete_workout'.tr(languageCode),
          progress: hasWorkout ? 100 : 0,
          completed: hasWorkout,
          currentValue: hasWorkout ? 1 : 0,
          targetValue: 1,
          unit: 'séance',
        ),
      ];

      return goals;
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur récupération directe objectifs: $e');
      return [];
    }
  }

  /// Invalider le cache et mettre à jour les objectifs en temps réel
  /// Appelé après ajout/suppression de nourriture ou d'eau  
  static Future<void> invalidateAndRefreshGoals() async {
    if (kDebugMode) debugPrint('🔄 Invalidation du cache et mise à jour des objectifs...');
    
    // Vider les caches pour forcer une nouvelle récupération
    _cachedGoals = null;
    _cachedGoalsDate = null;
    FastCacheService.invalidateDashboard();
    
    // Récupérer directement depuis Supabase (plus rapide que getDailyGoals avec cache)
    final goals = await getDailyGoalsFromSource();
    
    // Mettre à jour immédiatement le notifier
    GoalsNotifier.instance.update(goals);
    
    if (kDebugMode) debugPrint('✅ Objectifs mis à jour en temps réel avec ${goals.length} objectifs');
    
    // Afficher le détail pour debug
    for (var goal in goals) {
      if (kDebugMode) debugPrint('   - ${goal.label}: ${goal.currentValue}/${goal.targetValue} ${goal.unit} (${goal.progress}%)');
    }
  }
  
  /// Rafraîchissement en arrière-plan (non-bloquant)
  static void _refreshInBackground() {
    if (_isRefreshingInBackground) return; // Éviter les boucles infinies

    Future.delayed(const Duration(milliseconds: 100), () async {
      _isRefreshingInBackground = true;
      try {
        // debugPrint('🔄 Début rafraîchissement en arrière-plan...'); // Commenté pour réduire les logs

        // Vider uniquement le cache pour forcer une nouvelle récupération
        _cachedGoals = null;
        _cachedGoalsDate = null;
        // Vider aussi le cache rapide en supprimant directement la clé goals

        // Recharger directement depuis la source (sans passer par getDailyGoals pour éviter la boucle)
        final newGoals = await getDailyGoalsFromSource();

        // Mettre en cache les nouvelles données
        _cachedGoals = newGoals;
        _cachedGoalsDate = DateTime.now();
        FastCacheService.cacheGoals(newGoals);

        // Mettre à jour le notifier
        GoalsNotifier.instance.update(newGoals);

        // debugPrint('✅ Données rafraîchies en arrière-plan (${newGoals.length} objectifs)'); // Commenté pour réduire les logs
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Erreur refresh background: $e');
      } finally {
        _isRefreshingInBackground = false;
      }
    });
  }
  
  /// Invalider le cache après une séance sport
  /// Appelé après completion d'une séance cardio ou musculation
  static Future<void> invalidateAndRefreshAfterWorkout() async {
    if (kDebugMode) debugPrint('🏋️ Invalidation du cache après séance sport...');
    
    // Vider le cache pour forcer une nouvelle récupération
    _cachedGoals = null;
    _cachedGoalsDate = null;
    
    // Invalider aussi le cache du sport dashboard service
    try {
      SportDashboardService.invalidateCache();
      if (kDebugMode) debugPrint('🏋️ Cache SportDashboardService invalidé');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur lors de l\'invalidation du cache sport: $e');
    }
    
    // Récupérer les nouvelles données
    final goals = await getDailyGoals();
    if (kDebugMode) debugPrint('✅ Dashboard mis à jour après séance avec ${goals.length} objectifs');
    
    // IMPORTANT: Mettre à jour immédiatement le notifier pour la mise à jour visuelle
    GoalsNotifier.instance.update(goals);
    
    // Afficher le détail pour debug
    for (var goal in goals) {
      if (kDebugMode) debugPrint('   - ${goal.label}: ${goal.currentValue}/${goal.targetValue} ${goal.unit} (${goal.progress}%)');
    }
  }

} 