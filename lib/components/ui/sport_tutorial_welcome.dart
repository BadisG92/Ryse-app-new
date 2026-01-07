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

  String _getRyzeMessage() {
    return widget.languageCode == 'fr'
        ? 'Bienvenue dans ton espace Sport ! Découvre comment je peux t\'accompagner.'
        : widget.languageCode == 'de'
            ? 'Willkommen in deinem Sport-Bereich! Entdecke, wie ich dich unterstützen kann.'
            : 'Welcome to your Sport space! Discover how I can support you.';
  }

  String _getDescription() {
    return widget.languageCode == 'fr'
        ? 'Ici, je t\'accompagne pour suivre tes entraînements, gérer tes séances de cardio et musculation, et t\'aider à progresser vers tes objectifs fitness.'
        : widget.languageCode == 'de'
            ? 'Hier begleite ich dich, um deine Trainings zu verfolgen, deine Cardio- und Krafttraining-Einheiten zu verwalten und dir zu helfen, deine Fitness-Ziele zu erreichen.'
            : 'Here, I help you track your workouts, manage your cardio and strength training sessions, and help you progress towards your fitness goals.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Stack(
        children: [
          // Contenu principal
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
                        // Section panda + bulle (même style que page d'accueil)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Bulle de dialogue à GAUCHE
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Nom "Coach Ryze" au-dessus de la bulle
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                                    child: Text(
                                      'Coach Ryze',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.7),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  // Bulle de message
                                  Container(
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
                                      _getRyzeMessage(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF0B132B),
                                        fontWeight: FontWeight.w600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Panda à DROITE
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                width: 140,
                                height: 140,
                                child: Image.asset(
                                  'assets/images/coach_ryze_workout_avatar.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      LucideIcons.dumbbell,
                                      size: 70,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Description
                        Text(
                          _getDescription(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Bouton Commencer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0B132B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.languageCode == 'fr'
                                      ? 'Commencer la visite'
                                      : widget.languageCode == 'de'
                                          ? 'Tour starten'
                                          : 'Start the tour',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.arrowRight, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
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
                widget.languageCode == 'fr'
                    ? 'Passer'
                    : widget.languageCode == 'de'
                        ? 'Überspringen'
                        : 'Skip',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
