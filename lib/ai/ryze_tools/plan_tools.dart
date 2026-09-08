import 'package:flutter/foundation.dart';

import '../../models/weekly_planner_models.dart';
import '../../services/localization_service.dart';
import '../../services/planner_ai_service.dart';
import '../../services/translations.dart';
import '../ryze_persona.dart';
import 'ryze_tool.dart';

/// Écrire dans la semaine, depuis la conversation.
///
/// Le coach savait lire le plan et cocher un repas prévu ; il ne savait pas y
/// écrire. Demander une recette ou une séance ouvrait le planificateur, avec
/// la demande déjà transmise mais un changement d'écran au milieu de la
/// discussion.
///
/// Rien n'est réécrit ici. Les exécuteurs du planificateur sont bons et
/// éprouvés — les calories y sont recalculées depuis les macros, les exercices
/// ancrés sur la base, les jours vérifiés — et ce fichier ne fait que les
/// brancher sur le registre partagé. C'est aussi la première moitié de la
/// fusion : au lot suivant, l'écran du planificateur lira ses déclarations
/// ici, et ces outils gagneront simplement `RyzeSurface.planner`.
class PlanTools {
  PlanTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  /// Appelle un outil du planificateur et traduit sa réponse.
  static Future<RyzeToolResult> _run(String name, Map<String, dynamic> args) async {
    try {
      final out = await PlannerAIService.executeToolCall(name, args, _lang);

      // Les créations ne écrivent pas : elles rendent un objet en attente que
      // l'utilisateur valide. C'est ce qui protège sa semaine d'une IA trop
      // sûre d'elle, et ça se garde tel quel.
      final pendingMeal = out['pending_meal'] as PendingMeal?;
      final pendingWorkout = out['pending_workout'] as PendingWorkout?;
      final pendingCardio = out['pending_cardio'] as PendingCardio?;

      if (pendingMeal != null) {
        final result = await PlannerAIService.confirmMeals([pendingMeal]);
        return RyzeToolResult(
          ok: result.success,
          summary: result.message,
          data: {'created': result.success, 'kind': 'meal'},
        );
      }
      if (pendingWorkout != null || pendingCardio != null) {
        final session = pendingWorkout != null
            ? PendingSession.fromWorkout(pendingWorkout)
            : PendingSession.fromCardio(pendingCardio!);
        final result = await PlannerAIService.confirmSingleSession(session);
        return RyzeToolResult(
          ok: result.success,
          summary: result.message,
          data: {'created': result.success, 'kind': 'session'},
        );
      }

      final ok = out['success'] == true;
      final message = '${out['message'] ?? ''}'.trim();
      return RyzeToolResult(
        ok: ok,
        summary: message.isEmpty ? 'ryze_action_failed'.tr(_lang) : message,
        data: {'success': ok},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ $name : $e');
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    }
  }

  /// Une carte de validation, pour ce qui se défait mal.
  static Future<RyzePending> _confirm(
    String toolName,
    Map<String, dynamic> args,
    String title,
  ) async =>
      RyzePending(
        id: '$toolName-${DateTime.now().microsecondsSinceEpoch}',
        toolName: toolName,
        title: title,
        commit: () => _run(toolName, args),
      );

  // ------------------------------------------------------------- créations

  static final createMeal = RyzeTool(
    name: 'plan.create_meal',
    declaration: toolSchema(
      name: 'plan.create_meal',
      description:
          'Add a meal to the weekly plan. Use it when the user wants something planned '
          'for a coming meal, including a dish you just suggested. Do not use it to log '
          'something already eaten. Adding a second entry of the same meal type is '
          'allowed; only replace with plan.modify_meal when they say to replace.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the meal.', 'enum': _days},
        'meal_type': {
          'type': 'string',
          'description': 'Which meal of the day.',
          'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
        },
        'dish_name': {'type': 'string', 'description': 'Short name of the dish.'},
        'dish_description': {
          'type': 'string',
          'description':
              'Description then ingredients, recipe and tip, separated by "---", with '
              'section names in the user\'s language.',
        },
        'calories': {'type': 'integer', 'description': 'Estimated calories.'},
        'proteins': {'type': 'number', 'description': 'Proteins in grams.'},
        'carbs': {'type': 'number', 'description': 'Carbs in grams.'},
        'fats': {'type': 'number', 'description': 'Fats in grams.'},
        'quantity_g': {'type': 'number', 'description': 'Portion size in grams.'},
      },
      required: ['day', 'meal_type', 'dish_name', 'calories', 'proteins', 'carbs', 'fats', 'quantity_g'],
    ),
    execute: (args) => _run('create_meal', args),
  );

  static final createWorkout = RyzeTool(
    name: 'plan.create_workout',
    declaration: toolSchema(
      name: 'plan.create_workout',
      description:
          'Add a strength session to the weekly plan, with its exercises generated for '
          'the user. Use it when they want to plan training ahead. Ask for the muscle '
          'group and the duration first if they did not say; do not guess them.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'workout_type': {
          'type': 'string',
          'description': 'Muscle group or split: Chest, Back, Legs, Full Body, Arms, Shoulders...',
        },
        'duration_minutes': {
          'type': 'integer',
          'description': 'Length in minutes, between 15 and 120.',
        },
      },
      required: ['day', 'workout_type', 'duration_minutes'],
    ),
    execute: (args) => _run('create_workout', args),
  );

  static final createCardio = RyzeTool(
    name: 'plan.create_cardio',
    declaration: toolSchema(
      name: 'plan.create_cardio',
      description:
          'Add a cardio session to the weekly plan. Only running, cycling and walking '
          'are supported; for intervals use plan.create_hiit. Give at least a duration '
          'or a distance.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'activity': {
          'type': 'string',
          'description': 'Which activity.',
          'enum': ['running', 'bike', 'walking'],
        },
        'duration_minutes': {'type': 'integer', 'description': 'Length in minutes.'},
        'target_km': {'type': 'number', 'description': 'Distance in kilometres.'},
      },
      required: ['day', 'activity'],
    ),
    execute: (args) => _run('create_cardio', args),
  );

  // ------------------------------------------------- déplacer et modifier

  static final moveWorkout = RyzeTool(
    name: 'plan.move_workout',
    declaration: toolSchema(
      name: 'plan.move_workout',
      description:
          'Move a planned strength session from one day to another, keeping everything '
          'else. Use it only for a change of day; to change type or length use '
          'plan.modify_workout.',
      properties: {
        'current_day': {'type': 'string', 'description': 'Where it is now.', 'enum': _days},
        'new_day': {'type': 'string', 'description': 'Where it goes.', 'enum': _days},
      },
      required: ['current_day', 'new_day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'move_workout',
      args,
      'ryze_confirm_move'.tr(_lang).replaceAll('{from}', '${args['current_day']}').replaceAll('{to}', '${args['new_day']}'),
    ),
    execute: (args) => _run('move_workout', args),
  );

  static final modifyWorkout = RyzeTool(
    name: 'plan.modify_workout',
    declaration: toolSchema(
      name: 'plan.modify_workout',
      description:
          'Change a planned strength session: its muscle group, its length, or turn it '
          'into cardio. Use it when the session stays on the same day and only its '
          'content changes, and use it instead of deleting then recreating — the tool '
          'replaces the session itself.',
      properties: {
        'current_day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'new_workout_type': {'type': 'string', 'description': 'New muscle group or split.'},
        'new_duration_minutes': {'type': 'integer', 'description': 'New length in minutes.'},
        'regenerate_exercises': {
          'type': 'boolean',
          'description': 'True when the muscle group changes, so exercises are rebuilt.',
        },
      },
      required: ['current_day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'modify_workout',
      args,
      'ryze_confirm_modify'.tr(_lang).replaceAll('{day}', '${args['current_day']}'),
    ),
    execute: (args) => _run('modify_workout', args),
  );

  // ------------------------------------------------------------ retirer

  static final deleteMeal = RyzeTool(
    name: 'plan.delete_meal',
    declaration: toolSchema(
      name: 'plan.delete_meal',
      description:
          'Remove a planned meal. Use it only when the user wants it gone with nothing '
          'in its place; to swap it use plan.modify_meal.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the meal.', 'enum': _days},
        'meal_type': {
          'type': 'string',
          'description': 'Which meal.',
          'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
        },
      },
      required: ['day', 'meal_type'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'delete_meal',
      args,
      'ryze_confirm_delete_meal'.tr(_lang).replaceAll('{day}', '${args['day']}'),
    ),
    execute: (args) => _run('delete_meal', args),
  );

  static final deleteWorkout = RyzeTool(
    name: 'plan.delete_workout',
    declaration: toolSchema(
      name: 'plan.delete_workout',
      description:
          'Remove a planned strength session. Use it only when the user wants that day '
          'emptied; to change the session use plan.modify_workout.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
      },
      required: ['day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'delete_workout',
      args,
      'ryze_confirm_delete_workout'.tr(_lang).replaceAll('{day}', '${args['day']}'),
    ),
    execute: (args) => _run('delete_workout', args),
  );

  /// Les outils d'écriture du plan, pour la conversation.
  ///
  /// Ils gagneront `RyzeSurface.planner` quand l'écran rejoindra le registre.
  static List<RyzeTool> get all => [
        createMeal,
        createWorkout,
        createCardio,
        moveWorkout,
        modifyWorkout,
        deleteMeal,
        deleteWorkout,
      ];

  /// Les surfaces sur lesquelles ces outils vivent aujourd'hui.
  static const Set<RyzeSurface> surfaces = {RyzeSurface.coach};
}
