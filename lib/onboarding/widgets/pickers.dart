import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../services/haptic_service.dart';
import '../onboarding_state.dart';
import '../onboarding_theme.dart';

/// Haptic ticks, at most one every 35 ms. A fast drag crosses dozens of
/// graduations; queuing one click per graduation stalls the UI thread and is
/// the first thing that makes an instrument feel heavy.
class _Ticker {
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static void tick() {
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 35) return;
    _last = now;
    HapticService.instance.selectionClick();
  }
}

/// Digits that roll like an odometer: one column per digit, each rolling ten
/// times slower than the one on its right. A value that changes mid-roll
/// retargets the animation from where it currently is, so dragging the ruler
/// reads as a single continuous movement.
class RollingNumber extends StatelessWidget {
  const RollingNumber(this.value, {super.key, required this.style, this.duration = const Duration(milliseconds: 340)});

  final String value;
  final TextStyle style;
  final Duration duration;

  static final RegExp _runs = RegExp(r'\d+|\D+');

  @override
  Widget build(BuildContext context) {
    final digitStyle = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final cell = _cellSize(digitStyle, MediaQuery.textScalerOf(context));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final run in _runs.allMatches(value))
          if (_isDigits(run[0]!))
            _DigitRun(value: int.parse(run[0]!), digits: run[0]!.length, style: digitStyle, cell: cell, duration: duration)
          else
            Text(run[0]!, style: digitStyle),
      ],
    );
  }

  static bool _isDigits(String s) => s.codeUnitAt(0) >= 0x30 && s.codeUnitAt(0) <= 0x39;

  /// One digit box, measured on the real style so tabular figures line up.
  static Size _cellSize(TextStyle style, TextScaler scaler) {
    final painter = TextPainter(text: TextSpan(text: '0', style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }
}

class _DigitRun extends StatelessWidget {
  const _DigitRun({required this.value, required this.digits, required this.style, required this.cell, required this.duration});

  final int value;
  final int digits;
  final TextStyle style;
  final Size cell;
  final Duration duration;

  static const List<double> _pow10 = [1, 10, 100, 1000, 10000];

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var c = 0; c < digits; c++) _DigitColumn(position: v / _pow10[(digits - 1 - c).clamp(0, _pow10.length - 1)], style: style, cell: cell),
        ],
      ),
    );
  }
}

class _DigitColumn extends StatelessWidget {
  const _DigitColumn({required this.position, required this.style, required this.cell});

  /// Continuous position of this column: its integer part is the digit shown,
  /// its fractional part how far it has rolled toward the next one.
  final double position;
  final TextStyle style;
  final Size cell;

  @override
  Widget build(BuildContext context) {
    final p = position.isFinite && position > 0 ? position : 0.0;
    final base = p.floor();
    final frac = p - base;
    return SizedBox(
      width: cell.width,
      height: cell.height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(top: -frac * cell.height, left: 0, right: 0, child: _glyph(base)),
            Positioned(top: (1 - frac) * cell.height, left: 0, right: 0, child: _glyph(base + 1)),
          ],
        ),
      ),
    );
  }

  Widget _glyph(int n) => SizedBox(height: cell.height, child: Text('${((n % 10) + 10) % 10}', style: style, maxLines: 1, textAlign: TextAlign.center));
}

/// Vertical wheel (age).
class OnbWheelPicker extends StatefulWidget {
  const OnbWheelPicker({super.key, required this.min, required this.max, required this.value, required this.unit, required this.onChanged});
  final int min;
  final int max;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  State<OnbWheelPicker> createState() => _OnbWheelPickerState();
}

