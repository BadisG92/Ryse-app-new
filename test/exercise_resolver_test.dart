import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/exercise_resolver.dart';

/// L'identité d'un exercice.
///
/// Ryze peut nommer n'importe quel exercice ; ce qu'il ne doit jamais faire,
/// c'est créer deux fois le même sous deux orthographes. Le détail d'un
/// exercice ne montrerait alors qu'une partie des séances.
///
/// [ExerciseResolver.normalize] est le miroir de la fonction SQL
/// `public.ryze_normalize_exercise`, qui porte l'index unique. Les cas ci-
/// dessous sont ceux vérifiés des deux côtés : si l'un change sans l'autre,
/// la base refusera des insertions que le code croit légitimes.
void main() {
  group('La forme comparable d\'un nom', () {
    test('ignore la casse', () {
      expect(ExerciseResolver.normalize('Développé Couché'),
          ExerciseResolver.normalize('développé couché'));
    });

    test('ignore les accents', () {
      expect(ExerciseResolver.normalize('Développé couché'), 'developpe couche');
      expect(ExerciseResolver.normalize('Élévations latérales'), 'elevations laterales');
    });

    test('ignore les tirets et la ponctuation', () {
      expect(ExerciseResolver.normalize('Step-up'), 'step up');
      expect(ExerciseResolver.normalize('Développé-couché, barre'), 'developpe couche barre');
    });

    test('resserre les espaces et taille les bords', () {
      expect(ExerciseResolver.normalize('  Rowing   barre  '), 'rowing barre');
    });

    test('déplie le ß allemand', () {
      expect(ExerciseResolver.normalize('Fußheben'), 'fussheben');
    });

    test('garde les chiffres', () {
      expect(ExerciseResolver.normalize('100 pompes'), '100 pompes');
      expect(ExerciseResolver.normalize('100 Pompes !'), '100 pompes');
    });

    test('rend une chaîne vide pour un nom sans lettre ni chiffre', () {
      expect(ExerciseResolver.normalize('   '), '');
      expect(ExerciseResolver.normalize('---'), '');
    });

    test('les cas vérifiés aussi côté SQL donnent le même résultat', () {
      // Ces trois paires ont été exécutées contre
      // `public.ryze_normalize_exercise` sur la base réelle.
      expect(ExerciseResolver.normalize('Développé-Couché  à la Barre'),
          'developpe couche a la barre');
      expect(ExerciseResolver.normalize('Bankdrücken'), 'bankdrucken');
      expect(ExerciseResolver.normalize('100 pompes'), '100 pompes');
    });
  });

  group('La ressemblance entre deux noms', () {
    test('vaut 1 pour deux écritures du même nom', () {
      expect(ExerciseResolver.similarity('Développé couché', 'developpe-couche'), 1.0);
    });

    test('ne dépend pas de l\'ordre des mots', () {
      expect(ExerciseResolver.similarity('barre rowing', 'rowing barre'), 1.0);
    });

    test('baisse quand un mot s\'ajoute', () {
      final score = ExerciseResolver.similarity('développé couché', 'développé couché haltères');
      expect(score, lessThan(1.0));
      expect(score, greaterThan(0.0));
    });

    test('reste basse pour deux exercices différents', () {
      // Le seuil de rapprochement est à 0,8 : ces deux-là ne doivent jamais
      // être confondus, sinon leurs séances se mélangent.
      expect(ExerciseResolver.similarity('Développé couché', 'Rowing barre'), lessThan(0.8));
      expect(ExerciseResolver.similarity('Squat', 'Soulevé de terre'), lessThan(0.8));
    });

    test('vaut 0 quand un des deux noms est vide', () {
      expect(ExerciseResolver.similarity('', 'Squat'), 0.0);
      expect(ExerciseResolver.similarity('Squat', '   '), 0.0);
    });
  });

  group('Ce que le dédoublonnage protège', () {
    test('les variantes d\'un même exercice partagent une seule clé', () {
      const variantes = [
        'Développé couché',
        'developpe couche',
        'DÉVELOPPÉ COUCHÉ',
        'Développé-couché',
        '  développé   couché  ',
      ];
      final cles = variantes.map(ExerciseResolver.normalize).toSet();
      expect(cles.length, 1, reason: 'ces cinq écritures doivent viser la même ligne');
    });

    test('deux exercices distincts gardent des clés distinctes', () {
      final cles = ['Squat', 'Squat bulgare', 'Front squat']
          .map(ExerciseResolver.normalize)
          .toSet();
      expect(cles.length, 3);
    });
  });
}
