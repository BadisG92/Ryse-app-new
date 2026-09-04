import 'package:flutter/material.dart';

import '../onboarding_theme.dart';

/// Weight projection: the curve draws itself towards the target date,
/// a dashed ghost line shows "continuing as before".
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
  final bool losing;

  @override
  State<ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<ProjectionChart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final Animation<double> _draw = CurvedAnimation(parent: _c, curve: const Interval(0, 0.85, curve: OnbCurves.out));
  late final Animation<double> _end = CurvedAnimation(parent: _c, curve: const Interval(0.8, 1, curve: Cubic(0.2, 1.4, 0.3, 1)));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 450), () {
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
    return AspectRatio(
      aspectRatio: 320 / 165,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _ProjectionPainter(progress: _draw.value, endScale: _end.value, losing: widget.losing))),
              Positioned(
                left: context.vw(1),
                top: 0,
                child: _Label(title: widget.startLabel, value: widget.startValue),
              ),
              Positioned(
                right: 0,
                bottom: context.vw(11),
                child: Opacity(
                  opacity: _end.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - _end.value.clamp(0.0, 1.0)) * 8),
                    child: _Label(title: widget.endLabel, value: widget.endValue, accent: true, alignEnd: true),
                  ),
                ),
              ),
              Positioned(
                left: context.vw(1),
                bottom: context.vw(6),
                child: Text(widget.ghostLabel, style: OnbText.body(context, 2.8, weight: FontWeight.w500, color: OnbColors.mute2)),
              ),
            ],
          );
        },
      ),
    );
  }
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
  _ProjectionPainter({required this.progress, required this.endScale, required this.losing});
  final double progress;
  final double endScale;
  final bool losing;

  @override
  void paint(Canvas canvas, Size size) {
    final x0 = size.width * 0.07;
    final x1 = size.width * 0.93;
    final yTop = size.height * 0.2;
    final yBot = size.height * 0.78;
    final y0 = losing ? yTop : yBot;
    final y1 = losing ? yBot : yTop;

    // grid
    final grid = Paint()
      ..color = OnbColors.ink.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (final y in [yTop, (yTop + yBot) / 2, yBot]) {
      canvas.drawLine(Offset(x0, y), Offset(x1, y), grid);
    }

    // ghost dashed line
    final ghost = Paint()
      ..color = OnbColors.mute2
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final gy1 = y0 + (losing ? -4 : 4);
    final gPath = Path()
      ..moveTo(x0, y0)
      ..lineTo(x1, gy1);
    for (final metric in gPath.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + 4).clamp(0, metric.length)), ghost);
        d += 9;
      }
    }

    // curve
    final curve = Path()
      ..moveTo(x0, y0)
      ..cubicTo(x0 + (x1 - x0) * 0.4, y0, x1 - (x1 - x0) * 0.43, y1, x1, y1);
    final metrics = curve.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final drawn = m.extractPath(0, m.length * progress.clamp(0.0, 1.0));

    if (progress > 0) {
      final tail = drawn.getBounds();
      final area = Path.from(drawn)
        ..lineTo(tail.right, yBot + 2)
        ..lineTo(x0, yBot + 2)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OnbColors.acc.withValues(alpha: 0.22 * progress), OnbColors.acc.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, yTop, size.width, yBot - yTop + 2)),
      );
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..color = OnbColors.acc
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(Offset(x0, y0), 4, Paint()..color = OnbColors.ink);
    if (endScale > 0) {
      canvas.drawCircle(Offset(x1, y1), 5.5 * endScale, Paint()..color = OnbColors.acc);
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) => old.progress != progress || old.endScale != endScale || old.losing != losing;
}
