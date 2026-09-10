import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import '../services/ryze_connectivity.dart';
import '../services/translations.dart';
import '../services/water_queue.dart';

/// Ce que l'app sait de ses verres non envoyés, dit sans détour.
///
/// Rien quand tout est en ligne et que rien n'attend. Sinon une ligne sous les
/// verres : hors ligne et gardé sur le téléphone, ou « 2 verres à
/// synchroniser » avec un « Réessayer » qui insiste vraiment.
///
/// C'est la même surface que celle des séances de musculation, parce que c'est
/// devenu le même mécanisme : l'eau avait une mise à jour optimiste sans rien
/// derrière, donc un verre bu hors ligne s'affichait puis disparaissait.
class WaterPendingLine extends StatelessWidget {
  const WaterPendingLine({super.key, required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    final queue = WaterQueue.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: RyzeConnectivity.instance.online,
      builder: (context, online, _) => ValueListenableBuilder<int>(
        valueListenable: queue.pendingCount,
        builder: (context, pending, _) => ValueListenableBuilder<bool>(
          valueListenable: queue.syncing,
          builder: (context, syncing, _) {
            if (pending == 0) return const SizedBox.shrink();

            final String text;
            final IconData icon;
            VoidCallback? action;
            if (!online) {
              text = 'water_sync_offline'.tr(lang);
              icon = LucideIcons.wifiOff;
            } else if (syncing) {
              text = 'water_sync_syncing'.tr(lang);
              icon = LucideIcons.refreshCw;
            } else {
              text = 'water_sync_pending'.tr(lang).replaceAll('{n}', '$pending');
              icon = LucideIcons.cloudUpload;
              action = queue.retryNow;
            }

            return Padding(
              padding: EdgeInsets.only(top: context.vw(2.1)),
              child: Row(
                children: [
                  Icon(icon, size: context.vw(3.6), color: RyzeColors.mute),
                  SizedBox(width: context.vw(2.1)),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                    ),
                  ),
                  if (action != null)
                    Pressable(
                      onTap: () {
                        RyzeFeedback.tap();
                        action!();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.vw(2.1), vertical: context.vw(1)),
                        child: Text(
                          'session_sync_retry'.tr(lang),
                          style: RyzeText.body(context, 3.1, weight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
