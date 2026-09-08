import 'package:flutter/foundation.dart';

import '../../models/weekly_planner_models.dart';
import '../../services/app_navigator.dart';
import '../../services/localization_service.dart';
import '../../services/meal_planner_sync_service.dart';
import '../../services/translations.dart';
import '../../services/planner_ai_service.dart';
import '../../services/weekly_planner_service.dart';
import '../../sport/sport_start.dart';
import 'ryze_tool.dart';

/// Ce que Ryze peut lancer ou cocher dans la semaine.
///
/// Son prompt lui faisait dire « va dans l'onglet Sport pour le lancer ». Il
/// la lance.
class SportTools {
  SportTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  /// Le jour nommé par le modèle, dans la semaine affichée.
  static DateTime? _dateFor(String? day) {
    if (day == null || day.trim().isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return PlannerAIService.dateForDayName(day.trim().toLowerCase());
  }

  /// Lancer la séance prévue.
  static final startWorkout = RyzeTool(
    name: 'sport.start_planned_workout',
    declaration: toolSchema(
      name: 'sport.start_planned_workout',
      description:
          'Open and start the strength session already planned for a day, so the user '
          'can begin right away. Use it when they say they are ready to train. Do not '
          'use it to create a session.',
      properties: {
        'day': {
          'type': 'string',
          'description': 'Day of the planned session. Defaults to today.',
          'enum': [
            'monday', 'tuesday', 'wednesday', 'thursday',
            'friday', 'saturday', 'sunday',
          ],
        },
      },
    ),
    execute: (args) async {
      final date = _dateFor(args['day'] as String?);
      if (date == null) return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));

      final PlannedWorkout? workout;
      try {
        workout = await WeeklyPlannerService.findPlannedWorkoutForDate(date);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ sport.start_planned_workout : $e');
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }

      if (workout == null) {
        // Rien de prévu n'est pas une panne : Ryze doit pouvoir le dire et
        // proposer d'en planifier une.
        return RyzeToolResult(
          ok: false,
          summary: 'ryze_no_planned_workout'.tr(_lang),
          data: {'found': false},
        );
      }

      // Le contexte est relu après les attentes, jamais gardé au travers :
      // l'écran a pu partir pendant que la séance se chargeait.
      final context = AppNavigator().safestContext;
      if (context == null || !context.mounted) {
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }

      await SportStart.plannedWorkout(context, workout);
      return RyzeToolResult(
        ok: true,
        summary: 'ryze_workout_started'.tr(_lang).replaceAll('{name}', workout.workoutName),
        data: {'started': true, 'workout': workout.workoutName},
      );
    },
  );

  /// Cocher un repas planifié comme mangé.
  ///
  /// Avec confirmation : cocher écrit dans le journal, ajoute des calories et
  /// change le bilan du jour.
  static final markMealEaten = RyzeTool(
    name: 'plan.mark_meal_eaten',
    declaration: toolSchema(
      name: 'plan.mark_meal_eaten',
      description:
          'Mark a planned meal as actually eaten, which logs it in the journal. Use it '
          'when the user says they ate what was planned. If they ate something else, '
          'use journal.log_food_text instead.',
      properties: {
        'meal_type': {
          'type': 'string',
          'description': 'Which meal of the day.',
          'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
        },
        'day': {
          'type': 'string',
          'description': 'Day of the planned meal. Defaults to today.',
          'enum': [
            'monday', 'tuesday', 'wednesday', 'thursday',
            'friday', 'saturday', 'sunday',
          ],
        },
      },
      required: ['meal_type'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) async {
      final activity = await _findMeal(args);
      final name = activity?.mealData?.displayName ?? '';
      return RyzePending(
        id: 'meal-${DateTime.now().microsecondsSinceEpoch}',
        toolName: 'plan.mark_meal_eaten',
        title: 'ryze_confirm_meal_eaten'.tr(_lang).replaceAll('{name}', name),
        detail: activity?.mealData?.calories != null
            ? '${activity!.mealData!.calories} kcal'
            : null,
        commit: () => _validate(activity),
      );
    },
    execute: (args) async => _validate(await _findMeal(args)),
  );

  static Future<PlannedActivity?> _findMeal(Map<String, dynamic> args) async {
    final date = _dateFor(args['day'] as String?);
    if (date == null) return null;

    final type = PlannedActivityType.values.firstWhere(
      (t) => t.value == '${args['meal_type']}',
      orElse: () => PlannedActivityType.lunch,
    );

    try {
      final week = await WeeklyPlannerService.getWeekData();
      final day = week.getDayPlan(date);
      return day?.meals.firstWhere(
        (m) => m.activityType == type && m.status != PlannedStatus.completed,
        orElse: () => throw StateError('aucun'),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<RyzeToolResult> _validate(PlannedActivity? activity) async {
    if (activity == null) {
      return RyzeToolResult(
        ok: false,
        summary: 'ryze_no_planned_meal'.tr(_lang),
        data: {'found': false},
      );
    }

    try {
      final entryId = await MealPlannerSyncService.validateMeal(activity);
      if (entryId == null) return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));

      final name = activity.mealData?.displayName ?? '';
      return RyzeToolResult(
        ok: true,
        summary: 'ryze_meal_marked_eaten'.tr(_lang).replaceAll('{name}', name),
        data: {'logged': true, 'meal': name, 'calories': activity.mealData?.calories},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ plan.mark_meal_eaten : $e');
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    }
  }

  static List<RyzeTool> get all => [startWorkout, markMealEaten];
}
