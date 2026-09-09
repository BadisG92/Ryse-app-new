import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/prompts/persona_de.dart';
import 'package:ryze_app/ai/prompts/persona_en.dart';
import 'package:ryze_app/ai/prompts/persona_fr.dart';
import 'package:ryze_app/ai/prompts/persona_strings.dart';
import 'package:ryze_app/ai/ryze_context.dart';

/// Le vocabulaire des mouvements, tel qu'il arrive dans le prompt.
///
/// Le générateur de séance a toujours eu le catalogue sous les yeux ; le chat
/// ne l'avait jamais vu. Il nommait donc les exercices de mémoire, et
/// « bent over row » ne rejoignait pas « Rowing barre » : un seul mouvement,
/// deux lignes dans la base, deux historiques de charge.
///
/// Ce que ces tests protègent, c'est l'équilibre : la liste doit orienter
/// l'orthographe **sans** fermer la porte. Le catalogue est incomplet, et
/// Ryze doit pouvoir proposer un mouvement qui n'y figure pas.
void main() {
  const fr = PersonaFr();

  Map<String, List<String>> catalogue() => {
        'Dos': ['Rowing barre', 'Tirage vertical'],
        'Pectoraux': ['Développé couché'],
      };

  group('Ce que la liste dit', () {
    test('les noms du catalogue y sont, groupés', () {
      final out = RyzeContext.renderExercises(fr, catalogue());

      expect(out, contains('Dos : Rowing barre, Tirage vertical'));
      expect(out, contains('Pectoraux : Développé couché'));
    });

    test('elle porte le titre de sa langue', () {
      expect(RyzeContext.renderExercises(fr, catalogue()),
          contains(fr.label('section_exercises')));
    });

    test('elle dit de reprendre le nom exact', () {
      final out = RyzeContext.renderExercises(fr, catalogue());
      expect(out, contains('exactement'));
    });

    test('elle dit aussi qu\'on peut en sortir', () {
      // La régression à craindre : quelqu\'un « resserre » la consigne un jour
      // et Ryze se retrouve enfermé dans trois cent soixante-cinq mouvements.
      for (final s in const <PersonaStrings>[PersonaFr(), PersonaEn(), PersonaDe()]) {
        final hint = s.label('exercises_hint').toLowerCase();
        expect(
          hint.contains('incomplète') || hint.contains('incomplete') || hint.contains('unvollständig'),
          isTrue,
          reason: '${s.lang} : la liste doit se présenter comme incomplète',
        );
        expect(
          hint.contains('librement') || hint.contains('freely') || hint.contains('frei'),
          isTrue,
          reason: '${s.lang} : nommer hors catalogue doit rester permis',
        );
      }
    });

    test('une ligne par groupe, pas une puce par exercice', () {
      // Trois cent soixante-cinq puces coûtent trois fois le prix des mêmes
      // noms mis bout à bout.
      final lignes = RyzeContext.renderExercises(fr, catalogue())
          .split('\n')
          .where((l) => l.startsWith('- '));
      expect(lignes, isEmpty);
    });
  });

  group('Quand il n\'y a rien à dire', () {
    test('un catalogue vide ne met pas de section vide dans le prompt', () {
      expect(RyzeContext.renderExercises(fr, {}), isEmpty);
    });

    test('des groupes sans aucun nom non plus', () {
      expect(RyzeContext.renderExercises(fr, {'Dos': [], 'Pectoraux': ['  ']}), isEmpty);
    });

    test('un groupe vide parmi d\'autres disparaît seul', () {
      final out = RyzeContext.renderExercises(fr, {'Dos': [], 'Pectoraux': ['Dips']});

      expect(out, contains('Pectoraux : Dips'));
      expect(out, isNot(contains('Dos')));
    });
  });

  group('Sa place dans le contexte', () {
    test('elle vient après ce qui concerne l\'utilisateur', () {
      // C\'est une référence, pas une donnée du compte : le modèle doit lire
      // la journée et le plan avant le dictionnaire.
      expect(RyzeBlock.values.last, RyzeBlock.exercises);

      final out = RyzeContext.assemble({
        RyzeBlock.today: '## AUJOURD\'HUI\n1800 kcal',
        RyzeBlock.exercises: RyzeContext.renderExercises(fr, catalogue()),
      });

      expect(out.indexOf('AUJOURD\'HUI'), lessThan(out.indexOf('Rowing barre')));
    });
  });
}
