import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'home', 'label': 'Accueil', 'icon': LucideIcons.home},
      {'id': 'nutrition', 'label': 'Nutrition', 'icon': LucideIcons.apple},
      {'id': 'sport', 'label': 'Sport', 'icon': LucideIcons.dumbbell},
      {'id': 'progress', 'label': 'Progrès', 'icon': LucideIcons.trendingUp},
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
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.map((tab) {
                final isActive = activeTab == tab['id'];
                
                return GestureDetector(
                  onTap: () => onTabChange(tab['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
  }
} 