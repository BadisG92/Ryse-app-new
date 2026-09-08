import '../../models/sport_models.dart';

/// Une séance pendant qu'on la fait.
///
/// Le modèle `WorkoutSession` de l'app est figé et sert à l'écriture. Ici les
/// objets sont mutables, parce qu'une série se remplit en trois gestes et que
/// chacun doit être écrit sur le téléphone sans recréer tout l'arbre. Le pont
/// vers l'ancien modèle est [LiveSession.toWorkoutSession] : le chemin
/// d'écriture ne change pas de signature.
class LiveSet {
  LiveSet({this.weightKg = 0, this.reps = 0, this.done = false, this.record = false});

  double weightKg;
  int reps;
  bool done;

  /// Cette série a battu la dernière fois. Rare par nature : c'est la seule
  /// chose de la séance qui a le droit de se faire remarquer.
  bool record;

  bool get isEmpty => weightKg <= 0 && reps <= 0;

  Map<String, dynamic> toJson() => {'w': weightKg, 'r': reps, 'd': done, if (record) 'pb': true};

  factory LiveSet.fromJson(Map<String, dynamic> m) => LiveSet(
        weightKg: (m['w'] as num?)?.toDouble() ?? 0,
        reps: (m['r'] as num?)?.toInt() ?? 0,
        done: m['d'] as bool? ?? false,
        record: m['pb'] as bool? ?? false,
      );
}

class LiveExercise {
  LiveExercise({required this.exercise, required this.sets, this.repsMin, this.repsMax});

  Exercise exercise;
  final List<LiveSet> sets;
  int? repsMin;
  int? repsMax;

  int get doneCount => sets.where((s) => s.done).length;
  bool get allDone => sets.isNotEmpty && sets.every((s) => s.done);

  /// La dernière série validée, celle que la carte repliée cite.
  LiveSet? get lastDone {
    for (var i = sets.length - 1; i >= 0; i--) {
      if (sets[i].done) return sets[i];
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'exercise': exercise.toJson(),
        'sets': sets.map((s) => s.toJson()).toList(),
        'repsMin': repsMin,
        'repsMax': repsMax,
      };

  factory LiveExercise.fromJson(Map<String, dynamic> m) => LiveExercise(
        exercise: Exercise.fromJson(Map<String, dynamic>.from(m['exercise'] as Map)),
        sets: (m['sets'] as List).map((s) => LiveSet.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
        repsMin: (m['repsMin'] as num?)?.toInt(),
        repsMax: (m['repsMax'] as num?)?.toInt(),
      );

  /// Depuis le modèle figé qu'un programme ou le planificateur fournit.
  factory LiveExercise.fromWorkout(WorkoutExercise w) => LiveExercise(
        exercise: w.exercise,
        sets: w.sets.isEmpty
            ? [LiveSet(), LiveSet(), LiveSet()]
            : w.sets.map((s) => LiveSet(weightKg: s.weight, reps: s.reps, done: s.isCompleted)).toList(),
        repsMin: w.suggestedRepsMin,
        repsMax: w.suggestedRepsMax,
      );
}

class LiveSession {
  LiveSession({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.exercises,
    this.isFromProgram = false,
    this.isFromAI = false,
    this.guidedTemplateId,
    this.plannedWorkoutId,
    this.restSeconds = 90,
  });

  /// Généré au départ, jamais changé : il devient le `history_session_id` de
  /// l'écriture, ce qui rend le rejeu idempotent.
  final String id;
  String name;
  final DateTime startedAt;
  final List<LiveExercise> exercises;
  final bool isFromProgram;
  final bool isFromAI;
  final String? guidedTemplateId;
  final String? plannedWorkoutId;
  int restSeconds;

  int get totalSets => exercises.fold(0, (n, e) => n + e.sets.length);
  int get doneSets => exercises.fold(0, (n, e) => n + e.doneCount);
  int get undoneSets => totalSets - doneSets;

  /// Le volume levé, en kilos : ce que valent les séries validées.
  double get volumeKg => exercises.fold(0.0, (v, e) => v + e.sets.where((s) => s.done).fold(0.0, (x, s) => x + s.weightKg * s.reps));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'isFromProgram': isFromProgram,
        'isFromAI': isFromAI,
        'guidedTemplateId': guidedTemplateId,
        'plannedWorkoutId': plannedWorkoutId,
        'restSeconds': restSeconds,
      };

  factory LiveSession.fromJson(Map<String, dynamic> m) => LiveSession(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        startedAt: DateTime.tryParse(m['startedAt'] as String? ?? '') ?? DateTime.now(),
        exercises: (m['exercises'] as List).map((e) => LiveExercise.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        isFromProgram: m['isFromProgram'] as bool? ?? false,
        isFromAI: m['isFromAI'] as bool? ?? false,
        guidedTemplateId: m['guidedTemplateId'] as String?,
        plannedWorkoutId: m['plannedWorkoutId'] as String?,
        restSeconds: (m['restSeconds'] as num?)?.toInt() ?? 90,
      );

  /// Le pont vers l'écriture : seules les séries validées avec des reps
  /// partent, marquées faites. Les exercices sans aucune série validée ne
  /// sont pas envoyés — l'historique ne garde que ce qui a été fait.
  WorkoutSession toWorkoutSession(DateTime finishedAt) => WorkoutSession(
        id: id,
        name: name,
        startTime: startedAt,
        endTime: finishedAt,
        isCompleted: true,
        exercises: [
          for (final e in exercises)
            if (e.sets.any((s) => s.done && s.reps > 0))
              WorkoutExercise(
                exercise: e.exercise,
                suggestedRepsMin: e.repsMin,
                suggestedRepsMax: e.repsMax,
                sets: [
                  for (final s in e.sets)
                    if (s.done && s.reps > 0) ExerciseSet(reps: s.reps, weight: s.weightKg, isCompleted: true),
                ],
              ),
        ],
      );
}
