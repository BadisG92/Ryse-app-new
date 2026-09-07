import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// The planner's week band on the home: the seven chips with their marks.
///
/// Today's own slots used to hang below it; they now sit under the instrument,
/// where the day they describe is still the subject. Tapping the band opens
/// the planner.
class HomeWeek extends StatefulWidget {
  const HomeWeek({
    super.key,
    required this.lang,
    required this.days,
    required this.slots,
    required this.onOpenPlanner,
  });

  final String lang;
  final List<DateTime> days;
  final List<DaySlots> slots;
  final VoidCallback onOpenPlanner;

  @override
  State<HomeWeek> createState() => _HomeWeekState();
}

class _HomeWeekState extends State<HomeWeek> {
  // the strip anchors every mark for the planner's landing flights; the home
  // flies nothing, but the keys must stay stable across rebuilds
  final Map<String, GlobalKey> _keys = {};
  GlobalKey _key(int day, WeekSlot slot) => _keys.putIfAbsent('$day-${slot.name}', GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
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
      ],
    );
  }
}
