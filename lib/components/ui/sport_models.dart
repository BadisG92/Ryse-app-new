// Modèles de données pour les composants sport
class WorkoutProgram {
  final int id;
  final String name;
  final String duration;
  final String frequency;
  final String progress;
  final List<Exercise> exercises;
  final String lastUsed;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.duration,
    required this.frequency,
    required this.progress,
    required this.exercises,
    required this.lastUsed,
  });
}

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final String muscleGroup;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.muscleGroup,
  });
}

class ExerciseProgress {
  final String name;
  final String current;
  final String progress;
  final int sessions;

  const ExerciseProgress({
    required this.name,
    required this.current,
    required this.progress,
    required this.sessions,
  });
}

class SessionExerciseBest {
  final String name;
  final int setsCount;
  final double? weightKg; // nullable if no weight entered
  final int reps;

  const SessionExerciseBest({
    required this.name,
    required this.setsCount,
    required this.reps,
    this.weightKg,
  });
}

class WorkoutSession {
  final String name;
  final String day;
  final int calories;
  final int durationMinutes;
  final double totalVolumeKg;
  final List<SessionExerciseBest> items;
  final String lastUsed;

  const WorkoutSession({
    required this.name,
    required this.day,
    required this.calories,
    required this.durationMinutes,
    required this.totalVolumeKg,
    required this.items,
    required this.lastUsed,
  });
}

class WeeklyStats {
  final String sessions;
  final String weight;
  final String calories;

  const WeeklyStats({
    required this.sessions,
    required this.weight,
    required this.calories,
  });
} 
