import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'exercise_detail_page.dart';

class ExerciseListBottomSheet extends StatelessWidget {
  const ExerciseListBottomSheet({super.key});

  static const List<Map<String, dynamic>> exercisesData = [
    {
      'id': 1,
      'name': 'Développé couché',
      'muscleGroup': 'Pectoraux',
      'icon': LucideIcons.dumbbell,
      'sessions': 24,
      'lastWeight': '85kg',
      'progress': '+12%',
      'isPositive': true,
      'data': [65, 68, 70, 72, 75, 78, 80, 82, 85],
      'sessionHistory': [
        {
          'date': '2024-01-15',
          'weight': '85kg',
          'reps': '3x8',
          'rpe': 8,
        },
        {
          'date': '2024-01-12',
          'weight': '82kg',
          'reps': '3x8',
          'rpe': 7,
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
      'icon': LucideIcons.dumbbell,
      'sessions': 18,
      'lastWeight': '120kg',
      'progress': '+18%',
      'isPositive': true,
      'data': [85, 90, 95, 100, 105, 110, 115, 118, 120],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '120kg',
          'reps': '4x6',
          'rpe': 9,
        },
        {
          'date': '2024-01-11',
          'weight': '118kg',
          'reps': '4x6',
          'rpe': 8,
        },
        {
          'date': '2024-01-09',
          'weight': '115kg',
          'reps': '4x6',
          'rpe': 8,
        },
      ],
    },
    {
      'id': 3,
      'name': 'Soulevé de terre',
      'muscleGroup': 'Dos',
      'icon': LucideIcons.dumbbell,
      'sessions': 20,
      'lastWeight': '140kg',
      'progress': '+15%',
      'isPositive': true,
      'data': [100, 110, 115, 120, 125, 130, 135, 138, 140],
      'sessionHistory': [
        {
          'date': '2024-01-13',
          'weight': '140kg',
          'reps': '3x5',
          'rpe': 9,
        },
        {
          'date': '2024-01-10',
          'weight': '138kg',
          'reps': '3x5',
          'rpe': 8,
        },
        {
          'date': '2024-01-08',
          'weight': '135kg',
          'reps': '3x5',
          'rpe': 8,
        },
      ],
    },
    {
      'id': 4,
      'name': 'Tractions',
      'muscleGroup': 'Dos',
      'icon': LucideIcons.dumbbell,
      'sessions': 22,
      'lastWeight': '+15kg',
      'progress': '+25%',
      'isPositive': true,
      'data': [0, 2.5, 5, 7.5, 10, 12.5, 15],
      'sessionHistory': [
        {
          'date': '2024-01-15',
          'weight': '+15kg',
          'reps': '4x8',
          'rpe': 8,
        },
        {
          'date': '2024-01-12',
          'weight': '+12.5kg',
          'reps': '4x8',
          'rpe': 7,
        },
        {
          'date': '2024-01-10',
          'weight': '+10kg',
          'reps': '4x8',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 5,
      'name': 'Développé militaire',
      'muscleGroup': 'Épaules',
      'icon': LucideIcons.dumbbell,
      'sessions': 15,
      'lastWeight': '55kg',
      'progress': '+10%',
      'isPositive': true,
      'data': [40, 42, 45, 47, 50, 52, 55],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '55kg',
          'reps': '3x10',
          'rpe': 8,
        },
        {
          'date': '2024-01-11',
          'weight': '52kg',
          'reps': '3x10',
          'rpe': 7,
        },
        {
          'date': '2024-01-09',
          'weight': '50kg',
          'reps': '3x10',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 6,
      'name': 'Rowing barre',
      'muscleGroup': 'Dos',
      'icon': LucideIcons.dumbbell,
      'sessions': 16,
      'lastWeight': '75kg',
      'progress': '+8%',
      'isPositive': true,
      'data': [55, 58, 60, 65, 68, 70, 72, 75],
      'sessionHistory': [
        {
          'date': '2024-01-13',
          'weight': '75kg',
          'reps': '4x8',
          'rpe': 8,
        },
        {
          'date': '2024-01-10',
          'weight': '72kg',
          'reps': '4x8',
          'rpe': 7,
        },
        {
          'date': '2024-01-08',
          'weight': '70kg',
          'reps': '4x8',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 7,
      'name': 'Curl biceps',
      'muscleGroup': 'Bras',
      'icon': LucideIcons.dumbbell,
      'sessions': 14,
      'lastWeight': '32kg',
      'progress': '+6%',
      'isPositive': true,
      'data': [25, 26, 28, 29, 30, 31, 32],
      'sessionHistory': [
        {
          'date': '2024-01-12',
          'weight': '32kg',
          'reps': '3x12',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 8,
      'name': 'Extensions triceps',
      'muscleGroup': 'Bras',
      'icon': LucideIcons.dumbbell,
      'sessions': 12,
      'lastWeight': '28kg',
      'progress': '+4%',
      'isPositive': true,
      'data': [22, 24, 25, 26, 27, 28],
      'sessionHistory': [
        {
          'date': '2024-01-11',
          'weight': '28kg',
          'reps': '3x12',
          'rpe': 8,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header avec indicateur de drag
          Container(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Titre et bouton fermer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercices suivis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'Sélectionnez un exercice pour voir sa progression',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des exercices
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exercisesData.length,
              itemBuilder: (context, index) {
                final exercise = exercisesData[index];
                return _buildExerciseItem(context, exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(BuildContext context, Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Fermer le bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailPage(exercise: exercise),
              ),
            );
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
                        exercise['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${exercise['sessions']} séances',
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
                      exercise['lastWeight'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      exercise['progress'],
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

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseListBottomSheet(),
    );
  }
} 
