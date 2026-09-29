import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../services/app_navigator.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import 'arc_grid.dart';
import 'arc_service.dart';
import 'arc_state.dart';
import 'arc_words.dart';
import 'winter_flame.dart';

/// Ouvre l'écran de l'arc par-dessus ce qui est affiché.
Future<void> openArcPage(BuildContext context) {
  RyzeFeedback.select();
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArcPage()));
}

/// L'écran du Winter Arc : les 90 carrés, ce qui manque aujourd'hui, les
/// jokers et le prix.
///
/// Une seule chose à lire, le jour où l'on en est ; une seule chose à faire,
/// ce qui manque pour tenir aujourd'hui.
class ArcPage extends StatefulWidget {
  const ArcPage({super.key});

  @override
  State<ArcPage> createState() => _ArcPageState();
}

class _ArcPageState extends State<ArcPage> {
  @override
  void initState() {
    super.initState();
    ArcService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: RyzeColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            const OnbBackground(scene: false),
            SafeArea(
              bottom: false,
              child: ListenableBuilder(
                listenable: ArcService.instance,
                builder: (context, _) {
                  final s = ArcService.instance.state;
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, 64),
                    children: [
                      _Header(lang: lang),
                      SizedBox(height: context.vw(5.1)),
                      if (s == null)
                        Padding(
                          padding: EdgeInsets.only(top: context.vw(20)),
                          child: Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
                        )
                      else
                        ArcPageBody(state: s, lang: lang),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Le corps de l'écran pour un état donné, sans rien demander à la base.
class ArcPageBody extends StatelessWidget {
  const ArcPageBody({super.key, required this.state, required this.lang});

  final ArcState state;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final gap = SizedBox(height: context.vw(4.6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopIn(dy: 8, child: _Headline(state: s, lang: lang)),
        gap,
        PopIn(
          delay: const Duration(milliseconds: 120),
          dy: 8,
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ArcGrid(cells: s.cells, todayFirst: !s.isSoon),
                SizedBox(height: context.vw(3.6)),
                _Legend(lang: lang),
              ],
            ),
          ),
        ),
        if (s.rescuable) ...[
          gap,
          PopIn(delay: const Duration(milliseconds: 200), dy: 8, child: _GraceCard(grace: s.grace!, lang: lang)),
        ],
        if (s.isOpen && s.todayStatus != null) ...[
          gap,
          PopIn(delay: const Duration(milliseconds: 240), dy: 8, child: _TodayCard(today: s.todayStatus!, lang: lang)),
        ],
        if (!s.isSoon) ...[
          gap,
          PopIn(delay: const Duration(milliseconds: 360), dy: 8, child: _Jokers(state: s, lang: lang)),
        ],
        gap,
        PopIn(delay: const Duration(milliseconds: 440), dy: 8, child: _Prize(lang: lang)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: context.vw(9.7),
            height: context.vw(9.7),
            decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
            child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
          ),
        ),
        SizedBox(width: context.vw(3.1)),
        WinterFlame(size: context.vw(5.6)),
        SizedBox(width: context.vw(1.5)),
        Text(
          'arc_name'.tr(lang).toUpperCase(),
          style: RyzeText.body(context, 3.4, weight: FontWeight.w700, color: ArcIce.pillInk).copyWith(letterSpacing: 1.4),
        ),
      ],
    );
  }
}

/// « Jour 34 sur 90 », et la phrase qui dit où l'on en est.
class _Headline extends StatelessWidget {
  const _Headline({required this.state, required this.lang});
  final ArcState state;
  final String lang;

  String _sub() {
    final s = state;
    if (s.isSoon) return 'arc_page_sub_soon'.tr(lang).replaceAll('{date}', ArcWords.date(ArcSeason.opens, lang));
    if (s.won) return 'arc_page_sub_won'.tr(lang);
    if (s.isEnded) return 'arc_page_sub_ended'.tr(lang);
    if (!s.eligible) return 'arc_page_sub_out'.tr(lang);
    if (s.streak == 0) return 'arc_page_sub_start'.tr(lang);
    final left = ArcSeason.length - s.streak;
    return 'arc_page_sub_run'
        .tr(lang)
        .replaceAll('{n}', '$left')
        .replaceAll('{days}', ArcWords.days(left, lang))
        .replaceAll('{date}', ArcWords.date(s.finishOn, lang));
  }

