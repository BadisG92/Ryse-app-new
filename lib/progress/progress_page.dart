import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../components/ui/global_progress_models.dart';
import '../design/design.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/unit_service.dart';
import '../settings/settings_page.dart';
import 'progress_data.dart';
import 'sheets/weight_entry_sheet.dart';
import 'widgets/weight_chart.dart';

/// L'onglet Progression : est-ce que ça marche ?
///
/// Une seule question, donc un seul chiffre en tête — le poids — et la courbe
/// qui dit dans quel sens il va. Dessous, ce que ça a coûté cette semaine :
/// sept jours, chacun avec son anneau. Puis la série.
///
/// L'ancienne page empilait quatre cartes qui se répétaient : le bilan
/// hebdomadaire disait « objectif calorique 5/7 j » et la grille de suivi
/// redisait les mêmes sept jours juste dessous. Ici les jours portent le
/// détail et la ligne au-dessus n'en donne que le total.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with GlobalStateListener {
  /// L'entrée ne se joue qu'une fois par lancement.
  static bool _revealed = false;

  ProgressSnapshot _data = ProgressSnapshot.empty;
  bool _loaded = false;

  /// La fenêtre de la courbe. L'ancienne page dédiée au poids offrait
  /// les mêmes trois périodes ; elle disparaît, pas la fonction.
  static const List<String> _periodKeys = ['this_month', 'three_months', 'six_months'];
  static const List<int> _periodDays = [31, 92, 183];
  int _period = 1;
  late final bool _first;
  late bool _shown;

  @override
  void initState() {
    super.initState();
    _first = !_revealed;
    _revealed = true;
    _shown = !_first;
    _load();
    if (_first) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 240), () {
          if (mounted) setState(() => _shown = true);
        });
      });
    }
  }

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    switch (event.type) {
      case ChangeType.calories:
      case ChangeType.workout:
      case ChangeType.sport:
      case ChangeType.water:
      case ChangeType.streak:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _load();
      default:
        break;
    }
  }

  Future<void> _load() async {
    final data = await ProgressData.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loaded = true;
    });
  }

  String get _lang => LocalizationService.instance.currentLanguageCode;

  Future<void> _logWeight() async {
    final ok = await WeightEntrySheet.show(context, lang: _lang, currentKg: _data.weight?.currentWeight ?? 0);
    if (ok) _load();
  }

  Future<void> _openSettings() async {
    RyzeFeedback.tap();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animate = _first && !reduce;
    final shown = _shown || reduce;
    final gutter = context.vw(5.1);
    final w = _data.weight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: RyzeColors.ink,
              backgroundColor: RyzeColors.surf,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, 128),
                children: [
                  PopIn(
                    delay: const Duration(milliseconds: 40),
                    dy: 8,
                    animate: animate,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('progress_title'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                        ),
                        if (_data.streak > 0) _StreakPill(lang: lang, streak: _data.streak),
                        SizedBox(width: context.vw(2.1)),
                        Semantics(
                          label: 'settings'.tr(lang),
                          button: true,
                          child: Pressable(
                            onTap: _openSettings,
                            child: Container(
                              width: context.vw(9.7),
                              height: context.vw(9.7),
                              decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
                              child: Icon(LucideIcons.settings, size: context.vw(4.6), color: RyzeColors.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.vw(5.1)),
                  PopIn(
                    delay: const Duration(milliseconds: 160),
                    dy: 8,
                    animate: animate,
                    child: _weight(context, lang, w, shown, animate),
                  ),
                  SizedBox(height: context.vw(7)),
                  PopIn(
                    delay: const Duration(milliseconds: 460),
                    dy: 8,
                    animate: animate,
                    child: _week(context, lang),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ le poids

  Widget _weight(BuildContext context, String lang, WeightProgress? w, bool shown, bool animate) {
    final units = UnitService.instance;
    final numbers = NumberFormat('0.#', lang);

    if (w == null || w.entries.isEmpty) {
      return _Empty(lang: lang, loaded: _loaded, onTap: _logWeight);
    }

    final current = units.displayWeight(w.currentWeight);
    final total = w.totalWeightChange;
    final trend = WeightTrend.of(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('progress_weight_now'.tr(lang), style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
        SizedBox(height: context.vw(0.5)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RollingNumber(
              shown ? numbers.format(current) : '0',
              style: RyzeText.display(context, 13, weight: FontWeight.w600).copyWith(height: 1),
            ),
            SizedBox(width: context.vw(2.1)),
            Padding(
              padding: EdgeInsets.only(bottom: context.vw(1.5)),
              child: Text(units.weightUnit, style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
            ),
          ],
        ),
        SizedBox(height: context.vw(1)),
        Text(
          [
            if (total.abs() >= 0.05)
              'progress_since_start'.tr(lang)
                  .replaceAll('{n}', '${total > 0 ? '+' : '−'}${numbers.format(units.displayWeight(total.abs()))} ${units.weightUnit}'),
            if (w.targetWeight > 0)
              'progress_target'.tr(lang).replaceAll('{n}', '${numbers.format(units.displayWeight(w.targetWeight))} ${units.weightUnit}'),
          ].join(' · '),
          style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        SizedBox(height: context.vw(4.1)),
        RyzeSegmented(
          labels: [for (final k in _periodKeys) k.tr(lang)],
          index: _period,
          onChanged: (i) => setState(() => _period = i),
        ),
        SizedBox(height: context.vw(3.1)),
        WeightChart(progress: _windowed(w), animate: animate),
        SizedBox(height: context.vw(3.6)),
        // La projection n'apparaît que si les pesées la permettent : quatre
        // points sur deux semaines au moins, et une tendance qui va vers la
        // cible. Sinon rien — une date sortie de trois pesées serait un
        // mensonge poli.
        if (trend != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.trendingUp, size: context.vw(4.6), color: RyzeColors.accInk),
                SizedBox(width: context.vw(3.1)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('progress_at_this_pace'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                      Text(
                        'progress_eta'.tr(lang)
                            .replaceAll('{w}', '${numbers.format(units.displayWeight(w.targetWeight))} ${units.weightUnit}')
                            .replaceAll('{d}', RyzeDates.full(trend.eta, lang)),
                        style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
                      ),
                      Text(
                        'progress_pace'.tr(lang).replaceAll(
                              '{n}',
                              '${trend.kgPerWeek > 0 ? '+' : '−'}${numbers.format(units.displayWeight(trend.kgPerWeek.abs()))} ${units.weightUnit}',
                            ),
                        style: RyzeText.body(context, 2.9, color: RyzeColors.mute2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.vw(3.1)),
        ],
        SizedBox(
          width: double.infinity,
          child: Pressable(
            onTap: _logWeight,
            child: Container(
              height: context.vw(12.3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                border: Border.all(color: RyzeColors.idle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, size: context.vw(4.1), color: RyzeColors.ink),
                  SizedBox(width: context.vw(1.5)),
                  Text('progress_log_weight'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Les pesées de la période choisie, l'objectif et les repères gardés.
  /// En dessous de deux points la fenêtre ne dit rien : on rend tout.
  WeightProgress _windowed(WeightProgress w) {
    final from = DateTime.now().subtract(Duration(days: _periodDays[_period]));
    final kept = w.entries.where((e) => !e.date.isBefore(from)).toList();
    if (kept.length < 2) return w;
    return WeightProgress(
      currentWeight: w.currentWeight,
      previousWeight: w.previousWeight,
      initialWeight: w.initialWeight,
      targetWeight: w.targetWeight,
      entries: kept,
    );
  }

  // ----------------------------------------------------------- la semaine

  Widget _week(BuildContext context, String lang) {
    final days = _data.days;
    final parts = <String>[
      if (_data.calorieDays > 0) 'progress_days_on_target'.tr(lang).replaceAll('{n}', '${_data.calorieDays}'),
      if (_data.sessions > 0)
        _data.sportGoal != null
            ? 'sport_goal_progress'.tr(lang).replaceAll('{done}', '${_data.sessions}').replaceAll('{goal}', '${_data.sportGoal}')
            : 'sport_sessions_n'.tr(lang).replaceAll('{n}', '${_data.sessions}'),
      if (_data.waterDays > 0) 'progress_days_hydrated'.tr(lang).replaceAll('{n}', '${_data.waterDays}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('progress_this_week'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
        SizedBox(height: context.vw(3.6)),
        if (days.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(3)),
            child: Text(
              _loaded ? 'progress_week_empty'.tr(lang) : '',
              style: RyzeText.body(context, 3.4, color: RyzeColors.mute),
            ),
          )
        else ...[
          Row(
            children: [
              for (final d in days) Expanded(child: _Day(lang: lang, day: d)),
            ],
          ),
          SizedBox(height: context.vw(3.1)),
          if (parts.isNotEmpty)
            Text(
              parts.join(' · '),
              style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          SizedBox(height: context.vw(3.6)),
          const _Legend(),
        ],
      ],
    );
  }
}

/// Un jour : l'anneau nutrition rempli selon le score, un point ambre dessous
/// quand il y a eu du sport. Deux faits, une seule colonne.
class _Day extends StatelessWidget {
  const _Day({required this.lang, required this.day});

  final String lang;
  final TrackingDay day;

  @override
  Widget build(BuildContext context) {
    final size = context.vw(8.7);
    final now = DateTime.now();
    final isToday = day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
    final future = day.date.isAfter(DateTime(now.year, now.month, now.day));
    final sport = day.sportActivities.isNotEmpty;

    final Color fill;
    final Color edge;
    switch (day.nutritionScore) {
      case TrackingScore.achieved:
        fill = RyzeColors.ink;
        edge = RyzeColors.ink;
      case TrackingScore.partial:
        fill = RyzeColors.surf;
        edge = RyzeColors.ink;
      case TrackingScore.missed:
        fill = future ? Colors.transparent : RyzeColors.surf;
        edge = future ? RyzeColors.idle : RyzeColors.line;
    }

    return Column(
      children: [
        Container(
          width: size + 8,
          height: size + 8,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: RyzeColors.ink, width: 1.4) : null,
          ),
          child: AnimatedContainer(
            duration: RyzeDurations.fill,
            curve: RyzeCurves.out,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: edge, width: day.nutritionScore == TrackingScore.partial ? 2 : 1),
            ),
          ),
        ),
        SizedBox(height: context.vw(1)),
        SizedBox(
          height: 6,
          child: sport
              ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle))
              : null,
        ),
        SizedBox(height: context.vw(1)),
        Text(
          RyzeDates.short(day.date, lang).substring(0, 1),
          style: RyzeText.body(context, 2.9, weight: FontWeight.w600, color: isToday ? RyzeColors.ink : RyzeColors.mute2),
        ),
      ],
    );
  }
}

/// Ce que les deux marques veulent dire. Sans elle, un anneau plein et un
/// anneau bordé se ressemblent assez pour qu'on ne les distingue pas.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;
    return Wrap(
      spacing: context.vw(4.1),
      runSpacing: context.vw(1.5),
      children: [
        _LegendItem(
          mark: Container(width: 10, height: 10, decoration: const BoxDecoration(color: RyzeColors.ink, shape: BoxShape.circle)),
          label: 'progress_legend_hit'.tr(lang),
        ),
        _LegendItem(
          mark: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.ink, width: 2)),
          ),
          label: 'progress_legend_partial'.tr(lang),
        ),
        _LegendItem(
          mark: Container(width: 8, height: 8, decoration: const BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle)),
          label: 'progress_legend_sport'.tr(lang),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.mark, required this.label});

  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: context.vw(1.5)),
        Text(label, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.lang, required this.streak});

  final String lang;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final unit = (streak == 1 ? 'day' : 'days').tr(lang);
    return Container(
      padding: EdgeInsets.fromLTRB(context.vw(2.3), context.vw(1.5), context.vw(2.8), context.vw(1.5)),
      decoration: BoxDecoration(color: RyzeColors.accTint, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.flame, size: 14, color: RyzeColors.accInk),
          SizedBox(width: context.vw(1.2)),
          Text(
            '$streak $unit',
            style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.accInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// Aucune pesée : la page n'a rien à tracer, elle le dit et propose la seule
/// action qui la remplira.
class _Empty extends StatelessWidget {
  const _Empty({required this.lang, required this.loaded, required this.onTap});

  final String lang;
  final bool loaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(12)),
        child: const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
      );
    }
    return Container(
      padding: EdgeInsets.all(context.vw(4.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('progress_no_weight'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
          SizedBox(height: context.vw(1)),
          Text('progress_no_weight_hint'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.4)),
          SizedBox(height: context.vw(4.1)),
          Pressable(
            onTap: onTap,
            child: Container(
              height: context.vw(12.3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: RyzeColors.ink,
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                boxShadow: RyzeShadow.soft,
              ),
              child: Text('progress_log_weight'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
            ),
          ),
        ],
      ),
    );
  }
}
