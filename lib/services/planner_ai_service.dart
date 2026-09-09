import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_planner_models.dart';
import '../models/sport_models.dart';
import 'weekly_planner_service.dart';
import 'planned_cardio_service.dart';
import 'ai_workout_generation_service.dart';
import 'localization_service.dart';
import 'auth_service.dart';
import 'unified_subscription_service.dart';
import 'coach_preference_extractor.dart';
import 'translations.dart';
import '../ai/ryze_access.dart';

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

  // =====================================================
  // ACCÈS : premium, ou mode démo de l'onboarding
  // =====================================================

  /// Le mode démo de l'onboarding, sur un seul interrupteur.
  ///
  /// Il y en avait deux, un par moteur. Celui-ci reste pour les appelants
  /// existants et ne fait plus que déléguer.
  static void setDemoMode(bool value) => RyzeAccess.setDemoMode(value);

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

  /// Vérifier si l'utilisateur est premium
  static bool get isPremium => UnifiedSubscriptionService().isPremium;

  /// Message pour le paywall
  /// Le message quand la porte est fermée.
  ///
  /// Il parlait de « 3 planifications gratuites cette semaine », un compte qui
  /// n'existe plus depuis le paywall dur : `canUseAI` regarde l'abonnement, un
  /// point c'est tout.
  static String paywallMessage(String langCode) {
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
  /// Le jour que le modèle a écrit, lu comme une date.
  ///
  /// Public pour les tests : c'est la lecture qui a produit
  /// « Invalid days » à l'écran, et elle mérite d'être tenue.
  @visibleForTesting
  static DateTime? parseDay(String dayStr) => _parseSingleDay(dayStr);

  static DateTime? _parseSingleDay(String dayStr) {
    final weekStart = planningWindowStart;

    // « aujourd'hui » et « demain » d'abord.
    //
    // Le schéma n'accepte que les sept jours, mais quand l'utilisateur dit
    // « c'est pour aujourd'hui », le modèle écrit « today » et la lecture
    // échouait sur « Invalid days ». Ces mots-là désignent une date aussi
    // clairement qu'un nom de jour.
    const relatifs = {
      'today': 0, "aujourd'hui": 0, 'aujourdhui': 0, 'heute': 0,
      'tomorrow': 1, 'demain': 1, 'morgen': 1,
      'yesterday': -1, 'hier': -1, 'gestern': -1,
    };
    final decalage = relatifs[dayStr.toLowerCase().trim()];
    if (decalage != null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).add(Duration(days: decalage));
    }

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
  // FUNCTION CALLING - Nouvelle approche
  // =====================================================

  /// La dernière action, gardée pour pouvoir la défaire.
  static Map<String, dynamic>? _lastAction;

  /// Y a-t-il quelque chose à défaire ?
  ///
  /// Les exécuteurs gardent de quoi remettre en place ce qu'ils viennent de
  /// retirer ou de déplacer. C'est ce que la surface lit pour décider si la
  /// bulle porte un « annuler » : la question se pose après coup, pas au
  /// moment de déclarer l'outil.
  static bool get hasUndo => _lastAction != null;

  /// Exécuter un appel d'outil.
  ///
  /// Les déclarations vivent maintenant dans `lib/ai/ryze_tools/plan_tools.dart`,
  /// une seule fois pour les deux surfaces. Ce qui reste ici, ce sont les
  /// exécuteurs : ils écrivent dans la semaine et ils sont bons.
  static Future<Map<String, dynamic>> executeToolCall(
    String functionName,
    Map<String, dynamic> args,
    String langCode,
  ) async {
    switch (functionName) {
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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};

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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};

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

        PendingWorkout built(List<WorkoutExercise> exercises) => PendingWorkout(
              plannedDate: day,
              workoutName: '$workoutType - ${duration}min',
              workoutType: workoutType,
              durationMinutes: duration,
              workoutPrompt: focus,
              exercises: exercises,
            );

        // Les exercices dictés par la conversation passent d'abord.
        //
        // Sans eux, un second modèle composait la séance sans jamais rendre
        // son contenu à celui qui parlait : Ryze annonçait une liste, la base
        // en recevait une autre, et personne ne pouvait le voir. Quand la
        // conversation les fournit, ce sont eux qui sont posés.
        final dictated = args['exercises'];
        if (dictated is List && dictated.isNotEmpty) {
          final exercises = await AIWorkoutGenerationService.buildExercises(dictated);
          if (exercises.isNotEmpty) {
            return {
              'success': true,
              'message': 'Workout created for ${args['day']}',
              'pending_workout': built(exercises),
            };
          }
        }

        // Sinon, le générateur compose, et son contenu repart au modèle.
        const maxRetries = 2;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
          final result = await AIWorkoutGenerationService.generateWorkout(
            userRequest: '$workoutType workout, $focus',
            constraints: await _workoutConstraints(),
            durationMinutes: duration,
          );

          if (result.success && result.exercises.isNotEmpty) {
            return {
              'success': true,
              'message': 'Workout created for ${args['day']}',
              'pending_workout': built(result.exercises),
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
          return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
          return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
            return await executeToolCall('create_hiit', {'day': dayStr}, langCode);
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
            final created = await executeToolCall('create_cardio', {
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
          return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
            return await executeToolCall('create_hiit', {
              'day': args['current_day'],
              'hiit_type': hiitType,
            }, langCode);
          }

          // Sinon, rediriger vers create_hiit qui va demander les paramètres
          return await executeToolCall('create_hiit', {'day': args['current_day']}, langCode);
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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};

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
        if (day == null) return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};

        // Utiliser le service partagé pour détecter et rediriger HIIT
        if (PlannedCardioService.isHiitType(activityKey)) {
          return await executeToolCall('create_hiit', {'day': dayStr}, langCode);
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
        return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
        return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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
        return {'success': false, 'message': _getMessage(langCode, 'day_not_understood')};
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

  /// Annuler la dernière action (undo)
  static Future<PlannerActionResult> undoLastAction() async {
    final langCode = LocalizationService.instance.currentLanguageCode;
    final result = await executeToolCall('undo_last_action', {}, langCode);

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
      'day_not_understood': {
        'fr': "Je n'ai pas compris de quel jour tu parles. Dis-le-moi autrement ?",
        'en': "I did not catch which day you mean. Say it another way?",
        'de': 'Ich habe nicht verstanden, welchen Tag du meinst. Sag es anders?',
      },
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
