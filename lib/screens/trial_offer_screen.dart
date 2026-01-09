import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../services/unified_subscription_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/subscription_models.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../components/main_app.dart';

/// Écran de proposition d'essai gratuit 3 jours
/// Affiché après l'onboarding pour proposer le trial App Store
class TrialOfferScreen extends StatefulWidget {
  const TrialOfferScreen({Key? key}) : super(key: key);

  @override
  State<TrialOfferScreen> createState() => _TrialOfferScreenState();
}

class _TrialOfferScreenState extends State<TrialOfferScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du Coach Ryze
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startTrial() async {
    setState(() => _isLoading = true);

    try {
      final unifiedService = UnifiedSubscriptionService();

      // Lancer l'abonnement avec trial 3 jours (géré par App Store)
      final success = await unifiedService.upgradeToPremium(
        period: SubscriptionPeriod.monthly, // Par défaut mensuel
      );

      if (!mounted) return;

      if (success) {
        // Succès : aller vers l'app avec accès Premium
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      } else {
        // L'utilisateur a annulé
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'trial_cancelled'.tr(LocalizationService.instance.currentLanguageCode),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage du trial: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_generic'.tr(LocalizationService.instance.currentLanguageCode),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _skipToFreeVersion() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    final isFrench = locService.currentLanguageCode == 'fr';
    final isGerman = locService.currentLanguageCode == 'de';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Coach Ryze animé
                  const CoachRyzeAvatar(
                    size: CoachRyzeAvatarSize.xxlarge, // 160px
                    type: CoachRyzeAvatarType.workout,
                  ),

                  const SizedBox(height: 32),

                  // Titre principal
                  Text(
                    isFrench
                        ? 'Débloque tout ton potentiel'
                        : isGerman
                            ? 'Entfessle dein volles Potenzial'
                            : 'Unlock your full potential',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B132B),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sous-titre avec prix
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0B132B).withOpacity(0.1)),
                    ),
                    child: Text(
                      isFrench
                          ? '3 jours gratuits, puis 9,99€/mois'
                          : isGerman
                              ? '3 Tage kostenlos, dann 9,99€/Monat'
                              : '3 days free, then €9.99/month',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Features Premium avec Coach Ryze
                  _buildFeature(
                    icon: '📸',
                    title: isFrench ? 'Scans illimités' : isGerman ? 'Unbegrenzte Scans' : 'Unlimited scans',
                    description: isFrench
                        ? 'Le Coach Ryze analyse tes repas instantanément'
                        : isGerman
                            ? 'Coach Ryze analysiert deine Mahlzeiten sofort'
                            : 'Coach Ryze analyzes your meals instantly',
                  ),

                  const SizedBox(height: 16),

                  _buildFeature(
                    icon: '🤖',
                    title: isFrench ? 'Générateur de workouts' : isGerman ? 'Workout-Generator' : 'Workout generator',
                    description: isFrench
                        ? 'Le Coach Ryze crée des séances personnalisées'
                        : isGerman
                            ? 'Coach Ryze erstellt personalisierte Trainingseinheiten'
                            : 'Coach Ryze creates personalized workouts',
                  ),

                  const SizedBox(height: 16),

                  _buildFeature(
                    icon: '📊',
                    title: isFrench ? 'Bilan quotidien' : isGerman ? 'Täglicher Bericht' : 'Daily report',
                    description: isFrench
                        ? 'Le Coach Ryze analyse ta journée et te conseille'
                        : isGerman
                            ? 'Coach Ryze analysiert deinen Tag und berät dich'
                            : 'Coach Ryze analyzes your day and advises you',
                  ),

                  const SizedBox(height: 16),

                  _buildFeature(
                    icon: '💪',
                    title: isFrench ? 'Analyse de progression' : isGerman ? 'Fortschrittsanalyse' : 'Progress analysis',
                    description: isFrench
                        ? 'Le Coach Ryze suit tes performances'
                        : isGerman
                            ? 'Coach Ryze verfolgt deine Leistungen'
                            : 'Coach Ryze tracks your performance',
                  ),

                  const SizedBox(height: 40),

                  // CTA Principal - Commencer l'essai
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
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
                                const Icon(LucideIcons.sparkles, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  isFrench
                                      ? 'Commencer 3 jours gratuits'
                                      : isGerman
                                          ? '3 Tage kostenlos starten'
                                          : 'Start 3 days free',
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

                  const SizedBox(height: 16),

                  // Lien secondaire - Version gratuite
                  TextButton(
                    onPressed: _isLoading ? null : _skipToFreeVersion,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: Text(
                      isFrench
                          ? 'Continuer avec la version limitée'
                          : isGerman
                              ? 'Mit eingeschränkter Version fortfahren'
                              : 'Continue with limited version',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legal notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.info,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isFrench
                                    ? 'Annule à tout moment dans Réglages iOS'
                                    : isGerman
                                        ? 'Jederzeit in iOS-Einstellungen kündigen'
                                        : 'Cancel anytime in iOS Settings',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFrench
                              ? 'Aucun engagement. Paiement après 3 jours.'
                              : isGerman
                                  ? 'Keine Verpflichtung. Zahlung nach 3 Tagen.'
                                  : 'No commitment. Payment after 3 days.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
