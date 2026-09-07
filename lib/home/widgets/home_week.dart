import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// The planner's week band on the home: the seven chips with their marks,
/// and under them today's slots as tiles. The snack tile and mark exist only
/// on days that have a snack. Tapping the band opens the planner.
class HomeWeek extends StatefulWidget {
  const HomeWeek({
    super.key,
    required this.lang,
    required this.days,
    required this.slots,
    required this.onOpenPlanner,
    required this.onSlotTap,
  });

  final String lang;
  final List<DateTime> days;
  final List<DaySlots> slots;
  final VoidCallback onOpenPlanner;
  final void Function(WeekSlot slot) onSlotTap;

  @override
  State<HomeWeek> createState() => _HomeWeekState();
}

class _HomeWeekState extends State<HomeWeek> {
  // the strip anchors every mark for the planner's landing flights; the home
  // flies nothing, but the keys must stay stable across rebuilds
  final Map<String, GlobalKey> _keys = {};
  GlobalKey _key(int day, WeekSlot slot) => _keys.putIfAbsent('$day-${slot.name}', GlobalKey.new);

  /// Today's slots; empty when today is not in the band, never another day's.
  DaySlots get _today {
    final now = DateTime.now();
    final i = widget.days.indexWhere((d) => d.year == now.year && d.month == now.month && d.day == now.day);
    return i < 0 || i >= widget.slots.length ? const DaySlots() : widget.slots[i];
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final today = _today;
    final letters = 'day_letters'.tr(lang).split(',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('home_this_week'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenPlanner,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('home_plan'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                      const Icon(LucideIcons.chevronRight, size: 14, color: RyzeColors.ink),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.vw(0.6)),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: WeekStrip(
            days: widget.days,
            dayLetters: letters.length == widget.days.length ? letters : List.filled(widget.days.length, ''),
            slots: widget.slots,
            expanded: false,
            onToggle: widget.onOpenPlanner,
            slotKey: _key,
          ),
        ),
        SizedBox(height: context.vw(2)),
        Row(
          children: [
            for (final slot in WeekSlot.values)
              if (slot != WeekSlot.snack || today.state(slot) != SlotState.empty) ...[
                Expanded(
                  child: _TodaySlot(
                    slot: slot,
                    state: today.state(slot),
                    label: 'slot_${slot.name}'.tr(lang),
                    onTap: () => widget.onSlotTap(slot),
                  ),
                ),
                if (slot != WeekSlot.sport) SizedBox(width: context.vw(1.6)),
              ],
          ],
        ),
      ],
    );
  }
}

/// One of today's slots: planned is an ink edge, done an ink fill, and free
/// a white tile with a light edge, the invitation to fill it. The session is
/// a pill, a meal a tile.
class _TodaySlot extends StatelessWidget {
  const _TodaySlot({required this.slot, required this.state, required this.label, required this.onTap});
  final WeekSlot slot;
  final SlotState state;
  final String label;
  final VoidCallback onTap;

  static IconData _icon(WeekSlot s) => switch (s) {
        WeekSlot.breakfast => LucideIcons.sunrise,
        WeekSlot.lunch => LucideIcons.sun,
        WeekSlot.snack => LucideIcons.cookie,
        WeekSlot.dinner => LucideIcons.sunset,
        WeekSlot.sport => LucideIcons.dumbbell,
      };

  @override
  Widget build(BuildContext context) {
    final done = state == SlotState.done;
    final planned = state == SlotState.planned || state == SlotState.incoming;
    final fg = done ? RyzeColors.surf : (planned ? RyzeColors.ink : RyzeColors.mute);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: RyzeDurations.fill,
        curve: RyzeCurves.out,
        height: context.vw(12),
        decoration: BoxDecoration(
          color: done ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(slot == WeekSlot.sport ? RyzeRadius.pill : RyzeRadius.sm),
          border: Border.all(color: done || planned ? RyzeColors.ink : RyzeColors.line, width: planned && !done ? 1.4 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(done ? LucideIcons.check : _icon(slot), size: 16, color: fg),
            SizedBox(height: context.vw(0.6)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 2.7, weight: FontWeight.w600, color: fg, height: 1.1)),
          ],
        ),
      ),
    );
  }
}
