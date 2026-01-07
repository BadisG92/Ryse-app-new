import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/nutrition_analysis.dart';
import '../services/localization_service.dart';
import '../services/auth_service.dart';
import '../components/ui/coach_ryze_avatar.dart';

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
class NutritionAnalysisScreen extends StatefulWidget {
  final NutritionAnalysis analysis;
  final VoidCallback onRegenerate;

  const NutritionAnalysisScreen({
    Key? key,
    required this.analysis,
    required this.onRegenerate,
  }) : super(key: key);

  @override
  State<NutritionAnalysisScreen> createState() => _NutritionAnalysisScreenState();
}

class _NutritionAnalysisScreenState extends State<NutritionAnalysisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final langCode = locService.currentLanguageCode;

        return Scaffold(
          backgroundColor: Colors.white, // Fond blanc
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0B132B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _tr(langCode, 'Coach Ryze Tracking', 'Suivi de Coach Ryze', 'Coach Ryze Tracking'),
              style: AppTextStyles.h2,
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.rotateCw, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRegenerate();
                  },
                  tooltip: _tr(langCode, 'Regenerate analysis', 'Régénérer l\'analyse', 'Analyse neu generieren'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date et heure de l'analyse
                _buildDateHeader(langCode),

                // Header avec panda Coach Ryze
                _buildHeader(langCode),

                const SizedBox(height: 12),

                // Score nutritionnel horizontal compact
                if (widget.analysis.score != null) ...[
                  _buildEnhancedScoreCard(langCode),
                  const SizedBox(height: Spacing.xl),
                  _buildDivider(),
                  const SizedBox(height: Spacing.xl),
                ],

                // Bloc premium Analyse + Recommandations
                _buildCoachRyzeAnalysisBlock(langCode),

                const SizedBox(height: Spacing.xl),
                _buildDivider(),
                const SizedBox(height: Spacing.xl),

                // Métriques nutritionnelles
                _buildMetricsSection(langCode),

                // Contexte workout
                if (widget.analysis.metadata.hasWorkoutToday) ...[
                  const SizedBox(height: Spacing.lg),
                  _buildWorkoutContextCard(langCode),
                ],

                const SizedBox(height: Spacing.xl),

                // Bouton retour en style secondaire
                _buildSecondaryActionButton(context, langCode),

                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper pour traductions trilingues (en, fr, de)
  String _tr(String langCode, String en, String fr, String de) {
    if (langCode == 'de') return de;
    if (langCode == 'fr') return fr;
    return en;
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

  /// Retourne un message dynamique selon le contexte
  String _getContextMessage(String context, String langCode) {
    switch (context) {
      case 'empty_day':
        return _tr(langCode,
          'Your day is empty, let\'s start together!',
          'Ta journée est vide, commençons ensemble !',
          'Dein Tag ist leer, lass uns zusammen starten!');
      case 'post_workout':
        return _tr(langCode,
          'Great session! Let\'s analyze your nutrition recovery',
          'Belle séance ! Analysons ta récupération nutrition',
          'Tolle Einheit! Lass uns deine Ernährungserholung analysieren');
      case 'end_of_day':
        return _tr(langCode,
          'Let\'s review your day!',
          'Faisons le bilan de ta journée !',
          'Lass uns deinen Tag zusammenfassen!');
      case 'in_progress':
        return _tr(langCode,
          'Let\'s analyze your day together!',
          'Analysons ta journée ensemble !',
          'Lass uns deinen Tag zusammen analysieren!');
      default:
        return _tr(langCode,
          'Let\'s analyze your nutrition together!',
          'Analysons ta nutrition ensemble !',
          'Lass uns deine Ernährung zusammen analysieren!');
    }
  }

  /// Date et heure de l'analyse
  Widget _buildDateHeader(String langCode) {
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.analysis.date);
    final timeStr = DateFormat('HH:mm').format(widget.analysis.timestamp);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        _tr(langCode,
          'Report for $dateStr made at $timeStr',
          'Bilan du $dateStr fait à $timeStr',
          'Bericht vom $dateStr um $timeStr'),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildHeader(String langCode) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Capitaliser le prénom (même méthode que le dashboard)
        final rawName = authService.currentUser?.firstName ?? 'Champion';
        final userName = rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
        final greeting = _tr(langCode, 'Hey', 'Salut', 'Hey');
        final contextMessage = _getContextMessage(widget.analysis.context, langCode);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Texte à gauche
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting $userName !',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contextMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Avatar Coach Ryze Nutrition à droite avec animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: const CoachRyzeAvatar(
                    type: CoachRyzeAvatarType.nutrition,
                    size: CoachRyzeAvatarSize.xxxlarge, // 180px - Plus grand pour compenser la blouse blanche
                    withShadow: false, // Pas besoin, le container a déjà une ombre
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Badge contexte avec design impactant
  Widget _buildEnhancedContextBadge(String context, String langCode) {
    final color = _getContextColor(context);
    final label = _getContextBadge(context, langCode);

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
  Widget _buildEnhancedScoreCard(String langCode) {
    final score = widget.analysis.score!;
    final scoreColor = _getScoreColor(score);
    final scoreLabel = _getScoreLabel(score, langCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.05),
            scoreColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Score avec mini gauge à gauche
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                // Gauge circulaire en arrière-plan
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _CircularGaugePainter(
                    score: score,
                    color: scoreColor,
                  ),
                ),
                // Score au centre
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: scoreColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Infos à droite - Plus d'espace utilisé
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tr(langCode, 'Nutrition Score', 'Score Nutritionnel', 'Ernährungs-Score'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scoreColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scoreLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bloc premium Coach Ryze : Analyse + Recommandations dans un seul gradient
  Widget _buildCoachRyzeAnalysisBlock(String langCode) {
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
                _tr(langCode, 'Analysis', 'Analyse', 'Analyse'),
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
              widget.analysis.analysisText,
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
          if (widget.analysis.recommendations.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  _tr(langCode, 'Recommendations', 'Recommandations', 'Empfehlungen'),
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
            ...widget.analysis.recommendations.asMap().entries.map((entry) {
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
  Widget _buildRecommendationsSection(String langCode) {
    // Utiliser directement widget.analysis.recommendations (maintenant structuré par Gemini)
    final recos = widget.analysis.recommendations;

    if (recos.isEmpty) {
      debugPrint('⚠️ Aucune recommandation à afficher');
      return SizedBox.shrink();
    }

    debugPrint('✅ Affichage de ${recos.length} recommandations');

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
                _tr(langCode, 'Recommendations', 'Recommandations', 'Empfehlungen'),
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
  List<String> _parseRecommendationsFromText(String text, String langCode) {
    final keyword = langCode == 'fr' ? '**Recommandations**' : (langCode == 'de' ? '**Empfehlungen**' : '**Recommendations**');
    if (!text.contains(keyword)) {
      // Debug
      debugPrint('❌ Keyword "$keyword" non trouvé dans le texte');
      return [];
    }

    final parts = text.split(keyword);
    if (parts.length < 2) {
      debugPrint('❌ Pas assez de parties après split');
      return [];
    }

    final recoPart = parts[1].trim();
    debugPrint('📝 Partie recommandations: ${recoPart.substring(0, recoPart.length > 100 ? 100 : recoPart.length)}...');

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
      debugPrint('✅ ${recos.length} recommandations trouvées via regex');
    } else {
      // Fallback: split par double saut de ligne
      final splitRecos = recoPart
          .split(RegExp(r'\n\n+'))
          .where((s) => s.trim().isNotEmpty && !s.trim().startsWith('##'))
          .map((s) => s.trim())
          .toList();
      recos.addAll(splitRecos);
      debugPrint('✅ ${recos.length} recommandations trouvées via split');
    }

    return recos;
  }

  // Obtenir un emoji selon le contenu de la recommandation
  String _getRecommendationEmoji(String recommendation) {
    final lower = recommendation.toLowerCase();

    // Glucides / Carbohydrates (FR: glucide, EN: carb/carbohydrate)
    if (lower.contains('glucide') || lower.contains('carb') || lower.contains('carbohydrate') ||
        lower.contains('pain') || lower.contains('bread') ||
        lower.contains('céréale') || lower.contains('cereal') ||
        lower.contains('riz') || lower.contains('rice') ||
        lower.contains('pâte') || lower.contains('pasta')) {
      return '🌾';  // Icône de blé pour les glucides
    }

    // Protéines / Proteins (FR: protéine, EN: protein)
    if (lower.contains('protéine') || lower.contains('protein') ||
        lower.contains('viande') || lower.contains('meat') ||
        lower.contains('poisson') || lower.contains('fish') ||
        lower.contains('œuf') || lower.contains('egg') ||
        lower.contains('poulet') || lower.contains('chicken')) {
      return '🍗';
    }

    // Lipides / Fats (FR: lipide/graisse, EN: fat/lipid)
    if (lower.contains('lipide') || lower.contains('fat') || lower.contains('lipid') ||
        lower.contains('graisse') || lower.contains('huile') || lower.contains('oil') ||
        lower.contains('avocat') || lower.contains('avocado')) {
      return '🥑';
    }

    // Eau / Water (FR: eau/hydratation, EN: water/hydration)
    if (lower.contains('eau') || lower.contains('water') ||
        lower.contains('hydrat') || lower.contains('boire') || lower.contains('drink')) {
      return '💧';
    }

    // Fruits et légumes / Fruits and vegetables
    if (lower.contains('fruit') || lower.contains('légume') || lower.contains('vegetable') ||
        lower.contains('salade') || lower.contains('salad')) {
      return '🥗';
    }

    // Repas / Meals
    if (lower.contains('repas') || lower.contains('meal') ||
        lower.contains('manger') || lower.contains('eat') ||
        lower.contains('déjeuner') || lower.contains('lunch') ||
        lower.contains('dîner') || lower.contains('dinner')) {
      return '🍽️';
    }

    // Sport / Exercise
    if (lower.contains('sport') || lower.contains('workout') || lower.contains('exercise') ||
        lower.contains('entraînement') || lower.contains('training') ||
        lower.contains('activité') || lower.contains('activity')) {
      return '💪';
    }

    return '🍴';  // Icône par défaut (fourchette et couteau pour alimentation générale)
  }

  // Section Métriques redessinée selon le dashboard nutrition
  Widget _buildMetricsSection(String langCode) {
    final meta = widget.analysis.metadata;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre sans icône
          Text(
            _tr(langCode, 'Your Metrics', 'Tes Métriques', 'Deine Werte'),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: Spacing.lg),

          // Cercle de calories
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                children: [
                  // Cercle de progression
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: _CalorieCirclePainter(
                          consumed: meta.totalCalories.toDouble(),
                          target: meta.calorieTarget.toDouble(),
                        ),
                      ),
                    ),
                  ),
                  // Valeur au centre
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${meta.totalCalories}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kcal',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tr(langCode, 'Consumed', 'Consommé', 'Verbraucht'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Macros avec barres horizontales
          _buildMacroBar(
            label: _tr(langCode, 'Protein', 'Protéines', 'Protein'),
            value: meta.totalProteins,
            target: meta.proteinTarget,
            color: const Color(0xFF000000), // Noir
            langCode: langCode,
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            label: _tr(langCode, 'Carbs', 'Glucides', 'Kohlenhydrate'),
            value: meta.totalCarbs,
            target: meta.carbsTarget,
            color: const Color(0xFF000000), // Noir
            langCode: langCode,
          ),
          const SizedBox(height: 16),
          _buildMacroBar(
            label: _tr(langCode, 'Fats', 'Lipides', 'Fette'),
            value: meta.totalFats,
            target: meta.fatsTarget,
            color: const Color(0xFF000000), // Noir
            langCode: langCode,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieLegend(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B132B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double value,
    required double target,
    required Color color,
    required String langCode,
  }) {
    final progress = (value / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec pourcentage et valeurs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label + pourcentage
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            // Valeurs
            Text(
              '${value.toInt()}g / ${target.toInt()}g',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
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
    required String langCode,
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
            '$percentage% ${_tr(langCode, 'of your goal', 'de ton objectif', 'deines Ziels')}',
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

  Widget _buildWorkoutContextCard(String langCode) {
    final meta = widget.analysis.metadata;

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
                  _tr(langCode, 'Workout completed', 'Entraînement effectué', 'Training absolviert'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                if (meta.caloriesBurned != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${meta.caloriesBurned} kcal ${_tr(langCode, 'burned', 'brûlées', 'verbrannt')}',
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
  Widget _buildSecondaryActionButton(BuildContext context, String langCode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.arrowLeft, size: 18),
        label: Text(
          _tr(langCode, 'Back to journal', 'Retour au journal', 'Zurück zum Journal'),
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

  String _getScoreLabel(double score, String langCode) {
    if (score >= 80) {
      return _tr(langCode,
        'Great! Optimal nutritional balance',
        'Super ! Équilibre nutritionnel optimal',
        'Super! Optimale Nährstoffbalance');
    }
    if (score >= 60) {
      return _tr(langCode,
        'Good! A few minor tweaks needed',
        'Bien ! Quelques petits ajustements',
        'Gut! Ein paar kleine Anpassungen nötig');
    }
    if (score >= 40) {
      return _tr(langCode,
        'Not bad, but we can do better',
        'Pas mal, mais on peut mieux faire',
        'Nicht schlecht, aber da geht noch mehr');
    }
    return _tr(langCode,
      'Improve your nutritional balance',
      'Améliore ton équilibre nutritionnel',
      'Verbessere deine Nährstoffbalance');
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

  String _getContextLabel(String context, String langCode) {
    switch (context) {
      case 'empty_day':
        return _tr(langCode, 'Empty day', 'Journée vide', 'Leerer Tag');
      case 'post_workout':
        return _tr(langCode, 'Post-workout', 'Post-entraînement', 'Nach dem Training');
      case 'end_of_day':
        return _tr(langCode, 'End of day', 'Fin de journée', 'Tagesende');
      case 'in_progress':
        return _tr(langCode, 'Day in progress', 'Journée en cours', 'Tag läuft');
      default:
        return _tr(langCode, 'Analysis', 'Analyse', 'Analyse');
    }
  }

  String _getContextBadge(String context, String langCode) {
    switch (context) {
      case 'empty_day':
        return _tr(langCode, 'EMPTY DAY', 'JOURNÉE VIDE', 'LEERER TAG');
      case 'post_workout':
        return _tr(langCode, 'POST-WORKOUT', 'POST-ENTRAÎNEMENT', 'NACH DEM TRAINING');
      case 'end_of_day':
        return _tr(langCode, 'SUMMARY', 'BILAN', 'ZUSAMMENFASSUNG');
      case 'in_progress':
        return _tr(langCode, 'DAY IN PROGRESS', 'JOURNÉE EN COURS', 'TAG LÄUFT');
      default:
        return _tr(langCode, 'ANALYSIS', 'ANALYSE', 'ANALYSE');
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
    final radius = size.width / 2 - 6;
    final strokeWidth = 6.0;

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

// Custom painter pour le cercle de calories
class _CalorieCirclePainter extends CustomPainter {
  final double consumed;
  final double target;

  _CalorieCirclePainter({
    required this.consumed,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 12.0;

    // Background circle (gris clair)
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc (noir/bleu foncé)
    final progress = (consumed / target).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = const Color(0xFF0B132B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * math.pi;
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
