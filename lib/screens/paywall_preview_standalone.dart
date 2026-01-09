import 'package:flutter/material.dart';
import '../services/paywall_service.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../models/subscription_models.dart';

/// Écran de prévisualisation standalone des paywalls (sans dépendances)
/// Utilisé uniquement pour visualiser les designs
/// Optimisé avec les 5 éléments de conversion prouvés
class PaywallPreviewStandalone extends StatefulWidget {
  final PaywallContext paywallContext;

  const PaywallPreviewStandalone({
    Key? key,
    required this.paywallContext,
  }) : super(key: key);

  @override
  State<PaywallPreviewStandalone> createState() => _PaywallPreviewStandaloneState();
}

class _PaywallPreviewStandaloneState extends State<PaywallPreviewStandalone> with SingleTickerProviderStateMixin {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly; // Pré-sélectionner le mensuel
  bool _showCloseButton = false;
  bool _startAnimations = false; // Pour déclencher les animations après affichage
  AnimationController? _breathingController;
  Animation<double>? _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Démarrer les animations après 300ms (temps que le paywall s'affiche)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _startAnimations = true);
      }
    });

    // Close button delay (5 secondes)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showCloseButton = true);
      }
    });

    // Breathing animation pour l'avatar - démarre après 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _breathingController = AnimationController(
          duration: const Duration(milliseconds: 2000),
          vsync: this,
        )..repeat(reverse: true);

        _breathingAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _breathingController!, curve: Curves.easeInOut),
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _breathingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Détection de la langue (fr, de ou en)
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode == 'fr' ? 'fr' : locale.languageCode == 'de' ? 'de' : 'en';
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Contenu contextuel
    final avatarType = PaywallService.getContextAvatar(widget.paywallContext);
    final benefits = PaywallService.getContextBenefits(widget.paywallContext, languageCode);
    final title = PaywallService.getContextTitle(widget.paywallContext, languageCode);
    final bubbleText = PaywallService.getCoachBubbleText(widget.paywallContext, languageCode);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Même fond que les pages de l'app
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle gris
          const SizedBox(height: 4),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 🐼 AVATAR AVEC BULLE DE DIALOGUE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar avec breathing animation
                _breathingAnimation != null
                    ? ScaleTransition(
                        scale: _breathingAnimation!,
                        child: CoachRyzeAvatar(
                          size: CoachRyzeAvatarSize.large,
                          type: avatarType,
                        ),
                      )
                    : CoachRyzeAvatar(
                        size: CoachRyzeAvatarSize.large,
                        type: avatarType,
                      ),
                const SizedBox(width: 12),
                // Bulle de dialogue avec animation
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: _startAnimations ? 600 : 0),
                    tween: Tween(begin: _startAnimations ? 0.0 : 1.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        bubbleText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // TITRE - POSITIF ET ENGAGEANT AVEC ANIMATION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: _startAnimations ? 800 : 0),
              tween: Tween(begin: _startAnimations ? 0.0 : 1.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B132B),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // BENEFITS - CONTEXTUELS (AVEC STAGGER ANIMATION)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: benefits.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final benefit = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < 2 ? 8.0 : 0),
                  child: _buildSimpleBenefit(
                    index: index,
                    benefit: '${benefit['icon']} ${benefit['text']}',
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // "3 JOURS GRATUITS" BANNER AVEC ANIMATION
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: _startAnimations ? 1000 : 0),
            tween: Tween(begin: _startAnimations ? 0.0 : 1.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFCD34D)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isFrench ? '3 JOURS GRATUITS' : isGerman ? '3 TAGE KOSTENLOS' : '3 DAYS FREE TRIAL',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF92400E),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3 PRICING CARDS - NOUVEL ORDRE: ANNUEL / MENSUEL (POPULAIRE) / HEBDO
          SizedBox(
            height: 120, // Hauteur réduite
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ANNUEL (GAUCHE - MEILLEURE VALEUR) - Or/Jaune
                  Expanded(
                    child: _buildPricingCard(
                      period: SubscriptionPeriod.annual,
                      price: '69,99€',
                      interval: isFrench ? '/an' : isGerman ? '/Jahr' : '/yr',
                      badge: isFrench ? 'Meilleure valeur' : isGerman ? 'Bester Wert' : 'Best value',
                      badgeColor: const Color(0xFFFFD700),
                      description: 'Économise 49%',
                      equivalentPrice: isFrench ? '5,83€/mois' : isGerman ? '5,83€/Monat' : '€5.83/mo',
                      savingsText: isFrench ? 'Économise 49%' : isGerman ? 'Spare 49%' : 'Save 49%',
                      isHighlighted: true,
                      isFrench: isFrench,
                      isGerman: isGerman,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // MENSUEL (CENTER - LE PLUS CHOISI) - Orange
                  Expanded(
                    child: _buildPricingCard(
                      period: SubscriptionPeriod.monthly,
                      price: '9,99€',
                      interval: isFrench ? '/mois' : isGerman ? '/Monat' : '/mo',
                      badge: isFrench ? 'Le plus choisi' : isGerman ? 'Am beliebtesten' : 'Most popular',
                      badgeColor: const Color(0xFFFF8C00),
                      description: isFrench ? 'Sans engagement' : isGerman ? 'Ohne Bindung' : 'No commitment',
                      isFrench: isFrench,
                      isGerman: isGerman,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // HEBDOMADAIRE (DROITE - POUR TESTER) - Bleu clair
                  Expanded(
                    child: _buildPricingCard(
                      period: SubscriptionPeriod.weekly,
                      price: '2,99€',
                      interval: isFrench ? '/sem' : isGerman ? '/Woche' : '/wk',
                      badge: isFrench ? 'Pour tester' : isGerman ? 'Zum Testen' : 'Try it',
                      badgeColor: const Color(0xFF5AC8FA),
                      equivalentPrice: isFrench ? '12,96€/mois' : isGerman ? '12,96€/Monat' : '€12.96/mo',
                      isFrench: isFrench,
                      isGerman: isGerman,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // CTA BUTTON (56pt + 20pt = 76pt total)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFrench ? 'DEBLOQUER MON COACH' : isGerman ? 'MEINEN COACH FREISCHALTEN' : 'UNLOCK MY COACH',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          isFrench ? '3 JOURS GRATUITS' : isGerman ? '3 TAGE KOSTENLOS' : '3 DAYS FREE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPeriod == SubscriptionPeriod.monthly
                      ? (isFrench ? 'Puis 9,99€/mois • Annule en 1 clic' : isGerman ? 'Dann 9,99€/Monat • Mit 1 Klick kundigen' : 'Then €9.99/mo • Cancel in 1 click')
                      : _selectedPeriod == SubscriptionPeriod.annual
                          ? (isFrench ? 'Puis 69,99€/an • Annule en 1 clic' : isGerman ? 'Dann 69,99€/Jahr • Mit 1 Klick kundigen' : 'Then €69.99/yr • Cancel in 1 click')
                          : (isFrench ? 'Puis 2,99€/sem • Annule en 1 clic' : isGerman ? 'Dann 2,99€/Woche • Mit 1 Klick kundigen' : 'Then €2.99/wk • Cancel in 1 click'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // "Peut-être plus tard" (24pt) - APPARAÎT APRÈS 4 SECONDES
          AnimatedOpacity(
            opacity: _showCloseButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: _showCloseButton ? () => Navigator.pop(context) : null,
              child: Text(
                isFrench ? 'Peut-etre plus tard' : isGerman ? 'Vielleicht spater' : 'Maybe later',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          // Bottom safe area (102pt)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }

  // Benefit simple avec stagger animation
  Widget _buildSimpleBenefit({
    required int index,
    required String benefit,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: _startAnimations ? (200 + (index * 150)) : 0), // Stagger delay
      tween: Tween(begin: _startAnimations ? 0.0 : 1.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, _startAnimations ? 20 * (1 - value) : 0), // Slide from bottom
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Text(
        benefit,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  // Nouvelle pricing card compacte pour 3 colonnes
  Widget _buildPricingCard({
    required SubscriptionPeriod period,
    required String price,
    required String interval,
    required String badge,
    Gradient? badgeGradient,
    Color? badgeColor,
    String? description,
    String? equivalentPrice,
    String? savingsText,
    bool isHighlighted = false,
    required bool isFrench,
    bool isGerman = false,
  }) {
    final isSelected = _selectedPeriod == period;

    // Nom de l'abonnement
    String periodName = '';
    if (period == SubscriptionPeriod.annual) {
      periodName = isFrench ? 'Annuel' : isGerman ? 'Jahrlich' : 'Annual';
    } else if (period == SubscriptionPeriod.monthly) {
      periodName = isFrench ? 'Mensuel' : isGerman ? 'Monatlich' : 'Monthly';
    } else {
      periodName = isFrench ? 'Hebdo' : isGerman ? 'Wochentlich' : 'Weekly';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bloc principal
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE5E7EB),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nom de l'abonnement + Radio button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          periodName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B132B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Prix sur une seule ligne - centré
                  SizedBox(
                    width: double.infinity,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0B132B),
                              height: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: interval,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Texte d'économie (seulement pour annuel)
                  if (savingsText != null) ...[
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        savingsText,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Pastille badge en bas à cheval
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: badgeGradient,
                  color: badgeGradient == null ? badgeColor : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
