import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// Body of the first screen: what Ryze does, and why it is different.
class HelloContent extends StatelessWidget {
  const HelloContent({super.key, required this.s});
  final OnbStrings s;

  @override
  Widget build(BuildContext context) {
    final facts = [
      (LucideIcons.calendar, s.t('hello_f1')),
      (LucideIcons.dumbbell, s.t('hello_f2')),
      (LucideIcons.scanLine, s.t('hello_f3')),
      (LucideIcons.brain, s.t('hello_f4')),
      (LucideIcons.clock, s.t('hello_f5')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PopIn(
          delay: const Duration(milliseconds: 250),
          child: Row(
            children: [
              const CoachAvatar(OnbAssets.sportAvatar, sizeVw: 14),
              Transform.translate(offset: Offset(-context.vw(4), 0), child: const CoachAvatar(OnbAssets.nutriAvatar, sizeVw: 14)),
            ],
          ),
        ),
        SizedBox(height: context.vh(2.4)),
        PopIn(
          delay: const Duration(milliseconds: 350),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${s.t('hello_punch1')}\n'),
              TextSpan(text: s.t('hello_punch2'), style: const TextStyle(color: OnbColors.accInk)),
            ]),
            style: OnbText.display(context, 5.2, height: 1.15, letterSpacingEm: -0.02),
          ),
        ),
        SizedBox(height: context.vh(2.4)),
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) SizedBox(height: context.vw(1.6)),
          PopIn(
            delay: Duration(milliseconds: 400 + i * 70),
            child: Row(
              children: [
                Container(
                  width: context.vw(7.6),
                  height: context.vw(7.6),
                  decoration:
                      BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(2.4)), border: Border.all(color: OnbColors.line)),
                  child: Icon(facts[i].$1, size: context.vw(3.8), color: OnbColors.ink),
                ),
                SizedBox(width: context.vw(2.6)),
                Expanded(child: Text(facts[i].$2, style: OnbText.body(context, 3.4, height: 1.3))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
