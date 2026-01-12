import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'sport_models.dart';

/// Types d'activités planifiées
enum PlannedActivityType {
  breakfast,
  lunch,
  dinner,
  snack,
  cardio,
}

/// Extension pour PlannedActivityType
extension PlannedActivityTypeExtension on PlannedActivityType {
  String get value {
    switch (this) {
      case PlannedActivityType.breakfast:
        return 'breakfast';
      case PlannedActivityType.lunch:
        return 'lunch';
      case PlannedActivityType.dinner:
        return 'dinner';
      case PlannedActivityType.snack:
        return 'snack';
      case PlannedActivityType.cardio:
        return 'cardio';
    }
  }

  static PlannedActivityType fromString(String value) {
    switch (value) {
      case 'breakfast':
        return PlannedActivityType.breakfast;
      case 'lunch':
        return PlannedActivityType.lunch;
      case 'dinner':
        return PlannedActivityType.dinner;
      case 'snack':
        return PlannedActivityType.snack;
      case 'cardio':
        return PlannedActivityType.cardio;
      default:
        return PlannedActivityType.breakfast;
    }
  }

  /// Icône associée au type
  IconData get icon {
    switch (this) {
      case PlannedActivityType.breakfast:
        return Icons.free_breakfast;
      case PlannedActivityType.lunch:
        return Icons.restaurant;
      case PlannedActivityType.dinner:
        return Icons.nightlight_round;
      case PlannedActivityType.snack:
        return Icons.cookie;
      case PlannedActivityType.cardio:
        return LucideIcons.activity;
    }
  }

  /// Couleur associée au type
  Color get color {
    switch (this) {
      case PlannedActivityType.breakfast:
        return const Color(0xFFF59E0B); // Orange
      case PlannedActivityType.lunch:
        return const Color(0xFF10B981); // Vert
      case PlannedActivityType.dinner:
        return const Color(0xFF3B82F6); // Bleu
      case PlannedActivityType.snack:
        return const Color(0xFF8B5CF6); // Violet
      case PlannedActivityType.cardio:
        return const Color(0xFF3B82F6); // Bleu - couleur de l'app
    }
  }

  /// Vérifier si c'est un repas
  bool get isMeal {
    return this == PlannedActivityType.breakfast ||
        this == PlannedActivityType.lunch ||
        this == PlannedActivityType.dinner ||
        this == PlannedActivityType.snack;
  }
}

/// Statut d'une activité planifiée
enum PlannedStatus {
  planned,
  completed,
  missed,
}

extension PlannedStatusExtension on PlannedStatus {
  String get value {
    switch (this) {
      case PlannedStatus.planned:
        return 'planned';
      case PlannedStatus.completed:
        return 'completed';
      case PlannedStatus.missed:
        return 'missed';
    }
  }

  static PlannedStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return PlannedStatus.completed;
      case 'missed':
        return PlannedStatus.missed;
      default:
        return PlannedStatus.planned;
    }
  }
}

/// Données d'une activité cardio planifiée
class PlannedCardioData {
  final String activityName;
  final String activityKey; // 'running', 'bike', 'walking', etc.
  final int? targetMinutes;
  final double? targetKm;

  const PlannedCardioData({
    required this.activityName,
    required this.activityKey,
    this.targetMinutes,
    this.targetKm,
  });

  factory PlannedCardioData.fromJson(Map<String, dynamic> json) {
    return PlannedCardioData(
      activityName: json['activity_name'] ?? '',
      activityKey: json['activity_key'] ?? '',
      targetMinutes: json['target_minutes'],
      targetKm: json['target_km']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_name': activityName,
      'activity_key': activityKey,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (targetKm != null) 'target_km': targetKm,
    };
  }
}

/// Données d'un repas planifié
class PlannedMealData {
  final String foodDescription;
  final String? linkedEntryId;
  final int? calories;
  final double? proteins;
  final double? carbs;
  final double? fats;

  const PlannedMealData({
    required this.foodDescription,
    this.linkedEntryId,
    this.calories,
    this.proteins,
    this.carbs,
    this.fats,
  });

  factory PlannedMealData.fromJson(Map<String, dynamic> json) {
    return PlannedMealData(
      foodDescription: json['food_description'] ?? '',
      linkedEntryId: json['linked_entry_id'],
      calories: json['calories'],
      proteins: json['proteins']?.toDouble(),
      carbs: json['carbs']?.toDouble(),
      fats: json['fats']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_description': foodDescription,
      if (linkedEntryId != null) 'linked_entry_id': linkedEntryId,
      if (calories != null) 'calories': calories,
      if (proteins != null) 'proteins': proteins,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
    };
  }
}

