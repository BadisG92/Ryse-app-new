import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Premier écran de bienvenue affiché avant les slides de value proposition
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final String languageCode;

  const WelcomeScreen({
    Key? key,
    required this.onContinue,
    required this.languageCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo Ryze en haut (taille originale)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/logo_solo.svg',
                        width: 28,
                        height: 28,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nom "Ryze"
                  const Text(
                    'Ryze',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B132B),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Avatar panda au centre (taille originale)
              SizedBox(
                width: 280,
                height: 280,
                child: Image.asset(
                  'assets/images/coach_ryze_welcome_arms.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🐼', style: TextStyle(fontSize: 120)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Titre principal
              Text(
                isFrench
                    ? 'Salut, je suis Coach Ryze !'
                    : isGerman
                        ? 'Hallo, ich bin Coach Ryze!'
                        : 'Hi, I\'m Coach Ryze!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B132B),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Sous-titre (type de coach)
              Text(
                isFrench
                    ? 'Ton coach nutrition & sport'
                    : isGerman
                        ? 'Dein Fitness- & Ernährungscoach'
                        : 'Your nutrition & fitness coach',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Message d'intro
              Text(
                isFrench
                    ? 'Je vais te montrer comment atteindre\ntes objectifs sans te compliquer la vie'
                    : isGerman
                        ? 'Ich werde dir helfen, deine Ziele zu erreichen\nohne es zu kompliziert zu machen'
                        : 'Let me show you how to reach your goals\nwithout overcomplicating things',
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Indicateurs de progression (4 points: Welcome + 3 slides)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == 0 ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 0
                        ? const Color(0xFF0B132B)
                        : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Bouton Continuer en bas
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFrench
                            ? 'C\'est parti !'
                            : isGerman
                                ? 'Starten!'
                                : 'Let\'s go!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
