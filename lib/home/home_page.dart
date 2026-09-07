import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/ui/custom_snackbar.dart';
import '../components/ui/nutrition_widgets.dart';
import '../components/weekly_planner/cardio_recap_bottom_sheet.dart';
import '../components/weekly_planner/workout_recap_bottom_sheet.dart';
import '../design/design.dart';
import '../models/weekly_planner_models.dart';
import '../screens/planner_chat_screen.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/water_service.dart';
import '../services/weekly_planner_service.dart';
import 'home_slots.dart';
import 'home_suggestion.dart';
import 'widgets/coach_line.dart';
import 'widgets/day_tiles.dart';
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

  WeeklyPlannerData? _week;
  bool _syncing = false;
  late final bool _first;

  /// False for the first frames of the first entry: the instrument opens at
  /// zero and rolls up.
  late bool _shown;

  @override
  void initState() {
    super.initState();
    // read before it is set, or the entry would never play
    _first = !_revealed;
    _revealed = true;
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
    if (user == null || _syncedFor == user || !mounted) return;
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
      case HomeAction.viewWorkout:
        _openSession();
      case HomeAction.viewDay:
        widget.onTabChange?.call('progress');
    }
  }

  /// The journal's own flow for a named meal: the five ways to add food,
  /// with the meal already chosen. The name is the one the journal stores.
  void _logMealOf(WeekSlot slot) {
    NutritionQuickActionsSection.showAddFoodOptionsForNewMeal(context, 'meal_name_${slot.name}'.tr(_lang));
  }

  /// The journal's "+" button: pick the meal, then the way to add food.
  void _logMeal() => NutritionQuickActionsSection.showMealSelectionForDashboard(context);

  Future<void> _addWater(int millilitres) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      CustomSnackbarService.showError(context, 'must_be_connected'.tr(_lang));
      return;
    }
    final ok = await WaterService.addWaterEntry(amount: millilitres, sourceType: millilitres == 250 ? 'glass' : 'manual');
    if (!mounted) return;
    if (ok) {
      CustomSnackbarService.showSuccess(context, millilitres == 250 ? 'home_glass_added'.tr(_lang) : '$millilitres ${'water_added'.tr(_lang)}');
    } else {
      CustomSnackbarService.showError(context, 'water_add_error'.tr(_lang));
    }
  }

  void _waterSheet() => NutritionBottomSheetHelper.showWaterSheet(context, (ml) => _addWater(ml));

  /// Today's session, the same item the page draws: its recap. With no
  /// session, the sport tab, where every way of starting one lives.
  void _openSession() {
    final s = HomeSlots.session(_todayPlan);
    if (s?.workout != null) {
      _sheet(WorkoutRecapBottomSheet(workout: s!.workout!));
    } else if (s?.cardio != null) {
      _sheet(CardioRecapBottomSheet(activity: s!.cardio!));
    } else {
      widget.onTabChange?.call('sport');
    }
  }

  void _sheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    ).then((_) => _loadWeek(force: true));
  }

  Future<void> _openPlanner() async {
    final week = _week ?? await WeeklyPlannerService.getWeekData();
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlannerChatScreen(initialMode: 'meals', weekData: week),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
      ),
    );
    if (mounted) _loadWeek(force: true);
  }

  void _onSlotTap(WeekSlot slot) {
    if (slot == WeekSlot.sport) {
      _openSession();
    } else {
      _logMealOf(slot);
    }
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
    final now = DateTime.now();
    final todayIndex = days.indexWhere((d) => d.year == now.year && d.month == now.month && d.day == now.day);
    final today = todayIndex < 0 ? const DaySlots() : slots[todayIndex];

    final suggestion = HomeSuggestion.build(
      lang: lang,
      name: _name,
      today: today,
      waterL: gs.currentWaterL,
      waterGoalL: gs.waterGoalL,
      calories: gs.currentCalories.round(),
      calorieGoal: gs.calorieGoal.round(),
    );
    final looks = suggestion.action == HomeAction.viewWorkout || suggestion.action == HomeAction.viewDay;

    final gutter = context.vw(5.1);
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
                        final calories = gs.currentCalories.round();
                        final goal = gs.calorieGoal.round();
                        final remaining = goal - calories;
                        final numbers = NumberFormat.decimalPattern(lang);
                        return DayInstrument(
                          lead: remaining < 0
                              ? 'home_over_by'.tr(lang)
                              : (remaining == 0 ? 'home_goal_reached'.tr(lang) : 'home_remaining'.tr(lang)),
                          unit: 'home_remaining_unit'.tr(lang),
                          eatenLabel: 'home_eaten'.tr(lang).replaceAll('{n}', numbers.format(calories)),
                          goalLabel: 'home_goal'.tr(lang).replaceAll('{n}', numbers.format(goal)),
                          calories: calories,
                          calorieGoal: goal,
                          shown: shown,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.vw(3.6)),
                  PopIn(
                    delay: const Duration(milliseconds: 620),
                    dy: 8,
                    animate: animate,
                    child: DayTiles(
                      lang: lang,
                      waterL: gs.currentWaterL,
                      waterGoalL: gs.waterGoalL,
                      today: today,
                      shown: shown,
                      onWater: () => _addWater(250),
                      onWaterMore: _waterSheet,
                      onMeals: _logMeal,
                      onSession: _openSession,
                    ),
                  ),
                  SizedBox(height: context.vw(4.6)),
                  PopIn(
                    delay: const Duration(milliseconds: 840),
                    dy: 8,
                    animate: animate,
                    child: CoachLine(
                      text: suggestion.line,
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
                      onOpenPlanner: _openPlanner,
                      onSlotTap: _onSlotTap,
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

  static const _weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[date.weekday - 1].tr(lang);
    final cap = '${weekday[0].toUpperCase()}${weekday.substring(1)}';
    final day = 'home_date'.tr(lang).replaceAll('{d}', cap).replaceAll('{n}', '${date.day}');
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
                const Icon(LucideIcons.flame, size: 14, color: RyzeColors.accInk),
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
