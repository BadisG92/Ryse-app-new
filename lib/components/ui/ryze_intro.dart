import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import 'ryze_logo_paths.dart';

/// The opening of the app: the lockup is written stroke by stroke, floods
/// white, then the mark rushes at the viewer and becomes the window the first
/// screen is already waiting behind — you go *through* the logo.
///
/// It doubles as the loading cover: the timeline holds before the rush until
/// [ready] says the app knows where it is going, so routing never shows a
/// spinner and the reveal never opens onto nothing.
class RyzeIntro extends StatefulWidget {
  const RyzeIntro({super.key, required this.ready, required this.onDone});

  /// The app has resolved which screen comes next.
  final bool ready;

  /// Called once the mark has opened onto that screen.
  final VoidCallback onDone;

  @override
  State<RyzeIntro> createState() => _RyzeIntroState();
}

class _RyzeIntroState extends State<RyzeIntro> with SingleTickerProviderStateMixin {
  // The storyboard, in milliseconds.
  static const int _total = 2040;
  // The pen draws the mark and nothing else: it is the shape that becomes the
  // screen, and it used to get a third of the writing while the word — thrown
  // away three seconds later — took the rest.
  static const _write = (from: 0, to: 620);
  // A beat of silence, then the trace turns solid.
  static const _flood = (from: 800, to: 1080);
  // The word is not written, it is inked: one pass, left to right, with a soft
  // front so it reads as ink being laid down and not as a loading bar.
  static const _ink = (from: 1080, to: 1420);
  static const _hold = 1740; // the logo stands still, and waits for the app
  static const _rush = (from: _hold, to: _total); // 300 ms, and we are inside

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: _total));

  bool _light = false; // the reveal owns the screen: status bar icons flip
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    _c.forward();
  }

  void _tick() {
    final ms = _c.value * _total;
    // the mark holds until the app knows where it is going
    if (ms >= _hold && !widget.ready && _c.isAnimating) _c.stop();

    final light = ms >= _rush.from + 120;
    if (light != _light && mounted) setState(() => _light = light);

    if (!_done && _c.value >= 1) {
      _done = true;
      widget.onDone();
    }
  }

  @override
  void didUpdateWidget(RyzeIntro old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready && !_c.isAnimating && !_done) _c.forward();
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who asked their phone to stop animating gets the mark and the
    // opening, without the writing.
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _IntroPainter(ms: _c.value * _total, reduced: reduced),
          ),
        ),
      ),
    );
  }
}

/// Decoding six paths and measuring them costs more than it looks when it
/// happens on every frame: this holds them for as long as the width is stable.
class _Lockup {
  _Lockup(this.width)
      : icon = RyzeLogoPaths.icon(width),
        letters = RyzeLogoPaths.letters(width),
        anchor = RyzeLogoPaths.markAnchor(width),
        anchorRadius = RyzeLogoPaths.anchorRadius(width) {
    for (final p in icon) {
      final ms = p.computeMetrics().toList();
      metrics[p] = ms;
      lengths[p] = ms.fold<double>(0, (sum, m) => sum + m.length);
      // Where the pen touches down on each contour: the point nearest its own
      // top-left corner. From there the line grows both ways at once.
      starts[p] = [for (final m in ms) _touchDown(m)];
    }
    mark = icon.reduce((a, b) => Path.combine(PathOperation.union, a, b));
    penLength = icon.fold<double>(0, (sum, p) => sum + lengths[p]!);
    wordBounds = letters.map((l) => l.getBounds()).reduce((a, b) => a.expandToInclude(b));
  }

  final double width;
  final List<Path> icon;
  final List<Path> letters;
  final Offset anchor;
  final double anchorRadius;
  final Map<Path, List<PathMetric>> metrics = {};
  final Map<Path, double> lengths = {};
  final Map<Path, List<double>> starts = {};

  /// Distance along the contour of the point closest to its top-left corner.
  static double _touchDown(PathMetric m) {
    final corner = m.extractPath(0, m.length).getBounds().topLeft;
    var best = 0.0, bestD = double.infinity;
    const samples = 160;
    for (var i = 0; i < samples; i++) {
      final at = m.length * i / samples;
      final p = m.getTangentForOffset(at)?.position;
      if (p == null) continue;
      final d = (p - corner).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = at;
      }
    }
    return best;
  }

  /// The two shapes of the mark as one, so the opening is a single window.
  late final Path mark;

  /// How far the pen travels across the two contours of the mark.
  late final double penLength;

  /// The box the four letters occupy, so the ink knows where to sweep.
  late final Rect wordBounds;

  static _Lockup? _held;
  static _Lockup of(double width) {
    final held = _held;
    if (held != null && (held.width - width).abs() < 0.5) return held;
    return _held = _Lockup(width);
  }
}

class _IntroPainter extends CustomPainter {
  _IntroPainter({required this.ms, required this.reduced});

  final double ms;
  final bool reduced;

  static double _phase(double ms, ({int from, int to}) p, {Curve curve = Curves.linear}) =>
      curve.transform(((ms - p.from) / (p.to - p.from)).clamp(0.0, 1.0));

  /// Adds the stretch of [m] between two distances, wrapping around the end of
  /// a closed contour so an arc can straddle the start.
  static void _arc(Path out, PathMetric m, double from, double to) {
    final len = m.length;
    if (to - from >= len) {
      out.addPath(m.extractPath(0, len), Offset.zero);
      return;
    }
    final a = ((from % len) + len) % len;
    final b = ((to % len) + len) % len;
    if (a <= b) {
      out.addPath(m.extractPath(a, b), Offset.zero);
    } else {
      out.addPath(m.extractPath(a, len), Offset.zero);
      out.addPath(m.extractPath(0, b), Offset.zero);
    }
  }

