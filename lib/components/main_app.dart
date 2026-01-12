import 'package:flutter/material.dart';
import 'bottom_navigation.dart';
import 'main_dashboard_hybrid.dart';
import 'nutrition_section.dart';
import 'sport_section.dart';
import 'global_progress_hybrid.dart';
import 'onboarding_gamified_hybrid.dart';
import '../screens/coach_chat_screen.dart';
import '../services/coach_chat_service.dart';
import '../services/weekly_bilan_service.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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
    _checkBilanAvailability();
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
        return MainDashboardHybrid(
          onTabChange: _onTabChange,
          nutritionTabKey: _nutritionTabKey,
          sportTabKey: _sportTabKey,
          progressTabKey: _progressTabKey,
          coachFabKey: _coachFabKey,
        );
      case 'nutrition':
        return const NutritionSection();
      case 'sport':
        return const SportSection();
      case 'progress':
        return const GlobalProgress();
      default:
        return MainDashboardHybrid(
          onTabChange: _onTabChange,
          nutritionTabKey: _nutritionTabKey,
          sportTabKey: _sportTabKey,
          progressTabKey: _progressTabKey,
          coachFabKey: _coachFabKey,
        );
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
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
              child: BottomNavigation(
                activeTab: _activeTab,
                onTabChange: _onTabChange,
                onCoachTap: _onCoachTap,
                nutritionTabKey: _nutritionTabKey,
                sportTabKey: _sportTabKey,
                progressTabKey: _progressTabKey,
                coachFabKey: _coachFabKey,
                showBilanBadge: _showBilanBadge,
              ),
            ),
        ],
      ),
    );
  }
} 
