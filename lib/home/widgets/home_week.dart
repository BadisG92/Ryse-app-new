import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../home_slots.dart';
import 'day_panel.dart';

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
                    : DayPanel(
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

