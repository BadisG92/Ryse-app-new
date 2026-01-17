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

  /// Icône associée au type (Lucide icons pour uniformité avec les boutons d'ajout)
  IconData get icon {
    switch (this) {
      case PlannedActivityType.breakfast:
        return LucideIcons.sunrise; // Petit-déjeuner - lever de soleil
      case PlannedActivityType.lunch:
        return LucideIcons.sun; // Déjeuner - soleil
      case PlannedActivityType.dinner:
        return LucideIcons.sunset; // Dîner - coucher de soleil
      case PlannedActivityType.snack:
        return LucideIcons.milk; // Collation - lait
      case PlannedActivityType.cardio:
        return LucideIcons.activity;
    }
  }

  /// Couleur associée au type (bleu uniforme de l'app)
  /// Note: La couleur finale dépend du statut (vert=validé, gris=planifié, rouge=manqué)
  Color get color {
    // Couleur bleue uniforme pour tous les types
    return const Color(0xFF0B132B);
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

/// Configuration HIIT
class HiitConfig {
  final int workSeconds;
  final int restSeconds;
  final int rounds;
  final String type; // 'tabata', 'hiit_beginner', 'hiit_intense', 'custom'

  const HiitConfig({
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
    required this.type,
  });

  factory HiitConfig.fromJson(Map<String, dynamic> json) {
    return HiitConfig(
      workSeconds: json['work_seconds'] ?? 30,
      restSeconds: json['rest_seconds'] ?? 30,
      rounds: json['rounds'] ?? 10,
      type: json['type'] ?? 'custom',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'work_seconds': workSeconds,
      'rest_seconds': restSeconds,
      'rounds': rounds,
      'type': type,
    };
  }

  /// Durée totale en minutes
  int get totalMinutes => ((workSeconds + restSeconds) * rounds / 60).ceil();
}

/// Données d'une activité cardio planifiée
class PlannedCardioData {
  final String activityName;
  final String activityKey; // 'running', 'bike', 'walking', 'hiit', etc.
  final int? targetMinutes;
  final double? targetKm;
  final HiitConfig? hiitConfig; // Config HIIT si c'est une séance HIIT

  const PlannedCardioData({
    required this.activityName,
    required this.activityKey,
    this.targetMinutes,
    this.targetKm,
    this.hiitConfig,
  });

  /// Vérifie si c'est une séance HIIT
  bool get isHiit => activityKey.toLowerCase() == 'hiit' && hiitConfig != null;

  factory PlannedCardioData.fromJson(Map<String, dynamic> json) {
    HiitConfig? hiitConfig;
    if (json['hiit_config'] != null) {
      hiitConfig = HiitConfig.fromJson(json['hiit_config'] as Map<String, dynamic>);
    }

    return PlannedCardioData(
      activityName: json['activity_name'] ?? '',
      activityKey: json['activity_key'] ?? '',
      targetMinutes: json['target_minutes'],
      targetKm: json['target_km']?.toDouble(),
      hiitConfig: hiitConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_name': activityName,
      'activity_key': activityKey,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (targetKm != null) 'target_km': targetKm,
      if (hiitConfig != null) 'hiit_config': hiitConfig!.toJson(),
    };
  }
}

/// Données d'un repas planifié
class PlannedMealData {
  // Nouveaux champs pour le meal planner
  final String? dishName;           // Nom court du plat (ex: "Omelette protéinée")
  final String? dishDescription;    // Description détaillée (ex: "4 oeufs, épinards, fromage")
  final String? linkedFoodEntryId;  // Lien vers food_entries pour sync bidirectionnelle
  final double? estimatedQuantityG; // Quantité estimée en grammes
  final String? aiReasoning;        // Explication de l'IA pour ce choix

  // Champs existants (backward compatibility)
  final String foodDescription;     // Ancien champ, utilisé comme fallback
  final String? linkedEntryId;      // Ancien champ de liaison
  final int? calories;
  final double? proteins;
  final double? carbs;
  final double? fats;

  const PlannedMealData({
    this.dishName,
    this.dishDescription,
    this.linkedFoodEntryId,
    this.estimatedQuantityG,
    this.aiReasoning,
    this.foodDescription = '',
    this.linkedEntryId,
    this.calories,
    this.proteins,
    this.carbs,
    this.fats,
  });

  /// Nom d'affichage (préfère dishName, sinon foodDescription)
  String get displayName => dishName ?? (foodDescription.isNotEmpty ? foodDescription : 'Repas');

  /// Description d'affichage
  String get displayDescription => dishDescription ?? '';

  /// Vérifie si le repas est validé (lié au journal)
  bool get isValidated => linkedFoodEntryId != null;

  /// ID de liaison effectif (nouveau ou ancien champ)
  String? get effectiveLinkedId => linkedFoodEntryId ?? linkedEntryId;

  factory PlannedMealData.fromJson(Map<String, dynamic> json) {
    return PlannedMealData(
      dishName: json['dish_name'],
      dishDescription: json['dish_description'],
      linkedFoodEntryId: json['linked_food_entry_id'],
      estimatedQuantityG: json['estimated_quantity_g']?.toDouble(),
      aiReasoning: json['ai_reasoning'],
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
      if (dishName != null) 'dish_name': dishName,
      if (dishDescription != null) 'dish_description': dishDescription,
      if (linkedFoodEntryId != null) 'linked_food_entry_id': linkedFoodEntryId,
      if (estimatedQuantityG != null) 'estimated_quantity_g': estimatedQuantityG,
      if (aiReasoning != null) 'ai_reasoning': aiReasoning,
      if (foodDescription.isNotEmpty) 'food_description': foodDescription,
      if (linkedEntryId != null) 'linked_entry_id': linkedEntryId,
      if (calories != null) 'calories': calories,
      if (proteins != null) 'proteins': proteins,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
    };
  }

  /// Créer une copie avec modifications
  PlannedMealData copyWith({
    String? dishName,
    String? dishDescription,
    String? linkedFoodEntryId,
    double? estimatedQuantityG,
    String? aiReasoning,
    String? foodDescription,
    String? linkedEntryId,
    int? calories,
    double? proteins,
    double? carbs,
    double? fats,
  }) {
    return PlannedMealData(
      dishName: dishName ?? this.dishName,
      dishDescription: dishDescription ?? this.dishDescription,
      linkedFoodEntryId: linkedFoodEntryId ?? this.linkedFoodEntryId,
      estimatedQuantityG: estimatedQuantityG ?? this.estimatedQuantityG,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      foodDescription: foodDescription ?? this.foodDescription,
      linkedEntryId: linkedEntryId ?? this.linkedEntryId,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
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
  final String? linkedSessionId;
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
    this.linkedSessionId,
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
      linkedSessionId: json['linked_session_id'],
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
      if (linkedSessionId != null) 'linked_session_id': linkedSessionId,
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
    String? linkedSessionId,
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
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
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

/// Entrée du journal alimentaire (food_entry) pour affichage dans le planner
/// Représente un aliment ajouté manuellement depuis le journal (pas planifié par l'IA)
class JournalFoodEntry {
  final String id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, snack
  final int calories;
  final double proteins;
  final double carbs;
  final double fats;
  final double quantity;
  final String unit;
  final DateTime consumedAt;

  const JournalFoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.quantity,
    required this.unit,
    required this.consumedAt,
  });

  /// Créer depuis une map (résultat Supabase)
  /// [langCode] est utilisé pour choisir le nom localisé (fr/en)
  factory JournalFoodEntry.fromMap(Map<String, dynamic> map, {String langCode = 'fr'}) {
    // Extraire le nom depuis les différentes sources possibles
    String extractName() {
      // 1. Nom scanné (priorité - utilisé pour les repas planifiés validés et scans)
      if (map['scanned_food_name'] != null && (map['scanned_food_name'] as String).trim().isNotEmpty) {
        return map['scanned_food_name'] as String;
      }

      // 2. Aliment personnalisé (custom_foods)
      final customFood = map['custom_foods'] as Map<String, dynamic>?;
      if (customFood != null && customFood['name'] != null && (customFood['name'] as String).trim().isNotEmpty) {
        return customFood['name'] as String;
      }

      // 3. Aliment de la base de données (food_database)
      final foodDb = map['food_database'] as Map<String, dynamic>?;
      if (foodDb != null) {
        final nameKey = langCode == 'fr' ? 'name_fr' : 'name_en';
        if (foodDb[nameKey] != null && (foodDb[nameKey] as String).trim().isNotEmpty) {
          return foodDb[nameKey] as String;
        }
        // Fallback à l'autre langue
        final nameFr = foodDb['name_fr'] as String?;
        final nameEn = foodDb['name_en'] as String?;
        if (nameFr != null && nameFr.trim().isNotEmpty) return nameFr;
        if (nameEn != null && nameEn.trim().isNotEmpty) return nameEn;
      }

      // 4. Recette (recipes_database)
      final recipeDb = map['recipes_database'] as Map<String, dynamic>?;
      if (recipeDb != null) {
        final nameKey = langCode == 'fr' ? 'name_fr' : 'name_en';
        if (recipeDb[nameKey] != null && (recipeDb[nameKey] as String).trim().isNotEmpty) {
          return recipeDb[nameKey] as String;
        }
        final nameFr = recipeDb['name_fr'] as String?;
        final nameEn = recipeDb['name_en'] as String?;
        if (nameFr != null && nameFr.trim().isNotEmpty) return nameFr;
        if (nameEn != null && nameEn.trim().isNotEmpty) return nameEn;
      }

      // 5. Fallback: utiliser le type de repas comme nom lisible
      final mealType = map['meal_type'] as String?;
      if (mealType != null) {
        switch (mealType.toLowerCase()) {
          case 'breakfast':
            return 'Petit-déjeuner';
          case 'lunch':
            return 'Déjeuner';
          case 'dinner':
            return 'Dîner';
          case 'snack':
            return 'Collation';
        }
      }

      return 'Aliment';
    }

    return JournalFoodEntry(
      id: map['id'] as String,
      name: extractName(),
      mealType: map['meal_type'] as String? ?? 'snack',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      proteins: (map['proteins'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 100.0,
      unit: map['unit'] as String? ?? 'g',
      consumedAt: map['consumed_at'] != null
          ? DateTime.parse(map['consumed_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Données d'un jour dans le planner
class DayPlanData {
  final DateTime date;
  final List<PlannedActivity> activities;
  final List<PlannedWorkout> workouts;
  final List<JournalFoodEntry> journalEntries; // Aliments du journal non planifiés
  final bool isToday;
  final bool isPast;

  const DayPlanData({
    required this.date,
    required this.activities,
    required this.workouts,
    this.journalEntries = const [],
    required this.isToday,
    required this.isPast,
  });

  /// Nombre total d'items pour ce jour (inclut les journal entries)
  int get totalItems => activities.length + workouts.length + journalEntries.length;

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
    Map<DateTime, List<JournalFoodEntry>>? journalEntriesByDate,
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

      // Récupérer les journal entries pour ce jour
      final dayJournalEntries = journalEntriesByDate?[normalizedDate] ?? [];

      dayPlans[normalizedDate] = DayPlanData(
        date: normalizedDate,
        activities: dayActivities,
        workouts: dayWorkouts,
        journalEntries: dayJournalEntries,
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
  final result = !normalizedDate.isBefore(weekStart) && !normalizedDate.isAfter(weekEnd);
  // Debug: uncomment to trace
  // debugPrint('isInCurrentWeek: date=$normalizedDate, weekStart=$weekStart, weekEnd=$weekEnd, result=$result');
  return result;
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

/// Repas en attente de confirmation (généré par IA, pas encore ajouté au planner)
class PendingMeal {
  final DateTime plannedDate;
  final PlannedActivityType mealType;
  final String dishName;
  final String dishDescription;
  final int calories;
  final double proteins;
  final double carbs;
  final double fats;
  final double estimatedQuantityG;
  final String? aiReasoning;

  const PendingMeal({
    required this.plannedDate,
    required this.mealType,
    required this.dishName,
    required this.dishDescription,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.estimatedQuantityG,
    this.aiReasoning,
  });

  /// Convertir en activity_data pour insertion
  Map<String, dynamic> toActivityData() {
    return {
      'dish_name': dishName,
      'dish_description': dishDescription,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'estimated_quantity_g': estimatedQuantityG,
      if (aiReasoning != null) 'ai_reasoning': aiReasoning,
    };
  }

  /// Nom du jour formaté
  String get dayName {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[plannedDate.weekday - 1];
  }

  /// Nom du type de repas
  String get mealTypeName {
    switch (mealType) {
      case PlannedActivityType.breakfast:
        return 'Petit-déjeuner';
      case PlannedActivityType.lunch:
        return 'Déjeuner';
      case PlannedActivityType.dinner:
        return 'Dîner';
      case PlannedActivityType.snack:
        return 'Collation';
      default:
        return 'Repas';
    }
  }
}

// ============================================================================
// NOUVEAUX MODÈLES POUR PAGINATION MULTI-SESSIONS
// ============================================================================

/// Type de session en attente
enum PendingSessionType { workout, cardio }

/// Cardio en attente de confirmation (généré par IA)
class PendingCardio {
  final DateTime plannedDate;
  final String activityName; // "Course", "Vélo", "HIIT", etc.
  final String activityKey; // "running", "bike", "hiit", etc.
  final double? distanceKm;
  final int? durationMinutes;
  final HiitConfig? hiitConfig;
  final String? notes;

  const PendingCardio({
    required this.plannedDate,
    required this.activityName,
    required this.activityKey,
    this.distanceKm,
    this.durationMinutes,
    this.hiitConfig,
    this.notes,
  });

  /// Titre d'affichage (ex: "Course 5km" ou "HIIT 30min")
  String get displayTitle {
    if (distanceKm != null) {
      return '$activityName ${distanceKm!.toStringAsFixed(1)} km';
    } else if (durationMinutes != null) {
      return '$activityName ${durationMinutes} min';
    }
    return activityName;
  }

  /// Sous-titre avec la date
  String get displaySubtitle {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${days[plannedDate.weekday - 1]} ${plannedDate.day} ${months[plannedDate.month - 1]}';
  }

  /// Convertir en PlannedCardioData pour insertion
  PlannedCardioData toPlannedCardioData() {
    return PlannedCardioData(
      activityName: activityName,
      activityKey: activityKey,
      targetMinutes: durationMinutes,
      targetKm: distanceKm,
      hiitConfig: hiitConfig,
    );
  }

  /// Convertir en PlannedActivity pour affichage (preview)
  PlannedActivity toPlannedActivity() {
    return PlannedActivity(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      plannedDate: plannedDate,
      activityType: PlannedActivityType.cardio,
      activityData: toPlannedCardioData().toJson(),
      status: PlannedStatus.planned,
      isAiGenerated: true,
      createdAt: DateTime.now(),
    );
  }
}

/// Session unifiée (workout OU cardio) en attente de validation
class PendingSession {
  final PendingSessionType type;
  final DateTime plannedDate;
  final String displayTitle;
  final String displaySubtitle;
  final PendingWorkout? workout;
  final PendingCardio? cardio;

  const PendingSession({
    required this.type,
    required this.plannedDate,
    required this.displayTitle,
    required this.displaySubtitle,
    this.workout,
    this.cardio,
  });

  bool get isWorkout => type == PendingSessionType.workout;
  bool get isCardio => type == PendingSessionType.cardio;

  /// Créer depuis un PendingWorkout
  factory PendingSession.fromWorkout(PendingWorkout workout) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final subtitle = '${days[workout.plannedDate.weekday - 1]} ${workout.plannedDate.day} ${months[workout.plannedDate.month - 1]}';

    return PendingSession(
      type: PendingSessionType.workout,
      plannedDate: workout.plannedDate,
      displayTitle: workout.workoutType, // Juste le type, pas workoutName qui contient déjà la durée
      displaySubtitle: subtitle,
      workout: workout,
    );
  }

  /// Créer depuis un PendingCardio
  factory PendingSession.fromCardio(PendingCardio cardio) {
    return PendingSession(
      type: PendingSessionType.cardio,
      plannedDate: cardio.plannedDate,
      displayTitle: cardio.displayTitle,
      displaySubtitle: cardio.displaySubtitle,
      cardio: cardio,
    );
  }
}

/// Workout en attente de confirmation (existant, déplacé ici pour cohérence)
class PendingWorkout {
  final DateTime plannedDate;
  final String workoutName;
  final String workoutType; // "Back", "Push", "Legs", etc.
  final int durationMinutes;
  final String workoutPrompt;
  final List<WorkoutExercise>? exercises;

  const PendingWorkout({
    required this.plannedDate,
    required this.workoutName,
    required this.workoutType,
    required this.durationMinutes,
    required this.workoutPrompt,
    this.exercises,
  });

  /// Créer une copie avec des exercices
  PendingWorkout copyWithExercises(List<WorkoutExercise> exercises) {
    return PendingWorkout(
      plannedDate: plannedDate,
      workoutName: workoutName,
      workoutType: workoutType,
      durationMinutes: durationMinutes,
      workoutPrompt: workoutPrompt,
      exercises: exercises,
    );
  }

  /// Convertir en PlannedWorkout pour affichage (preview)
  PlannedWorkout toPlannedWorkout() {
    return PlannedWorkout(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      plannedDate: plannedDate,
      workoutName: workoutType, // Utiliser workoutType comme nom
      durationMinutes: durationMinutes,
      exercises: exercises ?? [],
      userPrompt: workoutPrompt,
      status: PlannedStatus.planned,
      isAiGenerated: true,
      createdAt: DateTime.now(),
    );
  }
}

/// Question en attente de réponse utilisateur
class PendingQuestion {
  final int sessionIndex;
  final String questionType; // 'duration', 'distance', 'intensity', etc.
  final String questionText;
  bool answered;
  String? answer;

  PendingQuestion({
    required this.sessionIndex,
    required this.questionType,
    required this.questionText,
    this.answered = false,
    this.answer,
  });

  PendingQuestion copyWith({
    int? sessionIndex,
    String? questionType,
    String? questionText,
    bool? answered,
    String? answer,
  }) {
    return PendingQuestion(
      sessionIndex: sessionIndex ?? this.sessionIndex,
      questionType: questionType ?? this.questionType,
      questionText: questionText ?? this.questionText,
      answered: answered ?? this.answered,
      answer: answer ?? this.answer,
    );
  }
}

/// Session partielle (en cours de construction, avant toutes les questions répondues)
class PartialSession {
  final PendingSessionType type;
  final DateTime plannedDate;
  final String? workoutType; // Pour workout: "Back", "Push", etc.
  final String? activityName; // Pour cardio: "Course", "Vélo", etc.
  final String? activityKey; // Pour cardio: "running", "bike", etc.
  int? durationMinutes;
  double? distanceKm;
  HiitConfig? hiitConfig;
  String? workoutPrompt;

  PartialSession({
    required this.type,
    required this.plannedDate,
    this.workoutType,
    this.activityName,
    this.activityKey,
    this.durationMinutes,
    this.distanceKm,
    this.hiitConfig,
    this.workoutPrompt,
  });

  bool get isWorkout => type == PendingSessionType.workout;
  bool get isCardio => type == PendingSessionType.cardio;

  /// Vérifier si toutes les infos nécessaires sont présentes
  bool get isComplete {
    if (isWorkout) {
      return workoutType != null && durationMinutes != null;
    } else {
      // Cardio: besoin soit de distance, soit de durée
      return activityName != null && (distanceKm != null || durationMinutes != null);
    }
  }

  /// Convertir en PendingWorkout (pour génération)
  PendingWorkout toPendingWorkout() {
    return PendingWorkout(
      plannedDate: plannedDate,
      workoutName: workoutType ?? 'Workout',
      workoutType: workoutType ?? 'Full Body',
      durationMinutes: durationMinutes ?? 45,
      workoutPrompt: workoutPrompt ?? 'Séance de $workoutType',
    );
  }

  /// Convertir en PendingCardio
  PendingCardio toPendingCardio() {
    return PendingCardio(
      plannedDate: plannedDate,
      activityName: activityName ?? 'Cardio',
      activityKey: activityKey ?? 'cardio',
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      hiitConfig: hiitConfig,
    );
  }
}

/// État du planning multi-sessions en cours
class SessionPlanningState {
  final List<PartialSession> sessions;
  final List<PendingQuestion> questions;
  int currentQuestionIndex;

  SessionPlanningState({
    required this.sessions,
    required this.questions,
    this.currentQuestionIndex = 0,
  });

  /// Toutes les questions ont été répondues ?
  bool get allQuestionsAnswered => questions.every((q) => q.answered);

  /// Prochaine question non répondue
  PendingQuestion? get nextQuestion {
    try {
      return questions.firstWhere((q) => !q.answered);
    } catch (_) {
      return null;
    }
  }

  /// Index de la prochaine question non répondue
  int get nextQuestionIndex {
    for (int i = 0; i < questions.length; i++) {
      if (!questions[i].answered) return i;
    }
    return -1;
  }

  /// Marquer la question courante comme répondue
  void answerCurrentQuestion(String answer) {
    final nextIdx = nextQuestionIndex;
    if (nextIdx >= 0 && nextIdx < questions.length) {
      questions[nextIdx].answered = true;
      questions[nextIdx].answer = answer;
    }
  }

  /// Appliquer la réponse à la session correspondante
  void applyAnswerToSession(int questionIndex, String answer) {
    if (questionIndex < 0 || questionIndex >= questions.length) return;

    final question = questions[questionIndex];
    final sessionIndex = question.sessionIndex;
    if (sessionIndex < 0 || sessionIndex >= sessions.length) return;

    final session = sessions[sessionIndex];

    // Parser la réponse selon le type de question
    switch (question.questionType) {
      case 'duration':
        // Extraire les minutes de la réponse (ex: "60 minutes", "45min", "1 heure")
        final minutes = _parseDuration(answer);
        if (minutes != null) {
          session.durationMinutes = minutes;
        }
        break;
      case 'distance':
        // Extraire la distance (ex: "5km", "10 kilomètres")
        final km = _parseDistance(answer);
        if (km != null) {
          session.distanceKm = km;
        }
        break;
      case 'intensity':
        // Gérer l'intensité si nécessaire
        break;
    }
  }

  /// Parser une durée depuis une réponse utilisateur
  int? _parseDuration(String answer) {
    final lowerAnswer = answer.toLowerCase().trim();

    // Chercher des patterns comme "60", "60min", "60 minutes", "1h", "1 heure"
    final minuteMatch = RegExp(r'(\d+)\s*(min|minutes?)?').firstMatch(lowerAnswer);
    if (minuteMatch != null) {
      return int.tryParse(minuteMatch.group(1)!);
    }

    final hourMatch = RegExp(r'(\d+)\s*(h|heure|heures?)').firstMatch(lowerAnswer);
    if (hourMatch != null) {
      final hours = int.tryParse(hourMatch.group(1)!);
      if (hours != null) return hours * 60;
    }

    // Juste un nombre
    final number = int.tryParse(lowerAnswer.replaceAll(RegExp(r'[^\d]'), ''));
    return number;
  }

  /// Parser une distance depuis une réponse utilisateur
  double? _parseDistance(String answer) {
    final lowerAnswer = answer.toLowerCase().trim();

    // Chercher des patterns comme "5", "5km", "5 kilomètres"
    final kmMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(km|kilomètres?)?').firstMatch(lowerAnswer);
    if (kmMatch != null) {
      return double.tryParse(kmMatch.group(1)!.replaceAll(',', '.'));
    }

    return null;
  }

  /// Créer une copie
  SessionPlanningState copyWith({
    List<PartialSession>? sessions,
    List<PendingQuestion>? questions,
    int? currentQuestionIndex,
  }) {
    return SessionPlanningState(
      sessions: sessions ?? this.sessions,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}
