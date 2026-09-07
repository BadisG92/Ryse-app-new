import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'macro_rail.dart';
import 'motion.dart';
import 'tokens.dart';
import 'type.dart';
import '../onboarding/widgets/pickers.dart';

/// The one number of the day, and how far it is of its goal.
///
/// What is left of the calorie goal in Archivo, an amber gauge under it, and
/// what has been eaten against the target. Amber is the progress the app gives
/// back, which is why the fill is amber and nothing else on the page is.
///
/// Nutrition adds the three macro rails under the gauge; the home does not,
/// because it has its tiles instead. Both read the same widget so the figure
/// can never disagree with itself between two screens.
class DayInstrument extends StatelessWidget {
  const DayInstrument({
    super.key,
    required this.lead,
    required this.unit,
    required this.eatenLabel,
    required this.goalLabel,
    required this.calories,
    required this.calorieGoal,
    required this.shown,
    this.macros,
  });

  /// The line above the figure: what is left, over the goal, or goal reached.
  final String lead;
  final String unit;
  final String eatenLabel;
  final String goalLabel;

  final int calories;
  final int calorieGoal;

  /// False before the entry: the figure opens at zero and rolls up.
  final bool shown;

  /// Protein, carbs and fat, in that order, when the surface wants them.
  final List<MacroRail>? macros;

  @override
  Widget build(BuildContext context) {
    final remaining = calorieGoal - calories;
    final numbers = NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode);
    // the goal met exactly deserves the words, not a giant zero
    final showFigure = remaining != 0;
    final figure = numbers.format(remaining.abs());
    final shape = figure.replaceAll(RegExp(r'\d'), '0');
    final fraction = calorieGoal > 0 ? (calories / calorieGoal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lead, style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
        if (showFigure) ...[
          SizedBox(height: context.vw(0.5)),
          // Hauteur figée : l'odomètre reconstruit ses colonnes à chaque
          // image, et une rangée alignée sur la ligne de base recalculerait
          // sa hauteur autant de fois, faisant trembler la page entière.
          SizedBox(
            height: context.vw(15.4) * 1.06,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // the odometer retargets within one shape; a figure that gains or
                // loses a digit is swapped rather than spun through a hundred turns
                KeyedSubtree(
                  key: ValueKey(shape),
                  child: RollingNumber(
                    shown ? figure : shape,
                    style: RyzeText.display(context, 15.4, height: 1),
                    duration: RyzeDurations.advance,
                  ),
                ),
                SizedBox(width: context.vw(2.4)),
                Padding(
                  padding: EdgeInsets.only(bottom: context.vw(1.5)),
                  child: Text(unit, style: RyzeText.body(context, 4.2, weight: FontWeight.w600, color: RyzeColors.mute)),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: context.vw(3.1)),
        SizedBox(
          height: 10,
          child: Stack(
            children: [
              Container(decoration: BoxDecoration(color: RyzeColors.idle, borderRadius: BorderRadius.circular(RyzeRadius.pill))),
              FractionallySizedBox(
                widthFactor: shown ? fraction : 0,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: RyzeDurations.fill,
                  curve: RyzeCurves.out,
                  decoration: BoxDecoration(color: RyzeColors.acc, borderRadius: BorderRadius.circular(RyzeRadius.pill)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.vw(1.5)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(eatenLabel, style: _small(context)),
            Text(goalLabel, style: _small(context)),
          ],
        ),
        if (macros != null) ...[
          SizedBox(height: context.vw(4.1)),
          ...macros!,
        ],
      ],
    );
  }

  TextStyle _small(BuildContext context) =>
      RyzeText.body(context, 3.2, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
