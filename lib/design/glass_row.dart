import 'package:flutter/material.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// The day's water, as glasses you fill and empty with a tap.
///
/// One glass is 250 ml, so the goal decides how many are drawn. Tapping the
/// next empty one adds a glass; tapping a full one brings the level back to
/// just under it, which is the only way the app has ever offered to correct a
/// mistake. A long press on the dashed glass asks for another amount.
class GlassRow extends StatelessWidget {
  const GlassRow({
    super.key,
    required this.litres,
    required this.goalLitres,
    required this.shown,
    required this.onSet,
    this.onOther,
  });

  final double litres;
  final double goalLitres;

  /// False before the entry, so the glasses fill from empty.
  final bool shown;

  /// Asked for a new level, in glasses. Zero empties the day. Null makes the
  /// row a reading only, which is how a past day is shown.
  final ValueChanged<int>? onSet;

  /// Long press on the dashed glass.
  final VoidCallback? onOther;

  static const double glassLitres = 0.25;

  @override
  Widget build(BuildContext context) {
    final goal = goalLitres > 0 ? (goalLitres / glassLitres).round().clamp(4, 12) : 8;
    final full = shown ? (litres / glassLitres).floor().clamp(0, goal) : 0;

    return Row(
      children: [
        for (var i = 0; i < goal; i++) ...[
          if (i > 0) SizedBox(width: context.vw(1.8)),
          Expanded(
            child: _Glass(
              filled: i < full,
              next: i == full,
              onTap: () {
                final set = onSet;
                if (set == null) return;
                if (i < full) {
                  RyzeFeedback.removed();
                  set(i);
                } else {
                  final level = i + 1;
                  if (level >= goal) {
                    RyzeFeedback.success();
                  } else {
                    RyzeFeedback.tap();
                  }
                  set(level);
                }
              },
              onLongPress: i == full ? onOther : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _Glass extends StatefulWidget {
  const _Glass({required this.filled, required this.next, required this.onTap, this.onLongPress});

  final bool filled;
  final bool next;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_Glass> createState() => _GlassState();
}

class _GlassState extends State<_Glass> {
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
          scale: _down ? 0.93 : 1,
          duration: RyzeDurations.tap,
          curve: RyzeCurves.spring,
          child: Container(
            height: context.vw(11.3),
            clipBehavior: Clip.antiAlias,
            // a glass: square shoulders, rounded foot
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(RyzeRadius.xs), bottom: Radius.circular(11)),
              border: Border.all(
                color: widget.filled ? RyzeColors.ink : (widget.next ? RyzeColors.mute2 : RyzeColors.line),
                width: 1.4,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: RyzeDurations.fill,
                  curve: RyzeCurves.out,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: widget.filled ? context.vw(11.3) : 0,
                  child: const ColoredBox(color: RyzeColors.ink),
                ),
                if (widget.next)
                  Center(
                    child: Icon(Icons.add_rounded, size: context.vw(4.4), color: RyzeColors.mute2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
