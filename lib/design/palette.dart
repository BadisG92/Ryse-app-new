import 'package:flutter/material.dart';

/// Les cinq habits de Ryze.
///
/// Une palette ne change que deux choses : **le primaire**, la couleur de ce
/// que l'utilisateur choisit et presse, et **le secondaire**, celle de ce que
/// Ryze rend. Le papier, les gris, l'erreur et les trois macronutriments ne
/// bougent pas — ils portent un sens qui ne dépend pas du goût.
///
/// Les cinq duos ne sont pas choisis à l'œil. Chacun tient quatre seuils,
/// mesurés :
///
/// | | Nuit | Rose | Forêt | Ardoise | Prune | seuil |
/// |---|---|---|---|---|---|---|
/// | encre sur papier | 17,0 | 15,1 | 14,2 | 15,6 | 15,8 | ≥ 7 |
/// | blanc sur encre | 18,4 | 16,3 | 15,3 | 16,9 | 17,1 | ≥ 7 |
/// | ambre foncée sur papier | 4,8 | 6,1 | 5,4 | 6,4 | 8,4 | ≥ 4,5 |
/// | secondaire sur primaire | 9,2 | 6,0 | 6,9 | 6,5 | 6,4 | ≥ 3 |
///
/// C'est la raison pour laquelle il y a cinq duos plutôt qu'un choix libre :
/// cinq combinaisons vérifiées valent mieux que vingt-cinq dont aucune ne
/// l'est. Un ambre sur du rose, ou un vert sur du violet, se casse tout de
/// suite — pas en théorie, en contraste mesurable.
@immutable
class RyzePalette {
  const RyzePalette({
    required this.key,
    required this.ink,
    required this.ink2,
    required this.acc,
    required this.accDeep,
    required this.accLight,
    required this.accTint,
    required this.accInk,
    required this.glowWarm,
  });

  /// La clé du dictionnaire qui la nomme.
  final String key;

  /// Le primaire : ce que l'utilisateur choisit, presse, valide.
  final Color ink;

  /// Sa variante claire, pour les dégradés et l'auréole froide du fond.
  final Color ink2;

  /// Le secondaire : ce que Ryze rend — la progression, ses conseils, sa voix.
  final Color acc;
  final Color accDeep;
  final Color accLight;

  /// Le voile du secondaire, sur lequel `accInk` doit rester lisible.
  final Color accTint;

  /// Le secondaire assombri jusqu'à porter du petit texte sur le papier.
  final Color accInk;

  /// L'auréole chaude en haut à droite de chaque écran.
  final Color glowWarm;
}

/// Les cinq, et rien d'autre.
class RyzePalettes {
  RyzePalettes._();

  /// Le navy et l'ambre d'origine.
  static const RyzePalette nuit = RyzePalette(
    key: 'theme_nuit',
    ink: Color(0xFF0B132B),
    ink2: Color(0xFF1B2A5B),
    acc: Color(0xFFF2A93B),
    accDeep: Color(0xFFD98A16),
    accLight: Color(0xFFFFC766),
    accTint: Color(0xFFFDF1DC),
    accInk: Color(0xFF9A5F0C),
    glowWarm: Color(0xFFFFC478),
  );

  static const RyzePalette rose = RyzePalette(
    key: 'theme_rose',
    ink: Color(0xFF3B1028),
    ink2: Color(0xFF6B2049),
    acc: Color(0xFFF2739D),
    accDeep: Color(0xFFD94E7E),
    accLight: Color(0xFFFFA3C0),
    accTint: Color(0xFFFDE7EF),
    accInk: Color(0xFFA82C5B),
    glowWarm: Color(0xFFFFB3CC),
  );

  static const RyzePalette foret = RyzePalette(
    key: 'theme_foret',
    ink: Color(0xFF0E2A20),
    ink2: Color(0xFF1D5240),
    acc: Color(0xFFE0A23C),
    accDeep: Color(0xFFC08418),
    accLight: Color(0xFFF5C777),
    accTint: Color(0xFFFBF0DC),
    accInk: Color(0xFF8C5A0E),
    glowWarm: Color(0xFFF2CE8A),
  );

  static const RyzePalette ardoise = RyzePalette(
    key: 'theme_ardoise',
    ink: Color(0xFF1A1D24),
    ink2: Color(0xFF39404F),
    acc: Color(0xFF5FA8D3),
    accDeep: Color(0xFF3D86B0),
    accLight: Color(0xFF96C9E8),
    accTint: Color(0xFFE7F1F8),
    accInk: Color(0xFF1F5F86),
    glowWarm: Color(0xFFA9D4EC),
  );

  static const RyzePalette prune = RyzePalette(
    key: 'theme_prune',
    ink: Color(0xFF2A1038),
    ink2: Color(0xFF4E2069),
    acc: Color(0xFFC77DFF),
    accDeep: Color(0xFFA44BE0),
    accLight: Color(0xFFDDA9FF),
    accTint: Color(0xFFF3E8FD),
    accInk: Color(0xFF6A2299),
    glowWarm: Color(0xFFD5A8F5),
  );

  static const List<RyzePalette> all = [nuit, rose, foret, ardoise, prune];

  /// Celle qui porte cette clé, ou celle d'origine. Une clé inconnue — un
  /// réglage d'une version future, lu par une version ancienne — ne doit
  /// jamais laisser l'application sans couleurs.
  static RyzePalette byKey(String? key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return nuit;
  }
}
