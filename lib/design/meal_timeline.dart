import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../components/weekly_planner/week_strip.dart';
import '../models/nutrition_models.dart' as nutrition;
import '../onboarding/widgets/onb_widgets.dart';
import '../services/day_meals.dart';
import 'feedback.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';

/// The day's meals as one line, not a stack of cards.
///
/// A rail runs down the left, a dot per meal in the three states of the
/// system, and each row carries its real hour, what is in it, and what it
/// weighs. A meal that has something opens in place; an empty one goes
/// straight to adding. Nothing here pushes a screen the user did not ask for.
class MealTimeline extends StatelessWidget {
  const MealTimeline({
    super.key,
    required this.day,
    required this.labelOf,
    required this.hourOf,
    required this.plannedPrefix,
    required this.nothingLogged,
    required this.addLabel,
    required this.open,
    required this.onToggle,
    required this.onAdd,
    required this.onRemoveItem,
    this.onEditItem,
  });

  final DayMeals day;

  /// The meal's name in the user's language.
  final String Function(WeekSlot slot) labelOf;

  /// The hour to show when nothing has been eaten yet: the one the user set in
  /// their reminders.
  final String Function(WeekSlot slot) hourOf;

  final String plannedPrefix;
  final String nothingLogged;
  final String addLabel;

  final Set<WeekSlot> open;
  final ValueChanged<WeekSlot> onToggle;
  final ValueChanged<WeekSlot> onAdd;
  final void Function(WeekSlot slot, nutrition.FoodItem item) onRemoveItem;

  /// Taper un aliment déjà enregistré : corriger ce qu'il pesait. Absent
  /// quand la journée est en lecture seule.
  final void Function(WeekSlot slot, nutrition.FoodItem item)? onEditItem;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: context.vw(2.8),
          top: context.vw(4.1),
          bottom: context.vw(5.6),
          width: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(color: RyzeColors.line, borderRadius: BorderRadius.circular(1)),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final slot in DayMeals.order)
              _MealRow(
                meal: day[slot],
                label: labelOf(slot),
                hour: day[slot].at != null ? '${day[slot].at!.hour} h ${day[slot].at!.minute.toString().padLeft(2, '0')}' : hourOf(slot),
                plannedPrefix: plannedPrefix,
                nothingLogged: nothingLogged,
                addLabel: addLabel,
                open: open.contains(slot),
                onToggle: () => onToggle(slot),
                onAdd: () => onAdd(slot),
                onRemoveItem: (item) => onRemoveItem(slot, item),
                onEditItem: onEditItem == null ? null : (item) => onEditItem!(slot, item),
              ),
          ],
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.label,
    required this.hour,
    required this.plannedPrefix,
    required this.nothingLogged,
    required this.addLabel,
    required this.open,
    required this.onToggle,
    required this.onAdd,
    required this.onRemoveItem,
    this.onEditItem,
  });

  final DayMeal meal;
  final String label;
  final String hour;
  final String plannedPrefix;
  final String nothingLogged;
  final String addLabel;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final ValueChanged<nutrition.FoodItem> onRemoveItem;
  final ValueChanged<nutrition.FoodItem>? onEditItem;

  @override
  Widget build(BuildContext context) {
    final done = meal.isDone;
    final planned = meal.state == SlotState.planned;
    final description = done
        ? meal.summary
        : (meal.plannedName != null && meal.plannedName!.isNotEmpty ? '$plannedPrefix · ${meal.plannedName}' : nothingLogged);

    return Padding(
      padding: EdgeInsets.only(left: context.vw(9.2), bottom: context.vw(1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -context.vw(8.2),
            top: context.vw(4.6),
            child: _Dot(done: done, planned: planned),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Pressable(
                onTap: () {
                  if (done) {
                    RyzeFeedback.select();
                    onToggle();
                  } else {
                    onAdd();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.vw(3.1)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: RyzeText.body(context, 4, weight: FontWeight.w600, color: done || planned ? RyzeColors.ink : RyzeColors.mute),
                                  ),
                                ),
                                SizedBox(width: context.vw(1.8)),
                                Text(hour, style: RyzeText.body(context, 3.1, color: RyzeColors.mute2).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                              ],
                            ),
                            SizedBox(height: context.vw(0.5)),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RyzeText.body(context, 3.2, color: RyzeColors.mute),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.vw(2.6)),
                      if (done) ...[
                        Text.rich(
                          TextSpan(
                            style: RyzeText.body(context, 3.5, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            children: [
                              TextSpan(text: '${meal.calories}'),
                              TextSpan(text: ' kcal', style: RyzeText.body(context, 3.2, color: RyzeColors.mute)),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: open ? 0.25 : 0,
                          duration: RyzeDurations.tap,
                          curve: RyzeCurves.out,
                          child: Icon(LucideIcons.chevronRight, size: 16, color: RyzeColors.mute2),
                        ),
                      ] else
                        _AddButton(onTap: onAdd),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: RyzeDurations.enter,
                curve: RyzeCurves.out,
                alignment: Alignment.topCenter,
                // Ouvert, la rangée montre ce qu'elle contient et propose
                // toujours d'ajouter : même sans aucun aliment, elle ne doit
                // pas être un cul-de-sac.
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in meal.logged?.items ?? const [])
                            _ItemRow(
                              item: item,
                              onRemove: () => onRemoveItem(item),
                              onEdit: onEditItem == null ? null : () => onEditItem!(item),
                            ),
                          Padding(
                            padding: EdgeInsets.only(top: context.vw(2.3), bottom: context.vw(1.5)),
                            child: OnbButton(label: addLabel, ghost: true, onPressed: onAdd),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Free, planned, done: the three states of the system, on the rail.
class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.planned});

  final bool done;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: RyzeDurations.fill,
      curve: RyzeCurves.out,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: done ? RyzeColors.ink : (planned ? RyzeColors.surf : RyzeColors.paper),
        shape: BoxShape.circle,
        border: Border.all(color: done || planned ? RyzeColors.ink : RyzeColors.idle, width: 2),
      ),
      child: done ? Icon(LucideIcons.check, size: 9, color: RyzeColors.surf) : null,
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: RyzeColors.mute2, width: 1.4),
        ),
        child: Icon(LucideIcons.plus, size: 17, color: RyzeColors.mute),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onRemove, this.onEdit});

  final nutrition.FoodItem item;
  final VoidCallback onRemove;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.vw(2.3)),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: RyzeColors.line))),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: onEdit,
              child: Text.rich(
              TextSpan(
                style: RyzeText.body(context, 3.5),
                children: [
                  TextSpan(text: item.name),
                  if (item.portion.isNotEmpty)
                    TextSpan(text: ' · ${item.portion}', style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: context.vw(2.6)),
          Text(
            '${item.calories} kcal',
            style: RyzeText.body(context, 3.3, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Pressable(
            onTap: onRemove,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(LucideIcons.x, size: 15, color: RyzeColors.mute2),
            ),
          ),
        ],
      ),
    );
  }
}
