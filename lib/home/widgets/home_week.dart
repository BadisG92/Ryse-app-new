import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../home_slots.dart';

/// La semaine du planificateur sur l'accueil : les sept jours et leurs
/// marques, et « Planifier » à droite.
///
/// **Un jour touché s'ouvre en dessous.** La bande donne l'aperçu — sept
/// jours, leurs marques — mais une marque dit qu'il y a quelque chose, jamais
/// quoi ; et sept colonnes sur un téléphone ne laissent la place à aucun mot.
/// Le jour ouvert prend toute la largeur, une ligne par élément prévu, et on
/// lit enfin « Dîner · Saumon, riz · 620 kcal ». C'est ce qui remplace le
/// planificateur à la main, qui n'était branché nulle part.
///
/// Tout ce qui touchait la bande ouvrait auparavant le chat des repas : il n'y
/// avait donc aucun moyen de regarder sa semaine.
class HomeWeek extends StatefulWidget {
  const HomeWeek({
    super.key,
    required this.lang,
    required this.days,
    required this.slots,
    required this.lines,
    required this.onOpenPlanner,
    required this.onLineTap,
    required this.onPlanDay,
  });

  final String lang;
  final List<DateTime> days;
  final List<DaySlots> slots;

  /// Ce que chaque jour contient, dans l'ordre de la journée.
  final List<List<PlannedLine>> lines;

  /// Le bouton « Planifier » : la feuille qui demande repas ou séances.
  final VoidCallback onOpenPlanner;

  /// Une ligne du jour ouvert : sa feuille.
  final void Function(DateTime day, PlannedLine line) onLineTap;

  /// Un jour vide, ou la rangée « Ajouter » d'un jour ouvert.
  final ValueChanged<DateTime> onPlanDay;

  @override
  State<HomeWeek> createState() => _HomeWeekState();
}

class _HomeWeekState extends State<HomeWeek> {
  // the strip anchors every mark for the planner's landing flights; the home
  // flies nothing, but the keys must stay stable across rebuilds
  final Map<String, GlobalKey> _keys = {};
  GlobalKey _key(int day, WeekSlot slot) => _keys.putIfAbsent('$day-${slot.name}', GlobalKey.new);

  int? _open;

  /// L'index d'aujourd'hui dans la semaine affichée, ou null s'il n'y est pas.
  int? get _todayIndex {
    final now = DateTime.now();
    for (var i = 0; i < widget.days.length; i++) {
      final d = widget.days[i];
      if (d.year == now.year && d.month == now.month && d.day == now.day) return i;
    }
    return null;
  }

  void _tapDay(int index) {
    RyzeFeedback.select();
    setState(() => _open = _open == index ? null : index);
  }

  /// La poignée sous la bande : elle referme, ou ouvre aujourd'hui.
  void _toggle() {
    RyzeFeedback.tap();
    setState(() => _open = _open == null ? _todayIndex : null);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final letters = 'day_letters'.tr(lang).split(',');
    final open = _open;

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
                      Icon(LucideIcons.chevronRight, size: 14, color: RyzeColors.ink),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WeekStrip(
                days: widget.days,
                dayLetters: letters.length == widget.days.length ? letters : List.filled(widget.days.length, ''),
                slots: widget.slots,
                expanded: false,
                onToggle: _toggle,
                slotKey: _key,
                onDayTap: _tapDay,
                openDay: open,
              ),
              AnimatedSize(
                duration: RyzeDurations.enter,
                curve: RyzeCurves.out,
                alignment: Alignment.topCenter,
                child: open == null
                    ? const SizedBox(width: double.infinity)
                    : _DayPanel(
                        key: ValueKey(open),
                        lang: lang,
                        day: widget.days[open],
                        lines: widget.lines[open],
                        onLineTap: (line) => widget.onLineTap(widget.days[open], line),
                        onPlan: () => widget.onPlanDay(widget.days[open]),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le jour ouvert : sa date en petit, puis une ligne par élément prévu, et une
/// dernière rangée pour en ajouter un.
class _DayPanel extends StatelessWidget {
  const _DayPanel({
    super.key,
    required this.lang,
    required this.day,
    required this.lines,
    required this.onLineTap,
    required this.onPlan,
  });

  final String lang;
  final DateTime day;
  final List<PlannedLine> lines;
  final ValueChanged<PlannedLine> onLineTap;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.vw(3.6), context.vw(1), context.vw(3.6), context.vw(2.6)),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: RyzeColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.vw(2.6)),
          Text(
            RyzeDates.full(day, lang),
            style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute),
          ),
          SizedBox(height: context.vw(2.1)),
          for (final line in lines) _Line(lang: lang, line: line, onTap: () => onLineTap(line)),
          _Add(lang: lang, empty: lines.isEmpty, onTap: onPlan),
        ],
      ),
    );
  }
}

/// Une chose prévue : sa marque, son nom, son chiffre. Le sport porte un
/// anneau, la nourriture un carré — la règle du reste de l'application.
class _Line extends StatelessWidget {
  const _Line({required this.lang, required this.line, required this.onTap});

  final String lang;
  final PlannedLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = line.state == SlotState.done;
    final sport = line.slot == WeekSlot.sport;
    final size = context.vw(6.7);

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(1.8)),
        child: Row(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: done ? RyzeColors.ink : RyzeColors.surf,
                shape: sport ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: sport ? null : BorderRadius.circular(RyzeRadius.xs),
                border: Border.all(color: RyzeColors.ink, width: 1.4),
              ),
              child: Icon(
                done ? LucideIcons.check : iconForSlot(line.slot),
                size: context.vw(3.6),
                color: done ? RyzeColors.surf : RyzeColors.ink,
              ),
            ),
            SizedBox(width: context.vw(2.6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.4, weight: FontWeight.w600),
                  ),
                  Text(
                    line.detail.isEmpty ? 'slot_${line.slot.name}'.tr(lang) : '${'slot_${line.slot.name}'.tr(lang)} · ${line.detail}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 2.9, color: RyzeColors.mute),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: context.vw(4.1), color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}

/// La dernière rangée : planifier ce jour. Sur un jour vide c'est la seule, et
/// elle dit alors qu'il n'y a rien plutôt que de laisser un blanc.
class _Add extends StatelessWidget {
  const _Add({required this.lang, required this.empty, required this.onTap});

  final String lang;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(2.1)),
        child: Row(
          children: [
            SizedBox(
              width: context.vw(6.7),
              child: Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.mute),
            ),
            SizedBox(width: context.vw(2.6)),
            Expanded(
              child: Text(
                empty ? 'home_day_empty'.tr(lang) : 'home_plan'.tr(lang),
                style: RyzeText.body(context, 3.2, weight: FontWeight.w600, color: RyzeColors.mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
