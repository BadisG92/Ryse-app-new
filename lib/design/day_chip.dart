import 'package:flutter/material.dart';

import '../services/ryze_dates.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// Un jour d'une bande d'historique : sa lettre, son numéro, et sa marque.
///
/// La même carte dans Nutrition et dans Sport. Seule la marque du dessous
/// change — la jauge du jour d'un côté, ce qui a été fait de l'autre — parce
/// que c'est la seule chose qui diffère vraiment d'un onglet à l'autre. Les
/// deux bandes avaient dérivé : l'une posait ses jours sur des cartes
/// blanches bordées, l'autre sur rien du tout, avec ses propres tailles et son
/// propre rayon. Une seule définition, et elles ne peuvent plus se séparer.
///
/// La hauteur vient de la bande qui la porte : dans une liste horizontale, la
/// contrainte de hauteur est stricte, donc la carte la remplit et son contenu
/// se centre. Compter [stripHeight] pour la hauteur de cette bande.
class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.day,
    required this.lang,
    required this.selected,
    required this.onTap,
    required this.marker,
  });

  final DateTime day;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  /// Sous le numéro, dans une case de hauteur fixe : ce que ce jour a tenu.
  final Widget marker;

  /// La hauteur de la bande qui porte ces cartes, dans les deux onglets.
  static double stripHeight(BuildContext context) => context.vw(19);

  /// La largeur d'une carte, et l'écart entre deux.
  static double width(BuildContext context) => context.vw(13);
  static double gap(BuildContext context) => context.vw(2.1);

  /// La case de la marque. Fixe, pour que deux jours fassent la même hauteur
  /// quoi qu'ils portent.
  static double markerBox(BuildContext context) => context.vw(3.1);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        width: width(context),
        padding: EdgeInsets.symmetric(vertical: context.vw(2.1)),
        decoration: BoxDecoration(
          color: selected ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: selected ? RyzeColors.ink : RyzeColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              RyzeDates.short(day, lang),
              style: RyzeText.body(context, 2.6, weight: FontWeight.w600, color: selected ? RyzeColors.surf.withValues(alpha: 0.7) : RyzeColors.mute2),
            ),
            SizedBox(height: context.vw(0.8)),
            Text(
              '${day.day}',
              style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: selected ? RyzeColors.surf : RyzeColors.ink)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            SizedBox(height: context.vw(1.5)),
            SizedBox(height: markerBox(context), child: Center(child: marker)),
          ],
        ),
      ),
    );
  }
}
