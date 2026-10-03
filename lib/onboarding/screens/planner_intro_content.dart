import 'package:flutter/material.dart';

import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// Ce que fait le planificateur, juste avant d'y entrer.
///
/// Après le compte et la carte du chapitre 3, on tombait directement dans un
/// chat sans savoir à quoi il servait. Trois temps, dans l'ordre où ils
/// arrivent : on dit ce qu'on veut, les coachs construisent la semaine sur
/// son propre cap calorique, on valide ou on ajuste. Les numéros disent un
/// vrai ordre, pas un décor.
class PlannerIntroContent extends StatelessWidget {
  const PlannerIntroContent({super.key, required this.s, required this.kcal});
  final OnbStrings s;
  final int kcal;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (s.t('pi_1_t'), s.t('pi_1_s')),
      (s.t('pi_2_t'), s.t('pi_2_s', {'kcal': '$kcal'})),
      (s.t('pi_3_t'), s.t('pi_3_s')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) SizedBox(height: context.vw(5)),
          PopIn(
            delay: Duration(milliseconds: 320 + i * 90),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.vw(9),
                  height: context.vw(9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: OnbColors.surf, shape: BoxShape.circle, border: Border.all(color: OnbColors.line)),
                  child: Text('${i + 1}', style: OnbText.display(context, 4.2, height: 1)),
                ),
                SizedBox(width: context.vw(3.6)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.vw(0.6)),
                      Text(steps[i].$1, style: OnbText.body(context, 4.2, weight: FontWeight.w600, height: 1.25)),
                      SizedBox(height: context.vw(1)),
                      Text(steps[i].$2, style: OnbText.body(context, 3.7, color: OnbColors.mute, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