  @override
  Widget build(BuildContext context) {
    final number = state.won ? ArcSeason.length : (state.isSoon ? 0 : state.dayNumber);
    const tabular = [FontFeature.tabularFigures()];
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Une seule ligne qui rétrécit plutôt que de déborder : « Tag 34 von
        // 90 » sur un petit téléphone.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'arc_day_of'.tr(lang).replaceAll('{n}', '$number'),
                  style: RyzeText.display(context, 11.3).copyWith(fontFeatures: tabular),
                ),
                TextSpan(text: '  ${'arc_of_total'.tr(lang)}', style: RyzeText.display(context, 5.6, color: RyzeColors.mute2)),
              ],
            ),
            maxLines: 1,
          ),
        ),
        SizedBox(height: context.vw(2)),
        Text(_sub(), style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
      ],
    );
    // La flamme de la série, en grand, qui vit à côté du jour.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: text),
        SizedBox(width: context.vw(3.1)),
        WinterFlame(size: context.vw(18)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.vw(4.1)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    Widget item(Color fill, String key, {bool edge = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.vw(2.8),
              height: context.vw(2.8),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(3),
                border: edge ? Border.all(color: RyzeColors.ink, width: 1.2) : null,
              ),
            ),
            SizedBox(width: context.vw(1.3)),
            Text(key.tr(lang), style: RyzeText.body(context, 3.0, color: RyzeColors.mute)),
          ],
        );
    return Wrap(
      spacing: context.vw(3.6),
      runSpacing: context.vw(1.5),
      children: [
        item(RyzeColors.acc, 'arc_legend_held'),
        item(RyzeColors.accDeep, 'arc_legend_trained'),
        item(RyzeColors.accTint, 'arc_legend_joker'),
        item(RyzeColors.surf, 'arc_legend_today', edge: true),
      ],
    );
  }
}

/// Ce que la journée demande, coché au fur et à mesure.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today, required this.lang});
  final ArcToday today;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final water = 'arc_rule_water_count'
        .tr(lang)
        .replaceAll('{n}', ArcWords.litres(today.waterMl, lang))
        .replaceAll('{goal}', ArcWords.litres(today.waterGoalMl, lang));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('arc_today'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600))),
              if (today.held)
                Flexible(
                  child: Text(
                    'arc_card_held'.tr(lang),
                    textAlign: TextAlign.right,
                    style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.accInk),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.vw(3.1)),
          _Check(
            done: today.mealsMissing == 0,
            label: 'arc_rule_meals'.tr(lang),
            value: 'arc_rule_meals_count'.tr(lang).replaceAll('{n}', '${today.meals.clamp(0, ArcSeason.mealsNeeded)}'),
          ),
          SizedBox(height: context.vw(2.3)),
          _Check(done: today.waterMissingMl == 0, label: 'arc_rule_water'.tr(lang), value: water),
          SizedBox(height: context.vw(2.3)),
          _Check(done: today.trained, label: 'arc_rule_training'.tr(lang), value: 'arc_rule_training_hint'.tr(lang), bonus: true),
          if (today.mealsMissing > 0) ...[
            SizedBox(height: context.vw(4.1)),
            OnbButton(
              label: 'arc_log_meal'.tr(lang),
              ghost: true,
              onPressed: () {
                Navigator.of(context).pop();
                AppNavigator().requestTab('nutrition');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.label, required this.value, this.bonus = false});
  final bool done;
  final String label;
  final String value;
  final bool bonus;

  @override
  Widget build(BuildContext context) {
    final box = context.vw(5.6);
    return Row(
      children: [
        AnimatedContainer(
          duration: RyzeDurations.tap,
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: done ? RyzeColors.acc : RyzeColors.surf,
            borderRadius: BorderRadius.circular(box * 0.28),
            border: done ? null : Border.all(color: bonus ? RyzeColors.mute2 : RyzeColors.ink, width: 1.4),
          ),
          child: done ? Icon(Icons.check_rounded, size: box * 0.72, color: RyzeColors.onAcc) : null,
        ),
        SizedBox(width: context.vw(3.1)),
        Expanded(
          child: Text(label, style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: bonus ? RyzeColors.mute : RyzeColors.text)),
        ),
        SizedBox(width: context.vw(2)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: RyzeText.body(context, 3.2, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
  }
}

class _GraceCard extends StatelessWidget {
  const _GraceCard({required this.grace, required this.lang});
  final ArcGrace grace;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final missing = ArcWords.missing(meals: grace.mealsMissing, waterMl: grace.waterMissingMl, lang: lang);
    return Container(
      padding: EdgeInsets.all(context.vw(4.1)),
      decoration: BoxDecoration(color: RyzeColors.accTint, borderRadius: BorderRadius.circular(RyzeRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.clock, size: context.vw(4.6), color: RyzeColors.accInk),
              SizedBox(width: context.vw(3.1)),
              Expanded(
                child: Text(
                  'arc_grace_card'.tr(lang).replaceAll('{missing}', missing),
                  style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.accInk),
                ),
              ),
            ],
          ),
          SizedBox(height: context.vw(3.1)),
          // L'historique s'ouvre sur hier : repas et verres s'y ajoutent.
          OnbButton(
            label: 'arc_grace_cta'.tr(lang),
            onPressed: () {
              Navigator.of(context).pop();
              AppNavigator().requestNutritionHistory();
            },
          ),
        ],
      ),
    );
  }
}

