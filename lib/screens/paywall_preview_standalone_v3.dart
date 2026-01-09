import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/paywall_service.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../models/subscription_models.dart';
import '../services/haptic_service.dart';

/// V3 - Ton design actuel + animations gaming du trial offer
/// Garde le même contenu/structure mais avec particules et animations progressives
class PaywallPreviewStandaloneV3 extends StatefulWidget {
  final PaywallContext paywallContext;

  const PaywallPreviewStandaloneV3({
    Key? key,
    required this.paywallContext,
  }) : super(key: key);

  @override
  State<PaywallPreviewStandaloneV3> createState() => _PaywallPreviewStandaloneV3State();
}

class _PaywallPreviewStandaloneV3State extends State<PaywallPreviewStandaloneV3>
    with TickerProviderStateMixin {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  bool _showCloseButton = false;

  // Animation controllers
  late AnimationController _particleController;
  late AnimationController _heroController;
  late AnimationController _heroMoveController; // Pour la montée du panda
  late AnimationController _breathingController;
  late AnimationController _pulseController; // Pour l'animation pulse des pricing cards

  // Individual controllers for each element (staggered)
  late AnimationController _titleController;
  late AnimationController _benefitsController;
  late AnimationController _bannerController;
  late AnimationController _pricingController;
  late AnimationController _ctaController;

  // Animations
  late Animation<double> _heroFadeAnimation;
  late Animation<double> _heroScaleAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _heroMoveAnimation; // Animation de montée smooth
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;

  // Individual animations for each element
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _benefitsOpacity;
  late Animation<Offset> _benefitsSlide;
  late Animation<double> _bannerOpacity;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _pricingOpacity;
  late Animation<Offset> _pricingSlide;
  late Animation<double> _ctaOpacity;
  late Animation<Offset> _ctaSlide;

  // Timing variables
  bool _showHero = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Particle animation (continuous)
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Hero animation (avatar entrance)
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _heroScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Hero move animation (smooth upward movement)
    _heroMoveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroMoveAnimation = Tween<double>(
      begin: 0.0, // Starts at center
      end: 1.0,   // Moves to top
    ).animate(CurvedAnimation(
      parent: _heroMoveController,
      curve: Curves.easeInOutCubic,
    ));

    // Individual controllers for staggered animations
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleOpacity = CurvedAnimation(parent: _titleController, curve: Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic));

    _benefitsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _benefitsOpacity = CurvedAnimation(parent: _benefitsController, curve: Curves.easeOut);
    _benefitsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _benefitsController, curve: Curves.easeOutCubic));

    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bannerOpacity = CurvedAnimation(parent: _bannerController, curve: Curves.easeOut);
    _bannerSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bannerController, curve: Curves.easeOutCubic));

    _pricingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pricingOpacity = CurvedAnimation(parent: _pricingController, curve: Curves.easeOut);
    _pricingSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pricingController, curve: Curves.easeOutCubic));

    _ctaController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _ctaOpacity = CurvedAnimation(parent: _ctaController, curve: Curves.easeOut);
    _ctaSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctaController, curve: Curves.easeOutCubic));

    // Breathing animation for avatar
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for pricing cards (continuous subtle pulse)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Staggered animation sequence
    _startAnimationSequence();

    // Close button delay (added 1s for animations)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showCloseButton = true);
    });

    // Haptic feedback
    HapticService.instance.mediumImpact();
  }

  void _startAnimationSequence() async {
    // Step 1: Show hero (avatar + bubble) centered
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _showHero = true);
      _heroController.forward();
    }

    // Step 2: Wait for hero to fully appear, then move it up smoothly
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _heroMoveController.forward(); // Smooth upward movement
    }

    // Step 3: Show content container slightly after hero starts moving
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() => _showContent = true);
    }

    // Step 4: Stagger content animations (each element slides up)
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _benefitsController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _bannerController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _pricingController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) _ctaController.forward();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _heroController.dispose();
    _heroMoveController.dispose();
    _breathingController.dispose();
    _pulseController.dispose();
    _titleController.dispose();
    _benefitsController.dispose();
    _bannerController.dispose();
    _pricingController.dispose();
    _ctaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode == 'fr' ? 'fr' : locale.languageCode == 'de' ? 'de' : 'en';
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Contextual content
    final avatarType = PaywallService.getContextAvatar(widget.paywallContext);
    final benefits = PaywallService.getContextBenefits(widget.paywallContext, languageCode);
    final title = PaywallService.getContextTitle(widget.paywallContext, languageCode);
    final bubbleText = PaywallService.getCoachBubbleText(widget.paywallContext, languageCode);

    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF1A1F4E),
            Color(0xFF0A0E27),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Animated particles background (comme trial offer)
          ..._buildFloatingParticles(),

          // Main content - Taille fixe
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Stack(
              children: [
                // Handle bar and close button at top
                if (_showContent)
                  Column(
                    children: [
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
                      if (_showCloseButton) _buildCloseButton(),
                    ],
                  ),

                // HERO SECTION (Avatar + Bubble) - Starts centered, then moves up smoothly
                AnimatedBuilder(
                  animation: _heroMoveAnimation,
                  builder: (context, child) {
                    final screenHeight = MediaQuery.of(context).size.height * 0.85;
                    final centerY = (screenHeight - 300) / 2;
                    final topY = 50.0;
                    final currentY = centerY + (_heroMoveAnimation.value * (topY - centerY));

                    return Positioned(
                      top: currentY,
                      left: 24,
                      right: 24,
                      child: SlideTransition(
                        position: _heroSlideAnimation,
                        child: FadeTransition(
                          opacity: _heroFadeAnimation,
                          child: ScaleTransition(
                            scale: _heroScaleAnimation,
                            child: _buildHeroSection(avatarType, bubbleText),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // REST OF CONTENT - Appears after hero moves up
                if (_showContent)
                  Positioned(
                    top: 160,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Title - Slides up
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleOpacity,
                              child: _buildTitle(title),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Benefits - Slides up
                          SlideTransition(
                            position: _benefitsSlide,
                            child: FadeTransition(
                              opacity: _benefitsOpacity,
                              child: _buildBenefits(benefits, isFrench, isGerman),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Banner - Slides up
                          SlideTransition(
                            position: _bannerSlide,
                            child: FadeTransition(
                              opacity: _bannerOpacity,
                              child: _buildTrialBanner(isFrench, isGerman),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Pricing cards - Slides up
                          SlideTransition(
                            position: _pricingSlide,
                            child: FadeTransition(
                              opacity: _pricingOpacity,
                              child: _buildPricingCards(isFrench, isGerman),
                            ),
                          ),
                          const SizedBox(height: 26),

                          // CTA - Slides up
                          SlideTransition(
                            position: _ctaSlide,
                            child: FadeTransition(
                              opacity: _ctaOpacity,
                              child: _buildCTA(isFrench, isGerman),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Skip button (delayed)
                          if (_showCloseButton) _buildSkipButton(isFrench, isGerman),

                          // Bottom padding
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Floating particles (from trial offer) - Plus visibles sur fond sombre
  List<Widget> _buildFloatingParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      final size = 2.0 + random.nextDouble() * 4;
      final initialX = random.nextDouble() * 400;
      final initialY = random.nextDouble() * 800;

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = _particleController.value;
          final y = (initialY - progress * 1000) % 1000;

          return Positioned(
            left: initialX + math.sin(progress * 2 * math.pi) * 20,
            top: y,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1 + random.nextDouble() * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: size * 2,
                    spreadRadius: size * 0.5,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: IconButton(
          onPressed: () {
            HapticService.instance.lightImpact();
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(CoachRyzeAvatarType avatarType, String bubbleText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with breathing animation + glow
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathingAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CoachRyzeAvatar(
                    size: CoachRyzeAvatarSize.large,
                    type: avatarType,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Bubble with white background (same as tutorial welcome screen)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                bubbleText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0B132B),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildBenefits(List<Map<String, String>> benefits, bool isFrench, bool isGerman) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 10.0 : 0),
            child: Text(
              '${benefit['icon']} ${benefit['text']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrialBanner(bool isFrench, bool isGerman) {
    return Container(
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
    );
  }

  Widget _buildPricingCards(bool isFrench, bool isGerman) {
    return SizedBox(
      height: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annual
            Expanded(
              child: _buildPricingCard(
                period: SubscriptionPeriod.annual,
                price: '69,99€',
                interval: isFrench ? '/an' : isGerman ? '/Jahr' : '/yr',
                badge: isFrench ? 'Meilleure valeur' : isGerman ? 'Bester Wert' : 'Best value',
                badgeColor: const Color(0xFFFFD700),
                description: isFrench ? 'Économise 49%' : isGerman ? 'Spare 49%' : 'Save 49%',
                equivalentPrice: isFrench ? '5,83€/mois' : isGerman ? '5,83€/Monat' : '€5.83/mo',
                savingsText: isFrench ? 'Économise 49%' : isGerman ? 'Spare 49%' : 'Save 49%',
                isHighlighted: true,
                isFrench: isFrench,
                isGerman: isGerman,
              ),
            ),
            const SizedBox(width: 8),

            // Monthly
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

            // Weekly
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
    );
  }

  Widget _buildPricingCard({
    required SubscriptionPeriod period,
    required String price,
    required String interval,
    required String badge,
    required Color badgeColor,
    String? description,
    String? equivalentPrice,
    String? savingsText,
    bool isHighlighted = false,
    required bool isFrench,
    required bool isGerman,
  }) {
    final isSelected = _selectedPeriod == period;

    String periodName = '';
    if (period == SubscriptionPeriod.annual) {
      periodName = isFrench ? 'Annuel' : isGerman ? 'Jährlich' : 'Annual';
    } else if (period == SubscriptionPeriod.monthly) {
      periodName = isFrench ? 'Mensuel' : isGerman ? 'Monatlich' : 'Monthly';
    } else {
      periodName = isFrench ? 'Hebdo' : isGerman ? 'Wöchentlich' : 'Weekly';
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        HapticService.instance.selectionClick();
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _pulseAnimation.value : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFD700) : const Color(0xFFE5E7EB),
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Name + Radio
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

                  // Price
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

                  // Savings text
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

          // Badge at bottom
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
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
        },
      ),
    );
  }

  /// Get CTA button gradient colors based on context
  List<Color> _getCtaGradient() {
    switch (widget.paywallContext) {
      case PaywallContext.scanner:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold gradient

      case PaywallContext.barcodeScanner:
        return [const Color(0xFFFFD700), const Color(0xFFFF8C00)]; // Gold to Dark Orange

      case PaywallContext.chatInput:
        return [const Color(0xFFFFD700), const Color(0xFFFFB900)]; // Gold to Amber

      case PaywallContext.workoutGenerator:
        return [const Color(0xFFFFD700), const Color(0xFFFF6B00)]; // Gold to Bright Orange

      case PaywallContext.nutritionAnalysis:
        return [const Color(0xFFFFD700), const Color(0xFFF4C430)]; // Gold to Saffron

      case PaywallContext.exerciseAnalysis:
        return [const Color(0xFFFFD700), const Color(0xFFFFAA00)]; // Gold to Orange

      case PaywallContext.genericUpgrade:
        return [const Color(0xFFFFD700), const Color(0xFFDAA520)]; // Gold to Goldenrod (default)
    }
  }

  Widget _buildCTA(bool isFrench, bool isGerman) {
    final gradientColors = _getCtaGradient();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticService.instance.mediumImpact();
                Navigator.pop(context);
              },
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
                    isFrench ? 'DÉBLOQUER MON COACH' : isGerman ? 'MEINEN COACH FREISCHALTEN' : 'UNLOCK MY COACH',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    isFrench ? '3 JOURS GRATUITS' : isGerman ? '3 TAGE KOSTENLOS' : '3 DAYS FREE',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
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
            _getLegalText(isFrench, isGerman),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isFrench, bool isGerman) {
    return AnimatedOpacity(
      opacity: _showCloseButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: TextButton(
        onPressed: _showCloseButton
            ? () {
                HapticService.instance.lightImpact();
                Navigator.pop(context);
              }
            : null,
        child: Text(
          isFrench ? 'Peut-être plus tard' : isGerman ? 'Vielleicht später' : 'Maybe later',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  String _getLegalText(bool isFrench, bool isGerman) {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.monthly:
        return isFrench
            ? 'Puis 9,99€/mois • Annule en 1 clic'
            : isGerman
                ? 'Dann 9,99€/Monat • Mit 1 Klick kündigen'
                : 'Then €9.99/mo • Cancel in 1 click';
      case SubscriptionPeriod.annual:
        return isFrench
            ? 'Puis 69,99€/an • Annule en 1 clic'
            : isGerman
                ? 'Dann 69,99€/Jahr • Mit 1 Klick kündigen'
                : 'Then €69.99/yr • Cancel in 1 click';
      case SubscriptionPeriod.weekly:
        return isFrench
            ? 'Puis 2,99€/sem • Annule en 1 clic'
            : isGerman
                ? 'Dann 2,99€/Woche • Mit 1 Klick kündigen'
                : 'Then €2.99/wk • Cancel in 1 click';
      case SubscriptionPeriod.lifetime:
        return '';
    }
  }
}
