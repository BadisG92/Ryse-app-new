import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// One macro nutrient: a name, a rail, and how far it is of its goal.
///
/// The rail is ink on light grey, like every other fill in the system. The
/// three of them are stacked and named, so they need no colour to be told
/// apart, and amber stays what it has always been: the calorie gauge above.
class MacroRail extends StatelessWidget {
  const MacroRail({super.key, required this.label, required this.value, required this.goal, required this.shown});

  final String label;
  final double value;
  final int goal;

  /// False before the entry, so the rails fill from empty.
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final fraction = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.3)),
      child: Row(
        children: [
          SizedBox(
            width: context.vw(16),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: RyzeColors.mute)),
          ),
          SizedBox(width: context.vw(2.6)),
          Expanded(
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill))),
                  FractionallySizedBox(
                    widthFactor: shown ? fraction : 0,
                    heightFactor: 1,
                    child: AnimatedContainer(
                      duration: RyzeDurations.fill,
                      curve: RyzeCurves.spring,
                      decoration: BoxDecoration(color: RyzeColors.ink, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: context.vw(2.6)),
          SizedBox(
            width: context.vw(20),
            child: Text.rich(
              TextSpan(
                style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                children: [
                  TextSpan(text: '${value.round()}', style: RyzeText.body(context, 3.1, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  TextSpan(text: ' / $goal g'),
                ],
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
