import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../design/design.dart';
import '../services/analytics_service.dart';
import '../services/app_navigator.dart';
import '../services/notification_service.dart';
import '../services/translations.dart';
import 'arc_grid.dart';
import 'arc_page.dart';
import 'arc_state.dart';
import 'arc_words.dart';
import 'winter_flame.dart';

/// La première rencontre avec le Winter Arc.
///
/// Une fois par compte, à la première ouverture pendant la saison. Refaite
/// après un conseil (texte, design, psychologie, voix de la tendance) :
/// une affiche plutôt qu'une feuille de réglages.
///
/// - En haut, la nuit : le panda en capuche dans sa vraie scène, bord à bord,
///   et le titre qui porte toute l'offre.
/// - En bas, la bande des 90 cases telle que l'accueil la montrera, avec les
///   jours déjà tenus en ambre : la preuve, plutôt qu'une phrase.
/// - Deux règles, pas trois. Les jokers sont annoncés avec leurs dates, pour
///   que personne ne croie en avoir un dès le départ.
/// - Un seul geste : maintenir pour tenir l'hiver. C'est aussi le seul moment
///   où demander les notifications a du sens.
Future<void> showArcIntro(BuildContext context, ArcState state, String lang, {bool alreadyCommitted = false}) async {
  RyzeFeedback.confirm();
  final committed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0B132B).withValues(alpha: 0.5),
    builder: (sheet) => ArcIntroSheet(
      state: state,
      lang: lang,
      onRules: () => showArcRules(context, lang),
      onCommitted: () => Navigator.of(sheet).pop(true),
      alreadyCommitted: alreadyCommitted,
    ),
  );
  if (committed != true) {
    AnalyticsService.logEvent('arc_intro_closed_unsigned', parameters: {'day': state.dayNumber});
    return;
  }
  // Hier encore rattrapable : on l'ouvre, c'est la série qui se joue.
  if (state.rescuable) AppNavigator().requestNutritionHistory();
}

/// Les quatre situations, dites chacune à sa façon.
enum ArcIntroCase { fresh, started, before, grace }

class ArcIntroSheet extends StatefulWidget {
  const ArcIntroSheet({
    super.key,
    required this.state,
    required this.lang,
    required this.onRules,
    required this.onCommitted,
    this.nudges = true,
    this.alreadyCommitted = false,
  });

  final ArcState state;
  final String lang;
  final VoidCallback onRules;
  final VoidCallback onCommitted;

  /// Les rappels du soir sont actifs : la légende sous le bouton peut les
  /// promettre.
  final bool nudges;

  /// Le pacte de l'onboarding vient d'être signé : pas de second geste à
  /// maintenir, un simple bouton.
  final bool alreadyCommitted;

  static ArcIntroCase caseOf(ArcState s) {
    if (s.rescuable) return ArcIntroCase.grace;
    if (s.streak > 0) return ArcIntroCase.started;
    if (s.best >= 2) return ArcIntroCase.before;
    return ArcIntroCase.fresh;
  }

  @override
  State<ArcIntroSheet> createState() => _ArcIntroSheetState();
}

class _ArcIntroSheetState extends State<ArcIntroSheet> with TickerProviderStateMixin {
  /// L'entrée orchestrée, en une seule horloge.
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

  /// Les cases déjà tenues qui s'allument une à une.
  late final AnimationController _lit = AnimationController(vsync: this);

  bool _committed = false;
  bool _burst = false;

  ArcState get s => widget.state;
  String get lang => widget.lang;

  /// Les cases acquises, sans la case d'aujourd'hui qui arrive à la fin.
  List<ArcCell> get _earned {
    final cells = s.cells;
    if (cells.isEmpty) return const [];
    return cells.last == ArcCell.pending ? cells.sublist(0, cells.length - 1) : cells;
  }

