import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/planner_ai_service.dart';

/// Ce que le service du planificateur garantit encore.
///
/// Il portait deux listes de schémas d'outils, une par mode, que le modèle
/// lisait et que ce fichier vérifiait. Elles ont disparu : les déclarations
/// vivent maintenant en un seul endroit, `lib/ai/ryze_tools/plan_tools.dart`,
/// et c'est `test/ai/tools_test.dart` qui les tient. Ce qui reste ici est ce
/// que le service décide encore lui-même : la répartition des calories sur la
/// journée, et le jour que le modèle a désigné.
void main() {
  group('La répartition des calories sur la journée', () {
    test('les quatre repas couvrent exactement la journée', () {
      final total = PlannerAIService.mealSplit.values.reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 0.0001));
    });

    test('chaque moment de la journée a une part', () {
      for (final meal in ['breakfast', 'lunch', 'dinner', 'snack']) {
        expect(PlannerAIService.mealSplit.containsKey(meal), isTrue);
        expect(PlannerAIService.mealSplit[meal]! > 0, isTrue);
      }
    });
  });

  group('Le jour que le modèle a désigné', () {
    tearDown(() => PlannerAIService.setPlanningWindow(null));

    test('tombe dans la fenêtre affichée à l\'écran', () {
      // Une semaine qui commence le lundi 6 janvier 2025.
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6));

      expect(PlannerAIService.dateForDayName('monday'), DateTime(2025, 1, 6));
      expect(PlannerAIService.dateForDayName('wednesday'), DateTime(2025, 1, 8));
      expect(PlannerAIService.dateForDayName('sunday'), DateTime(2025, 1, 12));
    });

    test('suit la fenêtre même quand elle ne commence pas un lundi', () {
      // La démo de l'onboarding plante sa fenêtre ailleurs qu'un lundi.
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 9)); // un jeudi

      expect(PlannerAIService.dateForDayName('thursday'), DateTime(2025, 1, 9));
      expect(PlannerAIService.dateForDayName('saturday'), DateTime(2025, 1, 11));
      // Le lundi de cette fenêtre est celui d'après, pas celui d'avant.
      expect(PlannerAIService.dateForDayName('monday'), DateTime(2025, 1, 13));
    });

    test('rend null sur un nom de jour inconnu', () {
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6));
      expect(PlannerAIService.dateForDayName('funday'), isNull);
      expect(PlannerAIService.dateForDayName(''), isNull);
    });
  });
}
