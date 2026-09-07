import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/ryze_connectivity.dart';
import '../../services/translations.dart';
import '../../services/workout_session_store.dart';

/// Ce que l'app sait de ses séances non envoyées, dit sans détour.
///
/// Rien quand tout est en ligne et rien n'attend. Sinon une ligne : hors
/// ligne et gardé sur le téléphone ; ou « 1 séance à synchroniser » avec un
/// « Réessayer » qui insiste vraiment (sans sonde, sans délai). L'ancien
/// service n'avait aucune surface pour ça : la seule qui existait n'était
/// montée nulle part.
class PendingSyncLine extends StatelessWidget {
  const PendingSyncLine({super.key, required this.lang, this.compact = false});

  final String lang;

  /// Dans l'en-tête de séance : une ligne plus discrète.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final store = WorkoutSessionStore.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: RyzeConnectivity.instance.online,
      builder: (context, online, _) => ValueListenableBuilder<int>(
        valueListenable: store.pendingCount,
        builder: (context, pending, _) => ValueListenableBuilder<bool>(
          valueListenable: store.syncing,
          builder: (context, syncing, _) {
            if (online && pending == 0) return const SizedBox.shrink();

            final size = compact ? 3.0 : 3.3;
            final String text;
            final IconData icon;
            VoidCallback? action;
            if (!online) {
              text = 'session_sync_offline'.tr(lang);
              icon = LucideIcons.wifiOff;
            } else if (syncing) {
              text = 'session_sync_syncing'.tr(lang);
              icon = LucideIcons.refreshCw;
            } else {
              text = 'session_sync_pending'.tr(lang).replaceAll('{n}', '$pending');
              icon = LucideIcons.cloudUpload;
              action = () => store.retryNow();
            }

            return Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? context.vw(1) : context.vw(2.1)),
              child: Row(
                children: [
                  Icon(icon, size: context.vw(3.6), color: RyzeColors.mute),
                  SizedBox(width: context.vw(2.1)),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RyzeText.body(context, size, color: RyzeColors.mute),
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
                          style: RyzeText.body(context, size, weight: FontWeight.w600),
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
