import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../ui/custom_card.dart';
import '../ui/cardio_cards.dart';

/// Page mockée pour le tutorial Cardio
/// Réplique 100% fidèle de la vraie page Cardio avec données vides
class TutorialCardioPage extends StatelessWidget {
  final GlobalKey weeklyStatsKey;
  final GlobalKey activitySelectionKey;
  final GlobalKey lastSessionKey;
  final GlobalKey weekSessionsKey;
  final GlobalKey historyAccessKey;
  final ScrollController? scrollController;

  const TutorialCardioPage({
    Key? key,
    required this.weeklyStatsKey,
    required this.activitySelectionKey,
    required this.lastSessionKey,
    required this.weekSessionsKey,
    required this.historyAccessKey,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Bloc "Cette semaine" - Réplique 100% fidèle
                _buildWeeklyStatsSection(),

                const SizedBox(height: 16),

                // 2. Bloc "Choisir une activité" - Réplique 100% fidèle
                _buildActivitySelectionSection(),

                const SizedBox(height: 16),

                // 3. Bloc "Dernière séance" - Réplique 100% fidèle
                _buildLastSessionSection(),

                const SizedBox(height: 16),

                // 4. Bloc "Vos séances de la semaine" - Réplique 100% fidèle
                _buildWeekSessionsSection(),

                const SizedBox(height: 16),

                // 5. Footer / CTA - Réplique 100% fidèle
                _buildHistoryAccessWidget(),

                // Padding bottom pour éviter la coupure
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Bloc "Cette semaine" - EXACT copy de WeeklyStatsSection
  Widget _buildWeeklyStatsSection() {
    return CustomCard(
      key: weeklyStatsKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône calendar (pas trendingUp!)
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cette semaine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Les 3 stats cards (utilisant le vrai WeeklyStatCard)
            Row(
              children: [
                Expanded(
                  child: WeeklyStatCard(
                    title: '0 km',
                    subtitle: 'Distance',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: '0 min',
                    subtitle: 'Temps',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: '0',
                    subtitle: 'Calories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Bloc "Choisir une activité" - EXACT copy de ActivitySelectionSection
  Widget _buildActivitySelectionSection() {
    return CustomCard(
      key: activitySelectionKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône play
            Row(
              children: [
                const Icon(
                  LucideIcons.play,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Choisir une activité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid avec les vraies ActivityCard
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                ActivityCard(
                  icon: LucideIcons.activity,
                  title: 'Course à pied',
                  onTap: () {},
                ),
                ActivityCard(
                  icon: LucideIcons.bike,
                  title: 'Vélo',
                  onTap: () {},
                ),
                ActivityCard(
                  icon: LucideIcons.footprints,
                  title: 'Marche',
                  onTap: () {},
                ),
                ActivityCard(
                  icon: LucideIcons.flame,
                  title: 'HIIT',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Bloc "Dernière séance" - EXACT copy de LastSessionSection (état vide)
  Widget _buildLastSessionSection() {
    return CustomCard(
      key: lastSessionKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône clock
            Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dernière séance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Message "Aucune séance" (style exact de la vraie page)
            const Text(
              'Aucune séance enregistrée',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Bloc "Vos séances de la semaine" - EXACT copy de WeekSessionsSection (état vide)
  Widget _buildWeekSessionsSection() {
    return CustomCard(
      key: weekSessionsKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône activity (PAS list!)
            Row(
              children: [
                const Icon(
                  LucideIcons.activity,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vos séances de la semaine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Message "Aucune séance" (style exact de la vraie page)
            const Text(
              'Aucune séance cette semaine',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Footer / CTA - EXACT copy de HistoryAccessWidget
  Widget _buildHistoryAccessWidget() {
    return Center(
      key: historyAccessKey,
      child: TextButton(
        onPressed: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 16,
              color: Color(0xFF0B132B),
            ),
            const SizedBox(width: 8),
            const Text(
              'Voir le journal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
