import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../services/subscription_service.dart';
import '../services/unified_subscription_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../models/subscription_models.dart';
import '../components/ui/coach_ryze_avatar.dart';
import '../components/main_app.dart';
import '../services/haptic_service.dart';

/// Modern Trial Offer Screen V2 - Premium onboarding experience
/// Features:
/// - Immersive full-screen design with video-game inspired UI
/// - Neumorphic elements with subtle depth
/// - Particle effects and dynamic animations
/// - Achievement-style benefit cards
/// - Gamified progress indicators
class TrialOfferScreenV2 extends StatefulWidget {
  const TrialOfferScreenV2({Key? key}) : super(key: key);

  @override
  State<TrialOfferScreenV2> createState() => _TrialOfferScreenV2State();
}

class _TrialOfferScreenV2State extends State<TrialOfferScreenV2>
    with TickerProviderStateMixin {
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _heroController;
  late AnimationController _floatingController;
  late AnimationController _particleController;
  late AnimationController _shineController;
  late AnimationController _achievementController;

  // Animations
  late Animation<double> _heroScaleAnimation;
  late Animation<double> _heroRotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _shineAnimation;

  // Achievement card animations
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Hero animation (Coach Ryze entrance)
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _heroScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _heroRotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Shine effect
    _shineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shineAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _shineController,
      curve: Curves.linear,
    ));

    // Achievement cards animation
    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create individual card animations
    for (int i = 0; i < 6; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (i * 100)),
        vsync: this,
      );
      _cardControllers.add(controller);

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
      _cardAnimations.add(animation);
    }
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _heroController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    for (int i = 0; i < _cardControllers.length; i++) {
      _cardControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _floatingController.dispose();
    _particleController.dispose();
    _shineController.dispose();
    _achievementController.dispose();
    for (var controller in _cardControllers) {
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating particles
          ..._buildFloatingParticles(),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _heroController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),

                            // Hero section with Coach Ryze
                            _buildHeroSection(isFrench, isGerman),

                            const SizedBox(height: 40),

                            // Achievement cards
                            _buildAchievementCards(isFrench, isGerman),

                            const SizedBox(height: 40),

                            // Stats section
                            _buildStatsSection(isFrench, isGerman),

                            const SizedBox(height: 40),

                            // CTA section
                            _buildCTASection(isFrench, isGerman),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Skip button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSkipButton(isFrench, isGerman),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_particleController.value * 2 * math.pi) * 0.3,
                math.cos(_particleController.value * 2 * math.pi) * 0.3,
              ),
              radius: 1.5,
              colors: const [
                Color(0xFF1A1F4E),
                Color(0xFF0A0E27),
                Color(0xFF050714),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      final size = 2.0 + random.nextDouble() * 4;
      final initialX = random.nextDouble() * 400;
      final initialY = random.nextDouble() * 800;
      final duration = 10 + random.nextInt(10);

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

  Widget _buildHeroSection(bool isFrench, bool isGerman) {
    return Column(
      children: [
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.trophy, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isFrench ? 'NIVEAU PREMIUM' : isGerman ? 'PREMIUM-STUFE' : 'PREMIUM LEVEL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Coach Ryze with effects
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Rotating ring
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _particleController.value * 2 * math.pi,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Coach avatar
            Transform.scale(
              scale: _heroScaleAnimation.value,
              child: Transform.rotate(
                angle: _heroRotateAnimation.value,
                child: AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: const CoachRyzeAvatar(
                        size: CoachRyzeAvatarSize.xxlarge,
                        type: CoachRyzeAvatarType.workout,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Main title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFBBF24),
              Color(0xFFFF6B6B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            isFrench
                ? 'Débloquez votre\nPotentiel Maximum'
                : isGerman
                    ? 'Entfessle dein\nvolles Potenzial'
                    : 'Unlock Your\nFull Potential',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        Text(
          isFrench
              ? 'Rejoignez 10,000+ athlètes qui ont transformé leur physique'
              : isGerman
                  ? 'Schließe dich 10.000+ Athleten an, die ihren Körper transformiert haben'
                  : 'Join 10,000+ athletes who transformed their body',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementCards(bool isFrench, bool isGerman) {
    final achievements = [
      {
        'icon': '📸',
        'title': isFrench ? 'Scanner IA' : isGerman ? 'KI-Scanner' : 'AI Scanner',
        'desc': isFrench ? 'Photos → Calories' : isGerman ? 'Fotos → Kalorien' : 'Photos → Calories',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': '🎯',
        'title': isFrench ? 'Précision Max' : isGerman ? 'Max. Präzision' : 'Max Precision',
        'desc': isFrench ? '99.9% exact' : isGerman ? '99,9% genau' : '99.9% accurate',
        'color': const Color(0xFF6366F1),
      },
      {
        'icon': '💪',
        'title': isFrench ? 'Coach Personnel' : isGerman ? 'Persönlicher Coach' : 'Personal Coach',
        'desc': isFrench ? '24/7 disponible' : isGerman ? '24/7 verfügbar' : '24/7 available',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': '🔥',
        'title': isFrench ? 'Résultats' : isGerman ? 'Ergebnisse' : 'Results',
        'desc': isFrench ? 'Dès 7 jours' : isGerman ? 'In 7 Tagen' : 'In 7 days',
        'color': const Color(0xFFEF4444),
      },
      {
        'icon': '📊',
        'title': isFrench ? 'Analytics Pro' : isGerman ? 'Pro Analytics' : 'Pro Analytics',
        'desc': isFrench ? 'Graphiques avancés' : isGerman ? 'Erweiterte Diagramme' : 'Advanced charts',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': '🚀',
        'title': isFrench ? 'Boost x10' : isGerman ? 'x10 Boost' : 'x10 Boost',
        'desc': isFrench ? 'Progression accélérée' : isGerman ? 'Beschleunigter Fortschritt' : 'Accelerated progress',
        'color': const Color(0xFF14B8A6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];

        return AnimatedBuilder(
          animation: _cardAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimations[index].value,
              child: GestureDetector(
                onTapDown: (_) => HapticService.instance.lightImpact(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        achievement['color'] as Color,
                        (achievement['color'] as Color).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (achievement['color'] as Color).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shine effect
                      AnimatedBuilder(
                        animation: _shineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: _shineAnimation.value * 200 - 100,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  achievement['icon'] as String,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  achievement['desc'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsSection(bool isFrench, bool isGerman) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('10K+', isFrench ? 'Utilisateurs' : isGerman ? 'Nutzer' : 'Users'),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem('4.9★', isFrench ? 'Note App' : isGerman ? 'App-Bewertung' : 'App Rating'),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem('97%', isFrench ? 'Satisfaits' : isGerman ? 'Zufrieden' : 'Satisfied'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(bool isFrench, bool isGerman) {
    return Column(
      children: [
        // Price badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎁',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                isFrench ? '7 JOURS GRATUITS' : isGerman ? '7 TAGE KOSTENLOS' : '7 DAYS FREE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Main CTA button
        GestureDetector(
          onTapDown: (_) => HapticService.instance.mediumImpact(),
          onTap: _isLoading ? null : () => _startTrial(isFrench, isGerman),
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated shine
                AnimatedBuilder(
                  animation: _shineAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: _shineAnimation.value * MediaQuery.of(context).size.width,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Button content
                Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.zap,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  SubscriptionService.TEST_MODE
                                      ? (isFrench ? '🧪 SIMULER ACTIVATION' : isGerman ? '🧪 AKTIVIERUNG SIMULIEREN' : '🧪 SIMULATE ACTIVATION')
                                      : (isFrench ? 'ACTIVER MON COACH' : isGerman ? 'MEINEN COACH AKTIVIEREN' : 'ACTIVATE MY COACH'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (!SubscriptionService.TEST_MODE)
                                  Text(
                                    isFrench ? 'Annulation facile' : isGerman ? 'Einfache Kündigung' : 'Easy cancellation',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Price info
        Text(
          SubscriptionService.TEST_MODE
              ? (isFrench ? 'Mode TEST activé' : isGerman ? 'TEST-Modus aktiviert' : 'TEST mode enabled')
              : (isFrench
                  ? 'Puis 9,99€/mois après la période d\'essai'
                  : isGerman
                      ? 'Dann 9,99€/Monat nach der Testphase'
                      : 'Then €9.99/month after trial period'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSkipButton(bool isFrench, bool isGerman) {
    return GestureDetector(
      onTap: () => _skipTrial(isFrench, isGerman),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrench ? 'Passer' : isGerman ? 'Überspringen' : 'Skip',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTrial(bool isFrench, bool isGerman) async {
    setState(() => _isLoading = true);
    HapticService.instance.mediumImpact();

    try {
      if (SubscriptionService.TEST_MODE) {
        // Test mode - simulate activation
        await Future.delayed(const Duration(seconds: 2));

        final success = await SubscriptionService.instance.upgradeToPremium(
          period: SubscriptionPeriod.monthly,
          testBypass: true,
        );

        if (!mounted) return;

        if (success) {
          HapticService.instance.heavyImpact();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
        }
      } else {
        // Production mode
        final unifiedService = UnifiedSubscriptionService();
        final success = await unifiedService.upgradeToPremium(
          period: SubscriptionPeriod.monthly,
        );

        if (!mounted) return;

        if (success) {
          HapticService.instance.heavyImpact();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
        } else {
          setState(() => _isLoading = false);
          HapticService.instance.mediumImpact();
        }
      }
    } catch (e) {
      debugPrint('Error starting trial: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);
      HapticService.instance.mediumImpact();

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

  void _skipTrial(bool isFrench, bool isGerman) {
    HapticService.instance.selectionClick();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1F4E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            isFrench ? 'Êtes-vous sûr ?' : isGerman ? 'Bist du sicher?' : 'Are you sure?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isFrench
                ? 'Vous perdrez l\'accès aux fonctionnalités premium comme le scanner IA et le coach personnel.'
                : isGerman
                    ? 'Du verlierst den Zugang zu Premium-Funktionen wie KI-Scanner und persönlichem Coach.'
                    : 'You\'ll lose access to premium features like AI scanner and personal coach.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isFrench ? 'Retour' : isGerman ? 'Zurück' : 'Back',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(this.context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainApp()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isFrench ? 'Continuer gratuitement' : isGerman ? 'Kostenlos fortfahren' : 'Continue for free',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}