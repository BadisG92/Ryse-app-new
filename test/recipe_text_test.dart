import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/design/recipe_view.dart';

/// La recette que Ryze écrit, telle qu'elle est relue.
///
/// L'ancien lecteur exigeait « INGRÉDIENTS: » en majuscules avec le
/// deux-points collé. Le modèle écrit « Ingrédients : » à la française, et
/// « Conseil » aussi souvent qu'« Astuce ». Rien ne correspondait, donc tout
/// retombait dans un bloc unique et les sections disparaissaient.
void main() {
  group('Ce que le modèle écrit vraiment', () {
    test('la forme française, avec l\'espace avant le deux-points', () {
      final r = RecipeText.parse(
        'Un bol frais et protéiné.'
        '---Ingrédients : \n- 150 g de yaourt grec\n- 80 g de fruits rouges'
        '---Préparation : \n1. Verser le yaourt\n2. Ajouter les fruits'
        '---Conseil : ajoute quelques amandes pour le croquant.',
      );

      expect(r.summary, 'Un bol frais et protéiné.');
      expect(r.ingredients, contains('150 g de yaourt grec'));
      expect(r.steps, contains('Verser le yaourt'));
      expect(r.tip, contains('amandes'));
    });

    test('la forme anglaise et la forme allemande', () {
      final en = RecipeText.parse('A quick bowl.---Ingredients: - 2 eggs---Method: 1. Beat---Tip: salt at the end');
      expect(en.ingredients, contains('2 eggs'));
      expect(en.steps, contains('Beat'));
      expect(en.tip, contains('salt'));

      final de = RecipeText.parse('Eine Schüssel.---Zutaten: - 2 Eier---Zubereitung: 1. Verquirlen---Tipp: Salz zum Schluss');
      expect(de.ingredients, contains('2 Eier'));
      expect(de.steps, contains('Verquirlen'));
      expect(de.tip, contains('Salz'));
    });

    test('les majuscules d\'avant marchent toujours', () {
      final r = RecipeText.parse('Plat.---INGRÉDIENTS: riz---RECETTE: cuire---ASTUCE: sel');
      expect(r.ingredients, 'riz');
      expect(r.steps, 'cuire');
      expect(r.tip, 'sel');
    });

    test('le gras Markdown ne masque pas la section', () {
      final r = RecipeText.parse('Plat.---**Ingrédients :** poulet');
      expect(r.ingredients, contains('poulet'));
    });
  });

  group('Ce qui n\'a pas la bonne forme', () {
    test('une description sans section reste une description', () {
      final r = RecipeText.parse('Juste une phrase sur le plat.');
      expect(r.summary, 'Juste une phrase sur le plat.');
      expect(r.hasSections, isFalse);
    });

    test('un morceau sans nom n\'est pas perdu', () {
      final r = RecipeText.parse('Le plat.---Une précision de plus.---Ingrédients : riz');
      expect(r.summary, contains('Le plat.'));
      expect(r.summary, contains('Une précision de plus.'));
      expect(r.ingredients, 'riz');
    });

    test('une description vide ne rend rien', () {
      expect(RecipeText.parse('').isEmpty, isTrue);
      expect(RecipeText.parse('   ').isEmpty, isTrue);
    });
  });
}
