import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// A personal trainer and a nutritionist, at the same time: the price
/// comparison and the one-sentence argument.
class BothCoachesContent extends StatelessWidget {
  const BothCoachesContent({super.key, required this.s, required this.monthlyEquivalent});
  final OnbStrings s;

  /// e.g. "5,83 €", derived from the annual price when the store answered.
  final String monthlyEquivalent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
            index: 0,
            icon: LucideIcons.dumbbell,
            title: s.t('both_coach'),
            sub: s.t('both_coach_sub'),
            price: s.t('both_coach_price'),
            unit: s.t('both_coach_unit')),
        SizedBox(height: context.vw(1.8)),
        _Row(
            index: 1,
            icon: LucideIcons.heart,
            title: s.t('both_nutri'),
            sub: s.t('both_nutri_sub'),
            price: s.t('both_nutri_price'),
            unit: s.t('both_nutri_unit')),
        SizedBox(height: context.vw(1.8)),
        _Row(
            index: 2,
            icon: LucideIcons.sparkles,
            title: s.t('both_ryze'),
            sub: s.t('both_ryze_sub'),
            price: monthlyEquivalent,
            unit: s.t('both_ryze_unit'),
            hero: true),
        SizedBox(height: context.vw(2.4)),
        Text(s.t('both_note'), textAlign: TextAlign.center, style: OnbText.body(context, 2.9, color: OnbColors.mute2)),
        SizedBox(height: context.vh(2)),
        PopIn(
          delay: const Duration(milliseconds: 700),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.vw(1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('both_why1'), style: OnbText.body(context, 3.9, color: OnbColors.mute, height: 1.5)),
                SizedBox(height: context.vh(1.2)),
                Text(s.t('both_why2'), style: OnbText.display(context, 5, height: 1.15, letterSpacingEm: -0.02)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, required this.icon, required this.title, required this.sub, required this.price, required this.unit, this.hero = false});
  final int index;
  final IconData icon;
  final String title;
  final String sub;
  final String price;
  final String unit;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final fg = hero ? Colors.white : OnbColors.ink;
    final muted = hero ? Colors.white.withValues(alpha: 0.65) : OnbColors.mute;
    return PopIn(
      delay: Duration(milliseconds: 300 + index * 90),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4), vertical: context.vw(3.4)),
        decoration: BoxDecoration(
          color: hero ? OnbColors.ink : OnbColors.surf,
          borderRadius: BorderRadius.circular(context.vw(4)),
          border: Border.all(color: hero ? OnbColors.ink : OnbColors.line),
          boxShadow: hero ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.5), blurRadius: context.vw(4), offset: Offset(0, context.vw(1.6)))] : null,
        ),
        child: Row(
          children: [
            Container(
              width: context.vw(9),
              height: context.vw(9),
              decoration:
                  BoxDecoration(color: hero ? Colors.white.withValues(alpha: 0.14) : OnbColors.paper2, borderRadius: BorderRadius.circular(context.vw(2.8))),
              child: Icon(icon, size: context.vw(4.4), color: fg),
            ),
            SizedBox(width: context.vw(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OnbText.body(context, 3.8, weight: FontWeight.w600, color: fg, height: 1.2)),
                  SizedBox(height: context.vw(0.3)),
                  Text(sub, style: OnbText.body(context, 3, color: muted, height: 1.2)),
                ],
              ),
            ),
            SizedBox(width: context.vw(2)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: OnbText.display(context, 4.4, color: fg, letterSpacingEm: -0.02, height: 1.1)),
                Text(unit, style: OnbText.body(context, 2.8, weight: FontWeight.w500, color: muted, height: 1.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
