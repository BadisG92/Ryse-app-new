import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/ai/prompts/persona_de.dart';
import 'package:ryze_app/ai/prompts/persona_en.dart';
import 'package:ryze_app/ai/prompts/persona_fr.dart';
import 'package:ryze_app/ai/ryze_context.dart';
import 'package:ryze_app/models/weekly_planner_models.dart';

/// Ce qui reste de la semaine, et dans quelle langue on l'écrit.
///
/// Un mercredi soir, « ajoute trois séances cette semaine » a donné lundi,
/// mardi et jeudi dans la conversation, et jeudi, vendredi, samedi dans le
/// planificateur. Même modèle, mêmes outils : le planificateur recevait la
/// liste des jours disponibles, la conversation ne la recevait pas. Elle
/// connaissait la date sans jamais faire la soustraction.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
    await initializeDateFormatting('de');
  });

  group('Les jours qui restent', () {
    test('un mercredi, il reste de mercredi à dimanche', () {
      // Le 9 septembre 2026 est un mercredi : celui de la capture.
      final out = RyzeContext.renderNow(const PersonaFr(), at: DateTime(2026, 9, 9, 23, 2));

      expect(out, contains('mercredi'));
      expect(out, contains('dimanche'));
      expect(out, isNot(contains('lundi')));
      expect(out, isNot(contains('mardi')));
    });

    test('et il est dit que les autres sont passés', () {
      final out = RyzeContext.renderNow(const PersonaFr(), at: DateTime(2026, 9, 9));
      expect(out, contains('passés'));
    });

    test('un lundi, la semaine entière est devant', () {
      final out = RyzeContext.renderNow(const PersonaFr(), at: DateTime(2026, 9, 7));

      for (final jour in ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche']) {
        expect(out, contains(jour), reason: '$jour manque');
      }
    });

    test('un dimanche, il ne reste que le jour même', () {
      final out = RyzeContext.renderNow(const PersonaFr(), at: DateTime(2026, 9, 13));

      expect(out, contains('ne reste qu\'aujourd\'hui'));
      expect(out, isNot(contains('samedi')));
    });

    test('chaque langue le dit dans ses mots', () {
      final en = RyzeContext.renderNow(const PersonaEn(), at: DateTime(2026, 9, 9));
      expect(en, contains('Thursday'));
      expect(en, contains('behind us'));
      expect(en, isNot(contains('jeudi')));

      final de = RyzeContext.renderNow(const PersonaDe(), at: DateTime(2026, 9, 9));
      expect(de, contains('Donnerstag'));
      expect(de, isNot(contains('Thursday')));
    });
  });

  group('La date sur la carte de séance', () {
    PendingSession seance() => PendingSession.fromWorkout(
          PendingWorkout(
            plannedDate: DateTime(2026, 9, 10),
            workoutName: 'Back and Shoulders - 45min',
            workoutType: 'Back and Shoulders',
            durationMinutes: 45,
            workoutPrompt: 'dos et epaules',
            exercises: const [],
          ),
        );

    test('elle suit la langue du compte, pas celle du code', () {
      // « Jeudi 10 septembre » s'affichait sous une pastille « Thu » pour un
      // compte anglais : deux tableaux français étaient écrits en dur.
      expect(seance().dateLabel('en'), 'Thursday 10 September');
      expect(seance().dateLabel('fr'), 'jeudi 10 septembre');
      expect(seance().dateLabel('de'), 'Donnerstag 10 September');
    });

    test('une langue inconnue retombe sur l\'anglais', () {
      expect(seance().dateLabel('es'), contains('September'));
    });
  });
}
