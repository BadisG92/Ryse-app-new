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
import '../services/ai_notification_service.dart';
import '../services/weekly_planner_service.dart';
import '../models/weekly_planner_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  NotificationPreferences? _preferences;

  // Anti-doublon: timestamp du dernier scheduling
  DateTime? _lastScheduleTime;
  bool _isScheduling = false;

  // Compteur pour IDs uniques de notifications immédiates
  static int _immediateNotificationCounter = 0;

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
  /// Avec protection anti-doublon et debounce intégré
  Future<void> scheduleAllNotifications({bool force = false}) async {
    if (!_initialized) await initialize();

    // Protection anti-appels multiples simultanés
    if (_isScheduling && !force) {
      if (kDebugMode) debugPrint('⏸️ Already scheduling notifications, skipping');
      return;
    }

    // Debounce: ignorer si appelé il y a moins de 2 secondes
    final now = DateTime.now();
    if (!force && _lastScheduleTime != null) {
      final diff = now.difference(_lastScheduleTime!).inMilliseconds;
      if (diff < 2000) {
        if (kDebugMode) debugPrint('⏸️ Debounce: skipping schedule (last was ${diff}ms ago)');
        return;
      }
    }

    _isScheduling = true;
    _lastScheduleTime = now;

    try {
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

      // Planifier la protection de série (notification intelligente)
      if (prefs.streakProtectionEnabled) {
        await _scheduleStreakProtection(prefs);
      }

      // Planifier le résumé quotidien (notification intelligente)
      if (prefs.dailyGoalsSummaryEnabled) {
        await _scheduleDailyGoalsSummary(prefs);
      }

      // Planifier le résumé hebdomadaire
      if (prefs.weeklyRecapEnabled) {
        await _scheduleWeeklyRecap(prefs);
      }

      // Planifier la vérification "rien logué aujourd'hui" à 17h
      if (prefs.nothingLoggedEnabled) {
        await _scheduleNothingLoggedCheck(prefs);
      }

      // Planifier le rappel des séances planifiées du jour
      if (prefs.plannedActivityReminderEnabled) {
        await _schedulePlannedActivityReminder(prefs);
      }

      // Note: Les notifications de réengagement sont gérées séparément
      // et annulées quand l'utilisateur est actif

      if (kDebugMode) debugPrint('✅ All notifications scheduled');
    } finally {
      _isScheduling = false;
    }
  }

  /// Planifier les rappels de repas
  /// Avec 30% de chance d'utiliser un message IA personnalisé
  Future<void> _scheduleMealReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Petit-déjeuner (si activé)
    if (prefs.breakfastTime > 0) {
      final defaultTitle = NotificationMessages.getMealReminderTitle(
        mealType: 'breakfast',
        isFrench: isFrench,
        firstName: firstName,
      );
      final defaultBody = NotificationMessages.getMealReminderBody(
        mealType: 'breakfast',
        isFrench: isFrench,
      );

      // Essayer un message IA (30% de chance)
      final content = await AiNotificationService.instance.getNotificationContent(
        type: AiNotificationType.meal,
        defaultTitle: defaultTitle,
        defaultBody: defaultBody,
      );

      await _scheduleDailyNotification(
        id: 1,
        hour: prefs.breakfastTime,
        minute: 0,
        title: content.title,
        body: content.body,
        payload: NotificationPayload(
          type: NotificationType.mealReminder,
          mealType: 'breakfast',
        ).toJson(),
      );
    }

    // Déjeuner
    {
      final defaultTitle = NotificationMessages.getMealReminderTitle(
        mealType: 'lunch',
        isFrench: isFrench,
        firstName: firstName,
      );
      final defaultBody = NotificationMessages.getMealReminderBody(
        mealType: 'lunch',
        isFrench: isFrench,
      );

      final content = await AiNotificationService.instance.getNotificationContent(
        type: AiNotificationType.meal,
        defaultTitle: defaultTitle,
        defaultBody: defaultBody,
      );

      await _scheduleDailyNotification(
        id: 2,
        hour: prefs.lunchTime,
        minute: 30,
        title: content.title,
        body: content.body,
        payload: NotificationPayload(
          type: NotificationType.mealReminder,
          mealType: 'lunch',
        ).toJson(),
      );
    }

    // Dîner (si activé)
    if (prefs.dinnerTime > 0) {
      final defaultTitle = NotificationMessages.getMealReminderTitle(
        mealType: 'dinner',
        isFrench: isFrench,
        firstName: firstName,
      );
      final defaultBody = NotificationMessages.getMealReminderBody(
        mealType: 'dinner',
        isFrench: isFrench,
      );

      final content = await AiNotificationService.instance.getNotificationContent(
        type: AiNotificationType.meal,
        defaultTitle: defaultTitle,
        defaultBody: defaultBody,
      );

      await _scheduleDailyNotification(
        id: 3,
        hour: prefs.dinnerTime,
        minute: 0,
        title: content.title,
        body: content.body,
        payload: NotificationPayload(
          type: NotificationType.mealReminder,
          mealType: 'dinner',
        ).toJson(),
      );
    }

    if (kDebugMode) debugPrint('✅ Meal reminders scheduled');
  }

  /// Planifier les rappels d'hydratation selon la fréquence choisie
  /// Avec 30% de chance d'utiliser un message IA personnalisé
  Future<void> _scheduleWaterReminders(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final isFrench = LocalizationService.instance.currentLanguageCode == 'fr';

    // Heures selon la fréquence choisie (1-4 par jour)
    // Fréquence 1: 14h (milieu de journée)
    // Fréquence 2: 11h, 16h
    // Fréquence 3: 10h, 14h, 17h
    // Fréquence 4: 9h, 12h, 15h, 18h
    final List<int> waterHours;
    switch (prefs.waterReminderFrequency) {
      case 1:
        waterHours = [14];
        break;
      case 2:
        waterHours = [11, 16];
        break;
      case 3:
        waterHours = [10, 14, 17];
        break;
      case 4:
      default:
        waterHours = [9, 12, 15, 18];
        break;
    }

    for (int i = 0; i < waterHours.length; i++) {
      final defaultTitle = NotificationMessages.getWaterReminderTitle(
        isFrench: isFrench,
        firstName: firstName,
      );
      final defaultBody = NotificationMessages.getWaterReminderBody(isFrench: isFrench);

      // Essayer un message IA (30% de chance)
      final content = await AiNotificationService.instance.getNotificationContent(
        type: AiNotificationType.water,
        defaultTitle: defaultTitle,
        defaultBody: defaultBody,
      );

      await _scheduleDailyNotification(
        id: 10 + i,
        hour: waterHours[i],
        minute: 0,
        title: content.title,
        body: content.body,
        payload: NotificationPayload(
          type: NotificationType.waterReminder,
        ).toJson(),
      );
    }

    if (kDebugMode) debugPrint('✅ Water reminders scheduled (${waterHours.length}x/day at $waterHours)');
  }

  /// Planifier la protection de série avec message engageant
  /// Avec 30% de chance d'utiliser un message IA personnalisé
  Future<void> _scheduleStreakProtection(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Message générique engageant pour protéger la série
    final defaultTitle = isFrench
        ? '🔥 ${firstName.isNotEmpty ? "$firstName, p" : "P"}rotège ta série !'
        : isGerman
            ? '🔥 ${firstName.isNotEmpty ? "$firstName, s" : "S"}chütze deine Serie!'
            : '🔥 ${firstName.isNotEmpty ? "$firstName, p" : "P"}rotect your streak!';
    final defaultBody = isFrench
        ? 'Tu n\'as pas encore logué aujourd\'hui. Ne perds pas ta progression !'
        : isGerman
            ? 'Du hast heute noch nichts eingetragen. Verliere nicht deinen Fortschritt!'
            : 'You haven\'t logged anything today. Don\'t lose your progress!';

    // Essayer un message IA (30% de chance)
    final content = await AiNotificationService.instance.getNotificationContent(
      type: AiNotificationType.streak,
      defaultTitle: defaultTitle,
      defaultBody: defaultBody,
    );

    await _scheduleDailyNotification(
      id: 20,
      hour: 20,
      minute: 0,
      title: content.title,
      body: content.body,
      payload: NotificationPayload(
        type: NotificationType.streakProtection,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Streak protection scheduled (20h)');
  }

  /// Planifier le résumé des objectifs quotidiens avec message engageant
  Future<void> _scheduleDailyGoalsSummary(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Message motivant pour le résumé du soir
    final title = isFrench
        ? '📊 ${firstName.isNotEmpty ? "$firstName, c" : "C"}\'est l\'heure du bilan !'
        : isGerman
            ? '📊 ${firstName.isNotEmpty ? "$firstName, z" : "Z"}eit für deine Tageszusammenfassung!'
            : '📊 ${firstName.isNotEmpty ? "$firstName, t" : "T"}ime for your daily recap!';
    final body = isFrench
        ? 'Viens voir ta progression du jour et termine en beauté 💪'
        : isGerman
            ? 'Schau dir deinen Tagesfortschritt an und beende den Tag stark 💪'
            : 'Check your daily progress and finish strong 💪';

    await _scheduleDailyNotification(
      id: 30,
      hour: 20,
      minute: 0,
      title: title,
      body: body,
      payload: NotificationPayload(
        type: NotificationType.dailyGoalsSummary,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Daily goals summary scheduled (20h)');
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

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) debugPrint('📲 Notification tapped: ${response.payload}');

    // TODO: Navigation selon le type de notification
    // Ex: ouvrir la page nutrition pour meal reminder
    // Ex: ouvrir la page hydratation pour water reminder
  }

  /// Envoyer une notification immédiate (pour milestones/celebrations)
  /// Utilise un compteur pour éviter les collisions d'IDs
  Future<void> sendImmediateNotification({
    required String title,
    required String body,
    NotificationType? type,
  }) async {
    if (!_initialized) await initialize();

    final prefs = getPreferences();
    if (!prefs.notificationsEnabled) return;

    // Vérifier quiet hours
    if (!prefs.canSendNotificationAt(DateTime.now())) {
      if (kDebugMode) debugPrint('⏸️ Immediate notification skipped (quiet hours)');
      return;
    }

    // Vérifier les milestones sont activés si c'est ce type
    if (type == NotificationType.milestone && !prefs.milestonesEnabled) return;

    // ID unique garanti: combinaison timestamp + compteur
    _immediateNotificationCounter++;
    final uniqueId = (DateTime.now().millisecondsSinceEpoch % 90000) +
                     (_immediateNotificationCounter % 10000);

    await _notifications.show(
      uniqueId,
      title,
      body,
      _notificationDetails(),
    );

    if (kDebugMode) debugPrint('✅ Immediate notification sent (ID: $uniqueId): $title');
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
  /// Annule automatiquement les notifications de réengagement car l'utilisateur est actif
  Future<void> updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);

      // Sauvegarder aussi la série actuelle en cas d'inactivité
      final streak = await StreakService.getCurrentStreak();
      if (streak > 0) {
        await prefs.setInt(_previousStreakKey, streak);
      }

      // IMPORTANT: Annuler les notifications de réengagement car l'utilisateur est actif
      await cancelReengagementNotifications();

      if (kDebugMode) debugPrint('✅ Last activity updated, reengagement notifications cancelled');
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
  /// Message engageant pour ramener l'utilisateur
  Future<void> _scheduleNothingLoggedCheck(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    // Message engageant pour rappeler à l'utilisateur de logger
    final title = isFrench
        ? '👋 ${firstName.isNotEmpty ? "$firstName, o" : "O"}n ne t\'a pas vu aujourd\'hui !'
        : isGerman
            ? '👋 ${firstName.isNotEmpty ? "$firstName, w" : "W"}ir haben dich heute nicht gesehen!'
            : '👋 ${firstName.isNotEmpty ? "$firstName, w" : "W"}e haven\'t seen you today!';
    final body = isFrench
        ? 'Prends 30 secondes pour logger ton repas ou ton activité 🎯'
        : isGerman
            ? 'Nimm dir 30 Sekunden zum Eintragen deiner Mahlzeit oder Aktivität 🎯'
            : 'Take 30 seconds to log your meal or activity 🎯';

    await _scheduleDailyNotification(
      id: 70,
      hour: 17,
      minute: 0,
      title: title,
      body: body,
      payload: NotificationPayload(
        type: NotificationType.nothingLogged,
      ).toJson(),
    );

    if (kDebugMode) debugPrint('✅ Nothing logged check scheduled (17h)');
  }

  /// Planifier le rappel des séances planifiées du jour
  /// Cette notification est dynamique - elle vérifie les séances planifiées chaque jour
  Future<void> _schedulePlannedActivityReminder(NotificationPreferences prefs) async {
    final firstName = await _getUserFirstName();
    final languageCode = LocalizationService.instance.currentLanguageCode;
    final isFrench = languageCode == 'fr';
    final isGerman = languageCode == 'de';

    try {
      // Récupérer les données du planner pour aujourd'hui
      final weekData = await WeeklyPlannerService.getWeekData();
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final dayPlan = weekData.getDayPlan(todayNormalized);

      // Collecter toutes les séances de sport planifiées (pas les repas)
      final List<String> sessionNames = [];

      if (dayPlan != null) {
        // Workouts (musculation)
        for (final workout in dayPlan.workouts) {
          if (workout.status == PlannedStatus.planned) {
            sessionNames.add(workout.workoutName);
          }
        }

        // Cardio
        for (final activity in dayPlan.cardios) {
          if (activity.status == PlannedStatus.planned) {
            final cardioData = activity.cardioData;
            if (cardioData != null) {
              sessionNames.add(cardioData.activityName);
            }
          }
        }
      }

      // Si pas de séances planifiées, ne pas envoyer de notification
      if (sessionNames.isEmpty) {
        if (kDebugMode) debugPrint('⏸️ No planned sessions for today, skipping reminder');
        // Annuler la notification si elle était programmée
        await _notifications.cancel(80);
        return;
      }

      // Construire le message
      final title = NotificationMessages.getPlannedActivityReminderTitle(
        isFrench: isFrench,
        isGerman: isGerman,
        firstName: firstName,
        sessionCount: sessionNames.length,
      );

      final body = NotificationMessages.getPlannedActivityReminderBody(
        isFrench: isFrench,
        isGerman: isGerman,
        sessionNames: sessionNames,
      );

      await _scheduleDailyNotification(
        id: 80,
        hour: prefs.plannedActivityReminderTime,
        minute: 0,
        title: title,
        body: body,
        payload: NotificationPayload(
          type: NotificationType.plannedActivityReminder,
        ).toJson(),
      );

      if (kDebugMode) {
        debugPrint('✅ Planned activity reminder scheduled (${prefs.plannedActivityReminderTime}h): ${sessionNames.join(", ")}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error scheduling planned activity reminder: $e');
    }
  }

  /// Rafraîchir la notification des séances planifiées
  /// À appeler quand le planning change (ajout/suppression de séances)
  Future<void> refreshPlannedActivityNotification() async {
    final prefs = getPreferences();
    if (prefs.notificationsEnabled && prefs.plannedActivityReminderEnabled) {
      await _schedulePlannedActivityReminder(prefs);
    }
  }
}
