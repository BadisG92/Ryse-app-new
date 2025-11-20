import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'sport_dashboard.dart';
import 'sport_cardio_hybrid.dart';
import 'sport_musculation_hybrid.dart';
import '../services/dashboard_service.dart';
import '../services/streak_service.dart';
import '../services/header_cache_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/tutorial_service.dart';
import 'ui/custom_snackbar.dart';
import 'ui/global_state_header.dart';
import 'package:provider/provider.dart';
import 'ui/refresh_wrapper.dart';
import '../services/fast_cache_service.dart';
import '../services/sport_dashboard_service.dart';
import '../services/global_state_manager.dart';
import 'ui/sport_tutorial_welcome.dart'; // Welcome screen sport
import 'ui/cardio_tutorial_welcome.dart'; // Welcome screen cardio
import 'ui/musculation_tutorial_welcome.dart'; // Welcome screen musculation
import 'package:shared_preferences/shared_preferences.dart';

class SportSection extends StatefulWidget {
  const SportSection({super.key});

  @override
  State<SportSection> createState() => _SportSectionState();
}

class _SportSectionState extends State<SportSection>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentIndex = 0;
  int _completedGoals = 0;
  int _totalGoals = 0;
  int _currentStreak = 0;
  final GlobalKey<SportDashboardState> _dashboardKey = GlobalKey<SportDashboardState>();
  final GlobalKey<SportCardioHybridState> _cardioKey = GlobalKey<SportCardioHybridState>();

  // Tutorial GlobalKeys pour les 3 onglets
  final GlobalKey _dashboardTabKey = GlobalKey();
  final GlobalKey _cardioTabKey = GlobalKey();
  final GlobalKey _musculationTabKey = GlobalKey();

  // GlobalKey pour accéder au widget Musculation
  final GlobalKey<SportMusculationHybridState> _musculationKey = GlobalKey<SportMusculationHybridState>();

  // Suivre si les tutorials ont été lancés
  bool _cardioTutorialLaunched = false;
  bool _musculationTutorialLaunched = false;

  void _openSportCalendar() {
    // Naviguer vers le dashboard (index 0) si on n'y est pas déjà
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      _pageController.jumpToPage(0);
      _tabController.animateTo(0);

      // Attendre que la page soit construite avant d'ouvrir le calendrier
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dashboardKey.currentState?.openCalendar();
      });
    } else {
      // Si on est déjà sur le dashboard, ouvrir directement le calendrier
      _dashboardKey.currentState?.openCalendar();
    }
  }
  String _getObjectivesText(String languageCode) => '$_completedGoals/$_totalGoals ${'sport_objectives_text'.tr(languageCode)}';
  String _getStreakText(String languageCode) => '$_currentStreak ${'sport_days_text'.tr(languageCode)}';

  List<String> _getPageNames(String languageCode) => [
    'sport_dashboard_title'.tr(languageCode),
    'sport_cardio'.tr(languageCode),
    'sport_muscle_training'.tr(languageCode)
  ];
  final List<IconData> _pageIcons = [
    LucideIcons.activity,
    LucideIcons.activity,
    LucideIcons.dumbbell,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);

    // OPTIMISATION: Chargement instantané depuis GlobalStateManager
    _loadInitialDataSync();

    // Enrichissement en arrière-plan (non-bloquant)
    _loadObjectives();
    _loadStreak();

    // Forcer la mise à jour du compteur d'objectifs
    DashboardService.refreshGoalsNotifier();

    // Lancer le tutorial après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSportTutorial();
    });
  }

  /// Affiche l'écran de bienvenue Sport si c'est la première visite
  Future<void> _showSportTutorial() async {
    // Vérifier si déjà complété (en mode debug, toujours afficher)
    const debugMode = false; // Mode production : tutoriels une seule fois
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('sport_welcome_shown') ?? false;
      if (completed) {
        debugPrint('ℹ️ Welcome Sport déjà affiché');
        return;
      }
    }

    final locService = LocalizationService.instance;
    final globalState = GlobalStateManager.instance;

    // Afficher l'écran de bienvenue en PLEIN ÉCRAN (pas en dialog)
    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => SportTutorialWelcome(
          languageCode: locService.currentLanguageCode,
          userName: globalState.userName,
          onStart: () => Navigator.of(context).pop(true),
          onSkip: () => Navigator.of(context).pop(false),
        ),
      ),
    );

    // Marquer le welcome comme affiché
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sport_welcome_shown', true);
    }

    if (shouldContinue == true) {
      debugPrint('✅ Welcome Sport terminé - Lancement du tutorial Dashboard');

      // Lancer le tutorial du Dashboard APRÈS le welcome
      await _launchDashboardTutorial();
    } else {
      debugPrint('🔴 === BOUTON "PASSER" APPUYÉ - WELCOME SCREEN SPORT ===');
      // Marquer le tutoriel comme complété dans Supabase via TutorialService
      await TutorialService().markTutorialAsCompleted('tutorial_sport_completed');
      debugPrint('⏭️ Welcome Sport skippé');
    }
  }

  /// Lance le tutorial du Dashboard Sport en accédant au widget enfant
  Future<void> _launchDashboardTutorial() async {
    // Petit délai pour que le welcome screen se ferme complètement (même timing que Dashboard principal)
    await Future.delayed(const Duration(milliseconds: 300));

    // Appeler la méthode publique showDashboardTutorial() du Dashboard
    // En passant les GlobalKeys des onglets
    final dashboardState = _dashboardKey.currentState;
    if (dashboardState != null) {
      await dashboardState.showDashboardTutorial(
        dashboardTabKey: _dashboardTabKey,
        cardioTabKey: _cardioTabKey,
        musculationTabKey: _musculationTabKey,
      );
    } else {
      debugPrint('⚠️ Impossible d\'accéder au state du Dashboard Sport pour lancer le tutorial');
    }
  }

  /// Affiche l'écran de bienvenue Cardio si c'est la première visite
  Future<void> _showCardioTutorial() async {
    // Vérifier si déjà complété (en mode debug, toujours afficher)
    const debugMode = false; // Mode production : tutoriels une seule fois
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('cardio_welcome_shown') ?? false;
      if (completed) {
        debugPrint('ℹ️ Welcome Cardio déjà affiché');
        return;
      }
    }

    final locService = LocalizationService.instance;
    final globalState = GlobalStateManager.instance;

    // Afficher l'écran de bienvenue en PLEIN ÉCRAN (pas en dialog)
    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CardioTutorialWelcome(
          languageCode: locService.currentLanguageCode,
          userName: globalState.userName,
          onStart: () => Navigator.of(context).pop(true),
          onSkip: () => Navigator.of(context).pop(false),
        ),
      ),
    );

    // Marquer le welcome comme affiché
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cardio_welcome_shown', true);
    }

    if (shouldContinue == true) {
      debugPrint('✅ Welcome Cardio terminé - Lancement du tutorial');

      // Lancer le tutorial Cardio APRÈS le welcome
      await _launchCardioTutorial();
    } else {
      debugPrint('🔴 === BOUTON "PASSER" APPUYÉ - WELCOME SCREEN CARDIO ===');
      // Marquer le tutoriel comme complété dans Supabase via TutorialService
      await TutorialService().markTutorialAsCompleted('tutorial_cardio_completed');
      debugPrint('⏭️ Welcome Cardio skippé');
    }
  }

  /// Lance le tutorial Cardio sur la vraie page
  Future<void> _launchCardioTutorial() async {
    // Petit délai pour que le welcome screen se ferme complètement
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Naviguer vers la page Cardio (index 1)
    setState(() {
      _currentIndex = 1;
    });
    _pageController.jumpToPage(1);
    _tabController.animateTo(1);

    // Attendre que la page Cardio soit construite
    await Future.delayed(const Duration(milliseconds: 300));

    // Appeler la méthode du widget Cardio qui lance le tutorial sur la vraie page
    await _cardioKey.currentState?.showCardioTutorial();

    debugPrint('✅ Tutorial Cardio terminé');
  }

  /// Affiche l'écran de bienvenue Musculation si c'est la première visite
  Future<void> _showMusculationTutorial() async {
    // Vérifier si déjà complété (en mode debug, toujours afficher)
    const debugMode = false; // Mode production : tutoriels une seule fois
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('musculation_welcome_shown') ?? false;
      if (completed) {
        debugPrint('ℹ️ Welcome Musculation déjà affiché');
        return;
      }
    }

    final locService = LocalizationService.instance;
    final globalState = GlobalStateManager.instance;

    // Afficher l'écran de bienvenue en PLEIN ÉCRAN (pas en dialog)
    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MusculationTutorialWelcome(
          languageCode: locService.currentLanguageCode,
          userName: globalState.userName,
          onStart: () => Navigator.of(context).pop(true),
          onSkip: () => Navigator.of(context).pop(false),
        ),
      ),
    );

    // Marquer le welcome comme affiché
    if (!debugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('musculation_welcome_shown', true);
    }

    if (shouldContinue == true) {
      debugPrint('✅ Welcome Musculation terminé - Lancement du tutorial');

      // Lancer le tutorial Musculation APRÈS le welcome
      await _launchMusculationTutorial();
    } else {
      debugPrint('🔴 === BOUTON "PASSER" APPUYÉ - WELCOME SCREEN MUSCULATION ===');
      // Marquer le tutoriel comme complété dans Supabase via TutorialService
      await TutorialService().markTutorialAsCompleted('tutorial_musculation_completed');
      debugPrint('⏭️ Welcome Musculation skippé');
    }
  }

  /// Lance le tutorial Musculation sur la vraie page
  Future<void> _launchMusculationTutorial() async {
    // Petit délai pour que le welcome screen se ferme complètement
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Naviguer vers la page Musculation (index 2)
    setState(() {
      _currentIndex = 2;
    });
    _pageController.jumpToPage(2);
    _tabController.animateTo(2);

    // Attendre que la page Musculation soit construite
    await Future.delayed(const Duration(milliseconds: 300));

    // Appeler la méthode du widget Musculation qui lance le tutorial sur la vraie page
    await _musculationKey.currentState?.showMusculationTutorial();

    debugPrint('✅ Tutorial Musculation terminé');
  }

  /// NOUVEAU: Chargement synchrone instantané depuis GlobalStateManager
  void _loadInitialDataSync() {
    final globalState = GlobalStateManager.instance;

    setState(() {
      // Charger le streak depuis GlobalStateManager
      _currentStreak = globalState.currentStreak;

      // Calculer les objectifs complétés depuis GlobalStateManager
      final goals = globalState.getDailyGoalsForDashboard();
      _completedGoals = goals.where((g) => g['completed'] == true).length;
      _totalGoals = goals.length;
    });

    debugPrint('⚡ Sport header chargé INSTANTANÉMENT depuis GlobalStateManager:');
    debugPrint('   - Streak: $_currentStreak jours');
    debugPrint('   - Objectifs: $_completedGoals/$_totalGoals');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Rafraîchir le header quand on change de page
    _loadInitialDataSync();
    _loadObjectives();
    _loadStreak();

    setState(() {
      _currentIndex = index;
    });
    _tabController.animateTo(index);
  }

  void _onTabTapped(int index) {
    // Lancer le tutorial approprié si c'est la première visite de cet onglet
    // Cela évite les lancements multiples lors de swipe rapide
    if (index == 1 && !_cardioTutorialLaunched) {
      _cardioTutorialLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCardioTutorial();
      });
    } else if (index == 2 && !_musculationTutorialLaunched) {
      _musculationTutorialLaunched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMusculationTutorial();
      });
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onRefresh() async {
    try {
      // OPTIMISATION: Vider le cache rapide et le cache sport
      FastCacheService.invalidateDashboard();
      SportDashboardService.invalidateCache();
      
      // Recharger les données de la section sport en parallèle
      await Future.wait([
        _loadObjectives(),
        _loadStreak(),
        DashboardService.invalidateAndRefreshAfterWorkout(), // Refresh spécifique sport
        SportDashboardService.getDashboardData(), // Recharge les données sport
      ]);
      
      // Vider le cache et forcer le rafraîchissement
      HeaderCacheService.clearCache();
      DashboardService.refreshGoalsNotifier();
      
      // Feedback visuel
      if (mounted) {
        final locService = Provider.of<LocalizationService>(context, listen: false);
        CustomSnackbarService.showSuccess(
          context,
          locService.currentLanguageCode == 'fr' ? 'Données sportives mises à jour' : 'Sport data updated',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du sport: $e');
    }
  }

  Future<void> _loadObjectives() async {
    try {
      final goals = await DashboardService.getDailyGoals();
      final completed = goals.where((g) => g.completed).length;
      setState(() {
        _completedGoals = completed;
        _totalGoals = goals.length;
      });
    } catch (e) {
      // Erreur lors du chargement des objectifs, garder les valeurs de GlobalStateManager
      debugPrint('⚠️ Erreur chargement objectifs: $e');
    }
  }

  Future<void> _loadStreak() async {
    try {
      final streak = await StreakService.getCurrentStreak();
      setState(() {
        _currentStreak = streak;
      });
    } catch (e) {
      // Erreur lors du chargement du streak, garder la valeur de GlobalStateManager
      debugPrint('⚠️ Erreur chargement streak: $e');
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
                          SportDashboard(key: _dashboardKey, onOpenCalendar: _openSportCalendar),
                          SportCardioHybrid(key: _cardioKey, onOpenCalendar: _openSportCalendar),
                          SportMusculationHybrid(
                            key: _musculationKey,
                            onOpenCalendar: _openSportCalendar,
                          ),
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
                    : (index == 1 ? _cardioTabKey : _musculationTabKey);

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
                                    builder: (context, locService, _) => Text(
                                      _getPageNames(locService.currentLanguageCode)[index],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected 
                                            ? const Color(0xFF0B132B)
                                            : const Color(0xFF888888),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
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
