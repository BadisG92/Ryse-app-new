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
/// brancher sur le registre partagé. Les déclarations qui vivaient en double,
/// une copie par moteur, n'existent plus qu'ici : les deux surfaces lisent la
/// même liste.
class PlanTools {
  PlanTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  /// Appelle un outil du planificateur et traduit sa réponse.
  ///
  /// Une création **n'écrit pas** : l'exécuteur bâtit un objet en attente, avec
  /// ses macros ou ses exercices, et il repart en `payload`. La surface décide
  /// ensuite comment le montrer, et rien n'entre dans la semaine avant un oui.
  /// C'est ce qui protège la semaine d'une IA trop sûre d'elle.
  static Future<RyzeToolResult> _run(String name, Map<String, dynamic> args) async {
    try {
      final out = await PlannerAIService.executeToolCall(name, args, _lang);

      final pendingMeal = out['pending_meal'] as PendingMeal?;
      final pendingWorkout = out['pending_workout'] as PendingWorkout?;
      final pendingCardio = out['pending_cardio'] as PendingCardio?;

      if (pendingMeal != null) {
        return RyzeToolResult(
          ok: true,
          summary: pendingMeal.dishName,
          data: {'proposed': 'meal', 'dish': pendingMeal.dishName, 'calories': pendingMeal.calories},
          payload: pendingMeal,
        );
      }
      if (pendingWorkout != null || pendingCardio != null) {
        final session = pendingWorkout != null
            ? PendingSession.fromWorkout(pendingWorkout)
            : PendingSession.fromCardio(pendingCardio!);
        return RyzeToolResult(
          ok: true,
          summary: session.displayTitle,
          data: {'proposed': 'session', 'name': session.displayTitle},
          payload: session,
        );
      }

      final ok = out['success'] == true;
      final message = '${out['message'] ?? ''}'.trim();

      // Retirer ou déplacer se défait : l'exécuteur a gardé de quoi remettre
      // en place, et la bulle porte un « annuler » tant que rien d'autre n'a
      // eu lieu. Une création n'en a pas besoin, elle n'a encore rien écrit.
      final undoable = ok && name != 'undo_last_action' && PlannerAIService.hasUndo;

      return RyzeToolResult(
        ok: ok,
        summary: message.isEmpty ? 'ryze_action_failed'.tr(_lang) : message,
        data: {'success': ok},
        undo: undoable ? () => PlannerAIService.undoLastAction() : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ $name : $e');
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    }
  }

  /// Écrit pour de bon ce qu'une création a proposé.
  ///
  /// Appelé par la surface au moment du oui, jamais par l'outil.
  static Future<RyzeToolResult> commit(Object? payload) async {
    try {
      if (payload is PendingMeal) {
        final r = await PlannerAIService.confirmMeals([payload]);
        return RyzeToolResult(ok: r.success, summary: r.message, data: {'created': r.success});
      }
      if (payload is PendingSession) {
        final r = await PlannerAIService.confirmSingleSession(payload);
        return RyzeToolResult(ok: r.success, summary: r.message, data: {'created': r.success});
      }
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ commit : $e');
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    }
  }

  /// La carte d'une création : ce qui est proposé, avant que ça existe.
  static Future<RyzePending> _proposal(String toolName, Map<String, dynamic> args) async {
    final built = await _run(toolName, args);
    return RyzePending(
      id: '$toolName-${DateTime.now().microsecondsSinceEpoch}',
      toolName: toolName,
      title: built.ok ? built.summary : 'ryze_action_failed'.tr(_lang),
      detail: built.data['calories'] != null ? '${built.data['calories']} kcal' : null,
      commit: () => built.ok ? commit(built.payload) : Future.value(built),
    );
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
    surfaces: surfaces,
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
    needsConfirmation: (_) => true,
    preview: (args) => _proposal('create_meal', args),
    execute: (args) => _run('create_meal', args),
  );

  static final createWorkout = RyzeTool(
    name: 'plan.create_workout',
    surfaces: surfaces,
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
    needsConfirmation: (_) => true,
    preview: (args) => _proposal('create_workout', args),
    execute: (args) => _run('create_workout', args),
  );

  static final createCardio = RyzeTool(
    name: 'plan.create_cardio',
    surfaces: surfaces,
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
    needsConfirmation: (_) => true,
    preview: (args) => _proposal('create_cardio', args),
    execute: (args) => _run('create_cardio', args),
  );

  // ------------------------------------------------- déplacer et modifier

  static final moveWorkout = RyzeTool(
    name: 'plan.move_workout',
    surfaces: surfaces,
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
    surfaces: surfaces,
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

  static final createHiit = RyzeTool(
    name: 'plan.create_hiit',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.create_hiit',
      description:
          'Add an interval session to the weekly plan. Use it when the user asks for '
          'HIIT, tabata or intervals, rather than plan.create_cardio which is for '
          'steady effort.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'hiit_type': {
          'type': 'string',
          'description': 'Which format: beginner, classic, tabata, advanced.',
        },
        'work_seconds': {'type': 'integer', 'description': 'Seconds of effort per round.'},
        'rest_seconds': {'type': 'integer', 'description': 'Seconds of rest per round.'},
        'rounds': {'type': 'integer', 'description': 'Number of rounds.'},
      },
      required: ['day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _proposal('create_hiit', args),
    execute: (args) => _run('create_hiit', args),
  );

  static final moveCardio = RyzeTool(
    name: 'plan.move_cardio',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.move_cardio',
      description:
          'Move a planned cardio session from one day to another. Use it only for a '
          'change of day; to change the activity or its length use plan.modify_cardio.',
      properties: {
        'from_day': {'type': 'string', 'description': 'Where it is now.', 'enum': _days},
        'to_day': {'type': 'string', 'description': 'Where it goes.', 'enum': _days},
      },
      required: ['from_day', 'to_day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'move_cardio',
      args,
      'ryze_confirm_move'.tr(_lang).replaceAll('{from}', '${args['from_day']}').replaceAll('{to}', '${args['to_day']}'),
    ),
    execute: (args) => _run('move_cardio', args),
  );

  static final modifyCardio = RyzeTool(
    name: 'plan.modify_cardio',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.modify_cardio',
      description:
          'Change a planned cardio session: its activity, its length, its distance. Use '
          'it when the session stays and only its content changes. Always pass the new '
          'distance when the user gives one.',
      properties: {
        'current_day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'new_activity': {
          'type': 'string',
          'description': 'New activity.',
          'enum': ['running', 'bike', 'walking'],
        },
        'new_duration_minutes': {'type': 'integer', 'description': 'New length in minutes.'},
        'new_target_km': {'type': 'number', 'description': 'New distance in kilometres.'},
      },
      required: ['current_day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'modify_cardio',
      args,
      'ryze_confirm_modify'.tr(_lang).replaceAll('{day}', '${args['current_day']}'),
    ),
    execute: (args) => _run('modify_cardio', args),
  );

