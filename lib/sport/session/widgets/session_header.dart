import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../../widgets/pending_sync_line.dart';

/// Le haut de la séance : la sortie, le nom, l'avancement, l'horloge.
///
/// L'horloge n'écoute qu'un `ValueNotifier` : elle est la seule chose qui se
/// redessine chaque seconde, là où l'ancien écran reconstruisait tout.
class SessionHeader extends StatelessWidget {
  const SessionHeader({
    super.key,
    required this.lang,
    required this.name,
    required this.done,
    required this.total,
    required this.elapsed,
    required this.onClose,
  });

  final String lang;
  final String name;
  final int done;
  final int total;
  final ValueListenable<Duration> elapsed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final gutter = context.vw(5.1);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, context.vw(2.1), gutter, context.vw(2.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pressable(
                onTap: onClose,
                child: Container(
                  width: context.vw(9.7),
                  height: context.vw(9.7),
                  decoration: BoxDecoration(
                    color: RyzeColors.surf,
                    shape: BoxShape.circle,
                    border: Border.all(color: RyzeColors.line),
                  ),
                  child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.ink),
                ),
              ),
              SizedBox(width: context.vw(3.1)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
                    ),
                    Text(
                      'session_sets_progress'.tr(lang).replaceAll('{done}', '$done').replaceAll('{total}', '$total'),
                      style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.vw(2.1)),
              ValueListenableBuilder<Duration>(
                valueListenable: elapsed,
                builder: (context, d, _) => RollingNumber(
                  _mmss(d),
                  style: RyzeText.display(context, 5.6, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          PendingSyncLine(lang: lang, compact: true),
        ],
      ),
    );
  }

  static String _mmss(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
