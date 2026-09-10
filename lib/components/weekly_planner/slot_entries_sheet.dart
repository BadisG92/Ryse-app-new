import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// Une entrée d'un créneau : ce qu'elle est, où elle en est.
typedef SlotEntry = ({String title, String detail, bool done, bool sport});

/// Ce qu'un créneau du calendrier contient, quand il contient plusieurs choses.
///
/// Une case de la semaine n'ouvrait que sa première entrée : la première
/// séance du jour, le premier plat du créneau. Les autres existaient dans les
/// données, se comptaient dans les totaux, et n'étaient atteignables nulle
/// part depuis le calendrier — une journée avec une course et une séance de
/// dos n'en montrait qu'une, et un déjeuner noté par-dessus un déjeuner prévu
/// cachait l'un des deux.
///
/// Les entrées défilent horizontalement, la suivante dépasse du bord droit
/// pour qu'on sache qu'elle est là, et chacune dit si elle est faite ou
/// prévue. Une seule entrée n'ouvre pas cette feuille : l'appelant va droit au
/// détail.
class SlotEntriesSheet {
  SlotEntriesSheet._();

  /// Rend l'index choisi, ou nul si la feuille est refermée.
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String lang,
    required List<SlotEntry> entries,
  }) {
    return showRyzeSheet<int>(
      context,
      title: title,
      subtitle: subtitle,
      builder: (_) => _Pager(entries: entries, lang: lang),
    );
  }
}

class _Pager extends StatefulWidget {
  const _Pager({required this.entries, required this.lang});

  final List<SlotEntry> entries;
  final String lang;

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  late final PageController _c = PageController(viewportFraction: 0.88);
  int _page = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.vw(28),
          child: PageView.builder(
            controller: _c,
            itemCount: entries.length,
            onPageChanged: (i) {
              RyzeFeedback.select();
              setState(() => _page = i);
            },
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: context.vw(2.6)),
              child: _Card(
                entry: entries[i],
                lang: widget.lang,
                onTap: () => Navigator.pop(context, i),
              ),
            ),
          ),
        ),
        SizedBox(height: context.vw(3.6)),
        // Le compte des entrées, et où l'on en est : sans lui, la deuxième
        // carte qui dépasse est une décoration.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) SizedBox(width: context.vw(1.5)),
              AnimatedContainer(
                duration: RyzeDurations.tap,
                curve: RyzeCurves.out,
                width: i == _page ? context.vw(4.6) : context.vw(1.8),
                height: context.vw(1.8),
                decoration: BoxDecoration(
                  color: i == _page ? RyzeColors.ink : RyzeColors.idle,
                  borderRadius: BorderRadius.circular(RyzeRadius.pill),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vw(2.1)),
      ],
    );
  }
}

/// Une entrée : sa forme dit ce qu'elle est — carré pour l'assiette, anneau
/// pour le sport — et sa pastille dit où elle en est.
class _Card extends StatelessWidget {
  const _Card({required this.entry, required this.lang, required this.onTap});

  final SlotEntry entry;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.tap();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(context.vw(4.1)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Mark(done: entry.done, sport: entry.sport),
                SizedBox(width: context.vw(2.6)),
                Expanded(
                  child: Text(
                    (entry.done ? 'slot_done' : 'slot_planned').tr(lang),
                    style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: entry.done ? RyzeColors.ink : RyzeColors.mute),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: RyzeColors.mute2),
              ],
            ),
            const Spacer(),
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: RyzeText.body(context, 4.1, weight: FontWeight.w600),
            ),
            if (entry.detail.isNotEmpty) ...[
              SizedBox(height: context.vw(1)),
              Text(entry.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le carré de l'assiette, l'anneau du sport. La règle de forme du système.
class _Mark extends StatelessWidget {
  const _Mark({required this.done, required this.sport});

  final bool done;
  final bool sport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : RyzeColors.paper,
        shape: sport ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: sport ? null : BorderRadius.circular(5),
        border: Border.all(color: done ? RyzeColors.ink : RyzeColors.idle, width: 2),
      ),
      child: done ? Icon(LucideIcons.check, size: 10, color: RyzeColors.surf) : null,
    );
  }
}