class _OnbWheelPickerState extends State<OnbWheelPicker> {
  late final FixedExtentScrollController _controller = FixedExtentScrollController(initialItem: (widget.value - widget.min).clamp(0, widget.max - widget.min));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemExtent = context.vw(11.2);
    final height = context.vw(56);
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: context.vw(22),
            right: context.vw(22),
            child: Container(
              height: itemExtent,
              decoration: BoxDecoration(
                color: OnbColors.surf,
                borderRadius: BorderRadius.circular(context.vw(3)),
                border: Border.all(color: OnbColors.acc, width: 1.5),
                boxShadow: [BoxShadow(color: OnbColors.acc.withValues(alpha: 0.14), blurRadius: context.vw(4), offset: Offset(0, context.vw(1.4)))],
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.3, 0.7, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: itemExtent,
              perspective: 0.0025,
              diameterRatio: 1.8,
              useMagnifier: true,
              magnification: 1.18,
              overAndUnderCenterOpacity: 0.35,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) {
                _Ticker.tick();
                widget.onChanged(widget.min + i);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.max - widget.min + 1,
                builder: (context, i) => Center(
                  child: Text(
                    '${widget.min + i}',
                    style: OnbText.display(context, 9.4, letterSpacingEm: -0.03).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: context.vw(50) + context.vw(10),
            child: Text(widget.unit, style: OnbText.body(context, 3.8, weight: FontWeight.w500, color: OnbColors.mute)),
          ),
        ],
      ),
    );
  }
}

/// Horizontal graduated ruler (height, weight, target). Stores metric,
/// displays metric or imperial.
class OnbRulerPicker extends StatefulWidget {
  const OnbRulerPicker({
    super.key,
    required this.isHeight,
    required this.minMetric,
    required this.maxMetric,
    required this.valueMetric,
    required this.isMetric,
    required this.onChanged,
    required this.onUnitChanged,
    this.footer,
    this.decimal = ',',
  });

  /// Decimal mark of the current language, for the half kilos.
  final String decimal;

  final bool isHeight;
  final int minMetric;
  final int maxMetric;
  final double valueMetric;
  final bool isMetric;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool> onUnitChanged;
  final Widget? footer;

  @override
  State<OnbRulerPicker> createState() => _OnbRulerPickerState();
}

class _OnbRulerPickerState extends State<OnbRulerPicker> {
  /// The weight ruler works in half kilos: a bathroom scale does, so it must.
  /// Everything else counts in whole centimetres, inches or pounds.
  int get _perUnit => widget.isMetric && !widget.isHeight ? 2 : 1;

  int get _lo => _tickOfUnit(widget.isMetric ? widget.minMetric.toDouble() : (widget.isHeight ? OnbUnits.cmToIn(widget.minMetric).toDouble() : OnbUnits.kgToLb(widget.minMetric.toDouble()).toDouble()));
  int get _hi => _tickOfUnit(widget.isMetric ? widget.maxMetric.toDouble() : (widget.isHeight ? OnbUnits.cmToIn(widget.maxMetric).toDouble() : OnbUnits.kgToLb(widget.maxMetric.toDouble()).toDouble()));

  int _tickOfUnit(double unit) => (unit * _perUnit).round();

  int _tickOf(double metric) =>
      _tickOfUnit(widget.isMetric ? metric : (widget.isHeight ? OnbUnits.cmToIn(metric.round()).toDouble() : OnbUnits.kgToLb(metric).toDouble()));

  double _metricOfTick(int tick) {
    final unit = tick / _perUnit;
    if (widget.isMetric) return unit;
    return widget.isHeight ? OnbUnits.inToCm(unit.round()).toDouble() : OnbUnits.lbToKg(unit.round());
  }

  String _labelOfTick(int tick) {
    if (!widget.isMetric && widget.isHeight) return "${tick ~/ 12}'${tick % 12}";
    if (widget.isMetric && !widget.isHeight) return OnbUnits.fmtKg(tick / 2, decimal: widget.decimal);
    return '$tick';
  }

