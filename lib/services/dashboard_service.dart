import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../config/supabase_config.dart';
import '../components/ui/dashboard_models.dart';
import '../providers/goals_notifier.dart';

class DashboardService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  // ==== CACHE DES OBJECTIFS JOURNALIERS ====
  static List<DailyGoal>? _cachedGoals;
  static DateTime? _cachedGoalsDate;

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

      return UserProfile(
        name: response['first_name'] ?? 'Utilisateur',
        streak: 7, // TODO: Calculer le vrai streak
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

      // Créer les objectifs avec les vraies données
      final result = [
        DailyGoal(
          id: 'meals',
          label: 'Suivre mes repas aujourd\'hui',
          progress: ((mealsCount / 3) * 100).round(),
          xp: 25,
          completed: mealsCount >= 3,
          currentValue: mealsCount.toDouble(),
          targetValue: 3,
          unit: '',
        ),
        DailyGoal(
          id: 'water',
          label: 'Boire ${dailyWaterGoal.toStringAsFixed(1)}L d\'eau',
          progress: ((currentWaterL / dailyWaterGoal) * 100).round().clamp(0, 100),
          xp: 15,
          completed: currentWaterL >= dailyWaterGoal,
          currentValue: currentWaterL,
          targetValue: dailyWaterGoal,
          unit: 'L',
        ),
        DailyGoal(
          id: 'calories',
          label: 'Atteindre mes calories',
          progress: ((currentCalories / dailyCaloriesGoal) * 100).round().clamp(0, 100),
          xp: 25,
          completed: currentCalories >= dailyCaloriesGoal * 0.9, // 90% = complété
          currentValue: currentCalories,
          targetValue: dailyCaloriesGoal.toDouble(),
          unit: 'cal',
        ),
        DailyGoal(
          id: 'workout',
          label: 'Faire une séance aujourd\'hui',
          progress: 0, // TODO: Récupérer des vraies données d'entraînement
          xp: 30,
          completed: false, // TODO: Vérifier les sessions d'entraînement
          currentValue: 0,
          targetValue: 1,
          unit: '',
        ),
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

      return [
        ModulePreview(
          title: 'Nutrition',
          icon: LucideIcons.apple,
          stats: {
            'Calories': '${currentCalories.round()} kcal',
            'Eau': '${currentWaterL.toStringAsFixed(1)}L',
          },
          gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        // Module Sport reste statique pour l'instant
        const ModulePreview(
          title: 'Sport',
          icon: LucideIcons.dumbbell,
          stats: {
            'Calories': '342 kcal',
            'Séances': '1 / 3',
          },
          gradientColors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
      ];
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

} 