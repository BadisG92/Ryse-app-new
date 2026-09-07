import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cardio_session_models.dart';
import 'analytics_service.dart';
import 'cardio_service.dart';
import 'global_state_manager.dart';
import 'notification_service.dart';
import 'sport_dashboard_service.dart';
import 'weekly_planner_service.dart';

/// Ce qu'une séance terminée a produit, pour la feuille de résumé.
class SessionResult {
  const SessionResult({required this.saved, required this.minutes, required this.kcal, this.sessionId, this.distanceKm});

  final bool saved;
  final int minutes;
  final int kcal;
  final String? sessionId;
  final double? distanceKm;
}

/// La fin d'une séance cardio, en un seul endroit.
///
/// Cinq fichiers refaisaient la même queue à la main — sauvegarde,
/// invalidation, rafraîchissement, synchronisation du planificateur,
/// célébration — avec de la dérive : la synchronisation faite deux fois en
/// GPS, `DateTime.now()` au lieu du début de séance en HIIT. Ici elle est
/// écrite une fois. La musculation a la sienne, `WorkoutSessionStore.finish`,
/// parce qu'elle passe par une file locale.
class SportSessionFlow {
  SportSessionFlow._();

  /// Enregistre une séance cardio (course, marche, vélo, HIIT).
  ///
  /// `CardioService.saveCompletedCardioSession` reste le seul point
  /// d'écriture — et c'est lui qui fait déjà avancer la série. La
  /// synchronisation du planificateur part de `startTime`, jamais de
  /// maintenant : une séance finie après minuit reste celle de la veille.
  static Future<SessionResult> finishCardio(
    CardioSessionData session, {
    required String intensity,
    String? notes,
  }) async {
    final minutes = session.duration.inMinutes;
    final kcal = session.calories;
    String? sessionId;
    try {
      sessionId = await CardioService.saveCompletedCardioSession(
        sessionData: session,
        intensity: intensity,
        notes: notes,
      );
    } catch (e) {
      debugPrint('SportSessionFlow.finishCardio: $e');
      return SessionResult(saved: false, minutes: minutes, kcal: kcal, distanceKm: session.distance);
    }

    CardioService.invalidateCache();
    SportDashboardService.invalidateCache();
    try {
      await GlobalStateManager.instance.refreshSportData();
    } catch (_) {}

    try {
      await WeeklyPlannerService.syncCardioSessionToPlanner(
        sessionId: sessionId,
        activityType: session.activityType,
        activityTitle: session.activityTitle,
        sessionDate: session.startTime,
        durationMinutes: minutes,
        distanceKm: session.distance > 0 ? session.distance : null,
      );
    } catch (e) {
      debugPrint('SportSessionFlow: planner sync $e');
    }

    unawaited(NotificationService().updateLastActivity());
    unawaited(NotificationService().cancelPlannedActivityReminder());
    unawaited(NotificationService().cancelActivityBasedReminders());
    unawaited(AnalyticsService.logWorkoutCompleted(
      workoutType: session.activityType == 'hiit' ? 'hiit' : 'cardio',
      durationMinutes: minutes,
      caloriesBurned: kcal,
    ));

    return SessionResult(saved: true, minutes: minutes, kcal: kcal, sessionId: sessionId, distanceKm: session.distance);
  }
}
