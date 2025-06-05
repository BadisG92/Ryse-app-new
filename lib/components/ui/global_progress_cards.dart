import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_card.dart';
import 'global_progress_models.dart';

// Carte d'évolution du poids avec graphique
class WeightEvolutionCard extends StatelessWidget {
  final WeightProgress progress;
  final VoidCallback? onEditTap;

  const WeightEvolutionCard({
    super.key,
    required this.progress,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton modifier
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Évolution du poids',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.edit3, size: 16, color: Color(0xFF0B132B)),
                  label: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0B132B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: onEditTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Badge de changement de poids
            if (progress.weightChange != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progress.changeBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  progress.weightChangeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: progress.changeColor,
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Graphique linéaire
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minY: progress.minY,
                  maxY: progress.maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300.withOpacity(0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()} kg',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < progress.chartDates.length) {
                            return Text(
                              progress.chartDates[index],
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: progress.chartSpots,
                      isCurved: true,
                      color: const Color(0xFF0B132B),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF0B132B),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0B132B).withOpacity(0.1),
                            const Color(0xFF0B132B).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Statistiques en bas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeightStatItem(
                  label: 'Poids initial',
                  value: '${progress.initialWeight.toStringAsFixed(1)} kg',
                ),
                _WeightStatItem(
                  label: 'Poids actuel',
                  value: '${progress.currentWeight.toStringAsFixed(1)} kg',
                  isCurrent: true,
                ),
                _WeightStatItem(
                  label: 'Objectif',
                  value: '${progress.targetWeight.toStringAsFixed(1)} kg',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de statistique de poids
class _WeightStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isCurrent;

  const _WeightStatItem({
    required this.label,
    required this.value,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrent ? CrossAxisAlignment.center : 
          (label == 'Poids initial' ? CrossAxisAlignment.start : CrossAxisAlignment.end),
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCurrent ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// Carte du bilan global hebdomadaire
class WeeklyBalanceCard extends StatelessWidget {
  final WeeklyBalance balance;

  const WeeklyBalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec score global
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 20, color: Color(0xFF0B132B)),
                    SizedBox(width: 8),
                    Text(
                      'Bilan Global de la Semaine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                // Badge du score global
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: balance.scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(balance.globalScore * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: balance.scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Message motivationnel
            Text(
              balance.motivationalMessage,
              style: TextStyle(
                fontSize: 14,
                color: balance.scoreColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des items du bilan
            ...balance.items.map((item) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BalanceItemRow(item: item),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}

// Row d'un item de bilan
class _BalanceItemRow extends StatelessWidget {
  final BalanceItem item;

  const _BalanceItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
        // Barre de progression mini
        Container(
          width: 60,
          height: 6,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
            ),
          ),
        ),
        Text(
          item.valueText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }
}

// Carte de tracking hebdomadaire (nutrition + sport)
class WeeklyTrackingCard extends StatelessWidget {
  final List<TrackingDay> days;
  final List<TrackingLegend> nutritionLegends;
  final List<TrackingLegend> sportLegends;

  const WeeklyTrackingCard({
    super.key,
    required this.days,
    required this.nutritionLegends,
    required this.sportLegends,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 20, color: Color(0xFF0B132B)),
                SizedBox(width: 8),
                Text(
                  'Cette semaine',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Nutrition
            _TrackingSection(
              icon: LucideIcons.apple,
              title: 'Nutrition',
              days: days,
              isNutrition: true,
            ),
            
            const SizedBox(height: 12),
            
            // Légende nutrition
            _TrackingLegendRow(legends: nutritionLegends),
            
            const SizedBox(height: 24),
            
            // Section Sport
            _TrackingSection(
              icon: LucideIcons.dumbbell,
              title: 'Séances sport',
              days: days,
              isNutrition: false,
            ),
            
            const SizedBox(height: 12),
            
            // Légende sport
            _TrackingLegendRow(legends: sportLegends),
          ],
        ),
      ),
    );
  }
}

// Section de tracking (nutrition ou sport)
class _TrackingSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<TrackingDay> days;
  final bool isNutrition;

  const _TrackingSection({
    required this.icon,
    required this.title,
    required this.days,
    required this.isNutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Titre de section
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0B132B)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Indicateurs des 7 jours
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) {
            return _TrackingDayIndicator(
              day: day,
              isNutrition: isNutrition,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Indicateur pour un jour de tracking
class _TrackingDayIndicator extends StatelessWidget {
  final TrackingDay day;
  final bool isNutrition;

  const _TrackingDayIndicator({
    required this.day,
    required this.isNutrition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day.dayLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isNutrition ? _getNutritionGradient(day) : _getSportGradient(day),
            color: isNutrition ? _getNutritionColor(day) : _getSportColor(day),
            border: isNutrition ? _getNutritionBorder(day) : _getSportBorder(day),
            boxShadow: _getBoxShadow(day, isNutrition),
          ),
          child: _getIcon(day, isNutrition),
        ),
      ],
    );
  }

  LinearGradient? _getNutritionGradient(TrackingDay day) {
    final gradient = day.nutritionScore.gradient;
    if (gradient != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      );
    }
    return null;
  }

  LinearGradient? _getSportGradient(TrackingDay day) {
    if (day.sportActivity != null && day.sportActivity != SportActivity.none) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: day.sportActivity!.gradient,
      );
    }
    return null;
  }

  Color? _getNutritionColor(TrackingDay day) {
    return day.nutritionScore.gradient == null ? day.nutritionScore.color : null;
  }

  Color? _getSportColor(TrackingDay day) {
    return (day.sportActivity == null || day.sportActivity == SportActivity.none) 
        ? const Color(0xFFF1F5F9) : null;
  }

  Border? _getNutritionBorder(TrackingDay day) {
    return day.nutritionScore.gradient == null 
        ? Border.all(color: const Color(0xFFE2E8F0)) : null;
  }

  Border? _getSportBorder(TrackingDay day) {
    return (day.sportActivity == null || day.sportActivity == SportActivity.none)
        ? Border.all(color: const Color(0xFFE2E8F0)) : null;
  }

  List<BoxShadow>? _getBoxShadow(TrackingDay day, bool isNutrition) {
    final hasValidContent = isNutrition 
        ? day.nutritionScore != TrackingScore.missed
        : day.sportActivity != null && day.sportActivity != SportActivity.none;

    if (hasValidContent) {
      return [
        BoxShadow(
          color: const Color(0xFF0B132B).withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Widget? _getIcon(TrackingDay day, bool isNutrition) {
    if (isNutrition) {
      if (day.nutritionScore.hasIcon) {
        return Center(
          child: Icon(day.nutritionScore.icon, color: Colors.white, size: 14),
        );
      }
    } else {
      if (day.sportActivity != null && day.sportActivity!.hasIcon) {
        return Center(
          child: Icon(day.sportActivity!.icon, color: Colors.white, size: 14),
        );
      }
    }
    return null;
  }
}

// Row de légende pour le tracking
class _TrackingLegendRow extends StatelessWidget {
  final List<TrackingLegend> legends;

  const _TrackingLegendRow({required this.legends});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: legends.map((legend) {
        final isLast = legend == legends.last;
        return Row(
          children: [
            _TrackingLegendItem(legend: legend),
            if (!isLast) const SizedBox(width: 12),
          ],
        );
      }).toList(),
    );
  }
}

// Item de légende individuel
class _TrackingLegendItem extends StatelessWidget {
  final TrackingLegend legend;

  const _TrackingLegendItem({required this.legend});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (legend.icon != null)
          CircleAvatar(
            radius: 8,
            backgroundColor: legend.color,
            child: Icon(legend.icon, color: Colors.white, size: 8),
          )
        else
          CircleAvatar(radius: 6, backgroundColor: legend.color),
        const SizedBox(width: 6),
        Text(
          legend.label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// Carte de recommandation IA
class AIRecommendationCard extends StatelessWidget {
  final AIRecommendation recommendation;

  const AIRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icône avec couleur selon le type
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: recommendation.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                recommendation.icon,
                size: 20,
                color: recommendation.color,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge de priorité (si élevée)
            if (recommendation.priority >= 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendation.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 