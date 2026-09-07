import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// Ce qu'il reste de la journée, quand le grand chiffre est sorti de l'écran.
///
/// On descend dans ses repas pour décider quoi manger, et c'est exactement là
/// que le total cesse d'être visible. Cette barre le ramène : une ligne, le
/// chiffre, et la jauge réduite à deux points d'épaisseur. Elle ne se montre
/// qu'une fois l'instrument dépassé, sans quoi elle dirait deux fois la même
/// chose à quelques centimètres d'écart.
class StickyTotal extends StatelessWidget {
  const StickyTotal({
    super.key,
    required this.shown,
    required this.lead,
    required this.value,
    required this.unit,
    required this.fraction,
  });

  /// Vrai quand l'instrument a quitté le haut de l'écran.
  final bool shown;

  final String lead;
  final String value;
  final String unit;

  /// Part de l'objectif déjà mangée, de 0 à 1.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, -1),
        duration: RyzeDurations.enter,
        curve: RyzeCurves.out,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: RyzeDurations.tap,
          curve: RyzeCurves.out,
          child: Container(
            padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(2.3), context.vw(5.1), context.vw(2.3)),
            decoration: BoxDecoration(
              color: RyzeColors.paper,
              border: const Border(bottom: BorderSide(color: RyzeColors.line)),
              boxShadow: [
                BoxShadow(
                  color: RyzeColors.ink.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lead,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RyzeText.body(context, 3.3, color: RyzeColors.mute),
                      ),
                    ),
                    SizedBox(width: context.vw(2.6)),
                    Text.rich(
                      TextSpan(
                        style: RyzeText.body(context, 4.1, weight: FontWeight.w600).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(text: value),
                          TextSpan(text: ' $unit', style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.vw(1.8)),
                SizedBox(
                  height: 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(2)),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: AnimatedContainer(
                          duration: RyzeDurations.fill,
                          curve: RyzeCurves.out,
                          decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
