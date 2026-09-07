import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// L'eau du jour, sur toute la largeur : un relevé qui est aussi le seul
/// geste de l'accueil qui écrit sans rien ouvrir.
///
/// Il y avait trois tuiles ici — eau, repas, séance. Les deux dernières
/// redisaient la rangée du jour juste au-dessus, qui porte déjà un créneau
/// par repas et la séance, chacun tappable vers sa propre feuille : le
/// compte « 2 sur 4 » n'ajoutait rien à quatre pastilles qui disent
/// lesquels, et la séance était dessinée une deuxième fois. L'eau, elle,
/// n'est nulle part ailleurs sur cette page, et c'est le geste le plus
/// répété de la journée. Elle reste, seule, et prend la place des trois.
class WaterTile extends StatelessWidget {
  const WaterTile({
    super.key,
    required this.lang,
    required this.litres,
    required this.goal,
    required this.shown,
    required this.onTap,
    required this.onMore,
  });

  final String lang;
  final double litres;
  final double goal;

  /// Faux jusqu'à l'entrée de la page, pour que le niveau monte de zéro.
  final bool shown;

  /// Un tap : un verre de plus. Un appui long : une autre quantité.
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final level = goal > 0 ? (litres / goal).clamp(0.0, 1.0) : 0.0;
    final full = level >= 1;
    final n = NumberFormat.decimalPattern(lang)..maximumFractionDigits = 2;
    final fg = full ? RyzeColors.surf : RyzeColors.ink;
    final fg2 = full ? RyzeColors.surf.withValues(alpha: 0.75) : RyzeColors.mute;
    final height = context.vw(17);

    return Pressable(
      onTap: onTap,
      onLongPress: onMore,
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: full ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: full ? RyzeColors.ink : RyzeColors.line),
        ),
        child: Stack(
          children: [
            // Le niveau monte sur toute la largeur. Pas de trait sur son bord
            // haut, qui barrerait la valeur à certaines hauteurs.
            if (!full)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: RyzeDurations.fill,
                  curve: RyzeCurves.out,
                  height: shown ? height * level : 0,
                  color: RyzeColors.ink.withValues(alpha: 0.13),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.3)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(LucideIcons.droplet, size: 18, color: fg),
                        Text.rich(
                          TextSpan(
                            style: RyzeText.body(context, 4.1, weight: FontWeight.w600, color: fg)
                                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            children: [
                              TextSpan(text: n.format(litres)),
                              TextSpan(
                                text: ' ${'home_water_of'.tr(lang).replaceAll('{n}', n.format(goal))}',
                                style: RyzeText.body(context, 3.4, weight: FontWeight.w500, color: fg2),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!full)
                    Text(
                      'home_water_add'.tr(lang),
                      style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
