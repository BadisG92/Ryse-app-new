import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'motion.dart';
import 'tokens.dart';
import 'type.dart';
import '../onboarding/widgets/onb_widgets.dart';
import '../services/translations.dart';

/// The bar of the app: four tabs with no box around them, the active one in
/// ink with an amber dot under it, and in the middle the two coaches in a
/// paper pill — the door to the conversation. An amber dot on the pill says a
/// weekly review is waiting.
///
/// The pill rises above the bar, so it is laid out in a stack that is not
/// clipped: it is drawn whole, and taps land where it is drawn.
class RyzeNavBar extends StatelessWidget {
  const RyzeNavBar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.onCoachTap,
    required this.lang,
    this.showBadge = false,
    this.homeTabKey,
    this.nutritionTabKey,
    this.coachFabKey,
    this.sportTabKey,
    this.progressTabKey,
  });

  final String activeTab;
  final ValueChanged<String> onTabChange;
  final VoidCallback onCoachTap;
  final String lang;
  final bool showBadge;

  final GlobalKey? homeTabKey;
  final GlobalKey? nutritionTabKey;
  final GlobalKey? coachFabKey;
  final GlobalKey? sportTabKey;
  final GlobalKey? progressTabKey;

  /// How far the pill rises above the bar's top edge.
  static const double lift = 22;
  static const double pillWidth = 88;
  static const double pillHeight = 56;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final bottom = math.max(inset - 6, 10.0);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: lift),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: EdgeInsets.only(top: 8, bottom: bottom),
                decoration: BoxDecoration(
                  color: RyzeColors.surf.withValues(alpha: 0.86),
                  border: const Border(top: BorderSide(color: RyzeColors.line)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _Tab(id: 'home', label: 'nav_home'.tr(lang), icon: LucideIcons.house, active: activeTab == 'home', onTap: onTabChange, anchor: homeTabKey)),
                    Expanded(child: _Tab(id: 'nutrition', label: 'nutrition'.tr(lang), icon: LucideIcons.apple, active: activeTab == 'nutrition', onTap: onTabChange, anchor: nutritionTabKey)),
                    const SizedBox(width: pillWidth),
                    Expanded(child: _Tab(id: 'sport', label: 'sport'.tr(lang), icon: LucideIcons.dumbbell, active: activeTab == 'sport', onTap: onTabChange, anchor: sportTabKey)),
                    Expanded(child: _Tab(id: 'progress', label: 'progress'.tr(lang), icon: LucideIcons.trendingUp, active: activeTab == 'progress', onTap: onTabChange, anchor: progressTabKey)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: _CoachPill(key: coachFabKey, onTap: onCoachTap, badge: showBadge, label: 'nav_coaches'.tr(lang)),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.id, required this.label, required this.icon, required this.active, required this.onTap, this.anchor});
  final String id;
  final String label;
  final IconData icon;
  final bool active;
  final ValueChanged<String> onTap;
  final GlobalKey? anchor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(id),
        child: SizedBox(
          key: anchor,
          height: 46,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                duration: RyzeDurations.tap,
                curve: RyzeCurves.out,
                offset: Offset(0, active ? -0.04 : 0),
                child: Icon(icon, size: 24, color: active ? RyzeColors.ink : RyzeColors.mute),
              ),
              const SizedBox(height: 5),
              AnimatedScale(
                duration: RyzeDurations.enter,
                curve: RyzeCurves.spring,
                scale: active ? 1 : 0,
                child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two coaches side by side in a paper pill with an ink edge.
class _CoachPill extends StatelessWidget {
  const _CoachPill({super.key, required this.onTap, required this.badge, required this.label});
  final VoidCallback onTap;
  final bool badge;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: RyzeNavBar.pillWidth,
          height: RyzeNavBar.pillHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: RyzeNavBar.pillHeight,
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.pill),
                  border: Border.all(color: RyzeColors.ink, width: 1.5),
                  boxShadow: RyzeShadow.lift,
                ),
              ),
              // the two busts overlap by a third; on the widest phones they
              // outgrow the pill by a point, which is theirs to keep
              OverflowBox(
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoachAvatar(RyzeAssets.sportAvatar, sizeVw: 10.3),
                    Transform.translate(offset: Offset(-context.vw(3.1), 0), child: const CoachAvatar(RyzeAssets.nutriAvatar, sizeVw: 10.3)),
                  ],
                ),
              ),
              if (badge)
                Positioned(
                  top: 0,
                  right: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle, border: Border.all(color: RyzeColors.surf, width: 2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
