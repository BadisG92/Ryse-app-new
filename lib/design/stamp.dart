import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'feedback.dart';
import 'tokens.dart';

/// Le tampon du coach.
///
/// Un ou deux mots en capitales dans un double cadre, posés de travers, à
/// l'encre rouge des copies rendues. C'est le geste de l'application : il
/// tombe sur le dossier, demain sur le bilan du dimanche et sur la journée
/// validée du Winter Arc. Le mot change, le tampon jamais, c'est ce qui le
/// fait reconnaître d'un post à l'autre.
///
/// L'encre n'est pas parfaite exprès : les bords ondulent légèrement, il
/// manque de l'encre par endroits, et la pression faiblit vers un coin. Un
/// tampon net serait un badge ; celui-ci a été posé par quelqu'un.
class RyzeStamp extends StatelessWidget {
  const RyzeStamp({
    super.key,
    required this.word,
    this.height = 44,
    this.angle = -9,
    this.seed = 7,
    this.color,
  });

  /// Le mot, tel qu'il sera écrit (passé en capitales).
  final String word;

  /// La hauteur d'une ligne de cadre ; tout le reste en découle. Un mot qui
  /// doit se couper en deux lignes grandit d'autant.
  final double height;

  /// L'inclinaison, en degrés. Négatif penche vers la gauche, comme une main
  /// droite qui tamponne.
  final double angle;

  /// La graine des manques d'encre : le même tampon garde les mêmes trous
  /// d'un rendu à l'autre, une image partagée doit être stable.
  final int seed;

  final Color? color;

  /// Au-delà, le mot passe sur deux lignes à l'espace le plus central.
  static const int singleLineMax = 11;

  /// Les lignes du mot : une, ou deux quand il est long et qu'il a un espace.
  static List<String> linesOf(String word) {
    final w = word.trim().toUpperCase();
    if (w.length <= singleLineMax || !w.contains(' ')) return [w];
    final spaces = <int>[];
    for (var i = 0; i < w.length; i++) {
      if (w[i] == ' ') spaces.add(i);
    }
    final middle = w.length / 2;
    spaces.sort((a, b) => (a - middle).abs().compareTo((b - middle).abs()));
    final cut = spaces.first;
    return [w.substring(0, cut), w.substring(cut + 1)];
  }

  static TextStyle style(double fontSize, Color color) => TextStyle(
        fontFamily: 'Archivo',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800), FontVariation('wdth', 78)],
        letterSpacing: fontSize * 0.03,
        height: 0.98,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    final ink = (color ?? RyzeColors.stamp).withValues(alpha: 0.92);
    final layout = _StampLayout(word: word, height: height, color: ink);
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: CustomPaint(
        size: layout.size,
        painter: _StampPainter(layout, seed: seed),
        isComplex: true,
      ),
    );
  }
}

/// Les mesures d'un tampon : le texte posé, les épaisseurs, la taille.
class _StampLayout {
  _StampLayout({required String word, required this.height, required this.color}) {
    final lines = RyzeStamp.linesOf(word);
    fontSize = height * 0.52;
    outer = height * 0.08;
    gap = height * 0.06;
    inner = height * 0.035;
    padH = height * 0.30;
    padV = height * 0.17;

    text = TextPainter(
      text: TextSpan(text: lines.join('\n'), style: RyzeStamp.style(fontSize, color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout();

    final frame = outer + gap + inner;
    size = Size(
      text.width + 2 * (padH + frame),
      text.height + 2 * (padV + frame),
    );
  }

  final double height;
  final Color color;
  late final double fontSize, outer, gap, inner, padH, padV;
  late final TextPainter text;
  late final Size size;
}

class _StampPainter extends CustomPainter {
  const _StampPainter(this.l, {required this.seed});

  final _StampLayout l;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Tout le tampon se dessine dans un calque, pour que les manques d'encre
    // puissent le trouer sans toucher à ce qu'il y a dessous.
    canvas.saveLayer(rect.inflate(4), Paint());

    final stroke = Paint()
      ..color = l.color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(l.outer / 2), Radius.circular(l.height * 0.22)),
      stroke..strokeWidth = l.outer,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(l.outer + l.gap + l.inner / 2),
        Radius.circular(l.height * 0.15),
      ),
      stroke..strokeWidth = l.inner,
    );

    l.text.paint(
      canvas,
      Offset((size.width - l.text.width) / 2, (size.height - l.text.height) / 2),
    );

