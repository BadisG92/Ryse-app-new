import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/ai_analysis_models.dart';
import '../../screens/ai_analysis_screen.dart';
import '../../services/app_navigator.dart';
import '../../services/gemini_analysis_service_v2.dart';
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
        // Le verre se retire : c'est ce qui remplace la carte à valider. La
        // ligne est retrouvée par sa quantité et sa provenance, parce que
        // l'écriture est volontairement non bloquante et ne rend pas d'identifiant.
        undo: () async {
          final entries = await WaterService.getTodayWaterEntries();
          for (final e in entries) {
            if (e.sourceType == 'coach' && e.amount == ml) {
              await WaterService.deleteWaterEntry(e.id, amountToRemove: e.amount);
              return;
            }
          }
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

  /// Noter un repas décrit à voix haute.
  ///
  /// C'était le trou le plus gênant pour un coach nutrition : « j'ai mangé une
  /// omelette » ne se notait pas. Le prompt lui apprenait à répondre « prends
  /// ton plat en photo avec le scanner » — c'est-à-dire à demander à
  /// l'utilisateur de refaire lui-même ce qu'il venait de dire.
  ///
  /// L'analyse rend des aliments et des macros, que l'écran de revue affiche
  /// pour correction avant d'écrire. Cet écran **est** la validation : une
  /// carte de plus demanderait deux fois la même chose.
  static final food = RyzeTool(
    name: 'journal.log_food_text',
    declaration: toolSchema(
      name: 'journal.log_food_text',
      description:
          'Log a meal the user describes in words, by reading its foods and macros from '
          'their description. Use it when they say what they ate, only for food already '
          'eaten. Pass their words as they said them, in their language. For a meal '
          'that was planned and eaten as planned, use plan.mark_meal_eaten instead.',
      properties: {
        'description': {
          'type': 'string',
          'description':
              'What they ate, in their own words and language, with quantities when '
              'they gave any: "two eggs, a banana and a black coffee".',
        },
        'meal_type': {
          'type': 'string',
          'description': 'Which meal it was, when they said or it is obvious.',
          'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
        },
      },
      required: ['description'],
    ),
    execute: (args) async {
      final description = '${args['description'] ?? ''}'.trim();
      if (description.isEmpty) {
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }

      final AIAnalysisResult result;
      try {
        result = await GeminiAnalysisServiceV2.analyzeTextDescription(description);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ journal.log_food_text : $e');
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }

      if (!result.success || result.detectedFoods.isEmpty) {
        // Ne rien reconnaître n'est pas une panne : Ryze doit pouvoir le dire
        // et demander une description plus précise.
        return RyzeToolResult(
          ok: false,
          summary: 'ryze_food_not_recognised'.tr(_lang),
          data: {'recognised': false},
        );
      }

      final navigator = AppNavigator().navigatorState;
      if (navigator == null) return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));

      await navigator.push(MaterialPageRoute(
        builder: (_) => AIAnalysisScreen(
          note: description,
          isFromTextInput: true,
          isFromDashboard: true,
          analysisResult: result,
          mealName: args['meal_type'] as String?,
        ),
      ));

      final noms = result.detectedFoods.map((f) => f.name).take(3).join(', ');
      return RyzeToolResult(
        ok: true,
        summary: 'ryze_food_to_review'.tr(_lang).replaceAll('{foods}', noms),
        data: {'recognised': true, 'foods': result.detectedFoods.length, 'awaiting_review': true},
      );
    },
  );

  static List<RyzeTool> get all => [water, weight, food];
}
