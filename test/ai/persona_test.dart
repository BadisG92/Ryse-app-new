import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/prompts/persona_de.dart';
import 'package:ryze_app/ai/prompts/persona_en.dart';
import 'package:ryze_app/ai/prompts/persona_fr.dart';
import 'package:ryze_app/ai/prompts/persona_strings.dart';
import 'package:ryze_app/ai/ryze_persona.dart';

/// Ce que Ryze dit de lui-même, dans les trois langues.
///
/// Le prompt du coach était un squelette français quelle que soit la langue :
/// un utilisateur allemand recevait un texte français lui demandant de
/// répondre en allemand. Ces tests interdisent le retour de cette situation.
void main() {
  const personas = <PersonaStrings>[PersonaFr(), PersonaEn(), PersonaDe()];

  group('Chaque langue est complète', () {
    for (final p in personas) {
      test('${p.lang} : toutes les sections sont écrites', () {
        expect(p.languageName.isNotEmpty, isTrue);
        expect(p.identity('Badis').trim().isNotEmpty, isTrue,
            reason: '${p.lang} sans identité');
        expect(p.nonNegotiables.trim().isNotEmpty, isTrue,
            reason: '${p.lang} sans règles non négociables');
        expect(p.styleFrame.trim().isNotEmpty, isTrue, reason: '${p.lang} sans cadre de ton');
        expect(p.toolGuidance.trim().isNotEmpty, isTrue, reason: '${p.lang} sans guide des outils');
        expect(p.lengthRule.trim().isNotEmpty, isTrue, reason: '${p.lang} sans règle de longueur');
        expect(p.languageRule.trim().isNotEmpty, isTrue, reason: '${p.lang} sans consigne de langue');
      });

      test('${p.lang} : chaque intitulé a une valeur propre', () {
        // Un intitulé manquant retombe sur sa clé. C'est un repli acceptable
        // en production, mais ici c'est le signal d'un trou — sauf pour les
        // quelques mots anglais qui sont leur propre traduction.
        const coincidences = {
          'en': {'done', 'missed', 'planned', 'eaten', 'today', 'past'},
          'fr': <String>{},
          'de': <String>{},
        };
        final attendues = coincidences[p.lang] ?? const <String>{};

        for (final key in personaLabelKeys) {
          final value = p.label(key);
          expect(value.trim().isNotEmpty, isTrue, reason: '« $key » vide en ${p.lang}');
          if (!attendues.contains(key)) {
            expect(value, isNot(key),
                reason: 'intitulé « $key » manquant en ${p.lang}, la clé ressort telle quelle');
          }
        }
      });

      test('${p.lang} : une clé inconnue retombe sur elle-même', () {
        expect(p.label('cle_qui_nexiste_pas'), 'cle_qui_nexiste_pas');
      });

      test('${p.lang} : les trois genres et les trois âges sont couverts', () {
        for (final gender in ['female', 'male', null]) {
          expect(p.genderRule(gender).trim().isNotEmpty, isTrue,
              reason: 'genre $gender non couvert en ${p.lang}');
        }
        for (final age in [18, 30, 60]) {
          expect(p.ageRule(age).trim().isNotEmpty, isTrue,
              reason: 'âge $age non couvert en ${p.lang}');
        }
        // Un âge inconnu ne dit rien plutôt que d'inventer un registre.
        expect(p.ageRule(null), isEmpty);
      });
    }
  });

  group('Aucun français ne fuit', () {
    // Des mots que le français est seul à porter dans ces textes. S'ils
    // apparaissent dans la version anglaise ou allemande, c'est qu'une section
    // a été recopiée au lieu d'être écrite.
    const marqueursFr = [
      'Tu es Ryze',
      'jamais',
      'utilisateur',
      'séance',
      'aujourd\'hui',
      'Réponds en français',
    ];

    for (final p in personas.where((p) => p.lang != 'fr')) {
      test('${p.lang} : le texte ne contient pas de français', () {
        final assemble = [
          p.identity('Badis'),
          p.nonNegotiables,
          p.styleFrame,
          p.toolGuidance,
          p.lengthRule,
          p.languageRule,
          p.genderRule('female'),
          p.ageRule(30),
          for (final k in personaLabelKeys) p.label(k),
        ].join('\n');

        for (final mot in marqueursFr) {
          expect(assemble.toLowerCase(), isNot(contains(mot.toLowerCase())),
              reason: '« $mot » trouvé dans la version ${p.lang}');
        }
      });
    }

    test('chaque langue annonce la bonne langue de réponse', () {
      expect(const PersonaFr().languageRule.toLowerCase(), contains('français'));
      expect(const PersonaEn().languageRule.toLowerCase(), contains('english'));
      expect(const PersonaDe().languageRule.toLowerCase(), contains('deutsch'));
    });
  });

  group('La carte pose la question, pas Ryze', () {
    // Vu sur appareil : Ryze demande « veux-tu que je l'ajoute ? », la carte
    // s'affiche et l'utilisateur valide, puis Ryze redemande « est-ce que je
    // valide définitivement ? ». Trois oui pour une seule séance.
    for (final persona in personas) {
      test('la règle tient en ${persona.lang}', () {
        final guide = persona.toolGuidance.toLowerCase();

        // Ne pas demander la permission d'appeler l'outil.
        expect(
          guide.contains('permission') || guide.contains('erlaubnis'),
          isTrue,
          reason: '${persona.lang} : rien n\'interdit de demander avant d\'agir',
        );

        // La carte et ses deux boutons sont nommés, donc connus du modèle.
        expect(
          guide.contains('carte') || guide.contains('card') || guide.contains('karte'),
          isTrue,
          reason: '${persona.lang} : le modèle ignore que l\'application demande',
        );
      });
    }
  });


  group('Ce que Ryze ne doit jamais prétendre', () {
    // Vu sur appareil : l'utilisateur dit « je ne le vois pas dans la
    // planification », Ryze s'excuse et répond « c'est maintenant chose
    // faite » sans avoir appelé le moindre outil. Rien n'avait eu lieu.
    for (final persona in personas) {
      test('la règle tient en ${persona.lang}', () {
        final regles = persona.nonNegotiables.toLowerCase();

        // Une action ne se refait pas en paroles.
        expect(
          regles.contains('paroles') || regles.contains('in words') || regles.contains('mit worten'),
          isTrue,
          reason: '${persona.lang} : rien n\'interdit de prétendre avoir recommencé',
        );

        // Ce qui attend une validation n'est pas fait.
        expect(
          regles.contains('validation') || regles.contains('confirmed') || regles.contains('bestätigt'),
          isTrue,
          reason: '${persona.lang} : rien ne distingue proposé de fait',
        );
      });
    }
  });


  group('L\'ordre des sections', () {
    test('les règles passent avant le ton, pas après', () {
      // C'est la correction de fond : le ton venait en premier sous
      // « PRIORITÉ ABSOLUE », si bien que deux cents caractères écrits par
      // l'utilisateur pouvaient primer sur la règle médicale.
      for (final p in personas) {
        final assemble = '${p.identity('Badis')}\n${p.nonNegotiables}\n${p.styleFrame}';
        final posRegles = assemble.indexOf(p.nonNegotiables);
        final posTon = assemble.indexOf(p.styleFrame);
        expect(posRegles, greaterThan(-1));
        expect(posTon, greaterThan(posRegles),
            reason: 'en ${p.lang}, le ton doit venir après les règles');
      }
    });

    test('le cadre du ton dit qu\'il ne change pas les règles', () {
      // Sans cette phrase, un ton libre peut se croire au-dessus de tout.
      expect(const PersonaFr().styleFrame.toLowerCase(), contains('jamais les règles'));
      expect(const PersonaEn().styleFrame.toLowerCase(), contains('never the rules'));
      expect(const PersonaDe().styleFrame.toLowerCase(), contains('nie die regeln'));
    });

    test('les non-négociables couvrent le médical et l\'action non confirmée', () {
      expect(const PersonaFr().nonNegotiables.toLowerCase(), contains('médical'));
      expect(const PersonaEn().nonNegotiables.toLowerCase(), contains('medical'));
      expect(const PersonaDe().nonNegotiables.toLowerCase(), contains('medizinisch'));

      // « ne dis jamais qu'une chose est faite tant qu'un outil ne l'a pas
      // confirmée » : la règle qui empêche Ryze d'annoncer une action qu'il
      // n'a pas faite, maintenant qu'il en aura les moyens.
      expect(const PersonaFr().nonNegotiables.toLowerCase(), contains('outil'));
      expect(const PersonaEn().nonNegotiables.toLowerCase(), contains('tool'));
      expect(const PersonaDe().nonNegotiables.toLowerCase(), contains('werkzeug'));
    });
  });

  group('La sélection de la langue', () {
    test('rend le texte demandé', () {
      expect(RyzePersona.of('fr').lang, 'fr');
      expect(RyzePersona.of('en').lang, 'en');
      expect(RyzePersona.of('de').lang, 'de');
    });

    test('retombe sur l\'anglais pour une langue inconnue', () {
      expect(RyzePersona.of('es').lang, 'en');
      expect(RyzePersona.of('').lang, 'en');
    });

    test('les trois langues de l\'application sont couvertes', () {
      expect(RyzePersona.languages, containsAll(['fr', 'en', 'de']));
    });
  });
}
