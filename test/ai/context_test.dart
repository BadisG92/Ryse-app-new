import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ryze_app/ai/prompts/persona_de.dart';
import 'package:ryze_app/ai/prompts/persona_en.dart';
import 'package:ryze_app/ai/prompts/persona_fr.dart';
import 'package:ryze_app/ai/ryze_context.dart';
import 'package:ryze_app/services/global_state_manager.dart';

/// Ce que Ryze reçoit avant de répondre.
///
/// Les rendus sont des fonctions pures : elles se testent sans base, et c'est
/// là que vivent les bornes. Le prompt du coach n'en avait aucune — une
/// journée bien suivie produisait une ligne par aliment, sans plafond.
void main() {
  const fr = PersonaFr();
  const en = PersonaEn();
  const de = PersonaDe();

  group('Quel jour on est', () {
    // Les mêmes locales que `main.dart` charge au démarrage.
    setUpAll(() async {
      await initializeDateFormatting('fr');
      await initializeDateFormatting('en');
      await initializeDateFormatting('de');
    });

    // Ryze ne le savait pas. « Une séance demain » n'était pas un calcul mais
    // une devinette, et elle est tombée sur aujourd'hui.
    final mardi = DateTime(2026, 9, 8, 20, 21);

    test('la date, l\'heure et le fuseau sont dits', () {
      final bloc = RyzeContext.renderNow(fr, at: mardi);

      expect(bloc, contains('mardi'));
      expect(bloc, contains('8 septembre 2026'));
      expect(bloc, contains('20:21'));
      expect(bloc, contains('UTC'));
    });

    test('demain est nommé, pas laissé à deviner', () {
      final bloc = RyzeContext.renderNow(fr, at: mardi);
      expect(bloc, contains('mercredi 9 septembre'));
    });

    test('chaque langue a sa date et son mot', () {
      expect(RyzeContext.renderNow(en, at: mardi), contains('Tuesday'));
      expect(RyzeContext.renderNow(en, at: mardi), contains('"tomorrow"'));
      expect(RyzeContext.renderNow(de, at: mardi), contains('Dienstag'));
      expect(RyzeContext.renderNow(de, at: mardi), contains('morgen'));
    });

    test('le passage à minuit change le lendemain', () {
      final veille = RyzeContext.renderNow(fr, at: DateTime(2026, 9, 8, 23, 59));
      final apres = RyzeContext.renderNow(fr, at: DateTime(2026, 9, 9, 0, 1));

      expect(veille, contains('mercredi 9 septembre'));
      expect(apres, contains('jeudi 10 septembre'));
    });
  });

  group('Les repas du jour sont bornés', () {
    test('une journée normale s\'affiche en entier', () {
      final texte = RyzeContext.renderMeals(fr, ['Omelette 320 kcal', 'Poulet riz 600 kcal']);
      expect(texte, contains('Omelette 320 kcal'));
      expect(texte, contains('Poulet riz 600 kcal'));
      expect(texte, isNot(contains('(+')));
    });

    test('une journée chargée se résume au lieu de tout déverser', () {
      final lignes = List.generate(35, (i) => 'Aliment $i');
      final texte = RyzeContext.renderMeals(fr, lignes);

      final compte = '\n'.allMatches(texte).length;
      expect(compte, lessThan(25), reason: 'le bloc doit rester borné');
      expect(texte, contains('(+15)'), reason: '35 lignes, 20 montrées, 15 comptées');
      expect(texte, contains('Aliment 0'));
      expect(texte, isNot(contains('Aliment 34')));
    });

    test('une journée vide le dit dans la langue de l\'utilisateur', () {
      expect(RyzeContext.renderMeals(fr, const []), contains('Rien de noté'));
      expect(RyzeContext.renderMeals(en, const []), contains('Nothing logged'));
      expect(RyzeContext.renderMeals(de, const []), contains('nichts eingetragen'));
    });
  });

  group('La mémoire est bornée', () {
    test('elle se coupe au plafond et annonce le reste', () {
      final items = List.generate(50, (i) => 'fait $i');
      final texte = RyzeContext.renderMemory(fr, items);
      expect(texte, contains('(+10)'));
      expect(texte, isNot(contains('fait 45')));
    });

    test('une mémoire vide se dit, elle ne se tait pas', () {
      expect(RyzeContext.renderMemory(fr, const []), contains('Rien de retenu'));
      expect(RyzeContext.renderMemory(de, const []), contains('Noch nichts'));
    });
  });

  group('Le bilan du jour', () {
    test('calcule ce qu\'il reste plutôt que de le demander', () {
      final texte = RyzeContext.renderToday(
        fr,
        calorieGoal: 2200,
        caloriesEaten: 1450,
        proteins: 90, proteinsGoal: 140,
        carbs: 150, carbsGoal: 220,
        fats: 50, fatsGoal: 70,
        waterL: 1.2, waterGoalL: 2.5,
      );
      expect(texte, contains('750 kcal'));
      expect(texte, contains('P 90/140 g'));
      expect(texte, contains('1.2/2.5 L'));
    });

    test('un dépassement se montre en négatif, sans le maquiller', () {
      final texte = RyzeContext.renderToday(
        fr,
        calorieGoal: 2000,
        caloriesEaten: 2300,
        proteins: 0, proteinsGoal: 0, carbs: 0, carbsGoal: 0, fats: 0, fatsGoal: 0,
        waterL: 0, waterGoalL: 2,
      );
      expect(texte, contains('-300 kcal'));
    });

    test('le titre suit la langue', () {
      final commun = {
        'calorieGoal': 2000, 'caloriesEaten': 0,
      };
      String rendu(dynamic p) => RyzeContext.renderToday(
            p,
            calorieGoal: commun['calorieGoal'] as int,
            caloriesEaten: commun['caloriesEaten'] as int,
            proteins: 0, proteinsGoal: 0, carbs: 0, carbsGoal: 0, fats: 0, fatsGoal: 0,
            waterL: 0, waterGoalL: 2,
          );
      expect(rendu(fr), contains("AUJOURD'HUI"));
      expect(rendu(en), contains('TODAY'));
      expect(rendu(de), contains('HEUTE'));
    });
  });

  group('Le profil', () {
    test('n\'annonce que ce qui est renseigné', () {
      final texte = RyzeContext.renderProfile(fr, gender: 'female', age: 31, streak: 12);
      expect(texte, contains('Femme'));
      expect(texte, contains('31 ans'));
      expect(texte, contains("12 jours d'affilée"));
      // Rien sur le poids : il n'a pas été donné, donc il ne s'invente pas.
      expect(texte, isNot(contains('kg')));
    });

    test('une série à zéro ne se mentionne pas', () {
      final texte = RyzeContext.renderProfile(fr, gender: 'male', streak: 0);
      expect(texte, isNot(contains('affilée')));
    });
  });

  group('La tendance du poids', () {
    test('dit le sens de la variation, ce que le prompt ne savait pas faire', () {
      final baisse = RyzeContext.renderWeightTrend(fr, current: 78.4, fourWeeksAgo: 80.0, target: 75);
      expect(baisse, contains('-1.6 kg'));

      final hausse = RyzeContext.renderWeightTrend(fr, current: 81.0, fourWeeksAgo: 80.0);
      expect(hausse, contains('+1.0 kg'));
    });
  });

  group('Ce qu\'un changement rend faux', () {
    test('boire refait le jour, et rien d\'autre', () {
      expect(RyzeContext.blocksFor(ChangeType.water), {RyzeBlock.today});
    });

    test('un repas touche le jour, les repas et la semaine', () {
      final blocs = RyzeContext.blocksFor(ChangeType.meals);
      expect(blocs, contains(RyzeBlock.today));
      expect(blocs, contains(RyzeBlock.meals));
      expect(blocs, contains(RyzeBlock.weekPlan));
    });

    test('une séance touche les séances et la semaine', () {
      expect(RyzeContext.blocksFor(ChangeType.workout),
          {RyzeBlock.recentSessions, RyzeBlock.weekPlan});
    });

    test('un nouveau jour invalide tout', () {
      expect(RyzeContext.blocksFor(ChangeType.dayReset).length, RyzeBlock.values.length);
    });

    test('chaque type de changement est couvert', () {
      // Un `switch` non exhaustif ne compilerait pas ; ce test garde la
      // promesse qu'aucun type ne rend un ensemble vide par accident.
      for (final type in ChangeType.values) {
        expect(RyzeContext.blocksFor(type).isNotEmpty, isTrue,
            reason: '$type ne rafraîchit rien');
      }
    });
  });

  group('L\'assemblage', () {
    test('saute les blocs vides plutôt que de laisser des trous', () {
      final texte = RyzeContext.assemble({
        RyzeBlock.today: '## AUJOURD\'HUI\n2000 kcal',
        RyzeBlock.meals: '',
        RyzeBlock.profile: '## PROFIL\nFemme',
      });
      expect(texte, contains('AUJOURD\'HUI'));
      expect(texte, contains('PROFIL'));
      expect(texte, isNot(contains('\n\n\n')));
    });

    test('garde l\'ordre des blocs, quel que soit l\'ordre de la table', () {
      final texte = RyzeContext.assemble({
        RyzeBlock.memory: '## MEM',
        RyzeBlock.today: '## JOUR',
      });
      expect(texte.indexOf('## JOUR'), lessThan(texte.indexOf('## MEM')));
    });

    test('une section sans contenu ne produit pas de titre orphelin', () {
      expect(RyzeContext.section(fr, 'section_today', '   '), isEmpty);
    });
  });
}
