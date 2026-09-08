import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/design.dart';
import '../../design/palette.dart';
import '../../services/haptic_service.dart';

/// The opening of the app: the mark is written by hand, floods white, the name
/// is inked in one pass — then the mark rushes at the viewer and becomes the
/// window the first screen is already waiting behind. You go *through* the logo.
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
  static const int _total = 2180;

  /// The pen draws the mark and nothing else: it is the shape that becomes the
  /// screen. One pen, constant speed, the dot then the rise — time is shared by
  /// length, not by shape, so the hand never speeds up or stalls between them.
  static const _write = (from: 0, to: 620);

  /// A beat of silence after the trace, then it turns solid.
  static const _flood = (from: 800, to: 1080);

  /// The name is not written, it is inked: one pass, left to right, with a soft
  /// front so it reads as ink being laid down and not as a loading bar. Writing
  /// the letters one by one gave the word seven tenths of the drawing time, for
  /// a shape that is thrown away a second later.
  static const _ink = (from: 1080, to: 1420);

  static const _hold = 1740; // the logo stands still, and waits for the app

  /// 440 ms rather than the 300 measured on the reference: their mark is a
  /// checkmark opening onto a light screen, ours is a long arm sweeping across
  /// a navy one, and at 300 it lands like a slap.
  static const _rush = (from: _hold, to: _total);

  /// Where the opening starts when the logo has already been written once on
  /// this device: straight to the finished mark, no pen.
  static final double _writtenAt = _flood.to / _total;

  static const String _writtenKey = 'intro_logo_written';

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: _total));

  bool _light = false; // the reveal owns the screen: status bar icons flip
  bool _done = false;
  bool _tapped = false; // the punch is felt once

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    _boot();
  }

  /// The logo is written the first time the app is opened on this device, and
  /// only then: an opening you watch every morning stops being an opening. The
  /// preference resolves in a few milliseconds, and the ground behind is the
  /// same navy as the launch screen, so the wait shows nothing.
  Future<void> _boot() async {
    var written = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      written = prefs.getBool(_writtenKey) ?? false;
      if (!written) await prefs.setBool(_writtenKey, true);
    } catch (_) {
      // no preferences, no shortcut: draw it
    }
    if (!mounted) return;
    if (written) _c.value = _writtenAt;
    _c.forward();
  }

  void _tick() {
    final ms = _c.value * _total;
    // the mark holds until the app knows where it is going
    if (ms >= _hold && !widget.ready && _c.isAnimating) _c.stop();

    if (!_tapped && ms >= _rush.from) {
      _tapped = true;
      HapticService.instance.lightImpact();
    }

    final light = ms >= _rush.from + 200;
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
    // Someone who asked their phone to stop animating gets the logo and the
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

/// The lockup laid out for one screen size. Measuring the contours costs more
/// than it looks when it happens sixty times a second, so it is held for as
/// long as the box is stable.
class _Lockup {
  _Lockup(this.box)
      : marks = [for (final part in RyzeLogo.markParts(box)) part.shape],
        word = RyzeLogo.word(box),
        anchor = RyzeLogo.armAnchor(box),
        anchorRadius = RyzeLogo.armRadius(box) {
    for (final p in marks) {
      final ms = p.computeMetrics().toList();
      metrics[p] = ms;
      lengths[p] = ms.fold<double>(0, (sum, m) => sum + m.length);
      // Where the pen touches down on each contour: the point nearest its own
      // top-left corner. From there the line grows both ways at once.
      starts[p] = [for (final m in ms) _touchDown(m)];
    }
    mark = marks.reduce((a, b) => Path.combine(PathOperation.union, a, b));
    penLength = marks.fold<double>(0, (sum, p) => sum + lengths[p]!);
    wordBounds = word.getBounds();
  }

  final Rect box;
  final List<Path> marks;
  final Path word;
  final Offset anchor;
  final double anchorRadius;
  final Map<Path, List<PathMetric>> metrics = {};
  final Map<Path, double> lengths = {};
  final Map<Path, List<double>> starts = {};

  /// The shapes of the mark as one, so the opening is a single window.
  late final Path mark;

  /// How far the pen travels across the mark.
  late final double penLength;

  /// The box the name occupies, so the ink knows where to sweep.
  late final Rect wordBounds;

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

  static _Lockup? _held;
  static _Lockup of(Rect box) {
    final held = _held;
    if (held != null && (held.box.width - box.width).abs() < 0.5 && (held.box.top - box.top).abs() < 0.5) {
      return held;
    }
    return _held = _Lockup(box);
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

  /// One shape, drawn from its top-left in both directions at once: the two
  /// halves of the line travel around it and meet on the far side.
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
    // The lockup canvas is a little wider than its own ink — the name stops
    // short of both edges — so the box is set a touch wider than the logo
    // should read on screen.
    final boxWidth = size.width * 0.50;
    final boxHeight = boxWidth * RyzeLogo.lockup.height / RyzeLogo.lockup.width;
    final box = Rect.fromLTWH((size.width - boxWidth) / 2, (size.height - boxHeight) / 2, boxWidth, boxHeight);
    final lock = _Lockup.of(box);

    final flood = reduced ? 1.0 : _phase(ms, _RyzeIntroState._flood, curve: Curves.easeOut);
    // Linear, not eased in: on the reference the mark holds dead still and then
    // grows at an even rate. An ease-in spends half the time barely moving and
    // reads as a snap rather than as something coming at you.
    final rush = _phase(ms, _RyzeIntroState._rush);

    // The mark grows from the middle of its arm. Every point of the screen is
    // eventually inside it: a point at distance d from the anchor is covered
    // once the scale passes d / armRadius, so nothing has to be faded out —
    // the logo really does become the screen.
    final far = [Offset.zero, Offset(size.width, 0), Offset(0, size.height), size.bottomRight(Offset.zero)]
        .map((c) => (c - lock.anchor).distance)
        .reduce(math.max);
    final scale = 1 + rush * (far / math.max(lock.anchorRadius, 1) * 1.12);
    final blowUp = Matrix4.identity()
      ..translateByDouble(lock.anchor.dx, lock.anchor.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-lock.anchor.dx, -lock.anchor.dy, 0, 1);
    final window = rush <= 0 ? null : lock.mark.transform(blowUp.storage);

    // Ground everywhere except inside the window: that hole is the screen
    // underneath, which is already built and waiting. Same gradient as the
    // launch screen, so the handover from it shows nothing.
    final ground = Path()..addRect(Offset.zero & size);
    final opaque = window == null ? ground : Path.combine(PathOperation.difference, ground, window);
    canvas.drawPath(
      opaque,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          size.bottomRight(Offset.zero),
          // Le logo qui s'ecrit est la marque, pas l'habit de l'utilisateur :
          // il reste navy quelle que soit l'edition choisie.
          <Color>[RyzePalettes.nuit.ink, RyzePalettes.nuit.ink2],
        ),
    );

    // Inside the window, a white veil thins out as the mark grows: the screen
    // arrives through the white rather than after it.
    if (window != null) {
      final veil = 1 - Curves.easeInOut.transform(((rush - 0.35) / 0.65).clamp(0.0, 1.0));
      if (veil > 0) canvas.drawPath(window, Paint()..color = Colors.white.withValues(alpha: veil));
    }

    // Once the mark starts rushing it *is* the window: at scale 1 the window
    // plus its full white veil are the same pixels as the filled logo, so the
    // handover costs no frame.
    if (rush > 0) {
      // The name is not erased, it is carried: it rides the same zoom, and
      // since it sits below the anchor it sweeps down and out of the frame on
      // its own. It only fades so that no giant letter is left lying over the
      // screen that has just been revealed.
      final carried = 1 - Curves.easeInOut.transform((rush / 0.55).clamp(0.0, 1.0));
      if (carried > 0) {
        canvas.save();
        canvas.transform(blowUp.storage);
        canvas.drawPath(lock.word, Paint()..color = Colors.white.withValues(alpha: carried));
        canvas.restore();
      }
      return;
    }

    // The trace is a thin grey line, not a white one: it reads as a pen, and
    // the flood is what turns it into the logo.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(size.width * 0.0032, 1.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.55 * (1 - flood));
    final fill = Paint()..color = Colors.white.withValues(alpha: flood);

    final pen = reduced ? 1.0 : _phase(ms, _RyzeIntroState._write);
    var covered = 0.0;
    for (final path in lock.marks) {
      final len = lock.lengths[path]!;
      final from = covered / lock.penLength;
      final to = (covered + len) / lock.penLength;
      covered += len;
      final t = ((pen - from) / (to - from)).clamp(0.0, 1.0);
      if (flood > 0) canvas.drawPath(path, fill);
      if (t > 0 && flood < 1) canvas.drawPath(_written(lock, path, t), stroke);
    }

    // The name, inked in one pass. The gradient is clamped, so everything left
    // of the front is opaque and everything right of it is gone: the shader is
    // the whole mask, with no rectangle to keep in step with it.
    final ink = reduced ? 1.0 : _phase(ms, _RyzeIntroState._ink, curve: Curves.easeOut);
    if (ink > 0) {
      final soft = lock.wordBounds.width * 0.12;
      final front = lock.wordBounds.left - soft + ink * (lock.wordBounds.width + soft);
      final area = lock.wordBounds.inflate(soft);
      canvas.saveLayer(area, Paint());
      canvas.drawPath(lock.word, Paint()..color = Colors.white);
      canvas.drawRect(
        area,
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
  }

  @override
  bool shouldRepaint(covariant _IntroPainter old) => old.ms != ms || old.reduced != reduced;
}
