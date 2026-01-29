import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';
import 'translations.dart';
import '../components/ui/global_progress_models.dart';
import 'sport_dashboard_service.dart';
import 'header_cache_service.dart';
import 'app_review_service.dart';
import 'unified_subscription_service.dart';
import 'meal_widget_data_provider.dart';

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
  int _proteinGoal = 0;
  int _carbsGoal = 0;
  int _fatGoal = 0;

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
  int get proteinGoal => _proteinGoal;
  int get carbsGoal => _carbsGoal;
  int get fatGoal => _fatGoal;
  int get currentStreak => _currentStreak;

  // Getters - Informations utilisateur
  String get userName => _userName;
  bool get isPremium => UnifiedSubscriptionService().isPremium;

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

    if (kDebugMode) debugPrint('📊 GlobalState: Données hebdomadaires mises en cache');
    if (kDebugMode) debugPrint('   - Balance items: ${balance.items.length}');
    if (kDebugMode) debugPrint('   - Tracking days: ${tracking.length}');
  }

  // Forcer le rafraîchissement des données hebdomadaires
  void invalidateWeeklyData() {
    _weeklyDataLastUpdate = null;
    if (kDebugMode) debugPrint('🔄 GlobalState: Cache hebdomadaire invalidé');
    // Notifier les widgets du planner
    _eventController.add(StateChangeEvent(type: ChangeType.planner, value: null));
  }

  /// Initialiser avec les données existantes de Supabase
  Future<void> initialize() async {
    if (kDebugMode) debugPrint('🚀 GlobalStateManager: Initialisation DEBUT...');

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;

      if (kDebugMode) debugPrint('🔍 User connecté: ${user?.id ?? "AUCUN"}');

      if (user != null) {
        if (kDebugMode) debugPrint('✅ User trouvé, chargement des données...');
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
              .select('daily_calories, daily_water_goal, daily_protein, daily_carbs, daily_fat, streak_count, first_name')
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

        if (kDebugMode) debugPrint('📝 Profil utilisateur brut: $userProfile');

        final dailyCaloriesGoal = (userProfile['daily_calories'] as num?)?.toDouble() ?? 2000;
        final dailyWaterGoalMl = (userProfile['daily_water_goal'] as num?)?.toDouble() ?? 2000;
        final dailyProteinGoal = (userProfile['daily_protein'] as num?)?.toInt() ?? ((dailyCaloriesGoal * 0.30) / 4).toInt();
        final dailyCarbsGoal = (userProfile['daily_carbs'] as num?)?.toInt() ?? ((dailyCaloriesGoal * 0.40) / 4).toInt();
        final dailyFatGoal = (userProfile['daily_fat'] as num?)?.toInt() ?? ((dailyCaloriesGoal * 0.30) / 9).toInt();
        final streakCount = (userProfile['streak_count'] as num?)?.toInt() ?? 0;

        // Formater le nom avec la première lettre en majuscule dès le chargement
        final rawName = userProfile['first_name'] as String? ?? user.email?.split('@').first ?? 'User';
        final name = rawName.isNotEmpty
            ? rawName[0].toUpperCase() + (rawName.length > 1 ? rawName.substring(1).toLowerCase() : '')
            : 'User';

        if (kDebugMode) debugPrint('📊 Valeurs extraites:');
        if (kDebugMode) debugPrint('   - dailyCaloriesGoal: $dailyCaloriesGoal (brut: ${userProfile['daily_calories']})');
        if (kDebugMode) debugPrint('   - dailyWaterGoalMl: $dailyWaterGoalMl (brut: ${userProfile['daily_water_goal']})');
        if (kDebugMode) debugPrint('   - dailyProteinGoal: $dailyProteinGoal (brut: ${userProfile['daily_protein']})');
        if (kDebugMode) debugPrint('   - dailyCarbsGoal: $dailyCarbsGoal (brut: ${userProfile['daily_carbs']})');
        if (kDebugMode) debugPrint('   - dailyFatGoal: $dailyFatGoal (brut: ${userProfile['daily_fat']})');
        if (kDebugMode) debugPrint('   - streakCount: $streakCount');
        if (kDebugMode) debugPrint('   - name: $name');

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
        _proteinGoal = dailyProteinGoal;
        _carbsGoal = dailyCarbsGoal;
        _fatGoal = dailyFatGoal;
        _currentStreak = streakCount;
        _userName = name;

        if (kDebugMode) debugPrint('✅ GlobalState initialisé:');
        if (kDebugMode) debugPrint('   👤 Nom: $_userName');
        if (kDebugMode) debugPrint('   📊 ${_currentCalories.toInt()}/${_calorieGoal.toInt()} kcal (${calorieProgress.toInt()}%)');
        if (kDebugMode) debugPrint('   💧 ${_currentWaterL.toStringAsFixed(1)}L/${_waterGoalL.toStringAsFixed(1)}L (${waterProgress.toInt()}%)');
        if (kDebugMode) debugPrint('   🍽️  $_mealsCount repas');
        if (kDebugMode) debugPrint('   🏋️ Sport: ${_workoutCompleted ? "✅" : "❌"} ($_sportSessions séances, $totalCaloriesBurned kcal)');
        if (kDebugMode) debugPrint('   🔥 Streak: $_currentStreak jours');
      } else {
        if (kDebugMode) debugPrint('⚠️ AUCUN utilisateur connecté - GlobalState pas initialisé');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('⚠️ GlobalStateManager init error (non-critique): $e');
      if (kDebugMode) debugPrint('Stack trace: $stackTrace');
      // Continue sans les données, elles seront chargées par les pages
    }

    if (kDebugMode) debugPrint('🏁 GlobalStateManager: Initialisation TERMINEE');

    // Démarrer la vérification du changement de jour
    _startMidnightCheck();
    _lastCheckedDate = DateTime.now();
  }

  /// Démarrer la vérification périodique du changement de jour
  void _startMidnightCheck() {
    // Annuler le timer précédent s'il existe
    _midnightCheckTimer?.cancel();

    // Calculer le temps jusqu'à minuit LOCAL de l'utilisateur
    final now = DateTime.now(); // Heure locale
    final today = DateTime(now.year, now.month, now.day);
    final midnight = today.add(const Duration(days: 1)); // Minuit du jour suivant
    final timeUntilMidnight = midnight.difference(now);

    final hours = timeUntilMidnight.inHours;
    final minutes = timeUntilMidnight.inMinutes % 60;
    if (kDebugMode) debugPrint('⏰ GlobalState: Prochain check à minuit dans ${hours}h${minutes}min (heure locale utilisateur)');

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
        if (kDebugMode) debugPrint('🌙 GlobalState: Nouveau jour détecté! Réinitialisation des données journalières...');

        // Vérifier si c'est lundi (changement de semaine)
        if (now.weekday == DateTime.monday) {
          if (kDebugMode) debugPrint('📅 GlobalState: Nouveau lundi détecté! Réinitialisation des données hebdomadaires...');
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

    // TRIGGER: Invalider tous les caches pour le nouveau jour
    SportDashboardService.invalidateCache();
    HeaderCacheService.clearCache();
    if (kDebugMode) debugPrint('🗑️ GlobalState: Caches invalidés pour nouveau jour');

    // Mettre à jour le widget iOS avec les données du nouveau jour (vides)
    MealWidgetDataProvider.updateWidgetData();
    if (kDebugMode) debugPrint('📱 GlobalState: Widget iOS mis à jour pour nouveau jour');

    // Notifier tous les listeners
    _notifyChange(StateChangeEvent(
      type: ChangeType.dayReset,
      value: DateTime.now(),
    ));

    if (kDebugMode) debugPrint('✨ GlobalState: Données journalières réinitialisées à 0');
  }

  /// Réinitialiser les données hebdomadaires
  void _resetWeeklyData() {
    _weeklyBalance = null;
    _weeklyTracking = null;
    _weeklyDataLastUpdate = null;

    // TRIGGER: Invalider le cache sport pour la nouvelle semaine
    SportDashboardService.invalidateCache();
    if (kDebugMode) debugPrint('🗑️ GlobalState: Cache sport invalidé pour nouvelle semaine');

    if (kDebugMode) debugPrint('✨ GlobalState: Données hebdomadaires réinitialisées');
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

    if (kDebugMode) debugPrint('💧 GlobalState: Eau mise à jour -> ${_currentWaterL}L');

    // Vérifier si on peut demander une review
    _checkAndRequestReviewIfNeeded();
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

    if (kDebugMode) debugPrint('🍎 GlobalState: Calories mises à jour -> ${_currentCalories}kcal');

    // Vérifier si on peut demander une review
    _checkAndRequestReviewIfNeeded();
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

    if (kDebugMode) debugPrint('🥩 GlobalState: Macros mis à jour -> P:${_currentProteins}g C:${_currentCarbs}g F:${_currentFats}g');
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

    if (kDebugMode) debugPrint('🍽️ GlobalState: Repas mis à jour -> $_mealsCount');

    // Vérifier si on peut demander une review
    _checkAndRequestReviewIfNeeded();
  }

  /// MISE À JOUR INSTANTANÉE - Workout
  void updateWorkout(bool completed) {
    _workoutCompleted = completed;

    _notifyChange(StateChangeEvent(
      type: ChangeType.workout,
      value: _workoutCompleted,
    ));

    if (kDebugMode) debugPrint('🏋️ GlobalState: Workout mis à jour -> $_workoutCompleted');
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

    if (kDebugMode) debugPrint('🏋️ GlobalState: Sport mis à jour -> $_sportSessions séances, $_sportCaloriesBurned kcal');

    // Vérifier si on peut demander une review
    _checkAndRequestReviewIfNeeded();
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

      if (kDebugMode) debugPrint('🔍 DEBUG refreshSportData:');
      if (kDebugMode) debugPrint('   - Séances musculation trouvées: ${workoutSessions.length}');
      if (kDebugMode) debugPrint('   - Séances cardio trouvées: ${cardioSessions.length}');
      if (kDebugMode) debugPrint('   - Date recherchée: ${startOfDay.toIso8601String().split('T')[0]}');

      // Compter les séances
      final totalSessions = workoutSessions.length + cardioSessions.length;

      // Calculer les calories brûlées
      int totalCalories = 0;
      for (var session in workoutSessions) {
        final cals = (session['calories_burned'] as num?)?.toInt() ?? 0;
        totalCalories += cals;
        if (kDebugMode) debugPrint('   - Musculation: $cals kcal');
      }
      for (var session in cardioSessions) {
        final cals = (session['calories'] as num?)?.toInt() ?? 0;
        totalCalories += cals;
        if (kDebugMode) debugPrint('   - Cardio: $cals kcal');
      }

      if (kDebugMode) debugPrint('   - TOTAL: $totalSessions séances, $totalCalories kcal');

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

      if (kDebugMode) debugPrint('🔄 GlobalState: Sport rechargé depuis DB -> $_sportSessions séances, $_sportCaloriesBurned kcal');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur refresh sport data: $e');
    }
  }

  /// MISE À JOUR INSTANTANÉE - Streak
  void updateStreak(int newStreak) {
    _currentStreak = newStreak;

    _notifyChange(StateChangeEvent(
      type: ChangeType.streak,
      value: _currentStreak,
    ));

    if (kDebugMode) debugPrint('🔥 GlobalState: Streak mis à jour -> $_currentStreak jours');
  }

  /// MISE À JOUR INSTANTANÉE - Objectifs (si l'utilisateur change ses paramètres)
  void updateGoals({
    double? calorieGoal, 
    double? waterGoalL,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
  }) {
    if (calorieGoal != null) _calorieGoal = calorieGoal;
    if (waterGoalL != null) _waterGoalL = waterGoalL;
    if (proteinGoal != null) _proteinGoal = proteinGoal;
    if (carbsGoal != null) _carbsGoal = carbsGoal;
    if (fatGoal != null) _fatGoal = fatGoal;

    _notifyChange(StateChangeEvent(
      type: ChangeType.goals,
      value: {
        'calorieGoal': _calorieGoal,
        'waterGoalL': _waterGoalL,
        'proteinGoal': _proteinGoal,
        'carbsGoal': _carbsGoal,
        'fatGoal': _fatGoal,
      },
    ));

    if (kDebugMode) debugPrint('🎯 GlobalState: Objectifs mis à jour -> ${_calorieGoal.toInt()}kcal, ${_waterGoalL.toStringAsFixed(1)}L, P:$_proteinGoal g C:$_carbsGoal g F:$_fatGoal g');
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

      if (kDebugMode) debugPrint('🍽️ GlobalState: Repas recomptés depuis la base -> $_mealsCount');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur refresh meals count: $e');
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

    if (kDebugMode) debugPrint('📊 GlobalState: Batch update effectué');
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

    if (kDebugMode) debugPrint('📋 getDailyGoalsForDashboard() - État actuel:');
    if (kDebugMode) debugPrint('   Calories: $_currentCalories / $_calorieGoal kcal');
    if (kDebugMode) debugPrint('   Eau: $_currentWaterL / $_waterGoalL L');
    if (kDebugMode) debugPrint('   Repas: $_mealsCount');
    if (kDebugMode) debugPrint('   Séances sport: $_sportSessions');

    return [
      {
        'id': 'calories',
        'label': 'goal_calories'.tr(languageCode),
        'progress': calorieProgress.toInt(),
        'completed': calorieProgress >= 100,
        'currentValue': _currentCalories,
        'targetValue': _calorieGoal,
        'unit': 'kcal',
      },
      {
        'id': 'water',
        'label': 'goal_water'.tr(languageCode),
        'progress': waterProgress.toInt(),
        'completed': waterProgress >= 100,
        'currentValue': _currentWaterL,
        'targetValue': _waterGoalL,
        'unit': 'L',
      },
      // MASQUÉ - Objectif repas (conservé pour réactivation future)
      // {
      //   'id': 'meals',
      //   'label': 'goal_meals'.tr(languageCode),
      //   'progress': (_mealsCount >= 3) ? 100 : (_mealsCount * 33),
      //   'completed': _mealsCount >= 3,
      //   'currentValue': _mealsCount.toDouble(),
      //   'targetValue': 3.0,
      //   'unit': 'meals'.tr(languageCode),
      // },
      {
        'id': 'workout',
        'label': 'goal_sport'.tr(languageCode),
        'progress': _sportSessions >= 1 ? 100 : 0,
        'completed': _sportSessions >= 1,
        'currentValue': _sportSessions.toDouble(),
        'targetValue': 1.0,
        'unit': 'sessions'.tr(languageCode),
      },
    ];
  }

  /// Notifie tous les listeners d'un changement
  void _notifyChange(StateChangeEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Vérifie si les conditions sont remplies pour demander une review
  ///
  /// Appelée automatiquement après chaque mise à jour d'objectif:
  /// - Calories ajoutées
  /// - Eau ajoutée
  /// - Repas ajouté
  /// - Sport complété
  ///
  /// Déclenche la première review si:
  /// - Au moins 2 objectifs quotidiens sont complétés
  /// - Priorité si Calories + Sport sont complétés ensemble
  ///
  /// Déclenche les reviews suivantes (milestones) si:
  /// - Après 3 workouts complétés (total historique)
  /// - Après 7 jours de streak
  /// - Après 5 repas différents trackés (total historique)
  Future<void> _checkAndRequestReviewIfNeeded() async {
    try {
      // Calculer le nombre d'objectifs complétés
      final dailyGoals = getDailyGoalsForDashboard();
      final completedGoals = dailyGoals.where((goal) => goal['completed'] == true).toList();
      final completedCount = completedGoals.length;

      // Vérifier si Calories ET Sport sont complétés (combo premium)
      final caloriesCompleted = calorieProgress >= 100;
      final workoutCompleted = _sportSessions >= 1;
      final hasCaloriesAndWorkout = caloriesCompleted && workoutCompleted;

      if (kDebugMode) {
        debugPrint('🎯 GlobalState: Vérification review...');
        debugPrint('   - Objectifs complétés: $completedCount/3');
        debugPrint('   - Calories: ${caloriesCompleted ? "✅" : "❌"}');
        debugPrint('   - Sport: ${workoutCompleted ? "✅" : "❌"}');
        debugPrint('   - Combo premium: ${hasCaloriesAndWorkout ? "✅" : "❌"}');
        debugPrint('   - Streak: $_currentStreak jours');
      }

      // TRIGGER 1: Premier review - Si au moins 2 objectifs sont complétés
      if (completedCount >= 2) {
        await AppReviewService().requestReviewAfterDailyGoals(
          completedGoalsCount: completedCount,
          hasCaloriesAndWorkout: hasCaloriesAndWorkout,
        );
      }

      // TRIGGER 2: Après 7 jours de streak
      if (_currentStreak == 7) {
        await AppReviewService().requestReviewAfterMilestone('7_day_streak');
      }

      // TRIGGER 3: Après 3 workouts complétés (vérifier le total historique)
      await _checkWorkoutMilestone();

      // TRIGGER 4: Après 5 repas différents trackés (vérifier le total historique)
      await _checkMealsMilestone();

    } catch (e) {
      if (kDebugMode) debugPrint('❌ GlobalState: Erreur _checkAndRequestReviewIfNeeded - $e');
    }
  }

  /// Vérifie si l'utilisateur a complété 3 workouts (total historique)
  Future<void> _checkWorkoutMilestone() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Compter le nombre TOTAL de séances (musculation + cardio) depuis le début
      final futures = await Future.wait([
        // Total séances musculation
        client
            .from('workout_session_summaries')
            .select('history_session_id')
            .eq('user_id', user.id),

        // Total séances cardio
        client
            .from('cardio_sessions')
            .select('id')
            .eq('user_id', user.id)
            .eq('is_completed', true),
      ]);

      final workoutSessions = futures[0] as List;
      final cardioSessions = futures[1] as List;
      final totalWorkouts = workoutSessions.length + cardioSessions.length;

      if (kDebugMode) debugPrint('💪 Total workouts historiques: $totalWorkouts');

      // Si exactement 3 workouts → trigger review
      if (totalWorkouts == 3) {
        await AppReviewService().requestReviewAfterMilestone('3_workouts_completed');
      }

    } catch (e) {
      if (kDebugMode) debugPrint('❌ GlobalState: Erreur _checkWorkoutMilestone - $e');
    }
  }

  /// Vérifie si l'utilisateur a tracké 5 repas différents (total historique)
  Future<void> _checkMealsMilestone() async {
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Compter le nombre de meal_id UNIQUES (repas différents)
      final response = await client
          .from('food_entries')
          .select('meal_id')
          .eq('user_id', user.id)
          .not('meal_id', 'is', null);

      final entries = response as List;
      final uniqueMealIds = <String>{};

      for (var entry in entries) {
        final mealId = entry['meal_id'] as String?;
        if (mealId != null && mealId.isNotEmpty) {
          uniqueMealIds.add(mealId);
        }
      }

      final totalUniqueMeals = uniqueMealIds.length;

      if (kDebugMode) debugPrint('🍽️ Total repas uniques trackés: $totalUniqueMeals');

      // Si exactement 5 repas différents → trigger review
      if (totalUniqueMeals == 5) {
        await AppReviewService().requestReviewAfterMilestone('5_different_meals_tracked');
      }

    } catch (e) {
      if (kDebugMode) debugPrint('❌ GlobalState: Erreur _checkMealsMilestone - $e');
    }
  }

  /// Réinitialise complètement l'état global (pour déconnexion)
  void reset() {
    if (kDebugMode) debugPrint('🔄 GlobalState: Réinitialisation complète...');

    // Réinitialiser toutes les valeurs
    _currentCalories = 0;
    _currentWaterL = 0;
    _mealsCount = 0;
    _workoutCompleted = false;
    _currentProteins = 0;
    _currentCarbs = 0;
    _currentFats = 0;
    _sportSessions = 0;
    _sportCaloriesBurned = 0;

    // Réinitialiser les objectifs par défaut
    _calorieGoal = 2000;
    _waterGoalL = 2.0;
    _currentStreak = 0;
    _userName = 'User';

    // Vider les données hebdomadaires
    _weeklyBalance = null;
    _weeklyTracking = null;
    _weeklyDataLastUpdate = null;

    // Vider le cache global
    _globalCache.clear();

    // Annuler le timer
    _midnightCheckTimer?.cancel();
    _lastCheckedDate = null;

    // Notifier tous les listeners
    _notifyChange(StateChangeEvent(
      type: ChangeType.batch,
      value: null,
    ));

    if (kDebugMode) debugPrint('✅ GlobalState: Réinitialisation terminée');
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
  planner,   // Mise à jour du planner hebdomadaire
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