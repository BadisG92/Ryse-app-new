import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../components/ui/dashboard_models.dart';

class GoalsSummary {
  final int completed;
  final int total;
  final double totalProgress; // Nouveau: progrès total pour détecter les changements
  const GoalsSummary(this.completed, this.total, this.totalProgress);

  @override
  String toString() => '$completed/$total objectifs';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalsSummary &&
          runtimeType == other.runtimeType &&
          completed == other.completed &&
          total == other.total &&
          totalProgress == other.totalProgress;

  @override
  int get hashCode => completed.hashCode ^ total.hashCode ^ totalProgress.hashCode;
}

class GoalsNotifier extends ValueNotifier<GoalsSummary> {
  GoalsNotifier._internal() : super(const GoalsSummary(0, 4, 0.0));
  static final GoalsNotifier instance = GoalsNotifier._internal();

  bool _isUpdating = false;
  GoalsSummary? _lastValue;

  void update(List<DailyGoal> goals) {
    // PROTECTION ANTI-BOUCLE INFINIE
    if (_isUpdating) {
      debugPrint('⚠️ GoalsNotifier: update() déjà en cours, ignoré');
      return;
    }
    
    _isUpdating = true;
    
    try {
      // Considérer objectif comme complété si flag completed OU progress>=100
      final completed = goals.where((g) => g.completed || g.progress >= 100).length;
      
      // Calculer le progrès total pour détecter tous les changements
      final totalProgress = goals.fold<double>(0.0, (sum, goal) => sum + goal.progress) / goals.length;
      
      final newValue = GoalsSummary(completed, 4, totalProgress);
      
      // Ne notifier que si la valeur a changé (completed OU progress)
      if (_lastValue == null || _lastValue != newValue) {
        debugPrint('🎯 GoalsNotifier: ${_lastValue?.completed ?? 0}/${_lastValue?.totalProgress?.toStringAsFixed(1) ?? "0.0"}% -> ${newValue.completed}/${newValue.totalProgress.toStringAsFixed(1)}%');
        value = newValue;
        _lastValue = newValue;
      }
    } finally {
      _isUpdating = false;
    }
  }
} 