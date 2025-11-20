import 'package:flutter/material.dart';

/// Badge "PRO" Premium à afficher sur les boutons verrouillés
///
/// Affiche un badge doré "PRO" en haut à droite du widget enfant et
/// grise légèrement le bouton si `isLocked` est true.
///
/// Utilisation :
/// ```dart
/// PremiumBadge(
///   isLocked: !isPremium && hasUsedTrial,
///   onTap: () async {
///     final canUse = await PaywallService.instance.canUseFeature(
///       context: context,
///       paywallContext: PaywallContext.scanner,
///     );
///     if (canUse) {
///       // Ouvrir la feature
///     }
///   },
///   child: YourButtonWidget(),
/// )
/// ```
class PremiumBadge extends StatelessWidget {
  /// Si true, affiche le badge PRO et grise le bouton
  final bool isLocked;

  /// Widget enfant (généralement un bouton)
  final Widget child;

  /// Callback quand le widget est tapé
  final VoidCallback? onTap;

  /// Opacité du bouton quand verrouillé (0.0 à 1.0)
  final double lockedOpacity;

  const PremiumBadge({
    Key? key,
    required this.isLocked,
    required this.child,
    this.onTap,
    this.lockedOpacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bouton avec overlay grisé si locked
        Opacity(
          opacity: isLocked ? lockedOpacity : 1.0,
          child: GestureDetector(
            onTap: onTap,
            child: child,
          ),
        ),

        // Badge Premium en haut à droite
        if (isLocked)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 11,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Variante du badge Premium pour les icônes/petits boutons
class PremiumBadgeSmall extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final VoidCallback? onTap;
  final double lockedOpacity;

  const PremiumBadgeSmall({
    Key? key,
    required this.isLocked,
    required this.child,
    this.onTap,
    this.lockedOpacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: isLocked ? lockedOpacity : 1.0,
          child: GestureDetector(
            onTap: onTap,
            child: child,
          ),
        ),

        // Badge plus petit pour les icônes
        if (isLocked)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
