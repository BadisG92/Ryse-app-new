import 'package:flutter/material.dart';
import 'bottom_navigation.dart';
import 'main_dashboard_hybrid.dart';
import 'nutrition_section.dart';
import 'sport_section.dart';
import 'global_progress_hybrid.dart';
import 'onboarding_gamified_hybrid.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _activeTab = 'home';

  // GlobalKeys pour le tutorial (partagées entre Dashboard et BottomNavigation)
  final GlobalKey _nutritionTabKey = GlobalKey();
  final GlobalKey _sportTabKey = GlobalKey();
  final GlobalKey _progressTabKey = GlobalKey();

  void _onTabChange(String tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  Widget _renderContent() {
    switch (_activeTab) {
      case 'home':
        return MainDashboardHybrid(
          onTabChange: _onTabChange,
          nutritionTabKey: _nutritionTabKey,
          sportTabKey: _sportTabKey,
          progressTabKey: _progressTabKey,
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
                nutritionTabKey: _nutritionTabKey,
                sportTabKey: _sportTabKey,
                progressTabKey: _progressTabKey,
              ),
            ),
        ],
      ),
    );
  }
} 
