import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_persona.dart';
import 'package:ryze_app/ai/ryze_tools/ryze_tools.dart';

/// Ce que Ryze peut faire, et ce qu'il doit demander avant de le faire.
///
/// Le coach n'avait aucun outil : son prompt lui apprenait à décrire l'endroit
/// où l'utilisateur devait aller. Ces tests fixent le contrat des outils, celui
/// que le modèle lit et celui que l'application tient.
void main() {
  final registry = buildRyzeToolRegistry();

  group('Le registre tient debout', () {
    test('aucun reproche', () {
      expect(registry.validate(), isEmpty);
    });

    test('les noms sont uniques et acceptables par le modèle', () {
      final noms = registry.all.map((t) => t.name).toList();
      expect(noms.toSet().length, noms.length);
      for (final n in noms) {
        expect(RegExp(r'^[a-zA-Z0-9_.-]{1,63}$').hasMatch(n), isTrue, reason: n);
      }
    });

    test('chaque outil est rangé par domaine', () {
      // Le préfixe dit au modèle de quoi il s'agit avant même la description.
      const domaines = {'journal', 'plan', 'sport', 'nav', 'memory'};
      for (final t in registry.all) {
        final domaine = t.name.split('.').first;
        expect(domaines, contains(domaine), reason: '${t.name} hors domaine');
      }
    });

    test('un outil se retrouve par son nom', () {
      expect(registry.byName('journal.log_water'), isNotNull);
      expect(registry.byName('outil.qui.nexiste.pas'), isNull);
    });
  });

  group('Ce que le coach sait faire', () {
    final noms = registry.declarationsFor(RyzeSurface.coach).map((d) => d['name']).toList();

    test('noter l\'eau, le poids, un repas prévu', () {
      expect(noms, contains('journal.log_water'));
      expect(noms, contains('journal.log_weight'));
      expect(noms, contains('plan.mark_meal_eaten'));
    });

    test('lancer la séance, au lieu de dire où la trouver', () {
      // Le prompt disait « Va dans l'onglet Sport pour le lancer ! ».
      expect(noms, contains('sport.start_planned_workout'));
    });

    test('ouvrir le scanner et le planificateur', () {
      expect(noms, contains('nav.open_scanner'));
      expect(noms, contains('nav.open_planner'));
    });

    test('retenir un fait durable', () {
      expect(noms, contains('memory.remember'));
    });
  });

  group('Ce qui demande une validation', () {
    test('un poids et un repas coché, oui', () {
      // Ils écrivent dans une courbe ou dans le journal : un chiffre mal
      // entendu s'y installe.
      expect(registry.byName('journal.log_weight')!.needsConfirmation(const {}), isTrue);
      expect(registry.byName('plan.mark_meal_eaten')!.needsConfirmation(const {}), isTrue);
    });

    test('un verre d\'eau, non : la barre d\'annulation suffit', () {
      expect(registry.byName('journal.log_water')!.needsConfirmation(const {}), isFalse);
    });

    test('ouvrir un écran, non', () {
      expect(registry.byName('nav.open_scanner')!.needsConfirmation(const {}), isFalse);
      expect(registry.byName('nav.open_planner')!.needsConfirmation(const {}), isFalse);
    });

    test('tout ce qui demande une validation sait dire quoi', () {
      for (final t in registry.all.where((t) => t.needsConfirmation(const {}))) {
        expect(t.preview, isNotNull, reason: '${t.name} sans carte');
      }
    });
  });

  group('Les schémas envoyés au modèle', () {
    Map<String, dynamic> props(String name) =>
        ((registry.byName(name)!.declaration['parameters'] as Map)['properties'] as Map)
            .cast<String, dynamic>();

    List<String> requis(String name) => List<String>.from(
        (registry.byName(name)!.declaration['parameters'] as Map)['required'] as List);

    test('l\'eau se donne en millilitres, et c\'est obligatoire', () {
      expect(props('journal.log_water')['amount_ml']['type'], 'integer');
      expect(requis('journal.log_water'), contains('amount_ml'));
    });

    test('le poids est un nombre, pas un entier', () {
      // 78,4 kg doit passer.
      expect(props('journal.log_weight')['weight_kg']['type'], 'number');
    });

    test('un repas se désigne par son moment', () {
      final moments = List<String>.from(props('plan.mark_meal_eaten')['meal_type']['enum'] as List);
      expect(moments, ['breakfast', 'lunch', 'dinner', 'snack']);
      expect(requis('plan.mark_meal_eaten'), contains('meal_type'));
    });

    test('un jour est toujours l\'un des sept', () {
      for (final t in registry.all) {
        final p = (t.declaration['parameters'] as Map)['properties'] as Map;
        for (final entry in p.entries) {
          if (entry.key == 'day') {
            final jours = List<String>.from((entry.value as Map)['enum'] as List);
            expect(jours, hasLength(7), reason: '${t.name}.day');
          }
        }
      }
    });

    test('la mémoire n\'accepte que ses six tiroirs', () {
      final categories = List<String>.from(props('memory.remember')['category']['enum'] as List);
      expect(categories, hasLength(6));
      expect(categories, contains('allergy'));
      expect(categories, contains('fitness_constraint'));
    });

    test('le planificateur s\'ouvre sur un côté ou l\'autre', () {
      final modes = List<String>.from(props('nav.open_planner')['mode']['enum'] as List);
      expect(modes, ['meals', 'workouts']);
    });
  });

  group('Les descriptions guident le choix', () {
    test('chacune borne son usage, pas seulement son effet', () {
      // Une description qui dit ce que l'outil fait sans dire quand s'en
      // servir laisse le modèle deviner, et il devine mal.
      for (final t in registry.all) {
        final desc = (t.declaration['description'] as String).toLowerCase();
        expect(desc.length, greaterThan(40), reason: '${t.name} : description trop maigre');
        expect(desc.contains('when') || desc.contains('only'), isTrue,
            reason: '${t.name} : ne borne pas son usage');
      }
    });

    test('celles qui se ressemblent disent aussi quand ne pas s\'en servir', () {
      // Deux outils voisins ont besoin d'une frontière explicite, sinon le
      // modèle prend le premier qui passe.
      for (final nom in ['plan.mark_meal_eaten', 'sport.start_planned_workout']) {
        final desc = (registry.byName(nom)!.declaration['description'] as String).toLowerCase();
        expect(desc.contains('instead') || desc.contains('do not'), isTrue,
            reason: '$nom : sans frontière');
      }
    });

    test('les deux façons de noter un repas se distinguent', () {
      // Sans ça, le modèle coche un repas prévu alors que l'utilisateur a
      // mangé autre chose.
      final desc = registry.byName('plan.mark_meal_eaten')!.declaration['description'] as String;
      expect(desc, contains('journal.log_food_text'));
    });
  });
}
