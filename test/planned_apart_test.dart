import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/nutrition/meal_sheet.dart';

/// Quand le plat prévu est une chose à part, on le montre et on peut l'enlever.
///
/// Noter un aliment sur un créneau prévu coche le plat prévu et le relie à
/// l'aliment : le plan passe donc à « terminé » sans que personne ait mangé ce
/// qu'il annonçait. Il devenait indéracinable, et « Prévu · Bol d'avoine »
/// restait sous le poke bowl pour toujours.
void main() {
  _pages();

  test('rien de noté : le plat prévu est tout ce qu’il y a', () {
    expect(MealSheet.plannedApart('Bol d’avoine et fruits', const []), isTrue);
  });

  test('mangé autre chose : le plan reste une chose à part', () {
    expect(MealSheet.plannedApart('Bol d’avoine et fruits', const ['Poke bowl au saumon']), isTrue);
  });

  test('mangé ce qui était prévu : un seul repas', () {
    expect(MealSheet.plannedApart('Bol d’avoine et fruits', const ['Bol d’avoine et fruits']), isFalse);
  });

  test('un repas noté hors plan ne s’invente pas un plan', () {
    // Le journal crée son reflet dans le planificateur, du même nom : sans
    // cette règle, la feuille proposerait de « retirer le repas prévu » pour
    // un plan qui n’a jamais existé.
    expect(MealSheet.plannedApart('Poke bowl au saumon', const ['Poke bowl au saumon']), isFalse);
  });

  test('plusieurs aliments notés : la liste fait le nom', () {
    expect(MealSheet.plannedApart('Poulet, riz et brocolis', const ['Poulet', 'riz', 'brocolis']), isTrue);
    expect(MealSheet.plannedApart('Poulet, riz', const ['Poulet', 'riz']), isFalse);
  });

  test('pas de plat prévu, pas de bouton', () {
    expect(MealSheet.plannedApart(null, const ['Poke bowl']), isFalse);
    expect(MealSheet.plannedApart('', const []), isFalse);
    expect(MealSheet.plannedApart('   ', const []), isFalse);
  });
}

/// Le repas note et le plat prevu sont deux pages, pas deux moities.
///
/// Ouvrir un petit-dejeuner note affichait le journal, et il fallait faire
/// defiler pour trouver le plat prevu sous un trait. Deux choses differentes
/// empilees dans la meme page.
void _pages() {
  group('Les pages d’un creneau', () {
    test('mange autre chose que ce qui etait prevu : deux pages', () {
      expect(MealSheet.pagesFor(eaten: true, apart: true), [MealPage.logged, MealPage.planned]);
    });

    test('mange ce qui etait prevu : une seule', () {
      expect(MealSheet.pagesFor(eaten: true, apart: false), [MealPage.logged]);
    });

    test('rien de note, un plat prevu : la page du plan', () {
      expect(MealSheet.pagesFor(eaten: false, apart: true), [MealPage.planned]);
    });

    test('creneau vide : la page du journal, qui dira qu’il n’y a rien', () {
      expect(MealSheet.pagesFor(eaten: false, apart: false), [MealPage.logged]);
    });
  });
}
