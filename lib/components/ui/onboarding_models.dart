// Modèles de données et logique de calcul pour l'onboarding

class UserProfile {
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String activity;
  final String goal;
  final List<String> obstacles;
  final List<String> restrictions;

  const UserProfile({
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.activity,
    required this.goal,
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

    // Facteur d'activité
    final activityFactors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very': 1.725,
      'extra': 1.9,
    };

    return bmr * (activityFactors[profile.activity] ?? 1.2);
  }

  static int calculateDailyGoal(UserProfile profile) {
    final tdee = calculateTotalNeeds(profile);
    if (tdee == 0) return 0;

    // Ajustement selon l'objectif
    switch (profile.goal) {
      case 'lose':
        return (tdee - 500).round();
      case 'gain':
        return (tdee + 300).round();
      case 'maintain':
      default:
        return tdee.round();
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