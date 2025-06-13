class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String description;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.equipment = '',
    this.description = '',
    this.isCustom = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      muscleGroup: json['muscleGroup'] ?? '',
      equipment: json['equipment'] ?? '',
      description: json['description'] ?? '',
      isCustom: json['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'description': description,
      'isCustom': isCustom,
    };
  }
}

class ExerciseSet {
  final int reps;
  final double weight;
  final bool isCompleted;

  const ExerciseSet({
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
    };
  }
}

class WorkoutExercise {
  final Exercise exercise;
  final List<ExerciseSet> sets;

  const WorkoutExercise({
    required this.exercise,
    required this.sets,
  });

  WorkoutExercise copyWith({
    Exercise? exercise,
    List<ExerciseSet>? sets,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: (json['sets'] as List)
          .map((setJson) => ExerciseSet.fromJson(setJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }
}

class WorkoutSession {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final bool isCompleted;

  const WorkoutSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.isCompleted = false,
  });

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  int get totalSets {
    return exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);
  }

  int get completedSets {
    return exercises.fold(
      0,
      (sum, exercise) => sum + exercise.sets.where((set) => set.isCompleted).length,
    );
  }

  WorkoutSession copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutExercise>? exercises,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exercises: (json['exercises'] as List)
          .map((exerciseJson) => WorkoutExercise.fromJson(exerciseJson))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }
}

// Groupes musculaires disponibles
class MuscleGroups {
  static const String chest = 'Pectoraux';
  static const String back = 'Dos';
  static const String shoulders = 'Épaules';
  static const String biceps = 'Biceps';
  static const String triceps = 'Triceps';
  static const String legs = 'Jambes';
  static const String glutes = 'Fessiers';
  static const String abs = 'Abdominaux';
  static const String calves = 'Mollets';
  static const String forearms = 'Avant-bras';

  static List<String> get all => [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    legs,
    glutes,
    abs,
    calves,
    forearms,
  ];
}

// Modèle pour un exercice prédéfini dans un programme
class ProgramExercise {
  final Exercise exercise;
  final int sets;

  const ProgramExercise({
    required this.exercise,
    required this.sets,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
    };
  }
}

// Modèle pour un programme d'entraînement prédéfini
class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final String type; // 'Haut du corps', 'Bas du corps', 'Full body'
  final int estimatedDuration; // en minutes
  final List<ProgramExercise> exercises;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.estimatedDuration,
    required this.exercises,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    return WorkoutProgram(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      estimatedDuration: json['estimatedDuration'] ?? 60,
      exercises: (json['exercises'] as List)
          .map((exerciseJson) => ProgramExercise.fromJson(exerciseJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'estimatedDuration': estimatedDuration,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }
} 
