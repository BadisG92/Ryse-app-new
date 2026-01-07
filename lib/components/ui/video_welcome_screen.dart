import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../services/translations.dart';

/// Video welcome screen that plays a looping fullscreen video with a minimal
/// overlay button to enter the app. Creates an immersive first impression.
class VideoWelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final String videoAssetPath;
  final String? backgroundImagePath; // Static image to extend the video
  final String? buttonText;

  const VideoWelcomeScreen({
    Key? key,
    required this.onContinue,
    this.videoAssetPath = 'assets/videos/welcome_screen_video.mp4',
    this.backgroundImagePath =
        'assets/images/welcome_background.png', // Same scene as video
    this.buttonText,
  }) : super(key: key);

  @override
  State<VideoWelcomeScreen> createState() => _VideoWelcomeScreenState();
}

class _VideoWelcomeScreenState extends State<VideoWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  // Animation for the button entrance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoAssetPath);

      await _controller.initialize();

      // Set video to loop
      _controller.setLooping(true);

      // Start playing
      _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start button animation after video is ready
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        // Still show the button even if video fails
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine button text based on locale
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    final buttonLabel = widget.buttonText ?? 'welcome_join_us'.tr(langCode);

    return Scaffold(
      backgroundColor:
          const Color(0xFF1E1008), // Dark warm brown matching video floor
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Static background image (covers full screen)
          if (widget.backgroundImagePath != null) _buildBackgroundImage(),

          // 2. Video on top (perfectly aligned with background)
          if (_isInitialized && !_hasError)
            _buildFullscreenVideo()
          else if (_hasError)
            _buildFallbackBackground()
          else
            _buildLoadingState(),

          // 3. Subtle gradient at bottom for button visibility
          _buildBottomGradient(),

          // 4. Just the button at the bottom
          _buildButtonOverlay(buttonLabel),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final screenSize = MediaQuery.of(context).size;

    // Known dimensions (updated for taller background)
    const bgWidth = 1023.0;
    const bgHeight = 1313.0;
    const videoWidth = 540.0;
    const videoX = 241.5; // Video X offset on background ((1023-540)/2)

    // Scale based on WIDTH only (same as video)
    final scale = screenSize.width / videoWidth;

    // Scaled dimensions
    final scaledBgWidth = bgWidth * scale;
    final scaledBgHeight = bgHeight * scale;
    final scaledVideoX = videoX * scale;

    // Video is at (0, 0), so background position:
    // bgLeft + scaledVideoX = 0 → bgLeft = -scaledVideoX
    final bgLeft = -scaledVideoX;
    const bgTop = 0.0;

    return Positioned(
      left: bgLeft,
      top: bgTop,
      width: scaledBgWidth,
      height: scaledBgHeight,
      child: Image.asset(
        widget.backgroundImagePath!,
        fit: BoxFit.fill, // Fill the calculated space
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1E1008),
          );
        },
      ),
    );
  }

  Widget _buildFullscreenVideo() {
    final screenSize = MediaQuery.of(context).size;

    // Known dimensions
    const videoWidth = 540.0;
    const videoHeight = 960.0;

    // Scale based on WIDTH only (most phones are taller than 9:16)
    final scale = screenSize.width / videoWidth;

    // Scaled video dimensions (keeps proportions)
    final scaledVideoWidth = videoWidth * scale; // = screen width
    final scaledVideoHeight = videoHeight * scale;

    // Video fills width, aligned to TOP (Ryze logo always visible)
    const videoLeft = 0.0;
    const videoTop = 0.0;

    return Positioned(
      left: videoLeft,
      top: videoTop,
      child: SizedBox(
        width: scaledVideoWidth,
        height: scaledVideoHeight,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    // Warm gradient fallback matching video tones
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3D2317), // Warm brown top
            Color(0xFF2D1810), // Darker warm brown
            Color(0xFF1E0F08), // Dark bottom
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF2D1810), // Match background
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 280, // Taller gradient for smoother transition
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF3D2A1A).withOpacity(0.4), // Warm brown
              const Color(0xFF2D1810).withOpacity(0.85), // Match scaffold
              const Color(0xFF1E1008), // Dark warm
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonOverlay(String buttonLabel) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildGlassButton(buttonLabel),
            ),
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
          // Glass effect with blur simulation
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
