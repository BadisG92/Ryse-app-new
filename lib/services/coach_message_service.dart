import 'package:flutter/foundation.dart';
import 'translations.dart';
import 'global_state_manager.dart';

/// Service pour générer des messages de coach personnalisés
/// Utilisé par le widget lock screen pour afficher des conseils contextuels
class CoachMessageService {
  /// Génère un message de coach basé sur le contexte actuel
  ///
  /// Prend en compte:
  /// - L'heure de la journée
  /// - Les calories consommées vs objectif
  /// - L'apport en protéines
  /// - L'hydratation
  /// - Le streak de l'utilisateur
  static String generateCoachMessage(String languageCode) {
    final globalState = GlobalStateManager.instance;
    final hour = DateTime.now().hour;

    // Récupérer les données
    final currentCalories = globalState.currentCalories;
    final calorieGoal = globalState.calorieGoal;
    final double caloriePercentage = calorieGoal > 0
        ? (currentCalories / calorieGoal * 100)
        : 0.0;

    final currentWaterL = globalState.currentWaterL;
    final waterGoalL = globalState.waterGoalL;
    final double waterPercentage = waterGoalL > 0
        ? (currentWaterL / waterGoalL * 100)
        : 0.0;

    final currentProteins = globalState.currentProteins;
    final proteinGoal = globalState.proteinGoal;
    final double proteinPercentage = proteinGoal > 0
        ? (currentProteins / proteinGoal * 100)
        : 0.0;

    final streak = globalState.currentStreak;
    final mealsCount = globalState.mealsCount;

    if (kDebugMode) {
      debugPrint('🤖 CoachMessage: Génération du message...');
      debugPrint('   - Heure: $hour');
      debugPrint('   - Calories: ${caloriePercentage.toInt()}%');
      debugPrint('   - Eau: ${waterPercentage.toInt()}%');
      debugPrint('   - Protéines: ${proteinPercentage.toInt()}%');
      debugPrint('   - Streak: $streak jours');
      debugPrint('   - Repas: $mealsCount');
    }

    // Priorité 1: Milestones de streak (messages spéciaux)
    if (streak == 7) {
      return AppTranslations.get('coach_streak_7', languageCode);
    } else if (streak == 14) {
      return AppTranslations.get('coach_streak_14', languageCode);
    } else if (streak == 30 || streak == 31) {
      return AppTranslations.get('coach_streak_30', languageCode);
    }

    // Priorité 2: Messages contextuels selon l'heure
    String messageKey = _getContextualMessageKey(
      hour: hour,
      caloriePercentage: caloriePercentage,
      waterPercentage: waterPercentage,
      proteinPercentage: proteinPercentage,
      mealsCount: mealsCount,
    );

    final message = AppTranslations.get(messageKey, languageCode);

    if (kDebugMode) {
      debugPrint('   - Message sélectionné: $messageKey');
      debugPrint('   - Contenu: $message');
    }

    return message;
  }

  /// Détermine la clé du message selon le contexte
  static String _getContextualMessageKey({
    required int hour,
    required double caloriePercentage,
    required double waterPercentage,
    required double proteinPercentage,
    required int mealsCount,
  }) {
    // MATIN (6h-10h)
    if (hour >= 6 && hour < 10) {
      if (mealsCount == 0) {
        return 'coach_morning_no_breakfast';
      } else {
        return 'coach_morning_has_breakfast';
      }
    }

    // MIDI (11h-14h)
    if (hour >= 11 && hour < 14) {
      if (caloriePercentage < 25) {
        return 'coach_lunch_low_calories';
      } else {
        return 'coach_lunch_on_track';
      }
    }

    // APRÈS-MIDI (14h-18h)
    if (hour >= 14 && hour < 18) {
      if (proteinPercentage < 50 && caloriePercentage > 40) {
        return 'coach_afternoon_low_protein';
      } else {
        return 'coach_afternoon_good';
      }
    }

    // DÎNER (18h-21h)
    if (hour >= 18 && hour < 21) {
      if (caloriePercentage >= 90) {
        return 'coach_dinner_over_budget';
      } else if (caloriePercentage >= 70) {
        return 'coach_dinner_almost_goal';
      } else {
        return 'coach_lunch_on_track'; // Réutiliser "En bonne voie"
      }
    }

    // SOIRÉE (21h-6h)
    if (hour >= 21 || hour < 6) {
      if (caloriePercentage >= 90 && caloriePercentage <= 110) {
        return 'coach_evening_goal_reached';
      } else if (waterPercentage < 70) {
        return 'coach_evening_water_low';
      } else {
        return 'coach_evening_goal_reached';
      }
    }

    // Fallback
    return 'coach_default';
  }

  /// Génère les données du message pour le widget iOS
  /// Retourne un Map prêt à être sérialisé en JSON
  static Map<String, dynamic> generateCoachMessageData(String languageCode) {
    final message = generateCoachMessage(languageCode);
    final hour = DateTime.now().hour;

    return {
      'message': message,
      'generatedAt': DateTime.now().toIso8601String(),
      'timeContext': _getTimeContext(hour),
    };
  }

  /// Retourne le contexte temporel (pour debug/analytics)
  static String _getTimeContext(int hour) {
    if (hour >= 6 && hour < 10) return 'morning';
    if (hour >= 11 && hour < 14) return 'lunch';
    if (hour >= 14 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 21) return 'dinner';
    return 'evening';
  }
}
