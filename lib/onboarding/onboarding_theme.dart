import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens of the v2 onboarding ("studio" direction).
///
/// Rule of the system:
/// - ink (brand navy) = everything the user chooses or presses
/// - acc (amber) = everything Ryze gives back: progress, live value pointers,
///   the pact signature and the single gold trial button
class OnbColors {
  OnbColors._();

  static const Color paper = Color(0xFFF5F6F8);
  static const Color paper2 = Color(0xFFEEF0F4);
  static const Color surf = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0B132B);
  static const Color ink2 = Color(0xFF1B2A5B);
  static const Color mute = Color(0xFF6B7385);
  static const Color mute2 = Color(0xFF9AA1B2);
  static const Color line = Color(0x1A0B132B);
  static const Color line2 = Color(0x0F0B132B);

  static const Color acc = Color(0xFFF2A93B);
  static const Color accDeep = Color(0xFFD98A16);
  static const Color accLight = Color(0xFFFFC766);
  static const Color accTint = Color(0xFFFDF1DC);
  static const Color accInk = Color(0xFFA8690F);
  static const Color onAcc = ink;

  static const Color green = Color(0xFF17B26A);

  /// Warm light of the gym scene, top right of every screen.
  static const LinearGradient ground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F9FB), paper, paper2],
    stops: [0, 0.5, 1],
  );
}

class OnbCurves {
  OnbCurves._();

  static const Curve spring = Cubic(0.22, 1.12, 0.3, 1.02);
  static const Curve out = Cubic(0.2, 0.7, 0.2, 1);
  static const Curve snap = Cubic(0.7, 0, 0.2, 1);
}

/// Viewport-relative sizing, mirrors the prototype's `cqw` / `cqh` units.
extension OnbSizing on BuildContext {
  double vw(double percent) => MediaQuery.sizeOf(this).width * percent / 100;
  double vh(double percent) => MediaQuery.sizeOf(this).height * percent / 100;
}

class OnbText {
  OnbText._();

  /// Archivo for headlines and big numbers.
  static TextStyle display(
    BuildContext context,
    double sizeVw, {
    FontWeight weight = FontWeight.w800,
    Color color = OnbColors.ink,
    double height = 1.04,
    double letterSpacingEm = -0.028,
  }) {
    final size = context.vw(sizeVw);
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * letterSpacingEm,
    );
  }

  /// Instrument Sans for everything else.
  static TextStyle body(
    BuildContext context,
    double sizeVw, {
    FontWeight weight = FontWeight.w400,
    Color color = OnbColors.ink,
    double height = 1.4,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: context.vw(sizeVw),
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

class OnbAssets {
  OnbAssets._();

  static const String sportAvatar = 'assets/images/coach_ryze_sport_avatar.png';
  static const String nutriAvatar = 'assets/images/coach_ryze_nutrition_avatar.png';
  static const String scene = 'assets/images/welcome_background.png';
}
