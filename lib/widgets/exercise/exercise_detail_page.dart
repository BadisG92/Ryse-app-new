import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/exercise_ai_analysis_widget.dart';
import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../../services/workout_cache_service.dart';

/// La progression d'un exercice : la courbe, trois chiffres, l'analyse.
///
/// C'est la porte de l'analyse des performances, ouverte depuis trois
/// endroits : le nom d'un exercice en séance, « Tes exercices » dans
/// l'historique, et le menu d'un exercice. La courbe suit la meilleure série
/// de chaque séance — pas le volume, qui monte quand on ajoute des séries
/// même si on ne progresse pas.
class ExerciseDetailPage extends StatefulWidget {
  final String exerciseName;

  const ExerciseDetailPage({
    super.key,
    required this.exerciseName,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  static const List<String> _periodKeys = ['this_month', 'three_months', 'six_months'];
  static const List<int> _periodMonths = [1, 3, 6];

  int _period = 0;
  Map<String, dynamic>? _exercise;
  String? _localizedName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _localizedName = widget.exerciseName;
          _loading = false;
        });
      }
      return;
    }
    try {
      final data = await WorkoutCacheService.getExerciseDetails(userId, widget.exerciseName);
      final name = await WorkoutCacheService.getLocalizedExerciseName(widget.exerciseName);
      if (!mounted) return;
      setState(() {
        _exercise = data;
        _localizedName = name;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _localizedName = widget.exerciseName;
          _loading = false;
        });
      }
    }
  }

  DateTime get _from => DateTime.now().subtract(Duration(days: 31 * _periodMonths[_period]));

  /// Les séances de la période : une date, la meilleure série de ce jour.
  List<({DateTime date, double best})> get _points {
    final raw = (_exercise?['raw'] as List?) ?? const [];
    final from = _from;
    final out = <({DateTime date, double best})>[];
    for (final e in raw) {
      final d = DateTime.tryParse('${e['date']}');
      if (d == null || d.isBefore(from)) continue;
      out.add((date: d, best: ((e['best'] as num?) ?? 0).toDouble()));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  List<({DateTime date, double weight, int reps})> get _sessions {
    final raw = (_exercise?['sessionsFull'] as List?) ?? const [];
    final from = _from;
    final out = <({DateTime date, double weight, int reps})>[];
    for (final e in raw) {
      final d = DateTime.tryParse('${e['date']}');
      if (d == null || d.isBefore(from)) continue;
      out.add((date: d, weight: ((e['weight'] as num?) ?? 0).toDouble(), reps: ((e['reps'] as num?) ?? 0).toInt()));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final name = _localizedName ?? widget.exerciseName;
    final points = _points;

    return Scaffold(
      backgroundColor: RyzeColors.paper,
      body: Stack(
        children: [
          const OnbBackground(scene: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, context.vw(2.6)),
                  child: Row(
                    children: [
                      Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: context.vw(9.7),
                          height: context.vw(9.7),
                          decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
                          child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
                        ),
                      ),
                      SizedBox(width: context.vw(3.1)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
                            Text('exercise_details'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2))
                      : ListView(
                          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 132),
                          children: [
                            RyzeSegmented(
                              labels: [for (final k in _periodKeys) k.tr(lang)],
                              index: _period,
                              onChanged: (i) => setState(() => _period = i),
                            ),
                            SizedBox(height: context.vw(5.1)),
                            _stats(context, lang, points),
                            SizedBox(height: context.vw(5.1)),
                            _chart(context, lang, points),
                            SizedBox(height: context.vw(5.1)),
                            _analysis(),
                            SizedBox(height: context.vw(5.1)),
                            _history(context, lang),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context, String lang, List<({DateTime date, double best})> points) {
    final units = UnitService.instance;
    String best = '—';
    String progress = '—';
    if (points.isNotEmpty) {
      final top = points.map((p) => p.best).reduce(math.max);
      best = top > 0 ? units.formatWeight(top, decimals: top % 1 == 0 ? 0 : 1) : '—';

      // La progression compare le meilleur du premier jour au meilleur du
      // dernier : deux séances le même jour ne comptent pas deux fois.
      final byDay = <String, double>{};
      for (final p in points) {
        final key = '${p.date.year}-${p.date.month}-${p.date.day}';
        byDay[key] = math.max(byDay[key] ?? 0, p.best);
      }
      if (byDay.length > 1) {
        final days = byDay.keys.toList()..sort();
        final delta = byDay[days.last]! - byDay[days.first]!;
        final shown = units.displayWeight(delta.abs());
        final s = shown % 1 == 0 ? shown.toStringAsFixed(0) : shown.toStringAsFixed(1);
        progress = delta == 0 ? '—' : '${delta > 0 ? '+' : '−'}$s ${units.weightUnit}';
      }
    }
    return Row(
      children: [
        Expanded(child: _Stat(value: '${points.length}', label: 'sessions'.tr(lang))),
        Expanded(child: _Stat(value: progress, label: 'progression'.tr(lang), amber: progress.startsWith('+'))),
        Expanded(child: _Stat(value: best, label: 'best_set'.tr(lang))),
      ],
    );
  }

  Widget _chart(BuildContext context, String lang, List<({DateTime date, double best})> points) {
    if (points.length < 2) {
      return Container(
        height: context.vw(38),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Text('no_sessions_in_period'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
      );
    }
    final units = UnitService.instance;
    final values = [for (final p in points) units.displayWeight(p.best)];
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final pad = math.max((maxY - minY) * 0.2, maxY * 0.05 + 1);

    return Container(
      height: context.vw(46),
      padding: EdgeInsets.fromLTRB(context.vw(2.6), context.vw(4.6), context.vw(4.1), context.vw(2.6)),
      decoration: BoxDecoration(
        color: RyzeColors.surf,
        borderRadius: BorderRadius.circular(RyzeRadius.md),
        border: Border.all(color: RyzeColors.line),
      ),
      child: LineChart(
        LineChartData(
          minY: math.max(0, minY - pad),
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max((maxY + pad - math.max(0, minY - pad)) / 3, 1),
            getDrawingHorizontalLine: (_) => const FlLine(color: RyzeColors.idle, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: context.vw(11),
                getTitlesWidget: (value, meta) => Text(
                  value.round().toString(),
                  style: RyzeText.body(context, 2.6, color: RyzeColors.mute2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: context.vw(7),
                interval: math.max((points.length - 1) / 3, 1),
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  final d = points[i].date;
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
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              curveSmoothness: 0.25,
              color: RyzeColors.ink,
              barWidth: 2.5,
              dotData: FlDotData(
                show: points.length <= 14,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 3, color: RyzeColors.surf, strokeWidth: 2, strokeColor: RyzeColors.ink),
              ),
              belowBarData: BarAreaData(show: true, color: RyzeColors.acc.withValues(alpha: 0.18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysis() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();
    final history = (_exercise?['sessionHistory'] as List?) ?? const [];
    return ExerciseAiAnalysisWidget(
      exerciseName: _localizedName ?? widget.exerciseName,
      userId: userId,
      sessionHistory: history.cast<Map<String, dynamic>>(),
    );
  }

  Widget _history(BuildContext context, String lang) {
    final sessions = _sessions;
    final units = UnitService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('recent_sessions'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600)),
        SizedBox(height: context.vw(2.6)),
        if (sessions.isEmpty)
          Text('no_sessions_found'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute))
        else
          Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sessions.length && i < 20; i++)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
                    decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: RyzeColors.line))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${sessions[i].date.day}/${sessions[i].date.month}/${sessions[i].date.year % 100}',
                            style: RyzeText.body(context, 3.4, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                        Text(
                          sessions[i].weight > 0
                              ? '${_w(units.displayWeight(sessions[i].weight))} ${units.weightUnit} × ${sessions[i].reps}'
                              : '${sessions[i].reps} reps',
                          style: RyzeText.body(context, 3.6, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _w(double v) => v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.amber = false});

  final String value;
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: RyzeText.display(context, 6.2, weight: FontWeight.w600).copyWith(
            color: amber ? RyzeColors.accInk : RyzeColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
      ],
    );
  }
}
