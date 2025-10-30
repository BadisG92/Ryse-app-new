import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _subscriptionService = SubscriptionService.instance;
  bool _isProcessing = false;
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    final isFrench = locService.currentLanguageCode == 'fr';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isFrench ? 'Plans & Tarifs' : 'Plans & Pricing'),
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF0B132B),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Text(
                    isFrench
                        ? 'Débloque ton potentiel complet'
                        : 'Unlock your full potential',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFrench
                        ? 'Scans IA illimités • Bilan quotidien • Générateur workouts'
                        : 'Unlimited AI scans • Daily analysis • Workout generator',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plans de pricing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: SubscriptionPlan.availablePlans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPlanCard(plan, isFrench),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Features Premium
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFrench
                        ? 'Tout ce qui est inclus:'
                        : 'Everything included:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...PremiumFeature.premiumFeatures.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFeatureRow(feature),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (SubscriptionService.TEST_MODE) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handleTestUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
                                isFrench ? 'Commencer maintenant' : 'Start now',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isFrench) {
    final isSelected = _selectedPeriod == plan.period;
    final isRecommended = plan.period == SubscriptionPeriod.monthly;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = plan.period),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio button
                Container(
                  width: 24,
                  height: 24,
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
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Plan name
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        isFrench ? plan.displayName : plan.description,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF1E293B),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFrench ? 'Populaire' : 'Popular',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (plan.discountPercent != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${plan.discountPercent}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Prix
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${plan.priceEur.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _getPeriodLabel(plan.period, isFrench),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            if (plan.period != SubscriptionPeriod.lifetime &&
                plan.period != SubscriptionPeriod.monthly) ...[
              const SizedBox(height: 8),
              Text(
                '${plan.pricePerMonth.toStringAsFixed(2)}€ ${isFrench ? 'par mois' : 'per month'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(PremiumFeature feature) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel(SubscriptionPeriod period, bool isFrench) {
    switch (period) {
      case SubscriptionPeriod.weekly:
        return isFrench ? '/semaine' : '/week';
      case SubscriptionPeriod.monthly:
        return isFrench ? '/mois' : '/month';
      case SubscriptionPeriod.annual:
        return isFrench ? '/an' : '/year';
      case SubscriptionPeriod.lifetime:
        return isFrench ? 'une fois' : 'one-time';
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
        Navigator.pop(context);
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
      final success = await _subscriptionService.upgradeToPremium(
        period: _selectedPeriod,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
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
