import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_page.dart';
import '../services/localization_service.dart';
import '../nutrition/nutrition_page.dart';
import '../sport/sport_page.dart';
import '../progress/progress_page.dart';
import '../screens/coach_chat_screen.dart';
import '../services/coach_chat_service.dart';
import '../services/weekly_bilan_service.dart';
import '../design/design.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/workout_session_store.dart';
import '../services/app_navigator.dart';
import '../sport/session/session_models.dart';
import '../sport/session/session_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  String _activeTab = 'home';
  bool _showBilanBadge = false;

  // GlobalKeys pour le tutorial (partagées entre Dashboard et BottomNavigation)
  final GlobalKey _nutritionTabKey = GlobalKey();
  final GlobalKey _sportTabKey = GlobalKey();
  final GlobalKey _progressTabKey = GlobalKey();
  final GlobalKey _coachFabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppNavigator().requestedTab.addListener(_onRequestedTab);
    _checkBilanAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerResume();
      // a widget may have asked for a tab before the bar existed
      _onRequestedTab();
    });
  }

  @override
  void dispose() {
    AppNavigator().requestedTab.removeListener(_onRequestedTab);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Un widget ou un lien demande un onglet : la barre y va et efface la
  /// demande, pour qu'elle ne rejoue pas à la prochaine reconstruction.
  void _onRequestedTab() {
    final tab = AppNavigator().requestedTab.value;
    if (tab == null) return;
    AppNavigator().requestedTab.value = null;
    if (!mounted || tab == _activeTab) return;
    setState(() => _activeTab = tab);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Une séance gardée sur le téléphone repart dès que l'app revient.
    if (state == AppLifecycleState.resumed) {
      WorkoutSessionStore.instance.syncPending();
    }
  }

  /// Une séance de musculation interrompue (app tuée, téléphone éteint)
  /// est proposée une fois au lancement. Refuser n'est pas un cul-de-sac :
  /// la carte « Séance de {jour} en cours » de l'onglet Sport la garde.
  Future<void> _offerResume() async {
    final draft = await WorkoutSessionStore.instance.loadDraft();
    if (draft == null || !mounted) return;
    final LiveSession live;
    try {
      live = LiveSession.fromJson(draft.session);
    } catch (_) {
      await WorkoutSessionStore.instance.clearDraft();
      return;
    }
    final lang = LocalizationService.instance.currentLanguageCode;
    if (!mounted) return;
    final resume = await showRyzeSheet<bool>(
      context,
      title: 'session_resume_title'.tr(lang).replaceAll('{day}', RyzeDates.full(live.startedAt, lang)),
      subtitle: "${live.name} · ${'session_sets_progress'.tr(lang).replaceAll('{done}', '${live.doneSets}').replaceAll('{total}', '${live.totalSets}')}",
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(
            first: true,
            icon: Icons.play_arrow_rounded,
            label: 'session_resume'.tr(lang),
            onTap: () => Navigator.pop(sheet, true),
          ),
          RyzeSheetRow(
            icon: Icons.delete_outline_rounded,
            label: 'session_abandon'.tr(lang),
            danger: true,
            onTap: () => Navigator.pop(sheet, false),
          ),
        ],
      ),
    );
    if (!mounted || resume == null) return;
    if (!resume) {
      await WorkoutSessionStore.instance.clearDraft();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(sessionName: live.name, exercises: const [], draft: draft),
      ),
    );
  }

  Future<void> _checkBilanAvailability() async {
    final shouldShow = await WeeklyBilanService.instance.shouldShowBilanBanner();
    if (mounted && shouldShow != _showBilanBadge) {
      setState(() => _showBilanBadge = shouldShow);
    }
  }

  void _onTabChange(String tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  void _onCoachTap() async {
    // Get or create the single conversation
    await CoachChatService.instance.initialize();
    final conversation = await CoachChatService.instance.getOrCreateConversation();

    if (conversation != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CoachChatScreen(conversation: conversation),
        ),
      );
      // Re-vérifier la disponibilité du bilan après retour du chat
      // (le bilan peut avoir été lancé dans le chat)
      _checkBilanAvailability();
    }
  }

  Widget _renderContent() {
    switch (_activeTab) {
      case 'home':
        return HomePage(onTabChange: _onTabChange);
      case 'nutrition':
        return const NutritionPage();
      case 'sport':
        return const SportPage();
      case 'progress':
        return const ProgressPage();
      default:
        return HomePage(onTabChange: _onTabChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Masquer la barre de navigation quand le clavier est visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  RyzeColors.paper0,
                  RyzeColors.paper2,
                ],
              ),
            ),
          ),
          _renderContent(),
          // Masquer la barre de navigation quand le clavier est ouvert
          if (!isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Consumer<LocalizationService>(
                builder: (context, loc, _) => RyzeNavBar(
                  activeTab: _activeTab,
                  onTabChange: _onTabChange,
                  onCoachTap: _onCoachTap,
                  lang: loc.currentLanguageCode,
                  nutritionTabKey: _nutritionTabKey,
                  sportTabKey: _sportTabKey,
                  progressTabKey: _progressTabKey,
                  coachFabKey: _coachFabKey,
                  showBadge: _showBilanBadge,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
