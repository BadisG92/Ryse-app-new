import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/nutrition_analysis.dart';
import '../services/localization_service.dart';

// Design tokens pour cohérence
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Color(0xFF0B132B),
  );

  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFF0B132B),
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Color(0xFF334155),
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF94A3B8),
  );
}

/// Écran d'affichage d'une analyse nutritionnelle Coach Ryze
/// Version redesignée avec hiérarchie visuelle améliorée
class NutritionAnalysisScreen extends StatelessWidget {
  final NutritionAnalysis analysis;
  final VoidCallback onRegenerate;

  const NutritionAnalysisScreen({
    Key? key,
    required this.analysis,
    required this.onRegenerate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final isFrench = locService.currentLanguageCode == 'fr';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Fond gris très clair
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isFrench ? 'Suivi de Coach Ryze' : 'Coach Ryze Tracking',
              style: AppTextStyles.h2,
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF64748B)),
                onPressed: () {
                  Navigator.pop(context);
                  onRegenerate();
                },
                tooltip: isFrench ? 'Régénérer' : 'Regenerate',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec logo et contexte
                _buildHeader(isFrench),

                const SizedBox(height: Spacing.xl),

                // Score avec gauge circulaire impactante
                if (analysis.score != null) ...[
                  _buildEnhancedScoreCard(isFrench),
                  const SizedBox(height: Spacing.xl),
                  _buildDivider(),
                  const SizedBox(height: Spacing.xl),
                ],

                // Bloc premium Analyse + Recommandations
                _buildCoachRyzeAnalysisBlock(isFrench),

                const SizedBox(height: Spacing.xl),
                _buildDivider(),
                const SizedBox(height: Spacing.xl),

                // Métriques nutritionnelles
                _buildMetricsSection(isFrench),

                // Contexte workout
                if (analysis.metadata.hasWorkoutToday) ...[
                  const SizedBox(height: Spacing.lg),
                  _buildWorkoutContextCard(isFrench),
                ],

                const SizedBox(height: Spacing.xl),

