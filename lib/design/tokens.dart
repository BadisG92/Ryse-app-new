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

  // ------------------------------------------------- ce qui ne bouge jamais

  static const Color paper = Color(0xFFF5F6F8);
  static const Color paper2 = Color(0xFFEEF0F4);
  static const Color surf = Color(0xFFFFFFFF);

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

  /// 5.2:1 on paper, above AA for the small print it carries.
  static const Color mute = Color(0xFF5F6779);

  /// Decorative only (dashes, borders): too light for text.
  static const Color mute2 = Color(0xFF9AA1B2);
  /// Les traits derivent du texte et non de la marque : un trait est une
  /// separation, pas une couleur d'identite, et il doit rester discret meme
  /// quand la marque est vive.
  static Color get line => _palette.text.withValues(alpha: 0.11);
  static Color get line2 => _palette.text.withValues(alpha: 0.06);

  /// The idle fill of a free slot and of a dashed placeholder.
  static const Color idle = Color(0xFFD5DAE1);

  /// Le secondaire : ce que Ryze rend.
  static Color get acc => _palette.acc;
  static Color get accDeep => _palette.accDeep;
  static Color get accLight => _palette.accLight;
  static Color get accTint => _palette.accTint;

  /// Le secondaire assombri jusqu'a porter du petit texte sur le papier.
  static Color get accInk => _palette.accInk;
  static Color get onAcc => _palette.ink;

  /// Errors on a field. Dark enough to read on paper; never used for state.
  static const Color danger = Color(0xFFA62F1C);

  /// Reserved for confirmation controls ("Valider"); never a state colour.
  static const Color confirm = Color(0xFF10B981);
  static const Color green = Color(0xFF17B26A);

  /// Macro-nutrient dots, the only place a third hue is allowed.
  static const Color protein = Color(0xFF3B82F6);
  static const Color carbs = Color(0xFFF59E0B);
  static const Color fat = Color(0xFFEF4444);

  /// Le blanc a peine teinte du haut du fond.
  static const Color paper0 = Color(0xFFF8F9FB);

  /// Les deux aureoles du fond : la chaude en haut a droite, la froide en bas
  /// a gauche. Elles sont de la palette et non du decor - un theme qui change
  /// la couleur de l'application doit changer le fond avec, sans quoi l'ambre
  /// resterait seul derriere une interface devenue rose.
  /// L'auréole chaude est le secondaire éclairci : elle suit ce que Ryze
  /// rend, jamais la marque.
  static Color get glowWarm => _palette.accLight;
  static Color get glowCool => _palette.ink2;

  /// Warm light of the gym scene, top right of every screen.
  static const LinearGradient ground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [paper0, paper, paper2],
    stops: [0, 0.5, 1],
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

  static List<BoxShadow> get soft => [BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))];
  static List<BoxShadow> get card => [BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))];
  static List<BoxShadow> get lift => [BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10))];
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
