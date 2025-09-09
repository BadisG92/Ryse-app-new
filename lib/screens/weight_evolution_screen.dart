import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../components/ui/global_progress_models.dart';

class WeightEvolutionScreen extends StatefulWidget {
  final WeightProgress progress;

  const WeightEvolutionScreen({
    super.key,
    required this.progress,
  });

  @override
  State<WeightEvolutionScreen> createState() => _WeightEvolutionScreenState();
}

class _WeightEvolutionScreenState extends State<WeightEvolutionScreen> {
  String selectedPeriod = 'Ce mois-ci';
  bool showAddWeight = false;
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Évolution du poids',
            style: TextStyle(
              color: Color(0xFF0B132B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Color(0xFF0B132B)),
            onPressed: () => setState(() => showAddWeight = !showAddWeight),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
    );
  }

  // 3 KPI Cards carrés et uniformes
  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            "Actuel",
            "${widget.progress.currentWeight.toStringAsFixed(1)}",
            "kg",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            "Objectif", 
            "${widget.progress.targetWeight.toStringAsFixed(1)}",
            "kg",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKPICard(
            "Ce mois",
            "${widget.progress.weightChange >= 0 ? '+' : ''}${widget.progress.weightChange.toStringAsFixed(1)}",
            "kg",
          ),
        ),
      ],
    );
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
    final periods = ['Ce mois-ci', '3 mois', '6 mois'];
    
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
                  period,
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
          const Text(
            'Évolution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: widget.progress.entries.length > 10 
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(400, widget.progress.entries.length * 50.0),
                    height: 250,
                    child: LineChart(
              LineChartData(
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
                        if (value.toInt() >= 0 && value.toInt() < widget.progress.entries.length) {
                          final entry = widget.progress.entries[value.toInt()];
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
                minX: 0,
                maxX: widget.progress.entries.length.toDouble() - 1,
                minY: widget.progress.minY,
                maxY: widget.progress.maxY,
                lineBarsData: [
                  // Ligne de données
                  LineChartBarData(
                    spots: widget.progress.entries.asMap().entries.map((entry) {
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
                  // Ligne d'objectif
                  if (widget.progress.targetWeight > 0)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, widget.progress.targetWeight),
                        FlSpot(widget.progress.entries.length.toDouble() - 1, widget.progress.targetWeight),
                      ],
                      isCurved: false,
                      color: const Color(0xFF64748B),
                      barWidth: 2,
                      dashArray: [8, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            ),
                  ),
                )
              : LineChart(
                  LineChartData(
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
                            if (value.toInt() >= 0 && value.toInt() < widget.progress.entries.length) {
                              final entry = widget.progress.entries[value.toInt()];
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
                    minX: 0,
                    maxX: widget.progress.entries.length.toDouble() - 1,
                    minY: widget.progress.minY,
                    maxY: widget.progress.maxY,
                    lineBarsData: [
                      // Ligne de données
                      LineChartBarData(
                        spots: widget.progress.entries.asMap().entries.map((entry) {
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
                      // Ligne d'objectif
                      if (widget.progress.targetWeight > 0)
                        LineChartBarData(
                          spots: [
                            FlSpot(0, widget.progress.targetWeight),
                            FlSpot(widget.progress.entries.length.toDouble() - 1, widget.progress.targetWeight),
                          ],
                          isCurved: false,
                          color: const Color(0xFF64748B),
                          barWidth: 2,
                          dashArray: [8, 4],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Historique des pesées
  Widget _buildWeightHistory() {
    final lastEntries = widget.progress.entries.take(10).toList();
    
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
          const Text(
            'Historique des pesées',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 16),
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
                    '${entry.weight.toStringAsFixed(1)} kg',
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
            const Text(
              'Ajouter une pesée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Poids (kg)',
                hintText: 'Ex: 70.5',
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
                    child: const Text(
                      'Annuler',
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
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addWeight() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      // TODO: Implémenter l'ajout en base de données
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesée ajoutée avec succès')),
      );
      setState(() {
        showAddWeight = false;
        _weightController.clear();
      });
    }
  }

  double _calculateYInterval() {
    final range = widget.progress.maxY - widget.progress.minY;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return 10;
  }

  double _calculateXInterval() {
    final count = widget.progress.entries.length;
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