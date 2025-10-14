import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/workout_cache_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../components/exercise_ai_analysis_widget.dart';

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
  String selectedPeriod = 'this_month';
  Map<String, dynamic>? exercise; // données dynamiques
  String? localizedExerciseName; // nom localisé de l'exercice
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        exercise = {
          'name': widget.exerciseName,
          'muscleGroup': '',
          'sessions': 0,
          'progress': '',
          'lastWeight': 'N/A',
          'data': <double>[],
          'sessionHistory': <Map<String, dynamic>>[],
        };
        localizedExerciseName = widget.exerciseName;
      });
      return;
    }

    // Utilise le service de cache optimisé
    final exerciseData = await WorkoutCacheService.getExerciseDetails(userId, widget.exerciseName);

    // Récupérer le nom localisé de façon optimisée
    localizedExerciseName = await WorkoutCacheService.getLocalizedExerciseName(widget.exerciseName);

    setState(() {
      exercise = exerciseData;
    });
  }

  void _loadOld() async {
    // Ancienne méthode conservée pour référence - à supprimer plus tard
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final rows = await client
        .from('workout_set_history')
        .select('history_session_id, performed_at, weight, reps, best_set')
        .eq('user_id', userId)
        .eq('exercise_name', widget.exerciseName)
        .order('performed_at', ascending: true);

    // Agréger par session: garder la best_set si dispo; sinon meilleur score (weight*reps ou reps)
    final Map<String, Map<String, dynamic>> bySession = {};
    if (rows is List) {
      for (final r in rows) {
        final sid = r['history_session_id']?.toString() ?? '';
        if (sid.isEmpty) continue;
        final performedAt = DateTime.tryParse(r['performed_at']?.toString() ?? '');
        final weight = (r['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (r['reps'] as int?) ?? 0;
        final isBest = (r['best_set'] as bool?) ?? false;

        final current = bySession[sid] ?? {
          'date': performedAt,
          'weight': 0.0,
          'reps': 0,
          'score': 0.0,
          'isBest': false,
          'totalVolume': 0.0,
        };

        final score = weight > 0 ? (weight * reps) : reps.toDouble();

        // Priorité à best_set; sinon meilleur score
        if (isBest || (!current['isBest'] && score > (current['score'] as double))) {
          current['date'] = performedAt ?? current['date'];
          current['weight'] = weight;
          current['reps'] = reps;
          current['score'] = score;
          current['isBest'] = isBest || current['isBest'];
          bySession[sid] = current;
        }

        // Cumuler le volume total de la séance (poids*reps si poids>0)
        if (weight > 0 && reps > 0) {
          current['totalVolume'] = (current['totalVolume'] as double) + (weight * reps);
          bySession[sid] = current;
        }
      }
    }

    final sessions = bySession.values
        .where((v) => v['date'] != null)
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    String _fmtKg(double w) {
      if (w <= 0) return '—';
      if ((w % 1).abs() < 1e-6) return '${w.toInt()} kg';
      return '${w.toStringAsFixed(1)} kg';
    }

    final List<double> bestSeries = [];
    final List<double> volumeSeries = [];
    final List<String> labels = [];
    final List<Map<String, dynamic>> history = [];
    for (final s in sessions) {
      final double w = (s['weight'] as double);
      final int r = (s['reps'] as int);
      // Meilleure série: valeur = poids si dispo, sinon reps
      bestSeries.add(w > 0 ? w : r.toDouble());
      // Volume total
      volumeSeries.add((s['totalVolume'] as double));
      final dt = s['date'] as DateTime;
      history.add({
        'date': dt.toIso8601String(),
        'weight': _fmtKg(w),
        'reps': '$r',
      });
      labels.add('${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}');
    }

    // Statistiques d'en-tête
    String lastWeightLabel = 'N/A';
    if (sessions.isNotEmpty) {
      final last = sessions.last;
      final lw = (last['weight'] as double);
      final lr = (last['reps'] as int);
      lastWeightLabel = lw > 0 ? _fmtKg(lw) : '${lr} reps';
    }

    setState(() {
      exercise = {
        'name': widget.exerciseName,
        'muscleGroup': '',
        'sessions': sessions.length,
        'progress': '',
        'lastWeight': lastWeightLabel,
        'data_best': bestSeries,
        'data_volume': volumeSeries,
        'labels': labels,
        'raw': sessions.map((s) => {
          'date': (s['date'] as DateTime).toIso8601String(),
          'best': ((s['weight'] as double) > 0 ? (s['weight'] as double) : (s['reps'] as int).toDouble()),
          'volume': (s['totalVolume'] as double),
        }).toList(),
        'sessionsFull': sessions
            .map((s) => {
                  'date': (s['date'] as DateTime).toIso8601String(),
                  'weight': (s['weight'] as double),
                  'reps': (s['reps'] as int),
                })
            .toList(),
        'sessionHistory': history.take(10).toList().reversed.toList(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExerciseTitle(),
                    const SizedBox(height: 16),
                    _buildPeriodFilter(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildProgressChart(),
                    const SizedBox(height: 16),
                    _buildAiAnalysis(),
                    const SizedBox(height: 24),
                    _buildSessionHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'exercise_details'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildExerciseTitle() {
    final exerciseName = localizedExerciseName ?? (exercise?['name'] ?? widget.exerciseName);
    
    // Calculer la taille de police dynamiquement pour limiter à 2 lignes
    double fontSize = 24;
    if (exerciseName.length > 40) {
      fontSize = 18; // Très long nom
    } else if (exerciseName.length > 25) {
      fontSize = 20; // Long nom
    } else if (exerciseName.length > 15) {
      fontSize = 22; // Nom moyen
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          (exercise?['muscleGroup'] ?? ''),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    final periodKeys = ['this_month', 'three_months', 'six_months'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Consumer<LocalizationService>(
        builder: (context, locService, _) => Row(
          children: periodKeys.map((periodKey) {
            final isSelected = periodKey == selectedPeriod;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedPeriod = periodKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    periodKey.tr(locService.currentLanguageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    // Points uniquement aux jours/mois avec séance; l'axe démarre au premier point et s'arrête au dernier
    final raw = (exercise?['raw'] ?? []) as List;
    if (raw.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: const Text('Pas de données', style: TextStyle(color: Color(0xFF64748B))),
      );
    }
    final List<Map<String, dynamic>> points = [];
    final now = DateTime.now();
    late DateTime periodStart;
    late DateTime periodEnd;
    if (selectedPeriod == 'this_month') {
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = DateTime(now.year, now.month + 1, 0);
    } else if (selectedPeriod == '3 mois') {
      periodStart = DateTime(now.year, now.month - 5, 1);
      periodEnd = DateTime(now.year, now.month + 1, 0);
    } else {
      periodStart = DateTime(now.year, 1, 1);
      periodEnd = DateTime(now.year, 12, 31);
    }
    for (final r in raw) {
      final dt = DateTime.tryParse(r['date'] as String? ?? '');
      if (dt == null) continue;
      if (dt.isBefore(periodStart) || dt.isAfter(periodEnd)) continue;
      points.add({'date': dt, 'val': (r['best'] as num).toDouble()});
    }
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            'no_sessions_in_period'.tr(locService.currentLanguageCode),
            style: const TextStyle(color: Color(0xFF64748B))
          ),
        ),
      );
    }
    points.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final DateTime axisStart = _dayOnly(points.first['date'] as DateTime);
    final DateTime axisEnd = _dayOnly(points.last['date'] as DateTime);
    // Agréger par jour et construire les barres visibles seulement aux jours avec séance
    final List<DateTime> xDates = [];
    final List<double> xVals = [];
    DateTime? lastDay;
    for (final p in points) {
      final d = _dayOnly(p['date'] as DateTime);
      final v = (p['val'] as double);
      if (lastDay != null && d.isAtSameMomentAs(lastDay)) {
        // même jour -> prendre le max
        final idx = xDates.length - 1;
        xVals[idx] = math.max(xVals[idx], v);
      } else {
        xDates.add(d);
        xVals.add(v);
        lastDay = d;
      }
    }

    // Préparer les données triées (barres de gauche à droite)
    final List<MapEntry<DateTime, double>> sorted = [
      for (int i = 0; i < xDates.length; i++) MapEntry(xDates[i], xVals[i])
    ]..sort((a, b) => a.key.compareTo(b.key));

    final int barCount = sorted.length;
    const double barWidth = 18;
    const double groupSpace = 12;

    // Construire les groupes, calculer le max pour l'axe Y
    final List<BarChartGroupData> groups = <BarChartGroupData>[];
    double maxY = 0;
    for (int i = 0; i < barCount; i++) {
      final double v = sorted[i].value;
      if (v > maxY) maxY = v;
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 0,
          barRods: [
            BarChartRodData(
              toY: v,
              width: barWidth,
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    final double niceMax = _niceMaxY(maxY);
    // Déterminer l'unité du tooltip (kg vs reps) selon la période
    final List<Map<String, dynamic>> sessionsFullForChart = (exercise?['sessionsFull'] as List? ?? [])
        .map((e) => {
              'date': DateTime.parse(e['date'] as String),
              'weight': (e['weight'] as num).toDouble(),
            })
        .where((e) => !(e['date'] as DateTime).isBefore(periodStart) && !(e['date'] as DateTime).isAfter(periodEnd))
        .toList();
    final bool chartUsesWeight = sessionsFullForChart.any((e) => (e['weight'] as double) > 0);

    final double totalWidth = groups.isEmpty
        ? 0
        : (groups.length * barWidth) + ((groups.length - 1) * groupSpace) + 32;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Text(
              'progression'.tr(locService.currentLanguageCode),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(MediaQuery.of(context).size.width, totalWidth),
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.start,
                      barGroups: groups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                          getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          ),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                              final d = sorted[idx].key;
                              final dd = d.day.toString().padLeft(2, '0');
                              final mm = d.month.toString().padLeft(2, '0');
                              final String label = '$dd/$mm';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  label,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: niceMax,
                      barTouchData: BarTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          tooltipMargin: 6,
                          getTooltipColor: (_) => const Color(0xFFF1F5F9),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final double v = rod.toY;
                            final String val = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
                            // Unité selon la période: kg s'il y a eu du poids >0, sinon reps
                            final unit = chartUsesWeight ? 'kg' : 'reps';
                            return BarTooltipItem(
                              '$val $unit',
                              const TextStyle(
                                color: Color(0xFF0B132B),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // Recalcule en fonction de la période sélectionnée
    final raw = (exercise?['raw'] ?? []) as List;
    if (raw.isEmpty) {
      return Row(
        children: [
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Expanded(child: _buildStatCard(
              icon: LucideIcons.calendar, 
              title: 'sessions'.tr(locService.currentLanguageCode), 
              value: '0'
            )),
          ),
          const SizedBox(width: 12),
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Expanded(child: _buildStatCard(
              icon: LucideIcons.trendingUp, 
              title: 'progression'.tr(locService.currentLanguageCode), 
              value: '—'
            )),
          ),
          const SizedBox(width: 12),
          Consumer<LocalizationService>(
            builder: (context, locService, _) => Expanded(child: _buildStatCard(
              icon: LucideIcons.award, 
              title: 'best_set'.tr(locService.currentLanguageCode), 
              value: 'N/A'
            )),
          ),
        ],
      );
    }

    DateTime now = DateTime.now();
    late DateTime start;
    late DateTime end;
    if (selectedPeriod == 'this_month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (selectedPeriod == '3 mois') {
      start = DateTime(now.year, now.month - 5, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
    }

    List<Map<String, dynamic>> period = raw
        .map((e) => {
              'date': DateTime.parse(e['date'] as String),
              'best': (e['best'] as num).toDouble(),
            })
        .where((e) => !(e['date'] as DateTime).isBefore(start) && !(e['date'] as DateTime).isAfter(end))
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Compter les sessions uniques (pas les jours uniques)
    final int sessionsCount = period.length;

    // Déterminer l'unité dominante sur la période (poids si >0 présent au moins une fois)
    final List<Map<String, dynamic>> sessionsFull = (exercise?['sessionsFull'] as List? ?? [])
        .map((e) => {
              'date': DateTime.parse(e['date'] as String),
              'weight': (e['weight'] as num).toDouble(),
              'reps': (e['reps'] as int),
            })
        .where((e) => !(e['date'] as DateTime).isBefore(start) && !(e['date'] as DateTime).isAfter(end))
        .toList();
    final bool usesWeight = sessionsFull.any((e) => (e['weight'] as double) > 0);

    String bestLabel = 'N/A';
    if (period.isNotEmpty) {
      final double best = period.map((e) => e['best'] as double).reduce((a, b) => a > b ? a : b);
      if (usesWeight) {
        bestLabel = (best % 1 == 0) ? '${best.toInt()} kg' : '${best.toStringAsFixed(1)} kg';
      } else {
        bestLabel = '${best.toInt()} reps';
      }
    }

    // Progression: meilleure_dernière_best - meilleure_première_best (cohérent avec le graphique)
    String progressLabel = '—';
    if (period.length >= 2) {
      // Grouper par jour et prendre la meilleure valeur de chaque jour (comme le graphique)
      final Map<String, double> bestByDay = {};
      for (final p in period) {
        final date = p['date'] as DateTime;
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final best = p['best'] as double;
        bestByDay[dayKey] = math.max(bestByDay[dayKey] ?? 0, best);
      }
      
      // Trier les jours et prendre le premier et le dernier
      final sortedDays = bestByDay.keys.toList()..sort();
      if (sortedDays.length >= 2) {
        final double first = bestByDay[sortedDays.first]!;
        final double last = bestByDay[sortedDays.last]!;
        final double diff = last - first;
        final String diffStr = diff == 0
            ? '0'
            : (diff % 1 == 0 ? (diff > 0 ? '+${diff.toInt()}' : '${diff.toInt()}') : (diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1)));
        progressLabel = diffStr + (usesWeight ? ' kg' : ' reps');
      }
    }

    return Row(
      children: [
        Consumer<LocalizationService>(
          builder: (context, locService, _) => Expanded(
            child: _buildStatCard(
              icon: LucideIcons.calendar,
              title: 'sessions'.tr(locService.currentLanguageCode),
              value: sessionsCount.toString(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Consumer<LocalizationService>(
          builder: (context, locService, _) => Expanded(
            child: _buildStatCard(
              icon: LucideIcons.trendingUp,
              title: 'progression'.tr(locService.currentLanguageCode),
              value: progressLabel,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Consumer<LocalizationService>(
          builder: (context, locService, _) => Expanded(
            child: _buildStatCard(
              icon: LucideIcons.award,
              title: 'best_set'.tr(locService.currentLanguageCode),
              value: bestLabel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value}) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildValueWithDelta(value),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Rend la valeur avec pourcentage éventuel (en plus petit et grisé) 
  // Utilise RichText pour plus de fiabilité d'affichage
  Widget _buildValueWithDelta(String value) {
    final RegExp rx = RegExp(r"^(.*?)(?:\s*\(([-+]?\d+)%\))?$");
    final Match? m = rx.firstMatch(value);
    final String mainVal = (m?.group(1) ?? value).trim();
    final String? pct = m?.group(2);

    Color mainColor = const Color(0xFF0B132B);
    if (titleCaseEquals(value, '—') || value.trim().isEmpty) {
      mainColor = const Color(0xFF0B132B);
    } else if (value.trim().startsWith('+')) {
      mainColor = const Color(0xFF16A34A); // vert
    } else if (value.trim().startsWith('-')) {
      mainColor = const Color(0xFFDC2626); // rouge
    }

    // Séparer la valeur principale de l'unité (ex: "75 kg" -> "75" + "kg")
    final parts = mainVal.split(' ');
    if (parts.length >= 2) {
      final valueOnly = parts[0];
      final unit = parts.sublist(1).join(' ');
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: valueOnly,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
                if (pct != null) ...[
                  TextSpan(
                    text: ' ($pct%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mainColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Pas d'unité, utiliser l'ancien format
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: mainVal,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: mainColor,
              ),
            ),
            if (pct != null) ...[
              const WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(
                text: '(${pct}%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  bool titleCaseEquals(String a, String b) => a.toLowerCase() == b.toLowerCase();



  Widget _buildAiAnalysis() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();

    final sessionHistory = (exercise?['sessionHistory'] as List?) ?? [];

    // Afficher le widget dans tous les cas (il gère l'affichage selon le nombre de séances)
    return ExerciseAiAnalysisWidget(
      exerciseName: localizedExerciseName ?? widget.exerciseName,
      userId: userId,
      sessionHistory: sessionHistory.cast<Map<String, dynamic>>(),
    );
  }

  Widget _buildSessionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<LocalizationService>(
          builder: (context, locService, _) => Text(
            'recent_sessions'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildScrollableSessionTable(),
      ],
    );
  }

  Widget _buildScrollableSessionTable() {
    final maxSets = (exercise?['maxSets'] as int?) ?? 0;
    final sessionHistory = (exercise?['sessionHistory'] as List?) ?? [];
    
    // S'assurer qu'il y a toujours au moins une colonne même si maxSets = 0
    final displayMaxSets = math.max(maxSets, 1);
    
    if (sessionHistory.isEmpty) {
      return Consumer<LocalizationService>(
        builder: (context, locService, _) => Text(
          'no_sessions_found'.tr(locService.currentLanguageCode),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }


    return Row(
      children: [
        // Colonne Date fixe
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Date
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
              ),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'date'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            // Dates des séances
            ...sessionHistory.map((session) => Container(
              width: 100,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                _formatActualDate(session['date']),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            )),
          ],
        ),
        // Partie scrollable (Charge Max + toutes les séries)
        Expanded(
          child: SingleChildScrollView(
            controller: _tableScrollController,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header scrollable
                Row(
                  children: [
                    // Header Charge Max
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'max_weight'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Headers des séries
                    ...List.generate(displayMaxSets, (index) {
                      return Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'set_number'.tr(locService.currentLanguageCode)
                                .replaceAll('{number}', '${index + 1}'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // Lignes de données scrollables
                ...sessionHistory.map((session) {
                  final allSets = (session['allSets'] as List<String>?) ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Charge Max
                        Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            session['weight'] ?? '—',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Toutes les séries
                        ...List.generate(displayMaxSets, (seriesIndex) {
                          return Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              seriesIndex < allSets.length ? allSets[seriesIndex] : '—',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }




  String _formatActualDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double _getMinValue(List<dynamic> data) {
    if (data.isEmpty) return 0.0;
    double min = data[0].toDouble();
    for (var value in data) {
      final doubleValue = value.toDouble();
      if (doubleValue < min) {
        min = doubleValue;
      }
    }
    return min;
  }

  double _getMaxValue(List<dynamic> data) {
    if (data.isEmpty) return 0.0;
    double max = data[0].toDouble();
    for (var value in data) {
      final doubleValue = value.toDouble();
      if (doubleValue > max) {
        max = doubleValue;
      }
    }
    return max;
  }

  double _niceMaxY(double maxVal) {
    if (maxVal <= 0) return 10;
    final int rounded = ((maxVal / 5).ceil()) * 5;
    return rounded.toDouble();
  }

  String _monthAbbr(int m) {
    const abbr = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return abbr[(m - 1).clamp(0, 11)];
  }
} 
