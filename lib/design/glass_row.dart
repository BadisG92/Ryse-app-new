import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// The day's water, as glasses you fill and empty with a tap.
///
/// One glass is 250 ml, so the goal decides how many are drawn. Tapping the
/// next empty one adds a glass; tapping a full one brings the level back to
/// just under it, which is the only way the app has ever offered to correct a
/// mistake. A long press on the dashed glass asks for another amount.
class GlassRow extends StatelessWidget {
  const GlassRow({
    super.key,
    required this.litres,
    required this.goalLitres,
    required this.shown,
    required this.onSet,
    this.onOther,
  });

  final double litres;
  final double goalLitres;

  /// False before the entry, so the glasses fill from empty.
  final bool shown;

  /// Asked for a new level, in glasses. Zero empties the day. Null makes the
  /// row a reading only, which is how a past day is shown.
  final ValueChanged<int>? onSet;

  /// Long press on the dashed glass.
  final VoidCallback? onOther;

  static const double glassLitres = 0.25;

  @override
  Widget build(BuildContext context) {
    final goal = goalLitres > 0 ? (goalLitres / glassLitres).round().clamp(4, 12) : 8;
    final full = shown ? (litres / glassLitres).floor().clamp(0, goal) : 0;

    return Row(
      children: [
        for (var i = 0; i < goal; i++) ...[
          if (i > 0) SizedBox(width: context.vw(1.8)),
          Expanded(
            child: _Glass(
              filled: i < full,
              next: i == full,
              // Chaque verre part un cran après celui de gauche : la rangée se
              // remplit de gauche à droite au lieu de basculer d'un coup.
              delay: Duration(milliseconds: 40 * i),
              onTap: () {
                final set = onSet;
                if (set == null) return;
                if (i < full) {
                  RyzeFeedback.removed();
                  set(i);
                } else {
                  final level = i + 1;
                  if (level >= goal) {
                    RyzeFeedback.success();
                  } else {
                    RyzeFeedback.tap();
                  }
                  set(level);
                }
              },
              onLongPress: i == full ? onOther : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _Glass extends StatefulWidget {
  const _Glass({required this.filled, required this.next, required this.onTap, required this.delay, this.onLongPress});

  final bool filled;
  final bool next;
  final Duration delay;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_Glass> createState() => _GlassState();
}

class _GlassState extends State<_Glass> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final height = context.vw(12.3);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: RyzeDurations.tap,
          curve: RyzeCurves.spring,
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: widget.filled ? 1 : 0),
              // Le remplissage déborde légèrement puis se pose : c'est ce
              // dépassement qui fait lire un liquide plutôt qu'une barre.
              duration: RyzeDurations.fill + widget.delay,
              curve: Interval(
                widget.delay.inMilliseconds / (RyzeDurations.fill + widget.delay).inMilliseconds,
                1,
                curve: RyzeCurves.spring,
              ),
              builder: (context, level, _) => CustomPaint(
                painter: _GlassPainter(
                  level: level.clamp(0.0, 1.06),
                  edge: widget.filled ? RyzeColors.ink : (widget.next ? RyzeColors.mute2 : RyzeColors.line),
                ),
                child: widget.next
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: context.vw(1.2)),
                          child: Icon(Icons.add_rounded, size: context.vw(4.4), color: RyzeColors.mute2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un verre, dessiné : un tronc de cône, un pied arrondi, et l'eau qui monte
/// dedans avec sa surface bombée.
///
/// Vectoriel plutôt qu'une image : la silhouette suit la largeur que la
/// rangée lui donne (quatre verres ou douze), elle se teinte des jetons du
/// système, et elle reste nette à toutes les densités. Un PNG aurait fallu en
/// trois tailles, en deux teintes, et l'eau n'aurait pas pu monter dedans.
class _GlassPainter extends CustomPainter {
  const _GlassPainter({required this.level, required this.edge});

  /// De 0 à 1 — un peu au-delà pendant le rebond.
  final double level;
  final Color edge;

  /// Le pied est plus étroit que le buvant : c'est ce qui fait un verre
  /// plutôt qu'un rectangle.
  static const double _taper = 0.14;

  /// Le contour, du buvant droit au buvant gauche : deux flancs et un fond,
  /// et rien en haut. Le trait faisait le tour complet, ce qui dessinait un
  /// carré ; un verre est ouvert.
  ///
  /// Le chemin reste ouvert. Rempli ou utilisé en découpe, Flutter le referme
  /// par une droite entre ses deux extrémités — c'est justement le buvant, et
  /// c'est ce qu'on veut pour l'eau et le reflet. Tracé, il s'arrête.
  Path _silhouette(Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * _taper / 2;
    final foot = math.min(w * 0.30, h * 0.18);
    final lip = math.min(w * 0.10, 3.0);

    return Path()
      ..moveTo(w - lip, 0)
      ..quadraticBezierTo(w, 0, w - inset * 0.35, h * 0.16)
      ..lineTo(w - inset, h - foot)
      ..quadraticBezierTo(w - inset, h, w - inset - foot * 0.55, h)
      ..lineTo(inset + foot * 0.55, h)
      ..quadraticBezierTo(inset, h, inset, h - foot)
      ..lineTo(inset * 0.35, h * 0.16)
      ..quadraticBezierTo(0, 0, lip, 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glass = _silhouette(size);

    // Le verre lui-même.
    canvas.drawPath(glass, Paint()..color = RyzeColors.surf);

    if (level > 0.001) {
      canvas.save();
      canvas.clipPath(glass);

      // La surface de l'eau, bombée : une courbe, pas un trait. Le verre
      // n'est jamais rempli à ras bord — 6 % d'air en haut.
      final top = size.height * (1 - level * 0.94);
      final water = Path()
        ..moveTo(-2, top + size.height * 0.03)
        ..quadraticBezierTo(size.width / 2, top - size.height * 0.035, size.width + 2, top + size.height * 0.03)
        ..lineTo(size.width + 2, size.height + 2)
        ..lineTo(-2, size.height + 2)
        ..close();
      canvas.drawPath(water, Paint()..color = RyzeColors.ink);
      canvas.restore();
    }

    // Le reflet : une bande claire sur le flanc gauche, qui traverse l'eau et
    // le vide de la même façon. C'est elle qui dit « verre ».
    canvas.save();
    canvas.clipPath(glass);
    final shine = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.17, size.height * 0.14, math.max(size.width * 0.09, 1.5), size.height * 0.5),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(shine, Paint()..color = RyzeColors.surf.withValues(alpha: 0.55));
    canvas.restore();

    // Le trait du verre, par-dessus tout. Les deux bouts sont arrondis :
    // ce sont les bords du buvant, ils doivent finir proprement.
    canvas.drawPath(
      glass,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.level != level || old.edge != edge;
}
