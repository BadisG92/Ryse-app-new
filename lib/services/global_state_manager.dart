import 'dart:async';
import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';
import 'translations.dart';
import '../components/ui/global_progress_models.dart';

/// Gestionnaire d'état global pour synchronisation instantanée entre pages
/// Résout le problème de latence et de mise à jour non reflétée
class GlobalStateManager {
  static final GlobalStateManager _instance = GlobalStateManager._internal();
  static GlobalStateManager get instance => _instance;

  GlobalStateManager._internal();

  // Event bus pour propagation instantanée des changements
  final _eventController = StreamController<StateChangeEvent>.broadcast();
  Stream<StateChangeEvent> get events => _eventController.stream;

  // Cache global partagé entre TOUTES les pages
  final Map<String, dynamic> _globalCache = {};

  // État nutritionnel global
  double _currentCalories = 0;
  double _currentWaterL = 0;
  int _mealsCount = 0;
  bool _workoutCompleted = false;

  // Ajout des macros pour cohérence avec Supabase
  double _currentProteins = 0;
  double _currentCarbs = 0;
  double _currentFats = 0;

  // État Sport global (ajouté pour bloc Sport de la page d'accueil)
  int _sportSessions = 0;
  int _sportCaloriesBurned = 0;

  // Objectifs utilisateur (pour calcul de progression)
  double _calorieGoal = 2000;
  double _waterGoalL = 2.0;

  // Streak (série de jours consécutifs)
  int _currentStreak = 0;

  // Informations utilisateur
  String _userName = 'User';

  // NOUVEAU: Données hebdomadaires pour GlobalProgress
  WeeklyBalance? _weeklyBalance;
  List<TrackingDay>? _weeklyTracking;
  DateTime? _weeklyDataLastUpdate;
  static const Duration _weeklyDataCacheDuration = Duration(minutes: 5);

  // Gestion du changement de jour et de semaine
  DateTime? _lastCheckedDate;
  Timer? _midnightCheckTimer;

  // Getters - Valeurs actuelles
  double get currentCalories => _currentCalories;
  double get currentWaterL => _currentWaterL;
  int get mealsCount => _mealsCount;
  bool get workoutCompleted => _workoutCompleted;
  double get currentProteins => _currentProteins;
  double get currentCarbs => _currentCarbs;
  double get currentFats => _currentFats;
  int get sportSessions => _sportSessions;
  int get sportCaloriesBurned => _sportCaloriesBurned;

  // Getters - Objectifs
  double get calorieGoal => _calorieGoal;
  double get waterGoalL => _waterGoalL;
  int get currentStreak => _currentStreak;

  // Getters - Informations utilisateur
  String get userName => _userName;
  bool get isPremium => false; // Non utilisé dans l'app

  // Getters - Progression (%)
  double get calorieProgress => _calorieGoal > 0 ? (_currentCalories / _calorieGoal * 100).clamp(0, 100) : 0;
  double get waterProgress => _waterGoalL > 0 ? (_currentWaterL / _waterGoalL * 100).clamp(0, 100) : 0;

  // Getters pour les données hebdomadaires
  WeeklyBalance? get weeklyBalance => _weeklyBalance;
  List<TrackingDay>? get weeklyTracking => _weeklyTracking;

  // Vérifier si les données hebdomadaires sont encore valides
  bool get weeklyDataValid {
    if (_weeklyDataLastUpdate == null) return false;
    final age = DateTime.now().difference(_weeklyDataLastUpdate!);
    return age < _weeklyDataCacheDuration;
  }

  // Mettre à jour les données hebdomadaires
  void updateWeeklyData(WeeklyBalance balance, List<TrackingDay> tracking) {
    _weeklyBalance = balance;
    _weeklyTracking = tracking;
    _weeklyDataLastUpdate = DateTime.now();

    debugPrint('📊 GlobalState: Données hebdomadaires mises en cache');
    debugPrint('   - Balance items: ${balance.items.length}');
    debugPrint('   - Tracking days: ${tracking.length}');
  }

  // Forcer le rafraîchissement des données hebdomadaires
  void invalidateWeeklyData() {
    _weeklyDataLastUpdate = null;
    debugPrint('🔄 GlobalState: Cache hebdomadaire invalidé');
  }

