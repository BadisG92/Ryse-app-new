import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Écran de bienvenue du tutorial Cardio
class CardioTutorialWelcome extends StatefulWidget {
  final String languageCode;
  final String? userName;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const CardioTutorialWelcome({
    Key? key,
    required this.languageCode,
    this.userName,
    required this.onStart,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<CardioTutorialWelcome> createState() => _CardioTutorialWelcomeState();
}

class _CardioTutorialWelcomeState extends State<CardioTutorialWelcome>
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
        ? 'Bienvenue dans la partie Cardio ! Ici, je vais t\'aider à suivre toutes tes activités cardio : course, vélo, marche, HIIT... Découvre comment enregistrer tes séances et suivre tes progrès !'
        : 'Welcome to the Cardio section! Here, I\'ll help you track all your cardio activities: running, cycling, walking, HIIT... Discover how to record your sessions and track your progress!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

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
                                      LucideIcons.activity,
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

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bouton "Passer" en haut à droite
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                widget.languageCode == 'fr' ? 'Passer' : 'Skip',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
