import 'package:flutter/material.dart';

import '../services/paywall_service.dart';
import '../services/unified_subscription_service.dart';

/// Qui a le droit de parler à Ryze.
///
/// La règle est la même partout depuis le paywall dur : Ryze fait partie de
/// Premium. Elle était pourtant racontée de trois façons — dix messages à vie
/// comptés sur l'appareil, cinq par jour dans une phrase en dur, une remise à
/// zéro promise par une traduction — et le planificateur avait sa propre porte.
///
/// Deux exceptions, et deux seulement : le mode test, et la démo de
/// l'onboarding, qui tourne avant qu'un compte existe.
class RyzeAccess {
  RyzeAccess._();

  /// La démo de l'onboarding : pas de compte, pas d'abonnement, et pourtant il
  /// faut que Ryze réponde.
  ///
  /// Un compte de prises, pas un interrupteur. La démo passe des repas au
  /// sport en fondant un écran dans l'autre : l'écran du sport s'ouvrait et
  /// allumait la démo, puis celui des repas se fermait une demi-seconde plus
  /// tard et l'éteignait pour tout le monde. La première demande de sport
  /// répondait « fait partie de Premium », à chaque onboarding. Chaque `true`
  /// prend une place, chaque `false` en rend une ; la démo tient tant qu'il
  /// en reste une.
  static int _demoHolds = 0;
  static bool get demoMode => _demoHolds > 0;
  static void setDemoMode(bool value) {
    if (value) {
      _demoHolds++;
    } else if (_demoHolds > 0) {
      _demoHolds--;
    }
  }

  @visibleForTesting
  static void resetDemo() => _demoHolds = 0;

  /// Sans interface : le service peut-il appeler le modèle ?
  static bool get canUse {
    if (demoMode) return true;
    final subscription = UnifiedSubscriptionService();
    return subscription.isPremium || subscription.testMode;
  }

  /// Avec interface : vérifie, et montre le paywall si la porte est fermée.
  ///
  /// Rend vrai quand la conversation peut s'ouvrir.
  static Future<bool> gate(
    BuildContext context, {
    PaywallContext paywallContext = PaywallContext.coachChat,
  }) async {
    if (demoMode) return true;
    return PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: paywallContext,
    );
  }
}
