import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/design/chat.dart';

/// Ce que la bulle et la ligne d'action font du texte qu'on leur donne.
///
/// Vu sur appareil : des astérisques devant chaque exercice, et des lignes
/// d'action qui lisaient « ✓ ✅ 1 repas ajoutés ! », la coche de la ligne
/// devant celle de l'exécuteur.
void main() {
  group('Les listes du modèle', () {
    test('une puce Markdown devient une vraie puce', () {
      expect(RyzeBubble.tidy('* Squats : 3 x 20'), '•  Squats : 3 x 20');
      expect(RyzeBubble.tidy('- Pompes : 3 x 12'), '•  Pompes : 3 x 12');
    });

    test('même avec des espaces devant, comme le modèle les écrit', () {
      expect(RyzeBubble.tidy('*   **Squats** : 3 x 20'), '•  **Squats** : 3 x 20');
    });

    test('une liste entière, ligne par ligne', () {
      const raw = 'Voici :\n* Squats\n* Pompes\n- Fentes';
      expect(RyzeBubble.tidy(raw), 'Voici :\n•  Squats\n•  Pompes\n•  Fentes');
    });

    test('une liste numérotée garde ses numéros', () {
      expect(RyzeBubble.tidy('1. Échauffement\n2) Squats'), '1.  Échauffement\n2.  Squats');
    });

    test('un astérisque au milieu d\'une phrase n\'est pas une puce', () {
      const raw = 'Le gras compte 9 kcal * g';
      expect(RyzeBubble.tidy(raw), raw);
    });

    test('le gras reste au gras', () {
      // La puce se traite avant, le gras après : les deux doivent survivre.
      expect(RyzeBubble.tidy('* **Squats** : 3 x 20'), contains('**Squats**'));
    });
  });

  group('La ligne d\'action', () {
    test('ne garde pas la coche de l\'exécuteur', () {
      expect(RyzeToolLine.clean('✅ 1 repas ajouté au planificateur !'), '1 repas ajouté au planificateur');
      expect(RyzeToolLine.clean('❌ Aucune séance à annuler'), 'Aucune séance à annuler');
    });

    test('ni son point d\'exclamation', () {
      expect(RyzeToolLine.clean('0,5 L notés !'), '0,5 L notés');
      expect(RyzeToolLine.clean('Séance créée!'), 'Séance créée');
    });

    test('laisse un message propre tel quel', () {
      expect(RyzeToolLine.clean('Mercredi : Full Body'), 'Mercredi : Full Body');
    });
  });
}
