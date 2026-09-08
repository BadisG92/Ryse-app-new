import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../models/weekly_planner_models.dart';
import 'weekly_planner_service.dart';
import 'planned_cardio_service.dart';
import 'ai_workout_generation_service.dart';
import 'food_entries_service.dart';
import 'localization_service.dart';
import 'auth_service.dart';
import 'unified_subscription_service.dart';
import 'coach_preference_extractor.dart';
import 'global_state_manager.dart';
import 'translations.dart';

/// Types d'intentions détectées par l'IA
enum PlannerIntent {
  workout,       // Planifier des séances de musculation
  cardio,        // Planifier du cardio
  meal,          // Planifier des repas
  useTemplate,   // Utiliser une séance sauvegardée
  moveWorkout,   // Déplacer une séance
  deleteWorkout, // Supprimer une séance
  modifyWorkout, // Modifier une séance
  unknown,       // Intention non reconnue
  clarification, // Besoin de clarification
}

/// Types de splits disponibles
enum WorkoutSplit {
  fullBody,     // 3x le même workout Full Body
  pushPullLegs, // Push / Pull / Legs
  upperLower,   // Haut / Bas (alternance)
  custom,       // Personnalisé
}

extension WorkoutSplitExtension on WorkoutSplit {
  String get value {
    switch (this) {
      case WorkoutSplit.fullBody:
        return 'full_body';
      case WorkoutSplit.pushPullLegs:
        return 'push_pull_legs';
      case WorkoutSplit.upperLower:
        return 'upper_lower';
      case WorkoutSplit.custom:
        return 'custom';
    }
  }

  static WorkoutSplit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'full_body':
      case 'fullbody':
      case 'full body':
        return WorkoutSplit.fullBody;
      case 'push_pull_legs':
      case 'pushpulllegs':
      case 'ppl':
        return WorkoutSplit.pushPullLegs;
      case 'upper_lower':
      case 'upperlower':
      case 'haut_bas':
        return WorkoutSplit.upperLower;
      default:
        return WorkoutSplit.fullBody;
    }
  }

  /// Retourne les types de workout pour chaque jour selon le split
  List<String> getWorkoutTypes(int sessionCount) {
    switch (this) {
      case WorkoutSplit.fullBody:
        return List.filled(sessionCount, 'Full Body');
      case WorkoutSplit.pushPullLegs:
        final types = ['Push', 'Pull', 'Legs'];
        return List.generate(sessionCount, (i) => types[i % 3]);
      case WorkoutSplit.upperLower:
        final types = ['Upper Body', 'Lower Body'];
        return List.generate(sessionCount, (i) => types[i % 2]);
      case WorkoutSplit.custom:
        return List.filled(sessionCount, 'Full Body');
    }
  }

  /// Nom d'affichage selon la langue
  String getDisplayName(String langCode) {
    final names = {
      WorkoutSplit.fullBody: {
        'fr': 'Full Body (même séance)',
        'en': 'Full Body (same workout)',
        'de': 'Ganzkörper (gleiches Training)',
      },
      WorkoutSplit.pushPullLegs: {
        'fr': 'Push / Pull / Legs',
        'en': 'Push / Pull / Legs',
        'de': 'Push / Pull / Beine',
      },
      WorkoutSplit.upperLower: {
        'fr': 'Haut / Bas du corps',
        'en': 'Upper / Lower Body',
        'de': 'Oberkörper / Unterkörper',
      },
    };
    return names[this]?[langCode] ?? names[this]?['en'] ?? value;
  }
}

/// Résultat d'une analyse d'intention
class IntentAnalysis {
  final PlannerIntent intent;
  final Map<String, dynamic> extractedInfo;
  final String? followUpQuestion;
  final String? responseMessage; // Message de Ryze expliquant le programme
  final bool isComplete;

  IntentAnalysis({
    required this.intent,
    required this.extractedInfo,
    this.followUpQuestion,
    this.responseMessage,
    this.isComplete = false,
  });
}

/// Type de résultat d'une action de planification
enum PlannerResultType {
  success,        // Action réussie
  error,          // Erreur
  paywall,        // Paywall requis
  preview,        // Preview workout (ancien mode)
  mealPreview,    // Preview meals
  question,       // Question à poser à l'utilisateur
  sessionPreview, // Preview sessions paginé (nouveau)
}

/// Résultat d'une action de planification
class PlannerActionResult {
  final PlannerResultType resultType;
  final bool success;
  final String message;
  final List<String>? createdItems;
  final String? error;
  final bool isPaywallRequired;
  final bool requiresConfirmation; // Pour le mode preview
  final List<PendingWorkout>? pendingWorkouts; // Workouts à valider
  final List<PendingMeal>? pendingMeals; // Repas à valider
  final bool hasMoreActions; // Il reste des actions à exécuter
  final bool canUndo; // Dernière action peut être annulée
  final String? nextActionDescription; // Description de la prochaine action

  // NOUVEAUX CHAMPS pour flow questions séquentielles
  final PendingQuestion? pendingQuestion; // Question en cours
  final SessionPlanningState? planningState; // État du planning en cours
  final List<PendingSession>? pendingSessions; // Sessions à valider (paginé)

  PlannerActionResult({
    this.resultType = PlannerResultType.success,
    required this.success,
    required this.message,
    this.createdItems,
    this.error,
    this.isPaywallRequired = false,
    this.requiresConfirmation = false,
    this.pendingWorkouts,
    this.pendingMeals,
    this.hasMoreActions = false,
    this.canUndo = false,
    this.nextActionDescription,
    this.pendingQuestion,
    this.planningState,
    this.pendingSessions,
  });

  factory PlannerActionResult.success(String message, {List<String>? items}) {
    return PlannerActionResult(
      resultType: PlannerResultType.success,
      success: true,
      message: message,
      createdItems: items,
    );
  }

  factory PlannerActionResult.error(String error) {
    return PlannerActionResult(
      resultType: PlannerResultType.error,
      success: false,
      message: error,
      error: error,
    );
  }

  factory PlannerActionResult.paywall(String message) {
    return PlannerActionResult(
      resultType: PlannerResultType.paywall,
      success: false,
      message: message,
      isPaywallRequired: true,
    );
  }

  factory PlannerActionResult.preview({
    required String message,
    required List<PendingWorkout> workouts,
  }) {
    return PlannerActionResult(
      resultType: PlannerResultType.preview,
      success: true,
      message: message,
      requiresConfirmation: true,
      pendingWorkouts: workouts,
    );
  }

  factory PlannerActionResult.mealPreview({
    required String message,
    required List<PendingMeal> meals,
  }) {
    return PlannerActionResult(
      resultType: PlannerResultType.mealPreview,
      success: true,
      message: message,
      requiresConfirmation: true,
      pendingMeals: meals,
    );
  }

  /// NOUVEAU: Retourner une question à poser
  factory PlannerActionResult.question({
    required String questionText,
    required PendingQuestion question,
    required SessionPlanningState planningState,
  }) {
    return PlannerActionResult(
      resultType: PlannerResultType.question,
      success: true,
      message: questionText,
      pendingQuestion: question,
      planningState: planningState,
    );
  }

  /// NOUVEAU: Preview de sessions paginé (workouts + cardios)
  factory PlannerActionResult.sessionPreview({
    required String message,
    required List<PendingSession> sessions,
  }) {
    return PlannerActionResult(
      resultType: PlannerResultType.sessionPreview,
      success: true,
      message: message,
      requiresConfirmation: true,
      pendingSessions: sessions,
    );
  }

  /// Helper pour vérifier le type de résultat
  bool get isQuestion => resultType == PlannerResultType.question;
  bool get isSessionPreview => resultType == PlannerResultType.sessionPreview;
  bool get isMealPreview => resultType == PlannerResultType.mealPreview;
  bool get isPreview => resultType == PlannerResultType.preview;
}

/// Service d'IA pour le planificateur hebdomadaire
class PlannerAIService {
  /// La part de la journée qui revient à chaque repas.
  ///
  /// Une seule source : le tableau de macros injecté dans le prompt et la
  /// phrase qui le précède s'en servent tous les deux. Ils annonçaient des
  /// chiffres différents dans la même requête, juste au-dessus de la consigne
  /// « n'invente pas tes propres valeurs ».
  static const Map<String, double> mealSplit = {
    'breakfast': 0.25,
    'lunch': 0.35,
    'dinner': 0.30,
    'snack': 0.10,
  };

  static String _mealSplitPercent(String meal) =>
      (mealSplit[meal]! * 100).round().toString();

  // =====================================================
  // ACCÈS : premium, ou mode démo de l'onboarding
  // =====================================================

  static bool _demoMode = false;
  static void setDemoMode(bool value) => _demoMode = value;

  /// First of the seven days the screen is showing. The app passes the Monday
  /// of the week; the onboarding demo passes today, so its seven days roll.
  /// Everything the planner creates lands inside this window.
  static DateTime? _windowStart;
  static void setPlanningWindow(DateTime? start) => _windowStart = start == null ? null : DateTime(start.year, start.month, start.day);
  static DateTime get planningWindowStart => _windowStart ?? getCurrentWeekStart();

  /// The date the model meant when it said "saturday": the one day of the
  /// window that falls on that weekday. Adding an index to a Monday only works
  /// while the window starts on a Monday.
  static DateTime? dateForDayName(String day) {
    const names = {
      'monday': 1, 'lundi': 1, 'montag': 1,
      'tuesday': 2, 'mardi': 2, 'dienstag': 2,
      'wednesday': 3, 'mercredi': 3, 'mittwoch': 3,
      'thursday': 4, 'jeudi': 4, 'donnerstag': 4,
      'friday': 5, 'vendredi': 5, 'freitag': 5,
      'saturday': 6, 'samedi': 6, 'samstag': 6,
      'sunday': 7, 'dimanche': 7, 'sonntag': 7,
    };
    final weekday = names[day.toLowerCase().trim()];
    if (weekday == null) return null;
    final start = planningWindowStart;
    for (var i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      if (date.weekday == weekday) return date;
    }
    return null;
  }

  /// L'IA du planificateur est réservée aux abonnés.
  static Future<bool> canUseAI() async {
    if (_demoMode) return true;
    if (UnifiedSubscriptionService().isPremium) return true;
    // Mode test interne : accès sans abonnement.
    return UnifiedSubscriptionService().testMode;
  }



  /// Vérifier si l'utilisateur est premium
  static bool get isPremium => UnifiedSubscriptionService().isPremium;



  // =====================================================
  // CONVERSATION CONTEXT
  // =====================================================

  // Context de conversation pour multi-turn
  static final List<Map<String, String>> _conversationHistory = [];
  static const int _maxHistoryLength = 10;

