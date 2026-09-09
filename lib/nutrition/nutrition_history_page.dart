import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../models/notification_models.dart';
import '../services/day_meals.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/portions.dart';
import '../services/ryze_dates.dart';
import '../services/translations.dart';
import '../services/water_service.dart';
import 'add_food_sheet.dart';

/// A past day, read exactly the way today is read.
///
/// The history is not a list of rows to scroll: it is the same day, moved. A
/// strip of the last thirty days sits on top, each one marked by how close it
/// came to the goal, and choosing one rebuilds the instrument, the water and
/// the meals below. A forgotten meal can still be added, and it lands on that
/// day rather than on today.
class NutritionHistoryPage extends StatefulWidget {
  const NutritionHistoryPage({super.key});

  @override
  State<NutritionHistoryPage> createState() => _NutritionHistoryPageState();
}

class _NutritionHistoryPageState extends State<NutritionHistoryPage>
    with GlobalStateListener {
  static const int _span = 30;

  /// Un repas ajouté ou retiré ailleurs se voit ici aussi.
  ///
  /// Cette page n'écoutait rien : elle ne se rechargeait que sur ses propres
  /// gestes. Un repas supprimé depuis la conversation y restait affiché
  /// jusqu'à ce qu'on change de jour ou d'onglet.
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    switch (event.type) {
      case ChangeType.planner:
      case ChangeType.meals:
      case ChangeType.calories:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _load();
      default:
        break;
    }
  }

  late DateTime _selected;
  DayMeals? _day;
  NotificationPreferences? _prefs;
  int _waterMl = 0;
  int _waterGoalMl = 2000;
  bool _loading = true;
  final Set<WeekSlot> _open = {};

  /// Le total revient en barre dès que l'instrument a quitté le haut.
  final ScrollController _scroll = ScrollController();
  bool _stuck = false;

  /// How close each day of the strip came to its calorie goal, so the strip
  /// says something rather than just listing numbers.
  final Map<String, double> _fill = {};

  String get _lang => LocalizationService.instance.currentLanguageCode;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    _scroll.addListener(_onScroll);
    _load();
    _loadPrefs();
    _loadStrip();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final past = _scroll.offset > context.vw(30);
    if (past != _stuck) setState(() => _stuck = past);
  }

  List<DateTime> get _days {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return [for (var i = _span; i >= 1; i--) start.subtract(Duration(days: i))];
  }

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _loadPrefs() async {
    final prefs = NotificationService().getPreferences();
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final day = await DayMeals.forDate(_selected);
    final water = await WaterService.getDailyWaterProgress(date: _selected);
    if (!mounted) return;
    setState(() {
      _day = day;
      _waterMl = water?.consumedMl ?? 0;
      _waterGoalMl = (water?.goalMl ?? 0) > 0 ? water!.goalMl : 2000;
      _loading = false;
      _open.clear();
    });
  }

  /// The whole strip in one query, rather than thirty days read one by one.
  Future<void> _loadStrip() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final days = _days;
    final byDay = await FoodEntriesService.getDailyCalories(
      userId: userId,
      from: days.first,
      to: days.last,
    );
    if (!mounted) return;
    final goal = GlobalStateManager.instance.calorieGoal;
    setState(() {
      for (final day in days) {
        final eaten = byDay[_key(day)] ?? 0;
        _fill[_key(day)] = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0;
      }
    });
  }

  void _select(DateTime day) {
    if (_key(day) == _key(_selected)) return;
    RyzeFeedback.select();
    setState(() => _selected = day);
    _load();
  }

  String _hourOf(WeekSlot slot) {
    final prefs = _prefs ?? NotificationPreferences();
    final hour = switch (slot) {
      WeekSlot.breakfast => prefs.breakfastTime,
      WeekSlot.lunch => prefs.lunchTime,
      WeekSlot.snack => 16,
      _ => prefs.dinnerTime,
    };
    return '$hour h';
  }

  Future<void> _add(WeekSlot slot) async {
    final mealName = 'meal_name_${slot.name}'.tr(_lang);
    await AddFoodSheet.show(
      context,
      mealName: mealName,
      title: mealName,
      date: _selected,
      onAdded: (item) {
        if (!mounted) return;
        RyzeFeedback.success();
        _load();
        _loadStrip();
      },
    );
  }

  /// Refixer ce que pesait un aliment, comme sur la page du jour. La feuille
  /// existait là-bas seulement : sur un jour passé, se tromper de portion
  /// obligeait à supprimer puis ressaisir.
  Future<void> _editItem(WeekSlot slot, nutrition.FoodItem item) async {
    if (item.id == null) return;
    final parts = item.portion.trim().split(RegExp(r'\s+'));
    final current = double.tryParse(parts.first.replaceAll(',', '.')) ?? 100;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'g';
    final steps = <double>{...RyzePortions.presets(unit: unit, reference: current), current}.toList()..sort();

    final chosen = await showRyzeSheet<double>(
      context,
      title: item.name,
      subtitle: 'nutri_fix_portion'.tr(_lang),
      builder: (sheet) => Wrap(
        spacing: sheet.vw(2),
        runSpacing: sheet.vw(2),
        children: [
          for (final value in steps)
            _Chip(
              label: RyzePortions.label(value, unit, _lang),
              selected: (value - current).abs() < 0.05,
              onTap: () => Navigator.pop(sheet, value),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted || (chosen - current).abs() < 0.05) return;

    final ok = await FoodEntriesService.updateFoodEntryQuantity(item.id!, chosen);
    if (!mounted) return;
    if (ok) {
      RyzeFeedback.confirm();
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
    }
    _load();
    _loadStrip();
  }

  Future<void> _removeItem(WeekSlot slot, nutrition.FoodItem item) async {
    if (item.id == null) return;
    RyzeFeedback.removed();
    final ok = await FoodEntriesService.removeFoodEntry(item.id!);
    if (!mounted) return;
    if (ok) {
      RyzeUndo.show(
        context,
        message: 'undo_item_removed'.tr(_lang).replaceAll('{name}', item.name),
        undoLabel: 'undo'.tr(_lang),
        onUndo: () async {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) return;
          await FoodEntriesService.addFoodEntry(
            userId: userId,
            mealName: 'meal_name_${slot.name}'.tr(_lang),
            foodItem: item,
            consumedAt: _selected,
          );
          _load();
          _loadStrip();
        },
      );
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
    }
    _load();
    // La jauge du jour dans la bande restait sur son ancienne valeur : elle
    // n'était relue qu'à l'ajout, jamais au retrait.
    _loadStrip();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gs = GlobalStateManager.instance;
    final day = _day;
    final numbers = NumberFormat.decimalPattern(lang);
    final goal = gs.calorieGoal.round();
    final eaten = day?.caloriesLogged ?? 0;
    final remaining = goal - eaten;
    final gutter = context.vw(5.1);
    final label = RyzeDates.full(_selected, lang);

    return Column(
      children: [
        SizedBox(
          height: DayChip.stripHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: _days.length,
            separatorBuilder: (_, __) => SizedBox(width: DayChip.gap(context)),
            itemBuilder: (_, i) {
              final d = _days[_days.length - 1 - i];
              final selected = _key(d) == _key(_selected);
              return DayChip(
                day: d,
                lang: lang,
                selected: selected,
                onTap: () => _select(d),
                marker: _Gauge(fill: _fill[_key(d)], selected: selected),
              );
            },
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(gutter, context.vw(4), gutter, 132),
            children: [
              Text(
                label,
                style: RyzeText.body(context, 3.9, weight: FontWeight.w600),
              ),
              SizedBox(height: context.vw(4)),
              if (_loading || day == null)
                SizedBox(height: context.vw(40), child: Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)))
              else ...[
                DayInstrument(
                  lead: remaining < 0 ? 'nutri_over_that_day'.tr(lang) : 'nutri_left_that_day'.tr(lang),
                  unit: 'nutri_kcal'.tr(lang),
                  eatenLabel: 'nutri_eaten'.tr(lang).replaceAll('{n}', numbers.format(eaten)),
                  goalLabel: 'nutri_goal'.tr(lang).replaceAll('{n}', numbers.format(goal)),
                  calories: eaten,
                  calorieGoal: goal,
                  shown: true,
                  macros: [
                    MacroRail(label: 'nutri_proteins'.tr(lang), value: day.proteinsLogged, goal: gs.proteinGoal, shown: true),
                    MacroRail(label: 'nutri_carbs'.tr(lang), value: day.carbsLogged, goal: gs.carbsGoal, shown: true),
                    MacroRail(label: 'nutri_fats'.tr(lang), value: day.fatsLogged, goal: gs.fatGoal, shown: true),
                  ],
                ),
                SizedBox(height: context.vw(7)),
                _Header(
                  title: 'nutri_water'.tr(lang),
                  trailing: '${_litres(_waterMl / 1000, lang)} ${'nutri_water_of'.tr(lang).replaceAll('{n}', _litres(_waterGoalMl / 1000, lang))}',
                ),
                SizedBox(height: context.vw(2.6)),
                GlassRow(
                  litres: _waterMl / 1000,
                  goalLitres: _waterGoalMl / 1000,
                  shown: true,
                  onSet: null,
                  onOther: null,
                ),
                SizedBox(height: context.vw(7)),
                _Header(title: 'nutri_meals'.tr(lang), trailing: '${day.doneCount} / ${day.total}'),
                SizedBox(height: context.vw(1)),
                MealTimeline(
                  day: day,
                  labelOf: (slot) => 'slot_${slot.name}'.tr(lang),
                  hourOf: _hourOf,
                  plannedPrefix: 'nutri_planned_prefix'.tr(lang),
                  nothingLogged: 'nutri_nothing_logged'.tr(lang),
                  addLabel: 'nutri_add_food'.tr(lang),
                  open: _open,
                  onToggle: (slot) => setState(() => _open.contains(slot) ? _open.remove(slot) : _open.add(slot)),
                  onAdd: _add,
                  onRemoveItem: _removeItem,
                  onEditItem: _editItem,
                ),
              ],
            ],
          ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StickyTotal(
                  shown: _stuck && !_loading && day != null,
                  lead: remaining < 0 ? 'nutri_over_that_day'.tr(lang) : 'nutri_left_that_day'.tr(lang),
                  value: numbers.format(remaining.abs()),
                  unit: 'nutri_kcal'.tr(lang),
                  fraction: goal > 0 ? eaten / goal : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _litres(double l, String lang) => NumberFormat.decimalPattern(lang).format(double.parse(l.toStringAsFixed(2)));
}

/// A 3 pt bar under the number: how much of the goal that day held. Nothing is
/// drawn while the day is still being read, so the strip never shows a false
/// empty.
/// Une valeur possible, dans la feuille de correction de portion. Le même
/// jeton que sur la page du jour.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.selected = false});

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.ink, width: 1.5),
        ),
        child: Text(
          label,
          style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: selected ? RyzeColors.surf : RyzeColors.ink),
        ),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.fill, required this.selected});

  final double? fill;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final width = context.vw(6.4);
    return SizedBox(
      width: width,
      height: 3,
      child: fill == null
          ? null
          : Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: selected ? RyzeColors.surf.withValues(alpha: 0.28) : RyzeColors.idle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: RyzeDurations.fill,
                  curve: RyzeCurves.out,
                  width: width * fill!,
                  decoration: BoxDecoration(
                    color: selected ? RyzeColors.surf : RyzeColors.acc,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A block's name on the left, its count on the right.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
        Text(trailing, style: RyzeText.body(context, 3.3, color: RyzeColors.mute)),
      ],
    );
  }
}
