import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// La semaine du planificateur sur l'accueil : les sept jours et leurs
/// marques, et « Planifier » à droite.
///
/// La bande se déplie. Tout la touchait — les jours, la poignée du bas —
/// ouvrait le chat des repas, donc il n'existait aucun moyen de *regarder* la
/// semaine ni de toucher un autre jour qu'aujourd'hui. Un tap la déplie
/// maintenant et montre ce qui est prévu chaque jour ; un tap sur un créneau
/// dit à l'accueil quel jour et quel créneau, et c'est lui qui décide où
/// mener. « Planifier » reste le bouton, et il demande d'abord de quoi on
/// parle : les repas ou les séances.
class HomeWeek extends StatefulWidget {
  const HomeWeek({
    super.key,
    required this.lang,
    required this.days,
    required this.slots,
    required this.onOpenPlanner,
    required this.onSlotTap,
    required this.onEmptyDayTap,
  });

  final String lang;
  final List<DateTime> days;
  final List<DaySlots> slots;

  /// Le bouton « Planifier » : la feuille qui demande repas ou séances.
  final VoidCallback onOpenPlanner;

  /// Un créneau d'un jour donné, une fois la bande dépliée.
  final void Function(DateTime day, WeekSlot slot) onSlotTap;

  /// Un jour dont rien n'est prévu : la pastille en pointillés.
  final ValueChanged<DateTime> onEmptyDayTap;

  @override
  State<HomeWeek> createState() => _HomeWeekState();
}

class _HomeWeekState extends State<HomeWeek> {
  // the strip anchors every mark for the planner's landing flights; the home
  // flies nothing, but the keys must stay stable across rebuilds
  final Map<String, GlobalKey> _keys = {};
  GlobalKey _key(int day, WeekSlot slot) => _keys.putIfAbsent('$day-${slot.name}', GlobalKey.new);

  bool _expanded = false;

  void _toggle() {
    RyzeFeedback.tap();
    setState(() => _expanded = !_expanded);
  }

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
            expanded: _expanded,
            onToggle: _toggle,
            slotKey: _key,
            onSlotTap: (index, slot) => widget.onSlotTap(widget.days[index], slot),
            onEmptyTap: (index) => widget.onEmptyDayTap(widget.days[index]),
          ),
        ),
      ],
    );
  }
}
