import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'food_entries_service.dart';
import 'dashboard_service.dart';
import 'global_state_manager.dart';
import '../components/ui/dashboard_models.dart';

/// Service pour précharger les données AVANT la navigation
/// Élimine les 2 secondes de latence au changement de page
class NavigationPreloader {
  static final NavigationPreloader _instance = NavigationPreloader._internal();
  static NavigationPreloader get instance => _instance;

  NavigationPreloader._internal();

  // Cache des données préchargées par route
  final Map<String, dynamic> _preloadedData = {};
  final Map<String, DateTime> _preloadTimestamps = {};

  /// Précharge les données pour une route spécifique
  Future<void> preloadForRoute(String routeName) async {
    debugPrint('🔄 Preloading data for route: $routeName');

    try {
      switch (routeName) {
        case '/nutrition':
        case '/manual_food_entry':
          await _preloadNutritionData();
          break;

        case '/ai_scanner':
          await _preloadScannerData();
          break;

        case '/workout':
          await _preloadWorkoutData();
          break;

        case '/dashboard':
        case '/home':
          await _preloadDashboardData();
          break;

        default:
          // Précharger les données de base pour toute route
          await _preloadBaseData();
      }

      _preloadTimestamps[routeName] = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ Erreur preload pour $routeName: $e');
    }
  }

  /// Précharge les données de base (utilisées partout)
  Future<void> _preloadBaseData() async {
    // Données utilisateur de base
    if (!_isDataFresh('base_data', Duration(minutes: 5))) {
      final futures = <Future>[];

      // Goals et profil (utilisés sur toutes les pages)
      futures.add(
        DashboardService.getDailyGoals().then((goals) {
          _preloadedData['daily_goals'] = goals;

          // Mettre à jour le GlobalStateManager
          final calories = goals.firstWhere((g) => g.id == 'calories',
            orElse: () => DailyGoal(
              id: 'calories',
              label: '',
              progress: 0,
              xp: 0,
              completed: false
            )).currentValue ?? 0;

          final water = goals.firstWhere((g) => g.id == 'water',
            orElse: () => DailyGoal(
              id: 'water',
              label: '',
              progress: 0,
              xp: 0,
              completed: false
            )).currentValue ?? 0;

          GlobalStateManager.instance.batchUpdate(
            calories: calories.toDouble(),
            water: water.toDouble(),
          );
        })
      );

      await Future.wait(futures);
      _preloadTimestamps['base_data'] = DateTime.now();
    }
  }

  /// Précharge les données nutrition
  Future<void> _preloadNutritionData() async {
    if (!_isDataFresh('nutrition_data', Duration(minutes: 2))) {
      final futures = <Future>[];

      // Foods list (lourd, à précharger!)
      futures.add(
        DatabaseService.getFoods().then((foods) {
          _preloadedData['foods_list'] = foods;
          GlobalStateManager.instance.cacheData('foods_list', foods);
        }).catchError((e) {
          debugPrint('Erreur preload foods: $e');
        })
      );

      // Frequent foods (seulement si on a un user ID valide)
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        futures.add(
          DatabaseService.getFrequentlyUsedFoods(userId).then((foods) {
            _preloadedData['frequent_foods'] = foods;
            GlobalStateManager.instance.cacheData('frequent_foods', foods);
          }).catchError((e) {
            debugPrint('Erreur preload frequent foods: $e');
          })
        );

        // Today's meals
        futures.add(
          FoodEntriesService.getFoodEntriesForDate(
            userId,
            DateTime.now()
          ).then((meals) {
            _preloadedData['today_meals'] = meals;
            GlobalStateManager.instance.cacheData('today_meals', meals);
          }).catchError((e) {
            debugPrint('Erreur preload meals: $e');
          })
        );
      }

      await Future.wait(futures);
      _preloadTimestamps['nutrition_data'] = DateTime.now();
    }
  }

  /// Précharge les données scanner
  Future<void> _preloadScannerData() async {
    // Précharger les données de base nutrition
    await _preloadNutritionData();

    // Pas besoin de précharger plus, le scanner utilise les mêmes données
  }

  /// Précharge les données workout
  Future<void> _preloadWorkoutData() async {
    if (!_isDataFresh('workout_data', Duration(minutes: 5))) {
      final futures = <Future>[];

      // Exercices (lourd!)
      futures.add(
        DatabaseService.getSystemExercises().then((exercises) {
          _preloadedData['exercises_list'] = exercises;
          GlobalStateManager.instance.cacheData('exercises_list', exercises);
        })
      );

      // Templates
      futures.add(
        DatabaseService.getWorkoutTemplatesInstant().then((templates) {
          _preloadedData['workout_templates'] = templates;
          GlobalStateManager.instance.cacheData('workout_templates', templates);
        })
      );

      await Future.wait(futures);
      _preloadTimestamps['workout_data'] = DateTime.now();
    }
  }

  /// Précharge les données dashboard
  Future<void> _preloadDashboardData() async {
    // Le dashboard utilise les données de base
    await _preloadBaseData();

    // Plus les modules
    if (!_isDataFresh('dashboard_modules', Duration(minutes: 1))) {
      await DashboardService.getModulePreviews().then((modules) {
        _preloadedData['module_previews'] = modules;
        GlobalStateManager.instance.cacheData('module_previews', modules);
      });

      _preloadTimestamps['dashboard_modules'] = DateTime.now();
    }
  }

  /// Vérifie si les données sont encore fraîches
  bool _isDataFresh(String key, Duration maxAge) {
    final timestamp = _preloadTimestamps[key];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < maxAge;
  }

  /// Récupère les données préchargées
  T? getPreloadedData<T>(String key) {
    // D'abord vérifier le cache global
    final globalData = GlobalStateManager.instance.getCachedData<T>(key);
    if (globalData != null) return globalData;

    // Sinon utiliser le cache local
    return _preloadedData[key] as T?;
  }

  /// Navigation avec préchargement automatique
  static Future<T?> navigateWithPreload<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) async {
    // Précharger en parallèle avec l'animation de navigation
    if (routeName != null) {
      // Lancer le preload sans attendre
      instance.preloadForRoute(routeName);
    }

    // Naviguer immédiatement
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: routeName),
      ),
    );
  }

  /// Clear cache pour une route
  void clearRouteCache(String routeName) {
    _preloadedData.remove(routeName);
    _preloadTimestamps.remove(routeName);
  }

  /// Clear tout le cache
  void clearAllCache() {
    _preloadedData.clear();
    _preloadTimestamps.clear();
  }
}