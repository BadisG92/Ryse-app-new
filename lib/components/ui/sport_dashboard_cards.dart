import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import 'custom_card.dart';
import 'sport_dashboard_models.dart';

// Carte principale des calories hebdomadaires (réutilise le pattern nutrition)
class WeeklyCaloriesCard extends StatelessWidget {
  final SportProfile profile;
  final int animatedCalories;

  const WeeklyCaloriesCard({
    super.key,
    required this.profile,
    required this.animatedCalories,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Cercle principal avec compteur animé (même pattern que nutrition)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Effet de flou en arrière-plan
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Cercle principal
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            animatedCalories.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statistiques en 3 colonnes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SportCaloriesStatItem(
                    label: 'Brûlées', 
                    value: profile.weeklyCalories, 
                    color: const Color(0xFF0B132B),
                  ),
                  SportCaloriesStatItem(
                    label: 'Restantes', 
                    value: profile.remainingCalories, 
                    color: const Color(0xFF1C2951),
                  ),
                  SportCaloriesStatItem(
                    label: 'Objectif', 
                    value: profile.targetWeeklyCalories, 
                    color: const Color(0xFF888888),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barre de progression principale
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: min(profile.caloriesProgress, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(profile.progressColor),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '${profile.caloriesProgressPercent}% de l\'objectif atteint',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Moyenne : ${profile.avgDailyCalories} kcal/jour',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Item de statistique de calories sport
class SportCaloriesStatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const SportCaloriesStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Carte des activités quotidiennes
class DailyActivitiesCard extends StatelessWidget {
  final List<DailyActivity> activities;

  const DailyActivitiesCard({
    super.key,
    required this.activities,
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
              'Activité du jour',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...activities.map((activity) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DailyActivityItem(activity: activity),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}

// Item d'activité quotidienne
class DailyActivityItem extends StatelessWidget {
  final DailyActivity activity;

  const DailyActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: activity.typeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            Text(
              activity.activityText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Barre de progression
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activity.progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(activity.progressColor),
            ),
          ),
        ),
      ],
    );
  }
}

// Carte des séances récentes
class RecentWorkoutsCard extends StatelessWidget {
  final List<RecentWorkout> workouts;

  const RecentWorkoutsCard({
    super.key,
    required this.workouts,
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

// Item d'entraînement récent
class RecentWorkoutItem extends StatelessWidget {
  final RecentWorkout workout;

  const RecentWorkoutItem({
    super.key,
    required this.workout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: workout.typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            workout.icon,
            size: 16,
            color: workout.typeColor,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                workout.workoutInfo,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        
        Text(
          workout.dateText,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}

// Carte du calendrier compact (7 jours)
class WeeklyActivityCalendar extends StatelessWidget {
  final List<ActivityDay> days;

  const WeeklyActivityCalendar({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) => ActivityDayItem(day: day)).toList(),
      ),
    );
  }
}

// Item de jour d'activité
class ActivityDayItem extends StatelessWidget {
  final ActivityDay day;

  const ActivityDayItem({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day.dayLabel,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: day.hasWorkout 
                ? LinearGradient(colors: day.statusGradient)
                : null,
            color: day.hasWorkout ? null : day.statusColor,
            shape: BoxShape.circle,
          ),
          child: day.hasWorkout && day.icon != null
              ? Icon(
                  day.icon,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
      ],
    );
  }
}

// Carte de progression hebdomadaire
class WeeklyProgressCard extends StatelessWidget {
  final List<WeeklyStat> stats;

  const WeeklyProgressCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.trendingUp,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Deux stats principales côte à côte
            Row(
              children: [
                Expanded(
                  child: WeeklyStatCard(stat: stats[0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: WeeklyStatCard(stat: stats[1]),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stat du temps total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stats[2].label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    stats[2].value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B132B),
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

// Carte de statistique hebdomadaire
class WeeklyStatCard extends StatelessWidget {
  final WeeklyStat stat;

  const WeeklyStatCard({
    super.key,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stat.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (stat.icon != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat.icon,
                  size: 16,
                  color: stat.accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: stat.accentColor,
                  ),
                ),
              ],
            )
          else
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: stat.accentColor,
              ),
            ),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Carte d'action rapide sport (réutilise le pattern dashboard)
class SportQuickActionCard extends StatelessWidget {
  final SportQuickAction action;

  const SportQuickActionCard({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: action.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: action.colors,
                  ),
                ),
                child: Icon(
                  action.icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: action.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Carte d'accès au calendrier
class CalendarAccessCard extends StatelessWidget {
  final VoidCallback? onCalendarTap;

  const CalendarAccessCard({
    super.key,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.1),
                    const Color(0xFF1C2951).withOpacity(0.1),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.calendar,
                size: 20,
                color: Color(0xFF0B132B),
              ),
            ),
            
            const SizedBox(width: 12),
            
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique complet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Voir tous vos entraînements',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            GestureDetector(
              onTap: onCalendarTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: Color(0xFF0B132B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Voir calendrier',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0B132B),
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
