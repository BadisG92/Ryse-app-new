import 'package:flutter/material.dart';

import 'palette.dart';

/// Ryze design system, layer one: the tokens.
///
/// Born in the v2 onboarding and now the reference for the whole app. The rule
/// that makes the palette legible at a glance:
/// - ink (brand navy) is everything the user chooses or presses
/// - amber is everything Ryze gives back: progress, the live value pointer,
///   the pact signature, and the single gold button of the trial
/// - one visual variable, the fill, carries state: light grey is free, a navy
///   outline is planned, a navy fill is done
/// - sport is told apart from food by shape and icon, never by colour
class RyzeColors {
  RyzeColors._();

  /// La palette en vigueur. Lui affecter une autre valeur repeint toute
  /// l'application au prochain rendu : c'est le seul point de bascule, et
  /// c'est pour cela que les 1 100 usages de ces jetons n'ont pas eu a
  /// bouger d'une ligne.
  static RyzePalette _palette = RyzePalettes.nuit;

  static RyzePalette get palette => _palette;
  static set palette(RyzePalette value) => _palette = value;

  // ---------------------------------------------------------------- le sol
  //
  // Le papier suivait tous les themes ; il est maintenant a chaque edition.
  // C'est ce qui fait lire une edition comme une autre application et non
  // comme une option de couleur.

  static Color get paper0 => _palette.paper0;
  static Color get paper => _palette.paper;
  static Color get paper2 => _palette.paper2;
  static Color get surf => _palette.surf;

  /// Vrai quand le sol est sombre : la barre d'etat passe en clair, et la
  /// marque porte du sombre et non du blanc.
  static bool get isDark => _palette.dark;

  // ---------------------------------------------------- ce qui suit le theme

  /// Le quasi-noir du texte courant. Il etait confondu avec la marque, ce qui
  /// obligeait les cinq palettes au meme noir : le texte doit tenir 7:1 sur le
  /// papier, et les surfaces heritaient de cette contrainte.
  static Color get text => _palette.text;

  /// La marque : les surfaces pleines et les bordures. C'est elle qu'on voit
  /// de loin, et elle peut etre franche puisqu'elle ne porte pas de texte —
  /// elle porte du blanc, ce qui demande 4,5:1 et non 7:1.
  static Color get ink => _palette.ink;
  static Color get ink2 => _palette.ink2;

  /// Le gris du petit texte : >= 4,5:1 sur le sol de chaque edition.
  static Color get mute => _palette.mute;

  /// Decoratif seulement (tirets, bordures) : trop clair pour du texte.
  static Color get mute2 => _palette.mute2;
  /// Les traits derivent du texte et non de la marque : un trait est une
  /// separation, pas une couleur d'identite, et il doit rester discret meme
  /// quand la marque est vive.
  static Color get line => _palette.text.withValues(alpha: 0.11);
  static Color get line2 => _palette.text.withValues(alpha: 0.06);

  /// Le remplissage d'une case libre et d'une piste de jauge. Sur un sol
  /// sombre il est un gris sombre : « plus clair que le sol = libre » tient
  /// dans les deux sens.
  static Color get idle => _palette.idle;

  /// Le secondaire : ce que Ryze rend.
  static Color get acc => _palette.acc;
  static Color get accDeep => _palette.accDeep;
  static Color get accLight => _palette.accLight;
  static Color get accTint => _palette.accTint;

  /// Le secondaire assombri jusqu'a porter du petit texte sur le papier.
  static Color get accInk => _palette.accInk;
  static Color get onAcc => _palette.ink;

  /// La couleur des ombres. Le quasi-noir du texte sur un sol clair ; du noir
  /// pur sur un sol sombre.
  static Color get shadow => _palette.shadow;

  /// L'erreur sur un champ. Elle suit le sol : le rouge sombre d'origine ne
  /// fait que 2,7 sur du noir, ou il devient un rouge clair.
  static Color get danger => _palette.danger;

  /// Reserved for confirmation controls ("Valider"); never a state colour.
  static const Color confirm = Color(0xFF10B981);
  static const Color green = Color(0xFF17B26A);

  /// Macro-nutrient dots, the only place a third hue is allowed.
  static const Color protein = Color(0xFF3B82F6);
  static const Color carbs = Color(0xFFF59E0B);
  static const Color fat = Color(0xFFEF4444);

  /// Les deux aureoles du fond : la chaude en haut a droite, la froide en bas
  /// a gauche. Elles sont de la palette et non du decor - un theme qui change
  /// la couleur de l'application doit changer le fond avec, sans quoi l'ambre
  /// resterait seul derriere une interface devenue rose.
  /// L'auréole chaude est le secondaire éclairci : elle suit ce que Ryze
  /// rend, jamais la marque.
  static Color get glowWarm => _palette.accLight;
  static Color get glowCool => _palette.ink2;

  /// Le degrade du fond, du haut clair au bas un peu plus dense.
  static LinearGradient get ground => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [paper0, paper, paper2],
        stops: const [0, 0.5, 1],
      );
}

/// Corner radii. Cards and sheets are large, controls medium, tiles small.
class RyzeRadius {
  RyzeRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

/// Spacing scale, in logical pixels.
class RyzeSpace {
  RyzeSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Three shadow levels, instead of one alpha per widget. `soft` under a
/// resting card, `card` under a card that floats on paper, `lift` under the
/// one element that must come off the page (the selected plan, the CTA).
class RyzeShadow {
  RyzeShadow._();

  // L'ombre est celle de l'edition, pas la marque : une ombre volt sous une
  // carte noire serait une lueur. Sur Volt, `shadow` est du noir pur.
  static List<BoxShadow> get soft => [BoxShadow(color: RyzeColors.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))];
  static List<BoxShadow> get card => [BoxShadow(color: RyzeColors.shadow.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))];
  static List<BoxShadow> get lift => [BoxShadow(color: RyzeColors.shadow.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10))];
}

class RyzeAssets {
  RyzeAssets._();

  /// The coaches cropped on the bust: a full-body figure shrinks to a speck in
  /// a 40 pt circle. The full-body files stay for large illustrations.
  static const String sportAvatar = 'assets/images/coach_ryze_sport_head.png';
  static const String nutriAvatar = 'assets/images/coach_ryze_nutrition_head.png';
  static const String sportFigure = 'assets/images/coach_ryze_sport_avatar.png';
  static const String nutriFigure = 'assets/images/coach_ryze_nutrition_avatar.png';
  static const String scene = 'assets/images/welcome_background.png';
}
