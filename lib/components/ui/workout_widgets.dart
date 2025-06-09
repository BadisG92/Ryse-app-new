import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'custom_card.dart';
import 'sport_models.dart';
import 'sport_cards.dart';
import '../../widgets/exercise/exercise_list_bottom_sheet.dart';

// Section principale des statistiques de la semaine
class WeeklyStatsSection extends StatelessWidget {
  const WeeklyStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = WeeklyStats(
      sessions: '3',
      weight: '22 500 kg',
      calories: '1 240',
    );
    
    return WeeklyStatsCard(stats: stats);
  }
}

// Section historique des séances de la semaine
class WeekHistorySection extends StatelessWidget {
  const WeekHistorySection({super.key});

  static const List<WorkoutSession> _weekSessions = [
    WorkoutSession(
      name: 'Push/Pull/Legs',
      day: 'Lundi',
      calories: 340,
      exercises: [
        'Développé couché 4×8-10',
        'Développé incliné 3×10-12',
        'Écarté poulie 3×12-15',
        'Développé militaire 4×8-10',
      ],
      lastUsed: 'Il y a 2 jours',
    ),
    WorkoutSession(
      name: 'Séance Jambes',
      day: 'Mercredi',
      calories: 420,
      exercises: [
        'Squat 4×6-8',
        'Presse à cuisses 3×12-15',
        'Leg curl 3×12-15',
        'Mollets 4×15-20',
      ],
      lastUsed: 'Il y a 4 jours',
    ),
    WorkoutSession(
      name: 'Upper Body',
      day: 'Vendredi',
      calories: 380,
      exercises: [
        'Tractions 4×6-8',
        'Rowing 4×8-10',
        'Curl biceps 3×12-15',
        'Extensions triceps 3×12-15',
      ],
      lastUsed: 'Il y a 6 jours',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Historique de la semaine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        ..._weekSessions.map((session) => WorkoutHistoryCard(session: session)).toList(),
      ],
    );
  }
}

// Section progression des exercices
class ExerciseProgressSection extends StatelessWidget {
  const ExerciseProgressSection({super.key});

  static const List<ExerciseProgress> _exerciseProgress = [
    ExerciseProgress(name: 'Développé couché', current: '85kg', progress: '+12%', sessions: 24),
    ExerciseProgress(name: 'Squat', current: '120kg', progress: '+18%', sessions: 18),
    ExerciseProgress(name: 'Soulevé de terre', current: '140kg', progress: '+15%', sessions: 20),
    ExerciseProgress(name: 'Tractions', current: '+15kg', progress: '+25%', sessions: 22),
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Progression par exercice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ExerciseListBottomSheet.show(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ..._exerciseProgress.map((progress) => ExerciseProgressCard(progress: progress)).toList(),
          ],
        ),
      ),
    );
  }
}

// Widget pour les stats de session
class SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const SessionStat({
    super.key,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Card de tracking de session
class SessionTrackingCard extends StatelessWidget {
  final String sessionName;
  final DateTime sessionStartTime;
  final List<Map<String, dynamic>> currentExercises;
  final VoidCallback onComplete;

  const SessionTrackingCard({
    super.key,
    required this.sessionName,
    required this.sessionStartTime,
    required this.currentExercises,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duration = now.difference(sessionStartTime);
    final totalSets = currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).length,
    );
    final completedSets = currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).where((set) => set['completed'] == true).length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SessionStat(
                      icon: LucideIcons.clock,
                      value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 16),
                    SessionStat(
                      icon: LucideIcons.dumbbell,
                      value: '${currentExercises.length} exercices',
                    ),
                    const SizedBox(width: 16),
                    SessionStat(
                      icon: LucideIcons.checkCircle,
                      value: '$completedSets/$totalSets séries',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B132B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Terminer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Bouton principal pour commencer une séance
class StartSessionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartSessionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commencer une séance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.play, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Commencer une séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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