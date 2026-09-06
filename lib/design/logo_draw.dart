import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ryze_logo.dart';
import 'tokens.dart';

/// The Ryze logo at launch: the mark is written by hand, then the name lands.
///
/// The mark is laid down by a nib travelling along the middle of each shape, so
/// the ink only exists where the pen has already passed and the form builds
/// from one end to the other. The dot is set down, then the curve rises from
/// the bottom left to the top right.
///
/// The name does not get the same treatment. A hand writes `Ryze` in eight
/// separate strokes, and the seams between them read as a stutter rather than
/// as writing, so the whole word arrives at once instead. It takes as long to
/// settle as one stroke of the mark, and moves on the same pace, so the two
/// belong to the same hand.
///
/// With reduce-motion on, the logo is there from the first frame and
/// [onComplete] fires at once.
class RyzeLogoDraw extends StatefulWidget {
  const RyzeLogoDraw({
    super.key,
    this.height = 220,
    this.color = Colors.white,
    this.glow = RyzeColors.acc,
    this.onComplete,
  });

  /// Height of the whole lockup. The width follows the brand's proportions.
  final double height;

  /// The ink.
  final Color color;

  /// The warm light behind the mark, the one accent of the screen. Pass
  /// `Colors.transparent` to drop it.
  final Color glow;

  /// Fired once the name has landed.
  final VoidCallback? onComplete;

  /// When each shape of the mark starts and stops being drawn, in
  /// milliseconds. The two overlap by a hair so the hand never stops.
  static const List<({int from, int to})> strokes = [
    (from: 0, to: 320), // the dot
    (from: 260, to: 1240), // the rise, the long gesture of the mark
  ];

  /// The name comes in over the end of the rise and settles under it. Its
  /// window is as long as the rise's own, and it opens slowly, so the name
  /// reads as a second beat without leaving a gap after the first.
  static const int wordFrom = 1180;
  static const int wordTo = 2140;

  /// After a shape is drawn, any sliver the nib could not reach fades in over
  /// this long. It is a safety net, not an effect: when the sweep covers the
  /// shape, which is the normal case, nothing is visible.
  static const int settleMs = 150;

  /// How long the whole thing lasts, from the first stroke to the last frame.
  static const Duration duration = Duration(milliseconds: wordTo);

  @override
  State<RyzeLogoDraw> createState() => _RyzeLogoDrawState();
}

class _RyzeLogoDrawState extends State<RyzeLogoDraw> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: RyzeLogoDraw.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete?.call());
      return;
    }
    _c.forward().whenCompleteOrCancel(() {
      if (mounted && _c.isCompleted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.height * RyzeLogo.lockup.width / RyzeLogo.lockup.height, widget.height),
        painter: _PenPainter(repaint: _c, progress: _c, color: widget.color, glow: widget.glow),
      ),
    );
  }
}

/// The finished logo, no animation. For the frames before and after the
/// writing, and for any screen that just needs the lockup in vector form.
class RyzeLogoStill extends StatelessWidget {
  const RyzeLogoStill({super.key, this.height = 220, this.color = Colors.white, this.glow = Colors.transparent});

  final double height;
  final Color color;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * RyzeLogo.lockup.width / RyzeLogo.lockup.height, height),
      painter: _PenPainter(color: color, glow: glow),
    );
  }
}

/// One shape of the mark, measured: the form, the pen's path along it, and how
/// long that path is. Measuring is the expensive step, so it happens once per
/// size rather than once per frame.
class _Measured {
  _Measured(this.part) : _metrics = part.skeleton.computeMetrics().toList() {
    _total = _metrics.fold<double>(0, (sum, m) => sum + m.length);
    bounds = part.shape.getBounds().inflate(part.nib);
  }

  final RyzeLogoPart part;
  final List<ui.PathMetric> _metrics;
  late final double _total;
  late final Rect bounds;

