import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';

/// Les couleurs de la flamme de glace.
///
/// Une exception assumée à « l'ambre est ce que Ryze rend » : le Winter Arc a
/// sa flamme à lui, froide, et elle ne sert que pour lui.
class ArcIce {
  ArcIce._();

  static const Color outerTop = Color(0xFF3FA8FF);
  static const Color outerBottom = Color(0xFF1B3FB8);
  static const Color midTop = Color(0xFF9FE6FF);
  static const Color midBottom = Color(0xFF38A0FF);
  static const Color coreTop = Color(0xFFFFFFFF);
  static const Color coreBottom = Color(0xFFE4F8FF);

  /// Les étincelles : un cyan qui se voit sur le papier clair comme sur la
  /// nuit, un point blanc au centre, un halo autour.
  static const Color spark = Color(0xFF3FB4FF);

  /// Le fond et le texte de la pastille de série pendant la saison.
  static Color get pill => RyzeColors.isDark ? outerTop.withValues(alpha: 0.18) : const Color(0xFFE3F3FF);
  static Color get pillInk => RyzeColors.isDark ? midTop : outerBottom;
}

/// La flamme du Winter Arc : une flamme de glace qui danse.
///
/// Elle se penche de gauche à droite depuis sa base, ses trois couches l'une
/// après l'autre, et de petites étincelles s'en échappent vers le haut. Dessinée
/// plutôt qu'importée pour pouvoir bouger. Immobile quand le téléphone demande
/// de réduire les animations.
class WinterFlame extends StatefulWidget {
  const WinterFlame({super.key, required this.size, this.sparks, this.animate = true});

  final double size;

  /// Les étincelles ; par défaut à partir de 24 points, en dessous elles ne
  /// seraient qu'un grain.
  final bool? sparks;

  final bool animate;

  @override
  State<WinterFlame> createState() => _WinterFlameState();
}

class _WinterFlameState extends State<WinterFlame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  bool _still(BuildContext context) => !widget.animate || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = _still(context);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: WinterFlamePainter(
            _c,
            // Immobile, une étincelle figée en l'air ne veut rien dire.
            sparks: !still && (widget.sparks ?? widget.size >= 24),
          ),
        ),
      ),
    );
  }
}

/// Le dessin, sur une grille de 24 comme les icônes de l'app.
class WinterFlamePainter extends CustomPainter {
  WinterFlamePainter(this.time, {required this.sparks}) : super(repaint: time);

  final Animation<double> time;
  final bool sparks;

  static const double _tau = math.pi * 2;

  /// Une onde qui boucle sur la durée de l'animation : des fréquences
  /// entières, pour que la fin retombe exactement sur le début.
  static double _wave(double t, int freq, double phase) => math.sin(_tau * (t * freq + phase));

  /// De combien la flamme penche, en fraction de sa hauteur.
  static double _lean(double t, double delay) => 0.075 * _wave(t, 1, -delay) + 0.02 * _wave(t, 2, 0.3 - delay);

  /// La silhouette, dont la pointe et la lèche frémissent un peu.
  ///
  /// La base ne bouge jamais : une flamme tient à ce qui la nourrit.
  static Path flame(Offset tip, Offset lick) {
    final p = Path()..moveTo(12, 22);
    p.cubicTo(7.9, 22, 5, 19, 5, 15.3);
    p.cubicTo(5, 12.2, 6.7 + lick.dx * 0.4, 10.2 + lick.dy * 0.4, 8.5 + lick.dx, 8.1 + lick.dy);
    p.cubicTo(8.9 + lick.dx * 0.6, 9.7 + lick.dy * 0.6, 9.7, 10.8, 10.8, 11.3);
    p.cubicTo(10.2, 7.9, 11.5 + tip.dx * 0.6, 4.7 + tip.dy * 0.6, 13.7 + tip.dx, 2.2 + tip.dy);
    p.cubicTo(14.2 + tip.dx * 0.7, 4.6 + tip.dy * 0.6, 15.6 + tip.dx * 0.3, 6.4, 17.1, 8.1);
    p.cubicTo(18.7, 9.9, 20, 11.9, 20, 15.3);
    p.cubicTo(20, 19, 16.1, 22, 12, 22);
    p.close();
    return p;
  }

