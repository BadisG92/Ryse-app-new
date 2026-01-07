import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'nutrition_dashboard_hybrid.dart';
import 'nutrition_journal_hybrid.dart';
import 'nutrition_recipes_hybrid.dart';
import '../services/dashboard_service.dart';
import '../services/header_cache_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/tutorial_service.dart';
import '../services/global_state_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ui/refresh_wrapper.dart';
import 'ui/custom_snackbar.dart';
import 'ui/global_state_header.dart';
import '../services/fast_cache_service.dart';
import 'ui/nutrition_tutorial_welcome.dart';
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
    debugPrint('🔍 Vérification du tutorial Nutrition...');

    // ✅ VÉRIFIER DANS SUPABASE si le tutorial est déjà complété
    // On utilise directement la vérification interne du TutorialService
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await supabase
            .from('users')
            .select('tutorial_nutrition_completed')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 3));

        final isCompleted = response['tutorial_nutrition_completed'] as bool? ?? false;
        debugPrint('📊 Tutorial Nutrition dans Supabase: $isCompleted');

        if (isCompleted) {
          debugPrint('✅ Tutorial Nutrition déjà complété - Arrêt');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur vérification Supabase: $e - On continue quand même');
      }
    }

    final locService = LocalizationService.instance;
    final globalState = GlobalStateManager.instance;

    debugPrint('🚀 Affichage du Welcome Screen Nutrition...');
    // Afficher l'écran de bienvenue en PLEIN ÉCRAN (pas en dialog)
    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => NutritionTutorialWelcome(
          languageCode: locService.currentLanguageCode,
          userName: globalState.userName,
          onStart: () => Navigator.of(context).pop(true),
          onSkip: () => Navigator.of(context).pop(false),
        ),
      ),
    );

    // ℹ️ Note: On ne marque RIEN ici car c'est le TutorialService qui gère la sauvegarde
    // dans Supabase avec la clé 'tutorial_nutrition_completed'

    if (shouldContinue == true) {
      debugPrint('✅ Welcome Nutrition terminé - Lancement du tutorial');

      // Lancer d'abord le tutorial des onglets (sur la vraie page)
      final tabsCompleted = await _launchTabsTutorial();

      // Puis lancer le tutorial du Dashboard SEULEMENT si les onglets n'ont pas été skippés
      if (tabsCompleted) {
        await _launchDashboardTutorial();
      } else {
        debugPrint('⏭️ Tutorial onglets skippé - Arrêt complet du tutorial');
        // IMPORTANT: Marquer le tutoriel comme complété même si skippé
        await TutorialService().markTutorialAsCompleted('tutorial_nutrition_completed');
      }
    } else {
      debugPrint('🔴 === BOUTON "PASSER" APPUYÉ - WELCOME SCREEN NUTRITION ===');
      // Marquer le tutoriel comme complété dans Supabase via TutorialService
      await TutorialService().markTutorialAsCompleted('tutorial_nutrition_completed');
      debugPrint('⏭️ Welcome Nutrition skippé');
    }
  }

  /// Lance le tutorial des onglets Nutrition (partie 1)
  /// Retourne true si le tutorial est terminé, false si skippé
  Future<bool> _launchTabsTutorial() async {
    // Petit délai pour s'assurer que tout est rendu
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return false;

    final locService = LocalizationService.instance;

    // Completer pour attendre la fin du tutorial (true = terminé, false = skippé)
    final completer = Completer<bool>();

    // Créer les targets pour les 3 onglets
    final tabsTargets = [
      TargetFocus(
        identify: 'dashboard_tab',
        keyTarget: _dashboardTabKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'tutorial_nutrition_dashboard_tab_title'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tutorial_nutrition_dashboard_tab_desc'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => controller.next(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'understood'.tr(LocalizationService.instance.currentLanguageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: 'journal_tab',
        keyTarget: _journalTabKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'tutorial_nutrition_journal_tab_title'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tutorial_nutrition_journal_tab_desc'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => controller.next(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'understood'.tr(LocalizationService.instance.currentLanguageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: 'recipes_tab',
        keyTarget: _recipesTabKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'tutorial_nutrition_recipes_tab_title'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tutorial_nutrition_recipes_tab_desc'.tr(locService.currentLanguageCode),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => controller.next(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'understood'.tr(LocalizationService.instance.currentLanguageCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ];

    // Créer et afficher le tutorial des onglets
    final tabsTutorial = TutorialCoachMark(
      targets: tabsTargets,
      colorShadow: const Color(0xFF0B132B),
      paddingFocus: 8,
      opacityShadow: 0.8, // Même opacité que la page d'accueil
      alignSkip: Alignment.topRight,
      hideSkip: false,
      textSkip: 'skip'.tr(locService.currentLanguageCode),
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onSkip: () {
        debugPrint('⏭️ Tutorial onglets skippé');
        completer.complete(false); // Retourner false = skippé
        return true;
      },
      onFinish: () {
        debugPrint('✅ Tutorial onglets terminé');
        completer.complete(true); // Retourner true = terminé normalement
      },
    );

    if (mounted) {
      tabsTutorial.show(context: context);
    }

    // Attendre que le tutorial soit terminé avant de continuer
    return completer.future;
  }

  /// Lance le tutorial du Dashboard Nutrition sur la vraie page (partie 2)
  Future<void> _launchDashboardTutorial() async {
    // Petit délai pour que le tutorial des onglets se ferme complètement
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Appeler la méthode du Dashboard qui lance le tutorial sur la vraie page
    await _dashboardWidgetKey.currentState?.showDashboardTutorial(
      dashboardTabKey: _dashboardTabKey,
      journalTabKey: _journalTabKey,
      recipesTabKey: _recipesTabKey,
    );

    debugPrint('✅ Tutorial Dashboard Nutrition terminé');
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
        resizeToAvoidBottomInset: false, // Empêche la barre d'onglets de monter avec le clavier
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