  /// The stretch of the pen's path travelled so far.
  Path travelled(double t) {
    final out = Path();
    if (t <= 0 || _total <= 0) return out;
    var remaining = _total * t;
    for (final m in _metrics) {
      if (remaining <= 0) break;
      out.addPath(m.extractPath(0, math.min(remaining, m.length)), Offset.zero);
      remaining -= m.length;
    }
    return out;
  }
}

class _PenPainter extends CustomPainter {
  _PenPainter({super.repaint, this.progress, required this.color, required this.glow});

  /// 0 to 1 over the whole animation. Null paints the finished logo.
  final Animation<double>? progress;
  final Color color;
  final Color glow;

  Size? _measuredFor;
  List<_Measured> _mark = const [];
  Path? _word;
  Rect _wordBox = Rect.zero;

  void _measure(Size size) {
    if (_measuredFor == size) return;
    final box = Offset.zero & size;
    _mark = RyzeLogo.markParts(box).map(_Measured.new).toList();
    _word = RyzeLogo.word(box);
    _wordBox = _word!.getBounds();
    _measuredFor = size;
  }

  /// A hand keeps an even pace and eases off at both ends of a stroke.
  double _pace(double t) => 0.5 - math.cos(math.pi * t) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    _measure(size);
    const strokes = RyzeLogoDraw.strokes;
    final total = RyzeLogoDraw.duration.inMilliseconds.toDouble();
    final ms = (progress?.value ?? 1) * total;

    // The warm light comes up with the mark: the one accent of the screen, and
    // the same glow the rest of the app carries.
    final lit = (ms / strokes.last.to).clamp(0.0, 1.0);
    if (glow.a > 0 && lit > 0) {
      final centre = Rect.fromLTRB(
        RyzeLogo.markBounds.left / RyzeLogo.lockup.width * size.width,
        RyzeLogo.markBounds.top / RyzeLogo.lockup.height * size.height,
        RyzeLogo.markBounds.right / RyzeLogo.lockup.width * size.width,
        RyzeLogo.markBounds.bottom / RyzeLogo.lockup.height * size.height,
      ).center;
      final radius = size.height * 0.62;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(centre, radius, [
            glow.withValues(alpha: 0.20 * lit),
            glow.withValues(alpha: 0),
          ]),
      );
    }

    final ink = Paint()..color = color;

    for (var i = 0; i < _mark.length; i++) {
      final m = _mark[i];
      final window = strokes[i];
      final drawn = ((ms - window.from) / (window.to - window.from)).clamp(0.0, 1.0);
      if (drawn <= 0) continue;
      final settled = ((ms - window.to) / RyzeLogoDraw.settleMs).clamp(0.0, 1.0);

      if (settled >= 1) {
        canvas.drawPath(m.part.shape, ink);
        continue;
      }

      // The shape is painted, then everything the nib has not reached is taken
      // back out of it. What is left is the ink actually laid down.
      canvas.saveLayer(m.bounds, Paint());
      canvas.drawPath(m.part.shape, ink);
      canvas.drawPath(
        m.travelled(_pace(drawn)),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..style = PaintingStyle.stroke
          ..strokeWidth = m.part.nib
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF000000),
      );
      canvas.restore();

      if (settled > 0) {
        canvas.drawPath(m.part.shape, Paint()..color = color.withValues(alpha: color.a * settled));
      }
    }

    // The name, as one block. It comes up on the pen's own pace, so it starts
    // almost imperceptibly, carries through the middle of its window and
    // settles rather than stops. Position, size and ink all move together:
    // one object arriving, not three effects.
    const from = RyzeLogoDraw.wordFrom;
    const span = RyzeLogoDraw.wordTo - from;
    final raw = ((ms - from) / span).clamp(0.0, 1.0);
    if (raw <= 0) return;

    final placed = _pace(raw);
    final centre = _wordBox.center;

    canvas.save();
    canvas.translate(0, (1 - placed) * size.height * 0.05);
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(0.92 + 0.08 * placed);
    canvas.translate(-centre.dx, -centre.dy);
    canvas.drawPath(_word!, Paint()..color = color.withValues(alpha: color.a * placed));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PenPainter old) => old.color != color || old.glow != glow;
}
