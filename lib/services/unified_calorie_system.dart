import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Système unifié et cohérent pour les calories (alimentation + sport)
/// Basé sur les objectifs de poids et la durée souhaitée
class UnifiedCalorieSystem {
  static final _client = Supabase.instance.client;

  /// Calcule les objectifs cohérents alimentation + sport
  static Future<CalorieTargets> calculateUnifiedTargets(String userId) async {
    try {
      // 1. Récupérer le profil utilisateur
      final profile = await _getUserProfile(userId);
      if (profile == null) {
        return CalorieTargets.defaultTargets();
      }

      // 2. Calculer le TDEE (maintenance calories)
      final tdee = _calculateTDEE(profile);

      // 3. Déterminer l'objectif de poids et durée
      final weightGoal = await _getWeightGoal(userId) ?? WeightGoal.defaultGoal(profile);

      // 4. Calculer le déficit/surplus nécessaire
      final dailyDeficitSurplus = _calculateDailyDeficitSurplus(weightGoal);

      // 5. Répartir entre alimentation et sport
      final targets = _distributeCalorieTargets(
        tdee: tdee,
        dailyDeficitSurplus: dailyDeficitSurplus,
        userProfile: profile,
        weightGoal: weightGoal,
      );

      return targets;
    } catch (e) {
      debugPrint('❌ Erreur calcul objectifs unifiés: $e');
      return CalorieTargets.defaultTargets();
    }
  }

  /// Récupère le profil utilisateur
  static Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final result = await _client
          .from('users')
          .select('bmr, activity_level, fitness_goal, weight, height, age, gender')
          .eq('id', userId)
          .maybeSingle();
      
      return result;
    } catch (e) {
      debugPrint('❌ Erreur récupération profil: $e');
      return null;
    }
  }

  /// Calcule le TDEE (Total Daily Energy Expenditure)
  static double _calculateTDEE(Map<String, dynamic> profile) {
    final bmr = (profile['bmr'] as num?)?.toDouble() ?? 1600.0;
    final activityLevel = profile['activity_level'] as String? ?? 'moderate';

    final activityMultiplier = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };

    return bmr * activityMultiplier;
  }

  /// Récupère l'objectif de poids de l'utilisateur
  static Future<WeightGoal?> _getWeightGoal(String userId) async {
    try {
      final result = await _client
          .from('user_weight_goals')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (result == null) return null;

      return WeightGoal.fromJson(result);
    } catch (e) {
      debugPrint('❌ Pas d\'objectif de poids défini: $e');
      return null;
    }
  }

  /// Calcule le déficit/surplus quotidien nécessaire
  static double _calculateDailyDeficitSurplus(WeightGoal goal) {
    const kcalPerKg = 7700; // Approximation : 1kg = 7700 kcal
    
    final totalKcalNeeded = goal.weightChangeKg * kcalPerKg;
    final daysToGoal = goal.targetDate.difference(DateTime.now()).inDays;
    
    if (daysToGoal <= 0) return 0.0;
    
    return totalKcalNeeded / daysToGoal;
  }

  /// Répartit intelligemment entre alimentation et sport
  static CalorieTargets _distributeCalorieTargets({
    required double tdee,
    required double dailyDeficitSurplus,
    required Map<String, dynamic> userProfile,
    required WeightGoal weightGoal,
  }) {
    final activityLevel = userProfile['activity_level'] as String? ?? 'moderate';
    
    // Répartition selon le niveau d'activité et l'objectif
    double sportRatio;
    
    if (weightGoal.type == WeightGoalType.lose) {
      // Perte de poids : plus de sport pour préserver la masse musculaire
      sportRatio = switch (activityLevel) {
        'sedentary' => 0.3,    // 30% sport, 70% alimentation
        'light' => 0.4,        // 40% sport, 60% alimentation
        'moderate' => 0.5,     // 50% sport, 50% alimentation
        'active' => 0.6,       // 60% sport, 40% alimentation
        'very_active' => 0.7,  // 70% sport, 30% alimentation
        _ => 0.5,
      };
    } else if (weightGoal.type == WeightGoalType.gain) {
      // Prise de masse : moins de cardio, plus d'alimentation
      sportRatio = switch (activityLevel) {
        'sedentary' => 0.2,    // 20% sport, 80% alimentation
        'light' => 0.25,       // 25% sport, 75% alimentation
        'moderate' => 0.3,     // 30% sport, 70% alimentation
        'active' => 0.35,      // 35% sport, 65% alimentation
        'very_active' => 0.4,  // 40% sport, 60% alimentation
        _ => 0.3,
      };
    } else {
      // Maintien : équilibré
      sportRatio = 0.4;
    }

    // Calculs finaux
    final dailySportCalories = dailyDeficitSurplus.abs() * sportRatio;
    final weeklySportCalories = (dailySportCalories * 7).round();
    
    final dailyFoodAdjustment = dailyDeficitSurplus - 
        (weightGoal.type == WeightGoalType.lose ? dailySportCalories : -dailySportCalories);
    final dailyFoodCalories = (tdee + dailyFoodAdjustment).round();

    return CalorieTargets(
      // Alimentation
      dailyFoodCalories: dailyFoodCalories,
      tdee: tdee.round(),
      dailyFoodAdjustment: dailyFoodAdjustment.round(),
      
      // Sport
      weeklySportCalories: _roundToNearest100(weeklySportCalories),
      dailySportCalories: dailySportCalories.round(),
      
      // Objectif
      weightGoal: weightGoal,
      
      // Cohérence
      totalDailyDeficitSurplus: dailyDeficitSurplus.round(),
    );
  }

  /// Arrondit à la centaine la plus proche
  static int _roundToNearest100(int value) {
    return ((value / 100).round() * 100).clamp(300, 5000);
  }
}

