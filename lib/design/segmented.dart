import 'package:flutter/material.dart';

import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// Two or three pages of the same subject, side by side: the segmented control
/// of the system. The active position is a paper card that slides under the
/// labels, so the change reads as one object moving rather than two colours
/// swapping.
class RyzeSegmented extends StatelessWidget {
  const RyzeSegmented({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final height = context.vw(8.7);
    return Container(
      height: height + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: RyzeColors.paper2, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
      child: LayoutBuilder(
        builder: (context, c) {
          final slot = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: RyzeDurations.tap,
                curve: RyzeCurves.out,
                left: slot * index,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.pill),
                    boxShadow: RyzeShadow.soft,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i == index) return;
                          RyzeFeedback.select();
                          onChanged(i);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: RyzeDurations.tap,
                            curve: RyzeCurves.out,
                            style: RyzeText.body(
                              context,
                              3.4,
                              weight: FontWeight.w600,
                              color: i == index ? RyzeColors.ink : RyzeColors.mute,
                            ),
                            child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