  /// Initialiser avec les données existantes de Supabase
  Future<void> initialize() async {
    debugPrint('🚀 GlobalStateManager: Initialisation DEBUT...');

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;

      debugPrint('🔍 User connecté: ${user?.id ?? "AUCUN"}');

      if (user != null) {
        debugPrint('✅ User trouvé, chargement des données...');
        // Charger les données du jour depuis Supabase
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Requête parallèle pour performance
        final futures = await Future.wait<dynamic>([
          // Récupérer les calories/macros du jour
          client
              .from('food_entries')
              .select('calories, proteins, carbs, fats, meal_id')
              .eq('user_id', user.id)
              .gte('consumed_at', startOfDay.toIso8601String())
              .lt('consumed_at', endOfDay.toIso8601String()),

          // Récupérer l'eau du jour
          client
              .from('water_entries')
              .select('amount')
              .eq('user_id', user.id)
              .gte('consumed_at', startOfDay.toIso8601String())
              .lt('consumed_at', endOfDay.toIso8601String()),

          // Récupérer TOUTES les séances musculation du jour (ID + calories)
          client
              .from('workout_session_summaries')
              .select('history_session_id, calories_burned')
              .eq('user_id', user.id)
              .eq('session_date', startOfDay.toIso8601String().split('T')[0]),

          // Récupérer TOUTES les séances cardio du jour (ID + calories)
          client
              .from('cardio_sessions')
              .select('id, calories')
              .eq('user_id', user.id)
              .eq('is_completed', true)
              .gte('start_time', startOfDay.toIso8601String())
              .lt('start_time', endOfDay.toIso8601String()),

          // Récupérer les objectifs, le streak et le prénom de l'utilisateur
          client
              .from('users')
              .select('daily_calories, daily_water_goal, streak_count, first_name')
              .eq('id', user.id)
              .single(),
        ]);

        // Traiter les résultats des food_entries
        final foodEntries = futures[0] as List;
        double totalCalories = 0;
        double totalProteins = 0;
        double totalCarbs = 0;
        double totalFats = 0;
        final uniqueMealIds = <String>{};

        for (var entry in foodEntries) {
          totalCalories += (entry['calories'] as num?)?.toDouble() ?? 0;
          totalProteins += (entry['proteins'] as num?)?.toDouble() ?? 0;
          totalCarbs += (entry['carbs'] as num?)?.toDouble() ?? 0;
          totalFats += (entry['fats'] as num?)?.toDouble() ?? 0;

          final mealId = entry['meal_id'] as String?;
          if (mealId != null && mealId.isNotEmpty) {
            uniqueMealIds.add(mealId);
          }
        }

        // Traiter les water_entries
        final waterEntries = futures[1] as List;
        double totalWaterMl = 0;
        for (var entry in waterEntries) {
          totalWaterMl += (entry['amount'] as num?)?.toDouble() ?? 0;
        }

        // Traiter workout (musculation + cardio) - avec calories
        final workoutSessions = futures[2] as List;
        final cardioSessions = futures[3] as List;
        final hasWorkout = workoutSessions.isNotEmpty || cardioSessions.isNotEmpty;

        // Compter les séances du jour (musculation + cardio)
        final totalSessions = workoutSessions.length + cardioSessions.length;

        // Calculer les calories brûlées (musculation + cardio)
        int totalCaloriesBurned = 0;
        for (var session in workoutSessions) {
          totalCaloriesBurned += (session['calories_burned'] as num?)?.toInt() ?? 0;
        }
        for (var session in cardioSessions) {
          totalCaloriesBurned += (session['calories'] as num?)?.toInt() ?? 0;
        }

        // Traiter les objectifs, streak et infos utilisateur
        final userProfile = futures[4] as Map<String, dynamic>;

        debugPrint('📝 Profil utilisateur brut: $userProfile');

        final dailyCaloriesGoal = (userProfile['daily_calories'] as num?)?.toDouble() ?? 2000;
        final dailyWaterGoalMl = (userProfile['daily_water_goal'] as num?)?.toDouble() ?? 2000;
        final streakCount = (userProfile['streak_count'] as num?)?.toInt() ?? 0;
        final name = userProfile['first_name'] as String? ?? user.email?.split('@').first ?? 'User';

        debugPrint('📊 Valeurs extraites:');
        debugPrint('   - dailyCaloriesGoal: $dailyCaloriesGoal (brut: ${userProfile['daily_calories']})');
        debugPrint('   - dailyWaterGoalMl: $dailyWaterGoalMl (brut: ${userProfile['daily_water_goal']})');
        debugPrint('   - streakCount: $streakCount');
        debugPrint('   - name: $name');

        // Mettre à jour l'état global
        _currentCalories = totalCalories;
        _currentProteins = totalProteins;
        _currentCarbs = totalCarbs;
        _currentFats = totalFats;
        _currentWaterL = totalWaterMl / 1000.0;
        _mealsCount = uniqueMealIds.length;
        _workoutCompleted = hasWorkout;
        _sportSessions = totalSessions;
        _sportCaloriesBurned = totalCaloriesBurned;

        // Mettre à jour les objectifs et infos utilisateur
        _calorieGoal = dailyCaloriesGoal;
        _waterGoalL = dailyWaterGoalMl / 1000.0;
        _currentStreak = streakCount;
        _userName = name;

        debugPrint('✅ GlobalState initialisé:');
        debugPrint('   👤 Nom: $_userName');
        debugPrint('   📊 ${_currentCalories.toInt()}/${_calorieGoal.toInt()} kcal (${calorieProgress.toInt()}%)');
        debugPrint('   💧 ${_currentWaterL.toStringAsFixed(1)}L/${_waterGoalL.toStringAsFixed(1)}L (${waterProgress.toInt()}%)');
        debugPrint('   🍽️  $_mealsCount repas');
        debugPrint('   🏋️ Sport: ${_workoutCompleted ? "✅" : "❌"} ($_sportSessions séances, $totalCaloriesBurned kcal)');
        debugPrint('   🔥 Streak: $_currentStreak jours');
      } else {
        debugPrint('⚠️ AUCUN utilisateur connecté - GlobalState pas initialisé');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ GlobalStateManager init error (non-critique): $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue sans les données, elles seront chargées par les pages
    }

    debugPrint('🏁 GlobalStateManager: Initialisation TERMINEE');

    // Démarrer la vérification du changement de jour
    _startMidnightCheck();
    _lastCheckedDate = DateTime.now();
  }

