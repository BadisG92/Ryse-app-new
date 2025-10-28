import 'package:flutter/material.dart';

/// Modèle pour une étape du tutorial
class TutorialStep {
  final String title;
  final String description;
  final Offset bubblePosition; // Position de la bulle (% de l'écran)
  final Offset targetPosition; // Position de la cible à highlight (% de l'écran)
  final Size targetSize; // Taille de la cible (% de l'écran)
  final bool isTop; // Bulle en haut ou en bas de la cible

  TutorialStep({
    required this.title,
    required this.description,
    required this.bubblePosition,
    required this.targetPosition,
    required this.targetSize,
    this.isTop = false,
  });
}

/// Widget overlay pour afficher un tutorial sur une image statique
/// Résout le problème du scroll et des données variables
class TutorialImageOverlay extends StatefulWidget {
  final String imagePath; // Chemin vers l'image de la page vide
  final String avatarPath; // Avatar du coach
  final List<TutorialStep> steps; // Étapes du tutorial
  final String languageCode;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const TutorialImageOverlay({
    Key? key,
    required this.imagePath,
    required this.avatarPath,
    required this.steps,
    required this.languageCode,
    required this.onFinish,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<TutorialImageOverlay> createState() => _TutorialImageOverlayState();
}

class _TutorialImageOverlayState extends State<TutorialImageOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      widget.onFinish();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_currentStep];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Image de fond (screenshot de la page vide)
          Positioned.fill(
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si l'image n'existe pas encore
                return Container(
                  color: const Color(0xFFF8FAFC),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Screenshot placeholder\n${widget.imagePath}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Overlay sombre avec découpe pour la cible
          Positioned.fill(
            child: CustomPaint(
              painter: _HighlightPainter(
                targetRect: Rect.fromLTWH(
                  screenSize.width * step.targetPosition.dx,
                  screenSize.height * step.targetPosition.dy,
                  screenSize.width * step.targetSize.width,
                  screenSize.height * step.targetSize.height,
                ),
              ),
            ),
          ),

          // Bulle de dialogue avec animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Positioned(
              left: screenSize.width * step.bubblePosition.dx,
              top: screenSize.height * step.bubblePosition.dy,
              child: Container(
                width: screenSize.width * 0.85,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar + Titre
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Image.asset(
                            widget.avatarPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Boutons de navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Compteur d'étapes
                        Text(
                          '${_currentStep + 1}/${widget.steps.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        // Boutons
                        Row(
                          children: [
                            // Bouton Passer
                            TextButton(
                              onPressed: widget.onSkip,
                              child: Text(
                                widget.languageCode == 'fr' ? 'Passer' : 'Skip',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Bouton Suivant/Terminer
                            ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B132B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _currentStep < widget.steps.length - 1
                                    ? (widget.languageCode == 'fr'
                                        ? 'Suivant'
                                        : 'Next')
                                    : (widget.languageCode == 'fr'
                                        ? 'Terminer'
                                        : 'Finish'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour créer l'overlay sombre avec découpe
class _HighlightPainter extends CustomPainter {
  final Rect targetRect;

  _HighlightPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B132B).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Dessiner l'overlay complet
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Créer la découpe pour la cible (avec coins arrondis)
    final targetPath = Path()
      ..addRRect(RRect.fromRectAndRadius(targetRect, const Radius.circular(16)));

    // Soustraire la cible de l'overlay
    final finalPath = Path.combine(PathOperation.difference, fullPath, targetPath);

    canvas.drawPath(finalPath, paint);

    // Dessiner un contour blanc autour de la cible
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
