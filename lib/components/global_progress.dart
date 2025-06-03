import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import 'package:fl_chart/fl_chart.dart';

class GlobalProgress extends StatefulWidget {
  const GlobalProgress({super.key});

  @override
  State<GlobalProgress> createState() => _GlobalProgressState();
}

class _GlobalProgressState extends State<GlobalProgress> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWeightEvolution(),
                  const SizedBox(height: 16),
                  _buildWeeklyGlobalBalance(),
                  const SizedBox(height: 16),
                  _buildWeeklyTracking(),
                  const SizedBox(height: 16),
                  _buildAICoachRecommendation(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Données à des fins de démonstration, à remplacer par des données réelles si nécessaire
    const String dailyStreak = '7 jours'; 
    const String weeklyObjectives = '5/7 Objectifs';

    return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Padding ajusté
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
        bottom: false,
                child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHeaderItem(LucideIcons.flame, dailyStreak),
            _buildHeaderSeparator(),
            _buildHeaderItem(LucideIcons.target, weeklyObjectives), // Icône et texte mis à jour
            _buildHeaderSeparator(),
            _buildHeaderItem(LucideIcons.sparkles, 'Progrès', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(IconData icon, String text, {bool isBold = false}) {
    return Row(
                  children: [
        Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSeparator() {
    // Modifié pour afficher un point comme séparateur
    return const Text(
      '•',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500
      ),
    );
  }

  Widget _buildWeightEvolution() {
    final List<FlSpot> weightSpots = [
      const FlSpot(0, 72.0),
      const FlSpot(1, 71.2),
      const FlSpot(2, 70.5),
      const FlSpot(3, 69.8),
      const FlSpot(4, 69.7),
    ];

    final List<String> dates = ['1 Jan', '8 Jan', '15 Jan', '22 Jan', '29 Jan'];

    double currentWeight = 69.7;
    double previousWeight = 72.0;
    double weightChange = currentWeight - previousWeight;
    double minY = 68.0;
    double maxY = 73.0;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                    const Text(
                  'Évolution du poids',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.edit3, size: 16, color: Color(0xFF0B132B)),
                  label: const Text('Modifier', style: TextStyle(fontSize: 14, color: Color(0xFF0B132B), fontWeight: FontWeight.w500)),
                  onPressed: () {
                    // TODO: Logique pour modifier le poids
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300))),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (weightChange != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: weightChange < 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${weightChange > 0 ? "+" : ""}${weightChange.toStringAsFixed(1)} kg ce mois',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: weightChange < 0 ? Colors.green.shade700 : Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
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
                          return Text('${value.toInt()} kg', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
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
                          if (index >= 0 && index < dates.length) {
                             return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(dates[index], style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightSpots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0B132B).withOpacity(0.8), const Color(0xFF1C2951).withOpacity(0.9)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0B132B).withOpacity(0.3),
                            const Color(0xFF1C2951).withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeightStat('Poids initial', '72.0 kg'),
                _buildWeightStat('Poids actuel', '69.7 kg', isCurrent: true),
                _buildWeightStat('Objectif', '68.0 kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightStat(String label, String value, {bool isCurrent = false}) {
    return Column(
      crossAxisAlignment: isCurrent ? CrossAxisAlignment.center : (label == 'Poids initial' ? CrossAxisAlignment.start : CrossAxisAlignment.end),
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isCurrent ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildWeeklyGlobalBalance() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.checkCircle2, size: 20, color: Color(0xFF0B132B)),
                SizedBox(width: 8),
                Text(
                  'Bilan Global de la Semaine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGlobalBalanceItem(LucideIcons.flame, 'Calories cibles atteintes', '5 / 7 jours'),
            const SizedBox(height: 12),
            _buildGlobalBalanceItem(LucideIcons.droplet, 'Hydratation validée', '5 / 7 jours'),
            const SizedBox(height: 12),
            _buildGlobalBalanceItem(LucideIcons.utensils, 'Repas enregistrés', '17 / 21 repas'),
            const SizedBox(height: 12),
            _buildGlobalBalanceItem(LucideIcons.dumbbell, 'Séances de sport', '3 / 4 prévues'),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalBalanceItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0B132B))),
      ],
    );
  }

  Widget _buildWeeklyTracking() {
    // Données nutrition de la semaine (utilisant les couleurs de l'app)
    final nutritionWeek = [
      {'date': 'L', 'score': 2}, // Objectifs atteints
      {'date': 'M', 'score': 1}, // Partiel
      {'date': 'M', 'score': 2}, // Objectifs atteints
      {'date': 'J', 'score': 2}, // Objectifs atteints
      {'date': 'V', 'score': 1}, // Partiel
      {'date': 'S', 'score': 0}, // Pas de données
      {'date': 'D', 'score': 0}, // Pas de données
    ];

    // Données sport de la semaine
    final sportWeek = [
      {'date': 'L', 'activity': 'musculation'}, // Musculation
      {'date': 'M', 'activity': 'none'}, // Pas de séance
      {'date': 'M', 'activity': 'cardio'}, // Cardio
      {'date': 'J', 'activity': 'none'}, // Pas de séance
      {'date': 'V', 'activity': 'musculation'}, // Musculation
      {'date': 'S', 'activity': 'cardio'}, // Cardio
      {'date': 'D', 'activity': 'none'}, // Pas de séance
    ];

    IconData _getSportActivityIcon(String activity) {
      if (activity == 'musculation') return LucideIcons.dumbbell;
      if (activity == 'cardio') return LucideIcons.activity;
      return LucideIcons.x; // Pas de séance
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 20, color: Color(0xFF0B132B)),
                SizedBox(width: 8),
                Text('Cette semaine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 24),
            
            // Section Nutrition
            Row(
              children: [
                const Icon(LucideIcons.apple, size: 18, color: Color(0xFF0B132B)),
                const SizedBox(width: 8),
                const Text('Nutrition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: nutritionWeek.map((day) {
                return Column(
                  children: [
                    Text(day['date'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: (day['score'] as int) > 0
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: (day['score'] as int) == 2
                                    ? [const Color(0xFF0B132B), const Color(0xFF1C2951)]
                                    : [const Color(0xFF64748B), const Color(0xFF64748B)],
                              )
                            : null,
                        color: (day['score'] as int) > 0 ? null : const Color(0xFFF1F5F9),
                        border: (day['score'] as int) > 0 ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: (day['score'] as int) > 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0B132B).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: (day['score'] as int) > 0 
                          ? const Center(
                              child: Icon(LucideIcons.check, color: Colors.white, size: 14),
                            )
                          : null,
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Légende Nutrition
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF0B132B), 'Atteint'),
                const SizedBox(width: 12),
                _buildLegendItem(const Color(0xFF64748B), 'Partiel'),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.grey.shade300, 'Manqué'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Sport
            Row(
              children: [
                const Icon(LucideIcons.dumbbell, size: 18, color: Color(0xFF0B132B)),
                const SizedBox(width: 8),
                const Text('Séances sport', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: sportWeek.map((day) {
                String activity = day['activity'] as String;
                return Column(
                  children: [
                    Text(day['date'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: activity != 'none'
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: activity == 'musculation'
                                    ? [const Color(0xFF0B132B), const Color(0xFF1C2951)]
                                    : [const Color(0xFF0B132B).withOpacity(0.7), const Color(0xFF1C2951).withOpacity(0.7)],
                              )
                            : null,
                        color: activity != 'none' ? null : const Color(0xFFF1F5F9),
                        border: activity != 'none' ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: activity != 'none'
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0B132B).withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: activity != 'none' 
                          ? Center(
                              child: Icon(_getSportActivityIcon(activity), color: Colors.white, size: 14),
                            )
                          : null,
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Légende Sport
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItemWithIcon(const Color(0xFF0B132B), LucideIcons.dumbbell, 'Musculation'),
                const SizedBox(width: 12),
                _buildLegendItemWithIcon(const Color(0xFF1C2951), LucideIcons.activity, 'Cardio'),
                const SizedBox(width: 8),
                _buildLegendItem(Colors.grey.shade300, 'Repos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildLegendItemWithIcon(Color color, IconData icon, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 8, 
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 8),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildAICoachRecommendation() {
    List<String> recommendations = [
      "Tu es très régulier, mais ton apport en protéines est trop faible pour soutenir tes objectifs de tonification.",
      "Ton activité physique est en hausse 📈, continue comme ça pour booster ton métabolisme.",
      "Pense à varier tes sources de glucides pour un apport énergétique plus stable.",
      "N'oublie pas tes jours de repos, ils sont cruciaux pour la récupération et la progression !"
    ];
    String selectedRecommendation = (recommendations..shuffle()).first;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(LucideIcons.brain, size: 28, color: Color(0xFF0B132B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommandation intelligente 🧠',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedRecommendation,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
} 