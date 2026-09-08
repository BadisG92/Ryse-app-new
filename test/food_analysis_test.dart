import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/services/gemini_analysis_service_v2.dart';

/// Ce que devient la réponse du modèle avant d'arriver à l'écran.
///
/// La règle que ces tests protègent : **une quantité annoncée par
/// l'utilisateur est un fait**. « 150 g de purée » doit être chiffré sur
/// 150 g de puree. Le prompt le jurait déjà, mais le code multipliait ensuite
/// toutes les macros par les facteurs de compensation, et l'écran affichait
/// les calories d'environ 175 g.
void main() {
  Map<String, dynamic> food({
    String name = 'Purée',
    String from = 'estimate',
    bool liquid = false,
    num? grams = 150,
    num? ml,
    num proteins = 3,
    num carbs = 22,
    num fats = 5,
    num confidence = 90,
  }) =>
      {
        'name': name,
        'confidence': confidence,
        'is_liquid': liquid,
        'portion_grams': grams,
        'portion_ml': ml,
        'portion_from': from,
        'nutrition': {'proteins_g': proteins, 'carbs_g': carbs, 'fats_g': fats},
      };

  Map<String, dynamic> response(List<Map<String, dynamic>> foods) =>
      {'meal_name': 'Purée maison', 'foods': foods};

  int kcal(double p, double c, double f) => ((p * 4) + (c * 4) + (f * 9)).round();

  group('Une quantité donnée par l\'utilisateur', () {
    test('arrive intacte, sans un gramme de correction', () {
      // 150 g de purée : 3 g de protéines, 22 de glucides, 5 de lipides.
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([food(from: 'user')]));

      expect(parsed.foods, hasLength(1));
      final puree = parsed.foods.single;

      expect(puree.nutrition.proteins, closeTo(3, 0.001));
      expect(puree.nutrition.carbs, closeTo(22, 0.001));
      expect(puree.nutrition.fats, closeTo(5, 0.001));
      expect(puree.estimatedQuantity, 150);
      expect(puree.calories, kcal(3, 22, 5)); // 145, et pas 169
    });

    test('vaut aussi quand l\'utilisateur a donné des calories', () {
      // « un gâteau de 500 kcal » : le modèle choisit des macros qui font
      // exactement 500, et rien ne doit les gonfler après coup.
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Gâteau', from: 'user', grams: 120, proteins: 5, carbs: 65, fats: 24.4),
      ]));

      expect(parsed.foods.single.calories, kcal(5, 65, 24.4));
    });

    test('n\'épargne que l\'aliment concerné', () {
      // Une seule quantité annoncée dans une assiette de deux : l'autre reste
      // une estimation, donc il garde sa compensation.
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Purée', from: 'user'),
        food(name: 'Steak', from: 'estimate', proteins: 30, carbs: 0, fats: 10),
      ]));

      expect(parsed.foods, hasLength(2));
      expect(parsed.foods[0].nutrition.proteins, closeTo(3, 0.001));
      expect(parsed.foods[1].nutrition.proteins, closeTo(30 * 1.15, 0.001));
    });
  });

  group('Une quantité devinée par le modèle', () {
    test('porte la compensation, parce qu\'il oublie l\'huile et la sauce', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([food()]));
      final puree = parsed.foods.single;

      expect(puree.nutrition.proteins, closeTo(3 * 1.15, 0.001));
      expect(puree.nutrition.carbs, closeTo(22 * 1.20, 0.001));
      expect(puree.nutrition.fats, closeTo(5 * 1.10, 0.001));
    });

    test('la table de compensation ne prétend plus corriger les calories', () {
      // L'entrée `calories: 1.25` n'était lue nulle part : les calories sont
      // recalculées depuis les macros. La garder faisait croire à +25 %.
      expect(GeminiAnalysisServiceV2.geminiCorrections.containsKey('calories'), isFalse);
      expect(GeminiAnalysisServiceV2.geminiCorrections.keys.toSet(),
          {'proteines', 'glucides', 'lipides'});
    });
  });

  group('Les liquides', () {
    test('se mesurent en millilitres, des deux côtés', () {
      // Le prompt de la photo ne connaissait pas les liquides : un verre de
      // jus photographié était pesé en grammes.
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Jus d\'orange', liquid: true, grams: null, ml: 250, proteins: 1, carbs: 26, fats: 0),
      ]));

      final jus = parsed.foods.single;
      expect(jus.isLiquid, isTrue);
      expect(jus.estimatedQuantity, 250);
    });

    test('se rabattent sur les grammes si le modèle s\'est trompé de champ', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Lait', liquid: true, grams: 200, ml: null),
      ]));
      expect(parsed.foods.single.estimatedQuantity, 200);
    });
  });

  group('Ce qui arrive à l\'écran', () {
    test('un aliment trop incertain ne compte pas', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Quelque chose', confidence: 10),
      ]));
      expect(parsed.foods, isEmpty);
    });

    test('un aliment moyennement sûr compte quand même', () {
      // La photo exigeait 60 % et laissait tomber le reste en silence, ce qui
      // faussait le total sans le dire. L'écran de revue permet de retirer.
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        food(name: 'Sauce', confidence: 45),
      ]));
      expect(parsed.foods, hasLength(1));
    });

    test('la liste s\'arrête à huit lignes', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods(
          response([for (var i = 0; i < 12; i++) food(name: 'Aliment $i')]));
      expect(parsed.foods, hasLength(8));
    });

    test('un aliment illisible ne fait pas tomber les autres', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods(response([
        {'name': 'Sans nutrition'},
        food(name: 'Purée'),
      ]));
      expect(parsed.foods, hasLength(1));
      expect(parsed.foods.single.name.toLowerCase(), contains('purée'));
    });

    test('une description sans nourriture rend de quoi la reformuler', () {
      final parsed = GeminiAnalysisServiceV2.parseFoods({
        'error': 'non_food_input',
        'suggestion': 'Décris un repas avec ses quantités.',
      });

      expect(parsed.foods, isEmpty);
      expect(parsed.error, isNotNull);
      expect(parsed.error, contains('quantités'));
    });

    test('une réponse vide ne fabrique rien', () {
      // Un repli cherchait des mots anglais dans le texte et inventait des
      // portions standard, sur un compte français qui reçoit du français.
      final parsed = GeminiAnalysisServiceV2.parseFoods({'foods': []});
      expect(parsed.foods, isEmpty);
      expect(parsed.error, isNull);
    });
  });
}
