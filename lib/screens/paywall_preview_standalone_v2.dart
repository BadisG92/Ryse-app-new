import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/paywall_service.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../models/subscription_models.dart';

/// Version V2 moderne du paywall standalone - Tient dans un bottom sheet sans scroll
/// Design premium avec gradients, glassmorphism et micro-animations
class PaywallPreviewStandaloneV2 extends StatefulWidget {
  final PaywallContext paywallContext;

  const PaywallPreviewStandaloneV2({
    Key? key,
    required this.paywallContext,
  }) : super(key: key);

  @override
  State<PaywallPreviewStandaloneV2> createState() => _PaywallPreviewStandaloneV2State();
}

class _PaywallPreviewStandaloneV2State extends State<PaywallPreviewStandaloneV2>
    with TickerProviderStateMixin {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  bool _showCloseButton = false;

  // Animation controllers
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;

  // Animations
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer effect for gradient
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    // Pulse effect for CTA
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    // Start entrance animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });

    // Close button delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showCloseButton = true);
    });

    // Haptic feedback on load
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode == 'fr' ? 'fr' : 'en';
    final isFrench = languageCode == 'fr';

    // Contextual content
    final avatarType = PaywallService.getContextAvatar(widget.paywallContext);
    final benefits = PaywallService.getContextBenefits(widget.paywallContext, languageCode);
    final title = PaywallService.getContextTitle(widget.paywallContext, languageCode);
    final bubbleText = PaywallService.getCoachBubbleText(widget.paywallContext, languageCode);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF8FAFC),
                const Color(0xFFEEF2FF),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              // Animated gradient overlay
              _buildAnimatedGradientOverlay(),

              // Main content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Close button (delayed)
                  if (_showCloseButton) _buildCloseButton(),

                  // Coach avatar with bubble
                  _buildCoachSection(avatarType, bubbleText),
                  const SizedBox(height: 12),

                  // Title with gradient text
                  _buildTitle(title),
                  const SizedBox(height: 12),

                  // Benefits (compact - 3 only)
                  _buildBenefits(benefits),
                  const SizedBox(height: 12),

                  // Free trial banner
                  _buildTrialBanner(isFrench),
                  const SizedBox(height: 12),

                  // Pricing cards (3 columns)
                  _buildPricingCards(isFrench),
                  const SizedBox(height: 32),

                  // CTA button
                  _buildCTA(isFrench),
                  const SizedBox(height: 12),

                  // Skip button
                  if (_showCloseButton) _buildSkipButton(isFrench),

                  // Bottom padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientOverlay() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_shimmerAnimation.value - 1, -1),
                  end: Alignment(_shimmerAnimation.value, 1),
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 4),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
              ),
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

  Widget _buildCoachSection(CoachRyzeAvatarType avatarType, String bubbleText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CoachRyzeAvatar(
              size: CoachRyzeAvatarSize.large,
              type: CoachRyzeAvatarType.workout,
            ),
          ),
          const SizedBox(width: 12),

          // Glassmorphic bubble
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.9),
                    const Color(0xFF6366F1).withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                bubbleText,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
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
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits(List<Map<String, String>> benefits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: benefits.take(3).map((benefit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    benefit['icon']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit['text']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrialBanner(bool isFrench) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎁',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              isFrench ? '7 JOURS GRATUITS' : '7 DAYS FREE',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCards(bool isFrench) {
    return SizedBox(
      height: 115,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Annual
            Expanded(
              child: _buildPricingCard(
                period: SubscriptionPeriod.annual,
                price: '69,99€',
                interval: isFrench ? '/an' : '/yr',
                badge: isFrench ? 'Meilleur prix' : 'Best value',
                badgeGradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
                equivalent: '5,83€',
                isFrench: isFrench,
              ),
            ),
            const SizedBox(width: 8),

            // Monthly (Popular)
            Expanded(
              child: _buildPricingCard(
                period: SubscriptionPeriod.monthly,
                price: '9,99€',
                interval: isFrench ? '/mois' : '/mo',
                badge: isFrench ? 'Populaire' : 'Popular',
                badgeGradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                ),
                isPopular: true,
                isFrench: isFrench,
              ),
            ),
            const SizedBox(width: 8),

            // Weekly
            Expanded(
              child: _buildPricingCard(
                period: SubscriptionPeriod.weekly,
                price: '2,99€',
                interval: isFrench ? '/sem' : '/wk',
                badge: isFrench ? 'Test' : 'Try',
                badgeGradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                ),
                isFrench: isFrench,
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
    required Gradient badgeGradient,
    String? equivalent,
    bool isPopular = false,
    required bool isFrench,
  }) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        HapticFeedback.selectionClick();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Radio indicator
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 8),

                  // Price
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF0B132B),
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: interval,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Equivalent price
                  if (equivalent != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${isFrench ? "soit" : "or"} $equivalent${isFrench ? "/mois" : "/mo"}',
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Badge at bottom
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: badgeGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(bool isFrench) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isFrench ? 'DÉBLOQUER MON COACH' : 'UNLOCK MY COACH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              isFrench ? '7 JOURS GRATUITS' : '7 DAYS FREE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _getLegalText(isFrench),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(bool isFrench) {
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Text(
        isFrench ? 'Peut-être plus tard' : 'Maybe later',
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  String _getLegalText(bool isFrench) {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.weekly:
        return isFrench
            ? 'Puis 2,99€/sem • Annule en 1 clic'
            : 'Then €2.99/wk • Cancel in 1 click';
      case SubscriptionPeriod.monthly:
        return isFrench
            ? 'Puis 9,99€/mois • Annule en 1 clic'
            : 'Then €9.99/mo • Cancel in 1 click';
      case SubscriptionPeriod.annual:
        return isFrench
            ? 'Puis 69,99€/an • Annule en 1 clic'
            : 'Then €69.99/yr • Cancel in 1 click';
      case SubscriptionPeriod.lifetime:
        return '';
    }
  }
}
