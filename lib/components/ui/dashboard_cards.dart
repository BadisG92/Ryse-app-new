import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'custom_badge.dart';
import 'dashboard_models.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

// Header gamifié du dashboard
class DashboardHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onPremiumTap;

  const DashboardHeader({
    super.key,
    required this.profile,
    this.onPremiumTap,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B132B),
            Color(0xFF1C2951),
            Color(0xFF0B132B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern background
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: DotPatternPainter(),
              ),
            ),
          ),
          
          // Premium button
          if (!profile.isPremium)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onPremiumTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.crown, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Main content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 24, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              profile.streak.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Consumer<LocalizationService>(
                              builder: (context, locService, child) => Text(
                                'days'.tr(locService.currentLanguageCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Consumer<LocalizationService>(
                          builder: (context, locService, child) => CustomBadge(
                            text: 'current_series'.tr(locService.currentLanguageCode),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Greeting
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        profile.greetingMessage(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        profile.xpText(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Message contextuel CTA
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          profile.contextualMessage(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Score circulaire
              CircularScoreWidget(score: profile.todayScore, size: 70),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget de score circulaire
class CircularScoreWidget extends StatelessWidget {
  final int score;
  final double size;

  const CircularScoreWidget({
    super.key,
    required this.score,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: 0,
              strokeWidth: 5,
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.transparent,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: score / 100,
              strokeWidth: 5,
              backgroundColor: Colors.transparent,
              progressColor: Colors.white.withOpacity(0.9),
            ),
          ),
          // Score text
          Center(
            child: Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bouton d'action rapide
class QuickActionButton extends StatelessWidget {
  final QuickAction action;
  final GlobalKey? tutorialKey; // Clé pour le tutorial
  final bool isInRow; // Si dans une Row, pas de padding right

  const QuickActionButton({
    super.key,
    required this.action,
    this.tutorialKey,
    this.isInRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: action.onTap,
      child: Column(
        key: tutorialKey, // Key directement sur la Column (sans margin)
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Centrer tous les enfants
        children: [
          // Bouton carré avec gradient bleu
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: action.isDisabled
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFE2E8F0),
                        const Color(0xFFE2E8F0),
                      ],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              action.icon,
              size: 28,
              color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Texte en dessous
          SizedBox(
            width: 80,
            height: 36, // Hauteur fixe pour 2 lignes de texte
            child: Text(
              action.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: action.isDisabled
                    ? const Color(0xFF64748B)
                    : const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Si dans une Row, pas de padding. Sinon padding right pour le ListView
    return isInRow
        ? child
        : Padding(
            padding: const EdgeInsets.only(right: 16),
            child: child,
          );
  }
}

// Item d'objectif journalier
class DailyGoalItem extends StatelessWidget {
  final DailyGoal goal;
  final bool isPremium;

  const DailyGoalItem({
    super.key,
    required this.goal,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    goal.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (goal.isPremium && !isPremium) ...[
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.crown, size: 12, color: Color(0xFF0B132B)),
                  ],
                ],
              ),
              Text(
                goal.progressText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: goal.progressPercent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: goal.progressColors),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card de preview de module
class ModulePreviewCard extends StatelessWidget {
  final ModulePreview module;
  final VoidCallback? onTap;

  const ModulePreviewCard({
    super.key,
    required this.module,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B132B).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    module.icon, 
                    size: 20, 
                    color: const Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              ...module.stats.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildStatRow(entry.key, entry.value),
                )
              ).toList(),
            ],
          ),
        ),
      );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// Feature premium pour CTA
class PremiumFeatureItem extends StatelessWidget {
  final String value;
  final String label;

  const PremiumFeatureItem({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// Custom painter pour le pattern de points
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + 30, y + 30), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter pour le progress circulaire
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Progress arc
    if (progressColor != Colors.transparent && progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 
