// Generated types for Ryze App Supabase Database
// Simplified multilingual architecture with direct name_en/name_fr columns

// Base types
typedef Json = dynamic;

// Exercise types
class Exercise {
  final String id;
  final String nameEn;
  final String nameFr;
  final String muscleGroup;
  final String? equipment;
  final String? description;
  final bool isCustom;
  final String? userId;
  final DateTime? createdAt;

  Exercise({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.muscleGroup,
    this.equipment,
    this.description,
    this.isCustom = false,
    this.userId,
    this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      muscleGroup: json['muscle_group'],
      equipment: json['equipment'],
      description: json['description'],
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'description': description,
      'is_custom': isCustom,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getLocalizedName(String language) {
    return language == 'fr' ? nameFr : nameEn;
  }
}

// Food types
class Food {
  final String id;
  final String nameEn;
  final String nameFr;
  final int calories;
  final double proteins;
  final double carbs;
  final double fats;
  final String? category;
  final bool isCustom;
  final String? userId;
  final DateTime? createdAt;

  Food({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.calories,
    this.proteins = 0.0,
    this.carbs = 0.0,
    this.fats = 0.0,
    this.category,
    this.isCustom = false,
    this.userId,
    this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      calories: json['calories'],
      proteins: (json['proteins'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fats: (json['fats'] ?? 0).toDouble(),
      category: json['category'],
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'category': category,
      'is_custom': isCustom,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getLocalizedName(String language) {
    return language == 'fr' ? nameFr : nameEn;
  }
}

// HIIT Workout types
class HiitWorkout {
  final String id;
  final String titleEn;
  final String titleFr;
  final String? descriptionEn;
  final String? descriptionFr;
  final int workDuration;
  final int restDuration;
  final int totalDuration;
  final int totalRounds;
  final bool isCustom;
  final String? userId;
  final DateTime? createdAt;

  HiitWorkout({
    required this.id,
    required this.titleEn,
    required this.titleFr,
    this.descriptionEn,
    this.descriptionFr,
    required this.workDuration,
    required this.restDuration,
    required this.totalDuration,
    required this.totalRounds,
    this.isCustom = false,
    this.userId,
    this.createdAt,
  });

  factory HiitWorkout.fromJson(Map<String, dynamic> json) {
    return HiitWorkout(
      id: json['id'],
      titleEn: json['title_en'],
      titleFr: json['title_fr'],
      descriptionEn: json['description_en'],
      descriptionFr: json['description_fr'],
      workDuration: json['work_duration'],
      restDuration: json['rest_duration'],
      totalDuration: json['total_duration'],
      totalRounds: json['total_rounds'],
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_en': titleEn,
      'title_fr': titleFr,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'work_duration': workDuration,
      'rest_duration': restDuration,
      'total_duration': totalDuration,
      'total_rounds': totalRounds,
      'is_custom': isCustom,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getLocalizedTitle(String language) {
    return language == 'fr' ? titleFr : titleEn;
  }

  String? getLocalizedDescription(String language) {
    return language == 'fr' ? descriptionFr : descriptionEn;
  }
}

// Recipe types
class Recipe {
  final String id;
  final String nameEn;
  final String nameFr;
  final Json ingredients;
  final List<String> stepsEn;
  final List<String> stepsFr;
  final String? imageUrl;
  final String? duration;
  final int servings;
  final String? difficulty;
  final List<String>? tags;
  final bool isCustom;
  final String? userId;
  final DateTime? createdAt;

  Recipe({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.ingredients,
    required this.stepsEn,
    required this.stepsFr,
    this.imageUrl,
    this.duration,
    required this.servings,
    this.difficulty,
    this.tags,
    this.isCustom = false,
    this.userId,
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      ingredients: json['ingredients'],
      stepsEn: List<String>.from(json['steps_en'] ?? []),
      stepsFr: List<String>.from(json['steps_fr'] ?? []),
      imageUrl: json['image_url'],
      duration: json['duration'],
      servings: json['servings'],
      difficulty: json['difficulty'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'ingredients': ingredients,
      'steps_en': stepsEn,
      'steps_fr': stepsFr,
      'image_url': imageUrl,
      'duration': duration,
      'servings': servings,
      'difficulty': difficulty,
      'tags': tags,
      'is_custom': isCustom,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getLocalizedName(String language) {
    return language == 'fr' ? nameFr : nameEn;
  }

  List<String> getLocalizedSteps(String language) {
    return language == 'fr' ? stepsFr : stepsEn;
  }
}

// Cardio Activity types
class CardioActivity {
  final String id;
  final String activityType;
  final String nameEn;
  final String nameFr;
  final bool isCustom;
  final String? userId;
  final DateTime? createdAt;

  CardioActivity({
    required this.id,
    required this.activityType,
    required this.nameEn,
    required this.nameFr,
    this.isCustom = false,
    this.userId,
    this.createdAt,
  });

  factory CardioActivity.fromJson(Map<String, dynamic> json) {
    return CardioActivity(
      id: json['id'],
      activityType: json['activity_type'],
      nameEn: json['name_en'],
      nameFr: json['name_fr'],
      isCustom: json['is_custom'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': activityType,
      'name_en': nameEn,
      'name_fr': nameFr,
      'is_custom': isCustom,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getLocalizedName(String language) {
    return language == 'fr' ? nameFr : nameEn;
  }
}

// Session/History types
class WorkoutSession {
  final String id;
  final String userId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final DateTime? createdAt;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.name,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.createdAt,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class HiitSession {
  final String id;
  final String userId;
  final String? workoutId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? currentPhase;
  final int? currentRound;
  final bool isCompleted;
  final DateTime? createdAt;

  HiitSession({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.startTime,
    this.endTime,
    this.currentPhase,
    this.currentRound,
    this.isCompleted = false,
    this.createdAt,
  });

  factory HiitSession.fromJson(Map<String, dynamic> json) {
    return HiitSession(
      id: json['id'],
      userId: json['user_id'],
      workoutId: json['workout_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      currentPhase: json['current_phase'],
      currentRound: json['current_round'],
      isCompleted: json['is_completed'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_id': workoutId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'current_phase': currentPhase,
      'current_round': currentRound,
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class CardioSession {
  final String id;
  final String userId;
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final double? distanceKm;
  final double? targetDistanceKm;
  final int? targetDurationSeconds;
  final double? averageSpeedKmh;
  final double? currentSpeedKmh;
  final int? steps;
  final int? calories;
  final bool isRunning;
  final bool isPaused;
  final String? notes;
  final DateTime? createdAt;

  CardioSession({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.distanceKm,
    this.targetDistanceKm,
    this.targetDurationSeconds,
    this.averageSpeedKmh,
    this.currentSpeedKmh,
    this.steps,
    this.calories,
    this.isRunning = false,
    this.isPaused = false,
    this.notes,
    this.createdAt,
  });

  factory CardioSession.fromJson(Map<String, dynamic> json) {
    return CardioSession(
      id: json['id'],
      userId: json['user_id'],
      activityType: json['activity_type'],
      activityTitle: json['activity_title'],
      formatTitle: json['format_title'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationSeconds: json['duration_seconds'],
      distanceKm: json['distance_km']?.toDouble(),
      targetDistanceKm: json['target_distance_km']?.toDouble(),
      targetDurationSeconds: json['target_duration_seconds'],
      averageSpeedKmh: json['average_speed_kmh']?.toDouble(),
      currentSpeedKmh: json['current_speed_kmh']?.toDouble(),
      steps: json['steps'],
      calories: json['calories'],
      isRunning: json['is_running'] ?? false,
      isPaused: json['is_paused'] ?? false,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'activity_title': activityTitle,
      'format_title': formatTitle,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_km': distanceKm,
      'target_distance_km': targetDistanceKm,
      'target_duration_seconds': targetDurationSeconds,
      'average_speed_kmh': averageSpeedKmh,
      'current_speed_kmh': currentSpeedKmh,
      'steps': steps,
      'calories': calories,
      'is_running': isRunning,
      'is_paused': isPaused,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Meal {
  final String id;
  final String userId;
  final String mealTime;
  final String name;
  final DateTime date;
  final DateTime? createdAt;

  Meal({
    required this.id,
    required this.userId,
    required this.mealTime,
    required this.name,
    required this.date,
    this.createdAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['user_id'],
      mealTime: json['meal_time'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_time': mealTime,
      'name': name,
      'date': date.toIso8601String().split('T')[0], // Date only
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// User Daily Summary type
class UserDailySummary {
  final String summaryDate;
  final int totalMeals;
  final int totalCaloriesNutrition;
  final int workoutSessions;
  final int hiitSessions;
  final int cardioSessions;
  final int totalCaloriesBurned;

  UserDailySummary({
    required this.summaryDate,
    required this.totalMeals,
    required this.totalCaloriesNutrition,
    required this.workoutSessions,
    required this.hiitSessions,
    required this.cardioSessions,
    required this.totalCaloriesBurned,
  });

  factory UserDailySummary.fromJson(Map<String, dynamic> json) {
    return UserDailySummary(
      summaryDate: json['summary_date'],
      totalMeals: json['total_meals'],
      totalCaloriesNutrition: json['total_calories_nutrition'],
      workoutSessions: json['workout_sessions'],
      hiitSessions: json['hiit_sessions'],
      cardioSessions: json['cardio_sessions'],
      totalCaloriesBurned: json['total_calories_burned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary_date': summaryDate,
      'total_meals': totalMeals,
      'total_calories_nutrition': totalCaloriesNutrition,
      'workout_sessions': workoutSessions,
      'hiit_sessions': hiitSessions,
      'cardio_sessions': cardioSessions,
      'total_calories_burned': totalCaloriesBurned,
    };
  }
}

// Utility functions for localization
class LocalizationHelper {
  static String getLocalizedName(String nameEn, String nameFr, String language) {
    return language == 'fr' ? nameFr : nameEn;
  }

  static List<String> getLocalizedSteps(List<String> stepsEn, List<String> stepsFr, String language) {
    return language == 'fr' ? stepsFr : stepsEn;
  }

  static String? getLocalizedDescription(String? descriptionEn, String? descriptionFr, String language) {
    return language == 'fr' ? descriptionFr : descriptionEn;
  }
} 