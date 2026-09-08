import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../ryze_memory.dart';
import 'ryze_tool.dart';

/// Ce que Ryze retient quand on le lui dit.
///
/// Jusqu'ici la mémoire ne se remplissait qu'en arrière-plan, en relisant la
/// conversation après coup. Ryze pouvait entendre « je suis allergique aux
/// noix » sans rien en faire sur le moment.
class MemoryTools {
  MemoryTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  static final remember = RyzeTool(
    name: 'memory.remember',
    declaration: toolSchema(
      name: 'memory.remember',
      description:
          'Remember something lasting about the user: an allergy, an injury or physical '
          'limitation, a diet, a food they love or hate, when they prefer to train. '
          'Only for what stays true beyond today. Never for a passing mood, a one-off '
          'meal, or something you inferred rather than heard.',
      properties: {
        'category': {
          'type': 'string',
          'description': 'Which kind of fact this is.',
          'enum': [
            'allergy',
            'dietary_restriction',
            'food_preference',
            'fitness_constraint',
            'workout_time',
            'note',
          ],
        },
        'fact': {
          'type': 'string',
          'description':
              'The fact itself, short and in the user\'s language. Two to five words: '
              '"allergic to nuts", "bad right knee", "trains in the morning".',
        },
      },
      required: ['category', 'fact'],
    ),
    execute: (args) async {
      final category = MemoryCategory.fromKey('${args['category']}');
      final fact = '${args['fact'] ?? ''}'.trim();

      if (category == null || fact.isEmpty) {
        return RyzeToolResult.failed('ryze_action_failed'.tr(_lang));
      }
      if (fact.length > 120) {
        return RyzeToolResult.failed('ryze_memory_too_long'.tr(_lang));
      }

      final changed = await RyzeMemory.instance.remember(category, fact);

      // Rien de changé n'est pas un échec : Ryze le savait déjà, et il vaut
      // mieux qu'il le sache que d'insister.
      return RyzeToolResult(
        ok: true,
        summary: changed
            ? 'ryze_remembered'.tr(_lang).replaceAll('{fact}', fact)
            : 'ryze_already_known'.tr(_lang),
        data: {'stored': changed, 'fact': fact, 'category': category.jsonKey},
      );
    },
  );

  static List<RyzeTool> get all => [remember];
}
