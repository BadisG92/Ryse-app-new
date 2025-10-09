import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

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

  // Objectifs utilisateur (pour calcul de progression)
  double _calorieGoal = 2000;
  double _waterGoalL = 2.0;

  // Streak (série de jours consécutifs)
  int _currentStreak = 0;

  // Getters - Valeurs actuelles
  double get currentCalories => _currentCalories;
  double get currentWaterL => _currentWaterL;
  int get mealsCount => _mealsCount;
  bool get workoutCompleted => _workoutCompleted;
  double get currentProteins => _currentProteins;
  double get currentCarbs => _currentCarbs;
  double get currentFats => _currentFats;

  // Getters - Objectifs
  double get calorieGoal => _calorieGoal;
  double get waterGoalL => _waterGoalL;
  int get currentStreak => _currentStreak;

  // Getters - Progression (%)
  double get calorieProgress => _calorieGoal > 0 ? (_currentCalories / _calorieGoal * 100).clamp(0, 100) : 0;
  double get waterProgress => _waterGoalL > 0 ? (_currentWaterL / _waterGoalL * 100).clamp(0, 100) : 0;

  /// Initialiser avec les données existantes de Supabase
  Future<void> initialize() async {
    debugPrint('🚀 GlobalStateManager: Initialisation...');

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;

      if (user != null) {
        // Charger les données du jour depuis Supabase
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Requête parallèle pour performance
        final futures = await Future.wait([
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

          // Vérifier si workout fait aujourd'hui (workout_session_summaries)
          client
              .from('workout_session_summaries')
              .select('history_session_id')
              .eq('user_id', user.id)
              .eq('session_date', startOfDay.toIso8601String().split('T')[0])
              .limit(1),

          // Vérifier aussi les séances cardio du jour
          client
              .from('cardio_sessions')
              .select('id')
              .eq('user_id', user.id)
              .eq('is_completed', true)
              .gte('start_time', startOfDay.toIso8601String())
              .lt('start_time', endOfDay.toIso8601String())
              .limit(1),

          // Récupérer les objectifs et le streak de l'utilisateur
          client
              .from('users')
              .select('daily_calories, daily_water_goal, streak_count')
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

        // Traiter workout (musculation OU cardio)
        final workoutSessions = futures[2] as List;
        final cardioSessions = futures[3] as List;
        final hasWorkout = workoutSessions.isNotEmpty || cardioSessions.isNotEmpty;

        // Traiter les objectifs et streak
        final userProfile = futures[4] as Map<String, dynamic>;
        final dailyCaloriesGoal = (userProfile['daily_calories'] as num?)?.toDouble() ?? 2000;
        final dailyWaterGoalMl = (userProfile['daily_water_goal'] as num?)?.toDouble() ?? 2000;
        final streakCount = (userProfile['streak_count'] as num?)?.toInt() ?? 0;

        // Mettre à jour l'état global
        _currentCalories = totalCalories;
        _currentProteins = totalProteins;
        _currentCarbs = totalCarbs;
        _currentFats = totalFats;
        _currentWaterL = totalWaterMl / 1000.0;
        _mealsCount = uniqueMealIds.length;
        _workoutCompleted = hasWorkout;

        // Mettre à jour les objectifs
        _calorieGoal = dailyCaloriesGoal;
        _waterGoalL = dailyWaterGoalMl / 1000.0;
        _currentStreak = streakCount;

        debugPrint('✅ GlobalState initialisé:');
        debugPrint('   📊 ${_currentCalories.toInt()}/${_calorieGoal.toInt()} kcal (${calorieProgress.toInt()}%)');
        debugPrint('   💧 ${_currentWaterL.toStringAsFixed(1)}L/${_waterGoalL.toStringAsFixed(1)}L (${waterProgress.toInt()}%)');
        debugPrint('   🍽️  $_mealsCount repas');
        debugPrint('   🏋️ Sport: ${_workoutCompleted ? "✅" : "❌"}');
        debugPrint('   🔥 Streak: $_currentStreak jours');
      }
    } catch (e) {
      debugPrint('⚠️ GlobalStateManager init error (non-critique): $e');
      // Continue sans les données, elles seront chargées par les pages
    }
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
    return [
      {
        'id': 'calories',
        'label': 'Atteindre mes calories',
        'progress': calorieProgress.toInt(),
        'xp': 50,
        'completed': calorieProgress >= 100,
        'currentValue': _currentCalories,
        'targetValue': _calorieGoal,
        'unit': 'kcal',
      },
      {
        'id': 'water',
        'label': 'Boire',
        'progress': waterProgress.toInt(),
        'xp': 30,
        'completed': waterProgress >= 100,
        'currentValue': _currentWaterL,
        'targetValue': _waterGoalL,
        'unit': 'L',
      },
      {
        'id': 'meals',
        'label': 'Suivre mes repas aujourd\'hui',
        'progress': (_mealsCount >= 3) ? 100 : (_mealsCount * 33),
        'xp': 40,
        'completed': _mealsCount >= 3,
        'currentValue': _mealsCount.toDouble(),
        'targetValue': 3.0,
        'unit': 'repas',
      },
      {
        'id': 'workout',
        'label': 'Faire une séance aujourd\'hui',
        'progress': _workoutCompleted ? 100 : 0,
        'xp': 60,
        'completed': _workoutCompleted,
        'currentValue': _workoutCompleted ? 1.0 : 0.0,
        'targetValue': 1.0,
        'unit': 'séance',
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
  macros,
  streak,
  goals,
  batch,
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