import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Écran de bienvenue du tutorial Nutrition
class NutritionTutorialWelcome extends StatefulWidget {
  final String languageCode;
  final String? userName;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const NutritionTutorialWelcome({
    Key? key,
    required this.languageCode,
    this.userName,
    required this.onStart,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<NutritionTutorialWelcome> createState() => _NutritionTutorialWelcomeState();
}

class _NutritionTutorialWelcomeState extends State<NutritionTutorialWelcome>
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

  String _getTitle() {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      final name = widget.userName!;
      final capitalizedName = name[0].toUpperCase() + name.substring(1);
      return widget.languageCode == 'fr'
          ? 'Bienvenue dans Nutrition, $capitalizedName !'
          : 'Welcome to Nutrition, $capitalizedName!';
    }
    return widget.languageCode == 'fr'
        ? 'Bienvenue dans Nutrition !'
        : 'Welcome to Nutrition!';
  }

  String _getSubtitle() {
    return widget.languageCode == 'fr'
        ? 'Prenez de bonnes habitudes alimentaires et suivez vos objectifs nutritionnels.'
        : 'Build healthy eating habits and track your nutrition goals.';
  }

  List<Map<String, dynamic>> _getFeatures() {
    return [
      {
        'icon': LucideIcons.activity,
        'title': widget.languageCode == 'fr' ? 'Tableau de bord' : 'Dashboard',
        'desc': widget.languageCode == 'fr'
            ? 'Visualisez vos calories, macros et objectifs du jour en un coup d\'œil'
            : 'View your calories, macros and daily goals at a glance',
      },
      {
        'icon': LucideIcons.bookOpen,
        'title': widget.languageCode == 'fr' ? 'Journal alimentaire' : 'Food Journal',
        'desc': widget.languageCode == 'fr'
            ? 'Consultez l\'historique complet de tous vos repas et aliments'
            : 'View the complete history of all your meals and foods',
      },
      {
        'icon': LucideIcons.chefHat,
        'title': widget.languageCode == 'fr' ? 'Mes recettes' : 'My Recipes',
        'desc': widget.languageCode == 'fr'
            ? 'Créez et sauvegardez vos recettes favorites pour les réutiliser'
            : 'Create and save your favorite recipes to reuse them',
      },
      {
        'icon': LucideIcons.camera,
        'title': widget.languageCode == 'fr' ? 'Ajout rapide' : 'Quick Add',
        'desc': widget.languageCode == 'fr'
            ? 'Scanner IA, code-barres, recherche manuelle ou recettes enregistrées'
            : 'AI scanner, barcode, manual search or saved recipes',
      },
    ];
  }

  String _getWelcomeMessage() {
    return widget.languageCode == 'fr'
        ? 'Bienvenue dans la partie Nutrition ! Ici, je vais t\'aider à suivre tes habitudes alimentaires et t\'accompagner pour avoir un régime équilibré et cohérent avec tes objectifs.'
        : 'Welcome to the Nutrition section! Here, I\'ll help you track your eating habits and guide you towards a balanced diet that matches your goals.';
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
                          // Bulle à gauche + Avatar à droite
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Message à GAUCHE
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Label "Coach Ryze"
                                    const Text(
                                      'Coach Ryze',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Message
                                    Text(
                                      _getWelcomeMessage(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF0B132B),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Avatar du panda à DROITE
                              Expanded(
                                flex: 2,
                                child: Image.asset(
                                  'assets/images/coach_ryze_nutrition_avatar.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      LucideIcons.chefHat,
                                      size: 70,
                                      color: Color(0xFF0B132B),
                                    );
                                  },
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
      ),
    );
  }
}
