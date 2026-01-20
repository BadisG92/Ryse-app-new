import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/localization_service.dart';
import '../services/translations.dart';

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;
  final VoidCallback? onCoachTap;

  // GlobalKeys pour le tutorial (optionnels)
  final GlobalKey? homeTabKey;
  final GlobalKey? nutritionTabKey;
  final GlobalKey? coachFabKey;
  final GlobalKey? sportTabKey;
  final GlobalKey? progressTabKey;

  // Badge de notification pour le bilan hebdomadaire
  final bool showBilanBadge;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    this.onCoachTap,
    this.homeTabKey,
    this.nutritionTabKey,
    this.coachFabKey,
    this.sportTabKey,
    this.progressTabKey,
    this.showBilanBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        // Left tabs (Home, Nutrition)
        final leftTabs = [
          {'id': 'home', 'icon': LucideIcons.house, 'key': homeTabKey},
          {'id': 'nutrition', 'icon': LucideIcons.apple, 'key': nutritionTabKey},
        ];

        // Right tabs (Sport, Progress)
        final rightTabs = [
          {'id': 'sport', 'icon': LucideIcons.dumbbell, 'key': sportTabKey},
          {'id': 'progress', 'icon': LucideIcons.trendingUp, 'key': progressTabKey},
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
              children: [
                // Left tabs
                ...leftTabs.map((tab) => _buildTab(tab, activeTab == tab['id'])),

                // Center FAB - Coach Ryze
                _buildCoachFab(),

                // Right tabs
                ...rightTabs.map((tab) => _buildTab(tab, activeTab == tab['id'])),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildTab(Map<String, dynamic> tab, bool isActive) {
    final tabKey = tab['key'] as GlobalKey?;

    return GestureDetector(
      onTap: () => onTabChange(tab['id'] as String),
      child: Container(
        key: tabKey,
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
  }

  Widget _buildCoachFab() {
    return Transform.translate(
      offset: const Offset(0, -12), // Raise the FAB higher
      child: GestureDetector(
        key: coachFabKey,
        onTap: onCoachTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B132B),
                    Color(0xFF1C2951),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/logo_seul.svg',
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => const Icon(
                    LucideIcons.messageCircle,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Badge de notification rouge style iOS
            if (showBilanBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30), // Rouge iOS
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
