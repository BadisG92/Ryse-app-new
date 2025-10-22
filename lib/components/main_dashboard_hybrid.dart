import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'ui/dashboard_models.dart';
import 'ui/dashboard_cards.dart';
import 'ui/dashboard_widgets.dart';
import 'ui/custom_card.dart';
import 'ui/custom_badge.dart';
import 'ui/global_state_header.dart';
import '../services/dashboard_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../providers/goals_notifier.dart';
import '../services/global_state_manager.dart';

class MainDashboardHybrid extends StatefulWidget {
  final Function(String)? onTabChange;
  
  const MainDashboardHybrid({super.key, this.onTabChange});

  @override
  State<MainDashboardHybrid> createState() => _MainDashboardHybridState();
}

class _MainDashboardHybridState extends State<MainDashboardHybrid>
    with TickerProviderStateMixin, GlobalStateListener {
  
  // State variables
  UserProfile? userProfile;
  List<DailyGoal> dailyGoals = [];
  List<ModulePreview> modulePreviews = [];
  late AnimationController _scoreAnimationController;
  late Timer _scoreTimer;
  int animatedScore = 0;
  bool isLoading = false; // Ne jamais bloquer l'affichage - toujours afficher le squelette

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _initializeAnimations();

    // OPTIMISATION: Charger instantanément depuis GlobalState en mode synchrone
    _loadInitialDataSync();

    // Puis charger les vraies données en arrière-plan
    _loadDashboardData();

    // Listen to language changes
    LocalizationService.instance.addListener(_onLanguageChanged);

    // Listen to goals changes for instant updates
    GoalsNotifier.instance.addListener(_onGoalsChanged);
  }

  /// Chargement synchrone instantané pour éviter tout flash
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;
    final locService = LocalizationService.instance;

    // Créer un profil basique instantanément avec le nom déjà formaté depuis GlobalState
    userProfile = UserProfile(
      name: globalState.userName, // Utiliser directement le nom formaté du GlobalState
      streak: globalState.currentStreak,
      todayScore: _calculateTodayScore(globalState),
      todayXP: _calculateTodayXP(globalState),
      isPremium: false, // Sera mis à jour
      photosUsed: 0,
      dailyCalories: globalState.calorieGoal.toInt(),
      currentCalories: globalState.currentCalories.toInt(),
    );

    // Charger les objectifs depuis GlobalState
    dailyGoals = GlobalStateManager.instance.getDailyGoalsForDashboard().map((data) =>
      DailyGoal(
        id: data['id'] as String,
        label: data['label'] as String,
        progress: data['progress'] as int,
        xp: data['xp'] as int,
        completed: data['completed'] as bool,
        isPremium: false,
        currentValue: data['currentValue'] as double?,
        targetValue: data['targetValue'] as double?,
        unit: data['unit'] as String?,
      )
    ).toList();

    // Charger les modules avec vraies données
    modulePreviews = _buildModulePreviewsFromGlobalState(globalState, locService.currentLanguageCode);

    // Démarrer l'animation du score
    _startScoreAnimation();

    print('⚡ Dashboard: Données initiales chargées en mode synchrone');
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    // S'assurer que les timers sont vraiment cancellés
    if (_scoreTimer.isActive) {
      _scoreTimer.cancel();
    }
    LocalizationService.instance.removeListener(_onLanguageChanged);
    GoalsNotifier.instance.removeListener(_onGoalsChanged);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _onLanguageChanged() {
    // Reload dashboard data when language changes
    _loadDashboardData();
  }
  
  void _onGoalsChanged() {
    // Recharger seulement les objectifs pour une mise à jour instantanée
    _reloadGoalsOnly();
  }
  
  Future<void> _reloadGoalsOnly() async {
    if (!mounted) return;

    try {
      // NOUVEAU: Recharger depuis GlobalStateManager pour mise à jour instantanée
      final newGoals = GlobalStateManager.instance.getDailyGoalsForDashboard().map((data) =>
        DailyGoal(
          id: data['id'] as String,
          label: data['label'] as String,
          progress: data['progress'] as int,
          xp: data['xp'] as int,
          completed: data['completed'] as bool,
          isPremium: false,
          currentValue: data['currentValue'] as double?,
          targetValue: data['targetValue'] as double?,
          unit: data['unit'] as String?,
        )
      ).toList();

      if (mounted) {
        setState(() {
          dailyGoals = newGoals;
        });
        print('🔄 Objectifs dashboard principal rechargés instantanément depuis GlobalState');
      }
    } catch (e) {
      print('❌ Erreur rechargement objectifs: $e');
    }
  }

  void _initializeAnimations() {
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _startScoreAnimation() {
    final targetScore = userProfile?.todayScore ?? 85;
    _scoreTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (animatedScore < targetScore) {
        setState(() {
          animatedScore = min(animatedScore + 1, targetScore);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    // OPTIMISATION: Charger instantanément depuis GlobalStateManager
    final globalState = GlobalStateManager.instance;

    // Créer un UserProfile basique avec les données GlobalState pour affichage immédiat
    final locService = LocalizationService.instance;
    final quickProfile = await _buildUserProfileFromGlobalState(globalState);

    // Charger instantanément les objectifs depuis GlobalState
    final quickGoals = GlobalStateManager.instance.getDailyGoalsForDashboard().map((data) =>
      DailyGoal(
        id: data['id'] as String,
        label: data['label'] as String,
        progress: data['progress'] as int,
        xp: data['xp'] as int,
        completed: data['completed'] as bool,
        isPremium: false,
        currentValue: data['currentValue'] as double?,
        targetValue: data['targetValue'] as double?,
        unit: data['unit'] as String?,
      )
    ).toList();

    // Charger instantanément les modules avec vraies données
    final quickModules = _buildModulePreviewsFromGlobalState(globalState, locService.currentLanguageCode);

    // Affichage INSTANTANÉ - plus de loading, plus d'erreur
    if (mounted) {
      setState(() {
        userProfile = quickProfile;
        dailyGoals = quickGoals;
        modulePreviews = quickModules;
      });

      // Démarrer l'animation du score
      _startScoreAnimation();
    }

    print('⚡ Dashboard: Affichage instantané depuis GlobalState');

    // En arrière-plan, charger le vrai profil utilisateur depuis la DB pour les infos complémentaires
    try {
      final loadedProfile = await DashboardService.getUserProfile();

      if (mounted && loadedProfile != null) {
        setState(() {
          // Mettre à jour avec les vraies données (nom, streak, premium, etc.)
          // mais garder les calories/eau/score du GlobalState qui sont plus à jour
          userProfile = loadedProfile.copyWith(
            currentCalories: globalState.currentCalories.toInt(),
            todayScore: _calculateTodayScore(globalState), // ✅ Recalculer le score en temps réel
            todayXP: _calculateTodayXP(globalState), // ✅ Recalculer les XP en temps réel
          );
        });

        // Redémarrer l'animation du score avec les vraies valeurs
        _startScoreAnimation();
      }
    } catch (e) {
      print('⚠️ Erreur chargement profil DB (non-bloquant): $e');
      // On garde le profil basique du GlobalState - pas d'erreur affichée
    }
  }

  /// Construit un UserProfile basique depuis le GlobalState pour affichage immédiat
  Future<UserProfile> _buildUserProfileFromGlobalState(GlobalStateManager globalState) async {
    // Récupérer directement depuis GlobalState (déjà chargé à l'init)
    return UserProfile(
      name: globalState.userName,
      streak: globalState.currentStreak,
      todayScore: _calculateTodayScore(globalState),
      todayXP: _calculateTodayXP(globalState),
      isPremium: globalState.isPremium,
      photosUsed: 0, // Sera mis à jour par le vrai profil
      dailyCalories: globalState.calorieGoal.toInt(),
      currentCalories: globalState.currentCalories.toInt(),
    );
  }

  /// Calcule le score du jour basé sur les objectifs complétés
  int _calculateTodayScore(GlobalStateManager globalState) {
    final goals = globalState.getDailyGoalsForDashboard();
    final completedCount = goals.where((g) => g['completed'] == true).length;
    final score = (completedCount / goals.length * 100).round();

    // DEBUG: Afficher les objectifs et le score
    print('🎯 DEBUG Score:');
    print('   - Objectifs complétés: $completedCount/${goals.length}');
    for (var goal in goals) {
      print('   - ${goal['label']}: ${goal['completed'] ? '✅' : '❌'} (${goal['progress']}%)');
    }
    print('   - Score final: $score%');

    return score;
  }

  /// Calcule les XP du jour
  int _calculateTodayXP(GlobalStateManager globalState) {
    final goals = globalState.getDailyGoalsForDashboard();
    int totalXP = 0;
    for (var goal in goals) {
      if (goal['completed'] == true) {
        totalXP += goal['xp'] as int;
      }
    }
    return totalXP;
  }

  /// Construit les ModulePreviews avec les vraies données du GlobalState
  List<ModulePreview> _buildModulePreviewsFromGlobalState(GlobalStateManager globalState, String languageCode) {
    return [
      ModulePreview(
        title: 'nutrition'.tr(languageCode),
        icon: LucideIcons.apple,
        stats: {
          'calories'.tr(languageCode): '${globalState.currentCalories.toInt()} kcal',
          'water'.tr(languageCode): '${globalState.currentWaterL.toStringAsFixed(1)}L',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      ),
      ModulePreview(
        title: 'sport'.tr(languageCode),
        icon: LucideIcons.dumbbell,
        stats: {
          'calories'.tr(languageCode): '${globalState.sportCaloriesBurned} kcal',
          'sessions'.tr(languageCode): '${globalState.sportSessions}',
        },
        gradientColors: const [Color(0xFF0B132B), Color(0xFF1C2951)],
      ),
    ];
  }

  // Supprimé : Le dashboard ne doit pas recalculer les objectifs
  // Les objectifs sont calculés uniquement :
  // 1. À l'onboarding (première utilisation)
  // 2. Quand l'utilisateur modifie ses paramètres dans la page paramètres
  // Le dashboard récupère les objectifs depuis DashboardService qui utilise les bonnes données historiques

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header avec bandeau global (identique aux autres pages)
          _buildHeader(),

          // Contenu scrollable
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDashboardData,
              color: const Color(0xFF0B132B),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                          // Objectifs du jour - Toujours affiché
                          EnhancedDailyGoalsSection(
                            goals: dailyGoals.isNotEmpty ? dailyGoals : DashboardData.dailyGoals,
                            profile: userProfile!,
                            isPremium: userProfile!.isPremium,
                          ),

                          const SizedBox(height: 16),

                          // Actions rapides - Toujours affiché
                          Consumer<LocalizationService>(
                            builder: (context, locService, child) => QuickActionsSection(
                              actions: DashboardData.getOriginalActionsWithWeight(userProfile!, locService.currentLanguageCode),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Suivi Nutrition & Sport - Toujours avec vraies données
                          Consumer<LocalizationService>(
                            builder: (context, locService, child) => NutritionSportTrackingSection(
                              modules: modulePreviews.isNotEmpty
                                ? modulePreviews
                                : DashboardData.getModulePreviews(locService.currentLanguageCode),
                              onModuleTap: _onModuleTap,
                            ),
                          ),

                          const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le header avec le bandeau global et le message de bienvenue
  Widget _buildHeader() {
    if (userProfile == null) {
      return const SizedBox.shrink();
    }

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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bandeau global avec GlobalStateManager (synchronisé instantanément)
          // useGradient: false pour hériter du gradient du container parent
          const GlobalStateHeaderWidget(useGradient: false),

          // Séparation visuelle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Message de bienvenue personnalisé (intégré dans le header)
          Consumer<LocalizationService>(
            builder: (context, locService, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message d'accueil engageant (plus gros)
                      Text(
                        userProfile!.greetingMessage(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 8),
                      // CTA actionnable (plus petit)
                      Text(
                        userProfile!.contextualMessage(locService.currentLanguageCode),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Actualiser les données du dashboard
  Future<void> _refreshDashboardData() async {
    await _loadDashboardData();
  }

  // Event handlers - restaurés du design original
  void _onPremiumUpgrade() {
    if (mounted && userProfile != null) {
      setState(() {
        userProfile = userProfile!.copyWith(isPremium: true);
      });
    }
    
    // TODO: Intégrer avec la logique de paiement
    final locService = LocalizationService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('welcome_premium'.tr(locService.currentLanguageCode)),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onModuleTap(String moduleTitle) {
    final locService = LocalizationService.instance;
    final nutritionTitle = 'nutrition'.tr(locService.currentLanguageCode);
    final sportTitle = 'sport'.tr(locService.currentLanguageCode);
    
    if (widget.onTabChange != null) {
      if (moduleTitle == nutritionTitle) {
        // Changer vers l'onglet nutrition
        widget.onTabChange!('nutrition');
      } else if (moduleTitle == sportTitle) {
        // Changer vers l'onglet sport
        widget.onTabChange!('sport');
      }
    } else {
      // Fallback si pas de callback disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'navigate_to'.tr(locService.currentLanguageCode)} $moduleTitle'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onViewAnalytics() {
    // TODO: Ouvrir les analytics avancés
    final locService = LocalizationService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('open_advanced_analytics'.tr(locService.currentLanguageCode)),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Implémentation requise par le mixin GlobalStateListener
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // Mise à jour instantanée quand l'état global change
    print('🔄 Dashboard: Mise à jour reçue du GlobalState - ${event.type}');

    // Si c'est un nouveau jour, recharger toutes les données
    if (event.type == ChangeType.dayReset) {
      print('🌅 Dashboard: Nouveau jour détecté, rechargement complet...');
      _loadDashboardData();
      return;
    }

    // Recharger les objectifs immédiatement depuis GlobalStateManager
    _reloadGoalsOnly();

    // Mettre à jour les modules avec les nouvelles données
    final globalState = GlobalStateManager.instance;
    final locService = LocalizationService.instance;

    if (mounted) {
      setState(() {
        // Mettre à jour les modules preview avec les vraies données
        modulePreviews = _buildModulePreviewsFromGlobalState(globalState, locService.currentLanguageCode);

        // Mettre à jour le userProfile avec les nouvelles calories si disponible
        if (userProfile != null) {
          userProfile = userProfile!.copyWith(
            currentCalories: globalState.currentCalories.toInt(),
            todayScore: _calculateTodayScore(globalState),
            todayXP: _calculateTodayXP(globalState),
          );

          // Redémarrer l'animation du score
          _startScoreAnimation();
        }
      });
    }
  }
}

// Section objectifs améliorée avec progression calorique et globale
class EnhancedDailyGoalsSection extends StatefulWidget {
  final List<DailyGoal> goals;
  final UserProfile profile;
  final bool isPremium;

  const EnhancedDailyGoalsSection({
    super.key,
    required this.goals,
    required this.profile,
    required this.isPremium,
  });

  @override
  State<EnhancedDailyGoalsSection> createState() => _EnhancedDailyGoalsSectionState();
}

class _EnhancedDailyGoalsSectionState extends State<EnhancedDailyGoalsSection>
    with TickerProviderStateMixin {
  
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  int animatedProgress = 0;
  int _targetProgress = 0; // Cible actuelle de l'animation
  Timer? _progressTimer; // Nullable pour vérification

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startProgressAnimation();
  }

  @override
  void didUpdateWidget(EnhancedDailyGoalsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculer la cible et redémarrer l'animation seulement si elle a changé
    if (oldWidget.goals != widget.goals) {
      // Calculer la nouvelle progression cible
      double totalProgress = 0;
      for (final goal in widget.goals) {
        final cappedProgress = goal.progress.clamp(0, 100);
        final goalContribution = (cappedProgress / 100.0) * 25.0;
        totalProgress += goalContribution;
      }
      final newTargetProgress = totalProgress.round().clamp(0, 100);

      // Ne relancer l'animation que si la cible a réellement changé
      if (newTargetProgress != _targetProgress) {
        _startProgressAnimation();
      }
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimation() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutExpo,
    );
  }

  void _startProgressAnimation() {
    // Annuler l'animation précédente si elle existe
    _progressTimer?.cancel();

    // Calculer la progression globale basée sur les pourcentages réels (25% par objectif)
    double totalProgress = 0;
    for (final goal in widget.goals) {
      // Chaque objectif vaut 25% du total maximum, cappé à 25%
      final cappedProgress = goal.progress.clamp(0, 100); // Capper à 100%
      final goalContribution = (cappedProgress / 100.0) * 25.0; // Max 25% par objectif
      totalProgress += goalContribution;
    }
    final targetProgress = totalProgress.round().clamp(0, 100); // Progression totale sur 100

    // Mémoriser la nouvelle cible
    _targetProgress = targetProgress;

    // Réinitialiser à 0 pour l'effet d'animation depuis le début
    if (mounted) {
      setState(() => animatedProgress = 0);
    }

    // Animation par étapes pour un effet fluide - toujours partir de 0
    const tickTime = 20; // 20ms
    const duration = 1200; // 1.2 secondes pour une animation visible

    _progressTimer = Timer.periodic(const Duration(milliseconds: tickTime), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = timer.tick * tickTime;
      final progress = (elapsed / duration).clamp(0.0, 1.0);
      final easedProgress = Curves.easeOutExpo.transform(progress);
      final currentValue = (targetProgress * easedProgress).round();

      setState(() => animatedProgress = currentValue);

      if (progress >= 1.0) {
        timer.cancel();
        if (mounted) {
          setState(() => animatedProgress = targetProgress);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculer les stats
    final completedGoals = widget.goals.where((goal) => goal.completed).length;
    final totalGoals = widget.goals.length;
    
    // Progression globale réelle (0.0 à 1.0)
    final globalProgressReal = completedGoals / totalGoals;
    
    // Progression animée pour l'affichage (0 à 100%)
    final globalProgressAnimated = animatedProgress / 100.0;
    const showGlobalProgressBar = false;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.target, 
                      size: 20, 
                      color: Color(0xFF0B132B),
                    ),
                    const SizedBox(width: 12),
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        'dashboard_daily_goals'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$completedGoals/$totalGoals',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Liste des objectifs
            ...widget.goals.map((goal) => DailyGoalItem(
              goal: goal,
              isPremium: widget.isPremium,
            )).toList(),
            
            if (showGlobalProgressBar) const SizedBox(height: 16),
            
            if (showGlobalProgressBar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0B132B).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            'progress'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        Text(
                          '$animatedProgress%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: globalProgressAnimated,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Bloc suivi Nutrition & Sport (hybrid format nouveau)
class NutritionSportTrackingSection extends StatelessWidget {
  final List<ModulePreview> modules;
  final Function(String moduleTitle)? onModuleTap;

  const NutritionSportTrackingSection({
    super.key,
    required this.modules,
    this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'nutrition_sport_tracking'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Blocs Nutrition et Sport style hybrid
            Row(
              children: modules.map((module) => 
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: modules.indexOf(module) < modules.length - 1 ? 12 : 0,
                    ),
                    child: _buildHybridModuleCard(module),
                  ),
                )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHybridModuleCard(ModulePreview module) {
    return GestureDetector(
      onTap: onModuleTap != null 
          ? () => onModuleTap!(module.title)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône et titre
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: module.gradientColors),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    module.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Stats du module
            ...module.stats.entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}

// Actions rapides gamifiées (5 actions avec pesée)
class GamifiedActionsSection extends StatelessWidget {
  final List<QuickAction> actions;

  const GamifiedActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            // Grille 2x3 pour 5 actions uniformes
            Column(
              children: [
                // Première ligne : 3 actions
                Row(
                  children: actions.take(3).map((action) => 
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: actions.indexOf(action) < 2 ? 8 : 0,
                        ),
                        child: _buildGamifiedAction(context, action),
                      ),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 8),
                // Deuxième ligne : 2 actions centrées
                Row(
                  children: [
                    Expanded(flex: 1, child: Container()),
                    ...actions.skip(3).take(2).map((action) => 
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: actions.indexOf(action) < actions.length - 1 ? 8 : 0,
                          ),
                          child: _buildGamifiedAction(context, action),
                        ),
                      )
                    ).toList(),
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamifiedAction(BuildContext context, QuickAction action) {
    return GestureDetector(
      onTap: () => _handleGamifiedAction(context, action),
      child: Container(
        height: 80, // Taille fixe pour uniformité
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: action.isDisabled 
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: action.isDisabled ? const Color(0xFFF1F5F9) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: action.isDisabled ? null : [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: 24,
              color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: action.isDisabled ? const Color(0xFF64748B) : Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGamifiedAction(BuildContext context, QuickAction action) {
    if (action.isDisabled || action.isPremiumRequired) {
      final locService = LocalizationService.instance;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feature_premium_only'.tr(locService.currentLanguageCode)),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    switch (action.id) {
      case 'add_meal':
        // TODO: Ouvrir sélection de repas
        final locService = LocalizationService.instance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('adding_meal'.tr(locService.currentLanguageCode)),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case 'add_water':
        // TODO: Ouvrir ajout d'eau
        final locService = LocalizationService.instance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('adding_hydration'.tr(locService.currentLanguageCode)),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case 'take_photo':
        // TODO: Ouvrir scanner IA
        final locService = LocalizationService.instance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('food_scanner'.tr(locService.currentLanguageCode)),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case 'workout':
        // TODO: Ouvrir sélection d'entraînement
        final locService = LocalizationService.instance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('starting_workout'.tr(locService.currentLanguageCode)),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
      case 'weight_tracking':
        // TODO: Ouvrir saisie de poids
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enregistrement du poids'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B132B).withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        break;
    }
  }
}

// Progression compacte mais engageante (style ancien amélioré)
class CompactProgressSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final UserProfile profile;

  const CompactProgressSection({
    super.key,
    required this.goals,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final completedGoals = goals.where((g) => g.completed).length;
    final totalGoals = goals.length;
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header avec progression globale
            Row(
              children: [
                Icon(
                  LucideIcons.target,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'daily_objectives'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedGoals >= 3 
                        ? const Color(0xFF22C55E).withOpacity(0.1)
                        : const Color(0xFF0B132B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedGoals/$totalGoals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: completedGoals >= 3 
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF0B132B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Liste compacte des objectifs
            ...goals.map((goal) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCompactGoalItem(goal),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGoalItem(DailyGoal goal) {
    final isCompleted = goal.completed;
    
    return Row(
      children: [
        // Icône de statut
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted 
                ? const Color(0xFF22C55E)
                : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: isCompleted 
              ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
              : null,
        ),
        
        const SizedBox(width: 12),
        
        // Texte de l'objectif
        Expanded(
          child: Text(
            goal.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCompleted 
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF64748B),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        
        // Badge XP ou progression
        if (isCompleted)
          CustomBadge(
            text: '+${goal.xp} XP',
            backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
            textColor: const Color(0xFF22C55E),
          )
        else
          Text(
            goal.progressText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
      ],
    );
  }
}

// Coach intégré (sans Premium)
class IntegratedCoachSection extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const IntegratedCoachSection({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    final coachMessage = _getCoachMessage(profile, completedGoals, totalGoals);
    final coachEmoji = _getCoachEmoji(completedGoals, totalGoals);
    
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.03),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar du coach avec animation
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  coachEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Message du coach
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coach Ryze',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coachMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCoachMessage(UserProfile profile, int completed, int total) {
    final completionRate = completed / total;
    final hour = DateTime.now().hour;
    
    if (completionRate >= 0.75) {
      return "Excellent ! Tu es sur une lancée fantastique aujourd'hui. Continue comme ça ! 🔥";
    } else if (completionRate >= 0.5) {
      return "Bon rythme ! Tu es à mi-parcours de tes objectifs. Encore un petit effort !";
    } else if (hour < 12) {
      return "La journée commence bien ! Prends un bon petit-déjeuner pour avoir de l'énergie.";
    } else if (hour < 17) {
      return "C'est le moment parfait pour se remettre sur les rails. Que dirais-tu d'une pause active ?";
    } else {
      return "Pas de stress ! Même les petites actions comptent. Demain sera un nouveau jour !";
    }
  }

  String _getCoachEmoji(int completed, int total) {
    final completionRate = completed / total;
    if (completionRate >= 0.75) return "🏆";
    if (completionRate >= 0.5) return "💪";
    if (completionRate >= 0.25) return "👍";
    return "🎯";
  }
}

// Badge de réussite du jour
class DailyAchievementBadge extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const DailyAchievementBadge({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = _getTodayAchievement(profile, completedGoals, totalGoals);
    if (achievement == null) return Container();
    
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              achievement['color'].withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement['color'].withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Badge d'achievement
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: achievement['color'],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: achievement['color'].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement['emoji'],
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Texte d'achievement
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: achievement['color'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bonus XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: achievement['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${achievement['xp']} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement['color'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getTodayAchievement(UserProfile profile, int completed, int total) {
    final completionRate = completed / total;
    final streak = profile.streak;
    final caloriesProgress = profile.caloriesProgress;
    
    // Achievement parfait
    if (completed == total) {
      return {
        'title': 'Jour Parfait !',
        'description': 'Tous les objectifs atteints !',
        'emoji': '🏆',
        'color': const Color(0xFFFFD700),
        'xp': 100,
      };
    }
    
    // Achievement streak
    if (streak >= 7 && completionRate >= 0.75) {
      return {
        'title': 'Série de Feu !',
        'description': '$streak jours consécutifs !',
        'emoji': '🔥',
        'color': const Color(0xFFFF6B35),
        'xp': 75,
      };
    }
    
    // Achievement calories
    if (caloriesProgress >= 0.9 && caloriesProgress <= 1.1) {
      return {
        'title': 'Équilibre Parfait',
        'description': 'Objectif calorique maîtrisé !',
        'emoji': '⚖️',
        'color': const Color(0xFF22C55E),
        'xp': 50,
      };
    }
    
    // Achievement progression
    if (completionRate >= 0.75) {
      return {
        'title': 'Belle Progression !',
        'description': 'Tu es sur la bonne voie !',
        'emoji': '💪',
        'color': const Color(0xFF0B132B),
        'xp': 25,
      };
    }
    
    return null;
  }
}

// Section détaillée supprimée - remplacée par CompactProgressSection
class DetailedProgressSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final UserProfile profile;

  const DetailedProgressSection({
    super.key,
    required this.goals,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Progression détaillée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...goals.map((goal) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDetailedGoalItem(goal),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedGoalItem(DailyGoal goal) {
    final isCompleted = goal.completed;
    final progress = goal.progressPercent;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFF22C55E).withOpacity(0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF22C55E).withOpacity(0.2)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : LucideIcons.target,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.progressText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                CustomBadge(
                  text: '+${goal.xp} XP',
                  backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
                  textColor: const Color(0xFF22C55E),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section détaillée supprimée car remplacée par CompactProgressSection
// Cette classe est conservée pour éviter les erreurs de compilation
class PersonalizedInsightsSection extends StatelessWidget {
  final UserProfile profile;
  final bool isPremium;
  final VoidCallback? onUpgrade;
  final VoidCallback? onViewAnalytics;

  const PersonalizedInsightsSection({
    super.key,
    required this.profile,
    required this.isPremium,
    this.onUpgrade,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    // Section supprimée - fonctionnalité intégrée dans IntegratedCoachSection
    return Container();
  }

}

// Section motivation supprimée car remplacée par IntegratedCoachSection et DailyAchievementBadge
// Cette classe est conservée pour éviter les erreurs de compilation
class MotivationSection extends StatelessWidget {
  final UserProfile profile;
  final int completedGoals;
  final int totalGoals;

  const MotivationSection({
    super.key,
    required this.profile,
    required this.completedGoals,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    // Section supprimée - fonctionnalité intégrée dans IntegratedCoachSection et DailyAchievementBadge
    return Container();
  }
}

// Extension pour faciliter la copie du UserProfile
extension UserProfileCopyWith on UserProfile {
  UserProfile copyWith({
    String? name,
    int? streak,
    int? todayScore,
    int? todayXP,
    bool? isPremium,
    int? photosUsed,
    int? dailyCalories,
    int? currentCalories,
  }) {
    return UserProfile(
      name: name ?? this.name,
      streak: streak ?? this.streak,
      todayScore: todayScore ?? this.todayScore,
      todayXP: todayXP ?? this.todayXP,
      isPremium: isPremium ?? this.isPremium,
      photosUsed: photosUsed ?? this.photosUsed,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      currentCalories: currentCalories ?? this.currentCalories,
    );
  }
} 