class _Jokers extends StatelessWidget {
  const _Jokers({required this.state, required this.lang});
  final ArcState state;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('arc_jokers'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600))),
              for (var i = 0; i < 2; i++)
                Padding(
                  padding: EdgeInsets.only(left: context.vw(1.5)),
                  child: Container(
                    width: context.vw(7.2),
                    height: context.vw(7.2),
                    decoration: BoxDecoration(
                      color: i < state.jokers ? RyzeColors.accTint : RyzeColors.idle,
                      borderRadius: BorderRadius.circular(RyzeRadius.sm),
                    ),
                    child: Icon(LucideIcons.snowflake, size: context.vw(4.1), color: i < state.jokers ? RyzeColors.accInk : RyzeColors.mute2),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.vw(2)),
          Text('arc_jokers_hint'.tr(lang), style: RyzeText.body(context, 3.2, color: RyzeColors.mute)),
          if (state.best > 0) ...[
            SizedBox(height: context.vw(3.1)),
            Text(
              'arc_best'.tr(lang).replaceAll('{n}', '${state.best}').replaceAll('{days}', ArcWords.days(state.best, lang)),
              style: RyzeText.body(context, 3.4, weight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _Prize extends StatelessWidget {
  const _Prize({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.gift, size: context.vw(4.6), color: RyzeColors.accInk),
            SizedBox(width: context.vw(2.6)),
            Expanded(child: Text('arc_prize'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.accInk))),
          ],
        ),
        SizedBox(height: context.vw(2.6)),
        Pressable(
          onTap: () => showArcRules(context, lang),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(1.5)),
            child: Text(
              'arc_rules_link'.tr(lang),
              style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.ink).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }
}

/// Le règlement, dans une feuille. Apple demande qu'il soit dans l'app.
Future<void> showArcRules(BuildContext context, String lang) {
  const parts = ['who', 'day', 'streak', 'prize', 'fair', 'org'];
  return showRyzeSheet<void>(
    context,
    title: 'arc_rules_title'.tr(lang),
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in parts) ...[
          Text('arc_rules_${p}_t'.tr(lang), style: RyzeText.body(sheet, 3.9, weight: FontWeight.w600)),
          SizedBox(height: sheet.vw(1)),
          Text('arc_rules_${p}_b'.tr(lang), style: RyzeText.body(sheet, 3.5, color: RyzeColors.mute)),
          SizedBox(height: sheet.vw(4.1)),
        ],
      ],
    ),
  );
}
