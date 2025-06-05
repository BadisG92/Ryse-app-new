import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'custom_badge.dart';
import 'dashboard_models.dart';
import 'dashboard_cards.dart';

// Section des actions rapides
class QuickActionsSection extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions - Ligne horizontale scrollable
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: actions.map((action) => QuickActionButton(action: action)).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Section des objectifs journaliers
class DailyGoalsSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final bool isPremium;

  const DailyGoalsSection({
    super.key,
    required this.goals,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les stats
    final completedGoals = goals.where((goal) => goal.completed).length;
    final totalGoals = goals.length;
    final completionRate = (completedGoals / totalGoals * 100).round();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Objectifs du jour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$completedGoals/$totalGoals',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomBadge(
                      text: '$completionRate%',
                      backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                      textColor: const Color(0xFF0B132B),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Goals list
            ...goals.map((goal) => DailyGoalItem(
              goal: goal,
              isPremium: isPremium,
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// Section preview nutrition & sport
class ModulesPreviewSection extends StatelessWidget {
  final List<ModulePreview> modules;
  final Function(String moduleTitle)? onModuleTap;

  const ModulesPreviewSection({
    super.key,
    required this.modules,
    this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: modules.map((module) => 
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: modules.indexOf(module) < modules.length - 1 ? 16 : 0,
            ),
            child: ModulePreviewCard(
              module: module,
              onTap: onModuleTap != null 
                ? () => onModuleTap!(module.title)
                : null,
            ),
          ),
        )
      ).toList(),
    );
  }
}

// Section statistiques communautaires
class CommunityStatsSection extends StatelessWidget {
  final CommunityStats stats;

  const CommunityStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.users, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Communauté Ryze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCommunityStat(
                  stats.activeUsersText,
                  'membres actifs',
                  LucideIcons.users,
                ),
                _buildCommunityStat(
                  stats.completedGoalsToday.toString(),
                  'objectifs atteints',
                  LucideIcons.target,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trendingUp, size: 16, color: Color(0xFF0B132B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔥 Challenge populaire : ${stats.topChallenge}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildCommunityStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// CTA Premium
class PremiumCTASection extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const PremiumCTASection({
    super.key,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.crown, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Débloquez votre potentiel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Photos illimitées + Coach IA personnel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: DashboardData.premiumFeatures.map((feature) =>
                PremiumFeatureItem(
                  value: feature['value']!,
                  label: feature['label']!,
                )
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Essayer 7 jours gratuits',
              icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: onUpgrade,
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Puis 15€/mois • Annulable à tout moment',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Section Premium Insights (pour utilisateurs premium)
class PremiumInsightsSection extends StatelessWidget {
  final VoidCallback? onViewAnalytics;

  const PremiumInsightsSection({
    super.key,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach IA Personnel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                CustomBadge(
                  text: 'Premium',
                  backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                  textColor: const Color(0xFF0B132B),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎯 Analyse personnalisée : Votre métabolisme est optimal entre 14h-16h. C\'est le moment idéal pour votre collation protéinée !',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Voir mes analytics avancés',
              icon: const Icon(LucideIcons.trendingUp, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: onViewAnalytics,
            ),
          ],
        ),
      ),
    );
  }
} 