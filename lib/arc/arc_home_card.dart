import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../services/translations.dart';
import 'arc_grid.dart';
import 'arc_page.dart';
import 'arc_state.dart';
import 'arc_words.dart';
import 'winter_flame.dart';

/// L'arc sur l'accueil : le jour, ce qui manque, et les 90 carrés en trois
/// lignes. Un tap ouvre l'écran de l'arc.
class ArcHomeCard extends StatelessWidget {
  const ArcHomeCard({super.key, required this.state, required this.lang});

  final ArcState state;
  final String lang;

  String _status() {
    final s = state;
    if (s.isSoon) return 'arc_card_soon'.tr(lang).replaceAll('{date}', ArcWords.date(ArcSeason.opens, lang));
    if (s.won) return 'arc_card_won'.tr(lang);
    final today = s.todayStatus;
    if (today == null || today.held) return 'arc_card_held'.tr(lang);
    final missing = ArcWords.missing(meals: today.mealsMissing, waterMl: today.waterMissingMl, lang: lang);
    return 'arc_card_missing'.tr(lang).replaceAll('{missing}', missing);
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final title = s.isSoon
        ? 'arc_name'.tr(lang)
        : (s.streak == 0 && !s.todayHeld ? 'arc_card_start'.tr(lang) : 'arc_day_of'.tr(lang).replaceAll('{n}', '${s.won ? ArcSeason.length : s.dayNumber}'));
    final held = s.todayHeld || s.won;
    return Pressable(
      onTap: () => openArcPage(context),
      child: Container(
        padding: EdgeInsets.all(context.vw(4.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                WinterFlame(size: context.vw(4.6)),
                SizedBox(width: context.vw(1.3)),
                Text(
                  'arc_name'.tr(lang).toUpperCase(),
                  style: RyzeText.body(context, 2.9, weight: FontWeight.w700, color: ArcIce.pillInk).copyWith(letterSpacing: 1.2),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: context.vw(4.1), color: RyzeColors.mute2),
              ],
            ),
            SizedBox(height: context.vw(1.5)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.display(context, 6.2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                SizedBox(width: context.vw(2)),
                Flexible(
                  child: Text(
                    _status(),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: held ? RyzeColors.accInk : RyzeColors.mute),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.vw(3.1)),
            ArcGrid(cells: s.isSoon ? const [] : s.cells, columns: 30, gapFraction: 0.32, todayFirst: !s.isSoon),
          ],
        ),
      ),
    );
  }
}
