// Modèles pour les séances HIIT
class HiitWorkout {
  final String id;
  final String title;
  final String description;
  final int workDuration; // en secondes
  final int restDuration; // en secondes
  final int totalDuration; // en minutes
  final int totalRounds;

  const HiitWorkout({
    required this.id,
    required this.title,
    required this.description,
    required this.workDuration,
    required this.restDuration,
    required this.totalDuration,
    required this.totalRounds,
  });
}

enum HiitPhase {
  warmup,
  work,
  rest,
  cooldown,
  finished,
}

class HiitSession {
  final HiitWorkout workout;
  final DateTime startTime;
  HiitPhase currentPhase;
  int currentRound;
  int phaseTimeRemaining; // en secondes
  int totalTimeRemaining; // en secondes
  bool isRunning;
  bool isPaused;

  HiitSession({
    required this.workout,
    required this.startTime,
    this.currentPhase = HiitPhase.work,
    this.currentRound = 1,
    required this.phaseTimeRemaining,
    required this.totalTimeRemaining,
    this.isRunning = false,
    this.isPaused = false,
  });

  HiitSession copyWith({
    HiitWorkout? workout,
    DateTime? startTime,
    HiitPhase? currentPhase,
    int? currentRound,
    int? phaseTimeRemaining,
    int? totalTimeRemaining,
    bool? isRunning,
    bool? isPaused,
  }) {
    return HiitSession(
      workout: workout ?? this.workout,
      startTime: startTime ?? this.startTime,
      currentPhase: currentPhase ?? this.currentPhase,
      currentRound: currentRound ?? this.currentRound,
      phaseTimeRemaining: phaseTimeRemaining ?? this.phaseTimeRemaining,
      totalTimeRemaining: totalTimeRemaining ?? this.totalTimeRemaining,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

// Workouts HIIT prédéfinis
class HiitWorkouts {
  static const List<HiitWorkout> predefinedWorkouts = [
    HiitWorkout(
      id: 'hiit_beginner',
      title: 'HIIT débutant',
      description: '15 min - 30s effort / 30s repos',
      workDuration: 30,
      restDuration: 30,
      totalDuration: 15,
      totalRounds: 15,
    ),
    HiitWorkout(
      id: 'hiit_intense',
      title: 'HIIT intense',
      description: '20 min - 45s effort / 15s repos',
      workDuration: 45,
      restDuration: 15,
      totalDuration: 20,
      totalRounds: 20,
    ),
    HiitWorkout(
      id: 'tabata',
      title: 'Tabata',
      description: '4 min - 20s effort / 10s repos',
      workDuration: 20,
      restDuration: 10,
      totalDuration: 4,
      totalRounds: 8,
    ),
  ];

  static HiitWorkout? getWorkoutById(String id) {
    try {
      return predefinedWorkouts.firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }
} 
