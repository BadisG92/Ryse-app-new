import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../services/translations.dart';

/// Onboarding video screen that plays a single video before the AI chat.
/// Video is displayed with preserved aspect ratio (letterbox/pillarbox with black bars).
class OnboardingVideoScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final String videoAssetPath;

  const OnboardingVideoScreen({
    Key? key,
    required this.onContinue,
    this.videoAssetPath = 'assets/videos/onboarding_video.mp4',
  }) : super(key: key);

  @override
  State<OnboardingVideoScreen> createState() => _OnboardingVideoScreenState();
}

class _OnboardingVideoScreenState extends State<OnboardingVideoScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showButton = false;
  bool _videoEnded = false;

  // Animation for the button entrance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;


  @override
  void initState() {
    super.initState();
    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setupAnimations();
    // Small delay to ensure smooth transition after login
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _initializeVideo();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

  }

  String _getWelcomeText(String langCode) {
    switch (langCode) {
      case 'fr':
        return 'Bienvenue';
      case 'de':
        return 'Willkommen';
      default:
        return 'Welcome';
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoAssetPath);

      await _controller.initialize();

      // Do NOT loop - play once only
      _controller.setLooping(false);

      // Listen for video end
      _controller.addListener(_onVideoUpdate);

      // Start playing
      _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing onboarding video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        // If video fails, skip directly to next screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onContinue();
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _videoEnded) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    // Check if video has ended (position >= duration - small buffer)
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      _videoEnded = true;
      setState(() {
        _showButton = true;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine button text based on device locale
    final deviceLocale = Platform.localeName; // e.g., "fr_FR"
    final rawLang = deviceLocale.split('_').first; // Extract "fr"
    final langCode = (rawLang == 'fr' || rawLang == 'de') ? rawLang : 'en';
    final buttonLabel = 'onboarding_lets_meet'.tr(langCode);
    final welcomeText = _getWelcomeText(langCode);
    debugPrint('🌍 OnboardingVideo - deviceLocale: $deviceLocale, langCode: $langCode, welcomeText: $welcomeText');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player (centered with preserved aspect ratio)
          if (_isInitialized && !_hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else if (!_hasError)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),

          // Button overlay (appears when video ends)
          if (_showButton) _buildButtonOverlay(buttonLabel, welcomeText),
        ],
      ),
    );
  }

  Widget _buildButtonOverlay(String buttonLabel, String welcomeText) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Bienvenue" text with slide-in reveal animation from left
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Text(
                    welcomeText,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Button with existing animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildGlassButton(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label) {
    return GestureDetector(
      onTap: widget.onContinue,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          // Glass effect
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