  static final modifyMeal = RyzeTool(
    name: 'plan.modify_meal',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.modify_meal',
      description:
          'Replace a planned meal with another one. Use it only when the user says to '
          'change or swap what is planned; to add a second dish to the same meal use '
          'plan.create_meal instead.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the meal.', 'enum': _days},
        'meal_type': {
          'type': 'string',
          'description': 'Which meal.',
          'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
        },
        'current_dish_name': {
          'type': 'string',
          'description':
              'Name of the dish being replaced. Needed when that day holds several '
              'entries of the same meal type.',
        },
        'dish_name': {'type': 'string', 'description': 'New dish name.'},
        'dish_description': {'type': 'string', 'description': 'New description, same format as create.'},
        'calories': {'type': 'integer', 'description': 'Estimated calories.'},
        'proteins': {'type': 'number', 'description': 'Proteins in grams.'},
        'carbs': {'type': 'number', 'description': 'Carbs in grams.'},
        'fats': {'type': 'number', 'description': 'Fats in grams.'},
        'quantity_g': {'type': 'number', 'description': 'Portion size in grams.'},
      },
      required: ['day', 'meal_type', 'dish_name', 'calories', 'proteins', 'carbs', 'fats', 'quantity_g'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'modify_meal',
      args,
      'ryze_confirm_replace_meal'.tr(_lang).replaceAll('{name}', '${args['dish_name']}'),
    ),
    execute: (args) => _run('modify_meal', args),
  );

  // ------------------------------------------------------------ retirer

  static final deleteMeal = RyzeTool(
    name: 'plan.delete_meal',
    surfaces: surfaces,
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
    surfaces: surfaces,
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

  static final deleteCardio = RyzeTool(
    name: 'plan.delete_cardio',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.delete_cardio',
      description:
          'Remove a planned cardio session. Use it only when the user wants it gone '
          'with nothing in its place; to change it use plan.modify_cardio.',
      properties: {
        'day': {'type': 'string', 'description': 'Day of the session.', 'enum': _days},
        'activity_name': {
          'type': 'string',
          'description': 'Which activity, when the day holds several.',
        },
      },
      required: ['day'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'delete_cardio',
      args,
      'ryze_confirm_delete_cardio'.tr(_lang).replaceAll('{day}', '${args['day']}'),
    ),
    execute: (args) => _run('delete_cardio', args),
  );

  /// La suppression en masse, en un seul outil plutôt que six.
  ///
  /// Le planificateur en a six — tout, les séances, le cardio, un jour, une
  /// sélection, les repas — parce que son prompt lui apprend lequel choisir.
  /// Un seul outil souple demande moins au modèle, et un modèle léger choisit
  /// d'autant mieux qu'on lui présente moins de portes voisines.
  static final deleteSessions = RyzeTool(
    name: 'plan.delete_sessions',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.delete_sessions',
      description:
          'Remove several planned training sessions at once. Use it when the request is '
          'broader than a single session: a whole day, every workout, all cardio, '
          'everything except one day. With no argument it clears the whole week. Only '
          'for training — for meals use plan.delete_all_meals.',
      properties: {
        'days': {
          'type': 'array',
          'items': {'type': 'string', 'enum': _days},
          'description': 'Days to clear. Empty means every day of the week.',
        },
        'exclude_days': {
          'type': 'array',
          'items': {'type': 'string', 'enum': _days},
          'description': 'Days to spare, for "everything except...".',
        },
        'session_types': {
          'type': 'array',
          'items': {'type': 'string', 'enum': ['workout', 'cardio']},
          'description': 'Which kinds to remove. Empty means both.',
        },
      },
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'delete_sessions',
      args,
      'ryze_confirm_delete_sessions'.tr(_lang),
    ),
    execute: (args) => _run('delete_sessions', args),
  );

  static final deleteAllMeals = RyzeTool(
    name: 'plan.delete_all_meals',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.delete_all_meals',
      description:
          'Remove every planned meal of the week. Use it only when the user clearly '
          'wants the whole meal plan cleared; for one meal use plan.delete_meal.',
    ),
    needsConfirmation: (_) => true,
    preview: (args) => _confirm(
      'delete_all_meals',
      args,
      'ryze_confirm_delete_all_meals'.tr(_lang),
    ),
    execute: (args) => _run('delete_all_meals', args),
  );

  /// Défaire la dernière suppression.
  ///
  /// Sans confirmation : c'est déjà le geste qui répare.
  static final undo = RyzeTool(
    name: 'plan.undo',
    surfaces: surfaces,
    declaration: toolSchema(
      name: 'plan.undo',
      description:
          'Undo the last removal from the plan. Use it when the user regrets what was '
          'just deleted and says so, only for the most recent one.',
    ),
    execute: (args) => _run('undo_last_action', args),
  );

  /// Les outils d'écriture du plan, pour les deux surfaces.
  static List<RyzeTool> get all => [
        createMeal,
        createWorkout,
        createCardio,
        createHiit,
        moveWorkout,
        moveCardio,
        modifyWorkout,
        modifyCardio,
        modifyMeal,
        deleteMeal,
        deleteWorkout,
        deleteCardio,
        deleteSessions,
        deleteAllMeals,
        undo,
      ];

  /// Les deux surfaces : la conversation et l'écran du planificateur.
  ///
  /// C'est ici que la frontière disparaît. Les deux parlent au même moteur,
  /// avec les mêmes outils ; ce qui les distingue est ce qu'elles montrent,
  /// pas ce qu'elles savent faire.
  static const Set<RyzeSurface> surfaces = {RyzeSurface.coach, RyzeSurface.planner};
}
