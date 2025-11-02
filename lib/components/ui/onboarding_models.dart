// Modèles de données et logique de calcul pour l'onboarding
import 'package:flutter/material.dart';

class UserProfile {
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String activity;
  final String goal;
  final String? targetWeight; // Poids cible optionnel
  final List<String> obstacles;
  final List<String> restrictions;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.activity,
    required this.goal,
    this.targetWeight,
    required this.obstacles,
    required this.restrictions,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      gender: data['gender'] ?? '',
      age: data['age'] ?? '',
      weight: data['weight'] ?? '',
      height: data['height'] ?? '',
      activity: data['activity'] ?? '',
      goal: data['goal'] ?? '',
      targetWeight: data['targetWeight'],
      obstacles: List<String>.from(data['obstacles'] ?? []),
      restrictions: List<String>.from(data['restrictions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'activity': activity,
      'goal': goal,
      'targetWeight': targetWeight,
      'obstacles': obstacles,
      'restrictions': restrictions,
    };
  }
}

class MetabolicCalculations {
  static double calculateBMR(UserProfile profile) {
    if (profile.gender.isEmpty || 
        profile.age.isEmpty || 
        profile.weight.isEmpty || 
        profile.height.isEmpty) {
      return 0;
    }

    final age = int.tryParse(profile.age) ?? 0;
    final weight = double.tryParse(profile.weight) ?? 0;
    final height = double.tryParse(profile.height) ?? 0;

    // Calcul BMR (Mifflin-St Jeor)
    if (profile.gender == 'Homme') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  static double calculateTotalNeeds(UserProfile profile) {
    final bmr = calculateBMR(profile);
    if (bmr == 0 || profile.activity.isEmpty) return 0;

    // Facteur d'activité - synchronisé avec dashboard_models.dart et onboarding (4 niveaux)
    final activityFactors = {
      'low': 1.2,      // Rarement (sédentaire)
      'light': 1.375,  // Quelques fois (légèrement actif)
      'moderate': 1.55, // Régulièrement (modérément actif)
      'high': 1.725,   // Très souvent (très actif)
    };

    return bmr * (activityFactors[profile.activity] ?? 1.2);
  }

  static int calculateDailyGoal(UserProfile profile) {
    final tdee = calculateTotalNeeds(profile);
    final bmr = calculateBMR(profile);
    if (tdee == 0) return 0;

    // Planchers de sécurité selon le genre
    final minimumCalories = profile.gender == 'Homme' ? 1500 : 1200;
    final bmrFloor = (bmr * 0.9).round(); // Jamais plus de 10% sous BMR
    final safeMinimum = bmrFloor > minimumCalories ? bmrFloor : minimumCalories;

    // Ajustement selon l'objectif avec déficit/surplus adaptatif
    int targetCalories;

    switch (profile.goal) {
      case 'lose':
        // Déficit adaptatif : 20% du TDEE (max 500 kcal)
        final deficit = (tdee * 0.20).round();
        final cappedDeficit = deficit > 500 ? 500 : deficit;
        targetCalories = (tdee - cappedDeficit).round();

        // Appliquer le plancher de sécurité
        if (targetCalories < safeMinimum) {
          targetCalories = safeMinimum;
        }
        break;

      case 'gain':
        // Surplus adaptatif : 15% du TDEE (max 500 kcal)
        final surplus = (tdee * 0.15).round();
        final cappedSurplus = surplus > 500 ? 500 : surplus;
        targetCalories = (tdee + cappedSurplus).round();
        break;

      case 'maintain':
      default:
        targetCalories = tdee.round();
        break;
    }

    return targetCalories;
  }

  /// Calcule un déficit/surplus optimal basé sur le poids cible (optionnel)
  /// Retourne un ajustement calorique réaliste selon l'écart de poids
  static int? calculateTargetBasedAdjustment(UserProfile profile) {
    if (profile.targetWeight == null || profile.targetWeight!.isEmpty) {
      return null; // Pas de poids cible défini
    }

    final currentWeight = double.tryParse(profile.weight);
    final targetWeight = double.tryParse(profile.targetWeight!);

    if (currentWeight == null || targetWeight == null || currentWeight <= 0 || targetWeight <= 0) {
      return null;
    }

    final weightDifference = currentWeight - targetWeight; // Positif = perte, Négatif = gain

    if (weightDifference.abs() < 1) {
      return 0; // Différence négligeable, pas d'ajustement
    }

    // Rythme de perte/gain sain selon le genre et l'objectif
    final isMale = profile.gender == 'Homme';
    final maxWeeklyLoss = isMale ? 0.75 : 0.5; // kg/semaine
    final maxWeeklyGain = 0.25; // kg/semaine (conservateur)

    double weeklyTarget;
    int weeksNeeded;

    if (weightDifference > 0) {
      // PERTE DE POIDS
      weeklyTarget = maxWeeklyLoss;
      weeksNeeded = (weightDifference / weeklyTarget).ceil();

      // Limiter à 6 mois max (26 semaines) pour éviter objectifs irréalistes
      if (weeksNeeded > 26) {
        weeksNeeded = 26;
        weeklyTarget = weightDifference / 26;
      }

      // 1kg de graisse ≈ 7700 kcal de déficit
      final dailyDeficit = (weeklyTarget * 7700) / 7;
      return -dailyDeficit.round(); // Négatif pour déficit

    } else {
      // PRISE DE POIDS
      final weightToGain = weightDifference.abs();
      weeklyTarget = maxWeeklyGain;
      weeksNeeded = (weightToGain / weeklyTarget).ceil();

      // Limiter à 6 mois max
      if (weeksNeeded > 26) {
        weeksNeeded = 26;
        weeklyTarget = weightToGain / 26;
      }

      // Surplus pour prise de poids
      final dailySurplus = (weeklyTarget * 7700) / 7;
      return dailySurplus.round(); // Positif pour surplus
    }
  }

  /// Calcule l'objectif calorique en tenant compte du poids cible (version avancée)
  /// Si targetWeight est défini, utilise un calcul plus précis
  static int calculateDailyGoalWithTarget(UserProfile profile) {
    final tdee = calculateTotalNeeds(profile);
    final bmr = calculateBMR(profile);
    if (tdee == 0) return 0;

    // Essayer de calculer selon le poids cible
    final targetAdjustment = calculateTargetBasedAdjustment(profile);

    if (targetAdjustment != null) {
      // Utiliser le déficit/surplus basé sur le poids cible
      int targetCalories = (tdee + targetAdjustment).round();

      // Appliquer les planchers de sécurité
      final minimumCalories = profile.gender == 'Homme' ? 1500 : 1200;
      final bmrFloor = (bmr * 0.9).round();
      final safeMinimum = bmrFloor > minimumCalories ? bmrFloor : minimumCalories;

      // Pour la perte, ne jamais descendre sous le plancher
      if (targetAdjustment < 0 && targetCalories < safeMinimum) {
        targetCalories = safeMinimum;
      }

      // Pour le gain, limiter à +500 kcal max par jour
      if (targetAdjustment > 0 && targetAdjustment > 500) {
        targetCalories = (tdee + 500).round();
      }

      return targetCalories;
    }

    // Fallback : utiliser la méthode standard
    return calculateDailyGoal(profile);
  }

  /// Calcule l'estimation du temps nécessaire pour atteindre le poids cible
  /// Retourne un Map avec les détails de la progression estimée
  static Map<String, dynamic> calculateTimeEstimate(UserProfile profile) {
    if (profile.targetWeight == null || profile.targetWeight!.isEmpty) {
      return {
        'weeks': 0,
        'months': 0,
        'rate': 0.0,
        'type': 'none',
        'totalChange': 0.0,
      };
    }

    final currentWeight = double.tryParse(profile.weight);
    final targetWeight = double.tryParse(profile.targetWeight!);

    if (currentWeight == null || targetWeight == null || currentWeight <= 0 || targetWeight <= 0) {
      return {
        'weeks': 0,
        'months': 0,
        'rate': 0.0,
        'type': 'none',
        'totalChange': 0.0,
      };
    }

    final weightDifference = currentWeight - targetWeight;

    if (weightDifference.abs() < 1) {
      return {
        'weeks': 0,
        'months': 0,
        'rate': 0.0,
        'type': 'maintain',
        'totalChange': 0.0,
      };
    }

    final isMale = profile.gender == 'Homme';
    final maxWeeklyLoss = isMale ? 0.75 : 0.5;
    final maxWeeklyGain = 0.25;

    double weeklyRate;
    int weeks;
    String type;

    if (weightDifference > 0) {
      // PERTE DE POIDS
      type = 'loss';
      weeklyRate = maxWeeklyLoss;
      weeks = (weightDifference / weeklyRate).ceil();

      // Limiter à 6 mois max
      if (weeks > 26) {
        weeks = 26;
        weeklyRate = weightDifference / 26;
      }
    } else {
      // GAIN DE POIDS
      type = 'gain';
      final weightToGain = weightDifference.abs();
      weeklyRate = maxWeeklyGain;
      weeks = (weightToGain / weeklyRate).ceil();

      // Limiter à 6 mois max
      if (weeks > 26) {
        weeks = 26;
        weeklyRate = weightToGain / 26;
      }
    }

    return {
      'weeks': weeks,
      'months': (weeks / 4.33).round(), // Moyenne de 4.33 semaines par mois
      'rate': weeklyRate,
      'type': type,
      'totalChange': weightDifference.abs(),
    };
  }

  /// Génère un texte descriptif de l'estimation pour l'UI
  static String getTimeEstimateText(UserProfile profile, {bool isMetric = true}) {
    final estimate = calculateTimeEstimate(profile);

    // Ne rien afficher si pas de poids cible
    if (estimate['type'] == 'none') {
      return '';
    }

    // Ne rien afficher si maintien (pas besoin d'estimation de temps)
    if (estimate['type'] == 'maintain' || profile.goal == 'maintain') {
      return '';
    }

    final weeks = estimate['weeks'] as int;
    final months = estimate['months'] as int;
    final totalChange = estimate['totalChange'] as double;
    final type = estimate['type'] as String;

    final weightUnit = isMetric ? 'kg' : 'lbs';
    final action = type == 'loss' ? 'perdre' : 'prendre';

    // Format simplifié sans le détail kg/semaine
    if (months == 0) {
      return 'Environ $weeks semaines pour $action ${totalChange.toStringAsFixed(1)} $weightUnit';
    } else if (months == 1) {
      return 'Environ 1 mois pour $action ${totalChange.toStringAsFixed(1)} $weightUnit';
    } else {
      return 'Environ $months mois pour $action ${totalChange.toStringAsFixed(1)} $weightUnit';
    }
  }

  static Map<String, int> calculateMacros(UserProfile profile) {
    final calories = calculateDailyGoal(profile);
    if (calories == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    // Répartition selon l'objectif
    switch (profile.goal) {
      case 'lose':
        // Haut protéine pour maintenir muscle
        return {
          'protein': ((calories * 0.35) / 4).round(),
          'carbs': ((calories * 0.30) / 4).round(),
          'fat': ((calories * 0.35) / 9).round(),
        };
      case 'gain':
        // Plus de glucides pour l'énergie
        return {
          'protein': ((calories * 0.25) / 4).round(),
          'carbs': ((calories * 0.50) / 4).round(),
          'fat': ((calories * 0.25) / 9).round(),
        };
      case 'maintain':
      default:
        // Équilibré
        return {
          'protein': ((calories * 0.30) / 4).round(),
          'carbs': ((calories * 0.40) / 4).round(),
          'fat': ((calories * 0.30) / 9).round(),
        };
    }
  }
}

class OnboardingStep {
  final String title;
  final String subtitle;
  final Widget content;

  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.content,
  });
}

class StatCard {
  final String value;
  final String label;

  const StatCard({
    required this.value,
    required this.label,
  });
} 
