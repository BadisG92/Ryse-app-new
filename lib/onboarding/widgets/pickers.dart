import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';
import '../onboarding_state.dart';
import '../onboarding_theme.dart';

/// Digits that roll vertically when the value changes.
class RollingNumber extends StatelessWidget {
  const RollingNumber(this.value, {super.key, required this.style});
  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (var i = 0; i < value.length; i++)
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: OnbCurves.spring,
              switchOutCurve: OnbCurves.out,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey('$i-${value[i]}');
                final offset = Tween<Offset>(begin: Offset(0, incoming ? 0.6 : -0.6), end: Offset.zero).animate(anim);
                return FadeTransition(opacity: anim, child: SlideTransition(position: offset, child: child));
              },
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, if (current != null) current]),
              child: Text(value[i], key: ValueKey('$i-${value[i]}'), style: style),
            ),
          ),
      ],
    );
  }
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
                HapticService.instance.selectionClick();
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
  });

  final bool isHeight;
  final int minMetric;
  final int maxMetric;
  final int valueMetric;
  final bool isMetric;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool> onUnitChanged;
  final Widget? footer;

  @override
  State<OnbRulerPicker> createState() => _OnbRulerPickerState();
}

class _OnbRulerPickerState extends State<OnbRulerPicker> {
  int get _lo => widget.isMetric ? widget.minMetric : (widget.isHeight ? OnbUnits.cmToIn(widget.minMetric) : OnbUnits.kgToLb(widget.minMetric));
  int get _hi => widget.isMetric ? widget.maxMetric : (widget.isHeight ? OnbUnits.cmToIn(widget.maxMetric) : OnbUnits.kgToLb(widget.maxMetric));

  int _fromMetric(int m) => widget.isMetric ? m : (widget.isHeight ? OnbUnits.cmToIn(m) : OnbUnits.kgToLb(m));
  int _toMetric(int v) => widget.isMetric ? v : (widget.isHeight ? OnbUnits.inToCm(v) : OnbUnits.lbToKg(v));

  String _label(int v) => (!widget.isMetric && widget.isHeight) ? "${v ~/ 12}'${v % 12}" : '$v';

  @override
  Widget build(BuildContext context) {
    final shown = _fromMetric(widget.valueMetric);
    final unit = widget.isMetric ? (widget.isHeight ? 'cm' : 'kg') : (widget.isHeight ? 'ft in' : 'lb');
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            RollingNumber(_label(shown),
                style: OnbText.display(context, 21, letterSpacingEm: -0.045, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            SizedBox(width: context.vw(1.8)),
            Text(unit, style: OnbText.display(context, 5, weight: FontWeight.w600, color: OnbColors.mute, letterSpacingEm: 0)),
          ],
        ),
        SizedBox(height: context.vh(2)),
        _RulerTrack(
          key: ValueKey('${widget.isMetric}-${widget.isHeight}'),
          lo: _lo,
          hi: _hi,
          value: shown,
          isHeight: widget.isHeight,
          imperial: !widget.isMetric,
          onChanged: (v) => widget.onChanged(_toMetric(v)),
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
    Widget seg(String label, bool on, bool metric) => GestureDetector(
          onTap: () => onChanged(metric),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(horizontal: context.vw(3.4), vertical: context.vw(1.4)),
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

class _RulerTrack extends StatefulWidget {
  const _RulerTrack(
      {super.key, required this.lo, required this.hi, required this.value, required this.isHeight, required this.imperial, required this.onChanged});
  final int lo;
  final int hi;
  final int value;
  final bool isHeight;
  final bool imperial;
  final ValueChanged<int> onChanged;

  @override
  State<_RulerTrack> createState() => _RulerTrackState();
}

class _RulerTrackState extends State<_RulerTrack> {
  PageController? _controller;
  double? _fraction;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickW = context.vw(3.2);
    final height = context.vw(17);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fraction = (tickW / constraints.maxWidth).clamp(0.01, 0.2);
        if (_controller == null || _fraction != fraction) {
          _controller?.dispose();
          _fraction = fraction;
          _controller = PageController(initialPage: (widget.value - widget.lo).clamp(0, widget.hi - widget.lo), viewportFraction: fraction);
        }
        final majorEvery = widget.imperial && widget.isHeight ? 12 : 10;
        final midEvery = widget.imperial && widget.isHeight ? 6 : 5;
        return Container(
          height: height,
          decoration: BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(4)), border: Border.all(color: OnbColors.line)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0, 0.16, 0.84, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.hi - widget.lo + 1,
                  onPageChanged: (i) {
                    HapticService.instance.selectionClick();
                    widget.onChanged(widget.lo + i);
                  },
                  itemBuilder: (context, i) {
                    final v = widget.lo + i;
                    final major = v % majorEvery == 0;
                    final mid = !major && v % midEvery == 0;
                    final h = major ? context.vw(8) : (mid ? context.vw(5.6) : context.vw(3.6));
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(width: major ? 1.5 : 1, height: h, color: OnbColors.ink.withValues(alpha: major ? 0.75 : (mid ? 0.4 : 0.22))),
                        SizedBox(height: context.vw(1)),
                        SizedBox(
                          height: context.vw(3.6),
                          child: major
                              ? OverflowBox(
                                  maxWidth: context.vw(12),
                                  child: Text(
                                    widget.imperial && widget.isHeight ? "${v ~/ 12}'" : '$v',
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
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: context.vw(5),
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: context.vw(2.6), height: context.vw(2.6), decoration: const BoxDecoration(color: OnbColors.acc, shape: BoxShape.circle)),
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
          ),
        );
      },
    );
  }
}