  @override
  Widget build(BuildContext context) {
    final tick = _tickOf(widget.valueMetric).clamp(_lo, _hi);
    final unit = widget.isMetric ? (widget.isHeight ? 'cm' : 'kg') : (widget.isHeight ? '' : 'lb');
    return Column(
      children: [
        _UnitSwitch(
          isMetric: widget.isMetric,
          metricLabel: widget.isHeight ? 'cm' : 'kg',
          imperialLabel: widget.isHeight ? 'ft / in' : 'lb',
          onChanged: widget.onUnitChanged,
        ),
        SizedBox(height: context.vh(1.6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RollingNumber(_labelOfTick(tick), style: OnbText.display(context, 21, letterSpacingEm: -0.045, height: 1)),
            if (unit.isNotEmpty) ...[
              SizedBox(width: context.vw(1.8)),
              Padding(
                padding: EdgeInsets.only(bottom: context.vw(1.4)),
                child: Text(unit, style: OnbText.display(context, 5, weight: FontWeight.w600, color: OnbColors.mute, letterSpacingEm: 0)),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vh(2)),
        _RulerTrack(
          key: ValueKey('${widget.isMetric}-${widget.isHeight}'),
          lo: _lo,
          hi: _hi,
          value: tick,
          majorEvery: widget.isHeight && !widget.isMetric ? 12 : 10 * _perUnit,
          midEvery: widget.isHeight && !widget.isMetric ? 6 : 5 * _perUnit,
          labelOf: (t) => widget.isHeight && !widget.isMetric ? "${t ~/ 12}'" : '${t ~/ _perUnit}',
          onChanged: (t) => widget.onChanged(_metricOfTick(t)),
        ),
        if (widget.footer != null) ...[SizedBox(height: context.vh(1.6)), widget.footer!],
      ],
    );
  }
}

class _UnitSwitch extends StatelessWidget {
  const _UnitSwitch({required this.isMetric, required this.metricLabel, required this.imperialLabel, required this.onChanged});
  final bool isMetric;
  final String metricLabel;
  final String imperialLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // 44 pt of touch target, whatever the label height
    Widget seg(String label, bool on, bool metric) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(metric),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            constraints: BoxConstraints(minHeight: context.vw(10.4)),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
            decoration: BoxDecoration(
              color: on ? OnbColors.surf : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: on ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.12), blurRadius: 2, offset: const Offset(0, 1))] : null,
            ),
            child: Text(label, style: OnbText.body(context, 3.2, weight: FontWeight.w600, color: on ? OnbColors.ink : OnbColors.mute)),
          ),
        );
    return Container(
      padding: EdgeInsets.all(context.vw(0.6)),
      decoration: BoxDecoration(color: OnbColors.paper2, borderRadius: BorderRadius.circular(999), border: Border.all(color: OnbColors.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg(metricLabel, isMetric, true), seg(imperialLabel, !isMetric, false)]),
    );
  }
}

/// Snaps to a graduation while keeping the whole fling: the friction
/// simulation decides where the flick naturally ends, and the ruler lands on
/// the nearest graduation to that point. A page view, by contrast, stops one
/// graduation away whatever the gesture.
class _TickScrollPhysics extends ScrollPhysics {
  const _TickScrollPhysics({required this.tick, super.parent});

  final double tick;

  @override
  _TickScrollPhysics applyTo(ScrollPhysics? ancestor) => _TickScrollPhysics(tick: tick, parent: buildParent(ancestor));

  double _settle(double offset, ScrollMetrics position) =>
      ((offset / tick).roundToDouble() * tick).clamp(position.minScrollExtent, position.maxScrollExtent);

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (tick <= 0 || position.outOfRange) return super.createBallisticSimulation(position, velocity);
    final tolerance = toleranceFor(position);
    final natural = super.createBallisticSimulation(position, velocity);
    final end = natural?.x(double.infinity) ?? position.pixels;
    if (!end.isFinite) return natural;
    // a fling that runs into an edge keeps the platform's own bounce
    if (natural != null && (end <= position.minScrollExtent || end >= position.maxScrollExtent)) return natural;