  /// Se pencher depuis la base : un cisaillement, le pied fixe, la pointe
  /// qui part.
  static void _leanFrom(Canvas canvas, double lean) {
    canvas.translate(12, 22);
    canvas.skew(-lean, 0);
    canvas.translate(-12, -22);
  }

  void _layer(
    Canvas canvas,
    double t, {
    required double scale,
    required Offset anchor,
    required double delay,
    required Color top,
    required Color bottom,
    bool gloss = false,
  }) {
    final tip = Offset(0.2 * _wave(t, 3, delay), -0.3 * _wave(t, 2, delay + 0.1));
    final lick = Offset(-0.25 * _wave(t, 2, delay + 0.35), 0.3 * _wave(t, 1, delay + 0.6));
    canvas.save();
    // Chaque couche se penche un peu après la précédente, et un peu plus :
    // c'est ce retard qui fait danser.
    _leanFrom(canvas, _lean(t, delay) * (1 + delay * 0.6));
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(scale);
    canvas.translate(-anchor.dx, -anchor.dy);
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])
          .createShader(const Rect.fromLTRB(5, 2, 20, 22));
    canvas.drawPath(flame(tip, lick), paint);
    if (gloss) {
      // Le reflet de la glace.
      canvas.drawPath(
        Path()
          ..moveTo(7.4, 12.6)
          ..cubicTo(6.5, 13.9, 6.1, 15.2, 6.3, 16.6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  /// Les étincelles : départ près de la pointe, montée en ondulant, puis
  /// elles pâlissent et rapetissent. Chacune a son départ et sa vitesse ; les
  /// vitesses sont entières, la boucle ne se voit pas.
  static const List<({double x, int speed, double phase, double size})> _sparks = [
    (x: 12.9, speed: 2, phase: 0.0, size: 0.62),
    (x: 10.6, speed: 1, phase: 0.35, size: 0.5),
    (x: 14.6, speed: 2, phase: 0.55, size: 0.45),
    (x: 11.9, speed: 3, phase: 0.2, size: 0.4),
    (x: 13.8, speed: 1, phase: 0.8, size: 0.55),
  ];

  void _drawSparks(Canvas canvas, double t) {
    for (final s in _sparks) {
      final u = (t * s.speed + s.phase) % 1.0;
      // De la pointe jusqu'au haut du cadre.
      final y = 5.6 - u * 8.4;
      // Elles suivent la flamme quand elle penche, puis s'en détachent.
      final x = s.x + _lean(t, 0) * (22 - y) * (1 - u) + 0.7 * math.sin(_tau * (u * 1.5 + s.phase));
      final fade = math.sin(math.pi * u);
      final r = s.size * (1 - 0.55 * u);
      canvas.drawCircle(Offset(x, y), r * 1.9, Paint()..color = ArcIce.spark.withValues(alpha: 0.22 * fade));
      canvas.drawCircle(Offset(x, y), r, Paint()..color = ArcIce.spark.withValues(alpha: 0.95 * fade));
      canvas.drawCircle(Offset(x, y), r * 0.45, Paint()..color = Colors.white.withValues(alpha: fade));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    if (sparks) {
      // Un peu de ciel au-dessus de la flamme, pour que les étincelles
      // montent sans sortir du cadre.
      canvas.translate(12, 23);
      canvas.scale(0.86);
      canvas.translate(-12, -23);
    }

    // Le tout respire à peine depuis la base.
    final breathe = 1 + 0.02 * _wave(t, 2, 0.15);
    canvas.save();
    canvas.translate(12, 22);
    canvas.scale(1, breathe);
    canvas.translate(-12, -22);
    _layer(canvas, t, scale: 1, anchor: const Offset(12, 22), delay: 0, top: ArcIce.outerTop, bottom: ArcIce.outerBottom, gloss: true);
    _layer(canvas, t, scale: 0.66, anchor: const Offset(12.3, 21.6), delay: 0.08, top: ArcIce.midTop, bottom: ArcIce.midBottom);
    _layer(canvas, t, scale: 0.36, anchor: const Offset(12.3, 21.2), delay: 0.16, top: ArcIce.coreTop, bottom: ArcIce.coreBottom);
    canvas.restore();

    if (sparks) _drawSparks(canvas, t);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WinterFlamePainter old) => old.sparks != sparks;
}
