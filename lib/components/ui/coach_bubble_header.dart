import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Type de contexte pour le message du coach
enum CoachMessageContext {
  nutrition,  // Messages liés aux repas, calories, eau
  sport,      // Messages liés au sport, entraînement
  general,    // Messages généraux, salutations, félicitations
}

/// Header compact avec Coach Ryze et bulle de conversation réaliste
/// Design minimaliste qui défile avec le contenu
class CoachBubbleHeader extends StatelessWidget {
  final String message;
  final int streak;
  final CoachMessageContext context;
  final VoidCallback? onTap;

  const CoachBubbleHeader({
    super.key,
    required this.message,
    required this.streak,
    this.context = CoachMessageContext.general,
    this.onTap,
  });

  /// Retourne le chemin de l'image selon le contexte
  String get _avatarPath {
    switch (context) {
      case CoachMessageContext.nutrition:
        return 'assets/images/coach_ryze_nutrition_avatar.png';
      case CoachMessageContext.sport:
        return 'assets/images/coach_ryze_workout_avatar.png';
      case CoachMessageContext.general:
        return 'assets/images/coach_ryze_welcome.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Panda à gauche (aligné en bas)
              Image.asset(
                _avatarPath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                cacheWidth: 240,
                filterQuality: FilterQuality.medium,
              ),
              // Bulle + Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bulle alignée en haut
                    Align(
                      alignment: Alignment.topLeft,
                      child: _SpeechBubble(message: message),
                    ),
                    const SizedBox(height: 8),
                    // Streak en bas à droite
                    _StreakBadge(streak: streak),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge streak en haut à droite
class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.flame,
              size: 15,
              color: Color(0xFFFF6B35),
            ),
            const SizedBox(width: 5),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulle de conversation style BD - forme complète avec queue intégrée
class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Painter pour dessiner une vraie bulle de dialogue avec queue
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const radius = 16.0;
    const tailWidth = 12.0;
    const tailHeight = 14.0;

    // Position de la queue (en bas à gauche)
    final tailY = size.height - 20;

    final path = Path();

    // Commencer en haut à gauche (après le radius)
    path.moveTo(tailWidth + radius, 0);

    // Ligne du haut
    path.lineTo(size.width - radius, 0);

    // Coin haut droit
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Ligne droite
    path.lineTo(size.width, size.height - radius);

    // Coin bas droit
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);

    // Ligne du bas (jusqu'à la queue)
    path.lineTo(tailWidth + radius, size.height);

    // Coin bas gauche
    path.quadraticBezierTo(tailWidth, size.height, tailWidth, size.height - radius);

    // Ligne gauche (descendre jusqu'à la queue)
    path.lineTo(tailWidth, tailY + tailHeight / 2);

    // Queue de la bulle (triangle arrondi)
    path.quadraticBezierTo(tailWidth - 2, tailY + tailHeight / 2 - 2, 0, tailY + tailHeight / 2 + 4);
    path.quadraticBezierTo(tailWidth - 4, tailY - 2, tailWidth, tailY - tailHeight / 2);

    // Continuer la ligne gauche vers le haut
    path.lineTo(tailWidth, radius);

    // Coin haut gauche
    path.quadraticBezierTo(tailWidth, 0, tailWidth + radius, 0);

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Extension pour déterminer le contexte du message
extension MessageContextDetector on String {
  /// Détecte le contexte d'un message pour choisir le bon panda
  CoachMessageContext detectContext() {
    final lowerMessage = toLowerCase();

    // Mots-clés nutrition
    final nutritionKeywords = [
      'petit-déjeuner', 'déjeuner', 'dîner', 'repas', 'manger', 'calorie',
      'kcal', 'eau', 'boire', 'hydrater', 'tracker', 'journal', 'scanne',
      'breakfast', 'lunch', 'dinner', 'meal', 'eat', 'water', 'drink',
      'frühstück', 'mittagessen', 'abendessen', 'trinken',
    ];

    // Mots-clés sport
    final sportKeywords = [
      'sport', 'séance', 'entraînement', 'workout', 'training', 'exercice',
      'musculation', 'cardio', 'course', 'running', 'gym',
      'training', 'übung',
    ];

    for (final keyword in nutritionKeywords) {
      if (lowerMessage.contains(keyword)) {
        return CoachMessageContext.nutrition;
      }
    }

    for (final keyword in sportKeywords) {
      if (lowerMessage.contains(keyword)) {
        return CoachMessageContext.sport;
      }
    }

    return CoachMessageContext.general;
  }
}
