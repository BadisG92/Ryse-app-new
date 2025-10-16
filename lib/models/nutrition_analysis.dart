/// Modèle pour une analyse nutritionnelle générée par Coach Ryze
class NutritionAnalysis {
  final String id;
  final String userId;
  final DateTime date; // Date de la journée analysée
  final DateTime timestamp; // Date/heure de l'analyse
  final String context; // empty_day, in_progress, post_workout, end_of_day
  final String analysisText; // Texte formaté de l'analyse Gemini
  final double? score; // Score nutritionnel optionnel (0-100)
  final List<String> insights; // Points clés identifiés
  final List<String> recommendations; // Recommandations spécifiques

  // Métadonnées nutritionnelles
  final NutritionMetadata metadata;

  NutritionAnalysis({
    required this.id,
    required this.userId,
    required this.date,
    required this.timestamp,
    required this.context,
    required this.analysisText,
    this.score,
    required this.insights,
    required this.recommendations,
    required this.metadata,
  });

  /// Crée une instance depuis JSON (Supabase)
  factory NutritionAnalysis.fromJson(Map<String, dynamic> json) {
    return NutritionAnalysis(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: json['context'] as String,
      analysisText: json['analysis_text'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: NutritionMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>),
    );
  }

  /// Convertit en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'analysis_text': analysisText,
      'score': score,
      'insights': insights,
      'recommendations': recommendations,
      'metadata': metadata.toJson(),
    };
  }

  /// Copie avec modifications
  NutritionAnalysis copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? timestamp,
    String? context,
    String? analysisText,
    double? score,
    List<String>? insights,
    List<String>? recommendations,
    NutritionMetadata? metadata,
  }) {
    return NutritionAnalysis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      analysisText: analysisText ?? this.analysisText,
      score: score ?? this.score,
      insights: insights ?? this.insights,
      recommendations: recommendations ?? this.recommendations,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Métadonnées nutritionnelles pour le contexte de l'analyse
class NutritionMetadata {
  // Données globales de la journée
  final int totalCalories;
  final double totalProteins;
  final double totalCarbs;
  final double totalFats;
  final int waterIntake; // en ml

  // Objectifs
  final int calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatsTarget;

  // Métriques de progression
  final int caloriesRemaining;
  final double proteinPercentage;
  final double carbsPercentage;
  final double fatsPercentage;

  // Repas de la journée
  final int breakfastCalories;
  final int lunchCalories;
  final int dinnerCalories;
  final int snacksCalories;

  // Contexte sport (si pertinent)
  final bool hasWorkoutToday;
  final String? workoutType; // 'strength', 'cardio', 'hiit'
  final int? caloriesBurned;
  final DateTime? workoutTime;

  // Heure de l'analyse
  final String timeOfDay; // 'morning', 'afternoon', 'evening', 'night'

  NutritionMetadata({
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbs,
    required this.totalFats,
    required this.waterIntake,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatsTarget,
    required this.caloriesRemaining,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatsPercentage,
    required this.breakfastCalories,
    required this.lunchCalories,
    required this.dinnerCalories,
    required this.snacksCalories,
    required this.hasWorkoutToday,
    this.workoutType,
    this.caloriesBurned,
    this.workoutTime,
    required this.timeOfDay,
  });

  factory NutritionMetadata.fromJson(Map<String, dynamic> json) {
    return NutritionMetadata(
      totalCalories: json['total_calories'] as int,
      totalProteins: (json['total_proteins'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      totalFats: (json['total_fats'] as num).toDouble(),
      waterIntake: json['water_intake'] as int,
      calorieTarget: json['calorie_target'] as int,
      proteinTarget: (json['protein_target'] as num).toDouble(),
      carbsTarget: (json['carbs_target'] as num).toDouble(),
      fatsTarget: (json['fats_target'] as num).toDouble(),
      caloriesRemaining: json['calories_remaining'] as int,
      proteinPercentage: (json['protein_percentage'] as num).toDouble(),
      carbsPercentage: (json['carbs_percentage'] as num).toDouble(),
      fatsPercentage: (json['fats_percentage'] as num).toDouble(),
      breakfastCalories: json['breakfast_calories'] as int,
      lunchCalories: json['lunch_calories'] as int,
      dinnerCalories: json['dinner_calories'] as int,
      snacksCalories: json['snacks_calories'] as int,
      hasWorkoutToday: json['has_workout_today'] as bool,
      workoutType: json['workout_type'] as String?,
      caloriesBurned: json['calories_burned'] as int?,
      workoutTime: json['workout_time'] != null
          ? DateTime.parse(json['workout_time'] as String)
          : null,
      timeOfDay: json['time_of_day'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_calories': totalCalories,
      'total_proteins': totalProteins,
      'total_carbs': totalCarbs,
      'total_fats': totalFats,
      'water_intake': waterIntake,
      'calorie_target': calorieTarget,
      'protein_target': proteinTarget,
      'carbs_target': carbsTarget,
      'fats_target': fatsTarget,
      'calories_remaining': caloriesRemaining,
      'protein_percentage': proteinPercentage,
      'carbs_percentage': carbsPercentage,
      'fats_percentage': fatsPercentage,
      'breakfast_calories': breakfastCalories,
      'lunch_calories': lunchCalories,
      'dinner_calories': dinnerCalories,
      'snacks_calories': snacksCalories,
      'has_workout_today': hasWorkoutToday,
      'workout_type': workoutType,
      'calories_burned': caloriesBurned,
      'workout_time': workoutTime?.toIso8601String(),
      'time_of_day': timeOfDay,
    };
  }
}
