import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/weekly_planner_models.dart';
import '../services/coach_personality_service.dart';
import '../services/analytics_service.dart';
import '../services/haptic_service.dart';
import '../services/revenuecat_service.dart';
import '../services/translations.dart';
import '../services/unified_subscription_service.dart';
import 'onboarding_repository.dart';
import 'onboarding_state.dart';
import 'onboarding_strings.dart';
import 'onboarding_theme.dart';
import 'screens/answers_content.dart';
import 'screens/both_coaches_content.dart';
import 'screens/hello_content.dart';
import 'screens/onboarding_paywall_screen.dart';
import 'screens/pact_content.dart';
import 'screens/planner_demo_step.dart';
import 'widgets/chapter_card.dart';
import 'widgets/choices.dart';
import 'widgets/onb_widgets.dart';
import 'widgets/pickers.dart';
import 'widgets/projection_chart.dart';

enum OnbMode {
  /// New user: the whole flow, ending on the hard paywall.
  full,

  /// Legacy user already onboarded without the coach part: tone, day, pact.
  coachOnly,
}

class _Step {
  const _Step(this.id, {this.chapter = 0, this.card = false, this.bare = false, this.coach, this.skip});
  final String id;
  final int chapter;
  final bool card;
  final bool bare;
  final OnbCoach? coach;
  final bool Function(OnbAnswers a)? skip;
}

