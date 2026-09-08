import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/weekly_planner/cardio_recap_bottom_sheet.dart';
import '../components/weekly_planner/workout_recap_bottom_sheet.dart';
import '../design/design.dart';
import '../models/weekly_planner_models.dart';
import '../screens/planner_chat_screen.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/ryze_dates.dart';
import '../services/water_service.dart';
import '../services/weekly_planner_service.dart';
import '../sport/sport_start.dart';
import 'home_slots.dart';
import 'home_suggestion.dart';
import 'sheets/planned_meal_sheet.dart';
import 'widgets/coach_line.dart';
import 'widgets/today_row.dart';
import 'widgets/water_tile.dart';
import '../nutrition/day_analysis.dart';
import '../nutrition/add_food_sheet.dart';
import 'widgets/home_week.dart';

/// The home: the coach's brief of the day.
///
/// One thing to read, the calories left as the instrument of the day; one
/// thing to do, the action the coach proposes; then the week as the planner's
/// band, today opened. The ground is the onboarding's paper. Every value comes
/// from the global state and the week plan, both of which already drive the
/// rest of the app.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onTabChange});

  final ValueChanged<String>? onTabChange;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with GlobalStateListener {
  /// The planner reconciles the plan with the history once per user and run;
  /// the home does it too when it is the first to show.
  static String? _syncedFor;

  /// The entry is played once per run. Coming back to the tab, the page is
  /// simply there.
  static bool _revealed = false;

  /// The day the greeting was last said. It used to be glued to the front of
  /// every coach line, which produced « Bonsoir Badis. Bonne nuit. » and ate
  /// the room the button needed.
  static String? _greetedOn;

  /// What the user just did, held for a few seconds so the page acknowledges
  /// it before moving on to the next chore.
  String? _ack;
  Timer? _ackTimer;

  /// Vrai quand le coach a deja lu la journee : il propose alors de la
  /// revoir plutot que de la relancer, et l'appel n'est pas refacture.
  bool _analysisReady = false;

  /// Minuit est passe et la journee qui vient de finir a de quoi etre lue.
  bool _nightReview = false;

  WeeklyPlannerData? _week;
  bool _syncing = false;
  late final bool _first;

  /// False for the first frames of the first entry: the instrument opens at
  /// zero and rolls up.
  late bool _shown;

  /// True only the first time the home is shown on a given day.
  late final bool _greet;

  @override
  void initState() {
    super.initState();
    // read before it is set, or the entry would never play
    _first = !_revealed;
    _revealed = true;
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    _greet = _greetedOn != today;
    _greetedOn = today;
    _shown = !_first;
    _load();
    if (_first) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _shown = true);
        });
      });
    }
  }

  @override
  void dispose() {
    _ackTimer?.cancel();
    super.dispose();
  }

  /// Say back what just happened, then let the coach take over again.
  void _acknowledge(String message) {
    RyzeFeedback.success();
    _ackTimer?.cancel();
    setState(() => _ack = message);
    _ackTimer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => _ack = null);
    });
  }

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // the mixin already rebuilds; what changes the plan also reloads it
    switch (event.type) {
      case ChangeType.planner:
      case ChangeType.meals:
      case ChangeType.workout:
      case ChangeType.sport:
      case ChangeType.dayReset:
      case ChangeType.batch:
        if (!_syncing) _loadWeek(force: true);
      default:
        break;
    }
  }

  /// What is cached comes first, so the page is right within a frame; the
  /// history sync, which can take seconds, runs after and refreshes.
  Future<void> _load() async {
    await _loadWeek();
    final user = Supabase.instance.client.auth.currentUser?.id;
    if (user == null || !mounted) return;
    // Cette lecture vient avant la garde de synchronisation. Elle était après,
    // donc dès la deuxième venue sur l'accueil dans une même exécution elle ne
    // tournait plus : une analyse lancée depuis Nutrition laissait le coach
    // proposer « Je la regarde ? » alors qu'elle existait déjà.
    await _checkAnalysis();
    if (_syncedFor == user || !mounted) return;
    _syncing = true;
    try {
      await WeeklyPlannerService.cleanupMissedActivities();
      await WeeklyPlannerService.fullSyncFromHistory();
      _syncedFor = user;
    } finally {
      _syncing = false;
    }
    if (mounted) await _loadWeek(force: true);
  }

  Future<void> _checkAnalysis() async {
    // Entre minuit et 5 h, l'etat global a deja bascule de jour : ses calories
    // sont celles d'une journee de quelques minutes. Pour savoir si celle qui
    // vient de finir merite d'etre lue, il faut la relire dans la base.
    if (DayAnalysis.isNight()) {
      final worth = await DayAnalysis.worthReading(DayAnalysis.yesterday());
      if (mounted && worth != _nightReview) setState(() => _nightReview = worth);
      return;
    }
    if (mounted && _nightReview) setState(() => _nightReview = false);
    if (!DayAnalysis.isOffered()) return;
    final found = await DayAnalysis.cached();
    if (mounted && (found != null) != _analysisReady) {
      setState(() => _analysisReady = found != null);
    }
  }

  Future<void> _loadWeek({bool force = false}) async {
    try {
      final data = await WeeklyPlannerService.getWeekData(forceRefresh: force);
      if (mounted) setState(() => _week = data);
    } catch (_) {
      // the page keeps what it has; the next event or pull tries again
    }
  }

  /// Pull-to-refresh: the plan, the meals and the sport, all read again.
  Future<void> _refresh() async {
    final gs = GlobalStateManager.instance;
    await Future.wait<void>([
      gs.refreshMealsCount().catchError((_) {}),
      gs.refreshSportData().catchError((_) {}),
      _loadWeek(force: true),
    ]);
  }

  // ---------------------------------------------------------------- the week

  /// Monday to Sunday of this week, from the device's clock. The plan's own
  /// week is fetched for these dates; a day it does not hold is simply empty.
  List<DateTime> get _days {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
  }

  DayPlanData? get _todayPlan => _week?.getDayPlan(DateTime.now());

  // ---------------------------------------------------------------- actions

  String get _lang => LocalizationService.instance.currentLanguageCode;

  /// The global state fills an empty first name with a placeholder; the coach
  /// does not greet a placeholder.
  String get _name {
    final n = GlobalStateManager.instance.userName.trim();
    return n == 'User' ? '' : n;
  }

  void _run(HomeAction action) {
    switch (action) {
      case HomeAction.logBreakfast:
        _logMealOf(WeekSlot.breakfast);
      case HomeAction.logLunch:
        _logMealOf(WeekSlot.lunch);
      case HomeAction.logSnack:
        _logMealOf(WeekSlot.snack);
      case HomeAction.logDinner:
        _logMealOf(WeekSlot.dinner);
      case HomeAction.logMeal:
        _logMeal();
      case HomeAction.drinkWater:
        _addWater(250);
      case HomeAction.startWorkout:
        _startSession();
      case HomeAction.analyseDay:
        _analyseDay();
      case HomeAction.analyseYesterday:
        _analyseDay(day: DayAnalysis.yesterday());
      case HomeAction.viewDay:
        // « Voir ma journée » parle des repas du jour — « tu es à 210 kcal
        // au-dessus, on regarde ? ». Cela envoyait sur la Progression, qui
        // montre le poids et les tendances : elle ne répond pas à la question
        // posée. Le journal, lui, y répond.
        widget.onTabChange?.call('nutrition');
    }
  }

  /// One sheet: what the user eats again at this meal, then the five ways to
  /// describe something new. The same sheet Nutrition opens, so the two tabs
  /// add food the same way and through the same write path.
  Future<void> _logMealOf(WeekSlot slot) async {
    final mealName = 'meal_name_${slot.name}'.tr(_lang);
    await AddFoodSheet.show(
      context,
      mealName: mealName,
      title: mealName,
      onAdded: (item) {
        if (!mounted) return;
        _acknowledge('home_meal_logged'.tr(_lang).replaceAll('{m}', mealName));
        _loadWeek(force: true);
      },
    );
  }

  /// The meals tile: whichever meal comes next today, so the app never asks
  /// a question it can answer itself.
  void _logMeal() {
    final today = HomeSlots.ofDay(_todayPlan);
    final next = kFoodSlots.firstWhere(
      (s) => today.state(s) != SlotState.done && (s != WeekSlot.snack || today.state(s) != SlotState.empty),
      orElse: () => WeekSlot.dinner,
    );
    _logMealOf(next);
  }

  /// Les verres de l'accueil. Monter en ajoute un, descendre en retire un —
  /// les memes gestes que dans le journal, avec la meme annulation.
  Future<void> _setGlasses(int glasses) async {
    final gs = GlobalStateManager.instance;
    final current = (gs.currentWaterL / GlassRow.glassLitres).floor();
    if (glasses == current) return;
    if (glasses > current) {
      await _addWater(250);
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) return;
    RyzeFeedback.tap();
    // On descend : on retire les entrees les plus recentes jusqu'au niveau
    // vise, exactement comme le journal le fait.
    final target = glasses * 250;
    final entries = await WaterService.getTodayWaterEntries();
    entries.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    var total = entries.fold<int>(0, (s, e) => s + e.amount);
    var removed = 0;
    for (final entry in entries) {
      if (total <= target) break;
      final ok = await WaterService.deleteWaterEntry(entry.id, amountToRemove: entry.amount);
      if (!ok) break;
      total -= entry.amount;
      removed++;
    }
    if (!mounted || removed == 0) return;
    _acknowledge('undo_glass_removed'.tr(_lang));
  }

  Future<void> _addWater(int millilitres) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      RyzeUndo.failed(context, message: 'must_be_connected'.tr(_lang));
      return;
    }
    RyzeFeedback.tap();
    final ok = await WaterService.addWaterEntry(amount: millilitres, sourceType: millilitres == 250 ? 'glass' : 'manual');
    if (!mounted) return;
    if (ok) {
      _acknowledge(millilitres == 250 ? 'home_glass_added'.tr(_lang) : '$millilitres ${'water_added'.tr(_lang)}');
    } else {
      RyzeUndo.failed(context, message: 'water_add_error'.tr(_lang));
    }
  }

  /// Another amount than a glass. The same sheet as Nutrition, so the two
  /// tabs ask the question the same way.
  Future<void> _waterSheet() async {
    final ml = await showRyzeSheet<int>(
      context,
      title: 'nutri_water'.tr(_lang),
      subtitle: 'water_other'.tr(_lang),
      builder: (sheet) => Wrap(
        spacing: sheet.vw(2),
        runSpacing: sheet.vw(2),
        children: [
          for (final amount in [250, 500, 750, 1000])
            Pressable(
              onTap: () => Navigator.pop(sheet, amount),
              child: Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: sheet.vw(4.1)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.pill),
                  border: Border.all(color: RyzeColors.ink, width: 1.5),
                ),
                child: Text(
                  amount >= 1000 ? '1 L' : '${amount ~/ 10} cl',
                  style: RyzeText.body(sheet, 3.6, weight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
    if (ml != null && mounted) await _addWater(ml);
  }

  /// Le bouton du coach : la séance prévue démarre. Le coach ne la propose
  /// que tant qu'elle n'est pas faite, donc il n'y a rien à « voir » — et
  /// c'est le même chemin de départ que l'onglet Sport, avec l'identifiant du
  /// planifié transmis pour que ce soit bien celle-là qui se coche.
  Future<void> _startSession() async {
    final s = HomeSlots.session(_todayPlan);
    if (s == null) {
      widget.onTabChange?.call('sport');
      return;
    }
    if (s.workout != null) {
      await SportStart.plannedWorkout(context, s.workout!);
    } else if (s.cardio != null) {
      await SportStart.plannedCardio(context, s.cardio!);
    }
    if (mounted) _loadWeek(force: true);
  }

  /// La pastille « séance » de la rangée du jour : regarder ce qu'il y a
  /// dedans, avant de la lancer ou après l'avoir faite. Sans séance du jour,
  /// l'onglet Sport, où vivent toutes les façons d'en démarrer une.
  void _openSession() {
    final s = HomeSlots.session(_todayPlan);
    if (s?.workout != null) {
      WorkoutRecapBottomSheet.show(context, workout: s!.workout!).then((_) => _loadWeek(force: true));
    } else if (s?.cardio != null) {
      CardioRecapBottomSheet.show(context, activity: s!.cardio!).then((_) => _loadWeek(force: true));
    } else {
      widget.onTabChange?.call('sport');
    }
  }

  /// La lecture de la journee par Coach Ryze. Le cache est par date :
  /// rouvrir ne relance rien et ne consomme pas d'essai.
  Future<void> _analyseDay({DateTime? day}) async {
    await DayAnalysis.open(context, date: day);
    if (mounted) await _checkAnalysis();
  }

  /// « Planifier » demande d'abord de quoi on parle.
  ///
  /// Il ouvrait le planificateur des repas, sans le dire et sans autre porte :
  /// celui des séances n'était atteignable que depuis Sport → Aujourd'hui, ce
  /// que rien n'indiquait. Deux rangées, deux coachs, et le doute tombe.
  Future<void> _openPlanner() async {
    final mode = await showRyzeSheet<String>(
      context,
      title: 'plan_with_ryze'.tr(_lang),
      subtitle: 'home_this_week'.tr(_lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(
            first: true,
            icon: LucideIcons.utensils,
            label: 'plan_my_meals'.tr(_lang),
            onTap: () => Navigator.pop(sheet, 'meals'),
          ),
          RyzeSheetRow(
            icon: LucideIcons.dumbbell,
            label: 'plan_my_workouts'.tr(_lang),
            onTap: () => Navigator.pop(sheet, 'workouts'),
          ),
        ],
      ),
    );
    if (mode == null || !mounted) return;
    await _pushPlanner(mode);
  }

  Future<void> _pushPlanner(String mode) async {
    final week = _week ?? await WeeklyPlannerService.getWeekData();
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlannerChatScreen(initialMode: mode, weekData: week),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      ),
    );
    if (mounted) _loadWeek(force: true);
  }

  /// Une ligne du jour ouvert : la feuille de ce qu'elle porte. Ce sont les
  /// mêmes feuilles que partout ailleurs - la séance et le cardio les avaient
  /// déjà, le repas prévu vient d'avoir la sienne.
  Future<void> _onWeekLineTap(DateTime day, PlannedLine line) async {
    if (line.workout != null) {
      await WorkoutRecapBottomSheet.show(context, workout: line.workout!);
    } else if (line.slot == WeekSlot.sport && line.activity != null) {
      await CardioRecapBottomSheet.show(context, activity: line.activity!);
    } else if (line.activity != null) {
      await PlannedMealSheet.show(context, meal: line.activity!, lang: _lang);
    }
    if (mounted) _loadWeek(force: true);
  }

  /// A slot that is already done opens what is in it, in the Nutrition tab.
  /// Offering to add food on top of a logged meal was the app answering a
  /// question the user did not ask.
  void _onSlotTap(WeekSlot slot) {
    if (slot == WeekSlot.sport) {
      _openSession();
      return;
    }
    if (HomeSlots.ofDay(_todayPlan).state(slot) == SlotState.done) {
      widget.onTabChange?.call('nutrition');
      return;
    }
    _logMealOf(slot);
  }

    /// Good morning, good afternoon, good evening. Said once a day.
  String _greetingFor(DateTime now, String lang) {
    final who = _name.trim();
    if (who.isEmpty) return 'home_greet_anon'.tr(lang);
    final key = now.hour >= 5 && now.hour < 12
        ? 'home_greet_morning'
        : (now.hour >= 12 && now.hour < 18 ? 'home_greet_day' : 'home_greet_evening');
    return key.tr(lang).replaceAll('{n}', who);
  }

  // ---------------------------------------------------------------- the page

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gs = GlobalStateManager.instance;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animate = _first && !reduce;
    final shown = _shown || reduce;

    final days = _days;
    final slots = [for (final d in days) HomeSlots.ofDay(_week?.getDayPlan(d))];
    final lines = [
      for (final d in days)
        HomeSlots.linesOf(
          _week?.getDayPlan(d),
          slotLabel: (s) => 'slot_${s.name}'.tr(lang),
          kcal: 'nutri_kcal'.tr(lang),
          exercises: 'planner_exercises'.tr(lang),
        ),
    ];
    final now = DateTime.now();
    final todayIndex = days.indexWhere((d) => d.year == now.year && d.month == now.month && d.day == now.day);
    final today = todayIndex < 0 ? const DaySlots() : slots[todayIndex];

    final calories = gs.currentCalories.round();
    final goal = gs.calorieGoal.round();
    final ready = goal > 0;

    final suggestion = HomeSuggestion.build(
      lang: lang,
      name: _name,
      today: today,
      waterL: gs.currentWaterL,
      waterGoalL: gs.waterGoalL,
      calories: gs.currentCalories.round(),
      calorieGoal: gs.calorieGoal.round(),
      analysisOffered: DayAnalysis.isOffered(),
      analysisReady: _analysisReady,
      nightReview: _nightReview,
    );
    // Le bouton secondaire est pour quand l'étape suivante est de regarder.
    // Démarrer une séance est un engagement : il prend l'encre pleine.
    final looks = suggestion.action == HomeAction.viewDay;

    // The greeting is said once a day, on its own line, instead of being glued
    // to the front of every sentence the coach says.
    final greeting = _greet ? _greetingFor(now, lang) : null;
    final line = _ack ?? (greeting == null ? suggestion.line : '$greeting ${suggestion.line}');

    final gutter = context.vw(5.1);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: RyzeColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: RyzeColors.ink,
              backgroundColor: RyzeColors.surf,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, 128),
                children: [
                  PopIn(
                    delay: const Duration(milliseconds: 40),
                    dy: 8,
                    animate: animate,
                    child: _TopBar(lang: lang, name: _name, streak: gs.currentStreak, date: now),
                  ),
                  SizedBox(height: context.vw(4.6)),
                  PopIn(
                    delay: const Duration(milliseconds: 160),
                    dy: 8,
                    animate: animate,
                    child: Builder(
                      builder: (context) {
                        final remaining = goal - calories;
                        final numbers = NumberFormat.decimalPattern(lang);
                        return DayInstrument(
                          // With no goal yet, "goal reached" would be a lie
                          // told to every new subscriber whose targets are
                          // still loading.
                          lead: !ready
                              ? 'home_loading'.tr(lang)
                              : remaining < 0
                                  ? 'home_over_by'.tr(lang)
                                  : (remaining == 0 ? 'home_goal_reached'.tr(lang) : 'home_remaining'.tr(lang)),
                          unit: 'home_remaining_unit'.tr(lang),
                          eatenLabel: 'home_eaten'.tr(lang).replaceAll('{n}', numbers.format(calories)),
                          goalLabel: 'home_goal'.tr(lang).replaceAll('{n}', numbers.format(goal)),
                          calories: calories,
                          calorieGoal: goal,
                          shown: shown && ready,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.vw(4.6)),
                  // Today's five slots are the caption of the number above
                  // them; they used to arrive last, under the whole page.
                  PopIn(
                    delay: const Duration(milliseconds: 420),
                    dy: 8,
                    animate: animate,
                    child: TodayRow(lang: lang, today: today, onSlotTap: _onSlotTap),
                  ),
                  SizedBox(height: context.vw(4.1)),
                  PopIn(
                    delay: const Duration(milliseconds: 620),
                    dy: 8,
                    animate: animate,
                    child: WaterTile(
                      lang: lang,
                      litres: gs.currentWaterL,
                      goal: gs.waterGoalL,
                      shown: shown,
                      onSet: _setGlasses,
                      onMore: _waterSheet,
                    ),
                  ),
                  SizedBox(height: context.vw(4.6)),
                  PopIn(
                    delay: const Duration(milliseconds: 840),
                    dy: 8,
                    animate: animate,
                    child: CoachLine(
                      text: line,
                      sport: suggestion.sport,
                      cta: suggestion.cta,
                      ghost: looks,
                      onCta: () => _run(suggestion.action),
                      delay: const Duration(milliseconds: 840),
                      animate: animate,
                      still: reduce,
                    ),
                  ),
                  SizedBox(height: context.vw(4.6)),
                  PopIn(
                    delay: const Duration(milliseconds: 1500),
                    dy: 8,
                    animate: animate,
                    child: HomeWeek(
                      lang: lang,
                      days: days,
                      slots: slots,
                      lines: lines,
                      onOpenPlanner: _openPlanner,
                      onLineTap: _onWeekLineTap,
                      onPlanDay: (_) => _openPlanner(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The date and the first name on the left, the streak as an amber pill on
/// the right. Small and quiet: the instrument below is the headline.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.lang, required this.name, required this.streak, required this.date});
  final String lang;
  final String name;
  final int streak;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // « Mardi 8 » ne dit pas grand-chose : Nutrition ecrit « Mardi 8 septembre »
    // et l'accueil doit dire la meme date de la meme facon.
    final day = RyzeDates.full(date, lang);
    final unit = (streak == 1 ? 'day' : 'days').tr(lang);
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: RyzeText.body(context, 3.6, color: RyzeColors.mute),
              children: [
                TextSpan(text: day, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                if (name.isNotEmpty) TextSpan(text: ' · $name'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (streak > 0)
          Container(
            padding: EdgeInsets.fromLTRB(context.vw(2.3), context.vw(1.5), context.vw(2.8), context.vw(1.5)),
            decoration: BoxDecoration(color: RyzeColors.accTint, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, size: 14, color: RyzeColors.accInk),
                SizedBox(width: context.vw(1.2)),
                Text(
                  '$streak $unit',
                  style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.accInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
