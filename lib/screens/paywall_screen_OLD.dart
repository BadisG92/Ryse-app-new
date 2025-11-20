import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/unified_subscription_service.dart';
import '../services/paywall_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../components/ui/coach_ryze_avatar.dart';
import 'pricing_screen.dart';

class PaywallScreen extends StatefulWidget {
  final PaywallContext context;
  final String? customTitle;
  final String? customMessage;

  const PaywallScreen({
    Key? key,
    required this.context,
    this.customTitle,
    this.customMessage,
  }) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _subscriptionService = SubscriptionService.instance;
  final _unifiedService = UnifiedSubscriptionService();
  bool _isProcessing = false;
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    final languageCode = locService.currentLanguageCode;
    final isFrench = languageCode == 'fr';

    // Contenu contextuel
    final avatarType = PaywallService.getContextAvatar(widget.context);
    final title = PaywallService.getContextTitle(widget.context, languageCode);
    final benefits = PaywallService.getContextBenefits(widget.context, languageCode);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            // COACH RYZE + TITRE ACCROCHEUR (CONTEXTUEL)
            // ═══════════════════════════════════════════════════════
            CoachRyzeAvatar(
              size: CoachRyzeAvatarSize.xlarge,
              type: avatarType,
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B132B),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              isFrench ? 'Rejoins 10 000+ athlètes' : 'Join 10,000+ athletes',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            // SÉPARATEUR
            // ═══════════════════════════════════════════════════════
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B132B).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            // BÉNÉFICES ÉMOTIONNELS (CONTEXTUELS)
            // ═══════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: benefits.map((benefit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBenefit(
                      icon: benefit['icon']!,
                      text: benefit['text']!,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════
            // SÉPARATEUR
            // ═══════════════════════════════════════════════════════
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B132B).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════
            // PRICING CARDS (3 CÔTE À CÔTE)
            // ═══════════════════════════════════════════════════════
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // LEURRE GAUCHE: Annuel
                  _buildPricingCard(
                    period: SubscriptionPeriod.annual,
                    price: '69,99€',
                    pricePerMonth: isFrench ? '5,83€/mois' : '€5.83/mo',
                    interval: isFrench ? '/an' : '/year',
                    badge: '💎 -42%',
                    badgeColor: const Color(0xFF10B981),
                    description: isFrench ? 'Meilleure offre' : 'Best value',
                    isHighlighted: false,
                    isFrench: isFrench,
                  ),
                  const SizedBox(width: 12),

                  // CIBLE CENTRALE: Mensuel (POPULAIRE)
                  _buildPricingCard(
                    period: SubscriptionPeriod.monthly,
                    price: '9,99€',
                    pricePerMonth: null,
                    interval: isFrench ? '/mois' : '/month',
                    badge: isFrench ? '🔥 POPULAIRE' : '🔥 POPULAR',
                    badgeColor: const Color(0xFF0B132B),
                    description: isFrench ? 'Le + flexible' : 'Most flexible',
                    isHighlighted: true,
                    isFrench: isFrench,
                  ),
                  const SizedBox(width: 12),

                  // LEURRE DROITE: Hebdo
                  _buildPricingCard(
                    period: SubscriptionPeriod.weekly,
                    price: '2,99€',
                    pricePerMonth: null,
                    interval: isFrench ? '/semaine' : '/week',
                    badge: null,
                    badgeColor: null,
                    description: isFrench ? 'Parfait pour tester' : 'Perfect to try',
                    isHighlighted: false,
                    isFrench: isFrench,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════
            // SÉPARATEUR
            // ═══════════════════════════════════════════════════════
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B132B).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════
            // CTA DYNAMIQUE + LEGAL
            // ═══════════════════════════════════════════════════════
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                children: [
                  // CTA principal (change selon le plan sélectionné)
                  if (SubscriptionService.TEST_MODE) ...[
                    // MODE TEST
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handleTestUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.testTube, size: 20, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    isFrench ? '🧪 SIMULER PAIEMENT (TEST)' : '🧪 SIMULATE PAYMENT (TEST)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFrench ? 'Mode TEST: Aucun paiement réel' : 'TEST Mode: No real payment',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    // MODE PRODUCTION
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handleUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 20, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getCTAText(isFrench),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getLegalText(isFrench),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Bouton secondaire "Peut-être plus tard"
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      isFrench ? 'Peut-être plus tard' : 'Maybe later',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Bénéfice avec icône
  Widget _buildBenefit({required String icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E293B),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Carte de pricing (3 côte à côte)
  Widget _buildPricingCard({
    required SubscriptionPeriod period,
    required String price,
    String? pricePerMonth,
    required String interval,
    String? badge,
    Color? badgeColor,
    required String description,
    required bool isHighlighted,
    required bool isFrench,
  }) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF0B132B)
              : (isSelected ? const Color(0xFFF0F9FF) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF0B132B)
                : (isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0)),
            width: isHighlighted || isSelected ? 2 : 1,
          ),
          boxShadow: isHighlighted || isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white : badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? const Color(0xFF0B132B) : Colors.white,
                  ),
                ),
              )
            else
              const SizedBox(height: 24),

            const SizedBox(height: 12),

            // Prix
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isHighlighted ? Colors.white : const Color(0xFF0B132B),
              ),
            ),

            // Intervalle
            Text(
              interval,
              style: TextStyle(
                fontSize: 13,
                color: isHighlighted
                    ? Colors.white.withOpacity(0.8)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // Prix par mois (si applicable)
            if (pricePerMonth != null)
              Text(
                pricePerMonth,
                style: TextStyle(
                  fontSize: 12,
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF64748B),
                ),
              ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isHighlighted
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Texte CTA dynamique selon le plan sélectionné
  String _getCTAText(bool isFrench) {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.weekly:
        return isFrench ? 'Essayer 7 jours GRATUITEMENT' : 'Try 7 days FREE';
      case SubscriptionPeriod.monthly:
        return isFrench ? 'Essayer 7 jours GRATUITEMENT' : 'Try 7 days FREE';
      case SubscriptionPeriod.annual:
        return isFrench ? 'Essayer 7 jours GRATUITEMENT' : 'Try 7 days FREE';
      case SubscriptionPeriod.lifetime:
        return isFrench ? 'Continuer' : 'Continue';
    }
  }

  /// Texte légal dynamique selon le plan sélectionné
  String _getLegalText(bool isFrench) {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.weekly:
        return isFrench
            ? 'Puis 2,99€/semaine. Annule à tout moment.'
            : 'Then €2.99/week. Cancel anytime.';
      case SubscriptionPeriod.monthly:
        return isFrench
            ? 'Puis 9,99€/mois. Annule à tout moment.'
            : 'Then €9.99/month. Cancel anytime.';
      case SubscriptionPeriod.annual:
        return isFrench
            ? 'Puis 69,99€/an. Annule à tout moment.'
            : 'Then €69.99/year. Cancel anytime.';
      case SubscriptionPeriod.lifetime:
        return '';
    }
  }

  Future<void> _handleTestUpgrade() async {
    setState(() => _isProcessing = true);

    try {
      final success = await _subscriptionService.upgradeToPremium(
        period: _selectedPeriod,
        testBypass: true,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 TEST: Premium activé avec succès!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de l\'activation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isProcessing = true);

    try {
      final success = await _unifiedService.upgradeToPremium(
        period: _selectedPeriod,
      );

      if (!mounted) return;

      if (success) {
        final locService = LocalizationService.instance;
        final isFrench = locService.currentLanguageCode == 'fr';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFrench
                  ? '🎉 Bienvenue dans Ryse Premium !'
                  : '🎉 Welcome to Ryse Premium!',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final locService = LocalizationService.instance;
        final isFrench = locService.currentLanguageCode == 'fr';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFrench ? 'Paiement annulé' : 'Payment cancelled',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'.tr(LocalizationService.instance.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