/// The v2 onboarding: one conversation with Coach Ryze, four chapters,
/// the real planner in demo mode, the pact, then the paywall.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.mode = OnbMode.full, required this.onComplete, this.firstName, this.resume});

  final OnbMode mode;

  /// Called once everything is persisted (after purchase in `full` mode).
  final Future<void> Function() onComplete;
  final String? firstName;
  final ({String step, OnbAnswers answers})? resume;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  OnbStrings get s => OnbStrings.current();
  final OnboardingRepository _repo = OnboardingRepository();

  late OnbAnswers a;
  late final TextEditingController _motivationCtrl;
  late final List<_Step> _steps;
  bool _finishing = false;
  int _idx = 0;
  int _visit = 0;
  final List<int> _history = [];

  bool _profileSaved = false;
  bool _signed = false;
  final List<PendingMeal> _demoMeals = [];
  final List<PendingWorkout> _demoWorkouts = [];
  final List<PendingSession> _demoSessions = [];

  String? get _name {
    final n = (widget.firstName ?? '').trim();
    return n.isEmpty ? null : n;
  }

  @override
  void initState() {
    super.initState();
    a = widget.resume?.answers ?? OnbAnswers();
    _motivationCtrl = TextEditingController(text: a.motivationText);
    _loadAnnualPrice();
    _steps = widget.mode == OnbMode.coachOnly
        ? const [
            _Step('ch4', card: true),
            _Step('personality', chapter: 4, coach: OnbCoach.sport),
            _Step('bilan', chapter: 4, coach: OnbCoach.nutri),
            _Step('pact', chapter: 4),
          ]
        : [
            const _Step('hello'),
            const _Step('ch1', card: true),
            const _Step('goal', chapter: 1, coach: OnbCoach.sport),
            const _Step('gender', chapter: 1, coach: OnbCoach.nutri),
            const _Step('age', chapter: 1, coach: OnbCoach.nutri),
            const _Step('height', chapter: 1, coach: OnbCoach.nutri),
            const _Step('weight', chapter: 1, coach: OnbCoach.nutri),
            _Step('target', chapter: 1, coach: OnbCoach.nutri, skip: (a) => !a.hasTarget),
            const _Step('activity', chapter: 1, coach: OnbCoach.sport),
            _Step('projection', chapter: 1, coach: OnbCoach.duo, skip: (a) => !a.hasTarget || a.targetKg == a.weightKg),
            const _Step('diet', chapter: 1, coach: OnbCoach.nutri),
            const _Step('ch2', card: true),
            const _Step('motivation', chapter: 2, coach: OnbCoach.sport),
            const _Step('obstacles', chapter: 2, coach: OnbCoach.nutri),
            const _Step('answers', chapter: 2, coach: OnbCoach.duo),
            const _Step('ch3', card: true),
            const _Step('planner', chapter: 3, bare: true),
            const _Step('ch4', card: true),
            const _Step('personality', chapter: 4, coach: OnbCoach.sport),
            const _Step('bilan', chapter: 4, coach: OnbCoach.nutri),
            const _Step('both', chapter: 4, coach: OnbCoach.duo),
            const _Step('pact', chapter: 4),
            const _Step('offer', bare: true),
          ];

    if (a.restrictions.isEmpty) a.restrictions = ['classic'.tr(s.lang)];

    final resumeStep = widget.resume?.step;
    if (resumeStep != null) {
      var i = _steps.indexWhere((st) => st.id == resumeStep);
      if (i >= 0) {
        if (_steps[i].card && i + 1 < _steps.length) i++;
        _idx = i;
        // a resumed run must still be able to walk back through its answers;
        // without this the history is empty and the back button does nothing
        _history.addAll(_visible.where((v) => v < i));
      }
      OnbProgressStore.isProfileSaved().then((v) {
        if (mounted) setState(() => _profileSaved = v);
      });
    }
    _onEnter(_steps[_idx]);
  }

  // ---------------------------------------------------------------- navigation

  List<int> get _visible => [
        for (var i = 0; i < _steps.length; i++)
          if (!(_steps[i].skip?.call(a) ?? false)) i
      ];

  void _go(int index) {
    final step = _steps[index];
    setState(() {
      _idx = index;
      _visit++;
    });
    AnalyticsService.logEvent('onb_step_view', parameters: {
      'step_id': step.id,
      'chapter': step.chapter,
      'mode': widget.mode == OnbMode.full ? 'full' : 'coach_only',
      'resumed': widget.resume != null ? 1 : 0,
    });
    _onEnter(step);
    if (!step.card) OnbProgressStore.save(step.id, a);
  }

  void _next() {
    final vis = _visible;
    final pos = vis.indexOf(_idx);
    if (pos < 0 || pos >= vis.length - 1) {
      _finish();
      return;
    }
    _history.add(_idx);
    _go(vis[pos + 1]);
  }

  bool get _canGoBack => _history.any((h) => !_steps[h].card && !(_steps[h].id == 'planner' && _demoPlanSaved));

  void _back() {
    while (_history.isNotEmpty) {
      final p = _history.removeLast();
      if (_steps[p].id == 'planner' && _demoPlanSaved) continue;
      if (!_steps[p].card) {
        _go(p);
        return;
      }
    }
  }

  /// Lets the ink wipe of the chosen card finish (480 ms) and hold a beat before the page turns.
  void _autoNext() => Future.delayed(const Duration(milliseconds: 780), () {
        if (mounted) _next();
      });

  /// Annual plan price for the "both coaches" comparison. Falls back to the
  /// list price when the store has not answered.
  double _annualPrice = 69.99;
  String? _annualPriceLabel; // null until the store answers; the dictionary fallback is used meanwhile

  Future<void> _loadAnnualPrice() async {
    if (widget.mode == OnbMode.coachOnly) return;
    try {
      await UnifiedSubscriptionService().initialize();
      final packages = await RevenueCatService().getAvailablePackages();
      for (final p in packages) {
        final id = p.identifier.toLowerCase();
        if (id.contains('annual') || id.contains('yearly')) {
          if (!mounted) return;
          setState(() {
            _annualPrice = p.storeProduct.price;
            _annualPriceLabel = p.storeProduct.priceString;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Onboarding annual price: $e');
    }
  }

  Future<void> _onEnter(_Step step) async {
    if (step.id == 'planner') {
      // a fresh demo run: coming back through the planner must not stack the plan twice
      _demoMeals.clear();
      _demoWorkouts.clear();
      _demoSessions.clear();
      await _ensureProfileSaved();
    }
  }

  /// Profile goes to the database before the planner demo, like the legacy
  /// results screen did, so the planner can use the real targets.
  Future<void> _ensureProfileSaved() async {
    if (_profileSaved) return;
    try {
      await _repo.saveProfile(a);
      await _repo.saveCoachInsights(a, s);
      _profileSaved = true;
      AnalyticsService.logEvent('onb_profile_saved');
    } catch (e) {
      debugPrint('⚠️ Onboarding: profile save failed, continuing: $e');
      AnalyticsService.logEvent('onb_profile_save_failed', parameters: {'error': e.toString().substring(0, e.toString().length.clamp(0, 90))});
    }
  }

  /// The demo plan goes to the database when the user leaves the planner, not
  /// at the purchase: closing the app on the paywall is the most common moment
  /// of hesitation, and coming back to an empty week is the worst answer to it.
  /// The hard paywall still guards the app itself.
  bool _demoPlanSaved = false;

  Future<void> _persistDemoPlan() async {
    if (_demoPlanSaved || widget.mode != OnbMode.full) return;
    if (_demoMeals.isEmpty && _demoWorkouts.isEmpty && _demoSessions.isEmpty) return;
    // the planner screen already wrote each confirmation as it happened, so
    // the coach could modify, move or delete during the demo; writing the
    // lists again here would double every row
    _demoPlanSaved = true;
    AnalyticsService.logEvent('onb_demo_plan_saved', parameters: {'success': 1});
  }

  Future<void> _onPactSigned() async {
    setState(() => _signed = true);
    AnalyticsService.logEvent('onb_pact_signed', parameters: {'bilan_day': a.bilanDay ?? 0, 'personality': a.personality ?? ''});
    if (a.bilanDay != null) await _repo.saveBilanDay(a.bilanDay!);
    if (a.personality != null) await _repo.savePersonality(a.personality!);
    if (widget.mode == OnbMode.coachOnly) {
      await _repo.saveCoachInsights(a, s);
    }
  }

  @override
  void dispose() {
    _motivationCtrl.dispose();
    super.dispose();
  }

  /// End of the flow: after purchase (full) or after the pact (coachOnly).
  /// Guarded: a purchase and a restore could both resolve.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    var demoSaved = true;
    if (widget.mode == OnbMode.full) {
      await _ensureProfileSaved();
      if (!_profileSaved) {
        // the purchase went through, the profile did not: never open an empty account
        _finishing = false;
        if (mounted) _askRetry();
        return;
      }
      await _persistDemoPlan();
      demoSaved = _demoPlanSaved || (_demoMeals.isEmpty && _demoWorkouts.isEmpty && _demoSessions.isEmpty);
      if (!demoSaved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('demo_partial_save')), duration: const Duration(seconds: 3)));
      }
    }
    final synced = await _repo.markCompleted();
    AnalyticsService.logEvent('onb_completed', parameters: {
      'mode': widget.mode == OnbMode.full ? 'full' : 'coach_only',
      'demo_plan_saved': demoSaved ? 1 : 0,
      'server_synced': synced ? 1 : 0,
    });
    await widget.onComplete();
  }

  void _askRetry() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('profile_save_failed_title')),
        content: Text(s.t('profile_save_failed')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finish();
            },
            child: Text(s.t('retry')),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- questions

  String _question(String id) {
    switch (id) {
      case 'goal':
        return s.t('q_goal');
      case 'gender':
        return s.t('q_gender');
      case 'age':
        return s.t('q_age');
      case 'height':
        return s.t('q_height');
      case 'weight':
        return s.t('q_weight');
      case 'target':
        return s.t('q_target');
      case 'projection':
        return s.t('q_projection');
      case 'activity':
        return s.t('q_activity');
      case 'diet':
        return s.t('q_diet');
      case 'motivation':
        return s.t('q_motivation');
      case 'obstacles':
        return s.t('q_obstacles');
      case 'answers':
        return s.t('answers_title');
      case 'both':
        return s.t('both_title');
      case 'personality':
        return s.t('q_personality');
      case 'bilan':
        return s.t('q_bilan');
      case 'pact':
        return s.t('pact_title');
      case 'hello':
        return _name == null ? s.t('hello_title_anon') : s.t('hello_title', {'n': _name!});
      default:
        return '';
    }
  }

  String? _react(String id) {
    switch (id) {
      case 'gender':
        return a.goal == null ? null : s.t('react_${a.goal}');
      case 'motivation':
        return s.t('react_motivation');
      case 'obstacles':
        return a.motivation == null ? null : s.t('react_${a.motivation}');
      default:
        return null;
    }
  }

  String? _answer(String id) {
    switch (id) {
      case 'goal':
        return a.goal == null ? null : s.t('goal_${a.goal}');
      case 'gender':
        return a.gender == null ? null : s.t(a.gender == 'Homme' ? 'gender_m' : 'gender_f');
      case 'age':
        return '${a.age} ${s.t('unit_years')}';
      case 'height':
        return OnbUnits.height(a.heightCm, a.isMetric);
      case 'weight':
        return OnbUnits.weight(a.weightKg, a.isMetric, decimal: _decimal);
      case 'target':
        return OnbUnits.weight(a.targetKg, a.isMetric, decimal: _decimal);
      case 'activity':
        return a.activity == null ? null : s.t('act_${a.activity}');
      case 'diet':
        return a.restrictions.join(', ');
      case 'motivation':
        return a.motivation == null ? null : s.t(a.motivation!);
      case 'obstacles':
        return a.obstacles.map((o) => s.t(o)).join(', ');
      case 'personality':
        return a.personality == null ? null : CoachPersonalityService.getLocalizedLabel(_personalityType(a.personality!), s.lang);
      case 'bilan':
        return a.bilanDay == null ? null : s.dayFull[a.bilanDay! - 1];
      default:
        return null;
    }
  }

  /// "−8 kg d'ici le 12 nov., avec les deux coachs." Nine questions come back
  /// as one sentence at the moment the user decides.
  String get _decimal => s.lang == 'en' ? '.' : ',';

  String? _pactGoal() {
    final p = OnbMetabolics.projection(a, s.lang);
    if (p == null) return null;
    return s.t('pact_goal', {'target': OnbUnits.weight(a.targetKg, a.isMetric, decimal: _decimal), 'date': p.label});
  }

  String? _goalLine() {
    final p = OnbMetabolics.projection(a, s.lang);
    if (p == null) return null;
    final delta = '${p.deltaKg < 0 ? '−' : '+'}${OnbUnits.weight(p.deltaKg.abs(), a.isMetric, decimal: _decimal)}';
    return s.t('offer_goal', {'goal': delta, 'date': p.label, 'day': _dayName(a.bilanDay ?? 7)});
  }

  /// Only French writes a weekday in lower case mid-sentence.
  String _dayName(int day) {
    final name = s.dayFull[day - 1];
    return s.lang == 'fr' ? name.toLowerCase() : name;
  }

  CoachPersonalityType _personalityType(String key) =>
      CoachPersonalityType.values.firstWhere((t) => t.name == key, orElse: () => CoachPersonalityType.friendly);

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final step = _steps[_idx];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // light ground → dark status bar icons
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: OnbColors.paper,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: OnbBackground()),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: OnbCurves.out,
              switchOutCurve: OnbCurves.snap,
              layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey('${step.id}-$_visit');
                final slide = Tween<Offset>(begin: Offset(0, incoming ? 0.03 : -0.03), end: Offset.zero).animate(anim);
                return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
              },
              child: KeyedSubtree(key: ValueKey('${step.id}-$_visit'), child: _buildStep(step)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_Step step) {
    if (step.card) {
      final n = step.id.substring(2);
      return ChapterCard(number: '0$n', title: s.t('ch${n}_title'), subtitle: s.t('ch${n}_sub'), onDone: _next);
    }
    switch (step.id) {
      case 'planner':
        return _plannerStep(step);
      case 'offer':
        return _offerStep();
      default:
        return _questionStep(step);
    }
  }

  // ---------------------------------------------------------------- shell

  List<double> _fills(_Step step) {
    final vis = _visible;
    final chapters = <int>{
      for (final i in vis)
        if (_steps[i].chapter > 0) _steps[i].chapter
    }.toList()
      ..sort();
    return [
      for (final ch in chapters)
        () {
          final ids = vis.where((i) => _steps[i].chapter == ch).toList();
          if (ids.isEmpty) return 0.0;
          if (step.chapter == ch) return (ids.indexOf(_idx) + 0.5) / ids.length;
          return step.chapter > ch || (step.chapter == 0 && _idx > ids.last) ? 1.0 : 0.0;
        }(),
    ];
  }

  String _chapterLabel(_Step step) {
    if (step.chapter == 0) return '';
    final ids = _visible.where((i) => _steps[i].chapter == step.chapter).toList();
    return '${s.t('ch${step.chapter}_title')}  ${ids.indexOf(_idx) + 1}/${ids.length}';
  }

  _Step? _previousAnswered(_Step step) {
    for (var i = _history.length - 1; i >= 0; i--) {
      final p = _steps[_history[i]];
      if (p.card) continue;
      if (p.chapter != step.chapter) return null;
      return _answer(p.id) == null ? null : p;
    }
    return null;
  }

  Widget _shell(
    _Step step, {
    required Widget body,
    Widget? cta,
    Widget? foot,
    bool centerBody = true,
    bool showPast = true,
  }) {
    final prev = showPast ? _previousAnswered(step) : null;
    final react = _react(step.id);
    final headline = _question(step.id);
    final canBack = _canGoBack && step.id != 'hello';
    final chapterCount = _fills(step).length;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.vw(6), context.vh(1.6), context.vw(6), context.vh(2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnbTopBar(
              fills: _fills(step),
              chapter: step.chapter,
              label: _chapterLabel(step),
              onBack: canBack ? _back : null,
              showProgress: step.chapter > 0 && chapterCount > 0,
            ),
            SizedBox(height: context.vh(2)),
            if (step.coach != null) ...[
              PopIn(
                  delay: const Duration(milliseconds: 50),
                  dy: 10,
                  child: SpeakerRow(coach: step.coach!, name: s.t('coach_name'), role: s.t(step.coach == OnbCoach.sport ? 'coach_sport' : 'coach_nutri'))),
              SizedBox(height: context.vh(1.8)),
            ],
            if (prev != null) ...[
              PopIn(dy: 10, child: PastExchange(question: _question(prev.id), answer: _answer(prev.id)!)),
              SizedBox(height: context.vh(1.8)),
            ],
            if (react != null) ...[
              PopIn(dy: 6, child: Text(react, style: OnbText.body(context, 3.9, weight: FontWeight.w500, color: OnbColors.mute, height: 1.35))),
              SizedBox(height: context.vh(1)),
            ],
            WipeText(headline, style: OnbText.display(context, headline.length <= 30 ? 7.8 : (headline.length <= 46 ? 6.9 : 6.1))),
            if (step.id == 'hello') ...[
              SizedBox(height: context.vh(1.4)),
              PopIn(
                  delay: const Duration(milliseconds: 500),
                  dy: 8,
                  child: Text(s.t('hello_sub'), style: OnbText.body(context, 3.9, color: OnbColors.mute, height: 1.45))),
            ],
            SizedBox(height: context.vh(2)),
            Expanded(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.94, 1]).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: context.vh(3)),
                    child: ConstrainedBox(
                      // keyboard open → maxHeight can drop below the padding; never go negative
                      constraints: BoxConstraints(minHeight: (constraints.maxHeight - context.vh(3)).clamp(0.0, double.infinity)),
                      child: Column(
                        mainAxisAlignment: centerBody ? MainAxisAlignment.center : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [body],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (cta != null) ...[SizedBox(height: context.vh(1.4)), PopIn(delay: const Duration(milliseconds: 460), child: cta)],
            if (foot != null) ...[SizedBox(height: context.vh(1)), foot],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- steps

  Widget _questionStep(_Step step) {
    switch (step.id) {
      case 'hello':
        return _shell(step, body: HelloContent(s: s), cta: OnbButton(label: s.t('hello_cta'), onPressed: _next));

      case 'goal':
        return _shell(
          step,
          body: Column(
            children: [
              for (final (i, g) in [('lose', LucideIcons.flame), ('gain', LucideIcons.dumbbell), ('maintain', LucideIcons.heart)].indexed) ...[
                if (i > 0) SizedBox(height: context.vw(2.2)),
                OnbOptionCard(
                  index: i,
                  icon: g.$2,
                  title: s.t('goal_${g.$1}'),
                  subtitle: s.t('goal_${g.$1}_sub'),
                  selected: a.goal == g.$1,
                  onTap: () {
                    setState(() => a.goal = g.$1);
                    _autoNext();
                  },
                ),
              ],
            ],
          ),
        );

      case 'gender':
        return _shell(
          step,
          body: Row(
            children: [
              Expanded(
                  child: OnbOptionCard(
                      index: 0,
                      title: s.t('gender_m'),
                      selected: a.gender == 'Homme',
                      onTap: () {
                        setState(() => a.gender = 'Homme');
                        _autoNext();
                      })),
              SizedBox(width: context.vw(2.2)),
              Expanded(
                  child: OnbOptionCard(
                      index: 1,
                      title: s.t('gender_f'),
                      selected: a.gender == 'Femme',
                      onTap: () {
                        setState(() {
                          a.gender = 'Femme';
                          a.applyFemaleDefaults();
                        });
                        _autoNext();
                      })),
            ],
          ),
        );

      case 'age':
        return _shell(
          step,
          body: OnbWheelPicker(min: 13, max: 90, value: a.age, unit: s.t('unit_years'), onChanged: (v) => a.age = v),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'height':
        return _shell(
          step,
          body: OnbRulerPicker(
            isHeight: true,
            minMetric: 130,
            maxMetric: 220,
            valueMetric: a.heightCm.toDouble(),
            isMetric: a.isMetric,
            decimal: _decimal,
            onChanged: (v) => setState(() {
              a.heightCm = v.round();
              a.markBodyTouched();
            }),
            onUnitChanged: (m) => setState(() => a.isMetric = m),
            footer: Text(s.t('ruler_hint'), textAlign: TextAlign.center, style: OnbText.body(context, 3.7, color: OnbColors.mute)),
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'weight':
        return _shell(
          step,
          body: OnbRulerPicker(
            isHeight: false,
            minMetric: 35,
            maxMetric: 200,
            valueMetric: a.weightKg,
            isMetric: a.isMetric,
            decimal: _decimal,
            onChanged: (v) => setState(() {
              a.weightKg = v;
              a.markBodyTouched();
            }),
            onUnitChanged: (m) => setState(() => a.isMetric = m),
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'target':
        if (a.goal == 'lose' && a.targetKg >= a.weightKg) a.targetKg = (a.weightKg - 8).clamp(35.0, 200.0);
        if (a.goal == 'gain' && a.targetKg <= a.weightKg) a.targetKg = (a.weightKg + 6).clamp(35.0, 200.0);
        final delta = a.targetKg - a.weightKg;
        final rate = a.goal == 'lose' ? 0.6 : 0.3;
        final weeks = (delta.abs() / rate).ceil();
        final shownDelta = OnbUnits.weight(delta.abs(), a.isMetric, decimal: _decimal);
        return _shell(
          step,
          body: OnbRulerPicker(
            isHeight: false,
            minMetric: 35,
            maxMetric: 200,
            valueMetric: a.targetKg,
            isMetric: a.isMetric,
            decimal: _decimal,
            onChanged: (v) => setState(() => a.targetKg = v),
            onUnitChanged: (m) => setState(() => a.isMetric = m),
            footer: delta == 0
                ? Text(s.t('delta_same'), textAlign: TextAlign.center, style: OnbText.body(context, 3.7, color: OnbColors.mute))
                : Column(
                    children: [
                      Text('${delta > 0 ? '+' : '−'}$shownDelta', style: OnbText.display(context, 4.8, color: OnbColors.accInk, letterSpacingEm: -0.02)),
                      Text(s.t('delta_rate', {'w': '$weeks'}), textAlign: TextAlign.center, style: OnbText.body(context, 3.7, color: OnbColors.mute)),
                    ],
                  ),
          ),
          cta: OnbButton(label: s.t('cta_projection'), onPressed: _next),
        );

      case 'projection':
        final p = OnbMetabolics.projection(a, s.lang)!;
        final cap = OnbMetabolics.dailyCalories(a);
        return _shell(
          step,
          showPast: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopIn(
                delay: const Duration(milliseconds: 250),
                child: OnbCard(
                  child: Column(
                    children: [
                      ProjectionChart(
                        startLabel: s.t('proj_today'),
                        startValue: OnbUnits.weight(a.weightKg, a.isMetric, decimal: _decimal),
                        endLabel: s.t('proj_on', {'d': p.label}),
                        endValue: OnbUnits.weight(a.targetKg, a.isMetric, decimal: _decimal),
                        ghostLabel: s.t('proj_noplan'),
                        losing: a.goal == 'lose',
                      ),
                      SizedBox(height: context.vw(2)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: context.vw(5), height: 2.5, color: OnbColors.acc),
                          SizedBox(width: context.vw(1.4)),
                          Text(s.t('legend_with'), style: OnbText.body(context, 3.1, weight: FontWeight.w500, color: OnbColors.mute)),
                          SizedBox(width: context.vw(4)),
                          Container(width: context.vw(5), height: 2.5, decoration: const BoxDecoration(color: OnbColors.mute2)),
                          SizedBox(width: context.vw(1.4)),
                          Text(s.t('legend_without'), style: OnbText.body(context, 3.1, weight: FontWeight.w500, color: OnbColors.mute)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.vw(2.6)),
              PopIn(
                delay: const Duration(milliseconds: 1500),
                dy: 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: context.vw(0.6)),
                      child: Icon(LucideIcons.refreshCw, size: context.vw(4), color: OnbColors.mute),
                    ),
                    SizedBox(width: context.vw(2.6)),
                    Expanded(
                      child: Text(s.t('proj_adjust'), style: OnbText.body(context, 3.5, weight: FontWeight.w500, color: OnbColors.mute, height: 1.4)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.vw(2.6)),
              PopIn(
                delay: const Duration(milliseconds: 1700),
                child: Row(
                  children: [
                    if (cap > 0) ...[
                      Expanded(child: _statTile(s.t('stat_cap_kcal'), '$cap kcal')),
                      SizedBox(width: context.vw(2.2)),
                      Expanded(child: _statTile(s.t('stat_cap_protein'), '${OnbMetabolics.macros(a)['protein'] ?? 0} g')),
                    ] else ...[
                      Expanded(
                          child: _statTile(s.t('stat_rate'),
                              '${a.goal == 'lose' ? '−' : '+'}${p.ratePerWeekKg.toStringAsFixed(1).replaceAll('.', _decimal)} ${a.isMetric ? 'kg' : 'lb'} ${s.t('per_week')}')),
                      SizedBox(width: context.vw(2.2)),
                      Expanded(child: _statTile(s.t('stat_duration'), s.t('weeks', {'w': '${p.weeks}'}))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          cta: OnbButton(label: s.t('cta_go'), onPressed: _next),
        );

      case 'activity':
        return _shell(
          step,
          body: Column(
            children: [
              for (final (i, k) in ['low', 'light', 'moderate', 'high'].indexed) ...[
                if (i > 0) SizedBox(height: context.vw(2.2)),
                OnbOptionCard(
                    index: i,
                    title: s.t('act_$k'),
                    subtitle: s.t('act_${k}_sub'),
                    selected: a.activity == k,
                    onTap: () {
                      setState(() => a.activity = k);
                      _autoNext();
                    }),
              ],
            ],
          ),
        );

      case 'diet':
        // Same four options and the same stored values as the legacy form.
        final options = ['classic', 'vegetarian', 'vegan', 'pescetarian', 'gluten_free', 'lactose_free', 'halal'].map((k) => k.tr(s.lang)).toList();
        final none = options.first;
        return _shell(
          step,
          body: Wrap(
            spacing: context.vw(2),
            runSpacing: context.vw(2),
            children: [
              for (final (i, label) in options.indexed)
                OnbChip(
                  index: i,
                  label: label,
                  selected: a.restrictions.contains(label),
                  onTap: () => setState(() {
                    if (label == none) {
                      a.restrictions = [none];
                    } else {
                      a.restrictions.remove(none);
                      a.restrictions.contains(label) ? a.restrictions.remove(label) : a.restrictions.add(label);
                      if (a.restrictions.isEmpty) a.restrictions = [none];
                    }
                  }),
                ),
            ],
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'motivation':
        const keys = ['mot_event', 'mot_health', 'mot_body', 'mot_energy', 'mot_confidence'];
        return _shell(
          step,
          centerBody: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: context.vw(2),
                runSpacing: context.vw(2),
                children: [
                  for (final (i, k) in keys.indexed)
                    OnbChip(index: i, label: s.t(k), selected: a.motivation == k, onTap: () => setState(() => a.motivation = k)),
                ],
              ),
              SizedBox(height: context.vh(2)),
              PopIn(
                delay: const Duration(milliseconds: 560),
                child: TextField(
                  controller: _motivationCtrl,
                  onChanged: (v) => a.motivationText = v,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 200,
                  style: OnbText.body(context, 3.9),
                  decoration: InputDecoration(
                    hintText: s.t('mot_placeholder'),
                    hintStyle: OnbText.body(context, 3.9, color: OnbColors.mute2),
                    counterText: '',
                    filled: true,
                    fillColor: OnbColors.surf,
                    contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.2), vertical: context.vw(3.6)),
                    enabledBorder:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(context.vw(4.2)), borderSide: const BorderSide(color: OnbColors.line)),
                    focusedBorder:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(context.vw(4.2)), borderSide: const BorderSide(color: OnbColors.ink, width: 2)),
                  ),
                ),
              ),
            ],
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: a.motivation == null ? null : _next),
        );

      case 'obstacles':
        const keys = ['obs_time', 'obs_motiv', 'obs_diet', 'obs_know', 'obs_slow', 'obs_none'];
        return _shell(
          step,
          body: Column(
            children: [
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) SizedBox(height: context.vw(1.8)),
                OnbOptionCard(
                  index: i,
                  dense: true,
                  title: s.t(k),
                  selected: a.obstacles.contains(k),
                  onTap: () => setState(() {
                    if (k == 'obs_none') {
                      a.obstacles = a.obstacles.contains(k) ? [] : ['obs_none'];
                    } else {
                      a.obstacles.remove('obs_none');
                      a.obstacles.contains(k) ? a.obstacles.remove(k) : a.obstacles.add(k);
                    }
                  }),
                ),
              ],
            ],
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: a.obstacles.isEmpty ? null : _next),
        );

      case 'answers':
        return _shell(
          step,
          showPast: false,
          centerBody: false,
          body: AnswersContent(s: s, obstacleKeys: a.obstacles),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'both':
        return _shell(
          step,
          showPast: false,
          centerBody: false,
          body: BothCoachesContent(
            s: s,
            answers: a,
            projection: OnbMetabolics.projection(a, s.lang),
            annualPrice: _annualPrice,
            annualPriceLabel: _annualPriceLabel ?? s.t('price_default_annual'),
          ),
          cta: OnbButton(label: s.t('cta_continue'), onPressed: _next),
        );

      case 'personality':
        final options = [
          for (final t in [
            CoachPersonalityType.friendly,
            CoachPersonalityType.strict,
            CoachPersonalityType.supportive,
            CoachPersonalityType.sassy,
            CoachPersonalityType.direct
          ])
            OnbPersonalityOption(
                key: t.name,
                emoji: CoachPersonalityService.getEmoji(t),
                label: CoachPersonalityService.getLocalizedLabel(t, s.lang),
                sample: s.t('pers_${t.name}', {'n': _name ?? ''}).replaceAll(' ,', ',').replaceAll('  ', ' ')),
        ];
        return _shell(
          step,
          body: OnbPersonalityGrid(options: options, value: a.personality, hint: s.t('pers_hint'), onChanged: (k) => setState(() => a.personality = k)),
          cta: OnbButton(label: s.t('cta_tone'), onPressed: a.personality == null ? null : _next),
        );

      case 'bilan':
        return _shell(
          step,
          body: OnbDayPicker(
            shortNames: s.dayShort,
            fullNames: s.dayFull,
            value: a.bilanDay,
            onChanged: (d) {
              setState(() => a.bilanDay = d);
              Future.delayed(const Duration(milliseconds: 780), () {
                if (mounted) _next();
              });
            },
          ),
        );

      case 'pact':
        final dayName = _dayName(a.bilanDay ?? 7);
        return _shell(
          step,
          showPast: false,
          body: PactContent(
            s: s,
            firstName: _name ?? '',
            dayName: dayName,
            goal: _pactGoal(),
            why: a.motivationText.trim().isEmpty ? null : a.motivationText.trim(),
            signed: _signed,
            onSigned: _onPactSigned,
          ),
          cta: _signed ? OnbButton(label: widget.mode == OnbMode.coachOnly ? s.t('cta_continue') : s.t('cta_unlock'), onPressed: _next) : null,
        );

      default:
        return _shell(step, body: const SizedBox.shrink(), cta: OnbButton(label: s.t('cta_continue'), onPressed: _next));
    }
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.vw(4), vertical: context.vw(3.4)),
      decoration: BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(4)), border: Border.all(color: OnbColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OnbText.body(context, 2.9, weight: FontWeight.w500, color: OnbColors.mute)),
          SizedBox(height: context.vw(0.8)),
          Text(value, style: OnbText.display(context, 5.4, letterSpacingEm: -0.02)),
        ],
      ),
    );
  }

  Widget _plannerStep(_Step step) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.vw(6), context.vh(1.6), context.vw(6), context.vh(1.4)),
            child: OnbTopBar(fills: _fills(step), chapter: step.chapter, label: _chapterLabel(step), onBack: _canGoBack ? _back : null),
          ),
          Expanded(
            child: PlannerDemoStep(
              onCollected: (meals, workouts, sessions) {
                _demoMeals.addAll(meals);
                _demoWorkouts.addAll(workouts);
                _demoSessions.addAll(sessions);
              },
              onDone: () {
                HapticService.instance.mediumImpact();
                unawaited(_persistDemoPlan());
                _next();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _offerStep() {
    final mealsPerDay = List<int>.filled(7, 0);
    for (final m in _demoMeals) {
      final d = m.plannedDate.weekday - 1;
      if (d >= 0 && d < 7) mealsPerDay[d] = (mealsPerDay[d] + 1).clamp(0, 3);
    }
    final workoutDays = <int>{
      for (final w in _demoWorkouts) w.plannedDate.weekday - 1,
      for (final w in _demoSessions) w.plannedDate.weekday - 1,
    };
    return OnboardingPaywallScreen(
      s: s,
      bilanDayName: _dayName(a.bilanDay ?? 7),
      goalLine: _goalLine(),
      mealsPerDay: mealsPerDay,
      workoutDays: workoutDays,
      initialPlan: a.plan,
      onPurchased: _finish,
    );
  }
}
