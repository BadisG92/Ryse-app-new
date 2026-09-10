import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../models/notification_models.dart';
import 'add_food_sheet.dart';
import 'meal_sheet.dart';
import '../services/day_meals.dart';
import '../services/food_add_flow.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';
import 'day_analysis.dart';
import '../services/localization_service.dart';
import '../services/portions.dart';
import '../services/notification_service.dart';
import '../services/translations.dart';
import '../services/water_service.dart';

/// The day, read as one thing: the number, the water, the meals.
///
/// Everything shown is touchable and nothing is written twice. The figure and
/// the gauge are the instrument the home also uses; the glasses are both the
/// reading and the control; the meals open in place instead of pushing a
/// screen. Adding always starts from a meal, so the app never asks which one.
class NutritionTodayPage extends StatefulWidget {
  const NutritionTodayPage({super.key, this.date});

  /// The day being read. Null means today, which is the only day that can be
  /// written to until the tools carry a date.
  final DateTime? date;

  @override
  State<NutritionTodayPage> createState() => _NutritionTodayPageState();
}

class _NutritionTodayPageState extends State<NutritionTodayPage> with GlobalStateListener {
  DayMeals? _day;
  NotificationPreferences? _prefs;
  final Set<WeekSlot> _open = {};
  bool _shown = false;

  /// Vrai quand le coach a deja lu la journee : la rangee du soir propose
  /// alors de la revoir plutot que de la relancer.
  bool _analysisReady = false;

  /// Le total revient en barre dès que l'instrument a quitté le haut.
  final ScrollController _scroll = ScrollController();
  bool _stuck = false;

