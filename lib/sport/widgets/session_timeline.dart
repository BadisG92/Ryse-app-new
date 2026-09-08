import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_dates.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../sport_data.dart';

/// Des séances passées sur le rail, comme les repas sur la ligne du jour.
///
/// Le sport est un anneau : navy plein pour la musculation, bord ambre pour
/// le cardio — la famille se lit à la forme, sans onglet ni étiquette. Une
/// rangée dit le nom, quand, et ce qu'elle a coûté ; le chevron ouvre le
/// récapitulatif.
class SessionTimeline extends StatelessWidget {
  const SessionTimeline({super.key, required this.lang, required this.rows, required this.onTap});

  final String lang;
  final List<SportSessionRow> rows;
  final ValueChanged<SportSessionRow> onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: context.vw(2.8),
          top: context.vw(4.1),
          bottom: context.vw(5.6),
          width: 2,
          child: ColoredBox(color: RyzeColors.idle),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in rows) SessionRow(lang: lang, row: r, onTap: () => onTap(r)),
          ],
        ),
      ],
    );
  }
}

/// Une séance sur le rail.
class SessionRow extends StatelessWidget {
  const SessionRow({super.key, required this.lang, required this.row, required this.onTap, this.showDate = true});

  final String lang;
  final SportSessionRow row;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: context.vw(9.2), bottom: context.vw(2.1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -context.vw(8.2),
            top: context.vw(4.6),
            child: SessionRing(kind: row.kind, done: row.done),
          ),
          Pressable(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.fromLTRB(context.vw(4.1), context.vw(3.1), context.vw(2.6), context.vw(3.1)),
              decoration: BoxDecoration(
                color: RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.md),
                border: Border.all(color: RyzeColors.line),
              ),
              child: Row(
                children: [
                  Icon(
                    iconForKind(row.kind),
                    size: context.vw(4.4),
                    color: row.done ? RyzeColors.mute : RyzeColors.mute2,
                  ),
                  SizedBox(width: context.vw(2.6)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 3.9,
                              weight: FontWeight.w600,
                              color: row.done ? RyzeColors.ink : RyzeColors.mute),
                        ),
                        SizedBox(height: context.vw(0.5)),
                        Text(
                          meta(context, lang, row, showDate: showDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: context.vw(4.6), color: RyzeColors.mute2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// « Hier · 42 min · 310 kcal », avec la distance quand il y en a une.
  static String meta(BuildContext context, String lang, SportSessionRow row, {bool showDate = true}) {
    final parts = <String>[];
    if (showDate) parts.add(_day(lang, row.date));
    if (row.distanceKm != null && row.distanceKm! > 0) {
      final units = UnitService.instance;
      final d = units.displayDistance(row.distanceKm!);
      parts.add('${NumberFormat('0.#', lang).format(d)} ${units.distanceUnit}');
    }
    // Une séance qui n'a pas eu lieu n'a brûlé aucune calorie : elle annonce
    // sa durée prévue, et rien d'autre.
    if (row.done) {
      parts.add('sport_min_kcal'.tr(lang).replaceAll('{min}', '${row.minutes}').replaceAll('{kcal}', NumberFormat.decimalPattern(lang).format(row.kcal)));
    } else if (row.minutes > 0) {
      parts.add('sport_minutes'.tr(lang).replaceAll('{min}', '${row.minutes}'));
    }
    return parts.join(' · ');
  }

  static String _day(String lang, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'sport_today'.tr(lang);
    if (day == today.subtract(const Duration(days: 1))) return 'sport_yesterday'.tr(lang);
    return RyzeDates.full(d, lang);
  }
}

/// L'anneau d'une séance : plein quand elle a eu lieu, creux quand elle
/// attend.
///
/// Il disait la famille — navy pour la musculation, ambre pour le cardio —
/// alors que la même forme dit l'état partout ailleurs dans l'application.
/// Deux écrans montraient le même mardi, l'un avec des ronds pleins et
/// creux qui parlaient de muscu et de cardio, l'autre de fait et de prévu.
/// La famille est passée dans l'icône, à côté du nom.
class SessionRing extends StatelessWidget {
  const SessionRing({super.key, required this.kind, this.size = 16, this.done = true});

  final SportKind kind;
  final double size;

  /// La séance a-t-elle eu lieu ?
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : RyzeColors.surf,
        shape: BoxShape.circle,
        border: Border.all(color: done ? RyzeColors.ink : RyzeColors.idle, width: 2),
      ),
      child: done ? Icon(LucideIcons.check, size: size * 0.56, color: RyzeColors.surf) : null,
    );
  }
}

/// L'icône de la famille : haltère pour la musculation, course pour le reste.
IconData iconForKind(SportKind kind) =>
    kind == SportKind.strength ? LucideIcons.dumbbell : LucideIcons.footprints;
