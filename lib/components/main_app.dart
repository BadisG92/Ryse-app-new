import 'package:flutter/material.dart';
import 'bottom_navigation.dart';
import 'main_dashboard_hybrid.dart';
import 'nutrition_section.dart';
import 'sport_section.dart';
import 'global_progress_hybrid.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _activeTab = 'home';

  void _onTabChange(String tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  Widget _renderContent() {
    switch (_activeTab) {
      case 'home':
        return const MainDashboardHybrid();
      case 'nutrition':
        return const NutritionSection();
      case 'sport':
        return const SportSection();
      case 'progress':
        return const GlobalProgress();
      default:
        return const MainDashboardHybrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavigation(
              activeTab: _activeTab,
              onTabChange: _onTabChange,
            ),
          ),
        ],
      ),
    );
  }
} 
