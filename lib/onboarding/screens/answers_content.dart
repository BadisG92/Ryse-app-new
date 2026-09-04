import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// "What made you quit, we planned for it": one row per chosen obstacle,
/// then the two-coaches card.
class AnswersContent extends StatelessWidget {
  const AnswersContent({super.key, required this.s, required this.obstacleKeys});
  final OnbStrings s;
  final List<String> obstacleKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < obstacleKeys.length; i++) ...[
          if (i > 0) SizedBox(height: context.vw(1.8)),
          PopIn(
            delay: Duration(milliseconds: 350 + i * 90),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.vw(3.4), vertical: context.vw(3)),
              decoration: BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(3.8)), border: Border.all(color: OnbColors.line)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.vw(6.4),
                    height: context.vw(6.4),
                    decoration: BoxDecoration(color: OnbColors.green.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Icon(LucideIcons.check, size: context.vw(3.2), color: OnbColors.green),
                  ),
                  SizedBox(width: context.vw(2.8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.t(obstacleKeys[i]), style: OnbText.body(context, 3, color: OnbColors.mute)),
                        SizedBox(height: context.vw(0.4)),
                        Text(s.t('${obstacleKeys[i]}_a'), style: OnbText.body(context, 3.4, weight: FontWeight.w500, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: context.vh(2)),
        PopIn(
          delay: Duration(milliseconds: 350 + obstacleKeys.length * 90 + 250),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.vw(3.8), vertical: context.vw(3.4)),
            decoration: BoxDecoration(color: OnbColors.ink, borderRadius: BorderRadius.circular(context.vw(4.2))),
            child: Row(
              children: [
                SizedBox(
                  width: context.vw(15),
                  height: context.vw(9),
                  child: Stack(
                    children: [
                      const CoachAvatar(OnbAssets.sportAvatar, sizeVw: 9),
                      Positioned(left: context.vw(6), child: const CoachAvatar(OnbAssets.nutriAvatar, sizeVw: 9)),
                    ],
                  ),
                ),
                SizedBox(width: context.vw(3)),
                Expanded(child: Text(s.t('duo_text'), style: OnbText.body(context, 3.4, color: Colors.white, height: 1.4))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