    final target = _settle(end, position);
    final distance = target - position.pixels;
    if (distance.abs() < tolerance.distance && velocity.abs() < tolerance.velocity) return null;
    // enough speed and the same direction: ride the fling all the way to the graduation
    if (velocity.abs() > tolerance.velocity && distance != 0 && distance.sign == velocity.sign) {
      return FrictionSimulation.through(position.pixels, target, velocity, tolerance.velocity * velocity.sign);
    }
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _RulerTrack extends StatefulWidget {
  const _RulerTrack({
    super.key,
    required this.lo,
    required this.hi,
    required this.value,
    required this.majorEvery,
    required this.midEvery,
    required this.labelOf,
    required this.onChanged,
  });

  /// Bounds and value in graduations, not in units.
  final int lo;
  final int hi;
  final int value;
  final int majorEvery;
  final int midEvery;
  final String Function(int tick) labelOf;
  final ValueChanged<int> onChanged;

  @override
  State<_RulerTrack> createState() => _RulerTrackState();
}

class _RulerTrackState extends State<_RulerTrack> {
  ScrollController? _controller;
  double _tick = 0;
  int _index = 0;

  int get _count => widget.hi - widget.lo + 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tick = context.vw(3.2);
    if (_controller != null && tick == _tick) return;
    final old = _controller;
    _tick = tick;
    _index = (widget.value - widget.lo).clamp(0, _count - 1);
    _controller = ScrollController(initialScrollOffset: _index * tick)..addListener(_onScroll);
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void didUpdateWidget(covariant _RulerTrack old) {
    super.didUpdateWidget(old);
    // the value can also change from the outside (target adjusted to the goal)
    final target = (widget.value - widget.lo).clamp(0, _count - 1);
    final c = _controller;
    if (target == _index || c == null || !c.hasClients || c.position.isScrollingNotifier.value) return;
    _index = target;
    c.animateTo(target * _tick, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final c = _controller;
    if (_tick <= 0 || c == null || !c.hasClients) return;
    final i = (c.offset / _tick).round().clamp(0, _count - 1);
    if (i == _index) return;
    _index = i;
    _Ticker.tick();
    widget.onChanged(widget.lo + i);
  }

  @override
  Widget build(BuildContext context) {
    final height = context.vw(17);
    return Container(
      height: height,
      decoration: BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(4)), border: Border.all(color: OnbColors.line)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = ((constraints.maxWidth - _tick) / 2).clamp(0.0, double.infinity);
          return Stack(
            children: [
              ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: _TickScrollPhysics(tick: _tick),
                padding: EdgeInsets.symmetric(horizontal: side),
                itemExtent: _tick,
                itemCount: _count,
                itemBuilder: (context, i) {
                  final v = widget.lo + i;
                  final major = v % widget.majorEvery == 0;
                  final mid = !major && v % widget.midEvery == 0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: major ? 1.5 : 1,
                        height: major ? context.vw(8) : (mid ? context.vw(5.6) : context.vw(3.6)),
                        color: OnbColors.ink.withValues(alpha: major ? 0.75 : (mid ? 0.4 : 0.22)),
                      ),
                      SizedBox(height: context.vw(1)),
                      SizedBox(
                        height: context.vw(3.6),
                        child: major
                            ? OverflowBox(
                                maxWidth: context.vw(12),
                                child: Text(
                                  widget.labelOf(v),
                                  style: OnbText.body(context, 2.7, weight: FontWeight.w500, color: OnbColors.mute),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(height: context.vw(0.8)),
                    ],
                  );
                },
              ),
              // edges fade into the card: two gradients, no per-frame saveLayer
              _Fade(width: constraints.maxWidth * 0.16, left: true),
              _Fade(width: constraints.maxWidth * 0.16, left: false),
              Positioned(
                left: 0,
                right: 0,
                bottom: context.vw(5),
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: context.vw(2.6), height: context.vw(2.6), decoration: const BoxDecoration(color: OnbColors.acc, shape: BoxShape.circle)),
                        Container(
                          width: 2.4,
                          height: context.vw(9.4),
                          decoration: BoxDecoration(
                            color: OnbColors.acc,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: OnbColors.acc.withValues(alpha: 0.4), blurRadius: context.vw(1.6))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.width, required this.left});
  final double width;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [OnbColors.surf, OnbColors.surf.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
