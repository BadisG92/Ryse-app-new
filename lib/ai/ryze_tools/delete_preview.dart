import 'package:flutter/foundation.dart';

import '../../models/weekly_planner_models.dart';
import '../../services/planner_ai_service.dart';
import '../../services/translations.dart';
import '../../services/weekly_planner_service.dart';

/// Ce qu'une suppression va réellement emporter.
///
/// Les cartes de suppression annonçaient une catégorie, jamais son contenu :
/// « Retirer ces séances ? » pour une demande qui ne visait qu'un jour,
/// « Retirer ce repas de jeudi ? » sans dire lequel des quatre. On confirmait
/// donc à l'aveugle — et une fois, une demande de retirer « la séance de
/// sport » a emporté un cardio sans que rien à l'écran ne le laisse voir.
///
/// Le plan est lu avant de proposer, et la carte nomme ce qu'elle va défaire.
class DeletePreview {
  DeletePreview._();

  /// Au plus ce nombre de lignes dans une carte ; au-delà, un décompte.
  static const int maxLines = 6;

  /// Les jours visés par une suppression en masse.
  ///
  /// Aucun jour donné veut dire toute la semaine, moins ceux qu'on épargne.
  static List<DateTime> daysOf(Map<String, dynamic> args, List<DateTime> week) {
    final demandes = (args['days'] as List?)?.map((d) => '$d').toList() ?? const [];
    final exclus = (args['exclude_days'] as List?)?.map((d) => '$d').toList() ?? const [];

    DateTime? jour(String nom) => PlannerAIService.dateForDayName(nom);
    bool memeJour(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final base = demandes.isEmpty
        ? week
        : [for (final d in demandes) jour(d)].whereType<DateTime>().toList();

    final aEpargner = [for (final d in exclus) jour(d)].whereType<DateTime>().toList();
    return [
      for (final d in base)
        if (!aEpargner.any((e) => memeJour(e, d))) d,
    ];
  }

  /// Les séances d'un jour, nommées : « jeudi · Dos, 45 min ».
  static List<String> _sessionLines(
    DayPlanData? plan,
    String lang,
    String jourDit, {
    required bool muscu,
    required bool cardio,
  }) {
    if (plan == null) return const [];
    final out = <String>[];

    if (muscu) {
      for (final w in plan.workouts) {
        if (w.status == PlannedStatus.completed) continue;
        final duree = w.durationMinutes != null && w.durationMinutes! > 0
            ? ', ${w.durationMinutes} min'
            : '';
        out.add('$jourDit · ${w.workoutName}$duree');
      }
    }

    if (cardio) {
      for (final a in plan.activities) {
        if (a.activityType != PlannedActivityType.cardio) continue;
        if (a.status == PlannedStatus.completed) continue;
        final nom = '${a.activityData['activity_name'] ?? ''}'.trim();
        final km = a.activityData['target_km'];
        final min = a.activityData['target_minutes'];
        final detail = km is num && km > 0
            ? ', ${km.toStringAsFixed(1)} km'
            : (min is num && min > 0 ? ', ${min.round()} min' : '');
        out.add('$jourDit · ${nom.isEmpty ? 'cardio_word'.tr(lang) : nom}$detail');
      }
    }

    return out;
  }

  /// Les repas d'un jour, nommés : « jeudi · déjeuner, Saumon ».
  static List<String> _mealLines(DayPlanData? plan, String lang, String jourDit) {
    if (plan == null) return const [];
    return [
      for (final a in plan.activities)
        if (a.activityType != PlannedActivityType.cardio &&
            a.status != PlannedStatus.completed)
          '$jourDit · ${'meal_name_${a.activityType.value}'.tr(lang).toLowerCase()}'
              ', ${'${a.activityData['dish_name'] ?? ''}'.trim().isEmpty ? 'meal_word'.tr(lang) : a.activityData['dish_name']}',
    ];
  }

  /// Le détail à poser sous le titre d'une carte de suppression.
  ///
  /// Rend `null` quand il n'y a rien à nommer : la carte garde alors son
  /// titre seul, ce qui vaut mieux qu'une liste vide.
  static Future<String?> detailFor(
    String tool,
    Map<String, dynamic> args,
    String lang,
    String Function(Object?) dayLabel,
  ) async {
    try {
      final semaine = await WeeklyPlannerService.getWeekData();
      final plans = semaine.dayPlans;

      DayPlanData? planDe(DateTime d) => plans[DateTime(d.year, d.month, d.day)];
      final tousLesJours = plans.keys.toList()..sort();

      final lignes = <String>[];

      switch (tool) {
        case 'delete_workout':
        case 'delete_cardio':
          final jour = PlannerAIService.dateForDayName('${args['day']}');
          if (jour == null) return null;
          lignes.addAll(_sessionLines(
            planDe(jour),
            lang,
            dayLabel(args['day']),
            muscu: tool == 'delete_workout',
            cardio: tool == 'delete_cardio',
          ));

        case 'delete_sessions':
          final types = (args['session_types'] as List?)?.map((t) => '$t').toSet() ?? const {};
          final muscu = types.isEmpty || types.contains('workout');
          final cardio = types.isEmpty || types.contains('cardio');
          for (final jour in daysOf(args, tousLesJours)) {
            lignes.addAll(_sessionLines(
              planDe(jour),
              lang,
              dayLabel(_dayKey(jour)),
              muscu: muscu,
              cardio: cardio,
            ));
          }

        case 'delete_meal':
          final jour = PlannerAIService.dateForDayName('${args['day']}');
          if (jour == null) return null;
          final voulu = '${args['meal_type'] ?? ''}'.trim();
          final duJour = _mealLines(planDe(jour), lang, dayLabel(args['day']));
          lignes.addAll(voulu.isEmpty
              ? duJour
              : duJour.where((l) =>
                  l.toLowerCase().contains('meal_name_$voulu'.tr(lang).toLowerCase())));

        case 'delete_all_meals':
          for (final jour in tousLesJours) {
            lignes.addAll(_mealLines(planDe(jour), lang, dayLabel(_dayKey(jour))));
          }
      }

      if (lignes.isEmpty) return null;

      final montrees = lignes.take(maxLines).toList();
      final reste = lignes.length - montrees.length;
      if (reste > 0) montrees.add('+ $reste');
      return montrees.join('\n');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ DeletePreview : $e');
      // Une carte sans détail vaut mieux qu'une carte qui n'arrive pas.
      return null;
    }
  }

  /// Le nom anglais du jour, celui que `dayLabel` sait traduire.
  static String _dayKey(DateTime d) => const [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      ][d.weekday - 1];
}
