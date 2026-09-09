import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_tools/ryze_tool.dart';
import 'package:ryze_app/components/weekly_planner/proposal_group.dart';
import 'package:ryze_app/models/weekly_planner_models.dart';

/// Ce que la conversation fait d'un tour de propositions.
///
/// « Ajoute trois séances cette semaine » donnait trois cartes plates
/// empilées, chacune avec ses deux boutons, sans moyen de voir ce qu'il y
/// avait dedans. L'écran du planificateur, avec exactement les mêmes objets,
/// n'en faisait qu'une carte : les jours en pastilles, le détail au toucher.
///
/// Ce qui manquait n'était pas le composant — il existait — mais l'objet : la
/// carte du chat ne recevait qu'un titre et une ligne de texte.
void main() {
  RyzePending seance(String jour, DateTime date) => RyzePending(
        id: 'w-$jour',
        toolName: 'plan.create_workout',
        title: jour,
        payload: PendingSession.fromWorkout(
          PendingWorkout(
            plannedDate: date,
            workoutName: '$jour - 45min',
            workoutType: jour,
            durationMinutes: 45,
            workoutPrompt: 'seance',
            exercises: const [],
          ),
        ),
        commit: () async => const RyzeToolResult(ok: true, summary: 'ok', data: {}),
      );

  RyzePending repas(String plat) => RyzePending(
        id: 'm-$plat',
        toolName: 'plan.create_meal',
        title: plat,
        payload: PendingMeal(
          plannedDate: DateTime(2026, 9, 10),
          mealType: PlannedActivityType.lunch,
          dishName: plat,
          dishDescription: 'Un plat.---Ingrédients : riz',
          calories: 500,
          proteins: 30,
          carbs: 50,
          fats: 15,
          estimatedQuantityG: 350,
        ),
        commit: () async => const RyzeToolResult(ok: true, summary: 'ok', data: {}),
      );

  RyzePending suppression() => RyzePending(
        id: 'd-1',
        toolName: 'plan.delete_meal',
        title: 'Retirer le déjeuner de jeudi ?',
        commit: () async => const RyzeToolResult(ok: true, summary: 'ok', data: {}),
      );

  group('Ce que le groupe reconnaît', () {
    test('les séances d\'un tour se rassemblent', () {
      final out = SessionProposalGroup.sessionsOf([
        seance('Back', DateTime(2026, 9, 10)),
        seance('Legs', DateTime(2026, 9, 11)),
        seance('Chest', DateTime(2026, 9, 12)),
      ]);

      expect(out, hasLength(3));
      expect(out.map((s) => s.displayTitle), ['Back', 'Legs', 'Chest']);
    });

    test('les repas aussi, et séparément', () {
      final lot = [seance('Back', DateTime(2026, 9, 10)), repas('Saumon')];

      expect(SessionProposalGroup.sessionsOf(lot), hasLength(1));
      expect(MealProposalGroup.mealsOf(lot), hasLength(1));
      expect(MealProposalGroup.mealsOf(lot).single.dishName, 'Saumon');
    });

    test('ce qui ne porte pas d\'objet n\'entre dans aucun des deux', () {
      // Une suppression à confirmer n'a rien à montrer en détail : elle garde
      // la carte simple, qui lui suffit.
      final lot = [suppression()];

      expect(SessionProposalGroup.sessionsOf(lot), isEmpty);
      expect(MealProposalGroup.mealsOf(lot), isEmpty);
    });

    test('un lot vide ne rend rien', () {
      expect(SessionProposalGroup.sessionsOf(const []), isEmpty);
      expect(MealProposalGroup.mealsOf(const []), isEmpty);
    });
  });

  group('Ce que la proposition porte', () {
    test('l\'objet voyage jusqu\'à la surface', () {
      // Sans lui, la carte n'avait qu'un titre : c'est toute la raison pour
      // laquelle la conversation ne pouvait pas montrer les exercices.
      final p = seance('Back', DateTime(2026, 9, 10));
      expect(p.payload, isA<PendingSession>());
      expect((p.payload! as PendingSession).workout, isNotNull);
    });

    test('une proposition bloquée ne porte rien à valider', () {
      final p = RyzePending(
        id: 'x',
        toolName: 'plan.create_workout',
        title: 'Ce jour est déjà passé.',
        blocked: const RyzeToolResult(ok: false, summary: 'Ce jour est déjà passé.', data: {}),
        commit: () async => const RyzeToolResult(ok: false, summary: '', data: {}),
      );

      expect(p.blocked, isNotNull);
      expect(p.payload, isNull);
      expect(SessionProposalGroup.sessionsOf([p]), isEmpty);
    });
  });
}