  /// Ajouter un message à l'historique de conversation
  static void addToHistory(String role, String content) {
    _conversationHistory.add({
      'role': role, // 'user' ou 'assistant'
      'content': content,
    });

    // Limiter la taille de l'historique
    while (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
  }

  /// Effacer l'historique de conversation (après action réussie ou nouveau chat)
  static void clearHistory() {
    _conversationHistory.clear();
    _pendingAction = null;
    _pendingFollowUpActions = null;
    debugPrint('🗑️ Conversation history cleared');
  }

  /// Obtenir l'historique formaté pour le prompt
  static String _getFormattedHistory() {
    if (_conversationHistory.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Previous conversation:');

    for (final msg in _conversationHistory) {
      final role = msg['role'] == 'user' ? 'User' : 'Ryze';
      buffer.writeln('$role: ${msg['content']}');
    }

    buffer.writeln();
    buffer.writeln('## Current message (respond to this):');

    return buffer.toString();
  }




  /// Message pour le paywall
  /// Le message quand la porte est fermée.
  ///
  /// Il parlait de « 3 planifications gratuites cette semaine », un compte qui
  /// n'existe plus depuis le paywall dur : `canUseAI` regarde l'abonnement, un
  /// point c'est tout.
  static String _getPaywallMessage(String langCode) {
    switch (langCode) {
      case 'fr':
        return "La planification avec Ryze fait partie de Premium. 🎯\n\nPasse à Premium pour planifier ta semaine.";
      case 'de':
        return "Planen mit Ryze gehört zu Premium. 🎯\n\nWerde Premium, um deine Woche zu planen.";
      default:
        return "Planning with Ryze is part of Premium. 🎯\n\nUpgrade to Premium to plan your week.";
    }
  }


  /// Confirmer et sauvegarder les workouts après validation de l'utilisateur
  static Future<PlannerActionResult> confirmWorkouts(List<PendingWorkout> workouts) async {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final createdItems = <String>[];
    final createdWorkouts = <String>[];

    try {
      for (final pending in workouts) {
        if (pending.exercises == null || pending.exercises!.isEmpty) continue;

        final workout = await WeeklyPlannerService.addPlannedWorkout(
          plannedDate: pending.plannedDate,
          workoutName: pending.workoutName,
          exercises: pending.exercises!,
          durationMinutes: pending.durationMinutes,
          userPrompt: pending.workoutPrompt,
          isAiGenerated: true,
        );

        if (workout != null) {
          final dayName = _formatDayName(pending.plannedDate, langCode);
          createdItems.add(dayName);
          createdWorkouts.add('$dayName: ${pending.workoutType}');
        }
      }

      if (createdItems.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'workout_generation_failed'),
        );
      }


      return PlannerActionResult.success(
        _getConfirmationMessage(langCode, createdWorkouts),
        items: createdItems,
      );
    } catch (e) {
      debugPrint('❌ confirmWorkouts error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
    }
  }


  /// Message de preview pour les sessions unifiées (workouts + cardios)
  static String _getSessionsPreviewMessage(String langCode, List<PendingSession> sessions) {
    final header = {
      'fr': 'Voici tes séances ! Valide une par une 👇\n\n',
      'en': 'Here are your sessions! Validate one by one 👇\n\n',
      'de': 'Hier sind deine Einheiten! Bestätige einzeln 👇\n\n',
    };

    final sessionsList = sessions.map((s) {
      final dayName = _formatDayName(s.plannedDate, langCode);
      if (s.isWorkout && s.workout != null) {
        final exerciseCount = s.workout!.exercises?.length ?? 0;
        final exercisesLabel = langCode == 'fr' ? 'exercices' : langCode == 'de' ? 'Übungen' : 'exercises';
        return '• $dayName: ${s.workout!.workoutType} (${s.workout!.durationMinutes}min, $exerciseCount $exercisesLabel)';
      } else if (s.isCardio && s.cardio != null) {
        final cardio = s.cardio!;
        String details = '';
        if (cardio.distanceKm != null) {
          details = '${cardio.distanceKm!.toStringAsFixed(1)} km';
        } else if (cardio.durationMinutes != null) {
          details = '${cardio.durationMinutes} min';
        }
        return '• $dayName: ${cardio.activityName} ($details)';
      }
      return '• $dayName: ${s.displayTitle}';
    }).join('\n');

    final footer = {
      'fr': '\n\n💡 Valide chaque séance pour l\'ajouter à ton planning.',
      'en': '\n\n💡 Validate each session to add it to your schedule.',
      'de': '\n\n💡 Bestätige jede Einheit, um sie zu deinem Plan hinzuzufügen.',
    };

    return '${header[langCode] ?? header['en']}$sessionsList${footer[langCode] ?? footer['en']}';
  }

  /// Message de confirmation après sauvegarde
  static String _getConfirmationMessage(String langCode, List<String> createdWorkouts) {
    final header = {
      'fr': 'C\'est validé ! Tes séances sont planifiées 💪\n\n',
      'en': 'Done! Your sessions are scheduled 💪\n\n',
      'de': 'Erledigt! Deine Einheiten sind geplant 💪\n\n',
    };

    final workoutsList = createdWorkouts.map((w) => '✓ $w').join('\n');
    return '${header[langCode] ?? header['en']}$workoutsList';
  }


  /// Parser un jour unique
  static DateTime? _parseSingleDay(String dayStr) {
    final weekStart = planningWindowStart;
    final dayMap = {
      'monday': 0, 'lundi': 0, 'montag': 0,
      'tuesday': 1, 'mardi': 1, 'dienstag': 1,
      'wednesday': 2, 'mercredi': 2, 'mittwoch': 2,
      'thursday': 3, 'jeudi': 3, 'donnerstag': 3,
      'friday': 4, 'vendredi': 4, 'freitag': 4,
      'saturday': 5, 'samedi': 5, 'samstag': 5,
      'sunday': 6, 'dimanche': 6, 'sonntag': 6,
    };

    final offset = dayMap[dayStr.toLowerCase()];
    if (offset == null) return null;
    return dateForDayName(dayStr) ?? weekStart.add(Duration(days: offset));
  }

  /// Parser un type de repas
  static PlannedActivityType _parseMealType(String mealTypeStr) {
    switch (mealTypeStr.toLowerCase()) {
      case 'breakfast':
      case 'petit-déjeuner':
      case 'petit déjeuner':
      case 'frühstück':
        return PlannedActivityType.breakfast;
      case 'lunch':
      case 'déjeuner':
      case 'mittagessen':
        return PlannedActivityType.lunch;
      case 'dinner':
      case 'dîner':
      case 'diner':
      case 'abendessen':
        return PlannedActivityType.dinner;
      case 'snack':
      case 'collation':
      case 'goûter':
      case 'gouter':
        return PlannedActivityType.snack;
      default:
        return PlannedActivityType.lunch; // Default to lunch
    }
  }








  /// Confirmer et sauvegarder les repas dans le planner
  static Future<PlannerActionResult> confirmMeals(List<PendingMeal> meals) async {
    final langCode = LocalizationService.instance.currentLanguageCode;

    try {
      final createdItems = <String>[];

      for (final meal in meals) {
        final mealData = PlannedMealData(
          dishName: meal.dishName,
          dishDescription: meal.dishDescription,
          calories: meal.calories,
          proteins: meal.proteins,
          carbs: meal.carbs,
          fats: meal.fats,
          estimatedQuantityG: meal.estimatedQuantityG,
          aiReasoning: meal.aiReasoning,
        );

        final activity = await WeeklyPlannerService.addPlannedActivity(
          plannedDate: meal.plannedDate,
          activityType: meal.mealType,
          activityData: mealData.toJson(),
          isAiGenerated: true,
        );

        if (activity != null) {
          createdItems.add('${meal.dayName} - ${meal.mealTypeName}');
        }
      }

      if (createdItems.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'meal_creation_failed'),
        );
      }


      final message = langCode == 'fr'
          ? '✅ ${createdItems.length} repas ajoutés au planificateur !'
          : '✅ ${createdItems.length} meals added to planner!';

      return PlannerActionResult.success(message, items: createdItems);
    } catch (e) {
      debugPrint('❌ confirmMeals error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'meal_error'),
      );
    }
  }











  // =====================================================
  // HELPERS
  // =====================================================

  /// Récupérer le contexte utilisateur pour l'IA
  static Future<Map<String, dynamic>> _getUserContext() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return {};

      final client = Supabase.instance.client;
      final langCode = LocalizationService.instance.currentLanguageCode;

      // Récupérer les workouts déjà planifiés cette semaine
      final weekStart = planningWindowStart;
      final existingData = await WeeklyPlannerService.getWeekData();

      // Jours avec workout
      final daysWithWorkout = existingData.workouts
          .map((w) => w.plannedDate.weekday)
          .toList();

      // Jours avec cardio
      final daysWithCardio = existingData.activities
          .where((a) => a.activityType == PlannedActivityType.cardio)
          .map((a) => a.plannedDate.weekday)
          .toList();

      // Exercices déjà planifiés cette semaine (pour éviter trop de répétition)
      final plannedExercises = <String>[];
      for (final workout in existingData.workouts) {
        for (final ex in workout.exercises) {
          plannedExercises.add(ex.exercise.name.toLowerCase());
        }
      }

      // Jours disponibles (futurs, sans workout)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final availableDays = <String>[];
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        // named after the weekday it really is: the window does not always start on a Monday
        if (!day.isBefore(today) && !daysWithWorkout.contains(day.weekday)) {
          availableDays.add(dayNames[day.weekday - 1]);
        }
      }


      // Récupérer les templates sauvegardés par l'utilisateur
      final userTemplates = await _getUserWorkoutTemplates(client, user.id);

      // Formater les workouts planifiés cette semaine (pour move/delete/modify)
      final plannedWorkoutsThisWeek = _formatPlannedWorkouts(existingData.workouts, langCode);

      // Formater les cardios planifiés cette semaine
      final plannedCardioThisWeek = _formatPlannedCardio(existingData.activities, langCode);

      // Formater les repas planifiés cette semaine
      final plannedMealsThisWeek = _formatPlannedMeals(existingData.activities, langCode);

      // Récupérer les repas DÉJÀ LOGGUÉS dans le journal aujourd'hui
      // (pour éviter de proposer un déjeuner si l'utilisateur l'a déjà loggué)
      final loggedMealsToday = await _getLoggedMealTypesToday();

      // Récupérer les objectifs nutritionnels depuis GlobalStateManager
      final globalState = GlobalStateManager.instance;
      final calorieTarget = globalState.calorieGoal.toInt();
      final proteinTarget = globalState.proteinGoal;
      final carbsTarget = globalState.carbsGoal;
      final fatTarget = globalState.fatGoal;

      // Récupérer les calories/macros consommés aujourd'hui
      final todayCalories = globalState.currentCalories.toInt();
      final todayProteins = globalState.currentProteins.toInt();
      final todayCarbs = globalState.currentCarbs.toInt();
      final todayFats = globalState.currentFats.toInt();
      final remainingCalories = calorieTarget - todayCalories;

      return {
        'today': dayNames[today.weekday - 1],
        'today_date': '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        'fitness_goal': user.fitnessGoal ?? 'general_fitness',
        'activity_level': user.activityLevel ?? 'moderate',
        'gender': user.gender ?? 'unknown',
        'weight_kg': user.weight,
        'available_days': availableDays,
        'days_with_workout': daysWithWorkout.map((d) => dayNames[d - 1]).toList(),
        'days_with_cardio': daysWithCardio.map((d) => dayNames[d - 1]).toList(),
        'exercises_already_planned': plannedExercises.toSet().toList(),
        'user_templates': userTemplates,
        'planned_workouts_this_week': plannedWorkoutsThisWeek,
        'planned_cardio_this_week': plannedCardioThisWeek,
        // Données nutritionnelles
        'calorie_target': calorieTarget,
        'protein_target': proteinTarget,
        'carbs_target': carbsTarget,
        'fat_target': fatTarget,
        'today_calories': todayCalories,
        'today_proteins': todayProteins,
        'today_carbs': todayCarbs,
        'today_fats': todayFats,
        'remaining_calories': remainingCalories,
        'planned_meals_this_week': plannedMealsThisWeek,
        'logged_meals_today': loggedMealsToday,
      };
    } catch (e) {
      debugPrint('❌ _getUserContext error: $e');
      return {};
    }
  }

  /// Récupérer les types de repas déjà logués aujourd'hui dans le journal
  /// Retourne une liste comme ['breakfast', 'lunch'] si ces repas ont été logués
  static Future<List<String>> _getLoggedMealTypesToday() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final todayMeals = await FoodEntriesService.getFoodEntriesForDate(user.id, now);

      // Extraire les meal_type uniques des repas logués
      final loggedTypes = <String>{};
      for (final meal in todayMeals) {
        if (meal.items.isNotEmpty && meal.mealType != null) {
          // Le mealType est dans le MealGroup
          loggedTypes.add(meal.mealType!);
        }
      }

      return loggedTypes.toList();
    } catch (e) {
      debugPrint('❌ _getLoggedMealTypesToday error: $e');
      return [];
    }
  }

  /// Formater les cardios planifiés cette semaine pour le contexte AI
  static String _formatPlannedCardio(List<PlannedActivity> activities, String langCode) {
    final cardios = activities.where((a) => a.activityType == PlannedActivityType.cardio).toList();
    if (cardios.isEmpty) {
      return 'No cardio planned yet';
    }

    final dayNames = {
      1: {'fr': 'Lundi', 'en': 'Monday', 'de': 'Montag'},
      2: {'fr': 'Mardi', 'en': 'Tuesday', 'de': 'Dienstag'},
      3: {'fr': 'Mercredi', 'en': 'Wednesday', 'de': 'Mittwoch'},
      4: {'fr': 'Jeudi', 'en': 'Thursday', 'de': 'Donnerstag'},
      5: {'fr': 'Vendredi', 'en': 'Friday', 'de': 'Freitag'},
      6: {'fr': 'Samedi', 'en': 'Saturday', 'de': 'Samstag'},
      7: {'fr': 'Dimanche', 'en': 'Sunday', 'de': 'Sonntag'},
    };

    final buffer = StringBuffer();
    for (final cardio in cardios) {
      final day = dayNames[cardio.plannedDate.weekday]?[langCode] ?? 'Day ${cardio.plannedDate.weekday}';
      final activityName = cardio.cardioData?.activityName ?? 'Cardio';
      final duration = cardio.cardioData?.targetMinutes;
      final distance = cardio.cardioData?.targetKm;

      buffer.write('• $day: $activityName');
      if (duration != null) buffer.write(' (${duration}min)');
      if (distance != null) buffer.write(' - ${distance}km');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// Formater les repas planifiés cette semaine pour le contexte AI
  static String _formatPlannedMeals(List<PlannedActivity> activities, String langCode) {
    final meals = activities.where((a) => a.activityType.isMeal).toList();
    if (meals.isEmpty) {
      return 'No meals planned yet';
    }

    final dayNames = {
      1: {'fr': 'Lundi', 'en': 'Monday', 'de': 'Montag'},
      2: {'fr': 'Mardi', 'en': 'Tuesday', 'de': 'Dienstag'},
      3: {'fr': 'Mercredi', 'en': 'Wednesday', 'de': 'Mittwoch'},
      4: {'fr': 'Jeudi', 'en': 'Thursday', 'de': 'Donnerstag'},
      5: {'fr': 'Vendredi', 'en': 'Friday', 'de': 'Freitag'},
      6: {'fr': 'Samedi', 'en': 'Saturday', 'de': 'Samstag'},
      7: {'fr': 'Dimanche', 'en': 'Sunday', 'de': 'Sonntag'},
    };

    final mealTypeNames = {
      PlannedActivityType.breakfast: {'fr': 'Petit-déj', 'en': 'Breakfast', 'de': 'Frühstück'},
      PlannedActivityType.lunch: {'fr': 'Déjeuner', 'en': 'Lunch', 'de': 'Mittagessen'},
      PlannedActivityType.dinner: {'fr': 'Dîner', 'en': 'Dinner', 'de': 'Abendessen'},
      PlannedActivityType.snack: {'fr': 'Collation', 'en': 'Snack', 'de': 'Snack'},
    };

    // Grouper par jour
    final mealsByDay = <int, List<PlannedActivity>>{};
    for (final meal in meals) {
      final weekday = meal.plannedDate.weekday;
      mealsByDay[weekday] = mealsByDay[weekday] ?? [];
      mealsByDay[weekday]!.add(meal);
    }

    final buffer = StringBuffer();

    // Trier par jour de la semaine
    final sortedDays = mealsByDay.keys.toList()..sort();
    for (final weekday in sortedDays) {
      final dayName = dayNames[weekday]?[langCode] ?? 'Day $weekday';
      buffer.writeln('$dayName:');

      for (final meal in mealsByDay[weekday]!) {
        final mealData = meal.mealData;
        final mealTypeName = mealTypeNames[meal.activityType]?[langCode] ?? meal.activityType.value;
        final dishName = mealData?.displayName ?? 'Repas';
        final calories = mealData?.calories ?? 0;
        final status = meal.status == PlannedStatus.completed ? '✓' : '•';

        buffer.write('  $status $mealTypeName: $dishName');
        if (calories > 0) buffer.write(' (~${calories}kcal)');
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  /// Récupérer les templates de workout sauvegardés par l'utilisateur
  static Future<String> _getUserWorkoutTemplates(
    SupabaseClient client,
    String userId,
  ) async {
    try {
      // Requête simplifiée - juste les templates sans les exercices imbriqués
      final response = await client
          .from('user_workout_templates')
          .select('id, name, description, estimated_duration_minutes')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      if ((response as List).isEmpty) {
        return 'No saved templates';
      }

      final buffer = StringBuffer();
      for (final template in response) {
        final name = template['name'] as String? ?? 'Unnamed';
        final id = template['id'] as String? ?? '';
        final duration = template['estimated_duration_minutes'] as int?;
        final description = template['description'] as String?;

        buffer.write('• "$name" (id: $id)');
        if (duration != null) buffer.write(' - ~${duration}min');
        if (description != null && description.isNotEmpty) {
          buffer.write(' - $description');
        }
        buffer.writeln();
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint('❌ _getUserWorkoutTemplates error: $e');
      return 'No saved templates';
    }
  }

  /// Formater les workouts planifiés cette semaine pour le contexte AI
  static String _formatPlannedWorkouts(List<PlannedWorkout> workouts, String langCode) {
    if (workouts.isEmpty) {
      return 'No workouts planned yet';
    }

    // Séparer les séances complétées des planifiées
    final completed = workouts.where((w) => w.status == PlannedStatus.completed).toList();
    final planned = workouts.where((w) => w.status == PlannedStatus.planned).toList();
    final missed = workouts.where((w) => w.status == PlannedStatus.missed).toList();

    final buffer = StringBuffer();

    // Séances COMPLÉTÉES (ne pas les modifier, mais prendre en compte pour le planning)
    if (completed.isNotEmpty) {
      buffer.writeln('COMPLETED SESSIONS (DO NOT modify, count towards weekly total):');
      for (final workout in completed) {
        final dayName = _formatDayName(workout.plannedDate, 'en').toLowerCase();
        final exercises = workout.exercises.map((e) => e.exercise.name).join(', ');
        buffer.writeln('  ✓ $dayName: "${workout.workoutName}" - ${workout.exercises.length} exercises ($exercises)');
      }
      buffer.writeln();
    }

    // Séances PLANIFIÉES (peuvent être modifiées/déplacées/supprimées)
    if (planned.isNotEmpty) {
      buffer.writeln('PLANNED SESSIONS (can be modified/moved/deleted):');
      for (final workout in planned) {
        final dayName = _formatDayName(workout.plannedDate, 'en').toLowerCase();
        final exercises = workout.exercises.map((e) => e.exercise.name).join(', ');
        buffer.writeln('  • $dayName (id: ${workout.id}): "${workout.workoutName}" - ${workout.exercises.length} exercises ($exercises)');
      }
      buffer.writeln();
    }

    // Séances MANQUÉES
    if (missed.isNotEmpty) {
      buffer.writeln('MISSED SESSIONS (past, cannot be recovered):');
      for (final workout in missed) {
        final dayName = _formatDayName(workout.plannedDate, 'en').toLowerCase();
        buffer.writeln('  ✗ $dayName: "${workout.workoutName}" - missed');
      }
    }

    // Résumé
    final totalPlannedOrCompleted = completed.length + planned.length;
    buffer.writeln('\nSUMMARY: ${completed.length} completed + ${planned.length} planned = $totalPlannedOrCompleted sessions this week');

    return buffer.toString().trim();
  }









  // =====================================================
  // FUNCTION CALLING - Nouvelle approche
  // =====================================================

  /// Définition des tools disponibles pour le planner
  // Stocker la dernière action pour permettre l'annulation
  static Map<String, dynamic>? _lastAction;

  // Action en attente de confirmation
  static Map<String, dynamic>? _pendingAction;

  // Actions supplémentaires à exécuter après confirmation
  static List<Map<String, dynamic>>? _pendingFollowUpActions;

  /// Les outils du mode sport. Public pour que les tests lisent la vraie
  /// liste : le test en portait une copie recopiée à la main, déjà
  /// désynchronisée sur deux points.
  static List<Map<String, dynamic>> get plannerTools => [
    {
      'name': 'request_confirmation',
      'description': 'ALWAYS use this tool BEFORE any destructive action (delete). Describe what will be done and ask user to confirm. The user must say "oui", "yes", "confirme" to proceed.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action_type': {
            'type': 'string',
            'description': 'Type of action to confirm',
            'enum': ['delete_all', 'delete_all_workouts', 'delete_all_cardio', 'delete_workout', 'delete_cardio', 'delete_day_sessions', 'delete_sessions'],
          },
          'action_description': {
            'type': 'string',
            'description': '''Human-readable description of what will be DELETED (in user language).
MUST explicitly say "supprimer"/"delete" in the description!
Examples:
- FR: "supprimer toutes les séances de cardio de la semaine"
- FR: "supprimer la séance de musculation de mardi"
- EN: "delete all cardio sessions this week"
- EN: "delete Tuesday's workout"''',
          },
          'action_args': {
            'type': 'object',
            'description': '''Arguments for the deletion action:
- For delete_cardio/delete_workout/delete_day_sessions: {"day": "monday|tuesday|..."}
- For delete_sessions: {"days": [...], "exclude_days": [...], "session_types": [...], "activity_names": [...]}''',
            'properties': {
              'day': {
                'type': 'string',
                'description': 'Day for single delete or day sessions delete',
                'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
              },
              'days': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'List of days for delete_sessions',
              },
              'exclude_days': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'Days to exclude for delete_sessions',
              },
              'session_types': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'Session types (workout, cardio) for delete_sessions',
              },
              'activity_names': {
                'type': 'array',
                'items': {'type': 'string'},
                'description': 'Activity names to target for delete_sessions',
              },
            },
          },
        },
        'required': ['action_type', 'action_description'],
      },
    },
    {
      'name': 'delete_all',
      'description': 'Delete ALL planned activities (both workouts AND cardio) for this week. Use this when user says "supprime tout" / "efface tout" / "delete everything". Use request_confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {},
        'required': [],
      },
    },
    {
      'name': 'delete_all_workouts',
      'description': 'Delete ALL MUSCULATION/STRENGTH workouts planned for this week. NOT for cardio! Use request_confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {},
        'required': [],
      },
    },
    {
      'name': 'delete_all_cardio',
      'description': 'Delete ALL CARDIO sessions planned for this week. NOT for workouts/musculation! Use request_confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {},
        'required': [],
      },
    },
    {
      'name': 'delete_workout',
      'description': 'Delete a specific MUSCULATION/STRENGTH workout on a given day. NOT for cardio! If multiple workouts on same day, use workout_name to target the right one.',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day of the workout to delete (monday, tuesday, wednesday, thursday, friday, saturday, sunday)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'workout_name': {
            'type': 'string',
            'description': 'Optional: Name or type of the workout to delete if multiple workouts on same day (e.g. "Pecs", "Push", "Full Body")',
          },
        },
        'required': ['day'],
      },
    },
    {
      'name': 'delete_cardio',
      'description': 'Delete a specific CARDIO session on a given day. NOT for workouts/musculation! If multiple cardio on same day, use activity_name to target.',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day of the cardio to delete (monday, tuesday, wednesday, thursday, friday, saturday, sunday)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'activity_name': {
            'type': 'string',
            'description': 'Optional: Name of the cardio activity to delete if multiple on same day (e.g. "Running", "Cycling", "HIIT")',
          },
        },
        'required': ['day'],
      },
    },
    {
      'name': 'delete_day_sessions',
      'description': 'Delete ALL sessions (both workouts AND cardio) on a specific day. Use when user says "supprime toutes les séances de [jour]" / "delete all sessions on [day]". Use request_confirmation first!',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day to delete all sessions from (monday, tuesday, wednesday, thursday, friday, saturday, sunday)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
        },
        'required': ['day'],
      },
    },
    {
      'name': 'delete_sessions',
      'description': '''FLEXIBLE DELETE TOOL - Use this for any complex deletion request.
Can delete by:
- Specific days (one or multiple)
- Session types (workout, cardio, or both)
- Activity names
Use request_confirmation FIRST with action_type="delete_sessions"!

Examples:
- "supprime mes séances de lundi et mardi" → days=["monday","tuesday"]
- "supprime toutes les séances de muscu" → session_types=["workout"]
- "supprime tout le cardio de la semaine sauf vendredi" → session_types=["cardio"], exclude_days=["friday"]
- "supprime mes séances de Dos" → activity_names=["Back", "Dos"]''',
      'parameters': {
        'type': 'object',
        'properties': {
          'days': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
            },
            'description': 'List of days to delete from. If empty/null, applies to all days of the week.',
          },
          'exclude_days': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
            },
            'description': 'Days to exclude from deletion (useful with "delete all except...")',
          },
          'session_types': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['workout', 'cardio'],
            },
            'description': 'Types of sessions to delete. If empty/null, deletes both workout AND cardio.',
          },
          'activity_names': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Optional: Specific activity/workout names to target (e.g. ["Dos", "Back"] or ["Running", "HIIT"])',
          },
        },
        'required': [],
      },
    },
    {
      'name': 'create_workout',
      'description': 'Create a new MUSCULATION/STRENGTH workout for a specific day. IMPORTANT: If user did not specify workout_type or duration_minutes, use ask_clarification FIRST to ask what type and how long.',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day for the workout',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'workout_type': {
            'type': 'string',
            'description': 'Type of workout - REQUIRED. User must specify: "Chest/Pecs", "Back/Dos", "Legs/Jambes", "Shoulders/Épaules", "Arms/Bras", "Full Body", "Push", "Pull", "Upper Body/Haut du corps", "Lower Body/Bas du corps"',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration in minutes - REQUIRED. Accept any reasonable value between 15-120 minutes. Use the EXACT duration the user specifies (e.g., if user says 55min, use 55).',
          },
          'focus': {
            'type': 'string',
            'description': 'Specific focus or description for the workout generation (e.g., "focus on compound movements", "hypertrophy training")',
          },
        },
        'required': ['day', 'workout_type', 'duration_minutes'],
      },
    },
    {
      'name': 'move_workout',
      'description': 'Move a workout from one day to another',
      'parameters': {
        'type': 'object',
        'properties': {
          'from_day': {
            'type': 'string',
            'description': 'Current day of the workout',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'to_day': {
            'type': 'string',
            'description': 'New day for the workout',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
        },
        'required': ['from_day', 'to_day'],
      },
    },
    {
      'name': 'move_cardio',
      'description': 'Move a CARDIO session from one day to another. NOT for workouts/musculation!',
      'parameters': {
        'type': 'object',
        'properties': {
          'from_day': {
            'type': 'string',
            'description': 'Current day of the cardio session',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'to_day': {
            'type': 'string',
            'description': 'New day for the cardio session',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
        },
        'required': ['from_day', 'to_day'],
      },
    },
    {
      'name': 'modify_workout',
      'description': '''Modify an existing workout session. Can change type, duration, or convert to cardio/HIIT.
IMPORTANT: Use this tool to REPLACE a workout with a new one. Do NOT call delete_workout before this!
Use when user wants to change something about an existing planned workout:
- "change mardi en dos" → modify_workout(current_day="tuesday", new_workout_type="Dos")
- "remplace ma séance jambe par épaules" → modify_workout(current_workout_name="jambe", new_workout_type="Épaules")
- "rallonge à 60min" → modify_workout(current_day=X, new_duration_minutes=60)
- "remplace ma séance muscu par du HIIT" → modify_workout(current_day=X, new_workout_type="hiit") → will ask HIIT params
- "change ma séance en cardio/course/vélo" → modify_workout(current_day=X, new_workout_type="running") → will ask duration''',
      'parameters': {
        'type': 'object',
        'properties': {
          'current_day': {
            'type': 'string',
            'description': 'Current day of the workout to modify. Use if user specifies day.',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'current_workout_name': {
            'type': 'string',
            'description': 'Name/type of the workout to modify (e.g., "jambe", "dos", "pecs"). Use if user specifies workout name instead of day.',
          },
          'new_day': {
            'type': 'string',
            'description': 'New day for the workout (only if changing day)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_workout_type': {
            'type': 'string',
            'description': 'New workout type (e.g., "Dos", "Pecs", "Full Body", "Épaules", "Jambes", "Bras")',
          },
          'new_duration_minutes': {
            'type': 'integer',
            'description': 'New duration in minutes (only if changing duration)',
          },
          'regenerate_exercises': {
            'type': 'boolean',
            'description': 'If true, regenerate all exercises for this workout. Auto-set to true when changing workout_type.',
          },
        },
        'required': [],
      },
    },
    {
      'name': 'modify_cardio',
      'description': '''Modify an existing cardio session. Can change activity type, duration, distance, or day.
If changing to HIIT: the system will automatically ask for HIIT type.
IMPORTANT: When user specifies a distance (e.g., "5km run"), ALWAYS set new_target_km!
Examples:
- "change mon HIIT en course de 5km" → modify_cardio(current_day=X, new_activity="running", new_target_km=5)
- "change mon cardio de lundi en vélo 10km" → modify_cardio(current_day="monday", new_activity="bike", new_target_km=10)
- "change ma course en HIIT" → modify_cardio(current_day=X, new_activity="hiit") → will ask HIIT type
- "modifie la durée à 45min" → modify_cardio(current_day=X, new_duration_minutes=45)''',
      'parameters': {
        'type': 'object',
        'properties': {
          'current_day': {
            'type': 'string',
            'description': 'Current day of the cardio to modify',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_day': {
            'type': 'string',
            'description': 'New day for the cardio (only if changing day)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'new_activity': {
            'type': 'string',
            'description': 'New activity type. If "hiit", system will ask for HIIT config.',
            'enum': ['running', 'bike', 'walking', 'hiit'],
          },
          'hiit_type': {
            'type': 'string',
            'description': 'Only when new_activity="hiit". Type of HIIT workout.',
            'enum': ['tabata', 'hiit_beginner', 'hiit_intense', 'custom'],
          },
          'new_duration_minutes': {
            'type': 'integer',
            'description': 'New duration in minutes (only if changing duration)',
          },
          'new_target_km': {
            'type': 'number',
            'description': 'New target distance in km (only for running/bike/walking, NOT for hiit)',
          },
        },
        'required': ['current_day'],
      },
    },
    {
      'name': 'create_cardio',
      'description': '''Create a cardio session (running, bike, walking) for a specific day.
NOT for HIIT - use create_hiit instead!
Need duration_minutes OR target_km (ask if neither provided).''',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day for the cardio session',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'activity': {
            'type': 'string',
            'description': 'Type of cardio activity. NOT HIIT (use create_hiit for that).',
            'enum': ['running', 'bike', 'walking'],
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration in minutes.',
          },
          'target_km': {
            'type': 'number',
            'description': 'Target distance in kilometers.',
          },
        },
        'required': ['day', 'activity'],
      },
    },
    {
      'name': 'create_hiit',
      'description': '''Create a HIIT/Tabata session for a specific day.
Ask user what type they want OR propose presets:
- "tabata": Classic Tabata (4 min - 20s effort / 10s rest - 8 rounds)
- "hiit_beginner": Beginner HIIT (15 min - 30s effort / 30s rest - 15 rounds)
- "hiit_intense": Intense HIIT (20 min - 45s effort / 15s rest - 20 rounds)
- "custom": Custom config (ask for work_seconds, rest_seconds, rounds)

If user doesn't specify, propose the presets and let them choose OR offer to customize.
Example: "Tu veux quel type de HIIT? 🔥 Tabata (4min intense), 💪 HIIT débutant (15min), 🏋️ HIIT intense (20min), ou tu veux personnaliser?"''',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day for the HIIT session',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'hiit_type': {
            'type': 'string',
            'description': 'Type of HIIT workout. Use preset ID or "custom" for custom config.',
            'enum': ['tabata', 'hiit_beginner', 'hiit_intense', 'custom'],
          },
          'work_seconds': {
            'type': 'integer',
            'description': 'Work duration in seconds (only for custom). E.g., 30, 40, 45.',
          },
          'rest_seconds': {
            'type': 'integer',
            'description': 'Rest duration in seconds (only for custom). E.g., 10, 15, 20, 30.',
          },
          'rounds': {
            'type': 'integer',
            'description': 'Number of rounds (only for custom). E.g., 8, 10, 12, 15, 20.',
          },
        },
        'required': ['day'],
      },
    },
    {
      'name': 'ask_clarification',
      'description': 'Ask user for more information when the request is unclear or missing required details (like duration)',
      'parameters': {
        'type': 'object',
        'properties': {
          'question': {
            'type': 'string',
            'description': 'The clarification question to ask the user',
          },
        },
        'required': ['question'],
      },
    },
    {
      'name': 'undo_last_action',
      'description': 'Undo the last action (delete). Use when user says "annuler", "undo", "revenir en arrière", "annule ça", etc.',
      'parameters': {
        'type': 'object',
        'properties': {},
        'required': [],
      },
    },
  ];

  /// Outils pour le mode repas (nutrition)
  static List<Map<String, dynamic>> get mealTools => [
    {
      'name': 'create_meal',
      'description': 'Create a NEW planned meal entry. Use this to ADD meals - multiple entries of the same meal type are allowed (e.g., 2 snacks). ALWAYS use this for adding new items, even if a meal of the same type already exists.',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day for the meal (monday, tuesday, wednesday, thursday, friday, saturday, sunday)',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'meal_type': {
            'type': 'string',
            'description': 'Type of meal: breakfast (petit-déjeuner), lunch (déjeuner), dinner (dîner), snack (collation)',
            'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
          },
          'dish_name': {
            'type': 'string',
            'description': 'Name of the dish (e.g., "Omelette aux champignons", "Lasagnes bolognaise", "Salade César")',
          },
          'dish_description': {
            'type': 'string',
            'description': 'DETAILED description with 4 sections separated by "---": 1) Brief description, 2) INGRÉDIENTS: list with quantities, 3) RECETTE: numbered steps, 4) ASTUCE: cooking tip. Example: "Omelette moelleuse aux champignons de Paris.---INGRÉDIENTS:\\n- 3 œufs\\n- 100g champignons\\n- 30g fromage râpé\\n- Sel, poivre---RECETTE:\\n1. Battre les œufs\\n2. Faire revenir les champignons\\n3. Verser les œufs et cuire 3min\\n4. Ajouter le fromage et plier---ASTUCE: Ne pas trop cuire pour garder le moelleux"',
          },
          'calories': {
            'type': 'integer',
            'description': 'Estimated calories (kcal)',
          },
          'proteins': {
            'type': 'number',
            'description': 'Estimated proteins in grams',
          },
          'carbs': {
            'type': 'number',
            'description': 'Estimated carbohydrates in grams',
          },
          'fats': {
            'type': 'number',
            'description': 'Estimated fats in grams',
          },
          'quantity_g': {
            'type': 'number',
            'description': 'Estimated portion size in grams (default 200-400g depending on meal)',
          },
        },
        'required': ['day', 'meal_type', 'dish_name', 'calories', 'proteins', 'carbs', 'fats', 'quantity_g'],
      },
    },
    {
      'name': 'delete_meal',
      'description': 'Delete a specific planned meal. Use request_confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day of the meal to delete',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'meal_type': {
            'type': 'string',
            'description': 'Type of meal to delete',
            'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
          },
        },
        'required': ['day', 'meal_type'],
      },
    },
    {
      'name': 'delete_all_meals',
      'description': 'Delete ALL planned meals for this week. Use request_confirmation first.',
      'parameters': {
        'type': 'object',
        'properties': {},
        'required': [],
      },
    },
    {
      'name': 'modify_meal',
      'description': 'REPLACE an existing meal with a new one. ONLY use when user explicitly says "change", "replace", "modify" (e.g., "change my snack to..."). Do NOT use for adding new items - use create_meal instead!',
      'parameters': {
        'type': 'object',
        'properties': {
          'day': {
            'type': 'string',
            'description': 'Day of the meal to modify',
            'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
          },
          'meal_type': {
            'type': 'string',
            'description': 'Type of meal to modify',
            'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
          },
          'current_dish_name': {
            'type': 'string',
            'description': 'Name (or part of it) of the EXISTING dish being replaced. Required when the day has several entries of that meal type (e.g. two snacks), so the right one is replaced.',
          },
          'dish_name': {
            'type': 'string',
            'description': 'NEW dish name (short)',
          },
          'dish_description': {
            'type': 'string',
            'description': 'NEW dish description with ingredients and recipe',
          },
          'calories': {
            'type': 'integer',
            'description': 'NEW estimated calories (kcal)',
          },
          'proteins': {
            'type': 'number',
            'description': 'NEW estimated proteins (g)',
          },
          'carbs': {
            'type': 'number',
            'description': 'NEW estimated carbs (g)',
          },
          'fats': {
            'type': 'number',
            'description': 'NEW estimated fats (g)',
          },
          'quantity_g': {
            'type': 'number',
            'description': 'Estimated portion size in grams (default 200-400g depending on meal)',
          },
        },
        'required': ['day', 'meal_type', 'dish_name', 'calories', 'proteins', 'carbs', 'fats', 'quantity_g'],
      },
    },
    {
      'name': 'request_confirmation',
      'description': 'ALWAYS use this tool BEFORE any destructive action (delete). Ask user to confirm. CRITICAL: You MUST include day and meal_type in action_args!',
      'parameters': {
        'type': 'object',
        'properties': {
          'action_type': {
            'type': 'string',
            'description': 'Type of action to confirm',
            'enum': ['delete_meal', 'delete_all_meals'],
          },
          'action_description': {
            'type': 'string',
            'description': 'Human-readable description of what will be deleted (in user language)',
          },
          'action_args': {
            'type': 'object',
            'description': 'REQUIRED: Arguments for the action. For delete_meal: {"day": "monday", "meal_type": "breakfast"}',
            'properties': {
              'day': {
                'type': 'string',
                'description': 'Day of the meal (required for delete_meal)',
                'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
              },
              'meal_type': {
                'type': 'string',
                'description': 'Type of meal (required for delete_meal)',
                'enum': ['breakfast', 'lunch', 'dinner', 'snack'],
              },
            },
            'required': ['day', 'meal_type'],
          },
        },
        'required': ['action_type', 'action_description', 'action_args'],
      },
    },
    {
      'name': 'ask_clarification',
      'description': 'Ask user for more information when the request is unclear (which day, which meal type, dietary preferences)',
      'parameters': {
        'type': 'object',
        'properties': {
          'question': {
            'type': 'string',
            'description': 'The clarification question to ask the user',
          },
        },
        'required': ['question'],
      },
    },
  ];

  /// Construire le prompt système pour le mode repas
  static Future<String> _buildMealsSystemPrompt(String context) async {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';

    // Récupérer les préférences alimentaires de l'utilisateur
    String dietaryInfo = '';
    try {
      final prefs = await CoachPreferenceExtractor.instance.getUserPreferences();
      if (prefs != null && prefs.dietaryRestrictions.isNotEmpty) {
        final restrictions = prefs.dietaryRestrictions.join(', ');
        dietaryInfo = '\nDIETARY RESTRICTIONS: $restrictions';
      }
      if (prefs != null && prefs.allergies.isNotEmpty) {
        final allergies = prefs.allergies.join(', ');
        dietaryInfo += '\nALLERGIES: $allergies';
      }
    } catch (e) {
      debugPrint('Could not get dietary preferences: $e');
    }

    return '''
You are Ryze, a friendly nutrition coach AI assistant. You help users plan their weekly meals.
ALWAYS respond in $languageName.

═══════════════════════════════════════════════════════════════
                    ⚠️ RESPONSE STYLE - CRITICAL!
═══════════════════════════════════════════════════════════════
1. BE CONCISE: Short, structured responses. NO WALLS OF TEXT!
2. USE BULLET POINTS: Structure with • or numbers, not long paragraphs
3. MAX 2 BUBBLES: If you need more space, split with "|||" (max 2 parts)
   Example: "First message|||Second message"
4. SYNTHESIZE: Get to the point quickly. Users don't want to read essays.
5. NO REPETITION: Don't repeat what user already knows

GOOD RESPONSE:
"✅ Repas planifiés pour lundi!

• Petit-déj: Porridge protéiné
• Déjeuner: Poulet grillé + riz
• Dîner: Saumon + légumes"

BAD RESPONSE (too long):
"Parfait ! Je vais planifier tes repas pour lundi. J'ai préparé un petit-déjeuner équilibré avec un porridge protéiné qui va bien te caler pour la matinée. Pour le déjeuner, j'ai choisi un poulet grillé accompagné de riz complet..."

═══════════════════════════════════════════════════════════════
              🔴 CRITICAL: USE THE MACRO TABLE!
═══════════════════════════════════════════════════════════════
The context contains a table "RECOMMENDED MACROS PER MEAL" with EXACT values to use!

⚠️ For EACH create_meal call, use the values from the table:
- breakfast → use breakfast row values (calories, proteins, carbs, fats)
- lunch → use lunch row values
- dinner → use dinner row values
- snack → use snack row values

DO NOT invent your own values! The table is calculated from the user's personal targets.

═══════════════════════════════════════════════════════════════
              🔴 CRITICAL: COMPLETE ALL DAYS
═══════════════════════════════════════════════════════════════
WHEN USER ASKS FOR MULTIPLE MEALS (e.g., "planifie mes repas", "la semaine"):
→ You MUST generate meals for EVERY available day!
→ EACH DAY must have: breakfast + lunch + dinner (3 meals MINIMUM)
→ DO NOT STOP before completing all days!

CHECKLIST before finishing:
□ Did I create breakfast for EVERY available day?
□ Did I create lunch for EVERY available day?
□ Did I create dinner for EVERY available day?
→ If any checkbox is NO, continue creating meals!

Example: 4 available days = 12 create_meal calls minimum
- Day 1: breakfast ✓ lunch ✓ dinner ✓
- Day 2: breakfast ✓ lunch ✓ dinner ✓
- Day 3: breakfast ✓ lunch ✓ dinner ✓
- Day 4: breakfast ✓ lunch ✓ dinner ✓

═══════════════════════════════════════════════════════════════
                    MEAL TYPES
═══════════════════════════════════════════════════════════════
- breakfast: Morning meal - target ~${_mealSplitPercent('breakfast')}% daily calories
- lunch: Midday meal - target ~${_mealSplitPercent('lunch')}% daily calories
- dinner: Evening meal - target ~${_mealSplitPercent('dinner')}% daily calories
- snack: Light snack - target ~${_mealSplitPercent('snack')}% daily calories (optional)

═══════════════════════════════════════════════════════════════
                    PLANNING RULES
═══════════════════════════════════════════════════════════════
1. ONLY use days from AVAILABLE DAYS in context
2. For TODAY: If user is vague, use SUGGESTED MEALS based on time. If user specifies a meal type, ALWAYS do it!
3. For FUTURE days: All meal types are available (breakfast, lunch, dinner)
4. ALWAYS vary the dishes - don't repeat the same meal twice
5. AIM for daily calorie target within ±10% range (realistic, not exact!)
6. Use REALISTIC ingredient quantities (100g, 150g, 2 eggs) NOT decimals (127.3g)
7. Each day's total SHOULD be slightly different - that's natural and realistic!

🔴 CRITICAL RULE - RESPECT USER'S SPECIFIC FOOD REQUESTS:
When the user mentions a SPECIFIC food or ingredient (whey, chicken, salmon, eggs, etc.):
→ You MUST use THAT EXACT food in the dish!
→ NEVER substitute with something else!
→ Examples:
  - "30g de whey" → Create a dish WITH whey protein (shake, smoothie, etc.)
  - "je veux du poulet" → Create a dish WITH chicken
  - "plan me a salmon dinner" → Create a dish WITH salmon
→ Adapt the dish around the requested ingredient, don't ignore it!
→ Use the exact quantity if specified (e.g., "30g whey" = use 30g whey)

WHEN USER ASKS FOR "rest of the day" / "aujourd'hui" / "heute" (vague request):
→ Use SUGGESTED MEALS based on current time
→ Skip meals that are typically past (e.g., no breakfast at 22h unless explicitly asked)

WHEN USER EXPLICITLY ASKS FOR A SPECIFIC MEAL:
  Examples: "plan my dinner" / "planifie mon dîner" / "I want breakfast" / "je veux un petit-déj"
→ ALWAYS plan it, regardless of current time!
→ NEVER refuse or suggest something else - just do what they ask!

═══════════════════════════════════════════════════════════════
              🔴 DISH DESCRIPTION FORMAT (REQUIRED!)
═══════════════════════════════════════════════════════════════
For dish_description, ALWAYS use this format with "---" separators.
Use the SECTION NAMES in the USER'S LANGUAGE (from $languageName):
- French: INGRÉDIENTS, RECETTE, ASTUCE
- English: INGREDIENTS, RECIPE, TIP
- German: ZUTATEN, REZEPT, TIPP

Format:
[Brief description of the dish]---INGREDIENTS:
- [quantity] [ingredient 1]
- [quantity] [ingredient 2]
...---RECIPE:
1. [Step 1]
2. [Step 2]
...---TIP: [Cooking tip or variation]

⚠️ IMPORTANT RULE FOR INGREDIENTS:
- ONE ingredient per line (NEVER combine multiple ingredients)
- NEVER combine like: "egg + yolk", "salt + pepper", "Salz + Pfeffer"
- BAD: "- 1 whole egg + 1 egg yolk" or "- Salt, pepper"
- GOOD: Separate lines:
  "- 1 whole egg"
  "- 1 egg yolk"
  "- Salt"
  "- Pepper"

Example (in French, adapt to user's language):
"Fluffy mushroom omelette, ideal for a protein-rich breakfast.---INGREDIENTS:
- 3 eggs
- 100g button mushrooms
- 30g grated cheese
- 10g butter
- Salt
- Pepper---RECIPE:
1. Beat the eggs with salt and pepper
2. Sauté the sliced mushrooms in butter for 3-4 min
3. Pour the beaten eggs and cook over medium heat for 2-3 min
4. Add the grated cheese and fold the omelette---TIP: Keep the center slightly runny for more fluffiness"

═══════════════════════════════════════════════════════════════
              DELETE & MODIFY MEALS
═══════════════════════════════════════════════════════════════
DELETE MEAL - Keywords (detect in any language):
  French: "supprime", "enlève", "retire", "efface"
  English: "delete", "remove", "cancel"
  German: "lösche", "entferne"
  → When user wants to DELETE (WITHOUT a replacement)
  → ALWAYS use request_confirmation FIRST with action_type="delete_meal"
  → MUST include day AND meal_type in action_args!

  Example: "delete my Thursday snack" / "supprime ma collation de jeudi"
  → request_confirmation(
      action_type="delete_meal",
      action_description="delete the Thursday snack",
      action_args={"day": "thursday", "meal_type": "snack"}
    )

ADD NEW MEAL - Keywords (detect in any language):
  French: "planifie", "ajoute", "je veux", "prévois"
  English: "plan", "add", "I want", "schedule"
  German: "plane", "füge hinzu", "ich möchte"
  → ALWAYS use create_meal to ADD a new entry!
  → Even if a meal of the same type already exists, CREATE A NEW ENTRY!
  → User can have MULTIPLE items for the same meal type (e.g., 2 snacks)

  Example: User already has "Whey Shake" as snack, then asks "planifie des fraises en collation"
  → create_meal(day="friday", meal_type="snack", dish_name="Fraises", ...)
  → This creates a SECOND snack entry, NOT replacing the whey shake!

MODIFY MEAL - Keywords (detect in any language):
  French: "change en", "remplace par", "modifie", "transforme"
  English: "change to", "replace with", "modify", "switch to"
  German: "ändere zu", "ersetze durch", "wechsle zu"
  → Use modify_meal ONLY when user explicitly wants to REPLACE an existing meal!
  → Provide NEW dish details with realistic macros

  Example: "change my whey shake to a smoothie" / "change mon shaker whey en smoothie"
  → modify_meal (replaces the existing meal)

⚠️ CRITICAL DISTINCTION - ADD vs MODIFY:
  - "planifie des fraises" / "add strawberries" → ADD (create_meal - new entry!)
  - "ajoute une collation" / "add a snack" → ADD (create_meal - new entry!)
  - "change ma collation en fraises" / "change my snack to strawberries" → MODIFY (modify_meal - replaces!)
  - "remplace le shaker par des fraises" / "replace the shake with strawberries" → MODIFY (modify_meal)

  When in doubt, CREATE A NEW ENTRY (add) rather than replacing!

$dietaryInfo

$context

${_getFormattedHistory()}
''';
  }

  /// Appeler Gemini avec function calling
  static Future<PlannerActionResult> processRequestWithTools(
    String userMessage, {
    String? mode,
  }) async {
    final langCode = LocalizationService.instance.currentLanguageCode;

    try {
      // Vérifier si l'utilisateur répond à une demande de confirmation
      if (hasPendingAction) {
        if (_isConfirmation(userMessage)) {
          addToHistory('user', userMessage);
          final result = await executePendingAction();
          addToHistory('assistant', result.message);
          return result;
        } else if (_isCancellation(userMessage)) {
          cancelPendingAction();
          addToHistory('user', userMessage);
          final cancelMsg = langCode == 'fr' ? '❌ Action annulée' :
                            langCode == 'de' ? '❌ Aktion abgebrochen' :
                            '❌ Action cancelled';
          addToHistory('assistant', cancelMsg);
          return PlannerActionResult.success(cancelMsg);
        }
        // Si ce n'est ni oui ni non, continuer normalement mais effacer l'action en attente
        cancelPendingAction();
      }

      // Vérifier la limite d'utilisation
      if (!await canUseAI()) {
        return PlannerActionResult(
          success: false,
          message: _getPaywallMessage(langCode),
          isPaywallRequired: true,
        );
      }

      // Ajouter à l'historique
      addToHistory('user', userMessage);

      // Construire le contexte
      final context = await _getUserContext();
      final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';

      // Sélectionner le prompt et les outils selon le mode
      final String systemPrompt;
      final List<Map<String, dynamic>> tools;

      if (mode == 'meals') {
        // Mode repas : utiliser le prompt et les outils nutrition
        // Calculer les jours disponibles (aujourd'hui + futurs)
        final now = DateTime.now();
        final todayWeekday = now.weekday; // 1=Monday, 7=Sunday
        final currentHour = now.hour;
        final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        final availableDays = dayNames.sublist(todayWeekday - 1); // Du jour actuel jusqu'à dimanche

        // Récupérer les repas DÉJÀ LOGUÉS dans le journal aujourd'hui
        final loggedMealsToday = await _getLoggedMealTypesToday();

        // Calculer les repas SUGGÉRÉS pour aujourd'hui selon l'heure
        // EXCLURE les repas déjà logués
        final List<String> suggestedMealsToday = [];
        if (currentHour < 10 && !loggedMealsToday.contains('breakfast')) suggestedMealsToday.add('breakfast');
        if (currentHour < 14 && !loggedMealsToday.contains('lunch')) suggestedMealsToday.add('lunch');
        if (currentHour < 21 && !loggedMealsToday.contains('dinner')) suggestedMealsToday.add('dinner');
        if (!loggedMealsToday.contains('snack')) suggestedMealsToday.add('snack');

        final suggestedMealsInfo = suggestedMealsToday.isEmpty
            ? 'snack only (late night)'
            : suggestedMealsToday.join(', ');

        // Calculer la distribution calorique et macros recommandée
        final dailyCalorieTarget = context['calorie_target'] ?? 2000;
        final dailyProteinTarget = (context['protein_target'] as num?)?.toDouble() ?? 100.0;
        final dailyCarbsTarget = (context['carbs_target'] as num?)?.toDouble() ?? 250.0;
        final dailyFatTarget = (context['fat_target'] as num?)?.toDouble() ?? 65.0;

        // Une seule répartition, celle de [mealSplit] : la prose du prompt
        // annonçait une fourchette et le tableau juste en dessous en calculait
        // une autre, sous un encadré « n'invente pas tes propres valeurs ».
        final breakfastShare = mealSplit['breakfast']!;
        final lunchShare = mealSplit['lunch']!;
        final dinnerShare = mealSplit['dinner']!;
        final snackShare = mealSplit['snack']!;

        final breakfastCal = (dailyCalorieTarget * breakfastShare).round();
        final breakfastProt = (dailyProteinTarget * breakfastShare).round();
        final breakfastCarbs = (dailyCarbsTarget * breakfastShare).round();
        final breakfastFat = (dailyFatTarget * breakfastShare).round();

        final lunchCal = (dailyCalorieTarget * lunchShare).round();
        final lunchProt = (dailyProteinTarget * lunchShare).round();
        final lunchCarbs = (dailyCarbsTarget * lunchShare).round();
        final lunchFat = (dailyFatTarget * lunchShare).round();

        final dinnerCal = (dailyCalorieTarget * dinnerShare).round();
        final dinnerProt = (dailyProteinTarget * dinnerShare).round();
        final dinnerCarbs = (dailyCarbsTarget * dinnerShare).round();
        final dinnerFat = (dailyFatTarget * dinnerShare).round();

        final snackCal = (dailyCalorieTarget * snackShare).round();
        final snackProt = (dailyProteinTarget * snackShare).round();
        final snackCarbs = (dailyCarbsTarget * snackShare).round();
        final snackFat = (dailyFatTarget * snackShare).round();

        final contextInfo = '''
═══════════════════════════════════════════════════════════════
            🎯 USER'S DAILY TARGETS
═══════════════════════════════════════════════════════════════
TODAY: ${DateTime.now().toIso8601String().split('T')[0]} (${dayNames[todayWeekday - 1]})
CURRENT TIME: ${currentHour}h${now.minute.toString().padLeft(2, '0')}
FITNESS GOAL: ${context['fitness_goal'] ?? 'maintain'}

⚠️ GOAL COHERENCE:
- "muscle_gain" / "prise_masse" → High protein, caloric surplus. NO deficit meals!
- "weight_loss" / "perte_poids" → Caloric deficit, high protein. NO surplus meals!
- "maintenance" → Balanced calories, hit targets.

CONFLICT HANDLING (2 steps):
1. First time user contradicts goal: Politely explain and ASK if they want to proceed anyway
2. If user INSISTS (says "oui", "yes", "quand même", "anyway", etc.): EXECUTE their request, then suggest updating goals

Example conflict responses:
- FR: "Tu es en prise de masse, mais tu demandes un repas en déficit 🤔 Tu veux quand même ?"
- EN: "Your goal is muscle gain, but you're asking for deficit meals 🤔 Proceed anyway?"

Example if user insists:
- FR: "OK je fais ! Si ton objectif a changé, pense à le modifier dans ⚙️ Paramètres > Objectifs"
- EN: "OK, done! If your goals changed, update them in ⚙️ Settings > Objectives"

DAILY TARGETS (BASE - varies by day!):
- Base Calories: $dailyCalorieTarget kcal
- Proteins: ${dailyProteinTarget.round()}g
- Carbs: ${dailyCarbsTarget.round()}g
- Fats: ${dailyFatTarget.round()}g

🏋️ TRAINING DAYS (adjust calories!):
- Days with SPORT: ${context['days_with_workout'] ?? 'none'} + ${context['days_with_cardio'] ?? 'none'}
- ON TRAINING DAYS: Add +10-15% calories (mainly from carbs)
- ON REST DAYS: Use base targets or slightly less (-5%)
→ This creates NATURAL VARIATION between days!

🔴 TARGET MACROS PER MEAL (aim for these ranges, NOT exact values!):
┌─────────────┬──────────────────┬──────────────────┬──────────────────┬──────────────────┐
│ Meal        │ Calories         │ Proteins         │ Carbs            │ Fats             │
├─────────────┼──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ breakfast   │ ${(breakfastCal * 0.9).round()}-${(breakfastCal * 1.1).round()} kcal │ ${(breakfastProt * 0.85).round()}-${(breakfastProt * 1.15).round()}g │ ${(breakfastCarbs * 0.85).round()}-${(breakfastCarbs * 1.15).round()}g │ ${(breakfastFat * 0.85).round()}-${(breakfastFat * 1.15).round()}g │
│ lunch       │ ${(lunchCal * 0.9).round()}-${(lunchCal * 1.1).round()} kcal │ ${(lunchProt * 0.85).round()}-${(lunchProt * 1.15).round()}g │ ${(lunchCarbs * 0.85).round()}-${(lunchCarbs * 1.15).round()}g │ ${(lunchFat * 0.85).round()}-${(lunchFat * 1.15).round()}g │
│ dinner      │ ${(dinnerCal * 0.9).round()}-${(dinnerCal * 1.1).round()} kcal │ ${(dinnerProt * 0.85).round()}-${(dinnerProt * 1.15).round()}g │ ${(dinnerCarbs * 0.85).round()}-${(dinnerCarbs * 1.15).round()}g │ ${(dinnerFat * 0.85).round()}-${(dinnerFat * 1.15).round()}g │
│ snack       │ ${(snackCal * 0.8).round()}-${(snackCal * 1.2).round()} kcal │ ${(snackProt * 0.8).round()}-${(snackProt * 1.2).round()}g │ ${(snackCarbs * 0.8).round()}-${(snackCarbs * 1.2).round()}g │ ${(snackFat * 0.8).round()}-${(snackFat * 1.2).round()}g │
└─────────────┴──────────────────┴──────────────────┴──────────────────┴──────────────────┘

⚠️ IMPORTANT - REALISTIC & VARIED MACROS:
- Use REALISTIC quantities (100g, 150g, 2 eggs, 1 chicken breast) NOT decimal values (127.3g)
- Each meal's macros should vary naturally based on the actual recipe
- 🔴 DAILY TOTALS MUST VARY! Training days: ${(dailyCalorieTarget * 1.10).round()}-${(dailyCalorieTarget * 1.15).round()} kcal | Rest days: ${(dailyCalorieTarget * 0.95).round()}-${(dailyCalorieTarget * 1.0).round()} kcal
- It's REQUIRED that each day has different totals - monotone calories is WRONG!
- Prioritize recipe authenticity over hitting exact numbers

TODAY'S INTAKE (already consumed):
- Calories: ${context['today_calories'] ?? 0}/$dailyCalorieTarget kcal
- Remaining today: ${context['remaining_calories'] ?? dailyCalorieTarget} kcal

═══════════════════════════════════════════════════════════════
        🔴 ALREADY LOGGED IN JOURNAL TODAY (DO NOT PLAN THESE!)
═══════════════════════════════════════════════════════════════
${loggedMealsToday.isEmpty ? 'No meals logged yet today' : 'MEALS ALREADY LOGGED TODAY: ${loggedMealsToday.join(', ')}'}
⚠️ CRITICAL: Do NOT create meals for types already logged!
- If user asks for "today's meals" or "ma journée", SKIP the meal types listed above
- Only suggest meals that are NOT in the logged list
- If ALL meals for today are already logged, suggest meals for TOMORROW instead

═══════════════════════════════════════════════════════════════
                    AVAILABLE DAYS (cannot plan past days!)
═══════════════════════════════════════════════════════════════
⚠️ TODAY IS: ${_getTodayWithDayName()} (when user says "today"/"aujourd'hui"/"heute", use THIS day!)
AVAILABLE DAYS: ${availableDays.join(', ')}
TOTAL DAYS TO PLAN: ${availableDays.length} days
TOTAL MEALS TO CREATE: ${availableDays.length * 3} meals (3 per day: breakfast + lunch + dinner)
SUGGESTED MEALS FOR TODAY (based on time ${currentHour}h): $suggestedMealsInfo
⚠️ BUT: If user explicitly asks for a specific meal type (e.g., "plan my dinner"), ALWAYS do it regardless of time!
⚠️ IMPORTANT:
- You can ONLY plan meals for the available days above. Past days are NOT allowed!
- For TODAY: suggested meals are $suggestedMealsInfo (it's ${currentHour}h), BUT if user explicitly asks for any meal, DO IT!
- For FUTURE days, all meal types are available (breakfast, lunch, dinner, snack)

═══════════════════════════════════════════════════════════════
                    THIS WEEK'S PLANNED MEALS
═══════════════════════════════════════════════════════════════
${context['planned_meals_this_week'] ?? 'No meals planned yet'}

USER REQUEST: "$userMessage"
''';
        systemPrompt = await _buildMealsSystemPrompt(contextInfo);
        tools = mealTools;
      } else {
        // Mode sport (défaut) : utiliser le prompt fitness
        tools = plannerTools;
        // Ce que le coach a retenu des contraintes physiques. Le planificateur
        // ne lisait de la mémoire que les allergies et le régime, côté repas :
        // un genou blessé raconté au coach n'empêchait ni les squats ni la
        // course le lendemain.
        final constraints = await _getPhysicalConstraints();
        systemPrompt = '''
You are Ryze, a friendly fitness coach AI assistant. You help users plan their weekly workouts and cardio.
ALWAYS respond in $languageName.

═══════════════════════════════════════════════════════════════
                    ⚠️ RESPONSE STYLE - CRITICAL!
═══════════════════════════════════════════════════════════════
1. BE CONCISE: Short, structured responses. NO WALLS OF TEXT!
2. USE BULLET POINTS: Structure with • or numbers, not long paragraphs
3. MAX 2 BUBBLES: If you need more space, split with "|||" (max 2 parts)
   Example: "First message|||Second message"
4. SYNTHESIZE: Get to the point quickly. Users don't want to read essays.
5. NO REPETITION: Don't repeat what user already knows

GOOD RESPONSE:
"✅ J'ai créé ta séance Dos pour mardi!

• 6 exercices ciblés
• 45 min
• Focus épaisseur + largeur"

BAD RESPONSE (too long):
"Super ! Je suis ravi de t'aider avec ta séance de dos. J'ai donc créé une séance complète qui va cibler tous les muscles de ton dos, avec des exercices variés pour travailler à la fois l'épaisseur et la largeur. Cette séance de 45 minutes comprend 6 exercices soigneusement sélectionnés..."

═══════════════════════════════════════════════════════════════
                        4 MAIN ACTIONS
═══════════════════════════════════════════════════════════════
1. CREATE - create one or more sessions
2. DELETE - delete one, several, or all sessions (requires confirmation)
3. MOVE - change the date of a session
4. MODIFY - change parameters of an existing session

═══════════════════════════════════════════════════════════════
                        2 SESSION TYPES
═══════════════════════════════════════════════════════════════
WORKOUT (musculation, strength training, gym, poids):
  → Tools: create_workout, delete_workout, delete_all_workouts, move_workout, modify_workout

CARDIO - ONLY 4 activities supported: running, bike, walking, hiit
  (course/running, vélo/bike, marche/walking, HIIT - NO swimming, NO elliptical, NO rowing!)
  → Tools: create_cardio, delete_cardio, delete_all_cardio, move_cardio, modify_cardio

BOTH (when user says "all" / "tout" / "alles", "my sessions" / "mes séances" without specifying):
  → Tool: delete_all (for deletion only)

═══════════════════════════════════════════════════════════════
                    REQUIRED INFORMATION
═══════════════════════════════════════════════════════════════
FOR WORKOUT:
  ✓ workout_type (Chest/Pecs, Back/Dos, Legs/Jambes, Full Body, Arms/Bras, Shoulders/Épaules, PPL...) → MUST ASK if missing
  ✓ duration_minutes (any value 15-120, use user's exact request) → MUST ASK if missing
  ✓ day(s) → CAN CHOOSE AUTOMATICALLY if missing (pick optimal days based on context)

FOR CARDIO (ONLY: running, bike, walking, hiit):
  ✓ activity_type (running/course, bike/vélo, walking/marche, HIIT) → MUST ASK if missing
  ✓ duration_minutes OR target_km (at least one) → MUST ASK if both missing
  ✓ day(s) → CAN CHOOSE AUTOMATICALLY if missing

DAY DELEGATION - User can say (in any language):
  "you choose" / "choisis pour moi" / "up to you" / "à toi de voir" / "decide" / "décide"
  → AI should choose optimal days based on user's schedule and create directly

═══════════════════════════════════════════════════════════════
          ⚠️ CONTEXTUAL CLARIFICATIONS - ASK ONLY WHAT'S MISSING!
═══════════════════════════════════════════════════════════════
CRITICAL: Adapt your question to what's actually missing. DO NOT ask for info already provided!

WORKOUT EXAMPLES (user can speak any language, detect intent):
• "3 Full Body sessions" / "3 séances Full Body"
  → type=✓ duration=✗ days=auto
  → ASK: "How long for each session? (e.g., 45min, 60min)"

• "a chest session on Tuesday" / "une séance pecs mardi"
  → type=✓ duration=✗ days=✓
  → ASK: "How long for your Chest session? (e.g., 45min, 60min)"

• "a gym session on Tuesday" / "une séance de muscu mardi"
  → type=✗ duration=✗ days=✓
  → ASK: "What type of session (Chest, Back, Legs, Full Body...) and how long? (e.g., 45min, 60min)"

• "a chest session 45min" / "une séance pecs 45min"
  → type=✓ duration=✓ days=auto
  → CREATE directly, choose optimal day

• "Full Body Monday 60min" / "Full Body lundi 60min"
  → type=✓ duration=✓ days=✓
  → CREATE directly

CARDIO EXAMPLES:
• "cycling on Friday" / "du vélo vendredi"
  → type=✓ duration/distance=✗ days=✓
  → ASK: "How long or what distance?"

• "30min of cardio" / "30min de cardio"
  → type=✗ duration=✓ days=auto
  → ASK: "What type of cardio? (running, cycling, walking...)"

• "30min of cycling" / "30min de vélo"
  → type=✓ duration=✓ days=auto
  → CREATE directly, choose optimal day

• "10km run on Monday" / "10km de course lundi"
  → type=✓ distance=✓ days=✓
  → CREATE directly

═══════════════════════════════════════════════════════════════
                    MOVE vs DELETE DISTINCTION
═══════════════════════════════════════════════════════════════
MOVE keywords (detect in any language):
  FR: "change X à Y", "de X à Y", "décale", "déplace", "mets X à Y"
  EN: "move X to Y", "from X to Y", "reschedule", "shift"
  DE: "verschiebe", "von X nach Y"
  → Use move_workout or move_cardio

DELETE keywords (detect in any language):
  FR: "supprime", "enlève", "retire", "efface", "annule"
  EN: "delete", "remove", "cancel", "clear"
  DE: "lösche", "entferne"
  → Use delete_* tools with request_confirmation FIRST

DELETE EXAMPLES:
• "delete all" / "supprime tout" → delete_sessions() (no params = delete all)
• "delete my sessions" / "supprime mes séances" → delete_sessions()
• "delete my workout sessions" / "supprime mes séances de muscu" → delete_sessions(session_types=["workout"])
• "delete my cardio sessions" / "supprime mes séances de cardio" → delete_sessions(session_types=["cardio"])
• "delete all sport sessions on Monday" / "supprime toutes les séances de lundi" → delete_sessions(days=["monday"])
• "delete Monday and Tuesday sessions" / "supprime lundi et mardi" → delete_sessions(days=["monday", "tuesday"])
• "delete all except Friday" / "supprime tout sauf vendredi" → delete_sessions(exclude_days=["friday"])
• "delete all cardio except weekend" / "supprime le cardio sauf le weekend" → delete_sessions(session_types=["cardio"], exclude_days=["saturday", "sunday"])
• "delete my Back workouts" / "supprime mes séances de Dos" → delete_sessions(session_types=["workout"], activity_names=["Back", "Dos"])
• "delete Monday's workout" / "supprime la séance de muscu de lundi" → delete_workout(day="monday") or delete_sessions(days=["monday"], session_types=["workout"])

MOVE EXAMPLES:
• "move Tuesday's session to Friday" / "change la séance de mardi à vendredi" → move_workout(tuesday→friday)
• "reschedule my Thursday cardio to Saturday" / "décale mon cardio de jeudi à samedi" → move_cardio(thursday→saturday)

═══════════════════════════════════════════════════════════════
                    MODIFY - Change existing session
═══════════════════════════════════════════════════════════════
MODIFY keywords (detect in any language):
  FR: "change en", "modifie", "rallonge", "raccourcis", "remplace par", "transformer"
  EN: "change to", "modify", "extend", "shorten", "replace with", "transform"
  DE: "ändere zu", "verlängere", "verkürze", "ersetze durch"
  → Use modify_workout or modify_cardio

⚠️ CRITICAL: When modifying a session, call ONLY modify_workout or modify_cardio!
   NEVER call delete_workout/delete_cardio before modify_workout/modify_cardio!
   The modify functions handle replacement internally.

IMPORTANT: MODIFY ≠ MOVE!
  MOVE = only change the day
  MODIFY = change type, duration, or other parameters (not the day)

MODIFY EXAMPLES:
• "change my Tuesday session to back" / "change ma séance de mardi en dos"
  → modify_workout(current_day="tuesday", new_workout_type="Back", regenerate_exercises=true)
  ❌ WRONG: delete_workout + modify_workout
  ✅ CORRECT: only modify_workout
• "extend my Monday session to 60min" / "rallonge ma séance de lundi à 60min"
  → modify_workout(current_day="monday", new_duration_minutes=60)
• "change my Wednesday cardio to cycling" / "change mon cardio de mercredi en vélo"
  → modify_cardio(current_day="wednesday", new_activity="bike")
• "modify Thursday's cardio duration to 45min" / "modifie la durée du cardio de jeudi à 45min"
  → modify_cardio(current_day="thursday", new_duration_minutes=45)
• "change my HIIT to a 5km run" / "change mon HIIT en course de 5km"
  → modify_cardio(current_day=X, new_activity="running", new_target_km=5)
  ⚠️ IMPORTANT: Always pass new_target_km when user specifies a distance!
• "replace my leg session with shoulders" / "remplace ma séance jambe par une séance épaule"
  → modify_workout(current_day=[day of leg session], new_workout_type="Shoulders", regenerate_exercises=true)

═══════════════════════════════════════════════════════════════
                    CONFIRMATION RULES
═══════════════════════════════════════════════════════════════
For ANY delete action, ALWAYS use request_confirmation FIRST.
Include day in action_args for single deletes:
  request_confirmation(action_type="delete_workout", action_args={"day": "monday"}, ...)

═══════════════════════════════════════════════════════════════
                    MULTIPLE ACTIONS
═══════════════════════════════════════════════════════════════
When user asks for multiple things, call ALL tools in the SAME response:
• "delete all and add 3 sessions" / "supprime tout et ajoute 3 séances" → [request_confirmation(delete_all), create_workout x3]

═══════════════════════════════════════════════════════════════
                    🎯 GOAL COHERENCE - CRITICAL!
═══════════════════════════════════════════════════════════════
User's fitness goal: ${context['fitness_goal'] ?? 'general_fitness'}

IMPORTANT: The user's request MUST align with their configured goal:
- "muscle_gain" / "prise_masse" → Focus on hypertrophy, strength, progressive overload. NO weight loss programs!
- "weight_loss" / "perte_poids" → Focus on calorie burn, cardio, HIIT. High volume, shorter rest.
- "maintenance" → Balanced approach, maintain current physique.
- "general_fitness" → Overall health, flexibility in programming.

⚠️ CONFLICT HANDLING (2 steps):
1. First time user contradicts goal: Politely explain and ASK if they want to proceed anyway
2. If user INSISTS (says "oui", "yes", "quand même", "anyway", "fais-le", etc.): EXECUTE their request, then suggest updating goals

Example conflict responses:
- FR: "Tu es en prise de masse, mais tu demandes de perdre du poids 🤔 Tu veux quand même ?"
- EN: "Your goal is muscle gain, but you're asking for weight loss 🤔 Proceed anyway?"

Example if user insists:
- FR: "OK c'est parti ! Si ton objectif a changé, pense à le modifier dans ⚙️ Paramètres > Objectifs"
- EN: "OK let's go! If your goals changed, update them in ⚙️ Settings > Objectives"

$constraints
CONTEXT:
⚠️ TODAY IS: ${_getTodayWithDayName()} (when user says "today"/"aujourd'hui"/"heute", use THIS day!)
- User's Goal: ${context['fitness_goal'] ?? 'general_fitness'}
- Days with WORKOUTS (musculation): ${context['days_with_workout'] ?? 'none'}
- Days with CARDIO: ${context['days_with_cardio'] ?? 'none'}
- Available days (ONLY these!): ${context['available_days'] ?? 'all'}

THIS WEEK'S PLANNING:
WORKOUTS: ${context['planned_workouts_this_week'] ?? 'No workouts planned'}
CARDIO: ${context['planned_cardio_this_week'] ?? 'No cardio planned'}

${_getFormattedHistory()}

USER REQUEST: "$userMessage"
''';
      } // Fin du else (mode sport)

      // Appeler l'API avec les tools
      final result = await _callGeminiWithTools(systemPrompt, userMessage, tools);

      if (result == null) {
        return PlannerActionResult.error(_getErrorMessage(langCode, 'api_error'));
      }

      // Traiter les appels de fonctions
      final toolCalls = result['tool_calls'] as List<Map<String, dynamic>>? ?? [];
      final responseText = result['response_text'] as String?;

      if (toolCalls.isEmpty && responseText != null) {
        // Pas d'appel de fonction, juste une réponse texte
        addToHistory('assistant', responseText);
        return PlannerActionResult(success: true, message: responseText);
      }

      // Exécuter les tools
      final executionResults = <String>[];
      bool hasWorkoutCreations = false;
      bool hasCardioCreations = false;
      bool hasMealCreations = false;
      final pendingWorkouts = <PendingWorkout>[];
      final pendingCardios = <PendingCardio>[];
      final pendingMeals = <PendingMeal>[];

      for (int i = 0; i < toolCalls.length; i++) {
        final toolCall = toolCalls[i];
        final functionName = toolCall['name'] as String;
        final args = toolCall['args'] as Map<String, dynamic>? ?? {};

        debugPrint('🔧 Executing tool: $functionName with args: $args');

        final toolResult = await _executeToolCall(functionName, args, langCode);

        // Ajouter le message seulement s'il existe (les pending_meal/pending_workout/pending_cardio n'en ont pas)
        if (toolResult['message'] != null) {
          executionResults.add(toolResult['message'] as String);
        }

        // Si on demande une confirmation, stocker les actions restantes et retourner
        if (toolResult['requires_confirmation'] == true) {
          // Stocker les tools restants pour les exécuter après confirmation
          if (i + 1 < toolCalls.length) {
            _pendingFollowUpActions = toolCalls.sublist(i + 1);
            debugPrint('📋 Stored ${_pendingFollowUpActions!.length} follow-up actions for after confirmation');
          } else {
            _pendingFollowUpActions = null;
          }

          final confirmMsg = toolResult['message'] as String;
          addToHistory('assistant', confirmMsg);
          return PlannerActionResult(
            success: true,
            message: confirmMsg,
            requiresConfirmation: true,
          );
        }

        if (functionName == 'create_workout' && toolResult['pending_workout'] != null) {
          hasWorkoutCreations = true;
          pendingWorkouts.add(toolResult['pending_workout'] as PendingWorkout);
        }

        if (functionName == 'create_cardio' && toolResult['pending_cardio'] != null) {
          hasCardioCreations = true;
          pendingCardios.add(toolResult['pending_cardio'] as PendingCardio);
        }

        if (functionName == 'create_meal' && toolResult['pending_meal'] != null) {
          hasMealCreations = true;
          pendingMeals.add(toolResult['pending_meal'] as PendingMeal);
        }

        if (functionName == 'ask_clarification') {
          // Retourner la question de clarification
          final question = args['question'] as String? ?? 'Could you provide more details?';
          addToHistory('assistant', question);
          return PlannerActionResult(success: true, message: question);
        }

        // Détecter si un tool retourne une question (nécessite plus d'info de l'utilisateur)
        // Par exemple create_hiit demandant quel type, ou create_cardio demandant la durée
        if (toolResult['needs_clarification'] == true ||
            (toolResult['success'] == true &&
             toolResult['message'] != null &&
             _isQuestionMessage(toolResult['message'] as String))) {
          final questionMsg = toolResult['message'] as String;
          addToHistory('assistant', questionMsg);
          return PlannerActionResult(success: true, message: questionMsg);
        }
      }

      // Si on a des sessions à créer (workouts ET/OU cardios), retourner en mode preview paginé
      if ((hasWorkoutCreations && pendingWorkouts.isNotEmpty) ||
          (hasCardioCreations && pendingCardios.isNotEmpty)) {
        // Convertir en PendingSession unifiés
        final pendingSessions = <PendingSession>[];

        for (final workout in pendingWorkouts) {
          pendingSessions.add(PendingSession.fromWorkout(workout));
        }
        for (final cardio in pendingCardios) {
          pendingSessions.add(PendingSession.fromCardio(cardio));
        }

        // Trier par date puis par type (workouts avant cardios pour le même jour)
        pendingSessions.sort((a, b) {
          final dateCompare = a.plannedDate.compareTo(b.plannedDate);
          if (dateCompare != 0) return dateCompare;
          // Même jour: workouts avant cardios
          if (a.type == PendingSessionType.workout && b.type == PendingSessionType.cardio) return -1;
          if (a.type == PendingSessionType.cardio && b.type == PendingSessionType.workout) return 1;
          return 0;
        });

        final previewMessage = responseText ?? _getSessionsPreviewMessage(langCode, pendingSessions);
        addToHistory('assistant', previewMessage);
        return PlannerActionResult.sessionPreview(
          message: previewMessage,
          sessions: pendingSessions,
        );
      }

      // Si on a des repas à créer, retourner en mode preview
      if (hasMealCreations && pendingMeals.isNotEmpty) {
        final previewMessage = responseText ?? _getMealsPreviewMessage(langCode, pendingMeals);
        addToHistory('assistant', previewMessage);
        return PlannerActionResult.mealPreview(
          message: previewMessage,
          meals: pendingMeals,
        );
      }

      // Retourner le résultat final
      final finalMessage = responseText ?? executionResults.join('\n');
      addToHistory('assistant', finalMessage);

      // NOTE: Ne PAS incrémenter ici pour les tool calls (delete, move, ask_clarification)
      // L'incrément se fait UNIQUEMENT dans confirmWorkouts/confirmSessions/confirmMeals
      // quand l'utilisateur VALIDE une création

      return PlannerActionResult.success(finalMessage);

    } catch (e) {
      debugPrint('❌ processRequestWithTools error: $e');
      return PlannerActionResult.error(_getErrorMessage(langCode, 'api_error'));
    }
  }

  /// Appeler Gemini API avec function calling
  /// Utilise gemini-2.5-flash pour un meilleur raisonnement et function calling
  static Future<Map<String, dynamic>?> _callGeminiWithTools(
    String systemPrompt,
    String userMessage,
    List<Map<String, dynamic>> tools,
  ) async {
    const maxRetries = 3;

    // Max tokens fixe pour supporter jusqu'à 21 repas (1 semaine × 3 repas/jour)
    // ~1700 tokens par repas complet avec recette détaillée
    // 1700 × 21 = 35,700 tokens (bien sous la limite Gemini de 65,536)
    const maxOutputTokens = 35700;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final url = Uri.parse(
          '${GeminiConfig.plannerApiUrl}?key=${GeminiConfig.geminiApiKey}',
        );

        final body = {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\nUser: $userMessage'}
              ]
            }
          ],
          'tools': [
            {
              'function_declarations': tools,
            }
          ],
          'tool_config': {
            'function_calling_config': {
              // AUTO et non ANY : forcer un appel d'outil à chaque tour tordait
              // les réponses conversationnelles (« merci », une question sur le
              // plan) en demande de clarification, faute d'avoir le droit de
              // répondre en texte.
              'mode': 'AUTO',
            }
          },
          'safetySettings': GeminiConfig.safetySettingsList,
          'generationConfig': {
            'temperature': 0.4,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': maxOutputTokens,
          },
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          debugPrint('❌ Gemini API error (attempt $attempt/$maxRetries): ${response.statusCode} - ${response.body}');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        final responseData = jsonDecode(response.body);
        final candidates = responseData['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          debugPrint('⚠️ No candidates in response (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        // Log finish reason for debugging
        final finishReason = candidates[0]['finishReason'] as String?;
        debugPrint('📊 Gemini finishReason: $finishReason');
        if (finishReason == 'MAX_TOKENS') {
          debugPrint('⚠️ Response was truncated due to MAX_TOKENS - consider increasing maxOutputTokens');
        }

        final content = candidates[0]['content'];
        if (content == null) {
          debugPrint('⚠️ Gemini returned null content (attempt $attempt/$maxRetries) - response may have been blocked');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          debugPrint('⚠️ No parts in response (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        // Extraire les function calls et le texte
        final toolCalls = <Map<String, dynamic>>[];
        String? responseText;

        for (final part in parts) {
          if (part['functionCall'] != null) {
            final functionCall = part['functionCall'];
            toolCalls.add({
              'name': functionCall['name'],
              'args': functionCall['args'] ?? {},
            });
          }
          if (part['text'] != null) {
            responseText = part['text'];
          }
        }

        debugPrint('🔧 Gemini tool_calls: ${toolCalls.length}, responseText: ${responseText != null}');
        for (final tc in toolCalls) {
          debugPrint('  - Function: ${tc['name']}, args: ${tc['args']}');
        }

        return {
          'tool_calls': toolCalls,
          'response_text': responseText,
        };
      } catch (e) {
        debugPrint('❌ _callGeminiWithTools error (attempt $attempt/$maxRetries): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        return null;
      }
    }

    return null;
  }

  /// Exécuter un appel de fonction
  static Future<Map<String, dynamic>> _executeToolCall(
    String functionName,
    Map<String, dynamic> args,
    String langCode,
  ) async {
    switch (functionName) {
      case 'request_confirmation':
        // Stocker l'action en attente et demander confirmation
        _pendingAction = {
          'action_type': args['action_type'],
          'action_args': args['action_args'] ?? {},
          'description': args['action_description'],
        };
        final confirmMsg = _getActionConfirmMessage(langCode, args['action_description'] as String? ?? '');
        return {
          'success': true,
          'message': confirmMsg,
          'requires_confirmation': true,
        };

      case 'delete_all':
        // Supprimer TOUT (workouts + cardio) en une seule action
        final workoutsToDelete = await WeeklyPlannerService.getAllWorkoutsThisWeek();
        final cardiosToDelete = await WeeklyPlannerService.getAllCardioThisWeek();
        _lastAction = {
          'type': 'delete_all',
          'deleted_workouts': workoutsToDelete.map((w) => w.toJson()).toList(),
          'deleted_cardios': cardiosToDelete.map((c) => c.toJson()).toList(),
        };
        await WeeklyPlannerService.deleteAllWorkoutsThisWeek();
        await WeeklyPlannerService.deleteAllCardioThisWeek();
        return {'success': true, 'message': _getToolMessage(langCode, 'all_deleted')};

      case 'delete_all_workouts':
        // Stocker les workouts avant suppression pour undo
        final workoutsToDelete = await WeeklyPlannerService.getAllWorkoutsThisWeek();
        _lastAction = {
          'type': 'delete_all_workouts',
          'deleted_workouts': workoutsToDelete.map((w) => w.toJson()).toList(),
        };
        await WeeklyPlannerService.deleteAllWorkoutsThisWeek();
        return {'success': true, 'message': _getToolMessage(langCode, 'all_workouts_deleted')};

      case 'delete_all_cardio':
        // Stocker les cardios avant suppression pour undo
        final cardiosToDelete = await WeeklyPlannerService.getAllCardioThisWeek();
        _lastAction = {
          'type': 'delete_all_cardio',
          'deleted_cardios': cardiosToDelete.map((c) => c.toJson()).toList(),
        };
        await WeeklyPlannerService.deleteAllCardioThisWeek();
        return {'success': true, 'message': _getToolMessage(langCode, 'all_cardio_deleted')};

      case 'delete_workout':
        final day = _parseSingleDay(args['day'] as String? ?? '');
        if (day == null) return {'success': false, 'message': 'Invalid day'};
        final workoutName = args['workout_name'] as String?;

        // Utiliser la méthode avec filtre par nom si fourni
        final workout = await WeeklyPlannerService.findPlannedWorkoutByNameForDate(
          day,
          workoutName: workoutName,
        );
        if (workout != null) {
          // Stocker le workout complet pour undo
          _lastAction = {
            'type': 'delete_workout',
            'deleted_workout': workout.toJson(),
          };
          await WeeklyPlannerService.deletePlannedWorkout(workout.id);
          final deletedName = workout.workoutName;
          final msg = langCode == 'fr'
              ? '✅ Séance "$deletedName" supprimée'
              : langCode == 'de'
                  ? '✅ Training "$deletedName" gelöscht'
                  : '✅ Workout "$deletedName" deleted';
          return {'success': true, 'message': msg};
        }

        // Vérifier si une séance existe mais est passée (completed/missed)
        final existingWorkout = await WeeklyPlannerService.findPlannedWorkoutByNameForDate(
          day,
          workoutName: workoutName,
          includeAllStatus: true,
        );
        if (existingWorkout != null) {
          final status = existingWorkout.status;
          final msg = langCode == 'fr'
              ? status == PlannedStatus.completed
                  ? '⚠️ Cette séance est déjà terminée et ne peut pas être supprimée. Consulte l\'historique pour voir tes séances passées.'
                  : '⚠️ Cette séance est passée et ne peut pas être modifiée. Consulte l\'historique pour voir tes séances passées.'
              : langCode == 'de'
                  ? status == PlannedStatus.completed
                      ? '⚠️ Dieses Training ist bereits abgeschlossen und kann nicht gelöscht werden.'
                      : '⚠️ Dieses Training ist vergangen und kann nicht geändert werden.'
                  : status == PlannedStatus.completed
                      ? '⚠️ This workout is already completed and cannot be deleted. Check your history for past workouts.'
                      : '⚠️ This workout is in the past and cannot be modified. Check your history for past workouts.';
          return {'success': false, 'message': msg};
        }

        return {'success': false, 'message': _getToolMessage(langCode, 'no_workout')};

      case 'delete_cardio':
        final day = _parseSingleDay(args['day'] as String? ?? '');
        if (day == null) return {'success': false, 'message': 'Invalid day'};
        final activityName = args['activity_name'] as String?;

        // Utiliser la méthode avec filtre par nom si fourni
        final cardio = await WeeklyPlannerService.findPlannedCardioByNameForDate(
          day,
          activityName: activityName,
        );
        if (cardio != null) {
          // Stocker le cardio complet pour undo
          _lastAction = {
            'type': 'delete_cardio',
            'deleted_cardio': cardio.toJson(),
          };
          await WeeklyPlannerService.deletePlannedActivity(cardio.id);
          final deletedName = cardio.cardioData?.activityName ?? 'Cardio';
          final msg = langCode == 'fr'
              ? '✅ Séance "$deletedName" supprimée'
              : langCode == 'de'
                  ? '✅ Cardio "$deletedName" gelöscht'
                  : '✅ Cardio "$deletedName" deleted';
          return {'success': true, 'message': msg};
        }

        // Vérifier si un cardio existe mais est passé (completed/missed)
        final existingCardio = await WeeklyPlannerService.findPlannedCardioByNameForDate(
          day,
          activityName: activityName,
          includeAllStatus: true,
        );
        if (existingCardio != null) {
          final status = existingCardio.status;
          final msg = langCode == 'fr'
              ? status == PlannedStatus.completed
                  ? '⚠️ Cette séance cardio est déjà terminée et ne peut pas être supprimée. Consulte l\'historique pour voir tes séances passées.'
                  : '⚠️ Cette séance cardio est passée et ne peut pas être modifiée. Consulte l\'historique pour voir tes séances passées.'
              : langCode == 'de'
                  ? status == PlannedStatus.completed
                      ? '⚠️ Dieses Cardio ist bereits abgeschlossen und kann nicht gelöscht werden.'
                      : '⚠️ Dieses Cardio ist vergangen und kann nicht geändert werden.'
                  : status == PlannedStatus.completed
                      ? '⚠️ This cardio session is already completed and cannot be deleted. Check your history for past sessions.'
                      : '⚠️ This cardio session is in the past and cannot be modified. Check your history for past sessions.';
          return {'success': false, 'message': msg};
        }

        return {'success': false, 'message': _getToolMessage(langCode, 'no_cardio')};

      case 'delete_day_sessions':
        // Supprimer toutes les séances (workout + cardio) d'un jour spécifique
        final day = _parseSingleDay(args['day'] as String? ?? '');
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Trouver tous les workouts et cardios de ce jour
        final allWorkoutsWeek = await WeeklyPlannerService.getAllWorkoutsThisWeek();
        final allCardiosWeek = await WeeklyPlannerService.getAllCardioThisWeek();

        // Filtrer par jour et statut "planned"
        final plannedWorkouts = allWorkoutsWeek.where((w) =>
          _isSameDay(w.plannedDate, day) && w.status == PlannedStatus.planned
        ).toList();
        final plannedCardios = allCardiosWeek.where((c) =>
          _isSameDay(c.plannedDate, day) && c.status == PlannedStatus.planned
        ).toList();

        if (plannedWorkouts.isEmpty && plannedCardios.isEmpty) {
          final dayName = _translateDayName(args['day'] as String? ?? '', langCode);
          final msg = langCode == 'fr'
              ? '⚠️ Aucune séance planifiée trouvée pour $dayName'
              : langCode == 'de'
                  ? '⚠️ Keine geplanten Einheiten für $dayName gefunden'
                  : '⚠️ No planned sessions found for $dayName';
          return {'success': false, 'message': msg};
        }

        // Stocker pour undo
        _lastAction = {
          'type': 'delete_day_sessions',
          'day': day.toIso8601String(),
          'deleted_workouts': plannedWorkouts.map((w) => w.toJson()).toList(),
          'deleted_cardios': plannedCardios.map((c) => c.toJson()).toList(),
        };

        // Supprimer toutes les séances
        for (final workout in plannedWorkouts) {
          await WeeklyPlannerService.deletePlannedWorkout(workout.id);
        }
        for (final cardio in plannedCardios) {
          await WeeklyPlannerService.deletePlannedActivity(cardio.id);
        }

        final dayName = _translateDayName(args['day'] as String? ?? '', langCode);
        final totalDeleted = plannedWorkouts.length + plannedCardios.length;
        final msg = langCode == 'fr'
            ? '✅ $totalDeleted séance${totalDeleted > 1 ? 's' : ''} supprimée${totalDeleted > 1 ? 's' : ''} pour $dayName (${plannedWorkouts.length} muscu, ${plannedCardios.length} cardio)'
            : langCode == 'de'
                ? '✅ $totalDeleted Einheit${totalDeleted > 1 ? 'en' : ''} für $dayName gelöscht (${plannedWorkouts.length} Kraft, ${plannedCardios.length} Cardio)'
                : '✅ $totalDeleted session${totalDeleted > 1 ? 's' : ''} deleted for $dayName (${plannedWorkouts.length} workout${plannedWorkouts.length > 1 ? 's' : ''}, ${plannedCardios.length} cardio)';
        return {'success': true, 'message': msg};

      case 'delete_sessions':
        // Tool flexible pour suppression multiple
        final daysArg = args['days'] as List<dynamic>?;
        final excludeDaysArg = args['exclude_days'] as List<dynamic>?;
        final sessionTypesArg = args['session_types'] as List<dynamic>?;
        final activityNamesArg = args['activity_names'] as List<dynamic>?;

        // Convertir les listes
        final days = daysArg?.map((d) => d.toString().toLowerCase()).toList() ?? [];
        final excludeDays = excludeDaysArg?.map((d) => d.toString().toLowerCase()).toList() ?? [];
        final sessionTypes = sessionTypesArg?.map((t) => t.toString().toLowerCase()).toList() ?? [];
        final activityNames = activityNamesArg?.map((n) => n.toString().toLowerCase()).toList() ?? [];

        // Déterminer les jours cibles
        final allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        List<String> targetDays;
        if (days.isEmpty) {
          // Tous les jours sauf les exclus
          targetDays = allDays.where((d) => !excludeDays.contains(d)).toList();
        } else {
          // Jours spécifiés sauf les exclus
          targetDays = days.where((d) => !excludeDays.contains(d)).toList();
        }

        // Déterminer les types à supprimer
        final deleteWorkouts = sessionTypes.isEmpty || sessionTypes.contains('workout');
        final deleteCardios = sessionTypes.isEmpty || sessionTypes.contains('cardio');

        // Récupérer toutes les séances de la semaine
        final allWeekWorkouts = await WeeklyPlannerService.getAllWorkoutsThisWeek();
        final allWeekCardios = await WeeklyPlannerService.getAllCardioThisWeek();

        // Collecter toutes les séances à supprimer
        List<PlannedWorkout> workoutsToDelete = [];
        List<PlannedActivity> cardiosToDelete = [];

        for (final dayStr in targetDays) {
          final dayDate = _parseSingleDay(dayStr);
          if (dayDate == null) continue;

          if (deleteWorkouts) {
            for (final w in allWeekWorkouts) {
              if (!_isSameDay(w.plannedDate, dayDate)) continue;
              if (w.status != PlannedStatus.planned) continue;
              // Filtrer par nom si spécifié
              if (activityNames.isNotEmpty) {
                final workoutName = w.workoutName.toLowerCase();
                if (!activityNames.any((name) => workoutName.contains(name))) continue;
              }
              // Éviter les doublons
              if (!workoutsToDelete.any((x) => x.id == w.id)) {
                workoutsToDelete.add(w);
              }
            }
          }

          if (deleteCardios) {
            for (final c in allWeekCardios) {
              if (!_isSameDay(c.plannedDate, dayDate)) continue;
              if (c.status != PlannedStatus.planned) continue;
              // Filtrer par nom si spécifié
              if (activityNames.isNotEmpty) {
                final cardioName = (c.cardioData?.activityName ?? '').toLowerCase();
                if (!activityNames.any((name) => cardioName.contains(name))) continue;
              }
              // Éviter les doublons
              if (!cardiosToDelete.any((x) => x.id == c.id)) {
                cardiosToDelete.add(c);
              }
            }
          }
        }

        if (workoutsToDelete.isEmpty && cardiosToDelete.isEmpty) {
          final msg = langCode == 'fr'
              ? '⚠️ Aucune séance trouvée correspondant aux critères'
              : langCode == 'de'
                  ? '⚠️ Keine passenden Einheiten gefunden'
                  : '⚠️ No sessions found matching the criteria';
          return {'success': false, 'message': msg};
        }

        // Stocker pour undo
        _lastAction = {
          'type': 'delete_sessions',
          'deleted_workouts': workoutsToDelete.map((w) => w.toJson()).toList(),
          'deleted_cardios': cardiosToDelete.map((c) => c.toJson()).toList(),
        };

        // Supprimer
        for (final w in workoutsToDelete) {
          await WeeklyPlannerService.deletePlannedWorkout(w.id);
        }
        for (final c in cardiosToDelete) {
          await WeeklyPlannerService.deletePlannedActivity(c.id);
        }

        final totalDeletedSessions = workoutsToDelete.length + cardiosToDelete.length;
        final msgFlex = langCode == 'fr'
            ? '✅ $totalDeletedSessions séance${totalDeletedSessions > 1 ? 's' : ''} supprimée${totalDeletedSessions > 1 ? 's' : ''} (${workoutsToDelete.length} muscu, ${cardiosToDelete.length} cardio)'
            : langCode == 'de'
                ? '✅ $totalDeletedSessions Einheit${totalDeletedSessions > 1 ? 'en' : ''} gelöscht (${workoutsToDelete.length} Kraft, ${cardiosToDelete.length} Cardio)'
                : '✅ $totalDeletedSessions session${totalDeletedSessions > 1 ? 's' : ''} deleted (${workoutsToDelete.length} workout${workoutsToDelete.length != 1 ? 's' : ''}, ${cardiosToDelete.length} cardio)';
        return {'success': true, 'message': msgFlex};

      case 'create_workout':
        final dayStr = args['day'] as String? ?? '';
        final workoutType = args['workout_type'] as String?;
        final duration = args['duration_minutes'] as int?;
        final focus = args['focus'] as String? ?? workoutType ?? '';

        final day = _parseSingleDay(dayStr);
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Vérifier que le type est fourni
        if (workoutType == null || workoutType.isEmpty) {
          final askMsg = langCode == 'fr'
              ? 'Quel type de séance veux-tu? (ex: Pecs, Dos, Jambes, Full Body, Push, Pull, Bras, Épaules...)'
              : langCode == 'de'
                  ? 'Welche Art von Training möchtest du? (z.B. Brust, Rücken, Beine, Ganzkörper, Push, Pull...)'
                  : 'What type of workout do you want? (e.g. Chest, Back, Legs, Full Body, Push, Pull...)';
          return {'success': true, 'message': askMsg, 'needs_clarification': true};
        }

        // Vérifier que la durée est fournie
        if (duration == null) {
          final askMsg = langCode == 'fr'
              ? 'Combien de temps pour ta séance $workoutType?'
              : langCode == 'de'
                  ? 'Wie lange soll dein $workoutType Training dauern?'
                  : 'How long for your $workoutType workout?';
          return {'success': true, 'message': askMsg, 'needs_clarification': true};
        }

        // Générer le workout avec l'IA (avec retry automatique en cas d'échec)
        const maxRetries = 2;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
          final result = await AIWorkoutGenerationService.generateWorkout(
            userRequest: '$workoutType workout, $focus',
            constraints: await _workoutConstraints(),
            durationMinutes: duration,
          );

          if (result.success && result.exercises.isNotEmpty) {
            final pendingWorkout = PendingWorkout(
              plannedDate: day,
              workoutName: '$workoutType - ${duration}min',
              workoutType: workoutType,
              durationMinutes: duration,
              workoutPrompt: focus,
              exercises: result.exercises,
            );
            return {
              'success': true,
              'message': 'Workout created for ${args['day']}',
              'pending_workout': pendingWorkout,
            };
          }

          // Si ce n'est pas la dernière tentative, attendre un peu avant de réessayer
          if (attempt < maxRetries) {
            debugPrint('⚠️ Workout generation attempt $attempt failed, retrying...');
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        // Toutes les tentatives ont échoué
        return {'success': false, 'message': _getMessage(langCode, 'workout_generation_failed')};

      case 'move_workout':
        final fromDay = _parseSingleDay(args['from_day'] as String? ?? '');
        final toDay = _parseSingleDay(args['to_day'] as String? ?? '');
        if (fromDay == null || toDay == null) {
          return {'success': false, 'message': 'Invalid days'};
        }
        final workout = await WeeklyPlannerService.findPlannedWorkoutForDate(fromDay);
        if (workout != null) {
          // Stocker pour undo
          _lastAction = {
            'type': 'move_workout',
            'workout_id': workout.id,
            'from_day': fromDay.toIso8601String(),
            'to_day': toDay.toIso8601String(),
          };
          await WeeklyPlannerService.movePlannedWorkout(workout.id, toDay);
          return {'success': true, 'message': _getToolMessage(langCode, 'moved')};
        }

        // Vérifier si une séance existe mais est passée
        final existingWorkoutMove = await WeeklyPlannerService.findPlannedWorkoutForDate(
          fromDay,
          includeAllStatus: true,
        );
        if (existingWorkoutMove != null) {
          final status = existingWorkoutMove.status;
          final msg = langCode == 'fr'
              ? status == PlannedStatus.completed
                  ? '⚠️ Cette séance est déjà terminée et ne peut pas être déplacée.'
                  : '⚠️ Cette séance est passée et ne peut pas être déplacée.'
              : langCode == 'de'
                  ? status == PlannedStatus.completed
                      ? '⚠️ Dieses Training ist bereits abgeschlossen und kann nicht verschoben werden.'
                      : '⚠️ Dieses Training ist vergangen und kann nicht verschoben werden.'
                  : status == PlannedStatus.completed
                      ? '⚠️ This workout is already completed and cannot be moved.'
                      : '⚠️ This workout is in the past and cannot be moved.';
          return {'success': false, 'message': msg};
        }

        return {'success': false, 'message': _getToolMessage(langCode, 'no_workout')};

      case 'move_cardio':
        final fromDayCardio = _parseSingleDay(args['from_day'] as String? ?? '');
        final toDayCardio = _parseSingleDay(args['to_day'] as String? ?? '');
        if (fromDayCardio == null || toDayCardio == null) {
          return {'success': false, 'message': 'Invalid days'};
        }
        final cardioToMove = await WeeklyPlannerService.findPlannedCardioForDate(fromDayCardio);
        if (cardioToMove != null) {
          // Stocker pour undo
          _lastAction = {
            'type': 'move_cardio',
            'cardio_id': cardioToMove.id,
            'from_day': fromDayCardio.toIso8601String(),
            'to_day': toDayCardio.toIso8601String(),
          };
          await WeeklyPlannerService.movePlannedCardio(cardioToMove.id, toDayCardio);
          final movedMsg = langCode == 'fr' ? '✅ Cardio déplacé'
              : langCode == 'de' ? '✅ Cardio verschoben'
              : '✅ Cardio moved';
          return {'success': true, 'message': movedMsg};
        }

        // Vérifier si un cardio existe mais est passé
        final existingCardioMove = await WeeklyPlannerService.findPlannedCardioForDate(
          fromDayCardio,
          includeAllStatus: true,
        );
        if (existingCardioMove != null) {
          final status = existingCardioMove.status;
          final msg = langCode == 'fr'
              ? status == PlannedStatus.completed
                  ? '⚠️ Cette séance cardio est déjà terminée et ne peut pas être déplacée.'
                  : '⚠️ Cette séance cardio est passée et ne peut pas être déplacée.'
              : langCode == 'de'
                  ? status == PlannedStatus.completed
                      ? '⚠️ Dieses Cardio ist bereits abgeschlossen und kann nicht verschoben werden.'
                      : '⚠️ Dieses Cardio ist vergangen und kann nicht verschoben werden.'
                  : status == PlannedStatus.completed
                      ? '⚠️ This cardio session is already completed and cannot be moved.'
                      : '⚠️ This cardio session is in the past and cannot be moved.';
          return {'success': false, 'message': msg};
        }

        return {'success': false, 'message': _getToolMessage(langCode, 'no_cardio')};

      case 'modify_workout':
        final currentDayStr = args['current_day'] as String?;
        final currentWorkoutName = args['current_workout_name'] as String?;
        final newType = args['new_workout_type'] as String?;
        final newDuration = args['new_duration_minutes'] as int?;
        final regenerate = args['regenerate_exercises'] as bool? ?? (newType != null);

        PlannedWorkout? existingWorkout;
        DateTime? currentDay;

        // Trouver le workout existant - par jour ou par nom
        if (currentDayStr != null && currentDayStr.isNotEmpty) {
          currentDay = _parseSingleDay(currentDayStr);
          if (currentDay != null) {
            existingWorkout = await WeeklyPlannerService.findPlannedWorkoutForDate(currentDay);
          }
        }

        // Si pas trouvé par jour, chercher par nom
        if (existingWorkout == null && currentWorkoutName != null && currentWorkoutName.isNotEmpty) {
          debugPrint('🔍 modify_workout: Searching by name "$currentWorkoutName"');
          // Chercher dans toute la semaine
          final weekStart = planningWindowStart;
          for (int i = 0; i < 7; i++) {
            final day = weekStart.add(Duration(days: i));
            final workout = await WeeklyPlannerService.findPlannedWorkoutByNameForDate(
              day,
              workoutName: currentWorkoutName,
            );
            if (workout != null) {
              existingWorkout = workout;
              currentDay = day;
              debugPrint('✅ Found workout "${workout.workoutName}" on day $i');
              break;
            }
          }
        }

        if (existingWorkout == null) {
          // Vérifier si une séance existe mais est passée (par jour)
          if (currentDay != null) {
            final pastWorkout = await WeeklyPlannerService.findPlannedWorkoutForDate(
              currentDay,
              includeAllStatus: true,
            );
            if (pastWorkout != null) {
              final status = pastWorkout.status;
              final msg = langCode == 'fr'
                  ? status == PlannedStatus.completed
                      ? '⚠️ Cette séance est déjà terminée et ne peut pas être modifiée.'
                      : '⚠️ Cette séance est passée et ne peut pas être modifiée.'
                  : langCode == 'de'
                      ? status == PlannedStatus.completed
                          ? '⚠️ Dieses Training ist bereits abgeschlossen und kann nicht geändert werden.'
                          : '⚠️ Dieses Training ist vergangen und kann nicht geändert werden.'
                      : status == PlannedStatus.completed
                          ? '⚠️ This workout is already completed and cannot be modified.'
                          : '⚠️ This workout is in the past and cannot be modified.';
              return {'success': false, 'message': msg};
            }
          }

          // Chercher séance passée par nom si spécifié
          if (currentWorkoutName != null && currentWorkoutName.isNotEmpty) {
            final weekStart = planningWindowStart;
            for (int i = 0; i < 7; i++) {
              final day = weekStart.add(Duration(days: i));
              final pastWorkout = await WeeklyPlannerService.findPlannedWorkoutByNameForDate(
                day,
                workoutName: currentWorkoutName,
                includeAllStatus: true,
              );
              if (pastWorkout != null && pastWorkout.status != PlannedStatus.planned) {
                final status = pastWorkout.status;
                final msg = langCode == 'fr'
                    ? status == PlannedStatus.completed
                        ? '⚠️ La séance "$currentWorkoutName" est déjà terminée et ne peut pas être modifiée.'
                        : '⚠️ La séance "$currentWorkoutName" est passée et ne peut pas être modifiée.'
                    : langCode == 'de'
                        ? status == PlannedStatus.completed
                            ? '⚠️ Das Training "$currentWorkoutName" ist bereits abgeschlossen.'
                            : '⚠️ Das Training "$currentWorkoutName" ist vergangen.'
                        : status == PlannedStatus.completed
                            ? '⚠️ Workout "$currentWorkoutName" is already completed and cannot be modified.'
                            : '⚠️ Workout "$currentWorkoutName" is in the past and cannot be modified.';
                return {'success': false, 'message': msg};
              }
            }
          }

          // Si pas de workout existant mais on a un type à créer et un jour valide, créer une nouvelle séance
          if (newType != null && currentDay != null && isDateEditable(currentDay)) {
            debugPrint('🔄 modify_workout: No existing workout, creating new one');
            final duration = newDuration ?? 45;
            final result = await AIWorkoutGenerationService.generateWorkout(
              userRequest: '$newType workout',
              constraints: await _workoutConstraints(),
              durationMinutes: duration,
            );

            if (result.success && result.exercises.isNotEmpty) {
              // Sauvegarder directement
              await WeeklyPlannerService.addPlannedWorkout(
                plannedDate: currentDay,
                workoutName: '$newType - ${duration}min',
                exercises: result.exercises,
                durationMinutes: duration,
                userPrompt: newType,
                isAiGenerated: true,
              );
              return {'success': true, 'message': _getToolMessage(langCode, 'workout_modified')};
            }
          }

          return {'success': false, 'message': _getToolMessage(langCode, 'no_workout_found')};
        }

        // On a trouvé une séance, on utilise son jour si pas déjà défini
        currentDay ??= existingWorkout.plannedDate;

        // CAS SPÉCIAL: Si on veut transformer en HIIT ou cardio, c'est une conversion de type
        if (newType != null) {
          final lowerType = newType.toLowerCase().trim();

          // Conversion vers HIIT (utiliser le service partagé pour la détection)
          if (PlannedCardioService.isHiitType(lowerType)) {
            debugPrint('🔄 modify_workout: Converting workout to HIIT (detected: $lowerType)');
            // Supprimer le workout existant
            await WeeklyPlannerService.deletePlannedWorkout(existingWorkout.id);
            // Rediriger vers create_hiit qui demandera les paramètres
            final dayStr = _getDayString(currentDay);
            return await _executeToolCall('create_hiit', {'day': dayStr}, langCode);
          }

          // Conversion vers cardio (détection large)
          final isCardio = lowerType.contains('cardio') ||
              lowerType.contains('running') || lowerType.contains('course') || lowerType.contains('courir') ||
              lowerType.contains('bike') || lowerType.contains('vélo') || lowerType.contains('velo') || lowerType.contains('cycling') ||
              lowerType.contains('walk') || lowerType.contains('marche') ||
              lowerType.contains('swim') || lowerType.contains('natation') || lowerType.contains('nager');

          if (isCardio) {
            debugPrint('🔄 modify_workout: Converting workout to cardio (detected: $lowerType)');
            // Déterminer le type de cardio
            final dayStr = _getDayString(currentDay);
            String? activityKey;
            if (lowerType.contains('bike') || lowerType.contains('vélo') || lowerType.contains('velo') || lowerType.contains('cycling')) {
              activityKey = 'bike';
            } else if (lowerType.contains('walk') || lowerType.contains('marche')) {
              activityKey = 'walking';
            } else if (lowerType.contains('run') || lowerType.contains('course') || lowerType.contains('courir') || lowerType.contains('cardio')) {
              activityKey = 'running';
            }

            // La natation, le rameur et compagnie sont détectés comme du cardio
            // mais l'application ne sait pas les planifier. La séance était
            // supprimée d'abord, puis la création échouait : l'utilisateur
            // perdait sa séance et recevait un message d'erreur.
            if (activityKey == null || PlannedCardioService.validateCardioType(activityKey) == null) {
              return {
                'success': false,
                'message': _unsupportedActivityMessage(lowerType, langCode),
              };
            }

            // La création d'abord, la suppression seulement si elle a réussi.
            final created = await _executeToolCall('create_cardio', {
              'day': dayStr,
              'activity': activityKey,
            }, langCode);

            if (created['success'] == true) {
              await WeeklyPlannerService.deletePlannedWorkout(existingWorkout.id);
            }
            return created;
          }
        }

        // Stocker pour undo
        _lastAction = {
          'type': 'modify_workout',
          'workout_id': existingWorkout.id,
          'original_name': existingWorkout.workoutName,
          'original_duration': existingWorkout.durationMinutes,
          'original_day': currentDay.toIso8601String(),
        };

        // Appliquer les modifications
        final newDay = args['new_day'] != null ? _parseSingleDay(args['new_day'] as String) : null;

        // Si changement de jour → move
        if (newDay != null && newDay != currentDay) {
          await WeeklyPlannerService.movePlannedWorkout(existingWorkout.id, newDay);
        }

        // Si changement de type → regénérer les exercices (uniquement pour les types muscu)
        if (newType != null && regenerate) {
          // Utiliser la durée existante si pas de nouvelle durée
          final duration = newDuration ?? existingWorkout.durationMinutes ?? 45;

          // Générer les nouveaux exercices avec l'IA
          final result = await AIWorkoutGenerationService.generateWorkout(
            userRequest: '$newType workout',
            constraints: await _workoutConstraints(),
            durationMinutes: duration,
          );

          if (result.success && result.exercises.isNotEmpty) {
            // Mettre à jour avec le nouveau type ET les nouveaux exercices
            await WeeklyPlannerService.updatePlannedWorkout(
              existingWorkout.id,
              workoutName: newType,
              durationMinutes: duration,
              exercises: result.exercises,
            );
          } else {
            // Fallback: mettre à jour seulement le nom si génération échoue
            await WeeklyPlannerService.updatePlannedWorkout(
              existingWorkout.id,
              workoutName: newType,
              durationMinutes: newDuration,
            );
          }
        } else if (newDuration != null) {
          // Seulement changement de durée, pas besoin de regénérer
          await WeeklyPlannerService.updatePlannedWorkout(
            existingWorkout.id,
            durationMinutes: newDuration,
          );
        }

        return {'success': true, 'message': _getToolMessage(langCode, 'workout_modified')};

      case 'modify_cardio':
        final currentDayCardio = _parseSingleDay(args['current_day'] as String? ?? '');
        if (currentDayCardio == null) {
          return {'success': false, 'message': 'Invalid day'};
        }

        // Trouver le cardio existant
        final existingCardio = await WeeklyPlannerService.findPlannedCardioForDate(currentDayCardio);
        if (existingCardio == null) {
          return {'success': false, 'message': _getToolMessage(langCode, 'no_cardio_found')};
        }

        final newActivity = args['new_activity'] as String?;

        // Utiliser le service partagé pour détecter si on change vers HIIT
        if (newActivity != null && PlannedCardioService.isHiitType(newActivity)) {
          final hiitType = args['hiit_type'] as String?;

          // Supprimer l'ancien cardio d'abord
          await WeeklyPlannerService.deletePlannedActivity(existingCardio.id);

          // Si on a le type HIIT, le passer à create_hiit
          if (hiitType != null && hiitType.isNotEmpty) {
            return await _executeToolCall('create_hiit', {
              'day': args['current_day'],
              'hiit_type': hiitType,
            }, langCode);
          }

          // Sinon, rediriger vers create_hiit qui va demander les paramètres
          return await _executeToolCall('create_hiit', {'day': args['current_day']}, langCode);
        }

        // Stocker pour undo
        _lastAction = {
          'type': 'modify_cardio',
          'cardio_id': existingCardio.id,
          'original_day': currentDayCardio.toIso8601String(),
          'original_data': existingCardio.toJson(),
        };

        // Appliquer les modifications
        final newDayCardio = args['new_day'] != null ? _parseSingleDay(args['new_day'] as String) : null;
        final newDurationCardio = args['new_duration_minutes'] as int?;
        final newTargetKm = args['new_target_km'] as num?;

        // Si changement de jour → move
        if (newDayCardio != null && newDayCardio != currentDayCardio) {
          await WeeklyPlannerService.movePlannedCardio(existingCardio.id, newDayCardio);
        }

        // Si changement d'autres paramètres → update cardio
        if (newActivity != null || newDurationCardio != null || newTargetKm != null) {
          await WeeklyPlannerService.updatePlannedCardio(
            existingCardio.id,
            activityType: newActivity,
            durationMinutes: newDurationCardio,
            targetKm: newTargetKm?.toDouble(),
          );
        }

        return {'success': true, 'message': _getToolMessage(langCode, 'cardio_modified')};

      case 'create_hiit':
        final dayStr = args['day'] as String? ?? '';
        final hiitType = args['hiit_type'] as String?;
        final workSeconds = args['work_seconds'] as int?;
        final restSeconds = args['rest_seconds'] as int?;
        final rounds = args['rounds'] as int?;

        final day = _parseSingleDay(dayStr);
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Si pas de type spécifié, proposer les options via le service
        if (hiitType == null || hiitType.isEmpty) {
          final askMsg = langCode == 'fr'
              ? 'Quel type de HIIT veux-tu?\n\n🔥 Tabata (4 min - 20s effort / 10s repos)\n💪 HIIT débutant (15 min - 30s/30s)\n🏋️ HIIT intense (20 min - 45s/15s)\n⚙️ Personnalisé (tu choisis les temps)\n\nDis-moi ton choix ou dis "propose" et je te conseille!'
              : langCode == 'de'
                  ? 'Welche Art von HIIT möchtest du?\n\n🔥 Tabata (4 Min - 20s Arbeit / 10s Pause)\n💪 HIIT Anfänger (15 Min - 30s/30s)\n🏋️ HIIT Intensiv (20 Min - 45s/15s)\n⚙️ Personalisiert (du wählst die Zeiten)'
                  : 'What type of HIIT do you want?\n\n🔥 Tabata (4 min - 20s work / 10s rest)\n💪 Beginner HIIT (15 min - 30s/30s)\n🏋️ Intense HIIT (20 min - 45s/15s)\n⚙️ Custom (you choose the times)';
          return {'success': true, 'message': askMsg, 'needs_clarification': true};
        }

        PlannedActivity? createdHiit;
        int finalWorkSeconds;
        int finalRestSeconds;
        int finalRounds;
        String hiitTitle;

        if (hiitType == 'custom') {
          // Config personnalisée - vérifier qu'on a tous les paramètres
          if (workSeconds == null || restSeconds == null || rounds == null) {
            final askMsg = langCode == 'fr'
                ? 'Pour ta séance personnalisée, dis-moi:\n• Temps d\'effort (en secondes, ex: 30, 40, 45)\n• Temps de repos (en secondes, ex: 10, 15, 20)\n• Nombre de rounds (ex: 8, 10, 12)'
                : langCode == 'de'
                    ? 'Für dein personalisiertes Training, sag mir:\n• Arbeitszeit (in Sekunden, z.B. 30, 40, 45)\n• Ruhezeit (in Sekunden, z.B. 10, 15, 20)\n• Anzahl Runden (z.B. 8, 10, 12)'
                    : 'For your custom session, tell me:\n• Work time (in seconds, e.g., 30, 40, 45)\n• Rest time (in seconds, e.g., 10, 15, 20)\n• Number of rounds (e.g., 8, 10, 12)';
            return {'success': true, 'message': askMsg, 'needs_clarification': true};
          }

          // Utiliser le service partagé pour créer le HIIT custom
          createdHiit = await PlannedCardioService.createCustomHiit(
            date: day,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            rounds: rounds,
          );
          finalWorkSeconds = workSeconds;
          finalRestSeconds = restSeconds;
          finalRounds = rounds;
          hiitTitle = langCode == 'fr' ? 'HIIT personnalisé' : langCode == 'de' ? 'Personalisiertes HIIT' : 'Custom HIIT';
        } else {
          // Utiliser le service partagé pour valider et créer le preset
          final preset = PlannedCardioService.validateHiitType(hiitType);
          if (preset == null) {
            return {'success': false, 'message': 'Unknown HIIT type: $hiitType'};
          }

          createdHiit = await PlannedCardioService.createPlannedHiit(
            date: day,
            preset: preset,
          );
          finalWorkSeconds = preset.workSeconds;
          finalRestSeconds = preset.restSeconds;
          finalRounds = preset.rounds;
          hiitTitle = preset.getLocalizedName(langCode);
        }

        if (createdHiit != null) {
          _lastAction = {
            'type': 'create_cardio',
            'created_cardio_id': createdHiit.id,
          };
        }

        // Message de succès
        final totalMinutes = ((finalWorkSeconds + finalRestSeconds) * finalRounds / 60).ceil();
        final dayName = _getDayName(day, langCode);
        final successMsg = langCode == 'fr'
            ? '✅ $hiitTitle programmé $dayName!\n⏱️ ${finalWorkSeconds}s effort / ${finalRestSeconds}s repos × $finalRounds rounds (~$totalMinutes min)'
            : langCode == 'de'
                ? '✅ $hiitTitle am $dayName geplant!\n⏱️ ${finalWorkSeconds}s Arbeit / ${finalRestSeconds}s Pause × $finalRounds Runden (~$totalMinutes Min)'
                : '✅ $hiitTitle scheduled for $dayName!\n⏱️ ${finalWorkSeconds}s work / ${finalRestSeconds}s rest × $finalRounds rounds (~$totalMinutes min)';

        return {'success': true, 'message': successMsg};

      case 'create_cardio':
        final dayStr = args['day'] as String? ?? '';
        final activityKey = args['activity'] as String? ?? 'running';
        final duration = args['duration_minutes'] as int?;
        final targetKm = args['target_km'] as num?;

        final day = _parseSingleDay(dayStr);
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Utiliser le service partagé pour détecter et rediriger HIIT
        if (PlannedCardioService.isHiitType(activityKey)) {
          return await _executeToolCall('create_hiit', {'day': dayStr}, langCode);
        }

        // Valider le type de cardio via le service partagé
        final validatedType = PlannedCardioService.validateCardioType(activityKey);
        if (validatedType == null) {
          return {'success': false, 'message': _unsupportedActivityMessage(activityKey, langCode)};
        }

        // Vérifier qu'au moins une valeur est fournie
        if (duration == null && targetKm == null) {
          final askMsg = langCode == 'fr'
              ? 'Combien de temps ou quelle distance veux-tu faire?'
              : langCode == 'de'
                  ? 'Wie lange oder welche Distanz möchtest du machen?'
                  : 'How long or what distance do you want to do?';
          return {'success': true, 'message': askMsg, 'needs_clarification': true};
        }

        // Retourner un pending_cardio pour le preview (comme pour les workouts)
        final activityDisplayName = _getCardioActivityName(validatedType, langCode);
        final pendingCardio = PendingCardio(
          plannedDate: day,
          activityName: activityDisplayName,
          activityKey: validatedType,
          distanceKm: targetKm?.toDouble(),
          durationMinutes: duration,
        );
        return {
          'success': true,
          'pending_cardio': pendingCardio,
        };

      case 'ask_clarification':
        return {'success': true, 'message': args['question'] as String? ?? ''};

      case 'undo_last_action':
        if (_lastAction == null) {
          final noUndoMsg = langCode == 'fr' ? '❌ Aucune action à annuler'
              : langCode == 'de' ? '❌ Keine Aktion zum Rückgängigmachen'
              : '❌ No action to undo';
          return {'success': false, 'message': noUndoMsg};
        }

        final actionType = _lastAction!['type'] as String;
        try {
          switch (actionType) {
            case 'delete_all':
              // Restaurer TOUT (workouts + cardio)
              final deletedWorkouts = _lastAction!['deleted_workouts'] as List<dynamic>? ?? [];
              final deletedCardios = _lastAction!['deleted_cardios'] as List<dynamic>? ?? [];
              for (final workoutJson in deletedWorkouts) {
                await WeeklyPlannerService.restorePlannedWorkout(workoutJson as Map<String, dynamic>);
              }
              for (final cardioJson in deletedCardios) {
                await WeeklyPlannerService.restorePlannedActivity(cardioJson as Map<String, dynamic>);
              }
              _lastAction = null;
              final totalRestored = deletedWorkouts.length + deletedCardios.length;
              final msg0 = langCode == 'fr' ? '✅ $totalRestored séance(s) restaurée(s)'
                  : langCode == 'de' ? '✅ $totalRestored Einheit(en) wiederhergestellt'
                  : '✅ $totalRestored session(s) restored';
              return {'success': true, 'message': msg0};

            case 'delete_all_workouts':
              // Restaurer tous les workouts supprimés
              final deletedWorkouts = _lastAction!['deleted_workouts'] as List<dynamic>? ?? [];
              for (final workoutJson in deletedWorkouts) {
                await WeeklyPlannerService.restorePlannedWorkout(workoutJson as Map<String, dynamic>);
              }
              _lastAction = null;
              final msg1 = langCode == 'fr' ? '✅ ${deletedWorkouts.length} séance(s) restaurée(s)'
                  : langCode == 'de' ? '✅ ${deletedWorkouts.length} Training(s) wiederhergestellt'
                  : '✅ ${deletedWorkouts.length} workout(s) restored';
              return {'success': true, 'message': msg1};

            case 'delete_all_cardio':
              // Restaurer tous les cardios supprimés
              final deletedCardios = _lastAction!['deleted_cardios'] as List<dynamic>? ?? [];
              for (final cardioJson in deletedCardios) {
                await WeeklyPlannerService.restorePlannedActivity(cardioJson as Map<String, dynamic>);
              }
              _lastAction = null;
              final msg2 = langCode == 'fr' ? '✅ ${deletedCardios.length} cardio(s) restauré(s)'
                  : langCode == 'de' ? '✅ ${deletedCardios.length} Cardio(s) wiederhergestellt'
                  : '✅ ${deletedCardios.length} cardio session(s) restored';
              return {'success': true, 'message': msg2};

            case 'delete_workout':
              // Restaurer le workout supprimé
              final workoutJson = _lastAction!['deleted_workout'] as Map<String, dynamic>;
              await WeeklyPlannerService.restorePlannedWorkout(workoutJson);
              _lastAction = null;
              final msg3 = langCode == 'fr' ? '✅ Séance restaurée'
                  : langCode == 'de' ? '✅ Training wiederhergestellt'
                  : '✅ Workout restored';
              return {'success': true, 'message': msg3};

            case 'delete_cardio':
              // Restaurer le cardio supprimé
              final cardioJson = _lastAction!['deleted_cardio'] as Map<String, dynamic>;
              await WeeklyPlannerService.restorePlannedActivity(cardioJson);
              _lastAction = null;
              final msg4 = langCode == 'fr' ? '✅ Cardio restauré'
                  : langCode == 'de' ? '✅ Cardio wiederhergestellt'
                  : '✅ Cardio restored';
              return {'success': true, 'message': msg4};

            case 'delete_day_sessions':
              // Restaurer toutes les séances supprimées pour ce jour
              final deletedWorkoutsDay = _lastAction!['deleted_workouts'] as List<dynamic>? ?? [];
              final deletedCardiosDay = _lastAction!['deleted_cardios'] as List<dynamic>? ?? [];
              for (final workoutJson in deletedWorkoutsDay) {
                await WeeklyPlannerService.restorePlannedWorkout(workoutJson as Map<String, dynamic>);
              }
              for (final cardioJson in deletedCardiosDay) {
                await WeeklyPlannerService.restorePlannedActivity(cardioJson as Map<String, dynamic>);
              }
              _lastAction = null;
              final totalRestoredDay = deletedWorkoutsDay.length + deletedCardiosDay.length;
              final msgDay = langCode == 'fr' ? '✅ $totalRestoredDay séance(s) restaurée(s)'
                  : langCode == 'de' ? '✅ $totalRestoredDay Einheit(en) wiederhergestellt'
                  : '✅ $totalRestoredDay session(s) restored';
              return {'success': true, 'message': msgDay};

            case 'delete_sessions':
              // Restaurer toutes les séances supprimées (flexible)
              final deletedWorkoutsFlex = _lastAction!['deleted_workouts'] as List<dynamic>? ?? [];
              final deletedCardiosFlex = _lastAction!['deleted_cardios'] as List<dynamic>? ?? [];
              for (final workoutJson in deletedWorkoutsFlex) {
                await WeeklyPlannerService.restorePlannedWorkout(workoutJson as Map<String, dynamic>);
              }
              for (final cardioJson in deletedCardiosFlex) {
                await WeeklyPlannerService.restorePlannedActivity(cardioJson as Map<String, dynamic>);
              }
              _lastAction = null;
              final totalRestoredFlex = deletedWorkoutsFlex.length + deletedCardiosFlex.length;
              final msgFlex = langCode == 'fr' ? '✅ $totalRestoredFlex séance(s) restaurée(s)'
                  : langCode == 'de' ? '✅ $totalRestoredFlex Einheit(en) wiederhergestellt'
                  : '✅ $totalRestoredFlex session(s) restored';
              return {'success': true, 'message': msgFlex};

            case 'create_cardio':
              // Supprimer le cardio créé
              final cardioId = _lastAction!['created_cardio_id'] as String;
              await WeeklyPlannerService.deletePlannedActivity(cardioId);
              _lastAction = null;
              final msg5 = langCode == 'fr' ? '✅ Cardio annulé'
                  : langCode == 'de' ? '✅ Cardio rückgängig gemacht'
                  : '✅ Cardio cancelled';
              return {'success': true, 'message': msg5};

            case 'move_workout':
              // Remettre le workout à sa place originale
              final workoutId = _lastAction!['workout_id'] as String;
              final fromDay = DateTime.parse(_lastAction!['from_day'] as String);
              await WeeklyPlannerService.movePlannedWorkout(workoutId, fromDay);
              _lastAction = null;
              final msg6 = langCode == 'fr' ? '✅ Déplacement annulé'
                  : langCode == 'de' ? '✅ Verschiebung rückgängig gemacht'
                  : '✅ Move cancelled';
              return {'success': true, 'message': msg6};

            case 'move_cardio':
              // Remettre le cardio à sa place originale
              final cardioId = _lastAction!['cardio_id'] as String;
              final fromDayCardio = DateTime.parse(_lastAction!['from_day'] as String);
              await WeeklyPlannerService.movePlannedCardio(cardioId, fromDayCardio);
              _lastAction = null;
              final msg7 = langCode == 'fr' ? '✅ Déplacement annulé'
                  : langCode == 'de' ? '✅ Verschiebung rückgängig gemacht'
                  : '✅ Move cancelled';
              return {'success': true, 'message': msg7};

            case 'modify_meal':
              // Restaurer l'ancien repas (supprimer le nouveau + recréer l'ancien)
              final oldMeal = _lastAction!['old_meal'] as Map<String, dynamic>?;
              final dayStr = _lastAction!['day'] as String;
              final mealTypeStr = _lastAction!['meal_type'] as String;

              // Supprimer le nouveau repas créé
              final date = _parseSingleDay(dayStr);
              final mealType = _parseMealType(mealTypeStr);
              if (date != null) {
                final startOfDay = DateTime(date.year, date.month, date.day);
                final endOfDay = startOfDay.add(const Duration(days: 1));
                await Supabase.instance.client
                    .from('planned_activities')
                    .delete()
                    .eq('user_id', AuthService().currentUser!.id)
                    .eq('activity_type', mealType.value)
                    .gte('planned_date', startOfDay.toIso8601String().split('T')[0])
                    .lt('planned_date', endOfDay.toIso8601String().split('T')[0]);
              }

              // Restaurer l'ancien repas si existant
              if (oldMeal != null) {
                await Supabase.instance.client
                    .from('planned_activities')
                    .insert(oldMeal);
              }

              _lastAction = null;
              final msg8 = langCode == 'fr' ? '✅ Modification annulée'
                  : langCode == 'de' ? '✅ Änderung rückgängig gemacht'
                  : '✅ Modification cancelled';
              return {'success': true, 'message': msg8};

            default:
              final unknownMsg = langCode == 'fr' ? '❌ Action non annulable'
                  : langCode == 'de' ? '❌ Aktion nicht rückgängig zu machen'
                  : '❌ Cannot undo this action';
              return {'success': false, 'message': unknownMsg};
          }
        } catch (e) {
          debugPrint('❌ Undo error: $e');
          final errorMsg = langCode == 'fr' ? '❌ Erreur lors de l\'annulation'
              : langCode == 'de' ? '❌ Fehler beim Rückgängigmachen'
              : '❌ Error undoing action';
          return {'success': false, 'message': errorMsg};
        }

      // ==================== MEAL TOOLS ====================
      case 'create_meal':
        return await _executeCreateMeal(args, langCode);

      case 'delete_meal':
        return await _executeDeleteMeal(args, langCode);

      case 'modify_meal':
        return await _executeModifyMeal(args, langCode);

      case 'delete_all_meals':
        return await _executeDeleteAllMeals(langCode);

      default:
        return {'success': false, 'message': 'Unknown function: $functionName'};
    }
  }

  /// Créer un repas planifié
  static Future<Map<String, dynamic>> _executeCreateMeal(
    Map<String, dynamic> args,
    String langCode,
  ) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final dayStr = args['day'] as String? ?? '';
      final mealTypeStr = args['meal_type'] as String? ?? 'lunch';
      final dishName = args['dish_name'] as String? ?? 'Plat';
      final dishDescription = args['dish_description'] as String? ?? '';
      final proteins = (args['proteins'] as num?)?.toDouble() ?? 25.0;
      final carbs = (args['carbs'] as num?)?.toDouble() ?? 40.0;
      final fats = (args['fats'] as num?)?.toDouble() ?? 15.0;
      final quantityG = (args['quantity_g'] as num?)?.toDouble() ?? 300.0;
      // IMPORTANT: Calculer les calories avec la formule au lieu de prendre la valeur IA
      // Formule standard: protéines × 4 + glucides × 4 + lipides × 9
      final calories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

      // Parser le jour
      final date = _parseSingleDay(dayStr);
      if (date == null) {
        return {'success': false, 'message': 'Invalid day: $dayStr'};
      }

      // Vérifier que le jour n'est pas dans le passé
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      if (targetDate.isBefore(todayDate)) {
        final langCode = LocalizationService.instance.currentLanguageCode;
        final msg = langCode == 'fr'
            ? '⚠️ Impossible de planifier pour $dayStr (jour passé). Je ne peux planifier que pour aujourd\'hui et les jours futurs.'
            : langCode == 'de'
                ? '⚠️ Kann nicht für $dayStr planen (vergangener Tag). Ich kann nur für heute und zukünftige Tage planen.'
                : '⚠️ Cannot plan for $dayStr (past day). I can only plan for today and future days.';
        return {'success': false, 'message': msg, 'is_past_day': true};
      }

      // L'utilisateur peut planifier n'importe quel type de repas à n'importe quelle heure
      // (on ne bloque plus selon l'heure - c'est trop restrictif)

      // Convertir le type de repas
      final mealType = _parseMealType(mealTypeStr);

      // Créer un PendingMeal pour le mode preview (ne pas insérer directement)
      final pendingMeal = PendingMeal(
        plannedDate: date,
        mealType: mealType,
        dishName: dishName,
        dishDescription: dishDescription,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        estimatedQuantityG: quantityG,
      );

      return {
        'success': true,
        'pending_meal': pendingMeal,
      };
    } catch (e) {
      debugPrint('❌ Create meal error: $e');
      return {'success': false, 'message': 'Error creating meal: $e'};
    }
  }

  /// One short line: the card underneath already lists every dish, its
  /// calories and its macros, so repeating them in words says it twice.
  static String _getMealsPreviewMessage(String langCode, List<PendingMeal> meals) {
    final days = <DateTime>{
      for (final meal in meals) DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day),
    }.toList()
      ..sort();
    if (days.length == 1) {
      return 'planner_meals_preview_one'.tr(langCode).replaceAll('{day}', _formatDayName(days.first, langCode).toLowerCase());
    }
    return 'planner_meals_preview_many'.tr(langCode).replaceAll('{n}', '${days.length}');
  }

  /// Supprimer un repas planifié
  static Future<Map<String, dynamic>> _executeDeleteMeal(
    Map<String, dynamic> args,
    String langCode,
  ) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final dayStr = args['day'] as String? ?? '';
      final mealTypeStr = args['meal_type'] as String? ?? '';

      final date = _parseSingleDay(dayStr);
      if (date == null) {
        return {'success': false, 'message': 'Invalid day'};
      }

      final mealType = _parseMealType(mealTypeStr);

      // Trouver et supprimer le repas
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await Supabase.instance.client
          .from('planned_activities')
          .delete()
          .eq('user_id', user.id)
          .eq('activity_type', mealType.value)
          .gte('planned_date', startOfDay.toIso8601String().split('T')[0])
          .lt('planned_date', endOfDay.toIso8601String().split('T')[0])
          .select();

      if (result.isEmpty) {
        final msg = langCode == 'fr'
            ? '⚠️ Aucun repas trouvé pour ce jour'
            : langCode == 'de'
                ? '⚠️ Keine Mahlzeit für diesen Tag gefunden'
                : '⚠️ No meal found for this day';
        return {'success': false, 'message': msg};
      }

      final dayName = _formatDayName(date, langCode);
      final mealName = _getMealTypeName(mealType, langCode);

      final msg = langCode == 'fr'
          ? '✅ $mealName de $dayName supprimé'
          : langCode == 'de'
              ? '✅ $mealName am $dayName gelöscht'
              : '✅ $mealName on $dayName deleted';

      return {'success': true, 'message': msg};
    } catch (e) {
      debugPrint('❌ Delete meal error: $e');
      return {'success': false, 'message': 'Error deleting meal: $e'};
    }
  }

  /// Modifier un repas planifié existant (supprimer l'ancien + créer le nouveau)
  static Future<Map<String, dynamic>> _executeModifyMeal(
    Map<String, dynamic> args,
    String langCode,
  ) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final dayStr = args['day'] as String? ?? '';
      final mealTypeStr = args['meal_type'] as String? ?? '';
      final newDishName = args['dish_name'] as String? ?? 'Plat';
      final newDishDescription = args['dish_description'] as String? ?? '';
      final newProteins = (args['proteins'] as num?)?.toDouble() ?? 25.0;
      final newCarbs = (args['carbs'] as num?)?.toDouble() ?? 40.0;
      final newFats = (args['fats'] as num?)?.toDouble() ?? 15.0;
      final quantityG = (args['quantity_g'] as num?)?.toDouble() ?? 300.0;
      // IMPORTANT: Calculer les calories avec la formule au lieu de prendre la valeur IA
      // Formule standard: protéines × 4 + glucides × 4 + lipides × 9
      final newCalories = ((newProteins * 4) + (newCarbs * 4) + (newFats * 9)).round();

      final date = _parseSingleDay(dayStr);
      if (date == null) {
        final msg = langCode == 'fr'
            ? '⚠️ Jour invalide: $dayStr'
            : langCode == 'de'
                ? '⚠️ Ungültiger Tag: $dayStr'
                : '⚠️ Invalid day: $dayStr';
        return {'success': false, 'message': msg};
      }

      final mealType = _parseMealType(mealTypeStr);

      // D'abord, trouver et supprimer l'ancien repas
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Récupérer l'ancien repas pour le stocker dans _lastAction (pour undo)
      //
      // Le prompt encourage plusieurs entrées du même type le même jour (deux
      // collations, par exemple). `.maybeSingle()` lève alors une exception,
      // rendue à l'utilisateur en anglais brut. On prend donc le plus récent,
      // ou celui dont le nom correspond quand le modèle l'a précisé.
      final currentDishName = args['current_dish_name'] as String?;
      var oldMealQuery = Supabase.instance.client
          .from('planned_activities')
          .select()
          .eq('user_id', user.id)
          .eq('activity_type', mealType.value)
          .gte('planned_date', startOfDay.toIso8601String().split('T')[0])
          .lt('planned_date', endOfDay.toIso8601String().split('T')[0]);

      if (currentDishName != null && currentDishName.trim().isNotEmpty) {
        oldMealQuery = oldMealQuery.ilike('activity_data->>dish_name', '%${currentDishName.trim()}%');
      }

      final oldMealResult = await oldMealQuery
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Stocker l'ancien repas pour undo (si trouvé)
      if (oldMealResult != null) {
        _lastAction = {
          'type': 'modify_meal',
          'old_meal': oldMealResult,
          'day': dayStr,
          'meal_type': mealTypeStr,
        };

        // Supprimer l'ancien repas
        await Supabase.instance.client
            .from('planned_activities')
            .delete()
            .eq('id', oldMealResult['id']);
      }

      // Créer le nouveau repas
      final activityData = {
        'dish_name': newDishName,
        'dish_description': newDishDescription,
        'calories': newCalories,
        'proteins': newProteins,
        'carbs': newCarbs,
        'fats': newFats,
        'estimated_quantity_g': quantityG,
      };

      await Supabase.instance.client.from('planned_activities').insert({
        'user_id': user.id,
        'planned_date': startOfDay.toIso8601String().split('T')[0],
        'activity_type': mealType.value,
        'activity_data': activityData,
        'status': 'planned',
        'is_ai_generated': true,
      });

      final dayName = _formatDayName(date, langCode);
      final mealName = _getMealTypeName(mealType, langCode);

      // Calculer calories avec formule + utiliser traductions
      final calcCalories = ((newProteins * 4) + (newCarbs * 4) + (newFats * 9)).round();
      final macroLine = '~$calcCalories kcal | ${'proteins'.tr(langCode)[0]}: ${newProteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${newCarbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${newFats.toInt()}g';
      final msg = langCode == 'fr'
          ? '✅ $mealName de $dayName modifié: **$newDishName**\n$macroLine'
          : langCode == 'de'
              ? '✅ $mealName am $dayName geändert: **$newDishName**\n$macroLine'
              : '✅ $mealName on $dayName modified: **$newDishName**\n$macroLine';

      return {'success': true, 'message': msg};
    } catch (e) {
      debugPrint('❌ Modify meal error: $e');
      return {'success': false, 'message': 'Error modifying meal: $e'};
    }
  }

  /// Supprimer tous les repas planifiés de la semaine
  static Future<Map<String, dynamic>> _executeDeleteAllMeals(String langCode) async {
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // La fenêtre affichée à l'écran, comme partout ailleurs dans le service.
      // Ce calcul repartait de la date du jour : pendant la démo de
      // l'onboarding, qui plante sa fenêtre ailleurs, « supprime tous mes
      // repas » visait une autre semaine que celle sous les yeux.
      final normalizedStart = planningWindowStart;
      final weekEnd = normalizedStart.add(const Duration(days: 7));

      // Supprimer tous les repas de la semaine (breakfast, lunch, dinner, snack)
      final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

      for (final mealType in mealTypes) {
        await Supabase.instance.client
            .from('planned_activities')
            .delete()
            .eq('user_id', user.id)
            .eq('activity_type', mealType)
            .gte('planned_date', normalizedStart.toIso8601String().split('T')[0])
            .lt('planned_date', weekEnd.toIso8601String().split('T')[0]);
      }

      final msg = langCode == 'fr'
          ? '✅ Tous les repas de la semaine ont été supprimés'
          : langCode == 'de'
              ? '✅ Alle Mahlzeiten dieser Woche wurden gelöscht'
              : '✅ All meals for this week have been deleted';

      return {'success': true, 'message': msg};
    } catch (e) {
      debugPrint('❌ Delete all meals error: $e');
      return {'success': false, 'message': 'Error deleting meals: $e'};
    }
  }

  /// Obtenir le nom du type de repas dans la langue de l'utilisateur
  static String _getMealTypeName(PlannedActivityType type, String langCode) {
    switch (type) {
      case PlannedActivityType.breakfast:
        return langCode == 'fr' ? 'Petit-déjeuner' : langCode == 'de' ? 'Frühstück' : 'Breakfast';
      case PlannedActivityType.lunch:
        return langCode == 'fr' ? 'Déjeuner' : langCode == 'de' ? 'Mittagessen' : 'Lunch';
      case PlannedActivityType.dinner:
        return langCode == 'fr' ? 'Dîner' : langCode == 'de' ? 'Abendessen' : 'Dinner';
      case PlannedActivityType.snack:
        return langCode == 'fr' ? 'Collation' : langCode == 'de' ? 'Snack' : 'Snack';
      default:
        return langCode == 'fr' ? 'Repas' : langCode == 'de' ? 'Mahlzeit' : 'Meal';
    }
  }

  /// Message de confirmation pour les actions destructrices
  static String _getActionConfirmMessage(String langCode, String description) {
    // S'assurer que le mot "supprimer"/"delete" est dans la description
    final descLower = description.toLowerCase();
    final hasDeleteWord = descLower.contains('supprimer') ||
                          descLower.contains('delete') ||
                          descLower.contains('löschen') ||
                          descLower.contains('effacer') ||
                          descLower.contains('enlever') ||
                          descLower.contains('retirer');

    // Si pas de mot de suppression, on le rajoute
    String finalDesc = description;
    if (!hasDeleteWord) {
      finalDesc = langCode == 'fr'
          ? 'supprimer $description'
          : langCode == 'de'
              ? '$description löschen'
              : 'delete $description';
    }

    final templates = {
      'fr': '⚠️ Je vais $finalDesc\n\nConfirmes-tu ? (oui/non)',
      'en': '⚠️ I will $finalDesc\n\nDo you confirm? (yes/no)',
      'de': '⚠️ Ich werde $finalDesc\n\nBestätigst du? (ja/nein)',
    };
    return templates[langCode] ?? templates['en']!;
  }

  /// Vérifier si l'utilisateur confirme
  static bool _isConfirmation(String message) {
    final lower = message.toLowerCase().trim();
    return lower == 'oui' || lower == 'yes' || lower == 'ja' ||
           lower == 'ok' || lower == 'confirme' || lower == 'confirm' ||
           lower == 'go' || lower == 'd\'accord' || lower == 'valide';
  }

  /// Vérifier si l'utilisateur annule
  static bool _isCancellation(String message) {
    final lower = message.toLowerCase().trim();
    return lower == 'non' || lower == 'no' || lower == 'nein' ||
           lower == 'annule' || lower == 'cancel' || lower == 'stop';
  }

  /// Détecter si un message est une question qui attend une réponse
  static bool _isQuestionMessage(String message) {
    final lower = message.toLowerCase();
    // Détecter les questions par les mots-clés typiques
    return lower.contains('quel type') ||
           lower.contains('what type') ||
           lower.contains('welche art') ||
           lower.contains('combien de temps') ||
           lower.contains('how long') ||
           lower.contains('wie lange') ||
           lower.contains('quelle distance') ||
           lower.contains('what distance') ||
           lower.contains('dis-moi') ||
           lower.contains('tell me') ||
           lower.contains('veux-tu') ||
           lower.contains('do you want') ||
           lower.contains('möchtest du') ||
           lower.contains('pour ta séance') ||
           lower.contains('for your session') ||
           lower.contains('für dein') ||
           // Patterns de questions
           message.contains('?') && (
             lower.contains('hiit') ||
             lower.contains('tabata') ||
             lower.contains('cardio') ||
             lower.contains('temps') ||
             lower.contains('durée') ||
             lower.contains('duration')
           );
  }

  /// Exécuter l'action en attente après confirmation
  static Future<PlannerActionResult> executePendingAction() async {
    if (_pendingAction == null) {
      return PlannerActionResult.error('Pas d\'action en attente');
    }

    final langCode = LocalizationService.instance.currentLanguageCode;
    final actionType = _pendingAction!['action_type'] as String;
    // Convert _Map<dynamic, dynamic> to Map<String, dynamic>
    final rawArgs = _pendingAction!['action_args'];
    final Map<String, dynamic> actionArgs = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : {};

    _pendingAction = null; // Clear pending action

    final result = await _executeToolCall(actionType, actionArgs, langCode);
    final List<String> allMessages = [result['message'] as String];

    // Si l'action confirmée est une suppression, exécuter aussi les follow-ups de suppression
    // sans redemander confirmation (l'utilisateur a déjà confirmé)
    final isDeleteAction = actionType.startsWith('delete_');

    // Vérifier s'il y a des actions de suivi
    while (_pendingFollowUpActions != null && _pendingFollowUpActions!.isNotEmpty) {
      debugPrint('📋 ${_pendingFollowUpActions!.length} follow-up actions remaining');

      // Prendre la prochaine action
      final nextAction = _pendingFollowUpActions!.removeAt(0);
      final nextName = nextAction['name'] as String;
      final nextRawArgs = nextAction['args'];
      final Map<String, dynamic> nextArgs = nextRawArgs is Map
          ? Map<String, dynamic>.from(nextRawArgs)
          : {};

      debugPrint('🔧 Next action: $nextName with args: $nextArgs');

      // Cas spécial: si le follow-up est request_confirmation, extraire l'action réelle
      if (nextName == 'request_confirmation') {
        final realActionType = nextArgs['action_type'] as String?;
        final realActionArgsRaw = nextArgs['action_args'];
        final Map<String, dynamic> realActionArgs = realActionArgsRaw is Map
            ? Map<String, dynamic>.from(realActionArgsRaw)
            : {};
        final description = nextArgs['action_description'] as String? ?? '';

        if (realActionType != null) {
          // Si c'est aussi une suppression et qu'on vient d'exécuter une suppression,
          // exécuter directement sans redemander
          if (isDeleteAction && realActionType.startsWith('delete_')) {
            debugPrint('✅ Auto-executing follow-up delete action: $realActionType');
            final followResult = await _executeToolCall(realActionType, realActionArgs, langCode);
            allMessages.add(followResult['message'] as String);
            continue; // Continuer avec les suivantes
          }

          // Sinon, préparer l'action réelle comme pending
          _pendingAction = {
            'action_type': realActionType,
            'action_args': realActionArgs,
          };

          // Construire le message de confirmation
          final confirmMessage = '⚠️ Je vais: $description';

          // Vider les follow-ups s'il n'y en a plus
          if (_pendingFollowUpActions!.isEmpty) {
            _pendingFollowUpActions = null;
          }

          return PlannerActionResult(
            success: true,
            message: allMessages.join('\n'),
            canUndo: _lastAction != null,
            hasMoreActions: true,
            requiresConfirmation: true,
            nextActionDescription: confirmMessage,
          );
        }
      }

      // Si c'est une suppression et qu'on vient d'exécuter une suppression, exécuter directement
      if (isDeleteAction && nextName.startsWith('delete_')) {
        debugPrint('✅ Auto-executing follow-up delete action: $nextName');
        final nextResult = await _executeToolCall(nextName, nextArgs, langCode);
        allMessages.add(nextResult['message'] as String);
        continue; // Continuer avec les suivantes
      }

      // Vérifier si l'action suivante nécessite une confirmation
      if (_actionRequiresConfirmation(nextName, nextArgs)) {
        // Préparer l'action comme pending
        final confirmMessage = _buildConfirmationMessage(nextName, nextArgs, langCode);
        _pendingAction = {
          'action_type': nextName,
          'action_args': nextArgs,
        };

        // Vider les follow-ups s'il n'y en a plus
        if (_pendingFollowUpActions!.isEmpty) {
          _pendingFollowUpActions = null;
        }

        return PlannerActionResult(
          success: true,
          message: allMessages.join('\n'),
          canUndo: _lastAction != null,
          hasMoreActions: true,
          requiresConfirmation: true,
          nextActionDescription: confirmMessage,
        );
      } else {
        // Exécuter directement et continuer avec les suivantes
        final nextResult = await _executeToolCall(nextName, nextArgs, langCode);
        allMessages.add(nextResult['message'] as String);
        // Continuer la boucle while pour traiter les suivantes
      }
    }

    // Plus d'actions de suivi
    _pendingFollowUpActions = null;
    final combinedMessage = allMessages.join('\n');

    if (result['success'] == true) {
      return PlannerActionResult(
        success: true,
        message: combinedMessage,
        canUndo: _lastAction != null,
      );
    }
    return PlannerActionResult.error(combinedMessage);
  }

  /// Vérifie si une action nécessite une confirmation
  static bool _actionRequiresConfirmation(String actionName, Map<String, dynamic> args) {
    // Actions qui nécessitent toujours une confirmation
    if (actionName == 'delete_all' || actionName == 'delete_all_workouts' || actionName == 'delete_all_cardio' || actionName == 'delete_day_sessions' || actionName == 'delete_sessions') {
      return true;
    }
    // Suppression individuelle avec un jour spécifique
    if (actionName == 'delete_workout' || actionName == 'delete_cardio') {
      return true;
    }
    return false;
  }

  /// Construit le message de confirmation pour une action
  static String _buildConfirmationMessage(String actionName, Map<String, dynamic> args, String langCode) {
    final dayArg = args['day'] as String?;
    String dayName = '';
    if (dayArg != null) {
      dayName = _translateDayName(dayArg, langCode);
    }

    switch (actionName) {
      case 'delete_all':
        final msgs = {
          'fr': '⚠️ Je vais supprimer TOUTES les séances de la semaine (musculation + cardio). Confirmer ?',
          'en': '⚠️ I will delete ALL sessions for the week (workouts + cardio). Confirm?',
          'de': '⚠️ Ich werde ALLE Einheiten der Woche löschen (Krafttraining + Cardio). Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_all_workouts':
        final msgs = {
          'fr': '⚠️ Je vais supprimer toutes les séances de musculation de la semaine. Confirmer ?',
          'en': '⚠️ I will delete all strength workouts for the week. Confirm?',
          'de': '⚠️ Ich werde alle Krafttrainings der Woche löschen. Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_all_cardio':
        final msgs = {
          'fr': '⚠️ Je vais supprimer toutes les séances de cardio de la semaine. Confirmer ?',
          'en': '⚠️ I will delete all cardio sessions for the week. Confirm?',
          'de': '⚠️ Ich werde alle Cardio-Einheiten der Woche löschen. Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_workout':
        final msgs = {
          'fr': '⚠️ Je vais supprimer la séance de musculation du $dayName. Confirmer ?',
          'en': '⚠️ I will delete the strength workout on $dayName. Confirm?',
          'de': '⚠️ Ich werde das Krafttraining am $dayName löschen. Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_cardio':
        final msgs = {
          'fr': '⚠️ Je vais supprimer la séance de cardio du $dayName. Confirmer ?',
          'en': '⚠️ I will delete the cardio session on $dayName. Confirm?',
          'de': '⚠️ Ich werde die Cardio-Einheit am $dayName löschen. Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_day_sessions':
        final msgs = {
          'fr': '⚠️ Je vais supprimer TOUTES les séances (musculation + cardio) du $dayName. Confirmer ?',
          'en': '⚠️ I will delete ALL sessions (workouts + cardio) on $dayName. Confirm?',
          'de': '⚠️ Ich werde ALLE Einheiten (Krafttraining + Cardio) am $dayName löschen. Bestätigen?',
        };
        return msgs[langCode] ?? msgs['en']!;
      case 'delete_sessions':
        // Construire un message descriptif basé sur les args
        final daysArg = args['days'] as List<dynamic>?;
        final excludeDaysArg = args['exclude_days'] as List<dynamic>?;
        final sessionTypesArg = args['session_types'] as List<dynamic>?;
        final activityNamesArg = args['activity_names'] as List<dynamic>?;

        String daysDesc = '';
        if (daysArg != null && daysArg.isNotEmpty) {
          final translatedDays = daysArg.map((d) => _translateDayName(d.toString(), langCode)).toList();
          daysDesc = translatedDays.join(', ');
        } else if (excludeDaysArg != null && excludeDaysArg.isNotEmpty) {
          final excludedDays = excludeDaysArg.map((d) => _translateDayName(d.toString(), langCode)).toList();
          daysDesc = langCode == 'fr'
              ? 'tous les jours sauf ${excludedDays.join(", ")}'
              : langCode == 'de'
                  ? 'alle Tage außer ${excludedDays.join(", ")}'
                  : 'all days except ${excludedDays.join(", ")}';
        } else {
          daysDesc = langCode == 'fr' ? 'toute la semaine' : langCode == 'de' ? 'die ganze Woche' : 'the whole week';
        }

        String typesDesc = '';
        if (sessionTypesArg != null && sessionTypesArg.isNotEmpty) {
          final types = sessionTypesArg.map((t) {
            final type = t.toString().toLowerCase();
            if (type == 'workout') return langCode == 'fr' ? 'musculation' : langCode == 'de' ? 'Krafttraining' : 'workouts';
            if (type == 'cardio') return 'cardio';
            return type;
          }).toList();
          typesDesc = types.join(' + ');
        } else {
          typesDesc = langCode == 'fr' ? 'musculation + cardio' : langCode == 'de' ? 'Krafttraining + Cardio' : 'workouts + cardio';
        }

        String activityDesc = '';
        if (activityNamesArg != null && activityNamesArg.isNotEmpty) {
          activityDesc = langCode == 'fr'
              ? ' (${activityNamesArg.join(", ")})'
              : ' (${activityNamesArg.join(", ")})';
        }

        final msgsDelete = {
          'fr': '⚠️ Je vais supprimer $typesDesc$activityDesc pour $daysDesc. Confirmer ?',
          'en': '⚠️ I will delete $typesDesc$activityDesc for $daysDesc. Confirm?',
          'de': '⚠️ Ich werde $typesDesc$activityDesc für $daysDesc löschen. Bestätigen?',
        };
        return msgsDelete[langCode] ?? msgsDelete['en']!;
      default:
        return '⚠️ Confirmer cette action ?';
    }
  }


  /// Vérifie si deux dates sont le même jour
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Traduit le nom du jour en fonction de la langue
  static String _translateDayName(String dayKey, String langCode) {
    final dayNames = {
      'monday': {'fr': 'lundi', 'en': 'Monday', 'de': 'Montag'},
      'tuesday': {'fr': 'mardi', 'en': 'Tuesday', 'de': 'Dienstag'},
      'wednesday': {'fr': 'mercredi', 'en': 'Wednesday', 'de': 'Mittwoch'},
      'thursday': {'fr': 'jeudi', 'en': 'Thursday', 'de': 'Donnerstag'},
      'friday': {'fr': 'vendredi', 'en': 'Friday', 'de': 'Freitag'},
      'saturday': {'fr': 'samedi', 'en': 'Saturday', 'de': 'Samstag'},
      'sunday': {'fr': 'dimanche', 'en': 'Sunday', 'de': 'Sonntag'},
    };
    return dayNames[dayKey.toLowerCase()]?[langCode] ??
           dayNames[dayKey.toLowerCase()]?['en'] ??
           dayKey;
  }

  /// Annuler l'action en attente
  static void cancelPendingAction() {
    _pendingAction = null;
    _pendingFollowUpActions = null; // Clear follow-up actions too
  }

  /// Vérifier s'il y a une action en attente
  static bool get hasPendingAction => _pendingAction != null;

  /// Annuler la dernière action (undo)
  static Future<PlannerActionResult> undoLastAction() async {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final result = await _executeToolCall('undo_last_action', {}, langCode);

    if (result['success'] == true) {
      return PlannerActionResult.success(result['message'] as String);
    }
    return PlannerActionResult.error(result['message'] as String);
  }

  /// Messages pour les tools
  static String _getToolMessage(String langCode, String key) {
    final messages = {
      'all_deleted': {
        'fr': '✅ Toutes les séances ont été supprimées (musculation + cardio)',
        'en': '✅ All sessions have been deleted (workouts + cardio)',
        'de': '✅ Alle Einheiten wurden gelöscht (Krafttraining + Cardio)',
      },
      'all_workouts_deleted': {
        'fr': '✅ Toutes les séances de musculation ont été supprimées',
        'en': '✅ All strength workouts have been deleted',
        'de': '✅ Alle Krafttrainings wurden gelöscht',
      },
      'all_cardio_deleted': {
        'fr': '✅ Toutes les séances de cardio ont été supprimées',
        'en': '✅ All cardio sessions have been deleted',
        'de': '✅ Alle Cardio-Einheiten wurden gelöscht',
      },
      'workout_deleted': {
        'fr': '✅ Séance de musculation supprimée',
        'en': '✅ Strength workout deleted',
        'de': '✅ Krafttraining gelöscht',
      },
      'cardio_deleted': {
        'fr': '✅ Séance de cardio supprimée',
        'en': '✅ Cardio session deleted',
        'de': '✅ Cardio-Einheit gelöscht',
      },
      'no_workout': {
        'fr': 'Pas de séance de musculation ce jour-là',
        'en': 'No strength workout on that day',
        'de': 'Kein Krafttraining an diesem Tag',
      },
      'no_cardio': {
        'fr': 'Pas de cardio ce jour-là',
        'en': 'No cardio on that day',
        'de': 'Kein Cardio an diesem Tag',
      },
      'moved': {
        'fr': '✅ Séance déplacée',
        'en': '✅ Workout moved',
        'de': '✅ Training verschoben',
      },
      'cardio_created': {
        'fr': 'Cardio ajouté',
        'en': 'Cardio added',
        'de': 'Cardio hinzugefügt',
      },
      'workout_modified': {
        'fr': '✅ Séance modifiée',
        'en': '✅ Workout modified',
        'de': '✅ Training geändert',
      },
      'cardio_modified': {
        'fr': '✅ Cardio modifié',
        'en': '✅ Cardio modified',
        'de': '✅ Cardio geändert',
      },
      'no_workout_found': {
        'fr': '❌ Aucune séance trouvée ce jour-là',
        'en': '❌ No workout found on that day',
        'de': '❌ Kein Training an diesem Tag gefunden',
      },
      'no_cardio_found': {
        'fr': '❌ Aucun cardio trouvé ce jour-là',
        'en': '❌ No cardio found on that day',
        'de': '❌ Kein Cardio an diesem Tag gefunden',
      },
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  /// Traduire le nom de l'activité cardio
  /// Les 4 seules activités supportées: running, bike, walking, hiit
  static String _getCardioActivityName(String activityKey, String langCode) {
    final names = {
      'running': {'fr': 'Course à pied', 'en': 'Running', 'de': 'Laufen'},
      'bike': {'fr': 'Vélo', 'en': 'Cycling', 'de': 'Radfahren'},
      'walking': {'fr': 'Marche', 'en': 'Walking', 'de': 'Gehen'},
      'hiit': {'fr': 'HIIT', 'en': 'HIIT', 'de': 'HIIT'},
    };
    return names[activityKey.toLowerCase()]?[langCode] ??
           names[activityKey.toLowerCase()]?['en'] ??
           activityKey;
  }

  /// Obtenir le nom du jour dans la langue
  static String _getDayName(DateTime date, String langCode) {
    final dayNames = {
      'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'de': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
    };
    final days = dayNames[langCode] ?? dayNames['en']!;
    return days[date.weekday - 1];
  }

  /// Convertir une date en string de jour pour les tools (monday, tuesday, etc.)
  static String _getDayString(DateTime date) {
    const dayStrings = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return dayStrings[date.weekday - 1];
  }

  /// Les seules contraintes physiques, pour le générateur de séance.
  static Future<List<String>?> _workoutConstraints() async {
    try {
      final prefs = await CoachPreferenceExtractor.instance.getUserPreferences();
      final list = prefs?.fitnessConstraints ?? const <String>[];
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('Could not get workout constraints: $e');
      return null;
    }
  }

  /// Les contraintes physiques et les horaires que le coach a retenus.
  ///
  /// Elles vivent dans la mémoire du coach ; le planificateur n'en lisait que
  /// les allergies et le régime, et seulement côté repas. Retourne une chaîne
  /// vide quand il n'y a rien à dire, pour ne pas gonfler le prompt.
  static Future<String> _getPhysicalConstraints() async {
    try {
      final prefs = await CoachPreferenceExtractor.instance.getUserPreferences();
      if (prefs == null) return '';

      final lines = <String>[];
      if (prefs.fitnessConstraints.isNotEmpty) {
        lines.add('PHYSICAL CONSTRAINTS (injuries, limitations): ${prefs.fitnessConstraints.join(', ')}');
        lines.add('→ Avoid exercises and activities that load these areas. Say so in one short sentence when it changes your plan.');
      }
      if (prefs.preferredWorkoutTimes.isNotEmpty) {
        lines.add('PREFERRED TRAINING TIMES: ${prefs.preferredWorkoutTimes.join(', ')}');
      }
      if (lines.isEmpty) return '';

      return '''
═══════════════════════════════════════════════════════════════
              🔴 WHAT RYZE KNOWS ABOUT THIS USER
═══════════════════════════════════════════════════════════════
${lines.join('\n')}

''';
    } catch (e) {
      debugPrint('Could not get physical constraints: $e');
      return '';
    }
  }

  /// L'activité demandée sort des quatre que l'application sait planifier.
  ///
  /// Le message dit ce qui est possible plutôt que de renvoyer une erreur
  /// technique, et il existe dans les trois langues — l'allemand recevait
  /// l'anglais.
  static String _unsupportedActivityMessage(String requested, String langCode) {
    switch (langCode) {
      case 'fr':
        return 'Je ne sais pas encore planifier ça ($requested). Je gère la course, le vélo, la marche et le HIIT.';
      case 'de':
        return 'Das kann ich noch nicht planen ($requested). Ich kann Laufen, Radfahren, Gehen und HIIT.';
      default:
        return "I can't plan that yet ($requested). I handle running, cycling, walking and HIIT.";
    }
  }






  /// Retourne "Sunday (2026-01-18)" ou selon la langue "Dimanche (2026-01-18)"
  static String _getTodayWithDayName() {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[now.weekday - 1];
    final dateStr = now.toIso8601String().split('T')[0];
    return '$dayName ($dateStr)';
  }

  static String _formatDayName(DateTime date, String langCode) {
    final dayNames = {
      'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'de': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
    };

    final days = dayNames[langCode] ?? dayNames['en']!;
    return days[date.weekday - 1];
  }










  static String _getMessage(String langCode, String key) {
    final messages = {
      'workouts_created': {
        'fr': 'Parfait ! J\'ai créé {count} séances pour {days} 💪',
        'en': 'Perfect! I created {count} sessions for {days} 💪',
        'de': 'Perfekt! Ich habe {count} Einheiten für {days} erstellt 💪',
      },
      'cardio_created': {
        'fr': '{activity} planifié pour {days} 🏃',
        'en': '{activity} planned for {days} 🏃',
        'de': '{activity} geplant für {days} 🏃',
      },
      'meal_created': {
        'fr': '"{meal}" ajouté pour {days} 🍽️',
        'en': '"{meal}" added for {days} 🍽️',
        'de': '"{meal}" hinzugefügt für {days} 🍽️',
      },
      'no_available_days': {
        'fr': 'Désolé, il n\'y a plus de jours disponibles cette semaine.',
        'en': 'Sorry, there are no more available days this week.',
        'de': 'Entschuldigung, es sind keine Tage mehr diese Woche verfügbar.',
      },
      'workout_generation_failed': {
        'fr': 'Je n\'ai pas pu générer les séances. Réessaie !',
        'en': 'I couldn\'t generate the sessions. Try again!',
        'de': 'Ich konnte die Einheiten nicht erstellen. Versuche es erneut!',
      },
      'session_save_failed': {
        'fr': 'Impossible de sauvegarder la séance. Vérifie que le jour n\'est pas passé.',
        'en': 'Failed to save session. Check that the day is not in the past.',
        'de': 'Sitzung konnte nicht gespeichert werden. Prüfe, ob der Tag nicht in der Vergangenheit liegt.',
      },
      'cardio_creation_failed': {
        'fr': 'Je n\'ai pas pu planifier le cardio.',
        'en': 'I couldn\'t plan the cardio.',
        'de': 'Ich konnte das Cardio nicht planen.',
      },
      'meal_creation_failed': {
        'fr': 'Je n\'ai pas pu planifier le repas.',
        'en': 'I couldn\'t plan the meal.',
        'de': 'Ich konnte die Mahlzeit nicht planen.',
      },
      'meal_description_required': {
        'fr': 'Décris-moi le repas que tu veux planifier.',
        'en': 'Describe the meal you want to plan.',
        'de': 'Beschreibe mir die Mahlzeit, die du planen möchtest.',
      },
      'meal_analysis_failed': {
        'fr': 'Je n\'ai pas compris ce repas. Essaie avec plus de détails.',
        'en': 'I didn\'t understand that meal. Try with more details.',
        'de': 'Ich habe diese Mahlzeit nicht verstanden. Versuche es mit mehr Details.',
      },
      'no_valid_meals': {
        'fr': 'Aucun repas valide à planifier. Vérifie les jours demandés.',
        'en': 'No valid meals to plan. Check the requested days.',
        'de': 'Keine gültigen Mahlzeiten zu planen. Überprüfe die angeforderten Tage.',
      },
    };

    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  static String _getErrorMessage(String langCode, String key) {
    final errors = {
      'api_error': {
        'fr': 'Oups, une erreur s\'est produite. Réessaie !',
        'en': 'Oops, an error occurred. Try again!',
        'de': 'Hoppla, ein Fehler ist aufgetreten. Versuche es erneut!',
      },
      'unknown_intent': {
        'fr': 'Je n\'ai pas compris. Que veux-tu planifier ?',
        'en': 'I didn\'t understand. What would you like to plan?',
        'de': 'Ich habe nicht verstanden. Was möchtest du planen?',
      },
      'parse_error': {
        'fr': 'Je n\'ai pas pu traiter ta demande.',
        'en': 'I couldn\'t process your request.',
        'de': 'Ich konnte deine Anfrage nicht verarbeiten.',
      },
      'workout_error': {
        'fr': 'Erreur lors de la création des séances.',
        'en': 'Error creating workouts.',
        'de': 'Fehler beim Erstellen der Trainingseinheiten.',
      },
      'cardio_error': {
        'fr': 'Erreur lors de la planification du cardio.',
        'en': 'Error planning cardio.',
        'de': 'Fehler bei der Cardio-Planung.',
      },
      'meal_error': {
        'fr': 'Erreur lors de la planification du repas.',
        'en': 'Error planning meal.',
        'de': 'Fehler bei der Mahlzeitenplanung.',
      },
    };

    return errors[key]?[langCode] ?? errors[key]?['en'] ?? key;
  }






  /// Confirmer une seule session (workout ou cardio)
  static Future<PlannerActionResult> confirmSingleSession(PendingSession session) async {
    final langCode = LocalizationService.instance.currentLanguageCode;

    try {
      if (session.isWorkout && session.workout != null) {
        final workout = session.workout!;
        if (workout.exercises == null || workout.exercises!.isEmpty) {
          return PlannerActionResult.error('No exercises to save');
        }

        final savedWorkout = await WeeklyPlannerService.addPlannedWorkout(
          plannedDate: workout.plannedDate,
          workoutName: workout.workoutName,
          exercises: workout.exercises!,
          durationMinutes: workout.durationMinutes,
          userPrompt: workout.workoutPrompt,
          isAiGenerated: true,
        );

        if (savedWorkout != null) {
          final dayName = _formatDayName(workout.plannedDate, langCode);
          return PlannerActionResult.success('✓ $dayName: ${workout.workoutType}');
        }
      } else if (session.isCardio && session.cardio != null) {
        final cardio = session.cardio!;

        final cardioData = cardio.toPlannedCardioData();
        final activity = await WeeklyPlannerService.addPlannedActivity(
          plannedDate: cardio.plannedDate,
          activityType: PlannedActivityType.cardio,
          activityData: cardioData.toJson(),
          isAiGenerated: true,
        );

        if (activity != null) {
          final dayName = _formatDayName(cardio.plannedDate, langCode);
          return PlannerActionResult.success('✓ $dayName: ${cardio.displayTitle}');
        }
      }

      return PlannerActionResult.error(_getMessage(langCode, 'session_save_failed'));
    } catch (e) {
      debugPrint('❌ confirmSingleSession error: $e');
      return PlannerActionResult.error('Error saving session: $e');
    }
  }

}
