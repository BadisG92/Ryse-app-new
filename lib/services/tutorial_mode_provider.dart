import 'package:flutter/material.dart';

/// Provider pour gérer le mode tutorial
/// Quand activé, les widgets affichent des données de démonstration vides
class TutorialModeProvider extends ChangeNotifier {
  bool _isTutorialMode = false;

  /// Instance singleton
  static final TutorialModeProvider _instance = TutorialModeProvider._internal();
  factory TutorialModeProvider() => _instance;
  TutorialModeProvider._internal();

  /// Getter pour savoir si on est en mode tutorial
  bool get isTutorialMode => _isTutorialMode;

  /// Activer le mode tutorial
  void enableTutorialMode() {
    debugPrint('🎓 [PROVIDER] enableTutorialMode() appelé - Avant: $_isTutorialMode');
    _isTutorialMode = true;
    notifyListeners();
    debugPrint('🎓 [PROVIDER] Mode tutorial ACTIVÉ - Après: $_isTutorialMode');
  }

  /// Désactiver le mode tutorial
  void disableTutorialMode() {
    debugPrint('✅ [PROVIDER] disableTutorialMode() appelé - Avant: $_isTutorialMode');
    _isTutorialMode = false;
    notifyListeners();
    debugPrint('✅ [PROVIDER] Mode tutorial DÉSACTIVÉ - Après: $_isTutorialMode');
  }

  /// Données de démonstration pour Nutrition
  static const nutritionDemoData = {
    'calories_consumed': 0,
    'calories_target': 2000,
    'proteins': 0.0,
    'carbs': 0.0,
    'fats': 0.0,
    'fiber': 0.0,
    'water_glasses': 0,
    'water_target': 8,
    'meals_count': 0,
    'meals': [],
  };

  /// Données de démonstration pour Sport
  static const sportDemoData = {
    'calories_burned': 0,
    'sessions_count': 0,
    'streak_weeks': 0,
    'total_time_minutes': 0,
    'activities': [],
  };

  /// Données de démonstration pour Cardio
  static const cardioDemoData = {
    'total_distance': 0.0,
    'total_calories': 0,
    'total_time_minutes': 0,
    'sessions_count': 0,
    'sessions': [],
    'last_session': null,
  };
}
