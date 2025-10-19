import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/coach_ryze_nutrition_service.dart';
import '../models/nutrition_models.dart';
import '../models/nutrition_analysis.dart';
import '../screens/nutrition_analysis_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadContextAndCache();
  }

  @override
  void didUpdateWidget(CoachRyzeNutritionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour le contexte si les repas changent
    if (oldWidget.todayMeals.length != widget.todayMeals.length) {
      _loadContextAndCache();
    }
  }

  Future<void> _loadContextAndCache() async {
    final context = await CoachRyzeNutritionService.detectContext(
      todayMeals: widget.todayMeals,
      hasWorkoutToday: widget.hasWorkoutToday,
      workoutTime: widget.workoutTime,
    );

    final cached = await CoachRyzeNutritionService.getAnalysisForDate(
      userId: widget.userId,
      date: widget.date,
    );

    if (mounted) {
      setState(() {
        _currentContext = context;
        _cachedAnalysis = cached;
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
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locService.currentLanguageCode == 'fr'
                  ? 'Erreur lors de la génération de l\'analyse'
                  : 'Error generating analysis',
            ),
            backgroundColor: const Color(0xFFEF4444),
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
              if (showEndOfDayBadge)
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
