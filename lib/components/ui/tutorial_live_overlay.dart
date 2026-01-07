import 'package:flutter/material.dart';

/// Modèle pour une étape du tutorial
class TutorialStep {
  final String title;
  final String description;
  final GlobalKey targetKey; // Clé du widget à cibler
  final bool alignTop; // Bulle en haut ou en bas de la cible

  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.alignTop = false,
  });
}

/// Overlay pour afficher un tutorial sur la VRAIE page en mode démo
/// La page affiche des données vides/démo pendant le tutorial
class TutorialLiveOverlay extends StatefulWidget {
  final Widget demoPage; // La vraie page mais avec des données de démo
  final String avatarPath; // Avatar du coach
  final List<TutorialStep> steps; // Étapes du tutorial
  final String languageCode;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const TutorialLiveOverlay({
    Key? key,
    required this.demoPage,
    required this.avatarPath,
    required this.steps,
    required this.languageCode,
    required this.onFinish,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<TutorialLiveOverlay> createState() => _TutorialLiveOverlayState();
}

class _TutorialLiveOverlayState extends State<TutorialLiveOverlay>
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

    // Attendre que la page soit rendue avant de montrer la première bulle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // La vraie page en mode démo (en dessous)
          widget.demoPage,

          // Overlay sombre avec découpe pour la cible actuelle
          _buildOverlay(),

          // Bulle de dialogue avec animation
          _buildDialogueBubble(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final step = widget.steps[_currentStep];

    return FutureBuilder<Rect?>(
      future: _getTargetRect(step.targetKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          // Si pas encore de rect, overlay complet
          return Container(
            color: const Color(0xFF0B132B).withOpacity(0.85),
          );
        }

        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _HighlightPainter(targetRect: snapshot.data!),
        );
      },
    );
  }

  Widget _buildDialogueBubble() {
    final step = widget.steps[_currentStep];

    return FutureBuilder<Rect?>(
      future: _getTargetRect(step.targetKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          // Bulle centrée en attendant
          return Center(
            child: _buildBubbleContent(step),
          );
        }

        final targetRect = snapshot.data!;
        final screenSize = MediaQuery.of(context).size;

        // Calculer la position de la bulle
        const bubbleMaxHeight = 350.0; // Hauteur max estimée de la bulle
        const topMargin = 50.0; // Marge du haut de l'écran
        const bottomMargin = 80.0; // Marge du bas de l'écran (pour navigation bar)

        double bubbleTop;
        if (step.alignTop) {
          // Bulle AU-DESSUS de la cible
          bubbleTop = targetRect.top - bubbleMaxHeight - 20;
          // S'assurer qu'elle ne sort pas en haut
          if (bubbleTop < topMargin) {
            bubbleTop = topMargin;
          }
        } else {
          // Bulle EN-DESSOUS de la cible
          bubbleTop = targetRect.bottom + 20;
          // Vérifier s'il y a assez de place en bas
          if (bubbleTop + bubbleMaxHeight > screenSize.height - bottomMargin) {
            // Pas assez de place en bas, mettre au-dessus
            bubbleTop = targetRect.top - bubbleMaxHeight - 20;
            // S'assurer qu'elle ne sort pas en haut
            if (bubbleTop < topMargin) {
              // Si pas de place ni en haut ni en bas, centrer verticalement
              bubbleTop = (screenSize.height - bubbleMaxHeight) / 2;
            }
          }
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Positioned(
            left: screenSize.width * 0.075, // 7.5% de marge
            top: bubbleTop,
            child: _buildBubbleContent(step),
          ),
        );
      },
    );
  }

  Widget _buildBubbleContent(TutorialStep step) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.85,
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
                width: 80,
                height: 80,
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
                      widget.languageCode == 'fr'
                          ? 'Passer'
                          : widget.languageCode == 'de'
                              ? 'Überspringen'
                              : 'Skip',
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
                              ? 'Compris'
                              : widget.languageCode == 'de'
                                  ? 'Verstanden'
                                  : 'Got it')
                          : (widget.languageCode == 'fr'
                              ? 'Terminer'
                              : widget.languageCode == 'de'
                                  ? 'Beenden'
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
    );
  }

  Future<Rect?> _getTargetRect(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final context = key.currentContext;
    if (context == null) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Ajouter un padding de 8px autour de la zone pour qu'elle soit plus visible
    const padding = 8.0;
    return Rect.fromLTWH(
      position.dx - padding,
      position.dy - padding,
      size.width + (padding * 2),
      size.height + (padding * 2),
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
      ..addRRect(RRect.fromRectAndRadius(targetRect, const Radius.circular(12)));

    // Soustraire la cible de l'overlay
    final finalPath = Path.combine(PathOperation.difference, fullPath, targetPath);

    canvas.drawPath(finalPath, paint);

    // Dessiner un contour blanc épais autour de la cible
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
