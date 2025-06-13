import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'sport_models.dart';
import '../../widgets/exercise/exercise_detail_page.dart';

// Card pour les statistiques hebdomadaires individuelles
class WeeklyStatCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const WeeklyStatCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// Card principale pour les statistiques de la semaine
class WeeklyStatsCard extends StatelessWidget {
  final WeeklyStats stats;

  const WeeklyStatsCard({super.key, required this.stats});

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
            Row(
              children: [
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.sessions,
                    subtitle: 'Séances réalisées',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.weight,
                    subtitle: 'Soulevés',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.calories,
                    subtitle: 'Kcal brûlées',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card pour l'historique des séances
class WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutHistoryCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      session.day,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Bulle calories brûlées
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.flame,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session.calories} kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Aperçu des exercices
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: session.exercises.map((exercise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Dernière utilisation: ${session.lastUsed}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to get full exercise data from name
Map<String, dynamic>? _getExerciseDataByName(String exerciseName) {
  // Les mêmes données que dans ExerciseListBottomSheet
  final exercisesList = [
    {
      'id': 1,
      'name': 'Développé couché',
      'muscleGroup': 'Pectoraux',
      'icon': null,
      'sessions': 24,
      'lastWeight': '85kg',
      'progress': '+12%',
      'isPositive': true,
      'data': [68, 70, 72, 75, 78, 80, 82, 85],
      'sessionHistory': [
        {
          'date': '2024-01-15',
          'weight': '85kg',
          'reps': '3x8',
          'rpe': 7,
        },
        {
          'date': '2024-01-12',
          'weight': '82kg',
          'reps': '3x8',
          'rpe': 6,
        },
        {
          'date': '2024-01-10',
          'weight': '80kg',
          'reps': '3x8',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 2,
      'name': 'Squat',
      'muscleGroup': 'Jambes',
      'icon': null,
      'sessions': 18,
      'lastWeight': '120kg',
      'progress': '+18%',
      'isPositive': true,
      'data': [85, 90, 95, 100, 105, 110, 115, 120],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '120kg',
          'reps': '4x6',
          'rpe': 8,
        },
        {
          'date': '2024-01-11',
          'weight': '115kg',
          'reps': '4x6',
          'rpe': 7,
        },
        {
          'date': '2024-01-09',
          'weight': '110kg',
          'reps': '4x6',
          'rpe': 6,
        },
      ],
    },
    {
      'id': 3,
      'name': 'Soulevé de terre',
      'muscleGroup': 'Dos',
      'icon': null,
      'sessions': 20,
      'lastWeight': '140kg',
      'progress': '+15%',
      'isPositive': true,
      'data': [100, 110, 115, 120, 125, 130, 135, 140],
      'sessionHistory': [
        {
          'date': '2024-01-13',
          'weight': '140kg',
          'reps': '3x5',
          'rpe': 9,
        },
        {
          'date': '2024-01-10',
          'weight': '135kg',
          'reps': '3x5',
          'rpe': 8,
        },
        {
          'date': '2024-01-08',
          'weight': '130kg',
          'reps': '3x5',
          'rpe': 8,
        },
      ],
    },
    {
      'id': 4,
      'name': 'Tractions',
      'muscleGroup': 'Dos',
      'icon': null,
      'sessions': 22,
      'lastWeight': '+15kg',
      'progress': '+25%',
      'isPositive': true,
      'data': [0, 2, 5, 7, 8, 10, 12, 15],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '+15kg',
          'reps': '4x6',
          'rpe': 8,
        },
        {
          'date': '2024-01-11',
          'weight': '+12kg',
          'reps': '4x6',
          'rpe': 7,
        },
        {
          'date': '2024-01-09',
          'weight': '+10kg',
          'reps': '4x6',
          'rpe': 7,
        },
      ],
    },
  ];

  try {
    return exercisesList.firstWhere((exercise) => exercise['name'] == exerciseName);
  } catch (e) {
    return null;
  }
}

// Card pour la progression des exercices
class ExerciseProgressCard extends StatelessWidget {
  final ExerciseProgress progress;

  const ExerciseProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final exerciseData = _getExerciseDataByName(progress.name);
            if (exerciseData != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailPage(exercise: exerciseData),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${progress.sessions} séances',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      progress.current,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      progress.progress,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
