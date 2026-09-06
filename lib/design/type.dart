import 'package:flutter/material.dart';

import 'tokens.dart';

/// Viewport-relative sizing, mirrors the prototype's `cqw` / `cqh` units.
/// The screens were drawn as fractions of the width, so a 390 pt phone and
/// a 430 pt phone show the same composition.
extension RyzeSizing on BuildContext {
  double vw(double percent) => MediaQuery.sizeOf(this).width * percent / 100;
  double vh(double percent) => MediaQuery.sizeOf(this).height * percent / 100;
}

/// Two faces, both bundled as variable fonts so nothing waits on a network:
/// Archivo for headlines and big numbers, Instrument Sans for everything else.
class RyzeText {
  RyzeText._();

  static TextStyle display(
    BuildContext context,
    double sizeVw, {
    FontWeight weight = FontWeight.w800,
    Color color = RyzeColors.ink,
    double height = 1.04,
    double letterSpacingEm = -0.028,
  }) {
    final size = context.vw(sizeVw);
    return TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', _wght(weight)), const FontVariation('wdth', 100)],
      color: color,
      height: height,
      letterSpacing: size * letterSpacingEm,
    );
  }

  static TextStyle body(
    BuildContext context,
    double sizeVw, {
    FontWeight weight = FontWeight.w400,
    Color color = RyzeColors.ink,
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: 'InstrumentSans',
      fontSize: context.vw(sizeVw),
      fontWeight: weight,
      fontVariations: [FontVariation('wght', _wght(weight)), const FontVariation('wdth', 100)],
      color: color,
      height: height,
    );
  }

  /// A headline shrinks with its length so a long German question never
  /// pushes the instrument off the screen.
  static double headlineVw(String text) => text.length <= 30 ? 7.8 : (text.length <= 46 ? 6.9 : 6.1);

  static double _wght(FontWeight w) => (w.index + 1) * 100.0;
}
