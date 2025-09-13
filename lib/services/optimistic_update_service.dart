import 'package:flutter/foundation.dart';
import 'dashboard_service.dart';
import '../components/ui/dashboard_models.dart';
import '../providers/goals_notifier.dart';

/// Service pour gérer les mises à jour optimistes
/// Permet de mettre à jour l'UI immédiatement sans attendre Supabase
class OptimisticUpdateService {
  static final OptimisticUpdateService _instance = OptimisticUpdateService._internal();
  factory OptimisticUpdateService() => _instance;
  OptimisticUpdateService._internal();

  // Cache local des objectifs pour mise à jour instantanée
  List<DailyGoal>? _localGoals;
  
  /// Met à jour l'eau de manière optimiste
  static Future<void> updateWaterOptimistic(int amountMl) async {
    try {
      // 1. Récupérer les objectifs actuels du cache
      List<DailyGoal> currentGoals = await DashboardService.getDailyGoals();
      
      // 2. Trouver et mettre à jour l'objectif eau localement
      final updatedGoals = currentGoals.map((goal) {
        if (goal.id == 'water') {
          final currentVal = goal.currentValue ?? 0.0;
          final targetVal = goal.targetValue ?? 2.0;
          final newValue = currentVal + (amountMl / 1000.0);
          final newProgress = ((newValue / targetVal) * 100).round().clamp(0, 100);
          
          return DailyGoal(
            id: goal.id,
            label: goal.label,
            progress: newProgress,
            xp: goal.xp,
            completed: newValue >= targetVal,
            currentValue: newValue,
            targetValue: targetVal,
            unit: goal.unit,
          );
        }
        return goal;
      }).toList();
      
      // 3. Mettre à jour immédiatement le notifier (UI se rafraîchit instantanément)
      GoalsNotifier.instance.update(updatedGoals);
      print('💧 Mise à jour optimiste de l\'eau: +${amountMl}ml');
      
      // 4. Lancer la vraie mise à jour en arrière-plan (non-bloquant)
      _syncWithBackend();
      
    } catch (e) {
      print('❌ Erreur mise à jour optimiste: $e');
    }
  }
  
  /// Met à jour les calories de manière optimiste
  static Future<void> updateCaloriesOptimistic(double calories) async {
    try {
      // 1. Récupérer les objectifs actuels
      List<DailyGoal> currentGoals = await DashboardService.getDailyGoals();
      
      // 2. Mettre à jour calories ET repas localement
      final updatedGoals = currentGoals.map((goal) {
        if (goal.id == 'calories') {
          final currentVal = goal.currentValue ?? 0.0;
          final targetVal = goal.targetValue ?? 2000.0;
          final newValue = currentVal + calories;
          final newProgress = ((newValue / targetVal) * 100).round().clamp(0, 100);
          
          return DailyGoal(
            id: goal.id,
            label: goal.label,
            progress: newProgress,
            xp: goal.xp,
            completed: newValue >= targetVal * 0.9,
            currentValue: newValue,
            targetValue: targetVal,
            unit: goal.unit,
          );
        } else if (goal.id == 'meals') {
          // Incrémenter le compteur de repas si c'est un nouveau repas
          final currentVal = goal.currentValue ?? 0.0;
          final newValue = currentVal + 1;
          final newProgress = ((newValue / 3) * 100).round();
          
          return DailyGoal(
            id: goal.id,
            label: goal.label,
            progress: newProgress,
            xp: goal.xp,
            completed: newValue >= 3,
            currentValue: newValue,
            targetValue: goal.targetValue,
            unit: goal.unit,
          );
        }
        return goal;
      }).toList();
      
      // 3. Mise à jour instantanée
      GoalsNotifier.instance.update(updatedGoals);
      print('🍎 Mise à jour optimiste calories: +${calories}kcal');
      
      // 4. Sync en arrière-plan
      _syncWithBackend();
      
    } catch (e) {
      print('❌ Erreur mise à jour optimiste: $e');
    }
  }
  
  /// Met à jour après un workout de manière optimiste
  static Future<void> updateWorkoutOptimistic() async {
    try {
      List<DailyGoal> currentGoals = await DashboardService.getDailyGoals();
      
      final updatedGoals = currentGoals.map((goal) {
        if (goal.id == 'workout') {
          return DailyGoal(
            id: goal.id,
            label: goal.label,
            progress: 100,
            xp: goal.xp,
            completed: true,
            currentValue: 1,
            targetValue: 1,
            unit: goal.unit,
          );
        }
        return goal;
      }).toList();
      
      GoalsNotifier.instance.update(updatedGoals);
      print('🏋️ Mise à jour optimiste workout complété');
      
      _syncWithBackend();
      
    } catch (e) {
      print('❌ Erreur mise à jour optimiste: $e');
    }
  }
  
  /// Synchronise avec le backend de manière non-bloquante
  static void _syncWithBackend() {
    // Sync immédiate mais non-bloquante (pas de délai)
    Future.microtask(() async {
      try {
        // Récupérer les vraies données depuis Supabase
        final freshGoals = await DashboardService.getDailyGoalsFromSource();
        // Mettre à jour seulement si les données ont changé
        GoalsNotifier.instance.update(freshGoals);
        print('🔄 Sync backend terminée - données actualisées');
      } catch (e) {
        print('⚠️ Erreur sync backend: $e');
        // L'UI reste avec les données optimistes si erreur
      }
    });
  }
  
  /// Annule les changements optimistes et recharge depuis le serveur
  static Future<void> rollback() async {
    await DashboardService.invalidateAndRefreshGoals();
  }
}