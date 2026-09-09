import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/planner_ai_service.dart';

/// Comment le planificateur lit un jour.
///
/// Vu sur appareil : « tu l'as mis à jeudi mais c'est pour aujourd'hui ». Le
/// modèle a écrit `to_day: today`, la lecture n'a pas compris, et le chat a
/// affiché « Invalid days » en anglais brut. Deux fois de suite.
void main() {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  group('Les mots du quotidien désignent une date', () {
    tearDown(() => PlannerAIService.setPlanningWindow(null));

    test('aujourd\'hui, dans les trois langues', () {
      final today = day(DateTime.now());

      for (final mot in ['today', "aujourd'hui", 'heute', 'AUJOURD\'HUI']) {
        expect(PlannerAIService.parseDay(mot), today, reason: mot);
      }
    });

    test('demain, dans les trois langues', () {
      final tomorrow = day(DateTime.now()).add(const Duration(days: 1));

      for (final mot in ['tomorrow', 'demain', 'morgen']) {
        expect(PlannerAIService.parseDay(mot), tomorrow, reason: mot);
      }
    });

    test('ces mots l\'emportent sur la fenêtre affichée', () {
      // La fenêtre peut pointer une autre semaine ; « aujourd'hui » reste
      // aujourd'hui.
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6));
      expect(PlannerAIService.parseDay('today'), day(DateTime.now()));
    });
  });

  group('Les noms de jour continuent de marcher', () {
    tearDown(() => PlannerAIService.setPlanningWindow(null));

    test('en anglais, en français et en allemand', () {
      PlannerAIService.setPlanningWindow(DateTime(2025, 1, 6)); // un lundi

      expect(PlannerAIService.parseDay('monday'), DateTime(2025, 1, 6));
      expect(PlannerAIService.parseDay('mercredi'), DateTime(2025, 1, 8));
      expect(PlannerAIService.parseDay('donnerstag'), DateTime(2025, 1, 9));
    });
  });

  group('Ce qui reste incompréhensible', () {
    test('rend null, et non une date au hasard', () {
      expect(PlannerAIService.parseDay('funday'), isNull);
      expect(PlannerAIService.parseDay(''), isNull);
    });
  });
}
