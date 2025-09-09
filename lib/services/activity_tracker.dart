import 'progress_service_v2.dart';
import 'streak_service.dart';

/// Service pour tracker les nouvelles activités et mettre à jour les caches
class ActivityTracker {
  
  /// Notifier qu'une nouvelle séance de sport a été complétée
  static void notifyWorkoutCompleted() {
    print('🏋️ Séance de sport terminée - rafraîchissement du cache progression');
    ProgressServiceV2.refreshAfterActivity();
    StreakService.notifyActivity(); // Mettre à jour la streak
  }
  
  /// Notifier qu'une nouvelle séance de cardio a été complétée
  static void notifyCardioCompleted() {
    print('🏃 Séance de cardio terminée - rafraîchissement du cache progression');
    ProgressServiceV2.refreshAfterActivity();
    StreakService.notifyActivity(); // Mettre à jour la streak
  }
  
  /// Notifier qu'un nouveau repas a été ajouté
  static void notifyFoodAdded() {
    print('🍽️ Nouveau repas ajouté - rafraîchissement du cache progression');
    ProgressServiceV2.refreshAfterActivity();
    StreakService.notifyActivity(); // Mettre à jour la streak
  }
  
  /// Notifier qu'une entrée d'eau a été ajoutée
  static void notifyWaterAdded() {
    print('💧 Eau ajoutée - rafraîchissement du cache progression');
    ProgressServiceV2.refreshAfterActivity();
    StreakService.notifyActivity(); // Mettre à jour la streak
  }
  
  /// Notifier qu'un objectif a été complété
  static void notifyGoalCompleted() {
    print('🎯 Objectif complété - rafraîchissement du cache progression');
    ProgressServiceV2.refreshAfterActivity();
    StreakService.notifyActivity(); // Mettre à jour la streak
  }
}
