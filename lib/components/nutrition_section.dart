import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'nutrition_dashboard_hybrid.dart';
import 'nutrition_journal_hybrid.dart';
import 'nutrition_recipes_hybrid.dart';
import '../services/dashboard_service.dart';
import '../services/streak_service.dart';
import '../services/header_cache_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/global_state_manager.dart'; // NOUVEAU
import '../providers/goals_notifier.dart';
import 'ui/refresh_wrapper.dart';
import 'ui/custom_snackbar.dart';
import 'ui/global_state_header.dart';
import '../services/fast_cache_service.dart';
import 'ui/nutrition_tutorial_welcome.dart'; // Welcome screen nutrition
import 'tutorial/tutorial_overlay_system.dart'; // Nouveau système tutorial avec page mockée
import 'tutorial/tutorial_nutrition_dashboard.dart'; // Page nutrition mockée pour tutorial
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'; // Pour ContentAlign et ShapeLightFocus

class NutritionSection extends StatefulWidget {
  const NutritionSection({super.key});

  @override
  State<NutritionSection> createState() => _NutritionSectionState();
}

class _NutritionSectionState extends State<NutritionSection>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentIndex = 0;
  int _completedGoals = 0;
  int _totalGoals = 0;
  bool _loadingObjectives = true;
  int _currentStreak = 0;
  bool _loadingStreak = true;
  String _objectivesText(String languageCode) => _loadingObjectives ? '...' : '$_completedGoals/$_totalGoals ${'objectives'.tr(languageCode)}';
  String _streakText(String languageCode) => _loadingStreak ? '...' : '$_currentStreak ${'days'.tr(languageCode)}';

  // Tutorial GlobalKeys pour les 3 onglets
  final GlobalKey _dashboardTabKey = GlobalKey();
  final GlobalKey _journalTabKey = GlobalKey();
  final GlobalKey _recipesTabKey = GlobalKey();

  // GlobalKey pour accéder au state du Dashboard et lancer son tutorial
  final GlobalKey<NutritionDashboardHybridState> _dashboardWidgetKey = GlobalKey<NutritionDashboardHybridState>();

  List<String> _getPageNames(String languageCode) {
    return [
      'dashboard'.tr(languageCode),
      'journal'.tr(languageCode),
      'recipes'.tr(languageCode),
    ];
  }
  final List<IconData> _pageIcons = [
    LucideIcons.activity,
    LucideIcons.bookOpen,
    LucideIcons.chefHat,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);

    // OPTIMISATION: Charger instantanément depuis GlobalStateManager
    _loadInitialDataSync();

    // Forcer la mise à jour du compteur d'objectifs (en arrière-plan)
    DashboardService.refreshGoalsNotifier();

    // Lancer le tutorial après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNutritionTutorial();
    });
  }

  /// Affiche l'écran de bienvenue Nutrition si c'est la première visite
  Future<void> _showNutritionTutorial() async {
    // Vérifier si déjà complété (en mode debug, toujours afficher)
    const debugMode = true; // Mettre à false en production
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('nutrition_welcome_shown') ?? false;
      if (completed) {
        debugPrint('ℹ️ Welcome Nutrition déjà affiché');
        return;
      }
    }

    final locService = LocalizationService.instance;
    final globalState = GlobalStateManager.instance;

    // Afficher uniquement l'écran de bienvenue
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NutritionTutorialWelcome(
        languageCode: locService.currentLanguageCode,
        userName: globalState.userName,
        onStart: () => Navigator.of(context).pop(true),
        onSkip: () => Navigator.of(context).pop(false),
      ),
    );

    // Marquer le welcome comme affiché
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nutrition_welcome_shown', true);
    }

    if (shouldContinue == true) {
      debugPrint('✅ Welcome Nutrition terminé - Lancement du tutorial Dashboard');

      // Lancer le tutorial du Dashboard APRÈS le welcome
      await _launchDashboardTutorial();
    } else {
      debugPrint('⏭️ Welcome Nutrition skippé');
    }
  }

  /// Lance le tutorial du Dashboard Nutrition avec page mockée
  Future<void> _launchDashboardTutorial() async {
    // Petit délai pour que le welcome screen se ferme complètement
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final locService = LocalizationService.instance;

    // Créer les GlobalKeys pour la page mockée
    final caloriesKey = GlobalKey();
    final macrosKey = GlobalKey();
    final hydrationMealsKey = GlobalKey();
    final quickActionsKey = GlobalKey();

    // Créer la page mockée avec données vierges
    final mockPage = TutorialNutritionDashboard(
      caloriesKey: caloriesKey,
      macrosKey: macrosKey,
      hydrationMealsKey: hydrationMealsKey,
      quickActionsKey: quickActionsKey,
    );

    // Créer les targets pour le tutorial
    final targets = [
      TutorialOverlaySystem.createTarget(
        identify: 'calories',
        keyTarget: caloriesKey,
        title: 'tutorial_nutrition_calories_title'.tr(locService.currentLanguageCode),
        description: 'tutorial_nutrition_calories_desc'.tr(locService.currentLanguageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: 'assets/images/coach_ryze_nutrition_avatar.png',
        nextTargetKey: macrosKey, // Scroll vers macros après
      ),
      TutorialOverlaySystem.createTarget(
        identify: 'macros',
        keyTarget: macrosKey,
        title: 'tutorial_nutrition_macros_title'.tr(locService.currentLanguageCode),
        description: 'tutorial_nutrition_macros_desc'.tr(locService.currentLanguageCode),
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: 'assets/images/coach_ryze_nutrition_avatar.png',
        nextTargetKey: hydrationMealsKey, // Scroll vers hydratation après
      ),
      TutorialOverlaySystem.createTarget(
        identify: 'hydration_meals',
        keyTarget: hydrationMealsKey,
        title: 'tutorial_nutrition_hydration_meals_title'.tr(locService.currentLanguageCode),
        description: 'tutorial_nutrition_hydration_meals_desc'.tr(locService.currentLanguageCode),
        align: ContentAlign.top, // ✅ Bulle en haut comme demandé
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: 'assets/images/coach_ryze_nutrition_avatar.png',
        nextTargetKey: quickActionsKey, // Scroll vers quick actions après
      ),
      TutorialOverlaySystem.createTarget(
        identify: 'quick_actions',
        keyTarget: quickActionsKey,
        title: 'tutorial_nutrition_quick_actions_title'.tr(locService.currentLanguageCode),
        description: 'tutorial_nutrition_quick_actions_desc'.tr(locService.currentLanguageCode),
        align: ContentAlign.top, // ✅ Bulle en haut comme demandé
        shape: ShapeLightFocus.RRect,
        radius: 24,
        avatarPath: 'assets/images/coach_ryze_nutrition_avatar.png',
        // Pas de nextTargetKey, c'est la dernière étape
      ),
    ];

    // Lancer le tutorial avec la page mockée
    await TutorialOverlaySystem().showTutorial(
      context: context,
      mockPage: mockPage,
      targets: targets,
      onFinish: () {
        debugPrint('✅ Tutorial Nutrition terminé');
        // Le Navigator.pop() sera appelé automatiquement par tutorial_coach_mark
      },
      onSkip: () {
        debugPrint('⏭️ Tutorial Nutrition skippé');
        // Le Navigator.pop() sera appelé automatiquement par tutorial_coach_mark
      },
    );
  }

  /// [OBSOLÈTE] Ancien système de tutorial par onglet - remplacé par TutorialLiveOverlay
  /// Les tutorials d'onglets individuels ne sont plus utilisés avec le nouveau système
  Future<void> showTabTutorial(String tabName) async {
    debugPrint('⚠️ showTabTutorial() est obsolète - utilise TutorialLiveOverlay à la place');
    // Méthode vide - ne fait plus rien
  }

  /// Chargement synchrone instantané depuis GlobalStateManager
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;

    // Charger instantanément les objectifs depuis GlobalStateManager
    final goals = globalState.getDailyGoalsForDashboard();
    final completed = goals.where((g) => g['completed'] == true).length;

    setState(() {
      _completedGoals = completed;
      _totalGoals = goals.length;
      _loadingObjectives = false;
      _currentStreak = globalState.currentStreak;
      _loadingStreak = false;
    });

    debugPrint('⚡ Nutrition Section: Données header chargées en mode synchrone');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh() async {
    try {
      // OPTIMISATION: Vider le cache rapide pour forcer une vraie mise à jour
      FastCacheService.invalidateDashboard();

      // Forcer le rechargement complet
      await DashboardService.invalidateAndRefreshGoals();

      // Recharger les données header depuis GlobalState
      _loadInitialDataSync();

      // Vider le cache et forcer le rafraîchissement
      HeaderCacheService.clearCache();
      DashboardService.refreshGoalsNotifier();

      // Feedback visuel
      if (mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        CustomSnackbarService.showSuccess(
          context,
          locService.currentLanguageCode == 'fr' ? 'Données mises à jour' : 'Data updated',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement de la nutrition: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // Header avec titre et indicateurs de page
                  _buildHeader(),
                  
                  // Contenu principal avec PageView et RefreshIndicator
                  Expanded(
                    child: RefreshWrapper(
                      onRefresh: _onRefresh,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          NutritionDashboardHybrid(key: _dashboardWidgetKey),
                          const NutritionJournalHybrid(),
                          const NutritionRecipesHybrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // NOUVEAU: Bandeau global avec GlobalStateManager (synchronisé instantanément)
          const GlobalStateHeaderWidget(),
          
          const SizedBox(height: 8),
          
          // Navigation tabs avec trait sous l'onglet actuel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(3, (index) {
                final isSelected = _currentIndex == index;
                // Flex personnalisés : plus d'espace pour "Tableau de bord"
                final flex = index == 0 ? 3 : 2;

                // Sélectionner la GlobalKey appropriée
                final GlobalKey? tutorialKey = index == 0
                    ? _dashboardTabKey
                    : (index == 1 ? _journalTabKey : _recipesTabKey);

                return Expanded(
                  flex: flex,
                  child: GestureDetector(
                    key: tutorialKey, // Attacher la key pour le tutorial
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 2 ? 4 : 0,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _pageIcons[index],
                                  size: 16,
                                  color: isSelected 
                                      ? const Color(0xFF0B132B)
                                      : const Color(0xFF888888),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Consumer<LocalizationService>(
                                    builder: (context, localizationService, _) {
                                      final pageNames = _getPageNames(localizationService.currentLanguageCode);
                                      return Text(
                                        pageNames[index],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected 
                                              ? const Color(0xFF0B132B)
                                              : const Color(0xFF888888),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trait sous l'onglet actuel
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF0B132B) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBannerSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: Colors.white60, fontSize: 14)),
    );
  }

  Widget _buildBannerItemWithLogo(String text) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/logo_seul.svg',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
} 
