import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared motion primitives, used by the onboarding and the planner chat.

const Curve kMotionSpring = Cubic(0.22, 1.12, 0.3, 1.02);
const Curve kMotionOut = Cubic(0.2, 0.7, 0.2, 1);

/// Staggered entrance: fade + rise + slight scale, spring curve.
/// With `animate: false` the child renders at rest immediately (used for
/// list items that were already on screen).
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.dy = 18,
    this.animate = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;
  final bool animate;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: kMotionSpring);

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final t = _a.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Three dots rising one after the other: "the coach is typing".
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, this.color = const Color(0xFF0B132B), this.size = 6, this.gap = 4});
  final Color color;
  final double size;
  final double gap;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              Builder(builder: (context) {
                final phase = ((_c.value - i * 0.15) % 1.0).clamp(0.0, 1.0);
                final lift = math.sin(phase * math.pi) * widget.size * 0.9;
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: Opacity(
                    opacity: 0.45 + 0.55 * math.sin(phase * math.pi),
                    child: Container(width: widget.size, height: widget.size, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

/// Text that slides up and fades when its content changes (counters, subtitles).
class SlideSwapText extends StatelessWidget {
  const SlideSwapText({super.key, required this.text, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: kMotionOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim), child: child),
      ),
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, if (current != null) current]),
      child: Text(text, key: ValueKey(text), style: style, textAlign: textAlign),
    );
  }
}
