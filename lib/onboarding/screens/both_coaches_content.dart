import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding_state.dart';
import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// "The same plan, with the pros": what the user's own plan would cost with a
/// personal trainer and a nutritionist, counted up live, against one year of
/// Ryze. One number, one ratio, one takeaway: the money that stays.
///
/// Reference prices are the low end of the French market (sessions 40–70 €,
/// consultations 50–80 €) so the comparison stays defensible.
class BothCoachesContent extends StatefulWidget {
  const BothCoachesContent({
    super.key,
    required this.s,
    required this.answers,
    required this.projection,
    required this.annualPrice,
    required this.annualPriceLabel,
  });

  final OnbStrings s;
  final OnbAnswers answers;

  /// Null when the user maintains their weight; the plan then defaults to 12 weeks.
  final OnbProjection? projection;

  /// Store price of the annual plan and its localized label ("69,99 €").
  final double annualPrice;
  final String annualPriceLabel;

  static const int pricePerSession = 50;
  static const int pricePerConsult = 60;
  static const int sessionsPerWeek = 2;

  @override
  State<BothCoachesContent> createState() => _BothCoachesContentState();
}

class _BothCoachesContentState extends State<BothCoachesContent> with SingleTickerProviderStateMixin {
  static const Color _accText = Color(0xFFA8690F);

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final Animation<double> _count = CurvedAnimation(parent: _c, curve: const Interval(0.10, 0.62, curve: Curves.easeOutCubic));
  late final Animation<double> _barHuman = CurvedAnimation(parent: _c, curve: const Interval(0.12, 0.62, curve: Curves.easeOutCubic));
  late final Animation<double> _barRyze = CurvedAnimation(parent: _c, curve: const Interval(0.60, 0.88, curve: Curves.easeOutCubic));
  late final Animation<double> _ratio = CurvedAnimation(parent: _c, curve: const Interval(0.86, 1.0, curve: Curves.easeOut));

  int get _weeks => (widget.projection?.weeks ?? 12).clamp(8, 26);
  int get _sessions => _weeks * BothCoachesContent.sessionsPerWeek;
  int get _consults => ((_weeks / 4).round() + 1).clamp(2, 8);
  int get _coach => _sessions * BothCoachesContent.pricePerSession;
  int get _nutri => _consults * BothCoachesContent.pricePerConsult;
  int get _human => _coach + _nutri;
  double get _ryzeShare => widget.annualPrice <= 0 ? 0.03 : (widget.annualPrice / _human).clamp(0.03, 1.0);
  int get _times => widget.annualPrice <= 0 ? 0 : (_human / widget.annualPrice).round();
  int get _keep => (_human - widget.annualPrice).round();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// "1 700 €" in French and German, "€1,700" in English.
  String _eur(num value) {
    final digits = value.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      // English groups with a comma, German with a full stop, French with a thin space
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(widget.s.lang == 'en' ? ',' : (widget.s.lang == 'de' ? '.' : ' '));
      buf.write(digits[i]);
    }
    return widget.s.lang == 'en' ? '€$buf' : '$buf €';
  }

  String _goalLabel() {
    final p = widget.projection;
    if (p == null || widget.answers.goal == 'maintain') return widget.s.t('both_goal_maintain');
    // kg or lb, like every other weight in the onboarding
    return '${p.deltaKg < 0 ? '−' : '+'}${OnbUnits.weight(p.deltaKg.abs().round(), widget.answers.isMetric)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final numberStyle = OnbText.display(context, 15, letterSpacingEm: -0.04, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // the cost of doing it with humans, counted up
        AnimatedBuilder(
          animation: _count,
          builder: (context, _) => Text(_eur(_human * _count.value), style: numberStyle, maxLines: 1, softWrap: false),
        ),
        SizedBox(height: context.vw(1.6)),
        Text(s.t('both_caption', {'n': '$_weeks', 'goal': _goalLabel()}), style: OnbText.body(context, 3.6, weight: FontWeight.w500, color: OnbColors.mute)),
        SizedBox(height: context.vh(2)),
        _Line(index: 0, icon: LucideIcons.dumbbell, text: s.t('both_line_coach', {'n': '$_sessions', 'p': '${BothCoachesContent.pricePerSession}'}), amount: _eur(_coach)),
        SizedBox(height: context.vw(2)),
        _Line(index: 1, icon: LucideIcons.apple, text: s.t('both_line_nutri', {'n': '$_consults', 'p': '${BothCoachesContent.pricePerConsult}'}), amount: _eur(_nutri)),
        SizedBox(height: context.vw(2)),
        _Line(index: 2, icon: LucideIcons.unlink, text: s.t('both_missing'), amount: '—', missing: true),
        SizedBox(height: context.vh(2.6)),
        // the ratio, physically
        _Bar(label: s.t('both_bar_human'), share: 1, color: OnbColors.ink, anim: _barHuman),
        SizedBox(height: context.vw(2.4)),
        _Bar(
          label: s.t('both_bar_ryze'),
          share: _ryzeShare,
          color: OnbColors.acc,
          anim: _barRyze,
          trailing: '${widget.annualPriceLabel} · ${s.t('both_ratio', {'x': '$_times'})}',
          trailingAnim: _ratio,
          trailingColor: _accText,
        ),
        SizedBox(height: context.vh(2.8)),
        // what stays in the pocket
        PopIn(
          delay: const Duration(milliseconds: 2050),
          dy: 12,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.vw(4.4), vertical: context.vw(4)),
            decoration: BoxDecoration(
              color: OnbColors.ink,
              borderRadius: BorderRadius.circular(context.vw(4.6)),
              boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.32), blurRadius: context.vw(6), offset: Offset(0, context.vw(2.4)))],
            ),
            child: Row(
              children: [
                Text(_eur(_keep), style: OnbText.display(context, 8.2, color: OnbColors.acc, letterSpacingEm: -0.035, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                SizedBox(width: context.vw(3.6)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('both_keep'), style: OnbText.body(context, 3.8, weight: FontWeight.w700, color: Colors.white, height: 1.2)),
                      SizedBox(height: context.vw(0.8)),
                      Text(s.t('both_keep_sub'), style: OnbText.body(context, 3.2, color: Colors.white.withValues(alpha: 0.72), height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.vh(2.2)),
        for (final (i, key) in ['both_tick_talk', 'both_tick_247', 'both_tick_after'].indexed) ...[
          if (i > 0) SizedBox(height: context.vw(2.2)),
          PopIn(
            delay: Duration(milliseconds: 2300 + i * 110),
            dy: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.vw(6),
                  height: context.vw(6),
                  margin: EdgeInsets.only(top: context.vw(0.2)),
                  decoration: BoxDecoration(color: OnbColors.ink, borderRadius: BorderRadius.circular(context.vw(2))),
                  child: Icon(LucideIcons.check, size: context.vw(3.4), color: Colors.white),
                ),
                SizedBox(width: context.vw(3)),
                Expanded(child: Text(s.t(key), style: OnbText.body(context, 3.6, weight: FontWeight.w500, color: OnbColors.ink, height: 1.35))),
              ],
            ),
          ),
        ],
        SizedBox(height: context.vh(2)),
        PopIn(
          delay: const Duration(milliseconds: 2700),
          child: Text(s.t('both_note'), style: OnbText.body(context, 2.9, color: OnbColors.mute2, height: 1.35)),
        ),
      ],
    );
  }
}

