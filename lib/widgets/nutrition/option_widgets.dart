import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/paywall_service.dart';
import '../../services/subscription_service.dart';

// Badge Premium avec animation pulse pour trial
class _PremiumBadge extends StatefulWidget {
  final bool isLocked;
  final String langCode;

  const _PremiumBadge({
    required this.isLocked,
    required this.langCode,
  });

  @override
  State<_PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<_PremiumBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animation pulse pour trial ET upgrade
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Démarrer l'animation pour tous les badges
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isLocked
            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)] // Doré pour UPGRADE
            : [const Color(0xFF0B132B), const Color(0xFF1C2951)], // Bleu DA pour TRY FREE
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.isLocked
              ? const Color(0xFFFFD700).withOpacity(0.4) // Glow doré
              : const Color(0xFF0B132B).withOpacity(0.3), // Glow bleu
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isLocked ? LucideIcons.lockOpen : LucideIcons.gift,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            widget.isLocked
              ? 'unlock_badge'.tr(widget.langCode)
              : 'trial_badge'.tr(widget.langCode),
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

    // Animation pulse pour tous les badges
    return ScaleTransition(
      scale: _pulseAnimation,
      child: badge,
    );
  }
}

class FoodOptionWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final GlobalKey? tutorialKey;
  final PaywallContext? paywallContext; // Nouveau: pour afficher le badge Premium

  const FoodOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tutorialKey,
    this.paywallContext, // Feature Premium optionnelle
  });

  @override
  State<FoodOptionWidget> createState() => _FoodOptionWidgetState();
}

class _FoodOptionWidgetState extends State<FoodOptionWidget> {
  bool? _isLocked;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    if (widget.paywallContext != null) {
      final locked = await PaywallService.instance.isFeatureLocked(widget.paywallContext!);
      if (kDebugMode) {
        debugPrint('🔒 FoodOptionWidget: ${widget.paywallContext!.name} is locked: $locked');
      }
      if (mounted) {
        setState(() {
          _isLocked = locked;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si c'est une feature Premium, afficher avec badge
    if (widget.paywallContext != null && !_isLoading) {
      final isLocked = _isLocked ?? false;
      final isPremium = SubscriptionService.instance.isPremium;
      final langCode = LocalizationService.instance.currentLanguageCode;

      return Opacity(
        opacity: isLocked ? 0.85 : 1.0, // Légère opacité sur items bloqués
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: widget.tutorialKey,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLocked
                      ? const Color(0xFFFFD700) // Bordure dorée quand locked (attirant!)
                      : const Color(0xFFE5E7EB),
                    width: isLocked ? 1.5 : 1, // Plus épaisse si locked
                  ),
                  boxShadow: isLocked ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A), // Toujours noir (lisible)
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B), // Toujours lisible
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: Color(0xFF64748B), // Toujours visible
                    ),
                  ],
                ),
              ),
              // Badge Premium à cheval sur le bord supérieur
              if (!isPremium)
                Positioned(
                  top: -12,
                  right: 16,
                  child: _PremiumBadge(
                    isLocked: isLocked,
                    langCode: langCode,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Widget normal sans badge Premium (ou en loading)
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        key: widget.tutorialKey,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: 24,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class MealOptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MealOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodSuggestionWidget extends StatelessWidget {
  final String name;
  final int calories;
  final String per;
  final VoidCallback onTap;
  final bool isCustom;
  final String? origin; // 'manual', 'barcode', ou null
  final bool hasModifiedMacros; // Macronutriments modifiés
  final bool isRecipe; // Est-ce une recette

  const FoodSuggestionWidget({
    super.key,
    required this.name,
    required this.calories,
    required this.per,
    required this.onTap,
    this.isCustom = false,
    this.origin,
    this.hasModifiedMacros = false,
    this.isRecipe = false,
  });

  // Méthode pour déterminer l'icône selon les nouvelles règles
  IconData _getIconBasedOnRules() {
    // Règle 1: Aliment custom_foods avec origin = 'barcode' → icône code-barres
    if (isCustom && origin?.toLowerCase().trim() == 'barcode') {
      return LucideIcons.scan;
    }

    // Règle 2: Aliment custom_foods avec origin = 'manual' → icône bonhomme
    if (isCustom && origin?.toLowerCase().trim() == 'manual') {
      return LucideIcons.user;
    }

    // Règle 3: Aliment de base avec macronutriments modifiés → icône bonhomme
    if (!isCustom && hasModifiedMacros) {
      return LucideIcons.user;
    }

    // Règle 4: Recette avec aliment modifié → icône bonhomme
    if (isRecipe && hasModifiedMacros) {
      return LucideIcons.user;
    }

    // Règle 5: Aliment custom par défaut → icône bonhomme
    if (isCustom) {
      return LucideIcons.user;
    }

    // Par défaut: pas d'icône (aliment de base non modifié)
    return LucideIcons.user; // Fallback, ne devrait pas être affiché
  }

  // Méthode pour déterminer le texte selon les nouvelles règles
  String _getTextBasedOnRules(String languageCode) {
    // Règle 1: Aliment custom_foods avec origin = 'barcode' → "Scanné"
    if (isCustom && origin?.toLowerCase().trim() == 'barcode') {
      return 'scanned'.tr(languageCode);
    }

    // Règle 2: Aliment custom_foods avec origin = 'manual' → "Personnalisé"
    if (isCustom && origin?.toLowerCase().trim() == 'manual') {
      return 'custom'.tr(languageCode);
    }

    // Règle 3: Aliment de base avec macronutriments modifiés → "Modifié"
    if (!isCustom && hasModifiedMacros) {
      return 'modified'.tr(languageCode);
    }

    // Règle 4: Recette avec aliment modifié → "Modifié"
    if (isRecipe && hasModifiedMacros) {
      return 'modified'.tr(languageCode);
    }

    // Règle 5: Aliment custom par défaut → "Personnalisé"
    if (isCustom) {
      return 'custom'.tr(languageCode);
    }

    // Par défaut
    return 'custom'.tr(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Vérifier les paramètres reçus et la logique (focus sur Nutella)
    if (name.toLowerCase().contains('nutella')) {
      debugPrint('🎨 DEBUG FoodSuggestionWidget - NUTELLA:');
      debugPrint('   - isCustom: $isCustom');
      debugPrint('   - origin: "$origin"');
      debugPrint('   - hasModifiedMacros: $hasModifiedMacros');
      debugPrint('   - isRecipe: $isRecipe');
      debugPrint('   - Icône sélectionnée: ${_getIconBasedOnRules()}');
      debugPrint('   - Texte sélectionné: ${_getTextBasedOnRules('fr')}');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Indicateur pour aliment personnalisé, modifié ou scanné
            if (isCustom || hasModifiedMacros || isRecipe) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconBasedOnRules(),
                  size: 14,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (isCustom || hasModifiedMacros || isRecipe) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Consumer<LocalizationService>(
                            builder: (context, locService, child) => Text(
                              _getTextBasedOnRules(locService.currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$calories kcal / $per',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
