import 'package:flutter/foundation.dart';

import '../../services/global_state_manager.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/water_service.dart';
import '../../services/weight_service.dart';
import 'ryze_tool.dart';

/// Ce que Ryze peut noter dans le journal.
///
/// Le coach n'avait aucun outil : son prompt lui apprenait à dire « prends-le
/// en photo avec le scanner » ou « va dans l'onglet Sport ». Il pouvait
/// constater, jamais agir.
class JournalTools {
  JournalTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  /// Noter de l'eau.
  ///
  /// Sans confirmation : un verre se retire d'un geste, et la barre
  /// d'annulation est plus rapide qu'une carte à valider.
  static final water = RyzeTool(
    name: 'journal.log_water',
    declaration: toolSchema(
      name: 'journal.log_water',
      description:
          'Log water the user says they drank. Use it when they mention drinking, even '
          'in passing, and only for water they already had, never for an intention. '
          'Convert glasses to millilitres: a glass is 250 ml, a large glass or a small '
          'bottle is 500 ml.',
      properties: {
        'amount_ml': {
          'type': 'integer',
          'description': 'Amount in millilitres, between 50 and 3000.',
        },
      },
      required: ['amount_ml'],
    ),
    execute: (args) async {
      final ml = (args['amount_ml'] as num?)?.round() ?? 0;
      if (ml < 50 || ml > 3000) {
        return RyzeToolResult.failed('ryze_water_amount_invalid'.tr(_lang));
      }

      final ok = await WaterService.addWaterEntry(amount: ml, sourceType: 'coach');
      if (!ok) return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));

      final litres = (ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1);
      return RyzeToolResult(
        ok: true,
        summary: 'ryze_logged_water'.tr(_lang).replaceAll('{n}', litres),
        data: {
          'logged_ml': ml,
          'total_today_l': GlobalStateManager.instance.currentWaterL,
          'goal_l': GlobalStateManager.instance.waterGoalL,
        },
      );
    },
  );

  /// Noter un poids.
  ///
  /// Avec confirmation : un poids entre dans une courbe, et un chiffre mal
  /// entendu la fausse durablement.
  static final weight = RyzeTool(
    name: 'journal.log_weight',
    declaration: toolSchema(
      name: 'journal.log_weight',
      description:
          'Record the weight the user just told you. Only when they state a weight for '
          'themselves today, never from an estimate or a goal.',
      properties: {
        'weight_kg': {
          'type': 'number',
          'description': 'Weight in kilograms, between 25 and 350.',
        },
      },
      required: ['weight_kg'],
    ),
    needsConfirmation: (_) => true,
    preview: (args) async {
      final kg = (args['weight_kg'] as num?)?.toDouble() ?? 0;
      return RyzePending(
        id: 'weight-${DateTime.now().microsecondsSinceEpoch}',
        toolName: 'journal.log_weight',
        title: 'ryze_confirm_weight'.tr(_lang).replaceAll('{n}', _kg(kg)),
        commit: () => _saveWeight(kg),
      );
    },
    execute: (args) => _saveWeight((args['weight_kg'] as num?)?.toDouble() ?? 0),
  );

  static String _kg(double kg) {
    final s = kg.toStringAsFixed(kg == kg.roundToDouble() ? 0 : 1);
    return _lang == 'en' ? s : s.replaceAll('.', ',');
  }

  static Future<RyzeToolResult> _saveWeight(double kg) async {
    if (kg < 25 || kg > 350) {
      return RyzeToolResult.failed('ryze_weight_invalid'.tr(_lang));
    }
    try {
      await WeightService.saveWeightEntry(kg);
      return RyzeToolResult(
        ok: true,
        summary: 'ryze_logged_weight'.tr(_lang).replaceAll('{n}', _kg(kg)),
        data: {'weight_kg': kg},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ journal.log_weight : $e');
      return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
    }
  }

  static List<RyzeTool> get all => [water, weight];
}