/// One cost line: icon tile, what it is, what it costs. `missing` is what the
/// human setup does not include.
class _Line extends StatelessWidget {
  const _Line({required this.index, required this.icon, required this.text, required this.amount, this.missing = false});
  final int index;
  final IconData icon;
  final String text;
  final String amount;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final fg = missing ? OnbColors.mute2 : OnbColors.ink;
    return PopIn(
      delay: Duration(milliseconds: 520 + index * 110),
      dy: 8,
      child: Row(
        children: [
          Container(
            width: context.vw(8),
            height: context.vw(8),
            decoration: BoxDecoration(color: OnbColors.paper2, borderRadius: BorderRadius.circular(context.vw(2.6))),
            child: Icon(icon, size: context.vw(4), color: fg),
          ),
          SizedBox(width: context.vw(3)),
          Expanded(child: Text(text, style: OnbText.body(context, 3.5, weight: FontWeight.w500, color: OnbColors.mute, height: 1.25))),
          SizedBox(width: context.vw(2)),
          Text(amount, style: OnbText.display(context, 3.9, color: fg, letterSpacingEm: -0.02, height: 1.1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// Label + horizontal bar that grows to `share` of the track, with an optional
/// value written right after the bar.
class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.share, required this.color, required this.anim, this.trailing, this.trailingAnim, this.trailingColor});
  final String label;
  final double share;
  final Color color;
  final Animation<double> anim;
  final String? trailing;
  final Animation<double>? trailingAnim;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final h = context.vw(5.6);
    return Row(
      children: [
        SizedBox(width: context.vw(22), child: Text(label, style: OnbText.body(context, 3.3, weight: FontWeight.w600, color: OnbColors.ink, height: 1.2))),
        SizedBox(width: context.vw(2.4)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: h,
              child: Stack(
                children: [
                  Container(decoration: BoxDecoration(color: OnbColors.paper2, borderRadius: BorderRadius.circular(context.vw(1.8)))),
                  AnimatedBuilder(
                    animation: anim,
                    builder: (context, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (share * anim.value).clamp(0.0, 1.0),
                        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(context.vw(1.8)))),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Positioned(
                      left: constraints.maxWidth * share + context.vw(2),
                      top: 0,
                      bottom: 0,
                      child: FadeTransition(
                        opacity: trailingAnim ?? const AlwaysStoppedAnimation(1),
                        child: Center(
                          child: Text(trailing!,
                              maxLines: 1,
                              softWrap: false,
                              style: OnbText.display(context, 3.3, color: trailingColor ?? OnbColors.ink, weight: FontWeight.w700, letterSpacingEm: -0.01, height: 1)
                                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
