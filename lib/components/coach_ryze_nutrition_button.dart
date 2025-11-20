import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/coach_ryze_nutrition_service.dart';
import '../models/nutrition_models.dart';
import '../models/nutrition_analysis.dart';
import '../screens/nutrition_analysis_screen.dart';
import '../services/paywall_service.dart';
import '../services/feature_trial_service.dart';
import '../services/subscription_service.dart';

// Badge Premium pour Coach Ryze
class _CoachRyzePremiumBadge extends StatefulWidget {
  final bool isLocked;
  final bool isFrench;

  const _CoachRyzePremiumBadge({
    required this.isLocked,
    required this.isFrench,
  });

  @override
  State<_CoachRyzePremiumBadge> createState() => _CoachRyzePremiumBadgeState();
}

class _CoachRyzePremiumBadgeState extends State<_CoachRyzePremiumBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isLocked
            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)] // Gold for UPGRADE
            : [const Color(0xFF0B132B), const Color(0xFF1C2951)], // Blue DA for TRY FREE
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.isLocked
              ? const Color(0xFFFFD700).withOpacity(0.4)
              : const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isLocked ? LucideIcons.lockOpen : LucideIcons.gift,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            widget.isLocked
              ? (widget.isFrench ? 'UPGRADE' : 'UPGRADE')
              : (widget.isFrench ? 'ESSAI GRATUIT' : 'TRY FREE'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    return ScaleTransition(
      scale: _pulseAnimation,
      child: badge,
    );
  }
}

/// Bouton intelligent Coach Ryze pour l'analyse nutritionnelle
/// Apparence adaptée selon le contexte détecté
class CoachRyzeNutritionButton extends StatefulWidget {
  final String userId;
  final DateTime date;
  final List<Meal> todayMeals;
  final int calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatsTarget;
  final int waterIntake;
  final bool hasWorkoutToday;
  final String? workoutType;
  final int? caloriesBurned;
  final DateTime? workoutTime;

  const CoachRyzeNutritionButton({
    Key? key,
    required this.userId,
    required this.date,
    required this.todayMeals,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatsTarget,
    required this.waterIntake,
    required this.hasWorkoutToday,
    this.workoutType,
    this.caloriesBurned,
    this.workoutTime,
  }) : super(key: key);

  @override
  State<CoachRyzeNutritionButton> createState() => _CoachRyzeNutritionButtonState();
}

class _CoachRyzeNutritionButtonState extends State<CoachRyzeNutritionButton> {
  String _currentContext = 'in_progress';
  bool _isLoading = false;
  NutritionAnalysis? _cachedAnalysis;
  bool _isInitialized = false;
  bool? _isLocked;
  bool _isCheckingLock = true;

  @override
  void initState() {
    super.initState();
    // Détecter le contexte de manière synchrone pour éviter le flash
    _currentContext = _detectContextSync();
    // Charger le cache en arrière-plan
    _loadCacheInBackground();
    // Vérifier le statut locked
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final locked = await PaywallService.instance.isFeatureLocked(
      PaywallContext.nutritionAnalysis,
    );
    if (mounted) {
      setState(() {
        _isLocked = locked;
        _isCheckingLock = false;
      });
    }
  }

  @override
  void didUpdateWidget(CoachRyzeNutritionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour le contexte si les repas changent
    if (oldWidget.todayMeals.length != widget.todayMeals.length) {
      setState(() {
        _currentContext = _detectContextSync();
      });
      _loadCacheInBackground();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check lock status when widget becomes visible again
    // This ensures badge updates after trial is used
    _checkLockStatus();
  }

  /// Détection synchrone du contexte pour éviter le flash
  String _detectContextSync() {
    final now = DateTime.now();
    final isEvening = now.hour >= 20; // Après 20h

    // Journée vide
    if (widget.todayMeals.isEmpty) {
      return 'empty_day';
    }

    // Post-workout (moins de 2h après l'entraînement)
    if (widget.hasWorkoutToday && widget.workoutTime != null) {
      final hoursSinceWorkout = now.difference(widget.workoutTime!).inHours;
      if (hoursSinceWorkout < 2) {
        return 'post_workout';
      }
    }

    // Fin de journée
    if (isEvening) {
      return 'end_of_day';
    }

    // Par défaut: journée en cours
    return 'in_progress';
  }

  /// Charger le cache en arrière-plan sans provoquer de flash
  Future<void> _loadCacheInBackground() async {
    final cached = await CoachRyzeNutritionService.getAnalysisForDate(
      userId: widget.userId,
      date: widget.date,
    );

    if (mounted && cached != null) {
      setState(() {
        _cachedAnalysis = cached;
        _isInitialized = true;
      });
    } else if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _handleAnalysisTap(BuildContext context) async {
    // Si analyse en cache existe, l'afficher directement
    if (_cachedAnalysis != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutritionAnalysisScreen(
            analysis: _cachedAnalysis!,
            onRegenerate: () => _generateNewAnalysis(context),
          ),
        ),
      );
      return;
    }

    // Sinon, générer une nouvelle analyse
    await _generateNewAnalysis(context);
  }

  Future<void> _generateNewAnalysis(BuildContext context) async {
    // Vérifier l'accès (Premium ou 1er essai gratuit)
    // Ne PAS marquer comme utilisé ici - on le fera seulement si l'analyse réussit
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.nutritionAnalysis,
      markAsUsed: false, // ← Ne pas marquer maintenant
    );

