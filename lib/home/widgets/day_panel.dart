import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../home_slots.dart';

/// Le jour ouvert sous la bande de semaine, lu comme le journal.
///
/// C'est la même ligne de temps que « Mes repas » dans Nutrition : un trait
/// vertical, un rond par créneau, et le contenu à droite. Le jour qu'on
/// regarde se lit donc de la même façon qu'aujourd'hui — un seul geste de
/// lecture pour la même chose, qu'elle soit passée, présente ou prévue.
///
/// Les quatre repas sont toujours là, dans l'ordre de la journée, et la séance
/// vient sous le dîner : c'est la fin de la journée sportive comme le dîner
/// est la fin de la journée alimentaire.
class DayPanel extends StatelessWidget {
  const DayPanel({
    super.key,
    required this.lang,
    required this.day,
    required this.lines,
    required this.onLineTap,
    required this.onPlan,
  });

  final String lang;
  final DateTime day;

  /// Ce qui est prévu ce jour-là, tel que le planificateur l'a écrit.
  final List<PlannedLine> lines;

  final void Function(PlannedLine line) onLineTap;

  /// Un créneau vide : planifier ce jour.
  final VoidCallback onPlan;

  /// L'ordre de la journée. La séance ferme la marche.
  static const List<WeekSlot> _order = [
    WeekSlot.breakfast,
    WeekSlot.lunch,
    WeekSlot.snack,
    WeekSlot.dinner,
    WeekSlot.sport,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.6), context.vw(4.1), context.vw(3.6)),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: RyzeColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            RyzeDates.full(day, lang),
            style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute),
          ),
          SizedBox(height: context.vw(3.1)),
          Stack(
            children: [
              // Le rail, derrière les ronds : il part du premier et s'arrête
              // au dernier, comme dans le journal.
              Positioned(
                left: context.vw(2.05),
                top: context.vw(3.1),
                bottom: context.vw(3.1),
                width: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: RyzeColors.line, borderRadius: BorderRadius.circular(1)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final slot in _order)
                    _SlotRow(
                      lang: lang,
                      slot: slot,
                      lines: [for (final l in lines) if (l.slot == slot) l],
                      onLineTap: onLineTap,
                      onPlan: onPlan,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un créneau : son rond, son nom, et ce qu'il porte — ou l'invitation à le
/// remplir. Un créneau peut porter plusieurs choses : deux séances le même
/// jour, ou un repas et son cardio.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.lang,
    required this.slot,
    required this.lines,
    required this.onLineTap,
    required this.onPlan,
  });

  final String lang;
  final WeekSlot slot;
  final List<PlannedLine> lines;
  final void Function(PlannedLine line) onLineTap;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    // Un jour où huit séances sur neuf sont faites n'est pas un jour vide.
    //
    // Le créneau exigeait que tout soit fait pour se remplir : une seule
    // séance restée prévue suffisait à laisser le rond creux, et la journée
    // se lisait comme si rien n'avait eu lieu.
    final faites = lines.where((l) => l.state == SlotState.done).length;
    final done = lines.isNotEmpty && faites == lines.length;
    final partial = faites > 0 && !done;
    final planned = lines.isNotEmpty && faites == 0;
    final empty = lines.isEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vw(1.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.vw(0.8)),
            child: _Dot(done: done, partial: partial, planned: planned, sport: slot == WeekSlot.sport),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'slot_${slot.name}'.tr(lang),
                  style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: empty ? RyzeColors.mute : RyzeColors.ink),
                ),
                if (empty)
                  Text('home_slot_free'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute2))
                else
                  for (final line in lines)
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(0.5)),
                      child: _LineText(line: line, onTap: () => onLineTap(line)),
                    ),
              ],
            ),
          ),
          if (empty) ...[
            SizedBox(width: context.vw(2.1)),
            Semantics(
              button: true,
              label: 'home_plan'.tr(lang),
              child: Pressable(
                onTap: onPlan,
                child: Container(
                  width: context.vw(8.2),
                  height: context.vw(8.2),
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    shape: BoxShape.circle,
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.mute),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le rond du créneau. La nourriture est un carré arrondi, le sport un
/// anneau — la règle de forme du reste de l'application, tenue jusqu'ici.
class _Dot extends StatelessWidget {
  const _Dot({
    required this.done,
    required this.planned,
    required this.sport,
    this.partial = false,
  });

  final bool done;

  /// Une partie seulement est faite : la coche apparaît, le plein attend.
  final bool partial;

  final bool planned;
  final bool sport;

  @override
  Widget build(BuildContext context) {
    final marque = done || partial || planned;

    return AnimatedContainer(
      duration: RyzeDurations.fill,
      curve: RyzeCurves.out,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : (marque ? RyzeColors.surf : RyzeColors.paper),
        shape: sport ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: sport ? null : BorderRadius.circular(4),
        border: Border.all(color: marque ? RyzeColors.ink : RyzeColors.idle, width: 2),
      ),
      child: done
          ? Icon(LucideIcons.check, size: 9, color: RyzeColors.surf)
          : partial
              ? Icon(LucideIcons.check, size: 9, color: RyzeColors.ink)
              : null,
    );
  }
}

/// Une ligne du jour : ce qu'elle contient, et le chevron seulement quand il
/// y a quelque chose derriere.
class _LineText extends StatelessWidget {
  const _LineText({required this.line, required this.onTap});

  final PlannedLine line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Chaque ligne dit son propre état. Elle n'en disait aucun : une séance
    // faite et une séance à faire s'écrivaient exactement pareil, et le jour
    // entier paraissait en attente.
    final done = line.state == SlotState.done;

    final row = Row(
      children: [
        SizedBox(
          width: context.vw(4.4),
          child: done
              ? Icon(LucideIcons.check, size: context.vw(3.4), color: RyzeColors.accInk)
              : null,
        ),
        Expanded(
          child: Text(
            line.detail.isEmpty ? line.title : '${line.title} · ${line.detail}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RyzeText.body(context, 3.1, color: done ? RyzeColors.ink : RyzeColors.mute),
          ),
        ),
        if (onTap != null) Icon(LucideIcons.chevronRight, size: context.vw(3.9), color: RyzeColors.mute2),
      ],
    );
    return onTap == null ? row : Pressable(onTap: onTap, child: row);
  }
}