  /// Démarrer la vérification périodique du changement de jour
  void _startMidnightCheck() {
    // Annuler le timer précédent s'il existe
    _midnightCheckTimer?.cancel();

    // Calculer le temps jusqu'à minuit
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = midnight.difference(now);

    debugPrint('⏰ GlobalState: Prochain check à minuit dans ${timeUntilMidnight.inMinutes} minutes');

    // Timer pour minuit
    _midnightCheckTimer = Timer(timeUntilMidnight, () {
      _checkDayChange();

      // Ensuite vérifier toutes les minutes pour détecter les changements d'app
      _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _checkDayChange();
      });
    });
  }

  /// Vérifier si on a changé de jour ou de semaine
  void _checkDayChange() {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);

    if (_lastCheckedDate != null) {
      final lastDay = DateTime(_lastCheckedDate!.year, _lastCheckedDate!.month, _lastCheckedDate!.day);

      // Si on a changé de jour
      if (currentDay.isAfter(lastDay)) {
        debugPrint('🌙 GlobalState: Nouveau jour détecté! Réinitialisation des données journalières...');

        // Vérifier si c'est lundi (changement de semaine)
        if (now.weekday == DateTime.monday) {
          debugPrint('📅 GlobalState: Nouveau lundi détecté! Réinitialisation des données hebdomadaires...');
          _resetWeeklyData();
        }

        // Réinitialiser les données journalières
        _resetDailyData();

        // Recharger les données depuis Supabase pour le nouveau jour
        initialize();
      }
    }

    _lastCheckedDate = now;
  }

  /// Réinitialiser les données journalières
  void _resetDailyData() {
    // Réinitialiser toutes les valeurs journalières
    _currentCalories = 0;
    _currentProteins = 0;
    _currentCarbs = 0;
    _currentFats = 0;
    _currentWaterL = 0;
    _mealsCount = 0;
    _workoutCompleted = false;
    _sportSessions = 0;
    _sportCaloriesBurned = 0;

    // Notifier tous les listeners
    _notifyChange(StateChangeEvent(
      type: ChangeType.dayReset,
      value: DateTime.now(),
    ));

    debugPrint('✨ GlobalState: Données journalières réinitialisées à 0');
  }

  /// Réinitialiser les données hebdomadaires
  void _resetWeeklyData() {
    _weeklyBalance = null;
    _weeklyTracking = null;
    _weeklyDataLastUpdate = null;

    debugPrint('✨ GlobalState: Données hebdomadaires réinitialisées');
  }


  /// MISE À JOUR INSTANTANÉE - Eau
  void updateWater(double deltaLiters, {bool isAbsolute = false}) {
    if (isAbsolute) {
      _currentWaterL = deltaLiters;
    } else {
      _currentWaterL += deltaLiters;
    }

    _notifyChange(StateChangeEvent(
      type: ChangeType.water,
      value: _currentWaterL,
    ));

    debugPrint('💧 GlobalState: Eau mise à jour -> ${_currentWaterL}L');
  }

  /// MISE À JOUR INSTANTANÉE - Calories et macros
  void updateCalories(double deltaCalories, {bool isAbsolute = false}) {
    if (isAbsolute) {
      _currentCalories = deltaCalories;
    } else {
      _currentCalories += deltaCalories;
    }

    _notifyChange(StateChangeEvent(
      type: ChangeType.calories,
      value: _currentCalories,
    ));

    debugPrint('🍎 GlobalState: Calories mises à jour -> ${_currentCalories}kcal');
  }

  /// MISE À JOUR INSTANTANÉE - Macronutriments
  void updateMacros({
    double? proteins,
    double? carbs,
    double? fats,
    bool isAbsolute = false,
  }) {
    if (proteins != null) {
      _currentProteins = isAbsolute ? proteins : _currentProteins + proteins;
    }
    if (carbs != null) {
      _currentCarbs = isAbsolute ? carbs : _currentCarbs + carbs;
    }
    if (fats != null) {
      _currentFats = isAbsolute ? fats : _currentFats + fats;
    }

    _notifyChange(StateChangeEvent(
      type: ChangeType.macros,
      value: {
        'proteins': _currentProteins,
        'carbs': _currentCarbs,
        'fats': _currentFats,
      },
    ));

    debugPrint('🥩 GlobalState: Macros mis à jour -> P:${_currentProteins}g C:${_currentCarbs}g F:${_currentFats}g');
  }

  /// MISE À JOUR INSTANTANÉE - Repas
  void updateMeals(int count, {bool isAbsolute = false}) {
    if (isAbsolute) {
      _mealsCount = count;
    } else {
      _mealsCount += count;
    }

    _notifyChange(StateChangeEvent(
      type: ChangeType.meals,
      value: _mealsCount,
    ));

    debugPrint('🍽️ GlobalState: Repas mis à jour -> $_mealsCount');
  }

  /// MISE À JOUR INSTANTANÉE - Workout
  void updateWorkout(bool completed) {
    _workoutCompleted = completed;

    _notifyChange(StateChangeEvent(
      type: ChangeType.workout,
      value: _workoutCompleted,
    ));

    debugPrint('🏋️ GlobalState: Workout mis à jour -> $_workoutCompleted');
  }

  /// MISE À JOUR INSTANTANÉE - Données Sport (séances + calories brûlées)
  void updateSportData({int? sessions, int? caloriesBurned, bool? isAbsolute}) {
    final absolute = isAbsolute ?? false;

    if (sessions != null) {
      _sportSessions = absolute ? sessions : _sportSessions + sessions;
    }
    if (caloriesBurned != null) {
      _sportCaloriesBurned = absolute ? caloriesBurned : _sportCaloriesBurned + caloriesBurned;
    }

    // Mettre à jour aussi workoutCompleted si on a des séances
    if (_sportSessions > 0) {
      _workoutCompleted = true;
    }

    _notifyChange(StateChangeEvent(
      type: ChangeType.sport,
      value: {
        'sessions': _sportSessions,
        'caloriesBurned': _sportCaloriesBurned,
      },
    ));

    debugPrint('🏋️ GlobalState: Sport mis à jour -> $_sportSessions séances, $_sportCaloriesBurned kcal');
  }

  /// RECOMPTE INSTANTANÉ - Recharge TOUTES les données Sport du jour depuis la base
  Future<void> refreshSportData() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Récupérer TOUTES les séances du jour en parallèle
      final futures = await Future.wait([
        // Séances musculation
        client
            .from('workout_session_summaries')
            .select('calories_burned')
            .eq('user_id', user.id)
            .eq('session_date', startOfDay.toIso8601String().split('T')[0]),

        // Séances cardio
        client
            .from('cardio_sessions')
            .select('calories')
            .eq('user_id', user.id)
            .eq('is_completed', true)
            .gte('start_time', startOfDay.toIso8601String())
            .lt('start_time', endOfDay.toIso8601String()),
      ]);

      final workoutSessions = futures[0] as List;
      final cardioSessions = futures[1] as List;

      debugPrint('🔍 DEBUG refreshSportData:');
      debugPrint('   - Séances musculation trouvées: ${workoutSessions.length}');
      debugPrint('   - Séances cardio trouvées: ${cardioSessions.length}');
      debugPrint('   - Date recherchée: ${startOfDay.toIso8601String().split('T')[0]}');

      // Compter les séances
      final totalSessions = workoutSessions.length + cardioSessions.length;

      // Calculer les calories brûlées
      int totalCalories = 0;
      for (var session in workoutSessions) {
        final cals = (session['calories_burned'] as num?)?.toInt() ?? 0;
        totalCalories += cals;
        debugPrint('   - Musculation: $cals kcal');
      }
      for (var session in cardioSessions) {
        final cals = (session['calories'] as num?)?.toInt() ?? 0;
        totalCalories += cals;
        debugPrint('   - Cardio: $cals kcal');
      }

      debugPrint('   - TOTAL: $totalSessions séances, $totalCalories kcal');

      // Mettre à jour avec les valeurs absolues
      _sportSessions = totalSessions;
      _sportCaloriesBurned = totalCalories;
      _workoutCompleted = totalSessions > 0;

      _notifyChange(StateChangeEvent(
        type: ChangeType.sport,
        value: {
          'sessions': _sportSessions,
          'caloriesBurned': _sportCaloriesBurned,
        },
      ));

      debugPrint('🔄 GlobalState: Sport rechargé depuis DB -> $_sportSessions séances, $_sportCaloriesBurned kcal');
    } catch (e) {
      debugPrint('❌ Erreur refresh sport data: $e');
    }
  }

  /// MISE À JOUR INSTANTANÉE - Streak
  void updateStreak(int newStreak) {
    _currentStreak = newStreak;

    _notifyChange(StateChangeEvent(
      type: ChangeType.streak,
      value: _currentStreak,
    ));

    debugPrint('🔥 GlobalState: Streak mis à jour -> $_currentStreak jours');
  }

  /// MISE À JOUR INSTANTANÉE - Objectifs (si l'utilisateur change ses paramètres)
  void updateGoals({double? calorieGoal, double? waterGoalL}) {
    if (calorieGoal != null) _calorieGoal = calorieGoal;
    if (waterGoalL != null) _waterGoalL = waterGoalL;

    _notifyChange(StateChangeEvent(
      type: ChangeType.goals,
      value: {
        'calorieGoal': _calorieGoal,
        'waterGoalL': _waterGoalL,
      },
    ));

    debugPrint('🎯 GlobalState: Objectifs mis à jour -> ${_calorieGoal.toInt()}kcal, ${_waterGoalL.toStringAsFixed(1)}L');
  }

  /// RECOMPTE INSTANTANÉ - Repas uniques du jour depuis la base
  Future<void> refreshMealsCount() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final foodEntries = await SupabaseConfig.client
          .from('food_entries')
          .select('meal_id')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lt('consumed_at', endOfDay.toIso8601String());

      final uniqueMealIds = <String>{};
      for (var entry in foodEntries) {
        final mealId = entry['meal_id'] as String?;
        if (mealId != null && mealId.isNotEmpty) {
          uniqueMealIds.add(mealId);
        }
      }

      _mealsCount = uniqueMealIds.length;
      _notifyChange(StateChangeEvent(
        type: ChangeType.meals,
        value: _mealsCount,
      ));

      debugPrint('🍽️ GlobalState: Repas recomptés depuis la base -> $_mealsCount');
    } catch (e) {
      debugPrint('❌ Erreur refresh meals count: $e');
    }
  }

  /// MISE À JOUR INSTANTANÉE - Multiple
  void batchUpdate({
    double? calories,
    double? water,
    int? meals,
    bool? workout,
  }) {
    if (calories != null) _currentCalories = calories;
    if (water != null) _currentWaterL = water;
    if (meals != null) _mealsCount = meals;
    if (workout != null) _workoutCompleted = workout;

    _notifyChange(StateChangeEvent(
      type: ChangeType.batch,
      value: {
        'calories': _currentCalories,
        'water': _currentWaterL,
        'meals': _mealsCount,
        'workout': _workoutCompleted,
      },
    ));

    debugPrint('📊 GlobalState: Batch update effectué');
  }

  /// Cache une donnée pour accès rapide
  void cacheData(String key, dynamic value) {
    _globalCache[key] = value;
  }

  /// Récupère une donnée cachée
  T? getCachedData<T>(String key) {
    return _globalCache[key] as T?;
  }

  /// Génère les DailyGoals à partir des données GlobalState (pour compatibilité dashboard)
  List<dynamic> getDailyGoalsForDashboard() {
    // Import dynamique pour éviter les dépendances circulaires
    // On retourne une liste de Maps que le dashboard peut convertir en DailyGoal
    final languageCode = LocalizationService.instance.currentLanguageCode;

    debugPrint('📋 getDailyGoalsForDashboard() - État actuel:');
    debugPrint('   Calories: $_currentCalories / $_calorieGoal kcal');
    debugPrint('   Eau: $_currentWaterL / $_waterGoalL L');
    debugPrint('   Repas: $_mealsCount');
    debugPrint('   Séances sport: $_sportSessions');

    return [
      {
        'id': 'calories',
        'label': 'goal_calories'.tr(languageCode),
        'progress': calorieProgress.toInt(),
        'xp': 50,
        'completed': calorieProgress >= 100,
        'currentValue': _currentCalories,
        'targetValue': _calorieGoal,
        'unit': 'kcal',
      },
      {
        'id': 'water',
        'label': 'goal_water'.tr(languageCode),
        'progress': waterProgress.toInt(),
        'xp': 30,
        'completed': waterProgress >= 100,
        'currentValue': _currentWaterL,
        'targetValue': _waterGoalL,
        'unit': 'L',
      },
      {
        'id': 'meals',
        'label': 'goal_meals'.tr(languageCode),
        'progress': (_mealsCount >= 3) ? 100 : (_mealsCount * 33),
        'xp': 40,
        'completed': _mealsCount >= 3,
        'currentValue': _mealsCount.toDouble(),
        'targetValue': 3.0,
        'unit': languageCode == 'fr' ? 'repas' : 'meals',
      },
      {
        'id': 'workout',
        'label': 'goal_sport'.tr(languageCode),
        'progress': _sportSessions >= 1 ? 100 : 0,
        'xp': 60,
        'completed': _sportSessions >= 1,
        'currentValue': _sportSessions.toDouble(),
        'targetValue': 1.0,
        'unit': languageCode == 'fr' ? (_sportSessions <= 1 ? 'séance' : 'séances') : (_sportSessions <= 1 ? 'session' : 'sessions'),
      },
    ];
  }

  /// Notifie tous les listeners d'un changement
  void _notifyChange(StateChangeEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _midnightCheckTimer?.cancel();
    _eventController.close();
  }
}

/// Événement de changement d'état
class StateChangeEvent {
  final ChangeType type;
  final dynamic value;
  final DateTime timestamp;

  StateChangeEvent({
    required this.type,
    required this.value,
  }) : timestamp = DateTime.now();
}

/// Types de changements
enum ChangeType {
  water,
  calories,
  meals,
  workout,
  sport,
  macros,
  streak,
  goals,
  batch,
  dayReset,  // Nouveau jour détecté (minuit)
  other,
}

/// Mixin pour les widgets qui écoutent les changements globaux
mixin GlobalStateListener<T extends StatefulWidget> on State<T> {
  StreamSubscription<StateChangeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GlobalStateManager.instance.events.listen(_onGlobalStateChange);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Override pour réagir aux changements
  void _onGlobalStateChange(StateChangeEvent event) {
    if (mounted) {
      setState(() {
        onGlobalStateUpdate(event);
      });
    }
  }

  /// À implémenter dans les classes qui utilisent le mixin
  void onGlobalStateUpdate(StateChangeEvent event);
}