import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../services/translations.dart';
import 'arc_state.dart';
import 'winter_flame.dart';

/// Les flammes de l'accueil et de la Progression.
///
/// Deux séries vivent côte à côte pendant le Winter Arc : la flamme normale
/// (une activité par jour, sa règle de toujours) et la flamme de glace de
/// l'arc (deux repas et l'eau). La normale n'est montrée pendant la saison
/// que si elle existait déjà avant le 1er octobre : on ne retire pas à
/// quelqu'un la série qu'il tenait, mais on n'en fait pas naître une seconde
/// à côté de l'arc.
class StreakPills extends StatelessWidget {
  const StreakPills({
    super.key,
    required this.lang,
    required this.streak,
    this.streakStart,
    this.arc,
    this.onArcTap,
    this.today,
  });

  final String lang;

  /// La flamme normale.
  final int streak;
  final DateTime? streakStart;

  /// L'arc, s'il est connu ; sinon la saison se déduit de la date.
  final ArcState? arc;

  /// Toucher la flamme de glace ouvre l'arc.
  final VoidCallback? onArcTap;

  /// Fixée dans les tests ; sinon aujourd'hui.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final season = arc != null ? arc!.isOpen : ArcSeason.isOpen(now);
    final hadBefore = streakStart != null && streakStart!.isBefore(ArcSeason.opens);
    final showNormal = streak > 0 && (!season || hadBefore);
    final arcStreak = arc?.streak ?? 0;
    final both = showNormal && season;

    String label(int n) => both ? '$n' : '$n ${(n == 1 ? 'day' : 'days').tr(lang)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNormal)
          _Pill(
            fill: RyzeColors.accTint,
            ink: RyzeColors.accInk,
            icon: Icon(LucideIcons.flame, size: 14, color: RyzeColors.accInk),
            text: label(streak),
          ),
        if (both) SizedBox(width: context.vw(1.5)),
        if (season)
          Pressable(
            onTap: onArcTap,
            child: _Pill(
              fill: ArcIce.pill,
              ink: ArcIce.pillInk,
              icon: const WinterFlame(size: 16),
              text: arcStreak > 0 ? label(arcStreak) : null,
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.fill, required this.ink, required this.icon, this.text});

  final Color fill;
  final Color ink;
  final Widget icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(2.3), context.vw(1.5), context.vw(text == null ? 2.3 : 2.8), context.vw(1.5)),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (text != null) ...[
            SizedBox(width: context.vw(1.2)),
            Text(
              text!,
              style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ],
      ),
    );
  }
}
