import 'package:flutter/material.dart';
import '../components/ui/tutorial_image_overlay.dart';
import 'translations.dart';

/// Configuration des tutorials avec positions exactes
/// Les positions sont en pourcentage de l'écran (0.0 à 1.0)
class TutorialConfig {

  /// Tutorial Nutrition Dashboard
  static List<TutorialStep> getNutritionSteps(String languageCode) {
    return [
      // Étape 1: Carte Calories
      TutorialStep(
        title: 'tutorial_nutrition_calories_title'.tr(languageCode),
        description: 'tutorial_nutrition_calories_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.35), // Position de la bulle
        targetPosition: const Offset(0.05, 0.15), // Position de la cible
        targetSize: const Size(0.9, 0.15), // Taille de la cible
        isTop: false,
      ),

      // Étape 2: Carte Macros
      TutorialStep(
        title: 'tutorial_nutrition_macros_title'.tr(languageCode),
        description: 'tutorial_nutrition_macros_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.55),
        targetPosition: const Offset(0.05, 0.32),
        targetSize: const Size(0.9, 0.18),
        isTop: true,
      ),

      // Étape 3: Hydratation & Repas
      TutorialStep(
        title: 'tutorial_nutrition_hydration_meals_title'.tr(languageCode),
        description: 'tutorial_nutrition_hydration_meals_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.52),
        targetSize: const Size(0.9, 0.12),
        isTop: false,
      ),

      // Étape 4: Actions rapides
      TutorialStep(
        title: 'tutorial_nutrition_quick_actions_title'.tr(languageCode),
        description: 'tutorial_nutrition_quick_actions_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.66),
        targetSize: const Size(0.9, 0.25),
        isTop: false,
      ),
    ];
  }

  /// Tutorial Sport Dashboard
  static List<TutorialStep> getSportSteps(String languageCode) {
    return [
      // Étape 1: Calories brûlées
      TutorialStep(
        title: 'tutorial_sport_calories_title'.tr(languageCode),
        description: 'tutorial_sport_calories_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.35),
        targetPosition: const Offset(0.05, 0.15),
        targetSize: const Size(0.9, 0.15),
        isTop: false,
      ),

      // Étape 2: Progression de la semaine
      TutorialStep(
        title: 'tutorial_sport_sessions_title'.tr(languageCode),
        description: 'tutorial_sport_sessions_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.55),
        targetPosition: const Offset(0.05, 0.32),
        targetSize: const Size(0.9, 0.15),
        isTop: true,
      ),

      // Étape 3: Activités du jour
      TutorialStep(
        title: 'tutorial_sport_split_title'.tr(languageCode),
        description: 'tutorial_sport_split_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.49),
        targetSize: const Size(0.9, 0.12),
        isTop: false,
      ),

      // Étape 4: Démarrer une activité
      TutorialStep(
        title: 'tutorial_sport_actions_title'.tr(languageCode),
        description: 'tutorial_sport_actions_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.63),
        targetSize: const Size(0.9, 0.2),
        isTop: false,
      ),
    ];
  }

  /// Tutorial Cardio
  static List<TutorialStep> getCardioSteps(String languageCode) {
    return [
      // Étape 1: Statistiques de la semaine
      TutorialStep(
        title: 'tutorial_cardio_stats_title'.tr(languageCode),
        description: 'tutorial_cardio_stats_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.35),
        targetPosition: const Offset(0.05, 0.15),
        targetSize: const Size(0.9, 0.15),
        isTop: false,
      ),

      // Étape 2: Choisir une activité
      TutorialStep(
        title: 'tutorial_cardio_activities_title'.tr(languageCode),
        description: 'tutorial_cardio_activities_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.55),
        targetPosition: const Offset(0.05, 0.32),
        targetSize: const Size(0.9, 0.18),
        isTop: true,
      ),

      // Étape 3: Dernière séance
      TutorialStep(
        title: 'tutorial_cardio_last_session_title'.tr(languageCode),
        description: 'tutorial_cardio_last_session_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.52),
        targetSize: const Size(0.9, 0.12),
        isTop: false,
      ),

      // Étape 4: Séances de la semaine
      TutorialStep(
        title: 'tutorial_cardio_week_sessions_title'.tr(languageCode),
        description: 'tutorial_cardio_week_sessions_desc'.tr(languageCode),
        bubblePosition: const Offset(0.075, 0.15),
        targetPosition: const Offset(0.05, 0.66),
        targetSize: const Size(0.9, 0.15),
        isTop: false,
      ),
    ];
  }

  /// Chemins vers les images des tutorials
  static const String nutritionImagePath = 'assets/images/tutorials/nutrition_dashboard_empty.png';
  static const String sportImagePath = 'assets/images/tutorials/sport_dashboard_empty.png';
  static const String cardioImagePath = 'assets/images/tutorials/cardio_dashboard_empty.png';
}
