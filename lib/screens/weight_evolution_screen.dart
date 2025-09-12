import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../components/ui/global_progress_models.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/weight_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';

class WeightEvolutionScreen extends StatefulWidget {
  const WeightEvolutionScreen({
    super.key,
  });

  @override
  State<WeightEvolutionScreen> createState() => _WeightEvolutionScreenState();
}

class _WeightEvolutionScreenState extends State<WeightEvolutionScreen> {
  String selectedPeriod = 'this_month';
  bool showAddWeight = false;
  final TextEditingController _weightController = TextEditingController();
  
  WeightProgress? _weightProgress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeightData();
  }

  // Filtrer les données selon la période sélectionnée
  List<WeightEntry> get _filteredEntries {
    if (_weightProgress?.entries == null) return [];
    
    final now = DateTime.now();
    final entries = _weightProgress!.entries;
    
    switch (selectedPeriod) {
      case 'this_month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return entries.where((entry) => entry.date.isAfter(monthAgo)).toList();
      case '3_months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return entries.where((entry) => entry.date.isAfter(threeMonthsAgo)).toList();
      case '6_months':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return entries.where((entry) => entry.date.isAfter(sixMonthsAgo)).toList();
      default:
        return entries;
    }
  }

  // Créer un WeightProgress filtré
  WeightProgress? get _filteredWeightProgress {
    if (_weightProgress == null) return null;
    
    final filteredEntries = _filteredEntries;
    if (filteredEntries.isEmpty) return _weightProgress;
    
    return WeightProgress(
      currentWeight: _weightProgress!.currentWeight,
      previousWeight: filteredEntries.length > 1 ? filteredEntries[filteredEntries.length - 2].weight : _weightProgress!.currentWeight,
      initialWeight: filteredEntries.first.weight,
      targetWeight: _weightProgress!.targetWeight,
      entries: filteredEntries,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final weightProgress = await WeightService.getWeightProgress();
      
      setState(() {
        _weightProgress = weightProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'weight_loading_error'.tr(LocalizationService.instance.currentLanguageCode).replaceAll('{error}', e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'evolution_poids'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              color: Color(0xFF0B132B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
              onPressed: () => setState(() => showAddWeight = !showAddWeight),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0B132B),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.x,
                        size: 48,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadWeightData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('retry'.tr(locService.currentLanguageCode)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeightData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Sélecteur de période (3 boutons) en premier
                        _buildPeriodSelector(),
                        
                        const SizedBox(height: 20),
                        
                        // 3 KPI en haut
                        _buildKPICards(),
                        
                        const SizedBox(height: 20),
                        
                        // Graphique 
                        _buildChart(),
                        
                        const SizedBox(height: 20),
                        
                        // Historique des pesées
                        _buildWeightHistory(),
                        
                        if (showAddWeight) ...[
                          const SizedBox(height: 20),
                          _buildAddWeightForm(),
                        ],
                        
                        const SizedBox(height: 100), // Espace pour la navigation
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  // 3 KPI Cards carrés et uniformes
  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'current_weight'.tr(LocalizationService.instance.currentLanguageCode),
            "${_filteredWeightProgress?.currentWeight.toStringAsFixed(1) ?? '0.0'}",
            "kg",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            'target_weight'.tr(LocalizationService.instance.currentLanguageCode), 
            "${_filteredWeightProgress?.targetWeight.toStringAsFixed(1) ?? '0.0'}",
            "kg",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            _getPeriodLabel(),
            "${(_filteredWeightProgress?.weightChange ?? 0) >= 0 ? '+' : ''}${_filteredWeightProgress?.weightChange.toStringAsFixed(1) ?? '0.0'}",
            "kg",
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    final locService = LocalizationService.instance;
    switch (selectedPeriod) {
      case 'this_month':
        return 'this_month_short'.tr(locService.currentLanguageCode);
      case '3_months':
        return '3_months'.tr(locService.currentLanguageCode);
      case '6_months':
        return '6_months'.tr(locService.currentLanguageCode);
      default:
        return 'period'.tr(locService.currentLanguageCode);
    }
  }

  Widget _buildKPICard(String title, String value, String unit) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B132B),
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
          ),
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

  // Sélecteur de période (identique à ExerciseDetailPage)
  Widget _buildPeriodSelector() {
    final locService = LocalizationService.instance;
    final periods = ['this_month', '3_months', '6_months'];
    final periodLabels = {
      'this_month': 'this_month'.tr(locService.currentLanguageCode),
      '3_months': '3_months'.tr(locService.currentLanguageCode),
      '6_months': '6_months'.tr(locService.currentLanguageCode),
    };
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  periodLabels[period] ?? period,
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
    );
  }

  // Graphique (identique à progression mais plus grand)
  Widget _buildChart() {
    // Même sans données de pesée, afficher le graphique avec la ligne d'objectif si elle existe
    final filteredProgress = _filteredWeightProgress;
    if (filteredProgress == null || filteredProgress.entries.isEmpty) {
      final targetWeight = _weightProgress?.targetWeight ?? 0.0;
      
      if (targetWeight <= 0) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'evolution'.tr(LocalizationService.instance.currentLanguageCode),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B132B),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'add_first_weight'.tr(LocalizationService.instance.currentLanguageCode),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      // Afficher un graphique avec seulement la ligne d'objectif
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'evolution'.tr(LocalizationService.instance.currentLanguageCode),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                _buildTargetOnlyChartData(targetWeight),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'evolution'.tr(LocalizationService.instance.currentLanguageCode),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: filteredProgress.entries.length > 10 
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(400, filteredProgress.entries.length * 50.0),
                    height: 250,
                    child: LineChart(_buildLineChartData(filteredProgress)),
                  ),
                )
              : LineChart(_buildLineChartData(filteredProgress)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildTargetOnlyChartData(double targetWeight) {
    // Graphique avec seulement la ligne d'objectif
    final minY = targetWeight - 5.0;
    final maxY = targetWeight + 5.0;
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2.0,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value == 0) return Text('start'.tr(LocalizationService.instance.currentLanguageCode), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
              if (value == 1) return Text('target'.tr(LocalizationService.instance.currentLanguageCode), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2.0,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      minX: 0,
      maxX: 1,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // Ligne d'objectif uniquement
        LineChartBarData(
          spots: [
            FlSpot(0, targetWeight),
            FlSpot(1, targetWeight),
          ],
          isCurved: false,
          color: const Color(0xFF64748B),
          barWidth: 2,
          dashArray: [8, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(WeightProgress weightProgress) {
    // Étendre seulement la ligne d'objectif, pas les données de poids
    final dataPointsCount = weightProgress.entries.length;
    final extendedWidth = dataPointsCount + 3; // Étendre un peu l'axe X pour la ligne d'objectif
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateYInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateXInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < weightProgress.entries.length) {
                // Seulement les dates réelles
                final entry = weightProgress.entries[index];
                return Text(
                  DateFormat('dd/MM').format(entry.date),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calculateYInterval(),
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (_shouldShowYLabel(value)) {
                return Text(
                  '${value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      // Gestion des tooltips améliorée
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => const Color(0xFF0B132B),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(12),
          tooltipMargin: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              // Afficher le tooltip seulement pour la première ligne (données réelles, barDataIndex = 0)
              if (barSpot.barIndex == 0 && barSpot.x.toInt() < weightProgress.entries.length) {
                final entry = weightProgress.entries[barSpot.x.toInt()];
                return LineTooltipItem(
                  '${barSpot.y.toStringAsFixed(1)} ${'kg'.tr(LocalizationService.instance.currentLanguageCode)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                );
              }
              return null;
            }).toList();
          },
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
      ),
      minX: 0,
      maxX: extendedWidth.toDouble() - 1,
      minY: weightProgress.minY,
      maxY: weightProgress.maxY,
      lineBarsData: [
        // Ligne de données - seulement les points réels
        LineChartBarData(
          spots: weightProgress.entries.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.weight);
          }).toList(),
          isCurved: true,
          color: const Color(0xFF0B132B),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: const Color(0xFF0B132B),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF0B132B).withOpacity(0.1),
          ),
        ),
        // Ligne d'objectif - Étendre sur toute la largeur du graphique
        if (weightProgress.targetWeight > 0)
          LineChartBarData(
            spots: [
              FlSpot(0, weightProgress.targetWeight),
              FlSpot(extendedWidth.toDouble() - 1, weightProgress.targetWeight),
            ],
            isCurved: false,
            color: const Color(0xFF64748B),
            barWidth: 2,
            dashArray: [8, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }

  // Historique des pesées
  Widget _buildWeightHistory() {
    final filteredProgress = _filteredWeightProgress;
    final lastEntries = filteredProgress?.entries.take(10).toList() ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'weight_history'.tr(LocalizationService.instance.currentLanguageCode),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 16),
          if (lastEntries.isEmpty)
            Text(
              'no_weight_recorded'.tr(LocalizationService.instance.currentLanguageCode),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            )
          else
            ...lastEntries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(entry.date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${entry.weight.toStringAsFixed(1)} ${'kg'.tr(LocalizationService.instance.currentLanguageCode)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Formulaire d'ajout de pesée
  Widget _buildAddWeightForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_weight'.tr(LocalizationService.instance.currentLanguageCode),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 16),
            NumericTextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'weight_kg'.tr(LocalizationService.instance.currentLanguageCode),
                hintText: 'weight_example'.tr(LocalizationService.instance.currentLanguageCode),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0B132B)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      showAddWeight = false;
                      _weightController.clear();
                    }),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'cancel'.tr(LocalizationService.instance.currentLanguageCode),
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('save_weight'.tr(LocalizationService.instance.currentLanguageCode)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      try {
        await WeightService.saveWeightEntry(weight);
        
        // Recharger les données
        await _loadWeightData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('weight_added_success'.tr(LocalizationService.instance.currentLanguageCode))),
        );
        setState(() {
          showAddWeight = false;
          _weightController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr(LocalizationService.instance.currentLanguageCode).replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  double _calculateYInterval() {
    final filteredProgress = _filteredWeightProgress;
    if (filteredProgress == null) return 1;
    final range = filteredProgress.maxY - filteredProgress.minY;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return 10;
  }

  double _calculateXInterval() {
    final count = _filteredWeightProgress?.entries.length ?? 1;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return 10;
  }

  bool _shouldShowYLabel(double value) {
    final interval = _calculateYInterval();
    return value % interval == 0;
  }
}