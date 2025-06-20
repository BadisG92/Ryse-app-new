import 'package:flutter/material.dart';
import '../components/ui/dashboard_models.dart';

class GoalsSummary {
  final int completed;
  final int total;
  const GoalsSummary(this.completed, this.total);

  @override
  String toString() => '$completed/$total objectifs';
}

class GoalsNotifier extends ValueNotifier<GoalsSummary> {
  GoalsNotifier._internal() : super(const GoalsSummary(0, 4));
  static final GoalsNotifier instance = GoalsNotifier._internal();

  void update(List<DailyGoal> goals) {
    // Considérer objectif comme complété si flag completed OU progress>=100
    final completed = goals.where((g) => g.completed || g.progress >= 100).length;
    print('🎯 GoalsNotifier.update() appelée avec ${goals.length} objectifs');
    print('📋 Objectifs détaillés:');
    for (var goal in goals) {
      print('  - ${goal.label}: completed=${goal.completed}, progress=${goal.progress}');
    }
    print('✅ Objectifs complétés: $completed/4');
    value = GoalsSummary(completed, 4); // Total fixe de 4 objectifs
    print('📊 GoalsSummary mise à jour: ${value.toString()}');
  }
} 