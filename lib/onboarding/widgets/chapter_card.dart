import 'package:flutter/material.dart';

import '../onboarding_theme.dart';
import 'onb_widgets.dart';

/// Full-screen ink curtain announcing a chapter, then leaving by the top.
class ChapterCard extends StatefulWidget {
  const ChapterCard({super.key, required this.number, required this.title, required this.subtitle, required this.onDone});
  final String number;
  final String title;
  final String subtitle;
  final VoidCallback onDone;

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));
  late final Animation<double> _in = CurvedAnimation(parent: _c, curve: const Interval(0, 0.24, curve: OnbCurves.snap));
  late final Animation<double> _out = CurvedAnimation(parent: _c, curve: const Interval(0.78, 1, curve: OnbCurves.snap));
  late final Animation<double> _bar = CurvedAnimation(parent: _c, curve: const Interval(0.22, 0.7, curve: OnbCurves.out));
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_fired) {
        _fired = true;
        widget.onDone();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final visibleFactor = (_in.value - _out.value).clamp(0.0, 1.0);
        return ClipRect(
          child: Align(
            // enters from the bottom, exits by the top
            alignment: _out.value > 0 ? Alignment.topCenter : Alignment.bottomCenter,
            heightFactor: visibleFactor,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height,
              width: double.infinity,
              child: ColoredBox(
                color: OnbColors.ink,
                child: Stack(
                  children: [
                    Positioned(
                      right: -context.vw(2),
                      top: context.vh(6),
                      child: Opacity(
                        opacity: (_in.value * 0.06).clamp(0.0, 0.06),
                        child: Text(widget.number,
                            style: OnbText.display(context, 52, weight: FontWeight.w900, color: Colors.white, height: 1, letterSpacingEm: -0.06)),
                      ),
                    ),
                    Positioned(
                      left: context.vw(7),
                      right: context.vw(7),
                      bottom: context.vh(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WipeText(
                            widget.title.toUpperCase(),
                            delay: const Duration(milliseconds: 420),
                            style: OnbText.display(context, 17, weight: FontWeight.w900, color: Colors.white, height: 0.92, letterSpacingEm: -0.02),
                          ),
                          SizedBox(height: context.vh(2.4)),
                          PopIn(
                            delay: const Duration(milliseconds: 850),
                            dy: 8,
                            child: Text(widget.subtitle, style: OnbText.body(context, 4, color: Colors.white.withValues(alpha: 0.65))),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: context.vw(7),
                      bottom: context.vh(7.4),
                      child: Container(
                        width: context.vw(20) * _bar.value,
                        height: context.vw(0.9),
                        decoration: BoxDecoration(color: OnbColors.acc, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
