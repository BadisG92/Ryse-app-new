import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/localization_service.dart';
import '../services/translations.dart';

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  // GlobalKeys pour le tutorial (optionnels)
  final GlobalKey? homeTabKey;
  final GlobalKey? nutritionTabKey;
  final GlobalKey? sportTabKey;
  final GlobalKey? progressTabKey;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    this.homeTabKey,
    this.nutritionTabKey,
    this.sportTabKey,
    this.progressTabKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        final tabs = [
          {'id': 'home', 'label': 'home_tab'.tr(locService.currentLanguageCode), 'icon': LucideIcons.house, 'key': homeTabKey},
          {'id': 'nutrition', 'label': 'nutrition_tab'.tr(locService.currentLanguageCode), 'icon': LucideIcons.apple, 'key': nutritionTabKey},
          {'id': 'sport', 'label': 'sport_tab'.tr(locService.currentLanguageCode), 'icon': LucideIcons.dumbbell, 'key': sportTabKey},
          {'id': 'progress', 'label': 'progress_tab'.tr(locService.currentLanguageCode), 'icon': LucideIcons.trendingUp, 'key': progressTabKey},
        ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.map((tab) {
                final isActive = activeTab == tab['id'];
                final tabKey = tab['key'] as GlobalKey?;

                return GestureDetector(
                  onTap: () => onTabChange(tab['id'] as String),
                  child: Container(
                    key: tabKey, // Attacher la GlobalKey ici
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0B132B),
                                Color(0xFF1C2951),
                              ],
                            )
                          : null,
                      color: isActive ? null : const Color(0xFFF1F5F9),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0B132B).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      tab['icon'] as IconData,
                      size: 24,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
      },
    );
  }
} 
