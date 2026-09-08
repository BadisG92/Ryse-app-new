import 'package:flutter/material.dart';

/// Les cinq univers de Ryze.
///
/// Une palette change trois choses :
///
/// * **le texte** — un quasi-noir teinté de la palette. Il porte le texte
///   courant, donc il ne peut pas être coloré : la lisibilité le veut sombre.
/// * **la marque** — la couleur saturée des surfaces pleines et des bordures :
///   un bouton, une tuile validée, une bulle, l'anneau d'un jour. C'est elle
///   qu'on voit de loin, et c'est elle qui fait l'univers.
/// * **le secondaire** — ce que Ryze rend : la jauge, ses conseils, sa voix.
///
/// Le papier, les gris, l'erreur et les trois macronutriments ne bougent pas.
///
/// **Pourquoi la marque est séparée du texte.** Les deux étaient un seul jeton.
/// Le texte doit tenir 7:1 sur le papier, ce qui force le quasi-noir ; les
/// surfaces héritaient de cette contrainte, et les cinq palettes s'effondraient
/// vers le même noir — leur contraste deux à deux tombait entre 1,01 et 1,20,
/// c'est-à-dire la même couleur. Choisir « Rose » donnait une application noire
/// avec des jauges roses. Séparées, la marque peut être franche : un bouton
/// rose est rose.
///
/// **Ce qui est vérifié**, pour chacune des cinq :
///
/// | | Nuit | Rose | Prune | Océan | Forêt | seuil |
/// |---|---|---|---|---|---|---|
/// | texte sur papier | 17,0 | 15,2 | 16,4 | 14,0 | 14,2 | ≥ 7 |
/// | blanc sur la marque | 14,3 | 4,6 | 7,1 | 6,2 | 8,0 | ≥ 4,5 |
/// | marque sur papier | 13,3 | 4,2 | 6,6 | 5,7 | 7,4 | ≥ 3 |
/// | secondaire foncé sur papier | 4,8 | 5,6 | 4,6 | 5,9 | 6,1 | ≥ 4,5 |
/// | secondaire sur la marque | 7,2 | 3,2 | 5,3 | 3,3 | 3,1 | ≥ 3 |
///
/// Et les cinq marques sont à **36° de teinte** au minimum les unes des autres :
/// c'est ce qui les rend reconnaissables, la clarté ne suffisant pas à
/// distinguer un magenta d'un turquoise.
@immutable
class RyzePalette {
  const RyzePalette({
    required this.key,
    required this.text,
    required this.ink,
    required this.ink2,
    required this.acc,
    required this.accDeep,
    required this.accLight,
    required this.accTint,
    required this.accInk,
  });

  /// La clé du dictionnaire qui la nomme.
  final String key;

  /// Le quasi-noir du texte courant, teinté de la palette.
  final Color text;

  /// La marque : les surfaces pleines et les bordures.
  final Color ink;

  /// Sa variante claire, pour les dégradés et l'auréole froide du fond.
  final Color ink2;

  /// Le secondaire : ce que Ryze rend.
  final Color acc;
  final Color accDeep;
  final Color accLight;

  /// Le voile du secondaire, sur lequel `accInk` doit rester lisible.
  final Color accTint;

  /// Le secondaire assombri jusqu'à porter du petit texte sur le papier.
  final Color accInk;

  /// L'auréole chaude en haut à droite de chaque écran n'est pas un champ :
  /// c'est le secondaire éclairci. Elle était déclarée à la main, et sur une
  /// palette elle avait pris la teinte de la marque au lieu de celle du
  /// retour — une incohérence qu'une dérivation rend impossible.
}

/// Les cinq, et rien d'autre.
class RyzePalettes {
  RyzePalettes._();

  /// Navy et ambre : l'habit d'origine, celui de la nuit.
  static const RyzePalette nuit = RyzePalette(
    key: 'theme_nuit',
    text: Color(0xFF0B132B),
    ink: Color(0xFF16265C),
    ink2: Color(0xFF2A3F86),
    acc: Color(0xFFF2A93B),
    accDeep: Color(0xFFD98A16),
    accLight: Color(0xFFFFC766),
    accTint: Color(0xFFFDF1DC),
    accInk: Color(0xFF9A5F0C),
  );

  /// Magenta et turquoise. Le rose franc est sur les surfaces, pas seulement
  /// sur la jauge : c'est ce qui fait qu'on le voit.
  static const RyzePalette rose = RyzePalette(
    key: 'theme_rose',
    text: Color(0xFF3A0F26),
    ink: Color(0xFFD6317B),
    ink2: Color(0xFFE85C9B),
    acc: Color(0xFF7FEBE1),
    accDeep: Color(0xFF3FD9CB),
    accLight: Color(0xFFA8F2EB),
    accTint: Color(0xFFE0FAF7),
    accInk: Color(0xFF0F6E67),
  );

  /// Violet et citron vert.
  static const RyzePalette prune = RyzePalette(
    key: 'theme_prune',
    text: Color(0xFF22102E),
    ink: Color(0xFF7B2CBF),
    ink2: Color(0xFF9D5AD6),
    acc: Color(0xFFC3EF4A),
    accDeep: Color(0xFFA5D428),
    accLight: Color(0xFFD9F585),
    accTint: Color(0xFFF2FBDD),
    accInk: Color(0xFF5A7A0C),
  );

  /// Turquoise profond et corail.
  static const RyzePalette ocean = RyzePalette(
    key: 'theme_ocean',
    text: Color(0xFF0A2A2E),
    ink: Color(0xFF0E6B78),
    ink2: Color(0xFF1A93A4),
    acc: Color(0xFFFFA98E),
    accDeep: Color(0xFFFF7A59),
    accLight: Color(0xFFFFC7B5),
    accTint: Color(0xFFFFEDE7),
    accInk: Color(0xFFA83A1C),
  );

  /// Vert forêt et rose vif.
  static const RyzePalette foret = RyzePalette(
    key: 'theme_foret',
    text: Color(0xFF0E2A20),
    ink: Color(0xFF1E5B3E),
    ink2: Color(0xFF2E8259),
    acc: Color(0xFFFF6FA8),
    accDeep: Color(0xFFE84C8C),
    accLight: Color(0xFFFF9DC4),
    accTint: Color(0xFFFFE8F0),
    accInk: Color(0xFFA82C5B),
  );

  static const List<RyzePalette> all = [nuit, rose, prune, ocean, foret];

  /// Celle qui porte cette clé, ou celle d'origine. Une clé inconnue — un
  /// réglage écrit par une version plus récente, ou une palette retirée — ne
  /// doit jamais laisser l'application sans couleurs.
  static RyzePalette byKey(String? key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return nuit;
  }
}
