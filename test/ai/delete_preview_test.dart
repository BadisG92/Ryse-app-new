import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_tools/delete_preview.dart';
import 'package:ryze_app/services/planner_ai_service.dart';

/// Quels jours une suppression en masse emporte vraiment.
///
/// La carte disait « Retirer ces séances ? » sans jamais regarder ses propres
/// arguments : ni les jours visés, ni ceux qu'on épargne, ni les types. On
/// confirmait à l'aveugle, et une demande de retirer « la séance de sport de
/// demain » a emporté un cardio sans que rien à l'écran ne le laisse voir.
void main() {
  // Une semaine du lundi 7 au dimanche 13 septembre 2026.
  final semaine = [for (var i = 0; i < 7; i++) DateTime(2026, 9, 7 + i)];

  List<int> joursDe(Map<String, dynamic> args) =>
      DeletePreview.daysOf(args, semaine).map((d) => d.day).toList();

  group('Ce que la suppression vise', () {
    test('sans argument, toute la semaine', () {
      expect(joursDe(const {}), [7, 8, 9, 10, 11, 12, 13]);
    });

    test('des jours nommés, ceux-là seulement', () {
      // `dateForDayName` résout dans la semaine courante ; on vérifie donc le
      // nombre de jours et non leur date, qui dépend d'aujourd'hui.
      expect(joursDe(const {'days': ['friday', 'sunday']}), hasLength(2));
    });

    test('« tout sauf mercredi » épargne bien mercredi', () {
      final mercredi = PlannerAIService.dateForDayName('wednesday');
      final out = DeletePreview.daysOf(const {'exclude_days': ['wednesday']}, semaine);

      expect(out, hasLength(6));
      if (mercredi != null) {
        expect(
          out.any((d) => d.year == mercredi.year && d.month == mercredi.month && d.day == mercredi.day),
          isFalse,
        );
      }
    });

    test('un jour à la fois visé et épargné n\'est pas emporté', () {
      expect(
        joursDe(const {'days': ['friday'], 'exclude_days': ['friday']}),
        isEmpty,
      );
    });

    test('un jour incompréhensible est ignoré, pas deviné', () {
      expect(joursDe(const {'days': ['blursday']}), isEmpty);
    });
  });

  group('La borne de la carte', () {
    test('elle ne déroule pas une semaine entière de repas', () {
      // Vingt-huit lignes dans une bulle de chat, personne ne les lit.
      expect(DeletePreview.maxLines, lessThanOrEqualTo(8));
      expect(DeletePreview.maxLines, greaterThanOrEqualTo(3));
    });
  });
}
