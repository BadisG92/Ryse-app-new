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
import '../services/notification_messages.dart';

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

    // Planifier la vérification "rien logué aujourd'hui" à 17h
    await _scheduleNothingLoggedCheck(prefs);

    // Planifier les notifications de réengagement (J+1, J+2, J+3)
    if (prefs.reengagementEnabled) {
      await scheduleReengagementNotifications();
    }

    if (kDebugMode) debugPrint('✅ All notifications scheduled');
  }

  /// Planifier les rappels de repas
  Future<void> _scheduleMealReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Petit-déjeuner (si activé)
    if (prefs.breakfastTime > 0) {
      await _scheduleDailyNotification(
        id: 1,
        hour: prefs.breakfastTime,
        minute: 0,
        title: NotificationMessages.getMealReminderTitle(
          mealType: 'breakfast',
          isFrench: isFrench,
          firstName: firstName,
        ),
        body: NotificationMessages.getMealReminderBody(
          mealType: 'breakfast',
          isFrench: isFrench,
        ),
        payload: NotificationPayload(
          type: NotificationType.mealReminder,
          mealType: 'breakfast',
        ).toJson(),
      );
    }

    // Déjeuner
    await _scheduleDailyNotification(
      id: 2,
      hour: prefs.lunchTime,
      minute: 30,
      title: NotificationMessages.getMealReminderTitle(
        mealType: 'lunch',
        isFrench: isFrench,
        firstName: firstName,
      ),
      body: NotificationMessages.getMealReminderBody(
        mealType: 'lunch',
        isFrench: isFrench,
      ),
      payload: NotificationPayload(
        type: NotificationType.mealReminder,
        mealType: 'lunch',
      ).toJson(),
    );

    // Dîner (si activé)
    if (prefs.dinnerTime > 0) {
      await _scheduleDailyNotification(
        id: 3,
        hour: prefs.dinnerTime,
        minute: 0,
        title: NotificationMessages.getMealReminderTitle(
          mealType: 'dinner',
          isFrench: isFrench,
          firstName: firstName,
        ),
        body: NotificationMessages.getMealReminderBody(
          mealType: 'dinner',
          isFrench: isFrench,
        ),
        payload: NotificationPayload(
          type: NotificationType.mealReminder,
          mealType: 'dinner',
        ).toJson(),
      );
    }

    if (kDebugMode) debugPrint('✅ Meal reminders scheduled');
  }

  /// Planifier les rappels d'hydratation
  Future<void> _scheduleWaterReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Rappels à 11h, 15h et 18h pour encourager l'hydratation
    final waterHours = [11, 15, 18];
    for (int i = 0; i < waterHours.length; i++) {
      await _scheduleDailyNotification(
        id: 10 + i,
        hour: waterHours[i],
        minute: 0,
        title: NotificationMessages.getWaterReminderTitle(
          isFrench: isFrench,
          firstName: firstName,
        ),
        body: NotificationMessages.getWaterReminderBody(isFrench: isFrench),
        payload: NotificationPayload(
          type: NotificationType.waterReminder,
        ).toJson(),
      );
    }

    if (kDebugMode) debugPrint('✅ Water reminders scheduled (11h, 15h, 18h)');
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
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    await _scheduleDailyNotification(
      id: 40,
      hour: prefs.workoutReminderTime,
      minute: 0,
      title: NotificationMessages.getWorkoutReminderTitle(
        isFrench: isFrench,
        firstName: firstName,
      ),
      body: NotificationMessages.getWorkoutReminderBody(isFrench: isFrench),
      payload: NotificationPayload(
        type: NotificationType.workoutReminder,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Workout reminders scheduled');
  }

  /// Planifier le résumé hebdomadaire
  Future<void> _scheduleWeeklyRecap(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Dimanche à 18h
    await _scheduleWeeklyNotification(
      id: 50,
      weekday: DateTime.sunday,
      hour: 18,
      minute: 0,
      title: NotificationMessages.getWeeklyRecapTitle(
        isFrench: isFrench,
        firstName: firstName,
      ),
      body: NotificationMessages.getWeeklyRecapBody(isFrench: isFrench),
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
      // Envoyer seulement si série >= 3 jours
      if (streak >= 3) {
        final firstName = await _getUserFirstName();
        final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

        await sendImmediateNotification(
          title: NotificationMessages.getStreakProtectionTitle(
            isFrench: isFrench,
            streakDays: streak,
            firstName: firstName,
          ),
          body: NotificationMessages.getStreakProtectionBody(
            isFrench: isFrench,
            streakDays: streak,
          ),
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
      final totalGoals = goals.length;

      // Envoyer si au moins 1 objectif complété mais pas tous
      if (completedCount >= 1 && completedCount < totalGoals) {
        final firstName = await _getUserFirstName();
        final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

        // Trouver les objectifs manquants
        final missingGoals = goals.where((g) => !g.completed).toList();
        final missingLabels = <String>[];

        for (var goal in missingGoals.take(2)) {
          if (goal.label.toLowerCase().contains('eau') ||
              goal.label.toLowerCase().contains('water')) {
            missingLabels.add(isFrench ? 'ton eau' : 'your water');
          } else if (goal.label.toLowerCase().contains('repas') ||
                     goal.label.toLowerCase().contains('meal')) {
            missingLabels.add(isFrench ? 'ton repas' : 'your meal');
          } else if (goal.label.toLowerCase().contains('calorie')) {
            missingLabels.add(isFrench ? 'tes calories' : 'your calories');
          } else if (goal.label.toLowerCase().contains('sport') ||
                     goal.label.toLowerCase().contains('workout')) {
            missingLabels.add(isFrench ? 'ton workout' : 'your workout');
          }
        }

        await sendImmediateNotification(
          title: NotificationMessages.getDailyGoalsSummaryTitle(
            isFrench: isFrench,
            completed: completedCount,
            total: totalGoals,
            firstName: firstName,
          ),
          body: NotificationMessages.getDailyGoalsSummaryBody(
            isFrench: isFrench,
            completed: completedCount,
            total: totalGoals,
            missingGoals: missingLabels.isNotEmpty ? missingLabels : null,
          ),
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

  // === HELPERS ===

  /// Récupérer le prénom de l'utilisateur pour personnalisation
  Future<String> _getUserFirstName() async {
    try {
      return GlobalStateManager.instance.userName;
    } catch (e) {
      return '';
    }
  }

  // === NOTIFICATIONS DE RÉENGAGEMENT ===

  static const String _lastActivityKey = 'last_activity_timestamp';
  static const String _previousStreakKey = 'previous_streak_before_inactive';

  /// Mettre à jour le timestamp de dernière activité
  /// Appeler cette méthode chaque fois que l'utilisateur log quelque chose
  Future<void> updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);

      // Sauvegarder aussi la série actuelle en cas d'inactivité
      final streak = await StreakService.getCurrentStreak();
      if (streak > 0) {
        await prefs.setInt(_previousStreakKey, streak);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating last activity: $e');
    }
  }

  /// Obtenir le nombre de jours d'inactivité
  /// Utile pour personnaliser les messages ou analytics
  Future<int> getDaysInactive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt(_lastActivityKey);

      if (lastActivity == null) return 0;

      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
      final now = DateTime.now();
      return now.difference(lastDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir la série précédente avant l'inactivité
  Future<int?> _getPreviousStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_previousStreakKey);
    } catch (e) {
      return null;
    }
  }

  /// Planifier les notifications de réengagement
  /// À appeler lors de la fermeture de l'app ou en background
  Future<void> scheduleReengagementNotifications() async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled) return;

    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';
    final previousStreak = await _getPreviousStreak();

    // Planifier J+1, J+2, J+3
    for (int day = 1; day <= 3; day++) {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(days: day));
      final notificationTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        day == 1 ? 20 : (day == 2 ? 18 : 12), // J+1: 20h, J+2: 18h, J+3: 12h
        0,
      );

      await _notifications.zonedSchedule(
        60 + day, // IDs 61, 62, 63
        NotificationMessages.getReengagementTitle(
          isFrench: isFrench,
          daysInactive: day,
          firstName: firstName,
        ),
        NotificationMessages.getReengagementBody(
          isFrench: isFrench,
          daysInactive: day,
          previousStreak: previousStreak,
        ),
        notificationTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: NotificationPayload(
          type: NotificationType.reengagement,
        ).toJson(),
      );
    }

    if (kDebugMode) debugPrint('✅ Reengagement notifications scheduled (J+1, J+2, J+3)');
  }

  /// Annuler les notifications de réengagement (quand l'utilisateur revient)
  Future<void> cancelReengagementNotifications() async {
    for (int i = 61; i <= 63; i++) {
      await _notifications.cancel(i);
    }
    if (kDebugMode) debugPrint('🗑️ Reengagement notifications cancelled');
  }

  // === NOTIFICATIONS INTELLIGENTES ===

  /// Envoyer une notification de milestone (nouveau record de série, poids atteint, etc.)
  Future<void> sendMilestoneNotification({
    required String milestoneType,
    required int value,
  }) async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled || !prefs.milestonesEnabled) return;

    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    await sendImmediateNotification(
      title: NotificationMessages.getMilestoneTitle(
        isFrench: isFrench,
        milestoneType: milestoneType,
        firstName: firstName,
      ),
      body: NotificationMessages.getMilestoneBody(
        isFrench: isFrench,
        milestoneType: milestoneType,
        value: value,
      ),
      type: NotificationType.milestone,
    );
  }

  /// Envoyer une notification "proche de l'objectif"
  Future<void> sendCloseToGoalNotification({
    required String goalType,
    required int remaining,
    required String unit,
  }) async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled) return;

    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    await sendImmediateNotification(
      title: NotificationMessages.getCloseToGoalTitle(
        isFrench: isFrench,
        goalType: goalType,
        firstName: firstName,
      ),
      body: NotificationMessages.getCloseToGoalBody(
        isFrench: isFrench,
        goalType: goalType,
        remaining: remaining,
        unit: unit,
      ),
      type: NotificationType.closeToGoal,
    );
  }

  /// Envoyer une notification "rien logué aujourd'hui" (à 17h par exemple)
  Future<void> checkAndSendNothingLoggedNotification() async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled) return;

    try {
      // Vérifier si quelque chose a été logué aujourd'hui
      final goals = await DashboardService.getDailyGoals();
      final anyCompleted = goals.any((g) => g.completed);

      if (!anyCompleted) {
        final firstName = await _getUserFirstName();
        final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

        await sendImmediateNotification(
          title: NotificationMessages.getNothingLoggedTitle(
            isFrench: isFrench,
            firstName: firstName,
          ),
          body: NotificationMessages.getNothingLoggedBody(isFrench: isFrench),
          type: NotificationType.nothingLogged,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error checking nothing logged: $e');
    }
  }

  /// Planifier une notification "rien logué" à 17h chaque jour
  Future<void> _scheduleNothingLoggedCheck(NotificationPreferences prefs) async {
    await _scheduleDailyNotification(
      id: 70,
      hour: 17,
      minute: 0,
      title: '', // Sera vérifié dynamiquement
      body: '',
      payload: NotificationPayload(
        type: NotificationType.nothingLogged,
      ).toJson(),
      checkBeforeSending: () async {
        await checkAndSendNothingLoggedNotification();
        return false; // On gère l'envoi manuellement
      },
    );
  }
}
