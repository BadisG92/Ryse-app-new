import 'package:flutter/material.dart';

import '../../models/weekly_planner_models.dart';
import '../../screens/ai_scanner_screen.dart';
import '../../screens/planner_chat_screen.dart';
import '../../services/app_navigator.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/weekly_planner_service.dart';
import 'ryze_tool.dart';

/// Ce que Ryze peut ouvrir.
///
/// Ces outils remplacent les phrases que son prompt lui apprenait à dire :
/// « prends-le en photo avec le scanner », « va dans l'onglet Sport ». Il
/// ouvre l'écran lui-même, et l'utilisateur arrive au bon endroit.
class NavTools {
  NavTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static Future<bool> _push(Widget screen) async {
    final navigator = AppNavigator().navigatorState;
    if (navigator == null) return false;
    await navigator.push(MaterialPageRoute(builder: (_) => screen));
    return true;
  }

  /// Ouvrir le scanner.
  static final openScanner = RyzeTool(
    name: 'nav.open_scanner',
    declaration: toolSchema(
      name: 'nav.open_scanner',
      description:
          'Open the camera scanner so the user can photograph a dish and have its '
          'calories read. Use it when they want to log something they can show rather '
          'than describe.',
    ),
    execute: (_) async {
      final ok = await _push(const AIScannerScreen(isFromDashboard: true));
      return ok
          ? RyzeToolResult(
              ok: true,
              summary: 'ryze_opened_scanner'.tr(_lang),
              data: {'opened': 'scanner'},
            )
          : RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    },
  );

  /// Ouvrir le planificateur, éventuellement avec une demande déjà écrite.
  ///
  /// Le relais vers le planificateur, tant que les deux moteurs sont séparés.
  /// Au lot suivant, Ryze planifiera sans changer d'écran.
  static final openPlanner = RyzeTool(
    name: 'nav.open_planner',
    declaration: toolSchema(
      name: 'nav.open_planner',
      description:
          'Open the weekly planner, where meals and training sessions are planned. Use '
          'it when the user wants to plan ahead rather than log what already happened. '
          'Pass their request in "prefill" so the planner starts on it.',
      properties: {
        'mode': {
          'type': 'string',
          'description': 'Which side of the planner to open.',
          'enum': ['meals', 'workouts'],
        },
        'prefill': {
          'type': 'string',
          'description':
              'The request to hand over, in the user\'s own words and language.',
        },
      },
      required: ['mode'],
    ),
    execute: (args) async {
      final mode = '${args['mode']}' == 'workouts' ? 'workouts' : 'meals';
      final prefill = '${args['prefill'] ?? ''}'.trim();

      WeeklyPlannerData week;
      try {
        week = await WeeklyPlannerService.getWeekData();
      } catch (_) {
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }

      final ok = await _push(PlannerChatScreen(
        initialMode: mode,
        weekData: week,
        initialMessage: prefill.isEmpty ? null : prefill,
      ));

      return ok
          ? RyzeToolResult(
              ok: true,
              summary: 'ryze_opened_planner'.tr(_lang),
              data: {'opened': 'planner', 'mode': mode},
            )
          : RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    },
  );

  static List<RyzeTool> get all => [openScanner, openPlanner];
}
