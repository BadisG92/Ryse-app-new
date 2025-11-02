/// Models for the notification system
library;

/// Types de notifications disponibles
enum NotificationType {
  mealReminder,      // Rappels de repas
  waterReminder,     // Rappels d'hydratation
  streakProtection,  // Protection de série
  dailyGoalsSummary, // Résumé des objectifs quotidiens
  workoutReminder,   // Rappels d'entraînement
  weeklyRecap,       // Résumé hebdomadaire
  milestone,         // Célébrations de jalons
  reengagement,      // Réengagement utilisateurs inactifs
}

/// Type de repas pour les rappels
enum MealType {
  breakfast,
  lunch,
  dinner,
}

/// Préférences de notifications de l'utilisateur
class NotificationPreferences {
  // Master controls
  bool notificationsEnabled;

  // Quiet hours
  int quietHoursStart; // 0-23 (hour)
  int quietHoursEnd;   // 0-23 (hour)

  // Category toggles
  bool mealRemindersEnabled;
  bool waterRemindersEnabled;
  bool streakProtectionEnabled;
  bool dailyGoalsSummaryEnabled;
  bool workoutRemindersEnabled;
  bool weeklyRecapEnabled;
  bool milestonesEnabled;
  bool reengagementEnabled;

  // Meal reminder times (hours in 24h format)
  int breakfastTime;  // Default: 8
  int lunchTime;      // Default: 12 (12:30 avec minutes)
  int dinnerTime;     // Default: 19 (19:30 avec minutes)

  // Water reminder frequency (times per day: 1-4)
  int waterReminderFrequency; // Default: 2

  // Workout reminder time
  int workoutReminderTime; // Default: 18

  NotificationPreferences({
    this.notificationsEnabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.mealRemindersEnabled = true,
    this.waterRemindersEnabled = true,
    this.streakProtectionEnabled = true,
    this.dailyGoalsSummaryEnabled = true,
    this.workoutRemindersEnabled = true,
    this.weeklyRecapEnabled = true,
    this.milestonesEnabled = true,
    this.reengagementEnabled = true,
    this.breakfastTime = 8,
    this.lunchTime = 12,
    this.dinnerTime = 19,
    this.waterReminderFrequency = 2,
    this.workoutReminderTime = 18,
  });

  /// Convertir en Map pour stockage
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'mealRemindersEnabled': mealRemindersEnabled,
      'waterRemindersEnabled': waterRemindersEnabled,
      'streakProtectionEnabled': streakProtectionEnabled,
      'dailyGoalsSummaryEnabled': dailyGoalsSummaryEnabled,
      'workoutRemindersEnabled': workoutRemindersEnabled,
      'weeklyRecapEnabled': weeklyRecapEnabled,
      'milestonesEnabled': milestonesEnabled,
      'reengagementEnabled': reengagementEnabled,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'waterReminderFrequency': waterReminderFrequency,
      'workoutReminderTime': workoutReminderTime,
    };
  }

  /// Créer depuis Map
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      mealRemindersEnabled: json['mealRemindersEnabled'] ?? true,
      waterRemindersEnabled: json['waterRemindersEnabled'] ?? true,
      streakProtectionEnabled: json['streakProtectionEnabled'] ?? true,
      dailyGoalsSummaryEnabled: json['dailyGoalsSummaryEnabled'] ?? true,
      workoutRemindersEnabled: json['workoutRemindersEnabled'] ?? true,
      weeklyRecapEnabled: json['weeklyRecapEnabled'] ?? true,
      milestonesEnabled: json['milestonesEnabled'] ?? true,
      reengagementEnabled: json['reengagementEnabled'] ?? true,
      breakfastTime: json['breakfastTime'] ?? 8,
      lunchTime: json['lunchTime'] ?? 12,
      dinnerTime: json['dinnerTime'] ?? 19,
      waterReminderFrequency: json['waterReminderFrequency'] ?? 2,
      workoutReminderTime: json['workoutReminderTime'] ?? 18,
    );
  }

  /// Copier avec modifications
  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? mealRemindersEnabled,
    bool? waterRemindersEnabled,
    bool? streakProtectionEnabled,
    bool? dailyGoalsSummaryEnabled,
    bool? workoutRemindersEnabled,
    bool? weeklyRecapEnabled,
    bool? milestonesEnabled,
    bool? reengagementEnabled,
    int? breakfastTime,
    int? lunchTime,
    int? dinnerTime,
    int? waterReminderFrequency,
    int? workoutReminderTime,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      waterRemindersEnabled: waterRemindersEnabled ?? this.waterRemindersEnabled,
      streakProtectionEnabled: streakProtectionEnabled ?? this.streakProtectionEnabled,
      dailyGoalsSummaryEnabled: dailyGoalsSummaryEnabled ?? this.dailyGoalsSummaryEnabled,
      workoutRemindersEnabled: workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      weeklyRecapEnabled: weeklyRecapEnabled ?? this.weeklyRecapEnabled,
      milestonesEnabled: milestonesEnabled ?? this.milestonesEnabled,
      reengagementEnabled: reengagementEnabled ?? this.reengagementEnabled,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      waterReminderFrequency: waterReminderFrequency ?? this.waterReminderFrequency,
      workoutReminderTime: workoutReminderTime ?? this.workoutReminderTime,
    );
  }

  /// Vérifier si une notification peut être envoyée selon les quiet hours
  bool canSendNotificationAt(DateTime time) {
    if (!notificationsEnabled) return false;

    final hour = time.hour;

    // Si quietHoursEnd > quietHoursStart (ex: 22h -> 7h, traverse minuit)
    if (quietHoursStart > quietHoursEnd) {
      return hour < quietHoursStart && hour >= quietHoursEnd;
    }

    // Sinon (ex: 22h -> 23h, même jour)
    return hour < quietHoursStart || hour >= quietHoursEnd;
  }
}

/// Notification payload pour les actions
class NotificationPayload {
  final NotificationType type;
  final String? mealType;
  final int? streakDays;
  final Map<String, dynamic>? extraData;

  NotificationPayload({
    required this.type,
    this.mealType,
    this.streakDays,
    this.extraData,
  });

  String toJson() {
    return '${type.name}|${mealType ?? ''}|${streakDays ?? ''}';
  }

  factory NotificationPayload.fromJson(String json) {
    final parts = json.split('|');
    return NotificationPayload(
      type: NotificationType.values.firstWhere(
        (e) => e.name == parts[0],
        orElse: () => NotificationType.mealReminder,
      ),
      mealType: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
      streakDays: parts.length > 2 && parts[2].isNotEmpty ? int.tryParse(parts[2]) : null,
    );
  }
}