  @override
  void initState() {
    super.initState();
    final n = _earned.length;
    _lit.duration = Duration(milliseconds: n == 0 ? 1 : math.min(600, n * 45));
    _in.addStatusListener((status) {
      if (status == AnimationStatus.completed && n > 0 && !_lit.isAnimating && _lit.value == 0) {
        _lit.forward().whenComplete(() => RyzeFeedback.success());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _in.value = 1;
      _lit.value = 1;
    } else if (_in.value == 0 && !_in.isAnimating) {
      // La feuille monte d'abord ; l'entrée se joue quand elle est posée.
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _in.forward();
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _lit.dispose();
    super.dispose();
  }

  /// Un tap ailleurs que sur le bouton : on saute l'entrée.
  void _skip() {
    if (_in.isAnimating) _in.value = 1;
  }

  Future<void> _commit() async {
    setState(() {
      _committed = true;
      _burst = true;
    });
    RyzeFeedback.success();
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (uid != null) await prefs.setString('arc_pact_$uid', DateTime.now().toIso8601String());
    } catch (_) {}
    AnalyticsService.logEvent('arc_pact_signed', parameters: {
      'case': ArcIntroSheet.caseOf(s).name,
      'day': s.dayNumber,
      'source': widget.alreadyCommitted ? 'onboarding' : 'intro',
    });
    // Les notifications se demandent ici ou jamais : juste après s'être
    // engagé, la question a un sens. Une seule fois par installation.
    await NotificationService().requestAfterFirstEntry();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onCommitted();
  }

  static double _interval(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  String _status() {
    switch (ArcIntroSheet.caseOf(s)) {
      case ArcIntroCase.grace:
        final g = s.grace!;
        return 'arc_intro_status_grace'.tr(lang).replaceAll('{missing}', ArcWords.missing(meals: g.mealsMissing, waterMl: g.waterMissingMl, lang: lang));
      case ArcIntroCase.started:
        return 'arc_intro_status_started'.tr(lang).replaceAll('{n}', '${s.streak}').replaceAll('{days}', ArcWords.days(s.streak, lang));
      case ArcIntroCase.before:
        return 'arc_intro_status_before'.tr(lang).replaceAll('{n}', '${s.best}');
      case ArcIntroCase.fresh:
        final line = 'arc_intro_status_today'.tr(lang);
        // Décembre : la vraie date limite, pas une fausse urgence.
        final late = s.eligible && !s.today.isBefore(DateTime(2026, 12, 1));
        return late ? '$line ${'arc_intro_last_start'.tr(lang)}' : line;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.vw(5.1);
    final screen = MediaQuery.sizeOf(context);
    // La nuit est le seul bloc qui plie : sur un petit écran, c'est le torse
    // du panda qui se coupe, jamais son visage ni le bouton.
    final night = math.min(context.vw(105), math.max(260.0, screen.height * 0.92 - 350));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _skip,
      child: Container(
        constraints: BoxConstraints(maxHeight: screen.height * 0.92),
        decoration: BoxDecoration(
          color: RyzeColors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(RyzeRadius.lg)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: Listenable.merge([_in, _lit]),
              builder: (context, _) {
                final t = _in.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Night(height: night, t: t, lang: lang, title: (s.eligible ? 'arc_intro_title_prize' : 'arc_intro_title_plain').tr(lang)),
                    Padding(
                      padding: EdgeInsets.fromLTRB(gutter, context.vw(4.6), gutter, context.vw(2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _fade(t, 0.32, 0.5, _BandHeader(state: s, lang: lang)),
                          SizedBox(height: context.vw(2.3)),
                          _Band(earned: _earned, reveal: _interval(t, 0.37, 0.68, Curves.easeInOut), lit: _lit.value, done: t >= 1),
                          SizedBox(height: context.vw(2.6)),
                          _fade(
                            t,
                            0.68,
                            0.8,
                            Text(_status(), style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.accInk)),
                          ),
                          SizedBox(height: context.vw(4.1)),
                          _fade(t, 0.78, 0.92, _Rule(cell: ArcCell.held, text: 'arc_intro_rule_day2'.tr(lang))),
                          SizedBox(height: context.vw(2.3)),
                          _fade(t, 0.83, 0.97, _Rule(cell: ArcCell.joker, text: 'arc_intro_rule_net'.tr(lang))),
                          SizedBox(height: context.vw(4.6)),
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if (widget.alreadyCommitted)
                                OnbButton(label: 'arc_intro_go'.tr(lang), onPressed: _committed ? null : _commit)
                              else
                                HoldToSign(
                                  label: 'arc_intro_hold'.tr(lang),
                                  doneLabel: 'arc_intro_hold_done'.tr(lang),
                                  onDone: _commit,
                                ),
                              if (_burst) const Positioned.fill(child: SparkBurst()),
                            ],
                          ),
                          if (widget.nudges) ...[
                            SizedBox(height: context.vw(2)),
                            Text(
                              (_committed ? 'arc_intro_nudge_done' : 'arc_intro_nudge').tr(lang),
                              textAlign: TextAlign.center,
                              style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
                            ),
                          ],
                          Center(
                            child: Pressable(
                              onTap: widget.onRules,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: context.vw(2.6), horizontal: context.vw(4)),
                                child: Text('arc_rules_link'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.mute)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _fade(double t, double a, double b, Widget child) {
    final v = _interval(t, a, b, RyzeCurves.out);
    return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 6 * (1 - v)), child: child));
  }
}

/// La nuit : une illustration fixe, dans ses propres couleurs quelle que soit
/// la palette choisie (un panda sur fond rouge pour l'édition Cerise n'aurait
/// pas de sens).
class _Night extends StatelessWidget {
  const _Night({required this.height, required this.t, required this.lang, required this.title});

  static const Color _nightInk = Color(0xFF0B132B);

  final double height;
  final double t;
  final String lang;
  final String title;

  static double _i(double t, double a, double b, [Curve c = Curves.linear]) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final burns = 1.06 - 0.06 * _i(t, 0, 0.74, RyzeCurves.out);
    final veil = 0.45 * (1 - _i(t, 0, 0.37));
    final flame = _i(t, 0.06, 0.28, RyzeCurves.spring);
    final eyebrow = _i(t, 0.06, 0.28, RyzeCurves.out);
    final lines = title.split('\n');
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _nightInk),
          ClipRect(
            child: Transform.scale(
              scale: burns,
              alignment: const Alignment(0, -0.1),
              child: Image.asset(
                'assets/images/coach_ryze_winter_arc.webp',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          // Le bas se fond dans la nuit : la coupe tombe dans le calme.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_nightInk.withValues(alpha: 0), _nightInk.withValues(alpha: 0.6)],
                ),
              ),
            ),
          ),
          // Le panda sort du noir.
          IgnorePointer(child: ColoredBox(color: _nightInk.withValues(alpha: veil))),
          const _Snow(),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(RyzeRadius.pill)),
              ),
            ),
          ),
          Positioned(
            top: context.vw(6.2),
            left: 0,
            right: 0,
            child: Opacity(
              opacity: eyebrow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(scale: 0.3 + 0.7 * flame, alignment: Alignment.bottomCenter, child: WinterFlame(size: context.vw(6.2))),
                  SizedBox(width: context.vw(1.5)),
                  Text(
                    'arc_name'.tr(lang).toUpperCase(),
                    style: RyzeText.body(context, 3.1, weight: FontWeight.w700, color: ArcIce.midTop).copyWith(letterSpacing: context.vw(3.1) * 0.16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: context.vw(15.4),
            left: context.vw(5.1),
            right: context.vw(5.1),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  Builder(builder: (context) {
                    final start = 0.14 + i * 0.05;
                    final v = _i(t, start, start + 0.25, RyzeCurves.out);
                    return Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - v)),
                        child: Text(
                          lines[i],
                          textAlign: TextAlign.center,
                          style: RyzeText.display(context, RyzeText.headlineVw(title), color: Colors.white, height: 1.02),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Jour 6 » à gauche, « Jour 90 · 29 déc. » et le cadeau à droite : le
/// départ et l'arrivée de la bande.
class _BandHeader extends StatelessWidget {
  const _BandHeader({required this.state, required this.lang});
  final ArcState state;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final end = state.eligible
        ? 'arc_intro_day90'.tr(lang).replaceAll('{date}', ArcWords.shortDate(state.finishOn, lang))
        : 'arc_intro_day90'.tr(lang).split(' · ').first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'arc_day_of'.tr(lang).replaceAll('{n}', '${state.dayNumber}'),
          style: RyzeText.display(context, 5.6).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const Spacer(),
        Text(end, style: RyzeText.body(context, 3.4, weight: FontWeight.w700, color: RyzeColors.accInk)),
        if (state.eligible) ...[
          SizedBox(width: context.vw(1.5)),
          Icon(LucideIcons.gift, size: context.vw(4.4), color: RyzeColors.accInk),
        ],
      ],
    );
  }
}

/// La bande des 90, identique à celle de l'accueil. Elle apparaît sous un
/// front de givre qui la traverse, puis les jours déjà tenus s'allument un à
/// un, et la case d'aujourd'hui se pose à la fin.
class _Band extends StatelessWidget {
  const _Band({required this.earned, required this.reveal, required this.lit, required this.done});

  final List<ArcCell> earned;
  final double reveal;
  final double lit;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final shown = (earned.length * lit).round();
    final cells = <ArcCell>[
      ...earned.take(shown),
      if (done && shown == earned.length && earned.isNotEmpty) ArcCell.pending,
    ];
    final grid = ArcGrid(cells: cells, columns: 30, gapFraction: 0.32, todayFirst: done);
    if (reveal >= 1) return grid;
    // Le front : ce qui est à sa gauche est posé, ce qui est dessus brille de
    // givre, ce qui est à sa droite n'existe pas encore.
    final edge = -0.1 + reveal * 1.2;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (r) => LinearGradient(
        begin: const Alignment(-1, -0.35),
        end: const Alignment(1, 0.35),
        colors: [Colors.transparent, ArcIce.midTop.withValues(alpha: 0.75), Colors.transparent],
        stops: [(edge - 0.08).clamp(0.0, 1.0), edge.clamp(0.0, 1.0), (edge + 0.02).clamp(0.0, 1.0)],
      ).createShader(r),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          begin: const Alignment(-1, -0.35),
          end: const Alignment(1, 0.35),
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0, edge.clamp(0.0, 1.0), (edge + 0.04).clamp(0.0, 1.0)],
        ).createShader(r),
        child: grid,
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.cell, required this.text});
  final ArcCell cell;
  final String text;

  @override
  Widget build(BuildContext context) {
    final size = context.vw(3.6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.vw(0.6)),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cell == ArcCell.joker ? RyzeColors.accTint : RyzeColors.acc,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            child: cell == ArcCell.joker ? Icon(LucideIcons.snowflake, size: context.vw(2.2), color: RyzeColors.accInk) : null,
          ),
        ),
        SizedBox(width: context.vw(3.1)),
        Expanded(child: Text(text, style: RyzeText.body(context, 3.7, weight: FontWeight.w500, height: 1.36))),
      ],
    );
  }
}

/// La neige du premier plan : peu de flocons, de tailles franches, les plus
/// gros un peu flous. Le bokeh de l'image fait le lointain.
class _Snow extends StatefulWidget {
  const _Snow();

  @override
  State<_Snow> createState() => _SnowState();
}

class _SnowState extends State<_Snow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 10));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _SnowPainter(_c))));
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.time) : super(repaint: time);
  final Animation<double> time;

  static final List<(double, double, double, int)> _flakes = () {
    final r = math.Random(11);
    return [for (var i = 0; i < 24; i++) (r.nextDouble(), r.nextDouble(), 1 + r.nextDouble() * 2, 1 + r.nextInt(2))];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    for (var i = 0; i < _flakes.length; i++) {
      final (x0, y0, r, speed) = _flakes[i];
      final y = ((y0 + t * speed) % 1.0) * size.height;
      // Un peu de vent : tout dérive vers la droite en ondulant.
      final x = (x0 * size.width + t * speed * 18 + math.sin((t * speed + x0) * math.pi * 2) * 5) % size.width;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.4 * ((r - 1) / 2));
      if (r > 2.5) paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => false;
}
