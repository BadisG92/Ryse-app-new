import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/translations.dart';
import 'coach_ryze_avatar.dart';

/// Écran de bienvenue du Coach Ryze avant le tutorial
/// Présente le coach IA et ses capacités
class TutorialWelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final String languageCode;
  final String? pandaImagePath; // Chemin vers l'image du panda
  final String? userName; // Prénom de l'utilisateur pour personnaliser le message

  const TutorialWelcomeScreen({
    super.key,
    required this.onStart,
    required this.onSkip,
    required this.languageCode,
    this.pandaImagePath,
    this.userName,
  });

  @override
  State<TutorialWelcomeScreen> createState() => _TutorialWelcomeScreenState();
}

class _TutorialWelcomeScreenState extends State<TutorialWelcomeScreen>
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF0B132B).withOpacity(0.95),
        child: SafeArea(
          child: Stack(
            children: [
              // Bouton "Passer" en haut à droite
              Positioned(
                top: 16,
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
                    'skip'.tr(widget.languageCode),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Contenu principal centré
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image du Panda (grande)
                          _buildPandaImage(),

                          const SizedBox(height: 32),

                          // Titre de bienvenue personnalisé
                          Text(
                            _getPersonalizedTitle(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Sous-titre
                          Text(
                            widget.languageCode == 'fr'
                                ? 'Ensemble, on va booster ton énergie et tes habitudes !'
                                : 'Together, we\'ll boost your energy and habits!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Liste des capacités du coach
                          _buildCapabilitiesList(),

                          const SizedBox(height: 40),

                          // Bouton "Commencer"
                          _buildStartButton(),

                          const SizedBox(height: 16),

                          // Texte "Passer le tutorial" (discret)
                          TextButton(
                            onPressed: widget.onSkip,
                            child: Text(
                              'tutorial_skip_intro'.tr(widget.languageCode),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPandaImage() {
    // Utiliser l'image fournie ou l'image par défaut de bienvenue
    final imagePath = widget.pandaImagePath ?? 'assets/images/coach_ryze_welcome.png';

    // Vérifier si c'est un SVG
    if (imagePath.endsWith('.svg')) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(30),
        child: SvgPicture.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
      );
    } else {
      // PNG par défaut
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback en cas d'erreur : Icône par défaut
              return Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  LucideIcons.bot,
                  size: 80,
                  color: Color(0xFF0B132B),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Widget _buildCapabilitiesList() {
    final capabilities = [
      {
        'icon': LucideIcons.camera,
        'key': 'tutorial_welcome_feature_1',
        'isSvg': false,
      },
      {
        'icon': LucideIcons.messageCircle, // Même icône que bouton Chat IA
        'key': 'tutorial_welcome_feature_text',
        'isSvg': false,
      },
      {
        'svgPath': 'assets/images/logo_solo.svg', // Logo Ryze pour nutrition
        'key': 'tutorial_welcome_feature_2',
        'isSvg': true,
      },
      {
        'icon': LucideIcons.dumbbell,
        'key': 'tutorial_welcome_feature_3',
        'isSvg': false,
      },
      {
        'icon': LucideIcons.trendingUp,
        'key': 'tutorial_welcome_feature_4',
        'isSvg': false,
      },
      {
        'icon': LucideIcons.target,
        'key': 'tutorial_welcome_feature_5',
        'isSvg': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'tutorial_welcome_capabilities'.tr(widget.languageCode),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...capabilities.map((capability) {
            final isSvg = capability['isSvg'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSvg
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: SvgPicture.asset(
                              capability['svgPath'] as String,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        : Icon(
                            capability['icon'] as IconData,
                            size: 18,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (capability['key'] as String).tr(widget.languageCode),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Générer le titre personnalisé avec le prénom de l'utilisateur
  String _getPersonalizedTitle() {
    final isFrench = widget.languageCode == 'fr';

    if (widget.userName != null && widget.userName!.isNotEmpty) {
      // Capitaliser la première lettre du prénom
      final name = widget.userName!;
      final capitalizedName = name[0].toUpperCase() + name.substring(1);

      return isFrench
          ? 'Salut $capitalizedName ! Moi c\'est Ryze !'
          : 'Hi $capitalizedName! I\'m Ryze!';
    } else {
      // Fallback si pas de prénom
      return isFrench
          ? 'Salut ! Moi c\'est Ryze !'
          : 'Hi! I\'m Ryze!';
    }
  }

  Widget _buildStartButton() {
    return SizedBox(
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
              'tutorial_welcome_start'.tr(widget.languageCode),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, size: 20),
          ],
        ),
      ),
    );
  }
}