  DateTime get _date => widget.date ?? DateTime.now();
  String get _lang => LocalizationService.instance.currentLanguageCode;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
    _loadPrefs();
    _checkAnalysis();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) setState(() => _shown = true);
      });
    });
  }

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    switch (event.type) {
      case ChangeType.meals:
      case ChangeType.calories:
      case ChangeType.planner:
      case ChangeType.dayReset:
      case ChangeType.batch:
        _load();
      default:
        break;
    }
  }

  /// Un creneau vide se remplit d'un tap. Un creneau qui porte un repas prevu
  /// s'ouvre d'abord : le plat que Ryze a prevu se lisait nulle part dans le
  /// journal, le tap proposait seulement d'ajouter un aliment par-dessus.
  /// Ce qu'un créneau prévoit : le plat, ce qu'il pèse, et de quoi le valider
  /// ou le retirer. Le « + » de la ligne, lui, ajoute sans passer par là.
  Future<void> _openPlanned(WeekSlot slot) async {
    await MealSheet.show(context, day: _date, slot: slot, onAdd: () => _add(slot));
    if (mounted) await _load();
  }

  Future<void> _load() async {
    final day = await DayMeals.forDate(_date);
    if (mounted) setState(() => _day = day);
  }

  /// The hours the user set for their reminders are the hours their day has.
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final past = _scroll.offset > context.vw(26);
    if (past != _stuck) setState(() => _stuck = past);
  }

  Future<void> _checkAnalysis() async {
    if (!DayAnalysis.isOffered()) return;
    final found = await DayAnalysis.cached(date: _date);
    if (mounted && (found != null) != _analysisReady) {
      setState(() => _analysisReady = found != null);
    }
  }

  Future<void> _openAnalysis() async {
    await DayAnalysis.open(context, date: _date);
    if (mounted) await _checkAnalysis();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = NotificationService().getPreferences();
      if (mounted) setState(() => _prefs = prefs);
    } catch (_) {
      // the defaults of NotificationPreferences are used instead
    }
  }

  // ------------------------------------------------------------------ water

  Future<void> _setGlasses(int glasses) async {
    final gs = GlobalStateManager.instance;
    final current = (gs.currentWaterL / GlassRow.glassLitres).floor();
    if (glasses == current) return;

    if (glasses > current) {
      final ok = await WaterService.addWaterEntry(amount: 250, sourceType: 'glass');
      if (!mounted) return;
      if (ok) {
        RyzeUndo.show(
          context,
          message: 'undo_glass_added'.tr(_lang),
          undoLabel: 'undo'.tr(_lang),
          onUndo: () => _removeLastGlass(),
        );
      } else {
        RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
      }
      return;
    }

    // going down: drop the most recent entries until the level is reached
    var removed = 0;
    final target = glasses * 250;
    final entries = await WaterService.getTodayWaterEntries();
    entries.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    var total = entries.fold<int>(0, (s, e) => s + e.amount);
    for (final entry in entries) {
      if (total <= target) break;
      final ok = await WaterService.deleteWaterEntry(entry.id, amountToRemove: entry.amount);
      if (!ok) break;
      total -= entry.amount;
      removed++;
    }
    if (!mounted || removed == 0) return;
    RyzeUndo.show(
      context,
      message: 'undo_glass_removed'.tr(_lang),
      undoLabel: 'undo'.tr(_lang),
      onUndo: () async {
        for (var i = 0; i < removed; i++) {
          await WaterService.addWaterEntry(amount: 250, sourceType: 'glass');
        }
      },
    );
  }

  Future<void> _removeLastGlass() async {
    final entries = await WaterService.getTodayWaterEntries();
    if (entries.isEmpty) return;
    entries.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    await WaterService.deleteWaterEntry(entries.first.id, amountToRemove: entries.first.amount);
  }

  Future<void> _otherAmount() async {
    final ml = await showRyzeSheet<int>(
      context,
      title: 'nutri_water'.tr(_lang),
      subtitle: 'water_other'.tr(_lang),
      builder: (context) => Wrap(
        spacing: context.vw(2),
        runSpacing: context.vw(2),
        children: [
          for (final amount in [250, 500, 750, 1000])
            _Chip(
              label: amount >= 1000 ? '1 L' : '${amount ~/ 10} cl',
              onTap: () => Navigator.pop(context, amount),
            ),
          // L'objectif n'était réglable nulle part : il l'est ici, là où on
          // regarde déjà ses verres.
          _Chip(
            label: 'water_goal_edit'.tr(_lang),
            onTap: () => Navigator.pop(context, -1),
          ),
        ],
      ),
    );
    if (ml == null || !mounted) return;
    if (ml < 0) {
      await _waterGoal();
      return;
    }
    final ok = await WaterService.addWaterEntry(amount: ml, sourceType: ml == 250 ? 'glass' : 'manual');
    if (!mounted) return;
    if (ok) {
      RyzeFeedback.success();
      RyzeUndo.show(context, message: 'undo_glass_added'.tr(_lang), undoLabel: 'undo'.tr(_lang), onUndo: _removeLastGlass);
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
    }
  }

  /// Combien on veut boire par jour. Enregistré dans `water_entries` par le
  /// même service que le reste de l'eau, donc l'app entière suit.
  Future<void> _waterGoal() async {
    final current = GlobalStateManager.instance.waterGoalL;
    final ml = await showRyzeSheet<int>(
      context,
      title: 'nutri_water'.tr(_lang),
      subtitle: 'water_goal_edit'.tr(_lang),
      builder: (context) => Wrap(
        spacing: context.vw(2),
        runSpacing: context.vw(2),
        children: [
          for (final litres in [1.0, 1.5, 2.0, 2.5, 3.0, 3.5])
            _Chip(
              label: '${NumberFormat.decimalPattern(_lang).format(litres)} L',
              selected: (current - litres).abs() < 0.05,
              onTap: () => Navigator.pop(context, (litres * 1000).round()),
            ),
        ],
      ),
    );
    if (ml == null || !mounted) return;
    final ok = await WaterService.updateDailyWaterGoal(ml);
    if (!mounted) return;
    if (ok) {
      RyzeFeedback.confirm();
      GlobalStateManager.instance.updateGoals(waterGoalL: ml / 1000);
      setState(() {});
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
    }
  }

  // ------------------------------------------------------------------ meals

  /// One sheet: what the user eats again at this meal, then the five ways to
  /// describe something new. The write is the journal's own, through
  /// [FoodAddFlow], so nothing downstream changes.
  Future<void> _add(WeekSlot slot) async {
    final mealName = 'meal_name_${slot.name}'.tr(_lang);
    await AddFoodSheet.show(
      context,
      mealName: mealName,
      title: mealName,
      date: _date,
      onAdded: (item) {
        if (!mounted) return;
        RyzeFeedback.success();
        RyzeUndo.show(
          context,
          message: 'undo_item_added'.tr(_lang).replaceAll('{name}', item.name),
          undoLabel: 'undo'.tr(_lang),
          onUndo: () async {
            final id = await FoodEntriesService.findLastEntryId(
              userId: Supabase.instance.client.auth.currentUser?.id ?? '',
              name: item.name,
              onDate: _date,
            );
            if (id != null) await FoodEntriesService.removeFoodEntry(id);
            _load();
          },
        );
        _load();
      },
    );
  }

  /// Taper un aliment enregistré : refixer ce qu'il pesait. Les calories et
  /// les macros suivent au prorata, du côté du service.
  Future<void> _editItem(WeekSlot slot, nutrition.FoodItem item) async {
    if (item.id == null) return;
    final parts = item.portion.trim().split(RegExp(r'\s+'));
    final current = double.tryParse(parts.first.replaceAll(',', '.')) ?? 100;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'g';
    // Les portions plausibles pour cet aliment, plus celle qui est enregistrée
    // si elle n'y figure pas : on doit toujours pouvoir revenir en arrière.
    final steps = <double>{...RyzePortions.presets(unit: unit, reference: current), current}.toList()..sort();

    final chosen = await showRyzeSheet<double>(
      context,
      title: item.name,
      subtitle: 'nutri_fix_portion'.tr(_lang),
      builder: (context) => Wrap(
        spacing: context.vw(2),
        runSpacing: context.vw(2),
        children: [
          for (final value in steps)
            _Chip(
              label: RyzePortions.label(value, unit, _lang),
              selected: (value - current).abs() < 0.05,
              onTap: () => Navigator.pop(context, value),
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
            consumedAt: _date,
          );
        },
      );
    } else {
      RyzeUndo.failed(context, message: 'undo_offline'.tr(_lang));
    }
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

  // ------------------------------------------------------------------- page

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gs = GlobalStateManager.instance;
    final day = _day;
    final numbers = NumberFormat.decimalPattern(lang);
    final calories = gs.currentCalories.round();
    final goal = gs.calorieGoal.round();
    final remaining = goal - calories;
    final gutter = context.vw(5.1);

    return Stack(
      children: [
        ListView(
          controller: _scroll,
        padding: EdgeInsets.fromLTRB(gutter, context.vw(2), gutter, 132),
        children: [
          PopIn(
            delay: const Duration(milliseconds: 60),
            dy: 8,
            child: DayInstrument(
              lang: lang,
              lead: remaining < 0 ? 'nutri_over_goal'.tr(lang) : (remaining == 0 ? 'nutri_goal_met'.tr(lang) : 'nutri_left_today'.tr(lang)),
              unit: 'nutri_kcal'.tr(lang),
              eatenLabel: 'nutri_eaten'.tr(lang).replaceAll('{n}', numbers.format(calories)),
              goalLabel: 'nutri_goal'.tr(lang).replaceAll('{n}', numbers.format(goal)),
              calories: calories,
              calorieGoal: goal,
              shown: _shown,
              macros: [
                MacroRail(label: 'nutri_proteins'.tr(lang), value: gs.currentProteins, goal: gs.proteinGoal, shown: _shown),
                MacroRail(label: 'nutri_carbs'.tr(lang), value: gs.currentCarbs, goal: gs.carbsGoal, shown: _shown),
                MacroRail(label: 'nutri_fats'.tr(lang), value: gs.currentFats, goal: gs.fatGoal, shown: _shown),
              ],
            ),
          ),
          SizedBox(height: context.vw(7)),
          PopIn(
            delay: const Duration(milliseconds: 320),
            dy: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BlockHeader(
                  title: 'nutri_water'.tr(lang),
                  trailing: '${_litres(gs.currentWaterL, lang)} ${'nutri_water_of'.tr(lang).replaceAll('{n}', _litres(gs.waterGoalL, lang))}',
                ),
                SizedBox(height: context.vw(2.6)),
                GlassRow(
                  litres: gs.currentWaterL,
                  goalLitres: gs.waterGoalL,
                  shown: _shown,
                  onSet: _setGlasses,
                  onOther: _otherAmount,
                ),
              ],
            ),
          ),
          SizedBox(height: context.vw(7)),
          PopIn(
            delay: const Duration(milliseconds: 500),
            dy: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BlockHeader(
                  title: 'nutri_meals'.tr(lang),
                  trailing: day == null ? '' : '${day.doneCount} / ${day.total}',
                ),
                SizedBox(height: context.vw(1)),
                if (day != null)
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
                    onOpen: _openPlanned,
                    onRemoveItem: _removeItem,
                    onEditItem: _editItem,
                  ),
              ],
            ),
          ),
          // Le soir, quand la journée a assez servi : la lecture du coach.
          // L'accueil l'a déjà proposée une fois ; celle-ci est là pour qui
          // revient dans son journal.
          if (DayAnalysis.isOffered()) ...[
            SizedBox(height: context.vw(7)),
            PopIn(
              delay: const Duration(milliseconds: 640),
              dy: 8,
              child: DayAnalysisRow(lang: lang, hasAnalysis: _analysisReady, onTap: _openAnalysis),
            ),
          ],
        ],
        ),

        // Le total revient dès que l'instrument a quitté le haut :
        // on descend dans ses repas justement pour décider quoi manger.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: StickyTotal(
            shown: _stuck,
            lead: remaining < 0
                ? 'nutri_over_goal'.tr(lang)
                : (remaining == 0 ? 'nutri_goal_met'.tr(lang) : 'nutri_left_today'.tr(lang)),
            value: numbers.format(remaining.abs()),
            unit: 'nutri_kcal'.tr(lang),
            fraction: goal > 0 ? calories / goal : 0,
          ),
        ),
      ],
    );
  }

  String _litres(double l, String lang) => NumberFormat.decimalPattern(lang).format(double.parse(l.toStringAsFixed(2)));
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
        Text(trailing, style: RyzeText.body(context, 3.2, color: RyzeColors.mute)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.selected = false});

  final String label;
  final VoidCallback onTap;

  /// La valeur en cours, pour qu'on voie ce qu'on est en train de changer.
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
