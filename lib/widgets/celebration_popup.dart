import 'package:flutter/material.dart';
import 'dart:async';
import '../services/localization_service.dart';

class CelebrationPopup extends StatefulWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onDismiss;
  final String celebrationType; // 'workout', 'food', 'nutrition'
  final String? actionDescription;

  const CelebrationPopup({
    Key? key,
    required this.message,
    this.subtitle,
    this.onDismiss,
    this.celebrationType = 'workout',
    this.actionDescription,
  }) : super(key: key);

  @override
  State<CelebrationPopup> createState() => _CelebrationPopupState();

  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    String celebrationType = 'workout',
    VoidCallback? onDismiss,
    String? actionDescription,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent, // Transparent barrier
      useSafeArea: false, // Important: ne pas respecter les safe areas
      useRootNavigator: true,
      builder: (context) => CelebrationPopup(
        message: message,
        subtitle: subtitle,
        celebrationType: celebrationType,
        onDismiss: onDismiss,
        actionDescription: actionDescription,
      ),
    );
  }
}

class _CelebrationPopupState extends State<CelebrationPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation
    _animationController.forward();

    // Auto-dismiss after 5 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;

    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  String _getCoachImagePath() {
    // Different coach images based on celebration type
    switch (widget.celebrationType) {
      case 'workout':
        return 'assets/images/coach_ryze_sport_avatar.png';
      case 'food':
      case 'nutrition':
        return 'assets/images/coach_ryze_chef_avatar.png';
      default:
        return 'assets/images/coach_ryze_congratulations.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: GestureDetector(
          onTap: _dismiss,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
                maxWidth: MediaQuery.of(context).size.width,
                minHeight: MediaQuery.of(context).size.height,
                maxHeight: MediaQuery.of(context).size.height,
              ),
              // Semi-transparent blue background overlay
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.85),
                    const Color(0xFF0B132B).withOpacity(0.95),
                  ],
                ),
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  if (widget.actionDescription != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.actionDescription!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Coach Ryze Image - No circle background, just shadow
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _getCoachImagePath(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image doesn't exist
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events,
                              size: 100,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Celebration message - Bigger text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                      ),
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                        ),
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 60),

                  // Dismiss hint with subtle animation
                  Opacity(
                    opacity: 0.6,
                    child: Column(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white.withOpacity(0.7),
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        DefaultTextStyle(
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                          ),
                          child: Text(
                            LocalizationService.instance.isGerman
                                ? "Tippe irgendwo, um fortzufahren"
                                : (LocalizationService.instance.currentLanguageCode == 'en'
                                    ? "Tap anywhere to continue"
                                    : "Touche l'écran pour continuer"),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.none,
                            ),
                          ),
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
      ),
    );
  }
}
