import 'package:flutter/material.dart';

export '../components/ui/motion.dart' show PopIn, TypingDots, SlideSwapText;

/// Motion of the system. Three curves and a handful of durations; everything
/// else is a combination of them.
///
/// - `out` is the workhorse: fast start, soft landing. Page slides, fills,
///   the flight of a mark to its day, the odometer.
/// - `spring` overshoots a little: entrances of cards and the pop of a slot
///   taking an impact. Reserved for things that arrive, never for text.
/// - `snap` eases both ends: curtains and chapter cards.
///
/// Rules the onboarding settled:
/// - one orchestrated reveal per screen, not an effect on every element
/// - a fill that the user must read is at least 480 ms, and the screen waits
///   for it (plus a beat) before turning: 780 ms from tap to page change
/// - continuous animations (sheen, pulse, odometer) live in their own
///   repaint boundary
/// - a value that changes mid-animation retargets from where it is; it never
///   restarts from zero
class RyzeCurves {
  RyzeCurves._();

  static const Curve spring = Cubic(0.22, 1.12, 0.3, 1.02);
  static const Curve out = Cubic(0.2, 0.7, 0.2, 1);
  static const Curve snap = Cubic(0.7, 0, 0.2, 1);
}

class RyzeDurations {
  RyzeDurations._();

  /// A control reacting under the finger.
  static const Duration tap = Duration(milliseconds: 220);

  /// An entrance (PopIn) or a mark landing.
  static const Duration enter = Duration(milliseconds: 420);

  /// A fill the user must be able to read (the ink wipe of a choice).
  static const Duration fill = Duration(milliseconds: 480);

  /// The flight of a validated item to its day.
  static const Duration flight = Duration(milliseconds: 620);

  /// From a choice to the next screen: the fill plus a beat.
  static const Duration advance = Duration(milliseconds: 780);

  /// A chapter curtain; a tap skips it.
  static const Duration curtain = Duration(milliseconds: 1700);
}

/// A control reacting under the finger: it sinks a little while pressed and
/// springs back on release, the way OnbButton does. Wrap anything tappable
/// that is not a button; it is announced as one.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? 0.975 : 1,
          duration: const Duration(milliseconds: 180),
          curve: RyzeCurves.spring,
          child: widget.child,
        ),
      ),
    );
  }
}
