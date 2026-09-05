import 'package:flutter/material.dart';

import '../onboarding_theme.dart';

/// Weight projection. The reveal is one orchestrated moment: the grid appears,
/// the dashed line of "continuing as before" runs across, then the amber curve
/// draws itself under a travelling head and lands on the target.
class ProjectionChart extends StatefulWidget {
  const ProjectionChart({
    super.key,
    required this.startLabel,
    required this.startValue,
    required this.endLabel,
    required this.endValue,
    required this.ghostLabel,
    required this.losing,
  });

  final String startLabel;
  final String startValue;
  final String endLabel;
  final String endValue;
  final String ghostLabel;

  /// True when the target is below today's weight. On screen, up is always
  /// more weight, so the curve falls when losing and rises when gaining.
  final bool losing;

  @override
  State<ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<ProjectionChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  late final Animation<double> _grid = CurvedAnimation(parent: _c, curve: const Interval(0, 0.14, curve: OnbCurves.out));
  late final Animation<double> _ghost = CurvedAnimation(parent: _c, curve: const Interval(0.08, 0.5, curve: OnbCurves.out));
  late final Animation<double> _draw = CurvedAnimation(parent: _c, curve: const Interval(0.22, 0.88, curve: OnbCurves.out));
  late final Animation<double> _end = CurvedAnimation(parent: _c, curve: const Interval(0.84, 1, curve: Cubic(0.2, 1.4, 0.3, 1)));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelH = context.vw(9);
    return AspectRatio(
      aspectRatio: 320 / 165,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geo = _Geo(Size(constraints.maxWidth, constraints.maxHeight), widget.losing);
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final endIn = _end.value.clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _ProjectionPainter(geo: geo, grid: _grid.value, ghost: _ghost.value, draw: _draw.value, endScale: endIn),
                      ),
                    ),
                  ),
                  // today, above the starting point
                  Positioned(
                    left: context.vw(1),
                    top: (geo.y0 - labelH - context.vw(2)).clamp(0.0, geo.size.height),
                    child: _Label(title: widget.startLabel, value: widget.startValue),
                  ),
                  // "continuing as before", at the end of the line it names
                  Positioned(
                    right: 0,
                    top: (widget.losing ? geo.ghostY1 - context.vw(5) : geo.ghostY1 + context.vw(1.6)).clamp(0.0, geo.size.height),
                    child: Opacity(
                      opacity: (_ghost.value * 1.4 - 0.4).clamp(0.0, 1.0),
                      child: Text(widget.ghostLabel, style: OnbText.body(context, 2.9, weight: FontWeight.w500, color: OnbColors.mute)),
                    ),
                  ),
                  // the target, on the side the curve actually lands
                  Positioned(
                    right: 0,
                    top: (widget.losing ? geo.y1 - labelH - context.vw(2.6) : geo.y1 + context.vw(2.6)).clamp(0.0, geo.size.height),
                    child: Opacity(
                      opacity: endIn,
                      child: Transform.translate(
                        offset: Offset(0, (1 - endIn) * 8),
                        child: _Label(title: widget.endLabel, value: widget.endValue, accent: true, alignEnd: true),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Where everything sits. The start point keeps a margin inside the band so the
/// flat line has somewhere to drift, instead of being pinned to the edge.
class _Geo {
  _Geo(this.size, this.losing);

  final Size size;
  final bool losing;

  double get x0 => size.width * 0.07;
  double get x1 => size.width * 0.93;
  double get yTop => size.height * 0.2;
  double get yBot => size.height * 0.76;
  double get band => yBot - yTop;

  double get y0 => losing ? yTop + band * 0.16 : yBot - band * 0.16;
  double get y1 => losing ? yBot : yTop;
  double get ghostY1 => losing ? yTop : yBot;
}

class _Label extends StatelessWidget {
  const _Label({required this.title, required this.value, this.accent = false, this.alignEnd = false});
  final String title;
  final String value;
  final bool accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(title, style: OnbText.body(context, 3, weight: FontWeight.w500, color: OnbColors.mute)),
        Text(value, style: OnbText.display(context, 4.6, color: accent ? OnbColors.accInk : OnbColors.ink, letterSpacingEm: -0.02)),
      ],
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  _ProjectionPainter({required this.geo, required this.grid, required this.ghost, required this.draw, required this.endScale});

  final _Geo geo;
  final double grid;
  final double ghost;
  final double draw;
  final double endScale;

  @override
  void paint(Canvas canvas, Size size) {
    // One rule, at the level the curve lands on, so it reads as the target
    // line. The three decorative rules that used to sit here measured nothing:
    // the chart has no scale, and none of them lined up with a real weight.
    final g = grid.clamp(0.0, 1.0);
    if (g > 0) {
      canvas.drawLine(
        Offset(geo.x0, geo.y1),
        Offset(geo.x0 + (geo.x1 - geo.x0) * g, geo.y1),
        Paint()
          ..color = OnbColors.ink.withValues(alpha: 0.08 * g)
          ..strokeWidth = 1,
      );
    }

    _paintGhost(canvas);
    _paintCurve(canvas);

    canvas.drawCircle(Offset(geo.x0, geo.y0), 4, Paint()..color = OnbColors.ink);
    if (endScale > 0) {
      canvas.drawCircle(Offset(geo.x1, geo.y1), 5.5 * endScale, Paint()..color = OnbColors.acc);
    }
  }

  /// Dashes that appear one after the other, so the flat line reads as a
  /// direction being taken rather than a rule already printed on the page.
  void _paintGhost(Canvas canvas) {
    final t = ghost.clamp(0.0, 1.0);
    if (t <= 0) return;
    final paint = Paint()
      ..color = OnbColors.mute2
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(geo.x0, geo.y0)
      ..lineTo(geo.x1, geo.ghostY1);
    for (final metric in path.computeMetrics()) {
      final visible = metric.length * t;
      var d = 0.0;
      while (d < visible) {
        canvas.drawPath(metric.extractPath(d, (d + 4).clamp(0, visible)), paint);
        d += 9;
      }
    }
  }

  void _paintCurve(Canvas canvas) {
    final t = draw.clamp(0.0, 1.0);
    if (t <= 0) return;
    final curve = Path()
      ..moveTo(geo.x0, geo.y0)
      ..cubicTo(geo.x0 + (geo.x1 - geo.x0) * 0.4, geo.y0, geo.x1 - (geo.x1 - geo.x0) * 0.43, geo.y1, geo.x1, geo.y1);
    final metrics = curve.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final drawn = m.extractPath(0, m.length * t);

    // the area keeps its density while it grows, instead of darkening as it goes
    final bounds = drawn.getBounds();
    final area = Path.from(drawn)
      ..lineTo(bounds.right, geo.yBot + 2)
      ..lineTo(geo.x0, geo.yBot + 2)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OnbColors.acc.withValues(alpha: 0.2), OnbColors.acc.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, geo.yTop, geo.size.width, geo.band + 2)),
    );

    canvas.drawPath(
      drawn,
      Paint()
        ..color = OnbColors.acc
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // a head that carries the stroke, and fades out as the end dot takes over
    if (t < 1) {
      final head = m.getTangentForOffset(m.length * t)?.position;
      if (head != null) {
        final fade = (1 - endScale).clamp(0.0, 1.0);
        canvas.drawCircle(head, 7, Paint()..color = OnbColors.acc.withValues(alpha: 0.28 * fade)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(head, 3.4, Paint()..color = OnbColors.acc.withValues(alpha: fade));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) =>
      old.grid != grid || old.ghost != ghost || old.draw != draw || old.endScale != endScale || old.geo.losing != geo.losing;
}