    // Les manques d'encre : de petites taches qui retirent de la matière.
    // Pseudo-aléatoires sur une graine fixe, donc identiques à chaque rendu.
    final rnd = math.Random(seed);
    final k = l.height / 44;
    final gaps = Paint()..blendMode = BlendMode.dstOut;
    final n = (size.width * size.height / (120 * k * k)).round().clamp(40, 320);
    for (var i = 0; i < n; i++) {
      final cx = rnd.nextDouble() * size.width;
      final cy = rnd.nextDouble() * size.height;
      final r = (0.35 + rnd.nextDouble() * 1.3) * k;
      gaps.color = Colors.black.withValues(alpha: 0.3 + rnd.nextDouble() * 0.7);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.4, height: r * 1.1), gaps);
      canvas.restore();
    }

    // La pression faiblit vers le bas à droite : l'encre y est plus claire.
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [Colors.white, Colors.white, Colors.white.withValues(alpha: 0.52)],
          const [0, 0.45, 1],
        ),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StampPainter old) =>
      old.seed != seed ||
      old.l.size != l.size ||
      old.l.color != l.color ||
      old.l.text.text != l.text.text;
}

/// Le tampon qui tombe.
///
/// Il arrive de face, trop grand et flou, s'écrase à sa taille avec un reste
/// de rotation, rebondit à peine, et ne bouge plus. Le téléphone vibre à
/// l'impact : c'est la coïncidence des deux qui fait le geste, pas
/// l'animation seule. Trois dixièmes de seconde, puis une image fixe.
///
/// [play] faux montre le tampon posé : un dossier relu dans l'historique ne
/// retombe pas.
class RyzeStampSlam extends StatefulWidget {
  const RyzeStampSlam({
    super.key,
    required this.play,
    required this.child,
    this.delay = Duration.zero,
    this.onImpact,
    this.restAngle = -9,
  });

  final bool play;
  final Widget child;

  /// Le temps avant la chute, pour laisser la carte arriver d'abord.
  final Duration delay;

  /// Au moment exact où il touche : la carte peut encaisser le choc.
  final VoidCallback? onImpact;

  /// L'inclinaison finale, la même que celle du [RyzeStamp] enfant, pour que
  /// le surplus de rotation de la chute s'y ajoute et s'y résorbe.
  final double restAngle;

  /// La part du mouvement avant l'impact.
  static const double impactAt = 0.62;

  @override
  State<RyzeStampSlam> createState() => _RyzeStampSlamState();
}

class _RyzeStampSlamState extends State<RyzeStampSlam> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  bool _hit = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    if (!widget.play) {
      _c.value = 1;
      _hit = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.play) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
      _hit = true;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward(from: 0);
    });
  }

  void _onTick() {
    if (!_hit && _c.value >= RyzeStampSlam.impactAt) {
      _hit = true;
      RyzeFeedback.failure(); // un seul coup lourd, celui du tampon sur la table
      widget.onImpact?.call();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        if (t >= 1) return child!;
        if (t == 0) return Opacity(opacity: 0, child: child);

        double scale, extraAngle, opacity, blur;
        if (t < RyzeStampSlam.impactAt) {
          final p = Curves.easeIn.transform(t / RyzeStampSlam.impactAt);
          scale = ui.lerpDouble(2.1, 0.95, p)!;
          extraAngle = ui.lerpDouble(-8, 0, p)!;
          opacity = (p * 1.6).clamp(0, 1);
          blur = ui.lerpDouble(7, 0, p)!;
        } else if (t < 0.84) {
          final p = (t - RyzeStampSlam.impactAt) / (0.84 - RyzeStampSlam.impactAt);
          scale = ui.lerpDouble(0.95, 1.03, Curves.easeOut.transform(p))!;
          extraAngle = 0;
          opacity = 1;
          blur = 0;
        } else {
          final p = (t - 0.84) / 0.16;
          scale = ui.lerpDouble(1.03, 1.0, Curves.easeOut.transform(p))!;
          extraAngle = 0;
          opacity = 1;
          blur = 0;
        }

        Widget out = Transform.rotate(
          angle: extraAngle * math.pi / 180,
          child: Transform.scale(scale: scale, child: child),
        );
        if (blur > 0.2) {
          out = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: out);
        }
        return Opacity(opacity: opacity, child: out);
      },
    );
  }
}