/// Activité planifiée (repas ou cardio)
class PlannedActivity {
  final String id;
  final String userId;
  final DateTime plannedDate;
  final PlannedActivityType activityType;
  final Map<String, dynamic> activityData;
  final PlannedStatus status;
  final bool isAiGenerated;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlannedActivity({
    required this.id,
    required this.userId,
    required this.plannedDate,
    required this.activityType,
    required this.activityData,
    this.status = PlannedStatus.planned,
    this.isAiGenerated = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Récupérer les données cardio si c'est une activité cardio
  PlannedCardioData? get cardioData {
    if (activityType == PlannedActivityType.cardio) {
      return PlannedCardioData.fromJson(activityData);
    }
    return null;
  }

  /// Récupérer les données repas si c'est un repas
  PlannedMealData? get mealData {
    if (activityType.isMeal) {
      return PlannedMealData.fromJson(activityData);
    }
    return null;
  }

  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    return PlannedActivity(
      id: json['id'],
      userId: json['user_id'],
      plannedDate: DateTime.parse(json['planned_date']),
      activityType: PlannedActivityTypeExtension.fromString(json['activity_type']),
      activityData: json['activity_data'] ?? {},
      status: PlannedStatusExtension.fromString(json['status'] ?? 'planned'),
      isAiGenerated: json['is_ai_generated'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'planned_date': plannedDate.toIso8601String().split('T')[0],
      'activity_type': activityType.value,
      'activity_data': activityData,
      'status': status.value,
      'is_ai_generated': isAiGenerated,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PlannedActivity copyWith({
    String? id,
    String? userId,
    DateTime? plannedDate,
    PlannedActivityType? activityType,
    Map<String, dynamic>? activityData,
    PlannedStatus? status,
    bool? isAiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlannedActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plannedDate: plannedDate ?? this.plannedDate,
      activityType: activityType ?? this.activityType,
      activityData: activityData ?? this.activityData,
      status: status ?? this.status,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Workout planifié (généré par IA)
class PlannedWorkout {
  final String id;
  final String userId;
  final DateTime plannedDate;
  final String workoutName;
  final int? durationMinutes;
  final List<WorkoutExercise> exercises;
  final String? userPrompt;
  final PlannedStatus status;
  final String? linkedSessionId;
  final bool isAiGenerated;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlannedWorkout({
    required this.id,
    required this.userId,
    required this.plannedDate,
    required this.workoutName,
    this.durationMinutes,
    required this.exercises,
    this.userPrompt,
    this.status = PlannedStatus.planned,
    this.linkedSessionId,
    this.isAiGenerated = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Nombre total de séries
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Nombre total d'exercices
  int get totalExercises => exercises.length;

  /// Couleur du workout
  Color get color => const Color(0xFF0B132B); // Navy

  /// Icône du workout
  IconData get icon => Icons.fitness_center;

  factory PlannedWorkout.fromJson(Map<String, dynamic> json) {
    // Parse exercises_json
    List<WorkoutExercise> exercises = [];
    if (json['exercises_json'] != null) {
      final exercisesData = json['exercises_json'];
      if (exercisesData is List) {
        exercises = exercisesData
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return PlannedWorkout(
      id: json['id'],
      userId: json['user_id'],
      plannedDate: DateTime.parse(json['planned_date']),
      workoutName: json['workout_name'],
      durationMinutes: json['duration_minutes'],
      exercises: exercises,
      userPrompt: json['user_prompt'],
      status: PlannedStatusExtension.fromString(json['status'] ?? 'planned'),
      linkedSessionId: json['linked_session_id'],
      isAiGenerated: json['is_ai_generated'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'planned_date': plannedDate.toIso8601String().split('T')[0],
      'workout_name': workoutName,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'exercises_json': exercises.map((e) => e.toJson()).toList(),
      if (userPrompt != null) 'user_prompt': userPrompt,
      'status': status.value,
      if (linkedSessionId != null) 'linked_session_id': linkedSessionId,
      'is_ai_generated': isAiGenerated,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Pour insertion en base (sans id, created_at, etc.)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'planned_date': plannedDate.toIso8601String().split('T')[0],
      'workout_name': workoutName,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'exercises_json': exercises.map((e) => e.toJson()).toList(),
      if (userPrompt != null) 'user_prompt': userPrompt,
      'status': status.value,
      'is_ai_generated': isAiGenerated,
    };
  }

  PlannedWorkout copyWith({
    String? id,
    String? userId,
    DateTime? plannedDate,
    String? workoutName,
    int? durationMinutes,
    List<WorkoutExercise>? exercises,
    String? userPrompt,
    PlannedStatus? status,
    String? linkedSessionId,
    bool? isAiGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlannedWorkout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plannedDate: plannedDate ?? this.plannedDate,
      workoutName: workoutName ?? this.workoutName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      userPrompt: userPrompt ?? this.userPrompt,
      status: status ?? this.status,
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Données d'un jour dans le planner
class DayPlanData {
  final DateTime date;
  final List<PlannedActivity> activities;
  final List<PlannedWorkout> workouts;
  final bool isToday;
  final bool isPast;

  const DayPlanData({
    required this.date,
    required this.activities,
    required this.workouts,
    required this.isToday,
    required this.isPast,
  });

  /// Nombre total d'items pour ce jour
  int get totalItems => activities.length + workouts.length;

  /// Vérifier s'il y a des activités
  bool get hasActivities => totalItems > 0;

  /// Nombre d'items complétés
  int get completedCount {
    int count = 0;
    count += activities.where((a) => a.status == PlannedStatus.completed).length;
    count += workouts.where((w) => w.status == PlannedStatus.completed).length;
    return count;
  }

  /// Nombre d'items manqués
  int get missedCount {
    int count = 0;
    count += activities.where((a) => a.status == PlannedStatus.missed).length;
    count += workouts.where((w) => w.status == PlannedStatus.missed).length;
    return count;
  }

  /// Récupérer les repas du jour
  List<PlannedActivity> get meals =>
      activities.where((a) => a.activityType.isMeal).toList();

  /// Récupérer les cardios du jour
  List<PlannedActivity> get cardios =>
      activities.where((a) => a.activityType == PlannedActivityType.cardio).toList();
}

/// Données complètes du planner pour une semaine
class WeeklyPlannerData {
  final DateTime weekStart; // Toujours un lundi
  final DateTime weekEnd; // Toujours un dimanche
  final List<PlannedActivity> activities;
  final List<PlannedWorkout> workouts;
  final Map<DateTime, DayPlanData> dayPlans;

  const WeeklyPlannerData({
    required this.weekStart,
    required this.weekEnd,
    required this.activities,
    required this.workouts,
    required this.dayPlans,
  });

  /// Créer les données du planner à partir des listes
  factory WeeklyPlannerData.fromLists({
    required DateTime weekStart,
    required List<PlannedActivity> activities,
    required List<PlannedWorkout> workouts,
  }) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Créer les plans par jour
    final Map<DateTime, DayPlanData> dayPlans = {};

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final dayActivities = activities.where((a) {
        final actDate = DateTime(a.plannedDate.year, a.plannedDate.month, a.plannedDate.day);
        return actDate == normalizedDate;
      }).toList();

      final dayWorkouts = workouts.where((w) {
        final workDate = DateTime(w.plannedDate.year, w.plannedDate.month, w.plannedDate.day);
        return workDate == normalizedDate;
      }).toList();

      dayPlans[normalizedDate] = DayPlanData(
        date: normalizedDate,
        activities: dayActivities,
        workouts: dayWorkouts,
        isToday: normalizedDate == today,
        isPast: normalizedDate.isBefore(today),
      );
    }

    return WeeklyPlannerData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      activities: activities,
      workouts: workouts,
      dayPlans: dayPlans,
    );
  }

  /// Créer un planner vide pour la semaine courante
  factory WeeklyPlannerData.empty() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final normalizedStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return WeeklyPlannerData.fromLists(
      weekStart: normalizedStart,
      activities: [],
      workouts: [],
    );
  }

  /// Récupérer le DayPlanData pour une date
  DayPlanData? getDayPlan(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dayPlans[normalizedDate];
  }

  /// Nombre total d'items sur la semaine
  int get totalItems => activities.length + workouts.length;

  /// Nombre d'items complétés sur la semaine
  int get totalCompleted {
    int count = 0;
    count += activities.where((a) => a.status == PlannedStatus.completed).length;
    count += workouts.where((w) => w.status == PlannedStatus.completed).length;
    return count;
  }

  /// Pourcentage de complétion
  double get completionPercentage {
    if (totalItems == 0) return 0;
    return totalCompleted / totalItems;
  }

  /// Liste des jours de la semaine
  List<DateTime> get weekDays {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }
}

/// Utilitaire pour obtenir le début de la semaine courante (lundi)
DateTime getCurrentWeekStart() {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  return DateTime(weekStart.year, weekStart.month, weekStart.day);
}

/// Utilitaire pour vérifier si une date est dans la semaine courante
bool isInCurrentWeek(DateTime date) {
  final weekStart = getCurrentWeekStart();
  final weekEnd = weekStart.add(const Duration(days: 6));
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return !normalizedDate.isBefore(weekStart) && !normalizedDate.isAfter(weekEnd);
}

/// Utilitaire pour vérifier si une date est dans le futur (ou aujourd'hui)
bool isDateEditable(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return !normalizedDate.isBefore(today);
}

/// Utilitaire pour vérifier si une date est aujourd'hui
bool isToday(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return normalizedDate == today;
}
