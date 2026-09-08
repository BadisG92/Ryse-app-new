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
/// ink and underlined by a short ink bar, and in the middle the two coaches in
/// a paper pill — the door to the conversation. An amber dot on the pill, and
/// only there, says a weekly review is waiting.
///
/// Ink for where you are, amber for what waits: two meanings, two colours, two
/// shapes. The active tab used to carry an amber dot too, which read as a
/// notification badge on the page you were already looking at.
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
                  border: Border(top: BorderSide(color: RyzeColors.line)),
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
              const SizedBox(height: 6),
              // La page ouverte est soulignée d'un trait d'encre. C'était un
              // point ambre, et un point ambre dans une barre d'onglets se lit
              // comme une pastille de notification — d'autant que la pilule
              // du coach en porte justement un, ambre lui aussi, pour dire
              // qu'un bilan attend. Deux sens pour un seul signe. Le trait
              // n'est ni rond ni ambre : il ne peut plus être confondu.
              AnimatedContainer(
                duration: RyzeDurations.enter,
                curve: RyzeCurves.spring,
                width: active ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: RyzeColors.ink,
                  borderRadius: BorderRadius.circular(1.5),
                ),
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
              // Les deux bustes se chevauchent d'un tiers. Le chevauchement se
              // fait par une translation, qui ne change pas la largeur que la
              // rangée déclare : centrée, elle plaçait donc son milieu de
              // calcul au centre de la pilule, et le dessin, plus étroit d'un
              // chevauchement, se retrouvait décalé vers la gauche de la
              // moitié de celui-ci. On rend cette moitié.
              OverflowBox(
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(context.vw(3.1) / 2, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoachAvatar(RyzeAssets.sportAvatar, sizeVw: 10.3),
                      Transform.translate(offset: Offset(-context.vw(3.1), 0), child: const CoachAvatar(RyzeAssets.nutriAvatar, sizeVw: 10.3)),
                    ],
                  ),
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
