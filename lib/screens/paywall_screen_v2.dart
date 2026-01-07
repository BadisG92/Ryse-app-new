import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/unified_subscription_service.dart';
import '../services/paywall_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/haptic_service.dart';
import '../components/ui/coach_ryze_avatar.dart';

/// Modern Paywall Screen V2 - Conversion-focused design
/// Features:
/// - Gradient mesh backgrounds with animated particles
/// - Glassmorphism pricing cards
/// - Staggered animations
/// - Tactile interactions with haptic feedback
/// - Modern typography (Clash Display + DM Sans)
class PaywallScreenV2 extends StatefulWidget {
  final PaywallContext context;
  final String? customTitle;
  final String? customMessage;

  const PaywallScreenV2({
    Key? key,
    required this.context,
    this.customTitle,
    this.customMessage,
  }) : super(key: key);

  @override
  State<PaywallScreenV2> createState() => _PaywallScreenV2State();
}

class _PaywallScreenV2State extends State<PaywallScreenV2>
    with TickerProviderStateMixin {
  final _subscriptionService = SubscriptionService.instance;
  final _unifiedService = UnifiedSubscriptionService();
  bool _isProcessing = false;
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _selectedCardController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  // Stagger animation delays
  final List<double> _benefitDelays = [0, 100, 200, 300, 400, 500];
  final Map<int, AnimationController> _benefitControllers = {};

  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Delayed close button appearance
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showCloseButton = true);
    });

    // Trigger haptic feedback on load
    HapticService.instance.mediumImpact();
  }

  void _initAnimations() {
    // Main animation controller
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Floating animation for background elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for CTA button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Selected card animation
    _selectedCardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Start main animation
    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _selectedCardController.dispose();
    for (var controller in _benefitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context);
    final languageCode = locService.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Contextual content
    final avatarType = PaywallService.getContextAvatar(widget.context);
    final title = widget.customTitle ??
        PaywallService.getContextTitle(widget.context, languageCode);
    final benefits = PaywallService.getContextBenefits(widget.context, languageCode);
    final bubbleText = PaywallService.getCoachBubbleText(widget.context, languageCode);

    return AnimatedBuilder(
      animation: _mainAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF1E3A8A), const Color(0xFF312E81), 0.5)!,
                Color.lerp(const Color(0xFF6B21A8), const Color(0xFF831843), 0.5)!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              // Animated gradient mesh background
              ..._buildBackgroundParticles(),

              // Main content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Handle bar
                        const SizedBox(height: 8),
                        Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        // Close button (delayed appearance)
                        if (_showCloseButton) _buildCloseButton(),

                        // Coach avatar with speech bubble
                        _buildCoachSection(avatarType, bubbleText),

                        const SizedBox(height: 32),

                        // Main title with gradient text
                        _buildTitle(title),

                        const SizedBox(height: 24),

                        // Animated benefits
                        _buildAnimatedBenefits(benefits),

                        const SizedBox(height: 40),

                        // Glassmorphism pricing cards
                        _buildPricingSection(isFrench, isGerman),

                        const SizedBox(height: 32),

                        // CTA section
                        _buildCTASection(isFrench, isGerman),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBackgroundParticles() {
    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: 50.0 + (index * 150),
            left: index.isEven ? -50 : null,
            right: index.isOdd ? -50 : null,
            child: Transform.translate(
              offset: Offset(
                index.isEven ? _floatingAnimation.value : -_floatingAnimation.value,
                _floatingAnimation.value * 0.5,
              ),
              child: Container(
                width: 200 + (index * 20).toDouble(),
                height: 200 + (index * 20).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
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
        padding: const EdgeInsets.all(16),
        child: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              LucideIcons.x,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachSection(CoachRyzeAvatarType avatarType, String bubbleText) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Glass bubble
              Positioned(
                top: -20,
                right: -40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 200),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    bubbleText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              // Avatar with glow effect
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: CoachRyzeAvatar(
                  size: CoachRyzeAvatarSize.xxlarge,
                  type: avatarType,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimatedBenefits(List<Map<String, String>> benefits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: benefits.asMap().entries.map((entry) {
          final index = entry.key;
          final benefit = entry.value;

          // Create controller if not exists
          if (!_benefitControllers.containsKey(index)) {
            final controller = AnimationController(
              duration: const Duration(milliseconds: 800),
              vsync: this,
            );
            _benefitControllers[index] = controller;

            // Start animation with delay
            Future.delayed(Duration(milliseconds: 500 + (index * 100)), () {
              if (mounted) controller.forward();
            });
          }

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _benefitControllers[index]!,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.2, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _benefitControllers[index]!,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        benefit['icon']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        benefit['text']!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingSection(bool isFrench, bool isGerman) {
    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPricingCard(
            period: SubscriptionPeriod.annual,
            price: '69,99€',
            originalPrice: '119,88€',
            interval: isFrench ? '/an' : isGerman ? '/Jahr' : '/year',
            monthlyEquivalent: '5,83€',
            badge: isFrench ? 'ÉCONOMISE 42%' : isGerman ? 'SPARE 42%' : 'SAVE 42%',
            isPopular: false,
            gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
            isFrench: isFrench,
            isGerman: isGerman,
          ),
          const SizedBox(width: 16),
          _buildPricingCard(
            period: SubscriptionPeriod.monthly,
            price: '9,99€',
            originalPrice: null,
            interval: isFrench ? '/mois' : isGerman ? '/Monat' : '/month',
            monthlyEquivalent: null,
            badge: isFrench ? 'LE PLUS POPULAIRE' : isGerman ? 'AM BELIEBTESTEN' : 'MOST POPULAR',
            isPopular: true,
            gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
            isFrench: isFrench,
            isGerman: isGerman,
          ),
          const SizedBox(width: 16),
          _buildPricingCard(
            period: SubscriptionPeriod.weekly,
            price: '2,99€',
            originalPrice: null,
            interval: isFrench ? '/semaine' : isGerman ? '/Woche' : '/week',
            monthlyEquivalent: '12,96€',
            badge: isFrench ? 'ESSAI COURT' : isGerman ? 'KURZER TEST' : 'SHORT TRIAL',
            isPopular: false,
            gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
            isFrench: isFrench,
            isGerman: isGerman,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required SubscriptionPeriod period,
    required String price,
    String? originalPrice,
    required String interval,
    String? monthlyEquivalent,
    required String badge,
    required bool isPopular,
    required List<Color> gradientColors,
    required bool isFrench,
    required bool isGerman,
  }) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        HapticService.instance.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 160,
        transform: Matrix4.identity()
          ..translate(0.0, isSelected ? -10.0 : 0.0)
          ..scale(isSelected ? 1.05 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected ? gradientColors : [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: isSelected
                ? ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.overlay),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? gradientColors.first
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      // Original price (strikethrough)
                      if (originalPrice != null)
                        Text(
                          originalPrice,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white.withOpacity(0.5),
                          ),
                        ),

                      // Current price
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                          letterSpacing: -1,
                        ),
                      ),

                      // Interval
                      Text(
                        interval,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Monthly equivalent
                  if (monthlyEquivalent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isFrench ? "soit" : isGerman ? "oder" : "or"} $monthlyEquivalent${isFrench ? "/mois" : isGerman ? "/Mo." : "/mo"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),

                  // Popular indicator
                  if (isPopular)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) =>
                        Icon(
                          Icons.star,
                          size: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTASection(bool isFrench, bool isGerman) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Trust badges
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTrustBadge('🔒', isFrench ? 'Sécurisé' : isGerman ? 'Sicher' : 'Secure'),
                _buildTrustBadge('🎯', isFrench ? 'Garanti' : isGerman ? 'Garantiert' : 'Guaranteed'),
                _buildTrustBadge('⚡', isFrench ? 'Instantané' : isGerman ? 'Sofort' : 'Instant'),
              ],
            ),
          ),

          // Main CTA button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessing ? null : _handlePurchase,
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.sparkles,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getCTAText(isFrench, isGerman),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
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

          const SizedBox(height: 12),

          // Legal text
          Text(
            _getLegalText(isFrench, isGerman),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Skip button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              isFrench ? 'Peut-être plus tard' : isGerman ? 'Vielleicht später' : 'Maybe later',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(String emoji, String text) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getCTAText(bool isFrench, bool isGerman) {
    if (SubscriptionService.TEST_MODE) {
      return isFrench ? '🧪 SIMULER PAIEMENT' : isGerman ? '🧪 ZAHLUNG SIMULIEREN' : '🧪 SIMULATE PAYMENT';
    }

    switch (_selectedPeriod) {
      case SubscriptionPeriod.weekly:
      case SubscriptionPeriod.monthly:
      case SubscriptionPeriod.annual:
        return isFrench
            ? 'DÉBUTER MON ESSAI GRATUIT'
            : isGerman ? 'KOSTENLOSE TESTVERSION STARTEN' : 'START MY FREE TRIAL';
      case SubscriptionPeriod.lifetime:
        return isFrench ? 'CONTINUER' : isGerman ? 'WEITER' : 'CONTINUE';
    }
  }

  String _getLegalText(bool isFrench, bool isGerman) {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.weekly:
        return isFrench
            ? '7 jours gratuits, puis 2,99€/semaine\nAnnulation en 1 clic'
            : isGerman ? '7 Tage kostenlos, dann 2,99€/Woche\nMit 1 Klick kündigen' : '7 days free, then €2.99/week\nCancel with 1 click';
      case SubscriptionPeriod.monthly:
        return isFrench
            ? '7 jours gratuits, puis 9,99€/mois\nAnnulation en 1 clic'
            : isGerman ? '7 Tage kostenlos, dann 9,99€/Monat\nMit 1 Klick kündigen' : '7 days free, then €9.99/month\nCancel with 1 click';
      case SubscriptionPeriod.annual:
        return isFrench
            ? '7 jours gratuits, puis 69,99€/an\nAnnulation en 1 clic'
            : isGerman ? '7 Tage kostenlos, dann 69,99€/Jahr\nMit 1 Klick kündigen' : '7 days free, then €69.99/year\nCancel with 1 click';
      case SubscriptionPeriod.lifetime:
        return '';
    }
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);
    HapticService.instance.mediumImpact();

    try {
      if (SubscriptionService.TEST_MODE) {
        // Test mode
        final success = await _subscriptionService.upgradeToPremium(
          period: _selectedPeriod,
          testBypass: true,
        );

        if (!mounted) return;

        if (success) {
          HapticService.instance.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🧪 TEST: Premium activé!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Production mode
        final success = await _unifiedService.upgradeToPremium(
          period: _selectedPeriod,
        );

        if (!mounted) return;

        if (success) {
          HapticService.instance.heavyImpact();
          Navigator.pop(context, true);
        } else {
          HapticService.instance.mediumImpact();
        }
      }
    } catch (e) {
      HapticService.instance.mediumImpact();
      debugPrint('Error during purchase: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}