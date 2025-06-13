import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'global_progress_models.dart';
import 'global_progress_cards.dart';
import '../../screens/weight_evolution_screen.dart';

// En-tête global avec statistiques (réutilise le pattern des dashboards)
class GlobalProgressHeader extends StatelessWidget {
  final HeaderStats stats;

  const GlobalProgressHeader({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildHeaderItems(stats.items),
      ),
    );
  }

  List<Widget> _buildHeaderItems(List<HeaderStatItem> items) {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < items.length; i++) {
      widgets.add(_GlobalHeaderStatItem(item: items[i]));
      
      // Ajouter un séparateur sauf pour le dernier élément
      if (i < items.length - 1) {
        widgets.add(const _HeaderSeparator());
      }
    }
    
    return widgets;
  }
}

// Item de statistique dans l'en-tête
class _GlobalHeaderStatItem extends StatelessWidget {
  final HeaderStatItem item;

  const _GlobalHeaderStatItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Utiliser le logo SVG en blanc pour "Progression", icône normale pour les autres
        item.text == 'Progression' 
          ? SvgPicture.asset(
              'assets/images/logo Seul.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Colors.white, 
                BlendMode.srcIn,
              ),
            )
          : Icon(item.icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          item.text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.isBold ? FontWeight.w600 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Séparateur pour l'en-tête
class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white60,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Section de progression du poids
class WeightProgressSection extends StatelessWidget {
  final WeightProgress progress;
  final VoidCallback? onEditWeight;

  const WeightProgressSection({
    super.key,
    required this.progress,
    this.onEditWeight,
  });

  @override
  Widget build(BuildContext context) {
    return WeightEvolutionCard(
      progress: progress,
      onAddWeightTap: onEditWeight,
      onGraphTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeightEvolutionScreen(progress: progress),
          ),
        );
      },
    );
  }
}

// Section du bilan hebdomadaire global
class WeeklyBalanceSection extends StatelessWidget {
  final WeeklyBalance balance;

  const WeeklyBalanceSection({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return WeeklyBalanceCard(balance: balance);
  }
}

// Section de tracking hebdomadaire (nutrition + sport)
class WeeklyTrackingSection extends StatelessWidget {
  final List<TrackingDay> days;

  const WeeklyTrackingSection({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return WeeklyTrackingCard(
      days: days,
      nutritionLegends: GlobalProgressData.nutritionLegends,
      sportLegends: GlobalProgressData.sportLegends,
    );
  }
}

// Section des recommandations IA
class AIRecommendationSection extends StatelessWidget {
  final List<AIRecommendation> recommendations;

  const AIRecommendationSection({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    // Prendre la recommandation avec la plus haute priorité, ou aléatoire
    final selectedRecommendation = _selectRecommendation(recommendations);
    
    return AIRecommendationCard(recommendation: selectedRecommendation);
  }

  AIRecommendation _selectRecommendation(List<AIRecommendation> recommendations) {
    if (recommendations.isEmpty) {
      return const AIRecommendation(
        message: "Continue tes efforts, tu es sur la bonne voie ! 🚀",
        type: RecommendationType.general,
        priority: 1,
      );
    }

    // Trier par priorité (descendant) puis prendre aléatoirement dans les top priorités
    final sortedByPriority = List<AIRecommendation>.from(recommendations)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final topPriority = sortedByPriority.first.priority;
    final topRecommendations = sortedByPriority
        .where((r) => r.priority == topPriority)
        .toList();

    // Retourner une recommandation aléatoire parmi celles de top priorité
    topRecommendations.shuffle();
    return topRecommendations.first;
  }
}

// Widget de résumé global pour d'autres vues (réutilisable)
class GlobalProgressSummary extends StatelessWidget {
  final WeightProgress weightProgress;
  final WeeklyBalance weeklyBalance;
  final VoidCallback? onTap;

  const GlobalProgressSummary({
    super.key,
    required this.weightProgress,
    required this.weeklyBalance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Progrès Global',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Statistiques rapides
            _buildQuickStat('Poids', '${weightProgress.currentWeight.toStringAsFixed(1)} kg'),
            const SizedBox(height: 4),
            _buildQuickStat('Score hebdo', '${(weeklyBalance.globalScore * 100).round()}%'),
            const SizedBox(height: 4),
            _buildQuickStat('Évolution', weightProgress.weightChangeText),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// Widget de badge de progression pour l'en-tête principal
class ProgressBadge extends StatelessWidget {
  final double progress;
  final String label;
  final Color color;

  const ProgressBadge({
    super.key,
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini cercle de progression
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de comparaison temporelle (semaine vs semaine précédente)
class TemporalComparisonWidget extends StatelessWidget {
  final String title;
  final double currentValue;
  final double previousValue;
  final String unit;

  const TemporalComparisonWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final difference = currentValue - previousValue;
    final percentageChange = previousValue != 0 ? (difference / previousValue) * 100 : 0.0;
    final isImprovement = difference > 0; // À adapter selon le contexte

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currentValue.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isImprovement ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 12,
                color: isImprovement ? Colors.green.shade600 : Colors.red.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${percentageChange > 0 ? '+' : ''}${percentageChange.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isImprovement ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper pour construire les sections de manière modulaire
class GlobalProgressSectionBuilder {
  static Widget buildHeaderSection(HeaderStats stats) {
    return GlobalProgressHeader(stats: stats);
  }

  static Widget buildWeightSection(WeightProgress progress, VoidCallback? onEdit) {
    return WeightProgressSection(
      progress: progress,
      onEditWeight: onEdit,
    );
  }

  static Widget buildBalanceSection(WeeklyBalance balance) {
    return WeeklyBalanceSection(balance: balance);
  }

  static Widget buildTrackingSection(List<TrackingDay> days) {
    return WeeklyTrackingSection(days: days);
  }

  static Widget buildAISection(List<AIRecommendation> recommendations) {
    return AIRecommendationSection(recommendations: recommendations);
  }

  static Widget buildSummaryWidget(
    WeightProgress weightProgress,
    WeeklyBalance weeklyBalance,
    VoidCallback? onTap,
  ) {
    return GlobalProgressSummary(
      weightProgress: weightProgress,
      weeklyBalance: weeklyBalance,
      onTap: onTap,
    );
  }
} 
