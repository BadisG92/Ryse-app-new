import 'package:flutter/material.dart';

import 'ryze_logo.dart';
import 'tokens.dart';

/// The Ryze mark alone, at icon size.
///
/// Wherever the app speaks as Ryze — a generated session, an analysis, the
/// coach's row in a sheet — this is the sign, not a sparkle glyph. Sparkles
/// say "an AI did this"; the mark says "Ryze did this", which is the only
/// claim the app makes. The geometry is the launch logo's own, so the two
/// can never drift apart.
///
/// [size] is the mark's own height. `RyzeLogo.markParts` draws into the full
/// lockup box, where the mark occupies a corner — passing it a box the size
/// of the mark therefore rendered it at half scale, off centre. Here the
/// lockup box is scaled and shifted so the mark's own bounds land exactly on
/// this widget.
class RyzeMark extends StatelessWidget {
  const RyzeMark({super.key, this.size = 20, this.color});

  /// Height of the mark itself.
  final double size;
  /// Nul pour l'encre du theme en vigueur : une valeur par defaut ne peut
  /// plus etre une constante depuis que la palette se choisit.
  final Color? color;

  /// The mark is taller than it is wide; the width follows.
  static double widthFor(double size) => size * RyzeLogo.markBounds.width / RyzeLogo.markBounds.height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widthFor(size), size),
      painter: _MarkPainter(color ?? RyzeColors.ink),
      isComplex: false,
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The scale that maps the mark's own bounds onto this canvas, then the
    // lockup box placed so those bounds start at the origin.
    final k = size.height / RyzeLogo.markBounds.height;
    final box = Rect.fromLTWH(
      -RyzeLogo.markBounds.left * k,
      -RyzeLogo.markBounds.top * k,
      RyzeLogo.lockup.width * k,
      RyzeLogo.lockup.height * k,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final part in RyzeLogo.markParts(box)) {
      canvas.drawPath(part.shape, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
