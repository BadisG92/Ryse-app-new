import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Écran de bienvenue du tutorial Sport
class SportTutorialWelcome extends StatefulWidget {
  final String languageCode;
  final String? userName;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const SportTutorialWelcome({
    Key? key,
    required this.languageCode,
    this.userName,
    required this.onStart,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<SportTutorialWelcome> createState() => _SportTutorialWelcomeState();
}

class _SportTutorialWelcomeState extends State<SportTutorialWelcome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getWelcomeMessage() {
    return widget.languageCode == 'fr'
        ? 'Bienvenue dans la partie Sport ! Ici, je vais t\'accompagner pour suivre tes entraînements, gérer tes séances de cardio et musculation, et t\'aider à progresser vers tes objectifs fitness.'
        : 'Welcome to the Sport section! Here, I\'ll help you track your workouts, manage your cardio and strength training sessions, and help you progress towards your fitness goals.';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B).withOpacity(0.8),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Bulle de dialogue avec avatar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar + Message
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar du panda workout
                              SizedBox(
                                width: 128,
                                height: 128,
                                child: Image.asset(
                                  'assets/images/coach_ryze_workout_avatar.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      LucideIcons.dumbbell,
                                      size: 70,
                                      color: Color(0xFF0B132B),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Message
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getWelcomeMessage(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF0B132B),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Bouton Commencer
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onStart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B132B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.languageCode == 'fr'
                                    ? 'Commencer'
                                    : 'Start',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bouton Passer (discret)
                    TextButton(
                      onPressed: widget.onSkip,
                      child: Text(
                        widget.languageCode == 'fr' ? 'Passer' : 'Skip',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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
