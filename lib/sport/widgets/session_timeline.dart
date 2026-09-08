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
            child: SessionRing(kind: row.kind),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
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
    parts.add('sport_min_kcal'.tr(lang).replaceAll('{min}', '${row.minutes}').replaceAll('{kcal}', NumberFormat.decimalPattern(lang).format(row.kcal)));
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

/// L'anneau d'une séance faite : navy plein pour la musculation, ambre au
/// bord pour le cardio.
class SessionRing extends StatelessWidget {
  const SessionRing({super.key, required this.kind, this.size = 16});

  final SportKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final strength = kind == SportKind.strength;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: strength ? RyzeColors.ink : RyzeColors.surf,
        shape: BoxShape.circle,
        border: Border.all(color: strength ? RyzeColors.ink : RyzeColors.acc, width: strength ? 1 : 2.5),
      ),
    );
  }
}