    if (!canUse) {
      // Le paywall s'est affiché automatiquement
      return;
    }

    final locService = Provider.of<LocalizationService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final analysis = await CoachRyzeNutritionService.generateAnalysis(
        userId: widget.userId,
        date: widget.date,
        todayMeals: widget.todayMeals,
        calorieTarget: widget.calorieTarget,
        proteinTarget: widget.proteinTarget,
        carbsTarget: widget.carbsTarget,
        fatsTarget: widget.fatsTarget,
        waterIntake: widget.waterIntake,
        hasWorkoutToday: widget.hasWorkoutToday,
        workoutType: widget.workoutType,
        caloriesBurned: widget.caloriesBurned,
        workoutTime: widget.workoutTime,
        languageCode: locService.currentLanguageCode,
      );

      setState(() {
        _cachedAnalysis = analysis;
        _isLoading = false;
      });

      // ✅ Marquer le trial comme utilisé UNIQUEMENT si l'analyse a été générée avec succès
      if (!SubscriptionService.instance.isPremium) {
        await FeatureTrialService.instance.markFeatureAsUsed(
          FeatureTrialService.keyNutritionAnalysis,
        );
        debugPrint('✅ Nutrition Analysis trial marked as used after successful generation');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionAnalysisScreen(
              analysis: analysis,
              onRegenerate: () => _generateNewAnalysis(context),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating nutrition analysis: $e');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locService.currentLanguageCode == 'fr'
                  ? 'Erreur lors de la génération de l\'analyse: ${e.toString()}'
                  : 'Error generating analysis: ${e.toString()}',
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final isFrench = locService.currentLanguageCode == 'fr';

        // Déterminer l'apparence selon le contexte
        final buttonConfig = _getButtonConfig(isFrench);
        final showEndOfDayBadge = _currentContext == 'end_of_day';

        final isPremium = SubscriptionService.instance.isPremium;
        final isLocked = _isLocked ?? false;

        return GestureDetector(
          onTap: _isLoading ? null : () => _handleAnalysisTap(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: buttonConfig.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: buttonConfig.gradientColors[0].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildButtonContent(buttonConfig, isFrench),
              ),
              // Badge "Bilan dispo" en fin de journée
              if (showEndOfDayBadge && (isPremium || !isLocked))
                Positioned(
                  top: 4,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      isFrench ? 'Bilan dispo' : 'Summary ready',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Badge Premium à cheval sur le bord supérieur
              if (!isPremium && !_isCheckingLock)
                Positioned(
                  top: 0,
                  right: 32,
                  child: _CoachRyzePremiumBadge(
                    isLocked: isLocked,
                    isFrench: isFrench,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final isFrench = locService.currentLanguageCode == 'fr';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isFrench ? 'Analyse en cours...' : 'Analyzing...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonContent(_ButtonConfig config, bool isFrench) {
    return Row(
      children: [
        // Logo Coach Ryze
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            'assets/images/logo_solo.svg',
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        // Icône
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            config.icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  _ButtonConfig _getButtonConfig(bool isFrench) {
    switch (_currentContext) {
      case 'empty_day':
        return _ButtonConfig(
          title: isFrench ? 'Coach Ryze Nutrition' : 'Coach Ryze Nutrition',
          subtitle: isFrench
              ? 'Commence ta journée alimentaire'
              : 'Start your food day',
          icon: LucideIcons.sparkles,
          gradientColors: [
            const Color(0xFFEC4899), // Rose
            const Color(0xFFF43F5E), // Rouge-rose
          ],
        );

      case 'post_workout':
        return _ButtonConfig(
          title: isFrench ? 'Coach Ryze Nutrition' : 'Coach Ryze Nutrition',
          subtitle: isFrench
              ? 'Optimise ta récupération'
              : 'Optimize your recovery',
          icon: LucideIcons.zap,
          gradientColors: [
            const Color(0xFF8B5CF6), // Violet
            const Color(0xFF6366F1), // Indigo
          ],
        );

      case 'end_of_day':
        return _ButtonConfig(
          title: isFrench ? 'Coach Ryze Nutrition' : 'Coach Ryze Nutrition',
          subtitle: isFrench
              ? 'Bilan de ta journée'
              : 'Your daily summary',
          icon: LucideIcons.circleCheck,
          gradientColors: [
            const Color(0xFF0B132B), // Bleu foncé Ryze
            const Color(0xFF1E293B), // Slate
          ],
        );

      case 'in_progress':
      default:
        return _ButtonConfig(
          title: isFrench ? 'Coach Ryze Nutrition' : 'Coach Ryze Nutrition',
          subtitle: _cachedAnalysis != null
              ? (isFrench ? 'Voir ton analyse' : 'View your analysis')
              : (isFrench ? 'Analyse ta journée' : 'Analyze your day'),
          icon: _cachedAnalysis != null ? LucideIcons.eye : LucideIcons.activity,
          gradientColors: [
            const Color(0xFF0B132B), // Bleu foncé Ryze
            const Color(0xFF1E293B), // Slate
          ],
        );
    }
  }
}

/// Configuration d'apparence du bouton
class _ButtonConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  _ButtonConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });
}
