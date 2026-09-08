import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../components/ui/global_progress_models.dart';
import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';

/// La courbe du poids : les pesees en encre, la cible en ambre, la tendance
/// en gris.
///
/// L'encre est ce que l'utilisateur a fait : ses pesees, telles quelles,
/// reliees en droites. La cible est une ligne ambre en pointilles, ce que
/// Ryze rend. La tendance (moyenne glissante sur cinq points) est en gris
/// clair et n'apparait qu'avec assez de pesees pour dire autre chose que la
/// moyenne : sur trois points elle n'etait qu'un trait plat, lu comme un
/// second objectif.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.progress, required this.animate});

  final WeightProgress progress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final units = UnitService.instance;
    final lang = LocalizationService.instance.currentLanguageCode;
    final entries = [...progress.entries]..sort((a, b) => a.date.compareTo(b.date));
    if (entries.length < 2) return const SizedBox.shrink();

    final values = [for (final e in entries) units.displayWeight(e.weight)];
    final target = units.displayWeight(progress.targetWeight);
    final trend = values.length >= _trendMin ? _trend(values) : null;

    final lo = math.min(values.reduce(math.min), target);
    final hi = math.max(values.reduce(math.max), target);
    final pad = math.max((hi - lo) * 0.18, 0.6);

    final chart = SizedBox(
      height: context.vw(38),
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max((hi + pad - lo + pad) / 3, 0.5),
            getDrawingHorizontalLine: (_) => FlLine(color: RyzeColors.idle, strokeWidth: 1),
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
            // la tendance dessous, en gris : ce que Ryze lit
            if (trend != null)
              LineChartBarData(
                spots: [for (var i = 0; i < trend.length; i++) FlSpot(i.toDouble(), trend[i])],
                isCurved: true,
                curveSmoothness: 0.25,
                color: RyzeColors.mute2,
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
              ),
            // les pesees en encre : ce que l'utilisateur a fait
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: false,
              color: RyzeColors.ink,
              barWidth: 2,
              dotData: FlDotData(
                show: entries.length <= 40,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 2.5, color: RyzeColors.ink, strokeWidth: 0),
              ),
            ),
          ],
        ),
        duration: animate ? RyzeDurations.fill : Duration.zero,
        curve: RyzeCurves.out,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chart,
        SizedBox(height: context.vw(2)),
        _ChartLegend(lang: lang, trend: trend != null),
      ],
    );
  }

  /// En dessous, la moyenne glissante ne dit que la moyenne.
  static const int _trendMin = 6;

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

/// Ce que chaque trait veut dire.
class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.lang, required this.trend});

  final String lang;
  final bool trend;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color, double h, [double w = 14]) =>
        Container(width: w, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h)));
    final style = RyzeText.body(context, 2.9, color: RyzeColors.mute2);
    Widget item(Widget mark, String label) =>
        Row(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(width: context.vw(1.5)), Text(label, style: style)]);
    return Wrap(
      spacing: context.vw(4.1),
      runSpacing: context.vw(1.5),
      children: [
        item(bar(RyzeColors.ink, 2.5), 'progress_legend_weight'.tr(lang)),
        item(
          Row(mainAxisSize: MainAxisSize.min, children: [bar(RyzeColors.acc, 1.5, 6), const SizedBox(width: 3), bar(RyzeColors.acc, 1.5, 6)]),
          'progress_legend_goal'.tr(lang),
        ),
        if (trend) item(bar(RyzeColors.mute2, 1.5), 'progress_legend_trend'.tr(lang)),
      ],
    );
  }
}
