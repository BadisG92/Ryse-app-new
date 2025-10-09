import 'package:flutter/foundation.dart';

/// Service global pour notifier toutes les pages qu'une séance sport a été completée
/// Permet une mise à jour instantanée de tous les composants UI
class WorkoutCompletionNotifier extends ChangeNotifier {
  static final WorkoutCompletionNotifier _instance = WorkoutCompletionNotifier._internal();
  static WorkoutCompletionNotifier get instance => _instance;
  WorkoutCompletionNotifier._internal();

  // Dernière séance completée pour debug
  String? _lastWorkoutType;
  DateTime? _lastWorkoutTime;
  Map<String, dynamic>? _lastWorkoutData;

  /// Getters pour les composants UI
  String? get lastWorkoutType => _lastWorkoutType;
  DateTime? get lastWorkoutTime => _lastWorkoutTime;
  Map<String, dynamic>? get lastWorkoutData => _lastWorkoutData;

  /// Notifier qu'une séance cardio a été completée
  void notifyCardioCompleted({
    required String activityType,
    required int calories,
    required Duration duration,
    Map<String, dynamic>? sessionData,
  }) {
    _lastWorkoutType = 'cardio';
    _lastWorkoutTime = DateTime.now();
    _lastWorkoutData = {
      'type': 'cardio',
      'activityType': activityType,
      'calories': calories,
      'duration': duration.inMinutes,
      'sessionData': sessionData,
    };

    debugPrint('🔥 WorkoutCompletionNotifier: Cardio $activityType completé ($calories kcal, ${duration.inMinutes}min)');

    // Notifier TOUS les listeners
    notifyListeners();
  }

  /// Notifier qu'une séance musculation a été completée
  void notifyMusculationCompleted({
    required String workoutName,
    required int calories,
    required Duration duration,
    Map<String, dynamic>? sessionData,
  }) {
    _lastWorkoutType = 'musculation';
    _lastWorkoutTime = DateTime.now();
    _lastWorkoutData = {
      'type': 'musculation',
      'workoutName': workoutName,
      'calories': calories,
      'duration': duration.inMinutes,
      'sessionData': sessionData,
    };

    debugPrint('🏋️ WorkoutCompletionNotifier: Musculation $workoutName completée ($calories kcal, ${duration.inMinutes}min)');

    // Notifier TOUS les listeners
    notifyListeners();
  }

  /// Reset pour les tests
  void reset() {
    _lastWorkoutType = null;
    _lastWorkoutTime = null;
    _lastWorkoutData = null;
  }

  /// Vérifie si une séance a été completée récemment (dernières 10 secondes)
  bool get hasRecentWorkout {
    if (_lastWorkoutTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastWorkoutTime!);
    return difference.inSeconds <= 10;
  }
}