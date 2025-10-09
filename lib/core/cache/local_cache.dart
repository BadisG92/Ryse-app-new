import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/ui/dashboard_models.dart';

/// Cache local pour les mises à jour optimistes
/// Permet de stocker temporairement les données avant sync avec Supabase
class LocalCache {
  // Clés pour le cache
  static const String _dailyGoalsKey = 'daily_goals_cache';
  static const String _waterEntriesKey = 'water_entries_cache';
  static const String _foodEntriesKey = 'food_entries_cache';
  static const String _mealsKey = 'meals_cache';
  static const String _exercisesKey = 'exercises_cache';
  static const String _workoutTemplatesKey = 'workout_templates_cache';
  static const String _userProfileKey = 'user_profile_cache';
  static const String _weightProgressKey = 'weight_progress_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';

  // Durée de vie du cache optimisée pour la navigation
  static const Duration _cacheExpiry = Duration(minutes: 10); // Augmenté pour éviter trop de requêtes
  static const Duration _shortCacheExpiry = Duration(minutes: 2); // Pour données critiques

  /// Sauvegarder les objectifs journaliers
  static Future<void> saveDailyGoals(List<DailyGoal> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = goals.map((goal) => jsonEncode({
        'id': goal.id,
        'label': goal.label,
        'progress': goal.progress,
        'xp': goal.xp,
        'completed': goal.completed,
        'currentValue': goal.currentValue,
        'targetValue': goal.targetValue,
        'unit': goal.unit,
        'isPending': goal.isPending ?? false,
      })).toList();

      await prefs.setStringList(_dailyGoalsKey, jsonList);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('💾 Cache local: Objectifs sauvegardés (${goals.length} items)');
    } catch (e) {
      print('❌ Erreur sauvegarde cache goals: $e');
    }
  }

  /// Récupérer les objectifs journaliers du cache
  static Future<List<DailyGoal>?> getDailyGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier si le cache n'a pas expiré
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
          print('📆 Cache expiré, suppression');
          await clearDailyGoals();
          return null;
        }
      }

      final jsonList = prefs.getStringList(_dailyGoalsKey);
      if (jsonList == null) return null;

      final goals = jsonList.map((jsonStr) {
        final json = jsonDecode(jsonStr);
        return DailyGoal(
          id: json['id'],
          label: json['label'],
          progress: json['progress'],
          xp: json['xp'],
          completed: json['completed'],
          currentValue: json['currentValue'],
          targetValue: json['targetValue'],
          unit: json['unit'],
          isPending: json['isPending'] ?? false,
        );
      }).toList();

      print('📱 Cache local: Objectifs récupérés (${goals.length} items)');
      return goals;
    } catch (e) {
      print('❌ Erreur lecture cache goals: $e');
      return null;
    }
  }

  /// Vider le cache des objectifs journaliers
  static Future<void> clearDailyGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyGoalsKey);
      await prefs.remove(_cacheTimestampKey);
      print('🧹 Cache objectifs vidé');
    } catch (e) {
      print('❌ Erreur vidage cache: $e');
    }
  }

  /// Mettre à jour un objectif spécifique dans le cache
  static Future<void> updateGoalInCache(String goalId, DailyGoal updatedGoal) async {
    try {
      final currentGoals = await getDailyGoals();
      if (currentGoals == null) return;

      final index = currentGoals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        currentGoals[index] = updatedGoal;
        await saveDailyGoals(currentGoals);
        print('🔄 Cache mis à jour pour objectif: $goalId');
      }
    } catch (e) {
      print('❌ Erreur mise à jour goal cache: $e');
    }
  }

  /// Marquer un objectif comme "en attente" (pending)
  static Future<void> markGoalAsPending(String goalId) async {
    try {
      final currentGoals = await getDailyGoals();
      if (currentGoals == null) return;

      final index = currentGoals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        final updatedGoal = DailyGoal(
          id: currentGoals[index].id,
          label: currentGoals[index].label,
          progress: currentGoals[index].progress,
          xp: currentGoals[index].xp,
          completed: currentGoals[index].completed,
          currentValue: currentGoals[index].currentValue,
          targetValue: currentGoals[index].targetValue,
          unit: currentGoals[index].unit,
          isPending: true,
        );

        currentGoals[index] = updatedGoal;
        await saveDailyGoals(currentGoals);
        print('⏳ Objectif $goalId marqué comme pending');
      }
    } catch (e) {
      print('❌ Erreur marking pending: $e');
    }
  }

  /// Sauvegarder une entrée d'eau temporaire
  static Future<void> saveWaterEntryTemp({
    required double amount,
    required DateTime timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempEntries = prefs.getStringList(_waterEntriesKey) ?? [];

      final tempEntry = {
        'id': 'temp_${timestamp.millisecondsSinceEpoch}',
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'isPending': true,
      };

      tempEntries.add(jsonEncode(tempEntry));
      await prefs.setStringList(_waterEntriesKey, tempEntries);

      print('💧 Cache eau: Entrée temporaire sauvegardée (+${amount}ml)');
    } catch (e) {
      print('❌ Erreur sauvegarde eau temp: $e');
    }
  }

  /// Supprimer les entrées d'eau temporaires après sync
  static Future<void> clearTempWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_waterEntriesKey);
      print('🧹 Entrées eau temporaires supprimées');
    } catch (e) {
      print('❌ Erreur suppression eau temp: $e');
    }
  }

  /// Vider tout le cache (utile en cas d'erreur)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyGoalsKey);
      await prefs.remove(_waterEntriesKey);
      await prefs.remove(_foodEntriesKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_userProfileKey);
      print('🧹 Tout le cache local vidé');
    } catch (e) {
      print('❌ Erreur vidage complet cache: $e');
    }
  }

  /// Vérifier si le cache est valide
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime) <= _cacheExpiry;
    } catch (e) {
      return false;
    }
  }

  /// Sauvegarder une liste d'exercices
  static Future<void> saveExercises(List<dynamic> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = exercises.map((ex) => jsonEncode(ex)).toList();
      await prefs.setStringList(_exercisesKey, jsonList);
      await prefs.setInt('${_exercisesKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('💾 Cache: ${exercises.length} exercices sauvegardés');
    } catch (e) {
      print('❌ Erreur sauvegarde cache exercices: $e');
    }
  }

  /// Récupérer les exercices du cache
  static Future<List<dynamic>?> getExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier expiration
      final timestamp = prefs.getInt('${_exercisesKey}_timestamp');
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
          await prefs.remove(_exercisesKey);
          await prefs.remove('${_exercisesKey}_timestamp');
          return null;
        }
      }

      final jsonList = prefs.getStringList(_exercisesKey);
      if (jsonList == null) return null;

      final exercises = jsonList.map((jsonStr) => jsonDecode(jsonStr)).toList();
      print('📱 Cache: ${exercises.length} exercices récupérés');
      return exercises;
    } catch (e) {
      print('❌ Erreur lecture cache exercices: $e');
      return null;
    }
  }

  /// Sauvegarder les repas du jour
  static Future<void> saveMealsForDate(DateTime date, List<dynamic> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${_mealsKey}_${date.toIso8601String().split('T')[0]}';
      final jsonList = meals.map((meal) => jsonEncode(meal)).toList();
      await prefs.setStringList(dateKey, jsonList);
      await prefs.setInt('${dateKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('💾 Cache: ${meals.length} repas sauvegardés pour ${date.toIso8601String().split('T')[0]}');
    } catch (e) {
      print('❌ Erreur sauvegarde cache repas: $e');
    }
  }

  /// Récupérer les repas du cache pour une date
  static Future<List<dynamic>?> getMealsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${_mealsKey}_${date.toIso8601String().split('T')[0]}';

      // Vérifier expiration (plus courte pour les repas car ils changent souvent)
      final timestamp = prefs.getInt('${dateKey}_timestamp');
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _shortCacheExpiry) {
          await prefs.remove(dateKey);
          await prefs.remove('${dateKey}_timestamp');
          return null;
        }
      }

      final jsonList = prefs.getStringList(dateKey);
      if (jsonList == null) return null;

      final meals = jsonList.map((jsonStr) => jsonDecode(jsonStr)).toList();
      print('📱 Cache: ${meals.length} repas récupérés pour ${date.toIso8601String().split('T')[0]}');
      return meals;
    } catch (e) {
      print('❌ Erreur lecture cache repas: $e');
      return null;
    }
  }

  /// Cache intelligent pour données fréquemment utilisées
  static Future<void> warmUpCache() async {
    try {
      print('🔥 Warm-up cache: Préchauffage des données essentielles...');

      // Précharger seulement si pas de cache existant
      final goals = await getDailyGoals();
      if (goals == null) {
        print('🔥 Cache goals manquant - sera chargé à la demande');
      }

      final exercises = await getExercises();
      if (exercises == null) {
        print('🔥 Cache exercices manquant - sera chargé à la demande');
      }

      print('🔥 Warm-up cache terminé');
    } catch (e) {
      print('❌ Erreur warm-up cache: $e');
    }
  }

  /// Nettoyer les caches expirés pour optimiser l'espace
  static Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cleaned = 0;

      for (final key in keys) {
        if (key.endsWith('_timestamp')) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final cacheKey = key.replaceAll('_timestamp', '');

            // Expiration différentielle selon le type de données
            Duration expiry = _cacheExpiry;
            if (key.contains('meals') || key.contains('goals')) {
              expiry = _shortCacheExpiry;
            }

            if (DateTime.now().difference(cacheTime) > expiry) {
              await prefs.remove(key);
              await prefs.remove(cacheKey);
              cleaned++;
            }
          }
        }
      }

      if (cleaned > 0) {
        print('🧹 Cache: $cleaned entrées expirées supprimées');
      }
    } catch (e) {
      print('❌ Erreur nettoyage cache: $e');
    }
  }

  /// Debug: Afficher le contenu du cache
  static Future<void> debugPrintCache() async {
    try {
      final goals = await getDailyGoals();
      final exercises = await getExercises();
      final todayMeals = await getMealsForDate(DateTime.now());
      final isValid = await isCacheValid();

      print('🔍 DEBUG CACHE LOCAL:');
      print('   - Cache valide: $isValid');
      print('   - Objectifs: ${goals?.length ?? 0} items');
      print('   - Exercices: ${exercises?.length ?? 0} items');
      print('   - Repas aujourd\'hui: ${todayMeals?.length ?? 0} items');

      if (goals != null) {
        for (final goal in goals) {
          print('   - ${goal.label}: ${goal.progress}% (pending: ${goal.isPending})');
        }
      }
    } catch (e) {
      print('❌ Erreur debug cache: $e');
    }
  }
}