import 'package:flutter/material.dart';

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

  static const Color paper = Color(0xFFF5F6F8);
  static const Color paper2 = Color(0xFFEEF0F4);
  static const Color surf = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0B132B);
  static const Color ink2 = Color(0xFF1B2A5B);

  /// 5.2:1 on paper, above AA for the small print it carries.
  static const Color mute = Color(0xFF5F6779);

  /// Decorative only (dashes, borders): too light for text.
  static const Color mute2 = Color(0xFF9AA1B2);
  static const Color line = Color(0x1A0B132B);
  static const Color line2 = Color(0x0F0B132B);

  /// The idle fill of a free slot and of a dashed placeholder.
  static const Color idle = Color(0xFFD5DAE1);

  static const Color acc = Color(0xFFF2A93B);
  static const Color accDeep = Color(0xFFD98A16);
  static const Color accLight = Color(0xFFFFC766);
  static const Color accTint = Color(0xFFFDF1DC);

  /// Amber dark enough to carry text on paper (4.8:1).
  static const Color accInk = Color(0xFF9A5F0C);
  static const Color onAcc = ink;

  /// Reserved for confirmation controls ("Valider"); never a state colour.
  static const Color confirm = Color(0xFF10B981);
  static const Color green = Color(0xFF17B26A);

  /// Macro-nutrient dots, the only place a third hue is allowed.
  static const Color protein = Color(0xFF3B82F6);
  static const Color carbs = Color(0xFFF59E0B);
  static const Color fat = Color(0xFFEF4444);

  /// Warm light of the gym scene, top right of every screen.
  static const LinearGradient ground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FB), paper, paper2],
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
