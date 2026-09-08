import 'package:flutter/material.dart';

/// Les quatre éditions de Ryze.
///
/// Une édition possède son **sol** — le papier, la carte, les gris — et non
/// seulement sa marque. C'est ce qui la fait lire comme une autre application
/// et non comme une option de couleur : Headspace est orange partout, Whoop est
/// noir. Neuf palettes posées sur le même gris avaient été essayées ; elles
/// faisaient neuf manteaux sur le même corps.
///
/// Chaque édition définit :
///
/// * **le sol** — `paper0` `paper` `paper2` `surf` : le fond et ses cartes
/// * **le texte et les gris** — `text` `mute` `mute2` `idle`
/// * **la marque** — `ink` `ink2` : les surfaces pleines et les bordures
/// * **le retour** — `acc` `accDeep` `accLight` `accTint` `accInk` : ce que
///   Ryze rend, la jauge, ses conseils, sa voix
/// * `danger` et `shadow`, qui doivent suivre le sol pour rester lisibles
///
/// **Sur une édition sombre, la marque porte du sombre.** Volt écrit son
/// libellé de bouton en noir sur du volt, pas en blanc. C'est `surf` qui le
/// porte : la carte suit le sol, donc « `surf` sur `ink` » est juste dans les
/// deux sens sans qu'un seul appelant ait à le savoir. Une ombre n'existe pas
/// sur du noir : `shadow` y est du noir pur, et l'élévation se dit par
/// l'échelle des surfaces.
///
/// **Ce qui est vérifié** sur le sol de chaque édition : texte ≥ 7 sur le
/// papier et sur la carte, gris ≥ 4,5, carte sur marque ≥ 4,5 (le libellé d'un
/// bouton), marque sur papier ≥ 3, retour foncé ≥ 4,5 sur le papier et sur son
/// voile, erreur ≥ 4,5. Le retour lui-même est *discret par conception* : il
/// vit sur sa piste et contre la marque, jamais en texte — l'ambre d'origine
/// fait 1,4 sur sa piste, et c'est la référence.
@immutable
class RyzePalette {
  const RyzePalette({
    required this.key,
    required this.dark,
    required this.paper0,
    required this.paper,
    required this.paper2,
    required this.surf,
    required this.text,
    required this.mute,
    required this.mute2,
    required this.idle,
    required this.ink,
    required this.ink2,
    required this.acc,
    required this.accDeep,
    required this.accLight,
    required this.accTint,
    required this.accInk,
    required this.danger,
    required this.shadow,
  });

  /// La clé du dictionnaire qui la nomme.
  final String key;

  /// Vrai quand le sol est sombre : la barre d'état passe en clair.
  final bool dark;

  // ---------------------------------------------------------------- le sol
  final Color paper0;
  final Color paper;
  final Color paper2;
  final Color surf;

  // ------------------------------------------------------ le texte, les gris
  final Color text;
  final Color mute;
  final Color mute2;
  final Color idle;

  // ------------------------------------------------------------- la marque
  final Color ink;
  final Color ink2;

  // -------------------------------------------------------------- le retour
  final Color acc;
  final Color accDeep;
  final Color accLight;
  final Color accTint;
  final Color accInk;

  // ------------------------------------------------ ce qui doit suivre le sol
  final Color danger;
  final Color shadow;
}

/// Les quatre, et rien d'autre.
class RyzePalettes {
  RyzePalettes._();

  /// Navy et ambre sur papier gris : l'identité, le défaut.
  static const RyzePalette nuit = RyzePalette(
    key: 'theme_nuit',
    dark: false,
    paper0: Color(0xFFF8F9FB),
    paper: Color(0xFFF5F6F8),
    paper2: Color(0xFFEEF0F4),
    surf: Color(0xFFFFFFFF),
    text: Color(0xFF0B132B),
    mute: Color(0xFF5F6779),
    mute2: Color(0xFF9AA1B2),
    idle: Color(0xFFD5DAE1),
    ink: Color(0xFF16265C),
    ink2: Color(0xFF2A3F86),
    acc: Color(0xFFF2A93B),
    accDeep: Color(0xFFD98A16),
    accLight: Color(0xFFFFC766),
    accTint: Color(0xFFFDF1DC),
    accInk: Color(0xFF9A5F0C),
    danger: Color(0xFFA62F1C),
    shadow: Color(0xFF0B132B),
  );

  /// Cerise saturée et or sur crème : la vague *cherry cola*. Pas la cerise
  /// sourde d'un coloriste — une vraie, qui se partage.
  static const RyzePalette cerise = RyzePalette(
    key: 'theme_cerise',
    dark: false,
    paper0: Color(0xFFFFFBF2),
    paper: Color(0xFFFFF7E8),
    paper2: Color(0xFFFBEFD8),
    surf: Color(0xFFFFFCF5),
    text: Color(0xFF1F0A10),
    mute: Color(0xFF6B4A52),
    mute2: Color(0xFFA8929A),
    idle: Color(0xFFE6D3B3),
    ink: Color(0xFFD8123F),
    ink2: Color(0xFFE8456A),
    acc: Color(0xFFE5AC00),
    accDeep: Color(0xFFC99500),
    accLight: Color(0xFFF2C94C),
    accTint: Color(0xFFFDF3CF),
    accInk: Color(0xFF7A5A08),
    danger: Color(0xFFA62F1C),
    shadow: Color(0xFF1F0A10),
  );

  /// Volt et orange de sécurité sur noir : le look dur de la salle. La seule
  /// édition sombre, et la seule où la marque porte du sombre.
  static const RyzePalette volt = RyzePalette(
    key: 'theme_volt',
    dark: true,
    paper0: Color(0xFF101115),
    paper: Color(0xFF0C0D10),
    paper2: Color(0xFF131418),
    surf: Color(0xFF17181D),
    text: Color(0xFFF3F3F1),
    mute: Color(0xFFA6A8A3),
    mute2: Color(0xFF62645F),
    idle: Color(0xFF2A2C31),
    ink: Color(0xFFC8FF3D),
    ink2: Color(0xFFA8DD1F),
    acc: Color(0xFFFF6A2B),
    accDeep: Color(0xFFE5541A),
    accLight: Color(0xFFFF9A6B),
    accTint: Color(0xFF2E1A14),
    accInk: Color(0xFFFFB08A),
    danger: Color(0xFFFF6B57),
    shadow: Color(0xFF000000),
  );

  /// Espresso et olive sur os : le registre calme d'Oura et d'Aesop. Ne penche
  /// ni fille ni garçon.
  static const RyzePalette sable = RyzePalette(
    key: 'theme_sable',
    dark: false,
    paper0: Color(0xFFF6F0E4),
    paper: Color(0xFFF2EADB),
    paper2: Color(0xFFE9DFCC),
    surf: Color(0xFFFAF5EB),
    text: Color(0xFF1C1611),
    mute: Color(0xFF6A5F52),
    mute2: Color(0xFFA69A8C),
    idle: Color(0xFFD9CFBE),
    ink: Color(0xFF3D2B1F),
    ink2: Color(0xFF5A4334),
    acc: Color(0xFF8A9A5B),
    accDeep: Color(0xFF6F7E44),
    accLight: Color(0xFFA9B67C),
    accTint: Color(0xFFE6EAD6),
    accInk: Color(0xFF4E5A2E),
    danger: Color(0xFFA62F1C),
    shadow: Color(0xFF1C1611),
  );

  static const List<RyzePalette> all = [nuit, cerise, volt, sable];

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
