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
class RyzeMark extends StatelessWidget {
  const RyzeMark({super.key, this.size = 16, this.color = RyzeColors.ink});

  /// Height of the mark; the width follows the brand's proportions.
  final double size;
  final Color color;

  static double widthFor(double size) => size * RyzeLogo.markBounds.width / RyzeLogo.markBounds.height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widthFor(size), size),
      painter: _MarkPainter(color),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final part in RyzeLogo.markParts(Offset.zero & size)) {
      canvas.drawPath(part.shape, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
