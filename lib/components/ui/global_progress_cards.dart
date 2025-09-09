import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_card.dart';
import 'global_progress_models.dart';

// Carte d'évolution du poids avec graphique
class WeightEvolutionCard extends StatelessWidget {
  final WeightProgress progress;
  final VoidCallback? onAddWeightTap;
  final VoidCallback? onGraphTap;

  const WeightEvolutionCard({
    super.key,
    required this.progress,
    this.onAddWeightTap,
    this.onGraphTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec actions subtiles
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 20,
                  color: const Color(0xFF0B132B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Évolution du poids',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Bouton d'expansion style DA
                GestureDetector(
                  onTap: onGraphTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.expand,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Graphique agrandi
            Container(
                height: isSmallScreen ? 160 : 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0B132B).withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: LineChart(
                          LineChartData(
                            minY: progress.minY,
                            maxY: progress.maxY,
                            // Étendre légèrement l'axe X pour la ligne d'objectif
                            minX: 0,
                            maxX: (progress.entries.length + 1).toDouble(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: const Color(0xFF0B132B).withOpacity(0.1),
                                  strokeWidth: 0.5,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: !isSmallScreen,
                                  reservedSize: 30,
                                  interval: (progress.maxY - progress.minY) > 10 ? 5 : 2,
                                  getTitlesWidget: (value, meta) {
                                    if (value % ((progress.maxY - progress.minY) > 10 ? 5 : 2) != 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      '${value.toInt()}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 18,
                                  interval: isSmallScreen ? 2 : 1,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < progress.entries.length) {
                                      final entry = progress.entries[index];
                                      return Text(
                                        '${entry.date.day}/${entry.date.month}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            // Gestion des tooltips améliorée
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (touchedSpot) => const Color(0xFF0B132B),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                  return touchedBarSpots.map((barSpot) {
                                    // Afficher le tooltip seulement pour la première ligne (données réelles, barDataIndex = 0)
                                    if (barSpot.barIndex == 0 && barSpot.x.toInt() < progress.entries.length) {
                                      final entry = progress.entries[barSpot.x.toInt()];
                                      return LineTooltipItem(
                                        '${barSpot.y.toStringAsFixed(1)} kg',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
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
                            lineBarsData: [
                              // Ligne principale des données - seulement points réels
                              LineChartBarData(
                                spots: progress.entries.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value.weight);
                                }).toList(),
                                isCurved: true,
                                color: const Color(0xFF0B132B),
                                barWidth: 2,
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
                              // Ligne d'objectif - étendue sur toute la largeur
                              if (progress.targetWeight > 0)
                                LineChartBarData(
                                  spots: [
                                    FlSpot(0, progress.targetWeight),
                                    FlSpot((progress.entries.length + 1).toDouble(), progress.targetWeight),
                                  ],
                                  isCurved: false,
                                  color: const Color(0xFF64748B), // Gris pour l'objectif
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  dashArray: [8, 4], // Ligne pointillée plus visible
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
          ],
        ),
      ),
    );
  }
}

// Widget moderne de statistique de poids
class _ModernWeightStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSmallScreen;

  const _ModernWeightStatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0B132B).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 12 : 14,
                  color: const Color(0xFF0B132B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B132B),
            ),
          ),
        ],
      ),
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
            // En-tête sans score global
            const Row(
              children: [
                Icon(LucideIcons.check, size: 20, color: Color(0xFF0B132B)),
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
        // Barre de progression uniforme avec couleur bleue
        Container(
          width: 60,
          height: 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
            ),
          ),
        ),
        // Conteneur à largeur fixe pour aligner toutes les valeurs
        SizedBox(
          width: 90, // Largeur fixe pour aligner les barres
          child: Text(
            item.valueText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0B132B),
            ),
            textAlign: TextAlign.left,
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
    // Pour les activités combinées, on utilise un gradient comme dans le calendrier sport
    if (day.hasBothActivities) {
      return null; // Géré différemment dans les icônes combinées
    } else if (day.hasCardio) {
      // Cardio avec gradient comme dans sport_calendar_view.dart
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0B132B).withOpacity(0.7), 
          const Color(0xFF1C2951).withOpacity(0.7)
        ],
      );
    } else if (day.hasMusculation) {
      // Musculation avec couleur solide comme dans sport_calendar_view.dart
      return null; // Utilise la couleur solide
    }
    return null;
  }

  Color? _getNutritionColor(TrackingDay day) {
    return day.nutritionScore.gradient == null ? day.nutritionScore.color : null;
  }

  Color? _getSportColor(TrackingDay day) {
    if (!day.hasAnyActivity) {
      return const Color(0xFFF1F5F9);
    } else if (day.hasBothActivities) {
      return null; // Géré dans les icônes combinées
    } else if (day.hasMusculation) {
      // Couleur solide pour musculation comme dans sport_calendar_view.dart
      return const Color(0xFF0B132B);
    }
    return null;
  }

  Border? _getNutritionBorder(TrackingDay day) {
    return day.nutritionScore.gradient == null 
        ? Border.all(color: const Color(0xFFE2E8F0)) : null;
  }

  Border? _getSportBorder(TrackingDay day) {
    return !day.hasAnyActivity ? Border.all(color: const Color(0xFFE2E8F0)) : null;
  }

  List<BoxShadow>? _getBoxShadow(TrackingDay day, bool isNutrition) {
    final hasValidContent = isNutrition 
        ? day.nutritionScore != TrackingScore.missed
        : day.hasAnyActivity;

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
      // Plus d'icône pour la nutrition, juste les couleurs
      return null;
    } else {
      // Nouvelle logique pour les icônes sport basée sur sportActivities
      if (day.hasBothActivities) {
        // Icône combinée exactement comme dans le calendrier sport
        return Stack(
          children: [
            // Partie musculation (haut-gauche)
            ClipPath(
              clipper: UpperLeftClipper(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0B132B), // Couleur musculation
                ),
                child: const Align(
                  alignment: Alignment(-0.2, -0.2),
                  child: Icon(
                    LucideIcons.dumbbell,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Partie cardio (bas-droite)
            ClipPath(
              clipper: LowerRightClipper(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0B132B).withOpacity(0.7), 
                      const Color(0xFF1C2951).withOpacity(0.7)
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment(0.2, 0.2),
                  child: Icon(
                    LucideIcons.activity,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (day.hasMusculation) {
        return const Center(
          child: Icon(LucideIcons.dumbbell, color: Colors.white, size: 14),
        );
      } else if (day.hasCardio) {
        return const Center(
          child: Icon(LucideIcons.activity, color: Colors.white, size: 14),
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
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: legend.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(legend.icon, color: Colors.white, size: 8),
          )
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: legend.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
            // Icône sans fond pour les recommandations
            Icon(
              recommendation.icon,
              size: 20,
              color: const Color(0xFF0B132B),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conseil intelligent',
                    style: TextStyle(
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
            

          ],
        ),
      ),
    );
  }
}

// CustomClippers pour les icônes combinées (copiés du calendrier sport)
class UpperLeftClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LowerRightClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
