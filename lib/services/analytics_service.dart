import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';  // Temporairement désactivé
import 'package:flutter/foundation.dart';

/// Service centralisé pour Firebase Analytics
///
/// Usage:
/// ```dart
/// // Tracker un event
/// AnalyticsService.logEvent('food_scan_camera', parameters: {'meal_type': 'lunch'});
///
/// // Tracker une erreur
/// AnalyticsService.recordError(error, stackTrace);
/// ```
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;  // Temporairement désactivé

  // ==========================================
  // CONFIGURATION
  // ==========================================

  /// Initialise Firebase Analytics
  static Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Configure Crashlytics - Temporairement désactivé
      // FlutterError.onError = _crashlytics.recordFlutterFatalError;
      // PlatformDispatcher.instance.onError = (error, stack) {
      //   _crashlytics.recordError(error, stack, fatal: true);
      //   return true;
      // };

      if (kDebugMode) {
        debugPrint('✅ Firebase Analytics initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Firebase Analytics initialization failed: $e');
      }
    }
  }

  /// Définit l'ID utilisateur pour le tracking
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      // await _crashlytics.setUserIdentifier(userId ?? '');  // Temporairement désactivé
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to set user ID: $e');
      }
    }
  }

  /// Définit des propriétés utilisateur personnalisées
  static Future<void> setUserProperties({
    String? plan,
    String? language,
    String? country,
  }) async {
    try {
      if (plan != null) {
        await _analytics.setUserProperty(name: 'plan', value: plan);
      }
      if (language != null) {
        await _analytics.setUserProperty(name: 'language', value: language);
      }
      if (country != null) {
        await _analytics.setUserProperty(name: 'country', value: country);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to set user properties: $e');
      }
    }
  }

  // ==========================================
  // EVENT LOGGING
  // ==========================================

  /// Log un événement générique
  static Future<void> logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('📊 Analytics Event: $eventName ${parameters ?? ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to log event: $e');
      }
    }
  }

  /// Log une navigation d'écran
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) {
        debugPrint('📱 Screen View: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to log screen view: $e');
      }
    }
  }

  // ==========================================
  // NUTRITION EVENTS
  // ==========================================

  /// Food scan via caméra
  static Future<void> logFoodScanCamera({
    required String mealType,
    bool? success,
  }) async {
    await logEvent('food_scan_camera', parameters: {
      'meal_type': mealType,
      if (success != null) 'success': success,
    });
  }

  /// Food scan via barcode
  static Future<void> logFoodScanBarcode({
    required String mealType,
    bool? success,
    String? source, // 'camera' ou 'manual'
  }) async {
    await logEvent('food_scan_barcode', parameters: {
      'meal_type': mealType,
      if (success != null) 'success': success,
      if (source != null) 'source': source,
    });
  }

  /// Ajout manuel de nourriture
  static Future<void> logManualFoodEntry({
    required String mealType,
    required String foodName,
  }) async {
    await logEvent('manual_food_entry', parameters: {
      'meal_type': mealType,
      'food_name': foodName,
    });
  }

  /// Création de recette
  static Future<void> logRecipeCreated({
    required int ingredientCount,
  }) async {
    await logEvent('recipe_created', parameters: {
      'ingredient_count': ingredientCount,
    });
  }

  /// Ajout de recette au repas
  static Future<void> logRecipeAdded({
    required String mealType,
    required String recipeName,
  }) async {
    await logEvent('recipe_added', parameters: {
      'meal_type': mealType,
      'recipe_name': recipeName,
    });
  }

  /// Log eau ajoutée
  static Future<void> logWaterLogged({
    required int amountMl,
  }) async {
    await logEvent('water_logged', parameters: {
      'amount_ml': amountMl,
    });
  }

  // ==========================================
  // WORKOUT EVENTS
  // ==========================================

  /// Workout complété
  static Future<void> logWorkoutCompleted({
    required String workoutType, // 'strength', 'cardio', 'hiit'
    required int durationMinutes,
    int? exerciseCount,
    int? caloriesBurned,
  }) async {
    await logEvent('workout_completed', parameters: {
      'workout_type': workoutType,
      'duration_minutes': durationMinutes,
      if (exerciseCount != null) 'exercise_count': exerciseCount,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
    });
  }

  /// Workout démarré
  static Future<void> logWorkoutStarted({
    required String workoutType,
  }) async {
    await logEvent('workout_started', parameters: {
      'workout_type': workoutType,
    });
  }

  /// Cardio complété
  static Future<void> logCardioCompleted({
    required String activityType, // 'running', 'cycling', etc.
    required int durationMinutes,
    double? distanceKm,
    int? caloriesBurned,
  }) async {
    await logEvent('cardio_completed', parameters: {
      'activity_type': activityType,
      'duration_minutes': durationMinutes,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
    });
  }

  // ==========================================
  // USER PROGRESS EVENTS
  // ==========================================

  /// Poids mis à jour
  static Future<void> logWeightUpdated({
    required double weightKg,
  }) async {
    await logEvent('weight_updated', parameters: {
      'weight_kg': weightKg,
    });
  }

  /// Streak atteint
  static Future<void> logStreakAchieved({
    required int streakDays,
  }) async {
    await logEvent('streak_achieved', parameters: {
      'streak_days': streakDays,
    });
  }

  /// Objectif atteint
  static Future<void> logGoalAchieved({
    required String goalType, // 'weight', 'calories', 'workout', etc.
  }) async {
    await logEvent('goal_achieved', parameters: {
      'goal_type': goalType,
    });
  }

  // ==========================================
  // WIDGET EVENTS
  // ==========================================

  /// Interaction avec le widget iOS
  static Future<void> logWidgetInteraction({
    required String action, // 'scan', 'manual', 'barcode', 'recipes', 'chat'
    required String widgetSize, // 'small', 'medium'
  }) async {
    await logEvent('meal_widget_interaction', parameters: {
      'action': action,
      'widget_size': widgetSize,
    });
  }

  // ==========================================
  // AUTHENTICATION EVENTS
  // ==========================================

  /// Login
  static Future<void> logLogin({
    required String method, // 'email', 'google', 'apple'
  }) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Sign up
  static Future<void> logSignUp({
    required String method,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // ==========================================
  // ERROR TRACKING
  // ==========================================

  /// Enregistre une erreur dans Crashlytics - Temporairement désactivé
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    // Temporairement désactivé - Crashlytics a des conflits CocoaPods
    if (kDebugMode) {
      debugPrint('🔥 Error (Crashlytics disabled): $exception');
    }
    // try {
    //   await _crashlytics.recordError(
    //     exception,
    //     stack,
    //     reason: reason,
    //     fatal: fatal,
    //   );
    //   if (kDebugMode) {
    //     debugPrint('🔥 Crashlytics Error: $exception');
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('⚠️ Failed to record error: $e');
    //   }
    // }
  }

  /// Log un message custom dans Crashlytics - Temporairement désactivé
  static Future<void> log(String message) async {
    if (kDebugMode) {
      debugPrint('📝 Log (Crashlytics disabled): $message');
    }
    // try {
    //   await _crashlytics.log(message);
    // } catch (e) {
    //   if (kDebugMode) {
    //     debugPrint('⚠️ Failed to log message: $e');
    //   }
    // }
  }

  // ==========================================
  // FEATURE USAGE
  // ==========================================

  /// Track quelle fonctionnalité est utilisée
  static Future<void> logFeatureUsed(String featureName) async {
    await logEvent('feature_used', parameters: {
      'feature_name': featureName,
    });
  }

  /// Premier lancement de l'app
  static Future<void> logFirstOpen() async {
    await _analytics.logAppOpen();
  }

  /// Tutorial terminé
  static Future<void> logTutorialComplete({
    required String tutorialName,
  }) async {
    await _analytics.logTutorialComplete();
    await logEvent('tutorial_completed', parameters: {
      'tutorial_name': tutorialName,
    });
  }

  /// Tutorial commencé
  static Future<void> logTutorialBegin({
    required String tutorialName,
  }) async {
    await _analytics.logTutorialBegin();
    await logEvent('tutorial_started', parameters: {
      'tutorial_name': tutorialName,
    });
  }
}
