/// Service de gestion des notifications locales
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_models.dart';
import '../services/localization_service.dart';
import '../services/dashboard_service.dart';
import '../services/streak_service.dart';
import '../services/global_state_manager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  NotificationPreferences? _preferences;

  static const String _prefsKey = 'notification_preferences';

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiser les timezones
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialiser avec callback pour les taps sur notifications
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Charger les préférences
      await _loadPreferences();

      _initialized = true;
      if (kDebugMode) debugPrint('✅ NotificationService initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Demander les permissions (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return result ?? true; // Android n'a pas besoin de permissions runtime
  }

  /// Charger les préférences depuis SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);

      if (json != null) {
        _preferences = NotificationPreferences.fromJson(jsonDecode(json));
      } else {
        _preferences = NotificationPreferences(); // Defaults
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading notification preferences: $e');
      _preferences = NotificationPreferences();
    }
  }

  /// Sauvegarder les préférences
  Future<void> savePreferences(NotificationPreferences prefs) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.setString(_prefsKey, jsonEncode(prefs.toJson()));
      _preferences = prefs;

      // Reschedule toutes les notifications avec les nouvelles préférences
      await scheduleAllNotifications();

      if (kDebugMode) debugPrint('✅ Notification preferences saved');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving preferences: $e');
    }
  }

  /// Récupérer les préférences actuelles
  NotificationPreferences getPreferences() {
    return _preferences ?? NotificationPreferences();
  }

  /// Planifier toutes les notifications selon les préférences
  Future<void> scheduleAllNotifications() async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();

    // Annuler toutes les notifications existantes
    await _notifications.cancelAll();

    if (!prefs.notificationsEnabled) {
      if (kDebugMode) debugPrint('⏸️ Notifications disabled, skipping schedule');
      return;
    }

    // Planifier les rappels de repas
    if (prefs.mealRemindersEnabled) {
      await _scheduleMealReminders(prefs);
    }

    // Planifier les rappels d'hydratation
    if (prefs.waterRemindersEnabled) {
      await _scheduleWaterReminders(prefs);
    }

    // Planifier la protection de série
    if (prefs.streakProtectionEnabled) {
      await _scheduleStreakProtection(prefs);
    }

    // Planifier le résumé quotidien
    if (prefs.dailyGoalsSummaryEnabled) {
      await _scheduleDailyGoalsSummary(prefs);
    }

    // Planifier les rappels d'entraînement
    if (prefs.workoutRemindersEnabled) {
      await _scheduleWorkoutReminders(prefs);
    }

    // Planifier le résumé hebdomadaire
    if (prefs.weeklyRecapEnabled) {
      await _scheduleWeeklyRecap(prefs);
    }

    if (kDebugMode) debugPrint('✅ All notifications scheduled');
  }

  /// Planifier les rappels de repas
  Future<void> _scheduleMealReminders(NotificationPreferences prefs) async {
    // Récupérer le prénom pour personnalisation
    final firstName = await _getUserFirstName();

    // Déjeuner uniquement pour MVP (comme recommandé)
    await _scheduleDailyNotification(
      id: 1,
      hour: prefs.lunchTime,
      minute: 30,
      title: _getMealReminderTitle(MealType.lunch, firstName: firstName),
      body: _getMealReminderBody(MealType.lunch),
      payload: NotificationPayload(
        type: NotificationType.mealReminder,
        mealType: 'lunch',
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Meal reminders scheduled (lunch only for MVP)');
  }

  /// Planifier les rappels d'hydratation
  Future<void> _scheduleWaterReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();

    // Pour MVP: 1 seul rappel à 15h
    await _scheduleDailyNotification(
      id: 10,
      hour: 15,
      minute: 0,
      title: _getWaterReminderTitle(firstName: firstName),
      body: _getWaterReminderBody(),
      payload: NotificationPayload(
        type: NotificationType.waterReminder,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Water reminders scheduled (15h for MVP)');
  }

  /// Planifier la protection de série
  Future<void> _scheduleStreakProtection(NotificationPreferences prefs) async {
    // Vérifier chaque soir à 19h si l'utilisateur a une série à protéger
    await _scheduleDailyNotification(
      id: 20,
      hour: 19,
      minute: 0,
      title: '', // Sera calculé dynamiquement
      body: '',  // Sera calculé dynamiquement
      payload: NotificationPayload(
        type: NotificationType.streakProtection,
      ).toJson(),
      checkBeforeSending: _shouldSendStreakProtection,
    );

    if (kDebugMode) debugPrint('✅ Streak protection scheduled (19h)');
  }

  /// Planifier le résumé des objectifs quotidiens
  Future<void> _scheduleDailyGoalsSummary(NotificationPreferences prefs) async {
    // Résumé à 20h
    await _scheduleDailyNotification(
      id: 30,
      hour: 20,
      minute: 0,
      title: '', // Sera calculé dynamiquement
      body: '',  // Sera calculé dynamiquement
      payload: NotificationPayload(
        type: NotificationType.dailyGoalsSummary,
      ).toJson(),
      checkBeforeSending: _shouldSendDailyGoalsSummary,
    );

    if (kDebugMode) debugPrint('✅ Daily goals summary scheduled (20h)');
  }

  /// Planifier les rappels d'entraînement
  Future<void> _scheduleWorkoutReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();

    await _scheduleDailyNotification(
      id: 40,
      hour: prefs.workoutReminderTime,
      minute: 0,
      title: _getWorkoutReminderTitle(firstName: firstName),
      body: _getWorkoutReminderBody(),
      payload: NotificationPayload(
        type: NotificationType.workoutReminder,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Workout reminders scheduled');
  }

  /// Planifier le résumé hebdomadaire
  Future<void> _scheduleWeeklyRecap(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();

    // Dimanche à 18h
    await _scheduleWeeklyNotification(
      id: 50,
      weekday: DateTime.sunday,
      hour: 18,
      minute: 0,
      title: _getWeeklyRecapTitle(firstName: firstName),
      body: _getWeeklyRecapBody(),
      payload: NotificationPayload(
        type: NotificationType.weeklyRecap,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Weekly recap scheduled (Sunday 18h)');
  }

  /// Planifier une notification quotidienne
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
    Future<bool> Function()? checkBeforeSending,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si l'heure est passée aujourd'hui, planifier pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Vérifier quiet hours
    if (!getPreferences().canSendNotificationAt(scheduledDate)) {
      if (kDebugMode) debugPrint('⏸️ Notification $id skipped (quiet hours)');
      return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Répéter chaque jour
      payload: payload,
    );
  }

  /// Planifier une notification hebdomadaire
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Trouver le prochain jour de la semaine
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// Détails de notification (Android + iOS)
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'ryze_daily_reminders',
        'Rappels quotidiens',
        channelDescription: 'Notifications pour les repas, hydratation et objectifs',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Vérifier et envoyer la protection de série si nécessaire
  Future<bool> _shouldSendStreakProtection() async {
    try {
      final streak = await StreakService.getCurrentStreak();
      // Envoyer seulement si série >= 5 jours (comme recommandé)
      if (streak >= 5) {
        // Envoyer la notification avec le nombre de jours
        final firstName = await _getUserFirstName();
        final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

        final title = isFrench
            ? "${firstName.isNotEmpty ? '$firstName, ' : ''}ta série de $streak jours ! 🔥"
            : "${firstName.isNotEmpty ? '$firstName, ' : ''}your $streak-day streak! 🔥";

        final body = isFrench
            ? "Log une activité (repas, eau, sport) avant minuit"
            : "Log any activity (meal, water, workout) before midnight";

        await sendImmediateNotification(
          title: title,
          body: body,
          type: NotificationType.streakProtection,
        );

        return false; // On a déjà envoyé, pas besoin de la notif planifiée
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier et envoyer le résumé des objectifs si nécessaire
  Future<bool> _shouldSendDailyGoalsSummary() async {
    try {
      final goals = await DashboardService.getDailyGoals();
      final completedCount = goals.where((g) => g.completed).length;

      // Envoyer si 1-2 objectifs manquants (comme recommandé)
      if (completedCount >= 1 && completedCount < 3) {
        final firstName = await _getUserFirstName();
        final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

        final title = isFrench
            ? "${firstName.isNotEmpty ? '$firstName, ' : ''}$completedCount/4 objectifs complétés 🎯"
            : "${firstName.isNotEmpty ? '$firstName, ' : ''}$completedCount/4 goals completed 🎯";

        // Trouver les objectifs manquants pour un message cohérent
        final missingGoals = goals.where((g) => !g.completed).toList();
        String body;

        if (missingGoals.isEmpty) {
          body = isFrench ? "Continue comme ça !" : "Keep it up!";
        } else {
          // Prendre les 2 premiers objectifs manquants
          final suggestions = <String>[];
          for (var goal in missingGoals.take(2)) {
            if (goal.label.toLowerCase().contains('eau') ||
                goal.label.toLowerCase().contains('water')) {
              suggestions.add(isFrench ? 'ton eau' : 'your water');
            } else if (goal.label.toLowerCase().contains('repas') ||
                       goal.label.toLowerCase().contains('meal')) {
              suggestions.add(isFrench ? 'ton repas' : 'your meal');
            } else if (goal.label.toLowerCase().contains('calorie')) {
              suggestions.add(isFrench ? 'tes calories' : 'your calories');
            } else if (goal.label.toLowerCase().contains('sport') ||
                       goal.label.toLowerCase().contains('workout')) {
              suggestions.add(isFrench ? 'ton workout' : 'your workout');
            }
          }

          if (suggestions.isEmpty) {
            body = isFrench
                ? "Tu y es presque ! Termine fort 💪"
                : "Almost there! Finish strong 💪";
          } else if (suggestions.length == 1) {
            body = isFrench
                ? "Tu y es presque ! Log ${suggestions[0]}"
                : "Almost there! Log ${suggestions[0]}";
          } else {
            body = isFrench
                ? "Tu y es presque ! Log ${suggestions[0]} ou ${suggestions[1]}"
                : "Almost there! Log ${suggestions[0]} or ${suggestions[1]}";
          }
        }

        await sendImmediateNotification(
          title: title,
          body: body,
          type: NotificationType.dailyGoalsSummary,
        );

        return false; // On a déjà envoyé
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) debugPrint('📲 Notification tapped: ${response.payload}');

    // TODO: Navigation selon le type de notification
    // Ex: ouvrir la page nutrition pour meal reminder
    // Ex: ouvrir la page hydratation pour water reminder
  }

  /// Envoyer une notification immédiate (pour milestones/celebrations)
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    NotificationType? type,
  }) async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled) return;

    // Vérifier les milestones sont activés si c'est ce type
    if (type == NotificationType.milestone && !prefs.milestonesEnabled) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // ID unique
      title,
      body,
      _notificationDetails(),
    );

    if (kDebugMode) debugPrint('✅ Immediate notification sent: $title');
  }

  /// Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    if (kDebugMode) debugPrint('🗑️ All notifications cancelled');
  }

  // === MESSAGES DES NOTIFICATIONS ===

  /// Récupérer le prénom de l'utilisateur pour personnalisation
  Future<String> _getUserFirstName() async {
    try {
      // Utiliser GlobalStateManager au lieu de DashboardService
      return GlobalStateManager.instance.userName;
    } catch (e) {
      return '';
    }
  }

  String _getMealReminderTitle(MealType mealType, {String firstName = ''}) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName.isNotEmpty ? '$firstName, ' : '';

    switch (mealType) {
      case MealType.breakfast:
        return isFrench ? "${name}petit-déjeuner 🍳" : "${name}breakfast time 🍳";
      case MealType.lunch:
        return isFrench ? "${name}l'heure du déjeuner 🥗" : "${name}lunch break 🥗";
      case MealType.dinner:
        return isFrench ? "${name}dernier repas 🍽️" : "${name}last meal 🍽️";
    }
  }

  String _getMealReminderBody(MealType mealType) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    switch (mealType) {
      case MealType.breakfast:
        return isFrench
            ? "Pas le temps ? Décris-moi ton repas et je m'en occupe"
            : "No time? Just describe your meal and I'll handle it";
      case MealType.lunch:
        return isFrench
            ? "Pas le temps ? Décris-moi ton repas et je m'en occupe"
            : "No time? Just describe your meal and I'll handle it";
      case MealType.dinner:
        return isFrench
            ? "Pas le temps ? Décris-moi ton repas et je m'en occupe"
            : "No time? Just describe your meal and I'll handle it";
    }
  }

  String _getWaterReminderTitle({String firstName = ''}) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName.isNotEmpty ? '$firstName, ' : '';
    return isFrench ? "${name}hydratation 💧" : "${name}hydration check 💧";
  }

  String _getWaterReminderBody() {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    return isFrench
        ? "Remplis ton verre pour atteindre ton objectif eau"
        : "Fill up your glass to hit your water goal";
  }

  String _getWorkoutReminderTitle({String firstName = ''}) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName.isNotEmpty ? '$firstName, ' : '';
    return isFrench ? "${name}c'est l'heure de bouger ! 🏋️" : "${name}time to move! 🏋️";
  }

  String _getWorkoutReminderBody() {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    return isFrench
        ? "Log une séance cardio ou muscu pour valider l'objectif"
        : "Log a cardio or strength session to hit your goal";
  }

  String _getWeeklyRecapTitle({String firstName = ''}) {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final name = firstName.isNotEmpty ? '$firstName, ' : '';
    return isFrench ? "${name}semaine terminée ! 📊" : "${name}week completed! 📊";
  }

  String _getWeeklyRecapBody() {
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    return isFrench
        ? "Vois tes progrès dans l'app. Continue comme ça !"
        : "Check your progress in the app. Keep it up!";
  }
}
