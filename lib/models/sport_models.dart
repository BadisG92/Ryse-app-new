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

  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    String? equipment,
    String? description,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
    );
  }

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

  /// Auto-validation: une série est valide si elle a au moins des répétitions
  /// Le poids peut être 0 pour les exercices au poids du corps
  bool get isValid => reps > 0;

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    // ⚡ DÉSACTIVATION de l'auto-validation verte
    // Les séries ne deviennent JAMAIS vertes automatiquement
    final newReps = reps ?? this.reps;

    return ExerciseSet(
      reps: newReps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? false, // ⚡ Toujours false par défaut
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
  final int? suggestedRepsMin;
  final int? suggestedRepsMax;

  const WorkoutExercise({
    required this.exercise,
    required this.sets,
    this.suggestedRepsMin,
    this.suggestedRepsMax,
  });

  WorkoutExercise copyWith({
    Exercise? exercise,
    List<ExerciseSet>? sets,
    int? suggestedRepsMin,
    int? suggestedRepsMax,
  }) {
    return WorkoutExercise(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      suggestedRepsMin: suggestedRepsMin ?? this.suggestedRepsMin,
      suggestedRepsMax: suggestedRepsMax ?? this.suggestedRepsMax,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: (json['sets'] as List)
          .map((setJson) => ExerciseSet.fromJson(setJson))
          .toList(),
      suggestedRepsMin: json['suggestedRepsMin'],
      suggestedRepsMax: json['suggestedRepsMax'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets.map((set) => set.toJson()).toList(),
      'suggestedRepsMin': suggestedRepsMin,
      'suggestedRepsMax': suggestedRepsMax,
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
      (sum, exercise) => sum + exercise.sets.where((set) => set.isValid).length,
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
  // Clés de traduction pour les groupes musculaires
  static const String chestKey = 'muscle_group_chest';
  static const String backKey = 'muscle_group_back';
  static const String shouldersKey = 'muscle_group_shoulders';
  static const String bicepsKey = 'muscle_group_biceps';
  static const String tricepsKey = 'muscle_group_triceps';
  static const String legsKey = 'muscle_group_legs';
  static const String glutesKey = 'muscle_group_glutes';
  static const String absKey = 'muscle_group_abs';
  static const String calvesKey = 'muscle_group_calves';
  static const String forearmsKey = 'muscle_group_forearms';
  static const String customKey = 'muscle_group_custom';

  // Valeurs par défaut (français) pour compatibilité
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
  static const String custom = 'Personnalisé';

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

  static List<String> get allKeys => [
    chestKey,
    backKey,
    shouldersKey,
    bicepsKey,
    tricepsKey,
    legsKey,
    glutesKey,
    absKey,
    calvesKey,
    forearmsKey,
  ];

  /// Traduit un nom de groupe musculaire français vers la clé de traduction
  static String getKeyFromFrenchName(String frenchName) {
    switch (frenchName) {
      case chest:
        return chestKey;
      case back:
        return backKey;
      case shoulders:
        return shouldersKey;
      case biceps:
        return bicepsKey;
      case triceps:
        return tricepsKey;
      case legs:
        return legsKey;
      case glutes:
        return glutesKey;
      case abs:
        return absKey;
      case calves:
        return calvesKey;
      case forearms:
        return forearmsKey;
      case custom:
      case 'Custom':
        return customKey;
      default:
        return customKey; // Par défaut
    }
  }

  /// Traduit une clé vers le nom français (pour compatibilité)
  static String getFrenchNameFromKey(String key) {
    switch (key) {
      case chestKey:
        return chest;
      case backKey:
        return back;
      case shouldersKey:
        return shoulders;
      case bicepsKey:
        return biceps;
      case tricepsKey:
        return triceps;
      case legsKey:
        return legs;
      case glutesKey:
        return glutes;
      case absKey:
        return abs;
      case calvesKey:
        return calves;
      case forearmsKey:
        return forearms;
      case customKey:
        return custom;
      default:
        return custom; // Par défaut
    }
  }
}

// Modèle pour un exercice prédéfini dans un programme
class ProgramExercise {
  final Exercise exercise;
  final int sets;
  final int? suggestedRepsMin;
  final int? suggestedRepsMax;

  const ProgramExercise({
    required this.exercise,
    required this.sets,
    this.suggestedRepsMin,
    this.suggestedRepsMax,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'] ?? 3,
      suggestedRepsMin: json['suggestedRepsMin'],
      suggestedRepsMax: json['suggestedRepsMax'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'suggestedRepsMin': suggestedRepsMin,
      'suggestedRepsMax': suggestedRepsMax,
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
  final bool isCustom; // true si le programme vient de user_workout_templates
  final bool isFromAI; // ⚡ true si le programme vient de Coach Ryze

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.estimatedDuration,
    required this.exercises,
    this.isCustom = false,
    this.isFromAI = false, // ⚡ Par défaut false
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
      isCustom: json['isCustom'] ?? false,
      isFromAI: json['isFromAI'] ?? false, // ⚡ Charger depuis JSON
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
      'isCustom': isCustom,
      'isFromAI': isFromAI, // ⚡ Sauvegarder dans JSON
    };
  }
} 
