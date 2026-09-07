import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../components/ui/global_progress_models.dart';
import '../../design/design.dart';
import '../../services/unit_service.dart';

/// La courbe du poids : les pesées réelles, la tendance par-dessus, la cible.
///
/// L'ancienne carte ne traçait qu'une moyenne glissante sur sept points. Elle
/// calmait le bruit — c'est bien — mais le chiffre affiché au-dessus ne se
/// trouvait alors nulle part sur la courbe. Ici les deux coexistent : les
/// pesées en points clairs, la tendance en encre, et le grand chiffre est
/// bien le dernier point. La cible est une ligne ambre en pointillés : c'est
/// ce que Ryze rend, pas ce que l'utilisateur a fait.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.progress, required this.animate});

  final WeightProgress progress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final units = UnitService.instance;
    final entries = [...progress.entries]..sort((a, b) => a.date.compareTo(b.date));
    if (entries.length < 2) return const SizedBox.shrink();

    final values = [for (final e in entries) units.displayWeight(e.weight)];
    final target = units.displayWeight(progress.targetWeight);
    final trend = _trend(values);

    final lo = math.min(values.reduce(math.min), target);
    final hi = math.max(values.reduce(math.max), target);
    final pad = math.max((hi - lo) * 0.18, 0.6);

    return SizedBox(
      height: context.vw(38),
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max((hi + pad - lo + pad) / 3, 0.5),
            getDrawingHorizontalLine: (_) => const FlLine(color: RyzeColors.idle, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: context.vw(10),
                getTitlesWidget: (value, meta) => Text(
                  value.round().toString(),
                  style: RyzeText.body(context, 2.6, color: RyzeColors.mute2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: context.vw(6.5),
                interval: math.max((entries.length - 1) / 3, 1),
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  final d = entries[i].date;
                  return Padding(
                    padding: EdgeInsets.only(top: context.vw(1)),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: RyzeText.body(context, 2.6, color: RyzeColors.mute2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target,
                color: RyzeColors.acc,
                strokeWidth: 1.5,
                dashArray: const [5, 4],
              ),
            ],
          ),
          lineBarsData: [
            // les pesées telles quelles, discrètes
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: false,
              color: RyzeColors.idle,
              barWidth: 1,
              dotData: FlDotData(
                show: entries.length <= 40,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 2, color: RyzeColors.line, strokeWidth: 0),
              ),
            ),
            // la tendance, qui est ce qu'on lit
            LineChartBarData(
              spots: [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i])],
              isCurved: true,
              curveSmoothness: 0.25,
              color: RyzeColors.ink,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: RyzeColors.ink.withValues(alpha: 0.06)),
            ),
          ],
        ),
        duration: animate ? RyzeDurations.fill : Duration.zero,
        curve: RyzeCurves.out,
      ),
    );
  }

  /// Moyenne glissante centrée sur cinq points : assez pour calmer une pesée
  /// du matin après un repas salé, pas assez pour effacer une vraie inflexion.
  static List<double> _trend(List<double> v) {
    const window = 5;
    return [
      for (var i = 0; i < v.length; i++)
        () {
          final from = math.max(0, i - window ~/ 2);
          final to = math.min(v.length, i + window ~/ 2 + 1);
          var sum = 0.0;
          for (var j = from; j < to; j++) {
            sum += v[j];
          }
          return sum / (to - from);
        }(),
    ];
  }
}
