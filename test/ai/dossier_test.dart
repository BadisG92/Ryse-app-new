import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/dossier.dart';
import 'package:ryze_app/ai/ryze_memory.dart';
import 'package:ryze_app/ai/ryze_persona.dart';
import 'package:ryze_app/ai/ryze_tools/ryze_tools.dart';
import 'package:ryze_app/design/stamp.dart';
import 'package:ryze_app/models/coach_chat_models.dart';
import 'package:ryze_app/services/coach_personality_service.dart';

/// Le dossier : ce que le tampon a le droit de dire, ce que la carte garde,
/// et ce que l'outil laisse passer.
///
/// Le tampon est un vocabulaire fermé : s'il grandit ou se traduit mal, c'est
/// ici que ça casse, pas sur une story déjà partagée.
void main() {
  group('Le vocabulaire des tampons', () {
    const personas = [
      CoachPersonalityType.strict,
      CoachPersonalityType.sassy,
      CoachPersonalityType.friendly,
      CoachPersonalityType.supportive,
      CoachPersonalityType.direct,
    ];

    test('chaque ton a ses deux mots, à corriger puis validé', () {
      for (final p in personas) {
        final mots = DossierStamps.forPersona(p);
        expect(mots.length, 2, reason: p.name);
        expect(mots.first.mood, DossierMood.toFix, reason: p.name);
        expect(mots.last.mood, DossierMood.good, reason: p.name);
      }
    });

    test('un mot tient dans le cadre, en capitales, dans les trois langues', () {
      for (final s in DossierStamps.all) {
        for (final w in s.words) {
          expect(w.length, lessThanOrEqualTo(DossierStamps.maxLength), reason: '${s.id} : $w');
          expect(w, w.toUpperCase(), reason: '${s.id} : $w');
          expect(w.trim(), isNotEmpty);
        }
      }
    });

    test('les identités sont uniques', () {
      final ids = DossierStamps.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('un mot se retrouve quelle que soit la langue, la casse ou le point', () {
      expect(DossierStamps.byWord('peut mieux faire')?.id, 'could_do_better');
      expect(DossierStamps.byWord('COULD DO BETTER')?.id, 'could_do_better');
      expect(DossierStamps.byWord('Geht besser')?.id, 'could_do_better');
      expect(DossierStamps.byWord('vu')?.id, 'seen');
      expect(DossierStamps.byWord('Seen.')?.id, 'seen');
      expect(DossierStamps.byWord('  locked in ')?.id, 'locked_in');
      expect(DossierStamps.byWord('n\'importe quoi'), isNull);
      expect(DossierStamps.byWord(''), isNull);
    });

    test('la liste donnée au modèle couvre tout, sans doublon', () {
      final words = DossierStamps.enumWords();
      expect(words.toSet().length, words.length);
      for (final s in DossierStamps.all) {
        expect(words, contains(s.fr));
        expect(words, contains(s.en));
        expect(words, contains(s.de));
      }
    });

    test('le repli est neutre', () {
      expect(DossierStamps.fallback.id, 'seen');
      expect(DossierTools.pickStamp('tampon inventé').id, 'seen');
      expect(DossierTools.pickStamp('INSUFFISANT').id, 'insufficient');
    });

    test('un mot long se coupe en deux lignes à l\'espace du milieu', () {
      expect(RyzeStamp.linesOf('PEUT MIEUX FAIRE'), ['PEUT MIEUX', 'FAIRE']);
      expect(RyzeStamp.linesOf('COULD DO BETTER'), ['COULD DO', 'BETTER']);
      expect(RyzeStamp.linesOf('INSUFFISANT'), ['INSUFFISANT']);
      expect(RyzeStamp.linesOf('vu.'), ['VU.']);
      expect(RyzeStamp.linesOf('NICHT SCHLECHT'), ['NICHT', 'SCHLECHT']);
    });
  });

  group('Ce que l\'outil laisse passer', () {
    test('les lignes sont nettoyées, dédoublonnées et bornées à huit', () {
      final lines = DossierTools.sanitize([
        '  - A promis : plus de tacos après minuit  ',
        'A promis : plus de tacos après minuit',
        '',
        'x',
        '• S\'entraîne dans un garage, deux haltères',
        'Objectif : 78 kg avant mars',
        'Quatrième ligne',
        'Cinquième ligne',
        'Sixième ligne',
        'Septième ligne',
        'Huitième ligne',
        'Neuvième ligne',
        'Dixième ligne',
      ]);
      expect(lines.length, DossierTools.maxLines);
      expect(lines.first, 'A promis : plus de tacos après minuit');
      expect(lines[1], 'S\'entraîne dans un garage, deux haltères');
      expect(lines, isNot(contains('x')));
      expect(lines, isNot(contains('Neuvième ligne')));
      expect(lines, isNot(contains('Dixième ligne')));
    });

    test('rien de médical ne sort, même reformulé', () {
      final lines = DossierTools.sanitize(
        [
          'Allergie : noix',
          'Est allergique aux noix depuis l\'enfance',
          'Genou droit fragile, pas de squat profond',
          'Déteste le brocoli, le mange quand même le lundi',
          'A promis : plus de tacos après minuit',
        ],
        exclude: ['allergique aux noix', 'genou droit fragile'],
      );
      expect(lines, ['Déteste le brocoli, le mange quand même le lundi', 'A promis : plus de tacos après minuit']);
    });

    test('un mot médical suffit, même sans fait exclu', () {
      final lines = DossierTools.sanitize([
        'Prend un médicament le soir',
        'Blessure à l\'épaule en août',
        'Sans gluten depuis deux ans',
        'Objectif : 78 kg avant mars',
      ]);
      expect(lines, ['Objectif : 78 kg avant mars']);
    });

    test('un mot vide d\'un fait exclu ne bannit rien', () {
      // « plus de tacos après minuit » n'est pas de la santé, et « apres »,
      // « minuit », « plus » ne doivent pas faire tomber une vraie ligne.
      final lines = DossierTools.sanitize(
        ['A promis : plus de tacos après minuit', 'Dîne souvent après 22 h'],
        exclude: ['sans lactose après minuit'],
      );
      expect(lines, ['A promis : plus de tacos après minuit', 'Dîne souvent après 22 h']);
    });

    test('une ligne trop longue est coupée à un mot, avec des points de suspension', () {
      final long = List.filled(30, 'mot').join(' ');
      final out = DossierTools.sanitize([long]).single;
      expect(out.length, lessThanOrEqualTo(DossierTools.maxLineLength));
      expect(out, endsWith('…'));
      expect(out, isNot(contains('mo…')));
    });

    test('le prénom est le premier mot, jamais le défaut du profil', () {
      expect(DossierTools.firstName('Badis Gaaloul'), 'Badis');
      expect(DossierTools.firstName('  Léa '), 'Léa');
      expect(DossierTools.firstName('User'), '');
      expect(DossierTools.firstName(''), '');
    });

    test('le compte dit ce qui est retenu, onboarding compris, et rien d\'autre', () {
      final prefs = UserCoachPreferences(
        id: 'p',
        userId: 'u',
        allergies: const ['noix'],
        promises: const ['plus de tacos après minuit', '3 séances par semaine'],
        customNotes: const ['garage, deux haltères'],
        onboardingInsights: '- **Objectif**: perdre du gras\n- **Motivation**: tenir plus de 6 jours\n',
        createdAt: DateTime(2026, 10, 1),
      );
      expect(DossierTools.countFacts(prefs), 4 + 2);
      expect(DossierTools.countFacts(null), 0);
    });
  });

  group('La carte se garde et se relit', () {
    test('un dossier fait l\'aller-retour par la métadonnée', () {
      final d = RyzeDossier(
        name: 'Badis',
        lines: const ['A promis : plus de tacos après minuit', 'Objectif : 78 kg avant mars', 'Record : développé 80 kg'],
        stampId: 'insufficient',
        stampWord: 'INSUFFISANT',
        verdict: 'Tu te mens mieux que tu ne t\'entraînes.',
        count: 23,
        personaLabel: 'Coach strict',
        lang: 'fr',
        at: DateTime(2026, 10, 3, 21, 12),
      );
      final back = RyzeDossier.fromMetadata(d.toMetadata())!;
      expect(back.name, d.name);
      expect(back.lines, d.lines);
      expect(back.stampId, d.stampId);
      expect(back.stampWord, d.stampWord);
      expect(back.verdict, d.verdict);
      expect(back.count, 23);
      expect(back.personaLabel, d.personaLabel);
      expect(back.lang, 'fr');
      expect(back.at, d.at);
    });

    test('une métadonnée d\'un autre genre, ou sans lignes, ne fait pas de carte', () {
      expect(RyzeDossier.fromMetadata({'kind': 'tool', 'name': 'journal.log_water'}), isNull);
      expect(RyzeDossier.fromMetadata({'kind': 'dossier', 'lines': <String>[]}), isNull);
    });

    test('la ligne de message se reconnaît', () {
      final m = CoachMessage(
        id: '1',
        conversationId: 'c',
        userId: 'u',
        role: MessageRole.assistant,
        content: 'Dossier compilé',
        createdAt: DateTime(2026, 10, 3),
        metadata: const {'kind': 'dossier', 'lines': ['a', 'b', 'c']},
      );
      expect(m.isDossier, isTrue);
      expect(m.isAction, isFalse);
    });
  });

  group('Le registre et la mémoire', () {
    final registry = buildRyzeToolRegistry();

    test('le coach a le dossier, et le registre tient toujours debout', () {
      final noms = registry.declarationsFor(RyzeSurface.coach).map((d) => d['name']).toList();
      expect(noms, contains('memory.dossier'));
      expect(registry.validate(), isEmpty);
    });

    test('un nom approximatif retrouve son outil', () {
      // Le premier dossier sur appareil : « j'ai fait une erreur avec
      // l'outil », pour un nom qui ne collait pas au caractère près.
      expect(registry.resolve('memory.dossier')?.name, 'memory.dossier');
      expect(registry.resolve('memory_dossier')?.name, 'memory.dossier');
      expect(registry.resolve('default_api.memory.dossier')?.name, 'memory.dossier');
      expect(registry.resolve('dossier')?.name, 'memory.dossier');
      expect(registry.resolve(' Memory.Dossier ')?.name, 'memory.dossier');
      expect(registry.resolve('journal_log_water')?.name, 'journal.log_water');
      expect(registry.resolve('log_water')?.name, 'journal.log_water');
      expect(registry.resolve('functions.plan.create_meal')?.name, 'plan.create_meal');
    });

    test('un nom qui ne désigne rien, ou plusieurs choses, reste inconnu', () {
      expect(registry.resolve('outil.magique'), isNull);
      expect(registry.resolve(''), isNull);
      // « create » finit plusieurs outils : trop ambigu pour deviner.
      expect(registry.resolve('create'), isNull);
    });

    test('les lignes passent en tableau, en JSON écrit, ou en texte', () {
      expect(DossierTools.linesArg(['a', 'b']), ['a', 'b']);
      expect(DossierTools.linesArg('["a", "b c"]'), ['a', 'b c']);
      expect(DossierTools.linesArg('a\nb\n\nc'), ['a', 'b', 'c']);
      expect(DossierTools.linesArg('• a • b'), ['a', 'b']);
      expect(DossierTools.linesArg(null), isEmpty);
      expect(DossierTools.linesArg(42), isEmpty);
      expect(DossierTools.linesArg('   '), isEmpty);
    });

    test('le schéma du tampon est la liste fermée', () {
      final decl = registry.byName('memory.dossier')!.declaration;
      final stamp = (decl['parameters'] as Map)['properties']['stamp'] as Map;
      expect(stamp['enum'], DossierStamps.enumWords());
    });

    test('la promesse est un tiroir que le modèle peut remplir', () {
      final decl = registry.byName('memory.remember')!.declaration;
      final cat = (decl['parameters'] as Map)['properties']['category'] as Map;
      expect(cat['enum'], contains('promise'));
      expect(MemoryCategory.fromKey('promise'), MemoryCategory.promise);
      expect(MemoryCategory.fromKey('promises'), MemoryCategory.promise);
    });

    test('un fait retenu porte sa date, et le prompt la dit', () {
      // Les dates sont rangées sous la forme normalisée du fait, la même que
      // le dédoublonnage : sans accents ni ponctuation.
      final prefs = UserCoachPreferences(
        id: 'p',
        userId: 'u',
        promises: const ['plus de tacos après minuit'],
        customNotes: const ['garage, deux haltères'],
        factDates: const {'plus de tacos apres minuit': '2026-09-12'},
        createdAt: DateTime(2026, 10, 1),
      );
      final items = RyzeMemory.itemsOf(prefs);
      final promesse = items.firstWhere((i) => i.category == MemoryCategory.promise);
      expect(promesse.date, DateTime(2026, 9, 12));
      expect(items.firstWhere((i) => i.category == MemoryCategory.note).date, isNull);

      final lines = RyzeMemory.promptLines(prefs, RyzePersona.of('fr'));
      expect(lines, contains('Promesse : plus de tacos après minuit (2026-09-12)'));
      expect(lines, contains('Note : garage, deux haltères'));
    });

    test('après une extraction, seul le nouveau prend la date du jour', () {
      final before = UserCoachPreferences(
        id: 'p',
        userId: 'u',
        promises: const ['plus de tacos après minuit'],
        factDates: const {'plus de tacos apres minuit': '2026-09-12'},
        createdAt: DateTime(2026, 10, 1),
      );
      final extracted = before.copyWith(
        promises: const ['plus de tacos après minuit', '3 séances par semaine'],
        foodPreferences: const ['déteste le brocoli'],
      );
      final dates = RyzeMemory.datedAfterExtraction(before: before, extracted: extracted, now: DateTime(2026, 10, 3));
      expect(dates['plus de tacos apres minuit'], '2026-09-12');
      expect(dates['3 seances par semaine'], '2026-10-03');
      expect(dates['deteste le brocoli'], '2026-10-03');
      expect(dates.length, 3);
    });

    test('le document de préférences garde les promesses et les dates', () {
      final prefs = UserCoachPreferences(
        id: 'p',
        userId: 'u',
        promises: const ['3 séances par semaine'],
        factDates: const {'3 séances par semaine': '2026-10-03'},
        createdAt: DateTime(2026, 10, 1),
      );
      final json = prefs.toPreferencesJson();
      expect(json['promises'], ['3 séances par semaine']);
      expect(json['fact_dates'], {'3 séances par semaine': '2026-10-03'});

      final back = UserCoachPreferences.fromJson({
        'id': 'p',
        'user_id': 'u',
        'preferences': json,
        'created_at': '2026-10-01T00:00:00Z',
      });
      expect(back.promises, prefs.promises);
      expect(back.factDates, prefs.factDates);
    });
  });
}
