import 'package:flutter/material.dart';
import '../../services/paywall_service.dart';
import '../../services/localization_service.dart';

/// Badge qui affiche le statut du trial gratuit d'une feature
/// - "1 ESSAI GRATUIT" si trial disponible
/// - "Plus d'essai gratuit" si trial consommé
/// - Rien si utilisateur Premium
class TrialStatusBadge extends StatelessWidget {
  final PaywallContext paywallContext;
  final bool showOnlyWhenLocked;

  const TrialStatusBadge({
    Key? key,
    required this.paywallContext,
    this.showOnlyWhenLocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locService = LocalizationService.instance;
    final isFrench = locService.currentLanguageCode == 'fr';
    final isGerman = locService.currentLanguageCode == 'de';

    return FutureBuilder<bool>(
      future: PaywallService.instance.isFeatureLocked(paywallContext),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final isLocked = snapshot.data!;

        // Si showOnlyWhenLocked et pas locked, ne rien afficher
        if (showOnlyWhenLocked && !isLocked) {
          return const SizedBox.shrink();
        }

        // Si locked, afficher "Plus d'essai gratuit"
        if (isLocked) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  isFrench ? 'Plus d\'essai gratuit' : isGerman ? 'Keine kostenlose Testversion mehr' : 'No free trial left',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Si pas locked et pas Premium, afficher "1 ESSAI GRATUIT"
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.card_giftcard,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isFrench ? '1 ESSAI GRATUIT' : isGerman ? '1 KOSTENLOSER TEST' : '1 FREE TRIAL',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wrapper pour désactiver un widget si la feature est verrouillée
class LockedFeatureWrapper extends StatelessWidget {
  final Widget child;
  final PaywallContext paywallContext;
  final VoidCallback? onLockedTap;

  const LockedFeatureWrapper({
    Key? key,
    required this.child,
    required this.paywallContext,
    this.onLockedTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PaywallService.instance.isFeatureLocked(paywallContext),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return child;
        }

        final isLocked = snapshot.data!;

        if (!isLocked) {
          return child;
        }

        // Si locked, envelopper dans un widget désactivé et grisé
        return Opacity(
          opacity: 0.5,
          child: AbsorbPointer(
            absorbing: true,
            child: child,
          ),
        );
      },
    );
  }
}
