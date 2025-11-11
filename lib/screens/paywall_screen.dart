import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/unified_subscription_service.dart';
import '../services/paywall_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
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

    final content = PaywallService.getPaywallContent(widget.context, languageCode);
    final title = widget.customTitle ?? content['title']!;
    final message = widget.customMessage ?? content['message']!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Plans de pricing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildPlanCard(
                  period: SubscriptionPeriod.monthly,
                  price: '9,99€',
                  subtitle: isFrench ? 'par mois' : 'per month',
                  badge: isFrench ? 'Populaire' : 'Popular',
                  badgeColor: const Color(0xFF0B132B),
                ),
                const SizedBox(height: 12),
                _buildPlanCard(
                  period: SubscriptionPeriod.annual,
                  price: '69,99€',
                  subtitle: isFrench ? 'par an (5,83€/mois)' : 'per year (€5.83/mo)',
                  badge: '-42%',
                  badgeColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildPlanCard(
                  period: SubscriptionPeriod.weekly,
                  price: '2,99€',
                  subtitle: isFrench ? 'par semaine' : 'per week',
                  badge: null,
                  badgeColor: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Boutons d'action
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                // Bouton principal (mode TEST avec bypass)
                if (SubscriptionService.TEST_MODE) ...[
                  // MODE TEST: Bouton "Simuler Paiement"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleTestUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Vert pour TEST
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.testTube, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  isFrench ? '🧪 SIMULER PAIEMENT (TEST)' : '🧪 SIMULATE PAYMENT (TEST)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFrench
                        ? 'Mode TEST: Aucun paiement réel'
                        : 'TEST Mode: No real payment',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  // MODE PRODUCTION: Bouton paiement normal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isFrench ? 'Continuer' : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Bouton "Voir tous les plans"
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PricingScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isFrench ? 'Voir tous les plans' : 'See all plans',
                    style: const TextStyle(
                      color: Color(0xFF0B132B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Bouton "Passer" (continuer en gratuit)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    isFrench ? 'Continuer en gratuit' : 'Continue with free',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPeriod period,
    required String price,
    required String subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Prix et période
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestUpgrade() async {
    setState(() => _isProcessing = true);

    try {
      final success = await _subscriptionService.upgradeToPremium(
        period: _selectedPeriod,
        testBypass: true, // MODE TEST
      );

      if (!mounted) return;

      if (success) {
        // Succès: fermer le paywall
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
      // Utilise UnifiedSubscriptionService qui gère RevenueCat en production
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
              isFrench
                ? 'Paiement annulé'
                : 'Payment cancelled',
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
