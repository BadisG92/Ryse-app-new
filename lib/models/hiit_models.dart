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