/// Modèle pour l'objectif de poids
class WeightGoal {
  final WeightGoalType type;
  final double currentWeight;
  final double targetWeight;
  final DateTime targetDate;
  final int durationWeeks;

  const WeightGoal({
    required this.type,
    required this.currentWeight,
    required this.targetWeight,
    required this.targetDate,
    required this.durationWeeks,
  });

  double get weightChangeKg => targetWeight - currentWeight;

  factory WeightGoal.fromJson(Map<String, dynamic> json) {
    return WeightGoal(
      type: WeightGoalType.values.firstWhere(
        (e) => e.name == json['goal_type'],
        orElse: () => WeightGoalType.maintain,
      ),
      currentWeight: (json['current_weight'] as num).toDouble(),
      targetWeight: (json['target_weight'] as num).toDouble(),
      targetDate: DateTime.parse(json['target_date']),
      durationWeeks: json['duration_weeks'] ?? 12,
    );
  }

  /// Objectif par défaut basé sur le fitness_goal existant
  factory WeightGoal.defaultGoal(Map<String, dynamic> profile) {
    final currentWeight = (profile['weight'] as num?)?.toDouble() ?? 70.0;
    final fitnessGoal = profile['fitness_goal'] as String? ?? 'maintain';
    
    final type = switch (fitnessGoal) {
      'lose' => WeightGoalType.lose,
      'gain' => WeightGoalType.gain,
      _ => WeightGoalType.maintain,
    };

    // Objectifs par défaut raisonnables
    double targetWeight = currentWeight;
    int durationWeeks = 12;

    if (type == WeightGoalType.lose) {
      targetWeight = currentWeight - 5.0; // -5kg par défaut
      durationWeeks = 20; // 5 mois pour perdre 5kg sainement
    } else if (type == WeightGoalType.gain) {
      targetWeight = currentWeight + 3.0; // +3kg par défaut
      durationWeeks = 16; // 4 mois pour prendre 3kg
    }

    return WeightGoal(
      type: type,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      targetDate: DateTime.now().add(Duration(days: durationWeeks * 7)),
      durationWeeks: durationWeeks,
    );
  }
}

enum WeightGoalType { lose, maintain, gain }

/// Résultat unifié des calculs de calories
class CalorieTargets {
  // Alimentation
  final int dailyFoodCalories;
  final int tdee;
  final int dailyFoodAdjustment; // Déficit/surplus alimentaire

  // Sport  
  final int weeklySportCalories;
  final int dailySportCalories;

  // Objectif
  final WeightGoal weightGoal;

  // Cohérence
  final int totalDailyDeficitSurplus;

  const CalorieTargets({
    required this.dailyFoodCalories,
    required this.tdee,
    required this.dailyFoodAdjustment,
    required this.weeklySportCalories,
    required this.dailySportCalories,
    required this.weightGoal,
    required this.totalDailyDeficitSurplus,
  });

  /// Objectifs par défaut en cas d'erreur
  factory CalorieTargets.defaultTargets() {
    final defaultGoal = WeightGoal(
      type: WeightGoalType.maintain,
      currentWeight: 70.0,
      targetWeight: 70.0,
      targetDate: DateTime.now().add(const Duration(days: 84)),
      durationWeeks: 12,
    );

    return CalorieTargets(
      dailyFoodCalories: 2000,
      tdee: 2000,
      dailyFoodAdjustment: 0,
      weeklySportCalories: 1200,
      dailySportCalories: 171,
      weightGoal: defaultGoal,
      totalDailyDeficitSurplus: 0,
    );
  }

  /// Vérifie la cohérence des calculs
  bool get isCoherent {
    final calculatedDeficit = dailyFoodAdjustment + 
        (weightGoal.type == WeightGoalType.lose ? dailySportCalories : -dailySportCalories);
    return (calculatedDeficit - totalDailyDeficitSurplus).abs() <= 10; // Tolérance 10 kcal
  }

  /// Description textuelle de l'objectif
  String get goalDescription {
    final weightChange = weightGoal.weightChangeKg.abs();
    final weeks = weightGoal.durationWeeks;
    
    switch (weightGoal.type) {
      case WeightGoalType.lose:
        return 'Perdre ${weightChange.toStringAsFixed(1)}kg en $weeks semaines';
      case WeightGoalType.gain:
        return 'Prendre ${weightChange.toStringAsFixed(1)}kg en $weeks semaines';
      case WeightGoalType.maintain:
        return 'Maintenir votre poids actuel';
    }
  }
}