  /// One glyph, drawn from its top-left in both directions at once: the two
  /// halves of the line travel around the shape and meet on the far side.
  /// A letter with a counter draws its outline and its hole together.
  static Path _written(_Lockup lock, Path path, double t) {
    final out = Path();
    if (t <= 0) return out;
    if (t >= 1) return path;
    final ms = lock.metrics[path]!;
    final starts = lock.starts[path]!;
    for (var i = 0; i < ms.length; i++) {
      final half = ms[i].length * t / 2;
      _arc(out, ms[i], starts[i] - half, starts[i] + half);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lockWidth = size.width * 0.46;
    final lockHeight = lockWidth * RyzeLogoPaths.ratio;
    final origin = Offset((size.width - lockWidth) / 2, (size.height - lockHeight) / 2);
    final lock = _Lockup.of(lockWidth);
    final anchor = origin + lock.anchor;

    final flood = reduced ? 1.0 : _phase(ms, _RyzeIntroState._flood, curve: Curves.easeOut);
    // Linear, not eased in: on the reference the mark holds dead still and then
    // grows at an even rate. An ease-in spends half the time barely moving and
    // reads as a snap rather than as something coming at you.
    final rush = _phase(ms, _RyzeIntroState._rush);

    // The mark grows from the middle of the swoosh's arm. Every point of the
    // screen is eventually inside it: a point at distance d from the anchor is
    // covered once the scale passes d / (radius of the disc that fits in the
    // arm), so no fade is needed — the logo really does become the screen.
    final far = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), size.bottomRight(Offset.zero)]
        .map((c) => (c - anchor).distance)
        .reduce(math.max);
    final scale = 1 + rush * (far / math.max(lock.anchorRadius, 1) * 1.12);
    final blowUp = Matrix4.identity()
      ..translateByDouble(anchor.dx, anchor.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-anchor.dx, -anchor.dy, 0, 1);
    final window = rush <= 0 ? null : lock.mark.shift(origin).transform(blowUp.storage);

    // Ground everywhere except inside the window: that hole is the screen
    // underneath, which is already built and waiting.
    final ground = Path()..addRect(Offset.zero & size);
    final opaque = window == null ? ground : Path.combine(PathOperation.difference, ground, window);
    canvas.drawPath(opaque, Paint()..color = RyzeColors.ink);

    // Inside the window, a white veil thins out as the mark grows: the screen
    // arrives through the white rather than after it.
    if (window != null) {
      // the white stays solid while the mark crosses the screen, then goes
      final veil = 1 - Curves.easeInOut.transform(((rush - 0.35) / 0.65).clamp(0.0, 1.0));
      if (veil > 0) canvas.drawPath(window, Paint()..color = Colors.white.withValues(alpha: veil));
    }

    // Once the mark starts rushing it *is* the window: at scale 1 the window
    // plus its full white veil are the same pixels as the filled logo, so the
    // handover costs no frame. Keeping the small logo painted on top here is
    // what used to make it look like it vanished instead of coming at you.
    if (rush > 0) {
      // The word is not erased, it is carried: the whole lockup rides the same
      // zoom, and since the word sits below the anchor it sweeps down and out
      // of the frame on its own. It only fades so that no giant letter is left
      // lying over the screen that has just been revealed.
      final carried = 1 - Curves.easeInOut.transform((rush / 0.55).clamp(0.0, 1.0));
      if (carried > 0) {
        canvas.save();
        canvas.transform(blowUp.storage);
        canvas.translate(origin.dx, origin.dy);
        final letterInk = Paint()..color = Colors.white.withValues(alpha: carried);
        for (final letter in lock.letters) {
          canvas.drawPath(letter, letterInk);
        }
        canvas.restore();
      }
      return;
    }

    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // The trace is a thin grey line, not a white one: it reads as a pen, and
    // the flood is what turns it into the logo.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(size.width * 0.0032, 1.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.55 * (1 - flood));
    final fill = Paint()..color = Colors.white.withValues(alpha: flood);

    // one pen, constant speed, across the two contours of the mark
    final pen = reduced ? 1.0 : _phase(ms, _RyzeIntroState._write);
    var covered = 0.0;
    for (final path in lock.icon) {
      final len = lock.lengths[path]!;
      final from = covered / lock.penLength;
      final to = (covered + len) / lock.penLength;
      covered += len;
      final t = ((pen - from) / (to - from)).clamp(0.0, 1.0);
      if (flood > 0) canvas.drawPath(path, fill);
      if (t > 0 && flood < 1) canvas.drawPath(_written(lock, path, t), stroke);
    }

    // The word, inked in one pass. The gradient is clamped, so everything left
    // of the front is opaque and everything right of it is gone: the shader is
    // the whole mask, no rectangle to keep in step with it.
    final ink = reduced ? 1.0 : _phase(ms, _RyzeIntroState._ink, curve: Curves.easeOut);
    if (ink > 0) {
      final box = lock.wordBounds;
      final soft = box.width * 0.12;
      final front = box.left - soft + ink * (box.width + soft);
      canvas.saveLayer(box.inflate(soft), Paint());
      final white = Paint()..color = Colors.white;
      for (final letter in lock.letters) {
        canvas.drawPath(letter, white);
      }
      canvas.drawRect(
        box.inflate(soft),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(front - soft, 0),
            Offset(front, 0),
            const [Colors.white, Color(0x00FFFFFF)],
          ),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IntroPainter old) => old.ms != ms || old.reduced != reduced;
}
