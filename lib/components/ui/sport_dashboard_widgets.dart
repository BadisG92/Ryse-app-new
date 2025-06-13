import 'package:flutter/material.dart';
import 'custom_card.dart';
import 'sport_dashboard_models.dart';
import 'sport_dashboard_cards.dart';

// Section des actions rapides sport
class SportQuickActionsSection extends StatelessWidget {
  final List<SportQuickAction> actions;

  const SportQuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Démarrer une activité',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: actions.map((action) {
                final isLast = action == actions.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 16),
                    child: SportQuickActionCard(action: action),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Section d'en-tête sport avec statut et calories
class SportHeaderSection extends StatelessWidget {
  final SportProfile profile;
  final int animatedCalories;

  const SportHeaderSection({
    super.key,
    required this.profile,
    required this.animatedCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message de statut avec émoji
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                profile.progressColor.withOpacity(0.1),
                profile.progressColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            profile.statusMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: profile.progressColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Carte principale des calories hebdomadaires
        WeeklyCaloriesCard(
          profile: profile,
          animatedCalories: animatedCalories,
        ),
      ],
    );
  }
}

// Section combinée des séances récentes avec calendrier
class RecentWorkoutsSection extends StatelessWidget {
  final List<RecentWorkout> workouts;
  final List<ActivityDay> activityDays;

  const RecentWorkoutsSection({
    super.key,
    required this.workouts,
    required this.activityDays,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Séances récentes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Calendrier compact des 7 derniers jours
            WeeklyActivityCalendar(days: activityDays),
            
            const SizedBox(height: 16),
            
            // Liste des entraînements récents
            ...workouts.take(3).map((workout) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecentWorkoutItem(workout: workout),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}

// Section des activités quotidiennes avec types
class DailyActivitiesSection extends StatelessWidget {
  final List<DailyActivity> activities;

  const DailyActivitiesSection({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return DailyActivitiesCard(activities: activities);
  }
}

// Section de progression hebdomadaire complète
class WeeklyProgressSection extends StatelessWidget {
  final SportProfile profile;

  const WeeklyProgressSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return WeeklyProgressCard(
      stats: SportDashboardData.getWeeklyStats(profile),
    );
  }
}

// Section d'accès au calendrier complet
class CalendarAccessSection extends StatelessWidget {
  final VoidCallback? onCalendarTap;

  const CalendarAccessSection({
    super.key,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarAccessCard(onCalendarTap: onCalendarTap);
  }
}

// Section de motivation et streak (peut être réutilisée)
class SportMotivationSection extends StatelessWidget {
  final SportProfile profile;

  const SportMotivationSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 20,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Série active : ${profile.dailyStreakText}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Continue comme ça ! 💪',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+10 XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget d'aperçu sport pour d'autres dashboards
class SportPreviewWidget extends StatelessWidget {
  final SportProfile profile;
  final VoidCallback? onTap;

  const SportPreviewWidget({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sport',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              _buildStatRow('Calories', '${profile.weeklyCalories} kcal'),
              const SizedBox(height: 4),
              _buildStatRow('Séances', profile.workoutsProgressText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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

// Helper pour construire les sections sport modulairement
class SportSectionBuilder {
  static Widget buildCaloriesSection(SportProfile profile, int animatedCalories) {
    return SportHeaderSection(
      profile: profile,
      animatedCalories: animatedCalories,
    );
  }

  static Widget buildActivitiesSection(List<DailyActivity> activities) {
    return DailyActivitiesSection(activities: activities);
  }

  static Widget buildRecentSection(List<RecentWorkout> workouts, List<ActivityDay> days) {
    return RecentWorkoutsSection(
      workouts: workouts,
      activityDays: days,
    );
  }

  static Widget buildProgressSection(SportProfile profile) {
    return WeeklyProgressSection(profile: profile);
  }

  static Widget buildQuickActionsSection(List<SportQuickAction> actions) {
    return SportQuickActionsSection(actions: actions);
  }

  static Widget buildCalendarSection(VoidCallback? onTap) {
    return CalendarAccessSection(onCalendarTap: onTap);
  }
} 