                // Bouton retour en style secondaire
                _buildSecondaryActionButton(context, isFrench),

                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  // Séparateur visuel
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFE2E8F0),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFrench) {
    final dateStr = DateFormat('dd/MM/yyyy').format(analysis.date);
    final timeStr = DateFormat('HH:mm').format(analysis.timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Même couleur que le fond de la page
      ),
      child: Row(
        children: [
          // Texte "Bilan du (date) fait à (heure)"
          Expanded(
            child: Text(
              isFrench
                ? 'Bilan du $dateStr fait à $timeStr'
                : 'Report for $dateStr made at $timeStr',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          // Badge contexte
          _buildEnhancedContextBadge(analysis.context, isFrench),
        ],
      ),
    );
  }

  // Badge contexte avec design impactant
  Widget _buildEnhancedContextBadge(String context, bool isFrench) {
    final color = _getContextColor(context);
    final label = _getContextBadge(context, isFrench);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Score avec gauge circulaire impactante
  Widget _buildEnhancedScoreCard(bool isFrench) {
    final score = analysis.score!;
    final scoreColor = _getScoreColor(score);
    final scoreLabel = _getScoreLabel(score, isFrench);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.05),
            scoreColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Gauge circulaire
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _CircularGaugePainter(
                score: score,
                color: scoreColor,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: scoreColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Label
          Text(
            isFrench ? 'Score Nutritionnel' : 'Nutrition Score',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getScoreEmoji(score), style: TextStyle(fontSize: 20)),
              const SizedBox(width: Spacing.sm),
              Text(
                scoreLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bloc premium Coach Ryze : Analyse + Recommandations dans un seul gradient
  Widget _buildCoachRyzeAnalysisBlock(bool isFrench) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B132B), // Bleu foncé Ryze
            const Color(0xFF1E293B), // Slate foncé
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal avec logo : "Coach Ryze"
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: SvgPicture.asset(
                  'assets/images/logo_solo.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Coach Ryze',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Séparateur blanc (symétrique)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 20),

          // Titre "Analyse" en blanc dans le gradient
          Row(
            children: [
              Icon(
                LucideIcons.messageCircle,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                isFrench ? 'Analyse' : 'Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bloc blanc d'analyse (sans titre dedans)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              analysis.analysisText,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Séparateur blanc (symétrique)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 20),

          // Titre "Recommandations" en blanc dans le gradient
          if (analysis.recommendations.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  isFrench ? 'Recommandations' : 'Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cards de recommandations individuelles (sans titre dedans)
            ...analysis.recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              final parts = _parseRecommendation(recommendation);
              final emoji = _getRecommendationEmoji(recommendation);
              final emojiColor = _getRecommendationColor(index);

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji dans cercle coloré
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: emojiColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parts['title'] ?? recommendation,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0B132B),
                              ),
                            ),
                            if (parts['description']?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text(
                                parts['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Section Recommandations avec cards séparées - Version épurée
  Widget _buildRecommendationsSection(bool isFrench) {
    // Utiliser directement analysis.recommendations (maintenant structuré par Gemini)
    final recos = analysis.recommendations;

    if (recos.isEmpty) {
      print('⚠️ Aucune recommandation à afficher');
      return SizedBox.shrink();
    }

    print('✅ Affichage de ${recos.length} recommandations');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                size: 20,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                isFrench ? 'Recommandations' : 'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B132B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards individuelles
          ...recos.asMap().entries.map((entry) {
            final index = entry.key;
            final recommendation = entry.value;

            final emoji = _getRecommendationEmoji(recommendation);

            // Parser titre et description (format: **Titre**\nDescription)
            final parts = _parseRecommendation(recommendation);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < recos.length - 1 ? 12 : 0,
              ),
              child: _RecommendationCardClean(
                emoji: emoji,
                title: parts['title'] ?? recommendation,
                description: parts['description'] ?? '',
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Parser une recommandation en titre/description
  Map<String, String> _parseRecommendation(String recommendation) {
    // Enlever les ** du markdown
    final cleanReco = recommendation.replaceAll('**', '');

    // Chercher un pattern "Titre\nDescription" ou "Titre: Description"
    if (cleanReco.contains('\n')) {
      final lines = cleanReco.split('\n');
      return {
        'title': lines[0].trim(),
        'description': lines.sublist(1).join('\n').trim(),
      };
    } else if (cleanReco.contains(':')) {
      final parts = cleanReco.split(':');
      return {
        'title': parts[0].trim(),
        'description': parts.sublist(1).join(':').trim(),
      };
    }

    // Si pas de séparation, tout est le titre
    return {
      'title': cleanReco,
      'description': '',
    };
  }

  // Parser les recommandations depuis le texte complet
  List<String> _parseRecommendationsFromText(String text, bool isFrench) {
    final keyword = isFrench ? '**Recommandations**' : '**Recommendations**';
    if (!text.contains(keyword)) {
      // Debug
      print('❌ Keyword "$keyword" non trouvé dans le texte');
      return [];
    }

    final parts = text.split(keyword);
    if (parts.length < 2) {
      print('❌ Pas assez de parties après split');
      return [];
    }

    final recoPart = parts[1].trim();
    print('📝 Partie recommandations: ${recoPart.substring(0, recoPart.length > 100 ? 100 : recoPart.length)}...');

    // Split par double retour à la ligne OU par pattern **Titre**
    final List<String> recos = [];

    // Chercher les patterns de recommandations avec **
    final recoMatches = RegExp(r'\*\*([^*]+)\*\*\s*\n?([^\n]+(?:\n(?!\*\*)[^\n]+)*)').allMatches(recoPart);

    if (recoMatches.isNotEmpty) {
      for (final match in recoMatches) {
        final title = match.group(1)?.trim() ?? '';
        final description = match.group(2)?.trim() ?? '';
        if (title.isNotEmpty) {
          recos.add('**$title**\n$description');
        }
      }
      print('✅ ${recos.length} recommandations trouvées via regex');
    } else {
      // Fallback: split par double saut de ligne
      final splitRecos = recoPart
          .split(RegExp(r'\n\n+'))
          .where((s) => s.trim().isNotEmpty && !s.trim().startsWith('##'))
          .map((s) => s.trim())
          .toList();
      recos.addAll(splitRecos);
      print('✅ ${recos.length} recommandations trouvées via split');
    }

    return recos;
  }

  // Obtenir un emoji selon le contenu de la recommandation
  String _getRecommendationEmoji(String recommendation) {
    final lower = recommendation.toLowerCase();
    if (lower.contains('eau') || lower.contains('hydrat') || lower.contains('water') || lower.contains('bois')) {
      return '💧';
    }
    if (lower.contains('protéine') || lower.contains('protein') || lower.contains('viande') || lower.contains('yaourt')) {
      return '🍗';
    }
    if (lower.contains('glucide') || lower.contains('carb') || lower.contains('pain') || lower.contains('céréale')) {
      return '🍞';
    }
    if (lower.contains('lipide') || lower.contains('fat') || lower.contains('huile') || lower.contains('avocat')) {
      return '🥑';
    }
    if (lower.contains('fruit') || lower.contains('légume') || lower.contains('vegetable') || lower.contains('salade')) {
      return '🥗';
    }
    if (lower.contains('repas') || lower.contains('meal') || lower.contains('manger') || lower.contains('petit-déjeuner') || lower.contains('déjeuner')) {
      return '🍽️';
    }
    if (lower.contains('sport') || lower.contains('workout') || lower.contains('entraînement') || lower.contains('exercice')) {
      return '💪';
    }
    return '💡';
  }

  // Section Métriques améliorées
  Widget _buildMetricsSection(bool isFrench) {
    final meta = analysis.metadata;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec emoji
          Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: Spacing.sm),
              Text(
                isFrench ? 'Tes Métriques' : 'Your Metrics',
                style: AppTextStyles.h2,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Grille 2x2
          Row(
            children: [
              Expanded(
                child: _buildEnhancedMetricCard(
                  icon: LucideIcons.flame,
                  label: isFrench ? 'Calories' : 'Calories',
                  value: meta.totalCalories.toDouble(),
                  target: meta.calorieTarget.toDouble(),
                  unit: '',
                  color: const Color(0xFFEF4444),
                  isFrench: isFrench,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedMetricCard(
                  icon: LucideIcons.beef,
                  label: isFrench ? 'Protéines' : 'Protein',
                  value: meta.totalProteins,
                  target: meta.proteinTarget,
                  unit: 'g',
                  color: const Color(0xFF3B82F6),
                  isFrench: isFrench,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedMetricCard(
                  icon: LucideIcons.wheat,
                  label: isFrench ? 'Glucides' : 'Carbs',
                  value: meta.totalCarbs,
                  target: meta.carbsTarget,
                  unit: 'g',
                  color: const Color(0xFFF59E0B),
                  isFrench: isFrench,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedMetricCard(
                  icon: LucideIcons.droplet,
                  label: isFrench ? 'Lipides' : 'Fats',
                  value: meta.totalFats,
                  target: meta.fatsTarget,
                  unit: 'g',
                  color: const Color(0xFF8B5CF6),
                  isFrench: isFrench,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Métrique améliorée avec pourcentage visible
  Widget _buildEnhancedMetricCard({
    required IconData icon,
    required String label,
    required double value,
    required double target,
    required String unit,
    required Color color,
    required bool isFrench,
  }) {
    final progress = (value / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône + Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Valeurs
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${value.toInt()}$unit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                ' / ${target.toInt()}$unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: Spacing.xs),

          // Pourcentage
          Text(
            '$percentage% ${isFrench ? 'de ton objectif' : 'of your goal'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutContextCard(bool isFrench) {
    final meta = analysis.metadata;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.dumbbell,
              color: const Color(0xFF8B5CF6),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFrench ? 'Entraînement effectué' : 'Workout completed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                if (meta.caloriesBurned != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${meta.caloriesBurned} kcal ${isFrench ? 'brûlées' : 'burned'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bouton retour en style secondaire
  Widget _buildSecondaryActionButton(BuildContext context, bool isFrench) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.arrowLeft, size: 18),
        label: Text(
          isFrench ? 'Retour au journal' : 'Back to journal',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          side: BorderSide(color: const Color(0xFFCBD5E1), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helpers
  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981); // Vert
    if (score >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }

  String _getScoreEmoji(double score) {
    if (score >= 80) return '🟢';
    if (score >= 60) return '🟡';
    return '🔴';
  }

  String _getScoreLabel(double score, bool isFrench) {
    if (isFrench) {
      if (score >= 80) return 'Excellent';
      if (score >= 60) return 'Bon';
      return 'À améliorer';
    } else {
      if (score >= 80) return 'Excellent';
      if (score >= 60) return 'Good';
      return 'Needs improvement';
    }
  }

  IconData _getRecommendationIcon(String recommendation) {
    final lower = recommendation.toLowerCase();
    if (lower.contains('eau') || lower.contains('hydrat') || lower.contains('water')) {
      return LucideIcons.droplets;
    }
    if (lower.contains('protéine') || lower.contains('protein')) {
      return LucideIcons.beef;
    }
    if (lower.contains('glucide') || lower.contains('carb')) {
      return LucideIcons.wheat;
    }
    if (lower.contains('lipide') || lower.contains('fat')) {
      return LucideIcons.droplet;
    }
    if (lower.contains('fruit') || lower.contains('légume') || lower.contains('vegetable')) {
      return LucideIcons.apple;
    }
    if (lower.contains('repas') || lower.contains('meal')) {
      return LucideIcons.utensils;
    }
    return LucideIcons.lightbulb;
  }

  Color _getRecommendationColor(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Rose
    ];
    return colors[index % colors.length];
  }

  String _getContextLabel(String context, bool isFrench) {
    if (isFrench) {
      switch (context) {
        case 'empty_day': return 'Journée vide';
        case 'post_workout': return 'Post-entraînement';
        case 'end_of_day': return 'Fin de journée';
        case 'in_progress': return 'Journée en cours';
        default: return 'Analyse';
      }
    } else {
      switch (context) {
        case 'empty_day': return 'Empty day';
        case 'post_workout': return 'Post-workout';
        case 'end_of_day': return 'End of day';
        case 'in_progress': return 'Day in progress';
        default: return 'Analysis';
      }
    }
  }

  String _getContextBadge(String context, bool isFrench) {
    if (isFrench) {
      switch (context) {
        case 'empty_day': return 'JOURNÉE VIDE';
        case 'post_workout': return 'POST-ENTRAÎNEMENT';
        case 'end_of_day': return 'BILAN';
        case 'in_progress': return 'JOURNÉE EN COURS';
        default: return 'ANALYSE';
      }
    } else {
      switch (context) {
        case 'empty_day': return 'EMPTY DAY';
        case 'post_workout': return 'POST-WORKOUT';
        case 'end_of_day': return 'SUMMARY';
        case 'in_progress': return 'DAY IN PROGRESS';
        default: return 'ANALYSIS';
      }
    }
  }

  Color _getContextColor(String context) {
    switch (context) {
      case 'empty_day': return const Color(0xFFEC4899); // Rose
      case 'post_workout': return const Color(0xFF8B5CF6); // Violet
      case 'end_of_day': return const Color(0xFF10B981); // Vert
      case 'in_progress': return const Color(0xFF0B132B); // Bleu foncé Ryze
      default: return const Color(0xFF64748B);
    }
  }
}

// Widget card pour recommandation individuelle - Version épurée
class _RecommendationCardClean extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _RecommendationCardClean({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji dans cercle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Jaune pâle
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B132B),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter pour gauge circulaire
class _CircularGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _CircularGaugePainter({
    required this.score,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = 12.0;

    // Background circle (gris clair)
    final backgroundPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color,
          color.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
