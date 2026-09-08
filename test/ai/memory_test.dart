import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_memory.dart';
import 'package:ryze_app/models/coach_chat_models.dart';

/// Quand Ryze relit ce qu'il a retenu, et ce qu'il en garde.
///
/// L'extraction tournait après **chaque** réponse, sur **toute** la
/// conversation, et se terminait par une reconstruction de la session qui
/// coupait le fil en pleine discussion. Ces tests fixent le nouveau rythme.
void main() {
  CoachMessage message(DateTime at) => CoachMessage(
        id: '${at.microsecondsSinceEpoch}',
        conversationId: 'c',
        userId: 'u',
        role: MessageRole.user,
        content: 'peu importe',
        createdAt: at,
      );

  group('Quand l\'extraction est due', () {
    final maintenant = DateTime(2026, 9, 8, 14);

    test('jamais faite et assez de messages : oui', () {
      expect(
        RyzeMemory.isDue(lastExtractionAt: null, newMessagesSince: 6, now: maintenant),
        isTrue,
      );
    });

    test('jamais faite mais trop peu de messages : non', () {
      // Trois messages ne disent rien de durable sur quelqu'un.
      expect(
        RyzeMemory.isDue(lastExtractionAt: null, newMessagesSince: 3, now: maintenant),
        isFalse,
      );
    });

    test('déjà faite aujourd\'hui : non, même avec beaucoup de messages', () {
      // C'est tout le changement : une par jour de conversation, pas une par
      // réponse.
      expect(
        RyzeMemory.isDue(
          lastExtractionAt: DateTime(2026, 9, 8, 9),
          newMessagesSince: 40,
          now: maintenant,
        ),
        isFalse,
      );
    });

    test('faite hier : oui', () {
      expect(
        RyzeMemory.isDue(
          lastExtractionAt: DateTime(2026, 9, 7, 23, 58),
          newMessagesSince: 5,
          now: maintenant,
        ),
        isTrue,
      );
    });

    test('faite hier mais rien de neuf : non', () {
      expect(
        RyzeMemory.isDue(
          lastExtractionAt: DateTime(2026, 9, 7),
          newMessagesSince: 1,
          now: maintenant,
        ),
        isFalse,
      );
    });
  });

  group('Ce que l\'extraction relit', () {
    test('seulement les messages arrivés depuis la dernière fois', () {
      final derniere = DateTime(2026, 9, 8, 10);
      final tous = [
        message(DateTime(2026, 9, 8, 8)),
        message(DateTime(2026, 9, 8, 9, 30)),
        message(DateTime(2026, 9, 8, 11)),
        message(DateTime(2026, 9, 8, 12)),
      ];

      final nouveaux = RyzeMemory.since(tous, derniere);

      expect(nouveaux, hasLength(2),
          reason: 'toute la conversation repartait à chaque fois');
      expect(nouveaux.first.createdAt.hour, 11);
    });

    test('tout, la première fois', () {
      final tous = [message(DateTime(2026, 9, 8, 8)), message(DateTime(2026, 9, 8, 9))];
      expect(RyzeMemory.since(tous, null), hasLength(2));
    });
  });

  group('Les plafonds', () {
    test('un tiroir qui déborde garde les plus récents', () {
      // La fusion en union de sets ne perdait jamais rien : la mémoire
      // enflait à chaque extraction jusqu'à occuper le prompt.
      final beaucoup = List.generate(20, (i) => 'fait $i');
      final gardes = RyzeMemory.capped(beaucoup);

      expect(gardes, hasLength(RyzeMemory.maxPerCategory));
      expect(gardes.last, 'fait 19');
      expect(gardes.first, 'fait 5');
    });

    test('un tiroir sous le plafond ne bouge pas', () {
      final peu = ['noix', 'lactose'];
      expect(RyzeMemory.capped(peu), peu);
    });

    test('un tiroir vide reste vide', () {
      expect(RyzeMemory.capped(const []), isEmpty);
    });
  });

  group('Les tiroirs', () {
    test('chaque catégorie a sa clé dans le document', () {
      for (final c in MemoryCategory.values) {
        expect(c.jsonKey.isNotEmpty, isTrue);
      }
      expect(MemoryCategory.allergy.jsonKey, 'allergies');
      expect(MemoryCategory.fitnessConstraint.jsonKey, 'fitness_constraints');
    });

    test('les clés sont uniques', () {
      final cles = MemoryCategory.values.map((c) => c.jsonKey).toSet();
      expect(cles.length, MemoryCategory.values.length);
    });

    test('une clé se retrouve dans les deux sens', () {
      expect(MemoryCategory.fromKey('allergies'), MemoryCategory.allergy);
      expect(MemoryCategory.fromKey('allergy'), MemoryCategory.allergy);
      expect(MemoryCategory.fromKey('inconnue'), isNull);
    });
  });

  group('Ce que la mémoire donne au prompt', () {
    test('les contraintes passent devant les goûts', () {
      // Une allergie et une blessure changent ce que Ryze a le droit de
      // proposer ; un goût ne fait qu'orienter.
      final prefs = UserCoachPreferences(
        id: '1',
        userId: 'u',
        allergies: const ['noix'],
        fitnessConstraints: const ['genou droit'],
        foodPreferences: const ['aime le poulet'],
        createdAt: DateTime(2026, 1, 1),
      );

      final items = RyzeMemory.itemsOf(prefs);
      final categories = items.map((i) => i.category).toList();

      expect(categories.first, MemoryCategory.allergy);
      expect(categories[1], MemoryCategory.fitnessConstraint);
      expect(categories.last, MemoryCategory.foodPreference);
    });

    test('une mémoire vide ne rend rien plutôt qu\'une ligne vide', () {
      expect(RyzeMemory.itemsOf(null), isEmpty);
      expect(
        RyzeMemory.itemsOf(UserCoachPreferences.empty(userId: 'u')),
        isEmpty,
      );
    });

    test('les entrées vides sont écartées', () {
      final prefs = UserCoachPreferences(
        id: '1',
        userId: 'u',
        allergies: const ['noix', '  ', ''],
        createdAt: DateTime(2026, 1, 1),
      );
      expect(RyzeMemory.itemsOf(prefs), hasLength(1));
    });
  });
}
