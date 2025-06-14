class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final String? activityLevel;
  final String? fitnessGoal;
  final String? profileImageUrl;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.fitnessGoal,
    this.profileImageUrl,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get fullName => '$firstName $lastName';
  
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  // Factory constructor from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      activityLevel: json['activity_level'],
      fitnessGoal: json['fitness_goal'],
      profileImageUrl: json['profile_image_url'],
      isEmailVerified: json['is_email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'fitness_goal': fitnessGoal,
      'profile_image_url': profileImageUrl,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? fitnessGoal,
    String? profileImageUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enums for user profile fields
enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  const Gender(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum ActivityLevel {
  sedentary('sedentary', 'Sedentary', 'Little to no exercise'),
  lightlyActive('lightly_active', 'Lightly Active', 'Light exercise 1-3 days/week'),
  moderatelyActive('moderately_active', 'Moderately Active', 'Moderate exercise 3-5 days/week'),
  veryActive('very_active', 'Very Active', 'Hard exercise 6-7 days/week'),
  extremelyActive('extremely_active', 'Extremely Active', 'Very hard exercise, physical job');

  const ActivityLevel(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;
}

enum FitnessGoal {
  loseWeight('lose_weight', 'Lose Weight', '🎯'),
  gainMuscle('gain_muscle', 'Gain Muscle', '💪'),
  maintainWeight('maintain_weight', 'Maintain Weight', '⚖️'),
  improveEndurance('improve_endurance', 'Improve Endurance', '🏃'),
  increaseStrength('increase_strength', 'Increase Strength', '🏋️'),
  generalFitness('general_fitness', 'General Fitness', '🌟');

  const FitnessGoal(this.value, this.displayName, this.emoji);
  final String value;
  final String displayName;
  final String emoji;
} 