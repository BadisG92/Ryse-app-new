import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../home_slots.dart';

/// Water, meals and the session, as three readouts that are also controls.
///
/// They belong to the home, where the day has to be readable in one glance
/// without scrolling; Nutrition shows the same facts at full length instead.
/// Tapping the water adds a glass, the meals open the journal's own flow, the
/// session opens whatever is planned.
class DayTiles extends StatelessWidget {
  const DayTiles({
    super.key,
    required this.lang,
    required this.waterL,
    required this.waterGoalL,
    required this.today,
    required this.shown,
    required this.onWater,
    required this.onWaterMore,
    required this.onMeals,
    required this.onSession,
  });

  final String lang;
  final double waterL;
  final double waterGoalL;
  final DaySlots today;

  /// False until the entry, so the water rises from empty.
  final bool shown;

  final VoidCallback onWater;
  final VoidCallback onWaterMore;
  final VoidCallback onMeals;
  final VoidCallback onSession;

  @override
  Widget build(BuildContext context) {
    final (mealsDone, mealsTotal) = HomeSlots.mealCount(today);
    final session = today.state(WeekSlot.sport);

    return Row(
      children: [
        Expanded(
          child: _WaterTile(
            lang: lang,
            litres: waterL,
            goal: waterGoalL,
            shown: shown,
            onTap: onWater,
            onLongPress: onWaterMore,
          ),
        ),
        SizedBox(width: context.vw(2.6)),
        Expanded(
          child: _Tile(
            onTap: onMeals,
            top: Row(
              children: [
                for (final slot in kFoodSlots)
                  if (slot != WeekSlot.snack || today.state(slot) != SlotState.empty)
                    Padding(padding: const EdgeInsets.only(right: 4), child: _MiniMark(state: today.state(slot), round: false)),
              ],
            ),
            value: '$mealsDone',
            unit: 'home_meals_of'.tr(lang).replaceAll('{n}', '$mealsTotal'),
          ),
        ),
        SizedBox(width: context.vw(2.6)),
        Expanded(
          child: _Tile(
            onTap: onSession,
            top: _MiniMark(state: session, round: true),
            value: session == SlotState.empty ? 'home_session_none'.tr(lang) : (today.labels[WeekSlot.sport] ?? 'home_session'.tr(lang)),
            unit: switch (session) {
              SlotState.done => 'home_session_done'.tr(lang),
              SlotState.planned || SlotState.incoming => 'home_session_planned'.tr(lang),
              SlotState.empty => '',
            },
            done: session == SlotState.done,
          ),
        ),
      ],
    );
  }
}

/// A readout the user can press: a white surface, a light edge, a value under
/// its mark.
class _Tile extends StatelessWidget {
  const _Tile({required this.top, required this.value, required this.unit, required this.onTap, this.done = false, this.onLongPress, this.overlay});

  final Widget top;
  final String value;
  final String unit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool done;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final fg = done ? RyzeColors.surf : RyzeColors.ink;
    final fg2 = done ? RyzeColors.surf.withValues(alpha: 0.75) : RyzeColors.mute;
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        height: context.vw(17),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: done ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: done ? RyzeColors.ink : RyzeColors.line),
        ),
        child: Stack(
          children: [
            if (overlay != null) overlay!,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(2.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconTheme(data: IconThemeData(color: fg, size: 18), child: top),
                  Text.rich(
                    TextSpan(
                      style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      children: [
                        TextSpan(text: value),
                        if (unit.isNotEmpty) TextSpan(text: ' $unit', style: RyzeText.body(context, 3.2, weight: FontWeight.w500, color: fg2)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// The water is a glass: the level rises from the bottom as a tint, and the
/// whole tile turns to ink when the goal is met. The tint has no rule along
/// its top, which would strike through the value at some levels.
class _WaterTile extends StatelessWidget {
  const _WaterTile({required this.lang, required this.litres, required this.goal, required this.shown, required this.onTap, required this.onLongPress});

  final String lang;
  final double litres;
  final double goal;
  final bool shown;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final level = goal > 0 ? (litres / goal).clamp(0.0, 1.0) : 0.0;
    final full = level >= 1;
    final n = NumberFormat.decimalPattern(lang)..maximumFractionDigits = 2;
    return _Tile(
      onTap: onTap,
      onLongPress: onLongPress,
      done: full,
      top: const Icon(LucideIcons.droplet),
      value: n.format(litres),
      unit: 'home_water_of'.tr(lang).replaceAll('{n}', n.format(goal)),
      overlay: full
          ? null
          : Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: RyzeDurations.fill,
                curve: RyzeCurves.out,
                height: shown ? context.vw(17) * level : 0,
                color: RyzeColors.ink.withValues(alpha: 0.13),
              ),
            ),
    );
  }
}

/// The strip's three states at 10 pt: a square for a meal, a ring for the
/// session. Free is light grey, planned is white with an ink edge, done is ink.
class _MiniMark extends StatelessWidget {
  const _MiniMark({required this.state, required this.round});

  final SlotState state;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final done = state == SlotState.done;
    final drawn = state == SlotState.planned || state == SlotState.incoming;
    return AnimatedContainer(
      duration: RyzeDurations.tap,
      curve: RyzeCurves.out,
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : (drawn ? RyzeColors.surf : RyzeColors.idle),
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(2),
        border: drawn ? Border.all(color: RyzeColors.ink, width: 1.4) : null,
      ),
    );
  }
}
