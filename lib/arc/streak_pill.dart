import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../services/translations.dart';
import 'arc_state.dart';
import 'winter_flame.dart';

/// La pastille de série de l'accueil et de la Progression.
///
/// Elles étaient deux copies identiques ; elles n'en font plus qu'une, parce
/// que pendant le Winter Arc la série change de visage : la flamme de glace
/// animée sur un fond givré, au lieu de la flamme ambre.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.lang, required this.streak, this.onTap, this.winter});

  final String lang;
  final int streak;

  /// Pendant la saison, la pastille ouvre l'arc.
  final VoidCallback? onTap;

  /// Forcé dans les tests ; sinon, la saison du jour.
  final bool? winter;

  @override
  Widget build(BuildContext context) {
    final winter = this.winter ?? ArcSeason.isOpen(DateTime.now());
    final ink = winter ? ArcIce.pillInk : RyzeColors.accInk;
    final unit = (streak == 1 ? 'day' : 'days').tr(lang);
    final pill = Container(
      padding: EdgeInsets.fromLTRB(context.vw(2.3), context.vw(1.5), context.vw(2.8), context.vw(1.5)),
      decoration: BoxDecoration(color: winter ? ArcIce.pill : RyzeColors.accTint, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (winter) const WinterFlame(size: 16) else Icon(LucideIcons.flame, size: 14, color: ink),
          SizedBox(width: context.vw(1.2)),
          Text(
            '$streak $unit',
            style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
    return onTap == null ? pill : Pressable(onTap: onTap, child: pill);
  }
}
