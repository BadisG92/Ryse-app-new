import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/weekly_planner_models.dart';
import '../models/sport_models.dart';
import '../models/ai_analysis_models.dart';
import '../models/user_model.dart';
import 'weekly_planner_service.dart';
import 'planned_cardio_service.dart';
import 'gemini_analysis_service_v2.dart';
import 'ai_workout_generation_service.dart';
import 'food_entries_service.dart';
import 'localization_service.dart';
import 'auth_service.dart';
import 'unified_subscription_service.dart';
import 'feature_trial_service.dart';
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
  final int? remainingFreeUses;
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
    this.remainingFreeUses,
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
  // =====================================================
  // FREE TIER LIMITS - 5 planifications IA à vie (sport + repas combinés)
  // =====================================================

  /// Vérifier si l'utilisateur peut utiliser l'IA (premium ou essais restants)
  static Future<bool> canUseAI() async {
    // Premium = accès illimité
    if (UnifiedSubscriptionService().isPremium) {
      return true;
    }
    // Mode test = accès illimité (sans décompte)
    if (UnifiedSubscriptionService().testMode) {
      return true;
    }
    // Free = vérifier les essais restants (5 à vie)
    final remaining = await getRemainingFreeUses();
    return remaining > 0;
  }

  /// Obtenir le nombre d'utilisations restantes pour les utilisateurs free
  /// Utilise maintenant FeatureTrialService (5 essais à vie, pas de reset hebdomadaire)
  static Future<int> getRemainingFreeUses() async {
    return await FeatureTrialService.instance.getPlannerRemainingUsages();
  }

  /// Incrémenter le compteur d'utilisation (appelé après une planification réussie)
  /// Utilise maintenant FeatureTrialService (compteur persistant en base de données)
  static Future<void> incrementUsageCount() async {
    // Ne pas incrémenter pour les premium
    if (UnifiedSubscriptionService().isPremium) {
      return;
    }

    // Incrémenter via FeatureTrialService (stocké en base de données)
    await FeatureTrialService.instance.incrementPlannerUsage();

    final remaining = await FeatureTrialService.instance.getPlannerRemainingUsages();
    debugPrint('📊 AI Planner usage: ${FeatureTrialService.maxPlannerUsages - remaining}/${FeatureTrialService.maxPlannerUsages} (restants: $remaining)');
  }

  /// Vérifier si l'utilisateur est premium
  static bool get isPremium => UnifiedSubscriptionService().isPremium;

  // =====================================================
  // SESSION TRACKING - Pour éviter de compter plusieurs fois par session
  // =====================================================

  /// Flag pour tracker si on a déjà incrémenté le compteur dans cette session de chat
  /// Reset quand on ouvre un nouveau chat ou qu'on clear l'historique
  static bool _sessionAlreadyCounted = false;

  /// Incrémenter le compteur une seule fois par session de génération
  /// Appelé quand l'utilisateur confirme des repas ou workouts
  static Future<void> _incrementUsageOncePerSession() async {
    // Si déjà compté dans cette session, ne pas re-compter
    if (_sessionAlreadyCounted) {
      debugPrint('📊 AI Planner: Session déjà comptée, pas de nouveau décompte');
      return;
    }

    // Incrémenter et marquer la session comme comptée
    await incrementUsageCount();
    _sessionAlreadyCounted = true;
  }

  /// Reset le flag de session (appelé quand on ouvre un nouveau chat)
  static void resetSessionCounter() {
    _sessionAlreadyCounted = false;
    debugPrint('📊 AI Planner: Session counter reset');
  }

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
    _sessionAlreadyCounted = false; // Reset le compteur de session
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

  /// Analyser l'intention de l'utilisateur
  /// [mode] peut être 'meals' ou 'workouts' pour spécialiser l'IA
  static Future<IntentAnalysis> analyzeIntent(
    String userMessage, {
    String? conversationId,
    String? mode, // 'meals' ou 'workouts'
  }) async {
    final langCode = LocalizationService.instance.currentLanguageCode;

    try {
      if (!GeminiConfig.isConfigured) {
        return IntentAnalysis(
          intent: PlannerIntent.unknown,
          extractedInfo: {},
          followUpQuestion: _getErrorMessage(langCode, 'api_error'),
        );
      }

      // Construire le prompt d'analyse d'intention (async pour récupérer le contexte)
      // Utiliser le prompt spécialisé selon le mode
      final prompt = mode == 'meals'
          ? await _buildMealsIntentPrompt(userMessage, langCode)
          : mode == 'workouts'
              ? await _buildWorkoutsIntentPrompt(userMessage, langCode)
              : await _buildIntentPrompt(userMessage, langCode);

      // Appeler Gemini
      final response = await _callGeminiAPI(prompt);

      if (response == null) {
        return IntentAnalysis(
          intent: PlannerIntent.unknown,
          extractedInfo: {},
          followUpQuestion: _getErrorMessage(langCode, 'api_error'),
        );
      }

      // Parser la réponse (inclut maintenant response_message)
      return _parseIntentResponse(response, langCode);
    } catch (e) {
      debugPrint('❌ PlannerAIService.analyzeIntent error: $e');
      return IntentAnalysis(
        intent: PlannerIntent.unknown,
        extractedInfo: {},
        followUpQuestion: _getErrorMessage(langCode, 'api_error'),
      );
    }
  }

  /// Traiter une demande complète de planification
  /// [mode] peut être 'meals' ou 'workouts' pour spécialiser l'IA
  static Future<PlannerActionResult> processRequest(
    String userMessage, {
    Map<String, dynamic>? additionalContext,
    String? mode, // 'meals' ou 'workouts'
  }) async {
    final langCode = LocalizationService.instance.currentLanguageCode;

    try {
      // Vérifier si l'utilisateur peut utiliser l'IA
      final canUse = await canUseAI();
      if (!canUse) {
        return PlannerActionResult.paywall(
          _getPaywallMessage(langCode),
        );
      }

      // Analyser l'intention avec le mode spécialisé
      final intent = await analyzeIntent(userMessage, mode: mode);

      if (!intent.isComplete) {
        // Besoin de plus d'infos - ne pas compter comme utilisation
        return PlannerActionResult(
          success: true,
          message: intent.followUpQuestion ?? _getFollowUpQuestion(langCode),
        );
      }

      // Vérifier que l'intent correspond au mode
      if (mode != null) {
        if (mode == 'meals' && intent.intent != PlannerIntent.meal) {
          return PlannerActionResult(
            success: true,
            message: _getModeErrorMessage(langCode, 'meals'),
          );
        }
        // Workout mode accepte: workout, cardio, useTemplate, moveWorkout, deleteWorkout, modifyWorkout
        final workoutIntents = [
          PlannerIntent.workout,
          PlannerIntent.cardio,
          PlannerIntent.useTemplate,
          PlannerIntent.moveWorkout,
          PlannerIntent.deleteWorkout,
          PlannerIntent.modifyWorkout,
        ];
        if (mode == 'workouts' && !workoutIntents.contains(intent.intent)) {
          return PlannerActionResult(
            success: true,
            message: _getModeErrorMessage(langCode, 'workouts'),
          );
        }
      }

      // Exécuter l'action appropriée
      PlannerActionResult result;
      switch (intent.intent) {
        case PlannerIntent.workout:
          result = await _handleWorkoutRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.cardio:
          result = await _handleCardioRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.meal:
          result = await _handleMealRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.useTemplate:
          result = await _handleUseTemplateRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.moveWorkout:
          result = await _handleMoveWorkoutRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.deleteWorkout:
          result = await _handleDeleteWorkoutRequest(intent.extractedInfo, langCode);
          break;
        case PlannerIntent.modifyWorkout:
          // Pour modify, on redirige vers workout avec les infos de modification
          result = await _handleModifyWorkoutRequest(intent.extractedInfo, langCode);
          break;
        default:
          return PlannerActionResult.error(
            _getErrorMessage(langCode, 'unknown_intent'),
          );
      }

      // NOTE: Ne PAS incrémenter ici (move, delete ne comptent pas comme utilisation)
      // L'incrément se fait UNIQUEMENT dans confirmWorkouts/confirmSessions/confirmMeals
      // quand l'utilisateur VALIDE une CRÉATION

      return result;
    } catch (e) {
      debugPrint('❌ PlannerAIService.processRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'api_error'),
      );
    }
  }

  /// Message d'erreur quand l'utilisateur demande quelque chose hors du mode
  static String _getModeErrorMessage(String langCode, String mode) {
    if (mode == 'meals') {
      switch (langCode) {
        case 'fr':
          return "Je suis ton coach nutrition ici ! 🍽️\n\nDis-moi plutôt quel repas tu veux planifier : petit-déjeuner, déjeuner, dîner ou collation ?";
        case 'de':
          return "Ich bin hier dein Ernährungscoach! 🍽️\n\nSag mir lieber, welche Mahlzeit du planen möchtest: Frühstück, Mittagessen, Abendessen oder Snack?";
        default:
          return "I'm your nutrition coach here! 🍽️\n\nTell me which meal you want to plan: breakfast, lunch, dinner or snack?";
      }
    } else {
      switch (langCode) {
        case 'fr':
          return "Je suis ton coach fitness ici ! 💪\n\nDis-moi plutôt quel type de séance tu veux : musculation, cardio, HIIT ?";
        case 'de':
          return "Ich bin hier dein Fitnesscoach! 💪\n\nSag mir lieber, welche Art von Training du möchtest: Krafttraining, Cardio, HIIT?";
        default:
          return "I'm your fitness coach here! 💪\n\nTell me what type of session you want: weight training, cardio, HIIT?";
      }
    }
  }

  /// Message pour le paywall
  static String _getPaywallMessage(String langCode) {
    switch (langCode) {
      case 'fr':
        return "Tu as utilisé tes 3 planifications gratuites cette semaine ! 🎯\n\nPasse à Premium pour des planifications illimitées avec Ryze.";
      case 'de':
        return "Du hast deine 3 kostenlosen Planungen diese Woche aufgebraucht! 🎯\n\nWerde Premium für unbegrenzte Planungen mit Ryze.";
      default:
        return "You've used your 3 free plannings this week! 🎯\n\nUpgrade to Premium for unlimited planning with Ryze.";
    }
  }

  /// Gérer une demande de workout (nouveau format intelligent avec preview)
  static Future<PlannerActionResult> _handleWorkoutRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      // Vérifier si on doit d'abord supprimer toutes les séances de la semaine
      final clearWeekFirst = info['clear_week_first'] as bool? ?? false;
      if (clearWeekFirst) {
        debugPrint('🗑️ Clearing all workouts for this week first...');
        await WeeklyPlannerService.deleteAllWorkoutsThisWeek();
      }

      // Nouveau format: liste de workouts personnalisés par Gemini
      final workouts = info['workouts'] as List?;
      final responseMessage = info['response_message'] as String?;

      if (workouts == null || workouts.isEmpty) {
        // Fallback vers l'ancien format si pas de workouts détaillés
        return await _handleLegacyWorkoutRequest(info, langCode);
      }

      final pendingWorkouts = <PendingWorkout>[];

      for (final workoutData in workouts) {
        final dayStr = workoutData['day'] as String? ?? '';
        final workoutType = workoutData['workout_type'] as String? ?? 'Full Body';
        final workoutPrompt = workoutData['workout_prompt'] as String? ?? workoutType;
        final durationMinutes = workoutData['duration_minutes'] as int? ?? 45;

        // Parser le jour
        final day = _parseSingleDay(dayStr);
        if (day == null) {
          debugPrint('⚠️ Invalid day: $dayStr');
          continue;
        }

        // Vérifier si un workout existe déjà ce jour
        final hasWorkout = await WeeklyPlannerService.hasWorkoutForDate(day);
        if (hasWorkout) {
          debugPrint('⚠️ Workout already exists for ${day.toIso8601String()}');
          continue;
        }

        // Générer le workout avec l'IA (preview, sans sauvegarder)
        final result = await AIWorkoutGenerationService.generateWorkout(
          userRequest: workoutPrompt,
          durationMinutes: durationMinutes,
        );

        if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
          pendingWorkouts.add(PendingWorkout(
            plannedDate: day,
            workoutName: '$workoutType - ${durationMinutes}min',
            workoutType: workoutType,
            durationMinutes: durationMinutes,
            workoutPrompt: workoutPrompt,
            exercises: result.exercises,
          ));
        }
      }

      if (pendingWorkouts.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'workout_generation_failed'),
        );
      }

      // Retourner un preview avec les workouts générés (non sauvegardés)
      final previewMessage = responseMessage ?? _getPreviewMessage(langCode, pendingWorkouts);

      return PlannerActionResult.preview(
        message: previewMessage,
        workouts: pendingWorkouts,
      );
    } catch (e) {
      debugPrint('❌ _handleWorkoutRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
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

      // Incrémenter le compteur UNE SEULE FOIS par session (même si plusieurs workouts confirmés)
      await _incrementUsageOncePerSession();

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

  /// Message de preview
  static String _getPreviewMessage(String langCode, List<PendingWorkout> workouts) {
    final header = {
      'fr': 'Voici ton programme ! Vérifie et valide 👇\n\n',
      'en': 'Here\'s your program! Review and confirm 👇\n\n',
      'de': 'Hier ist dein Programm! Überprüfe und bestätige 👇\n\n',
    };

    final exercisesLabel = {
      'fr': 'exercices',
      'en': 'exercises',
      'de': 'Übungen',
    };

    final workoutsList = workouts.map((w) {
      final dayName = _formatDayName(w.plannedDate, langCode);
      final exerciseCount = w.exercises?.length ?? 0;
      return '• $dayName: ${w.workoutType} (${w.durationMinutes}min, $exerciseCount ${exercisesLabel[langCode] ?? 'exercises'})';
    }).join('\n');

    final footer = {
      'fr': '\n\n💡 Les poids sont adaptés à ton historique. Clique sur une séance pour voir les exercices.',
      'en': '\n\n💡 Weights are adapted to your history. Tap a session to see exercises.',
      'de': '\n\n💡 Die Gewichte sind an deinen Verlauf angepasst. Tippe auf eine Einheit, um die Übungen zu sehen.',
    };

    return '${header[langCode] ?? header['en']}$workoutsList${footer[langCode] ?? footer['en']}';
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

  /// Fallback vers l'ancien format de workout
  static Future<PlannerActionResult> _handleLegacyWorkoutRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    final sessionCount = info['session_count'] as int? ?? 3;
    final splitTypeStr = info['split_type'] as String? ?? 'full_body';
    final durationMinutes = info['duration_minutes'] as int? ?? 45;

    final splitType = WorkoutSplitExtension.fromString(splitTypeStr);
    final targetDays = _getAvailableDays(sessionCount);

    if (targetDays.isEmpty) {
      return PlannerActionResult.error(
        _getMessage(langCode, 'no_available_days'),
      );
    }

    final workoutTypes = splitType.getWorkoutTypes(targetDays.length);
    final createdWorkouts = <String>[];

    for (int i = 0; i < targetDays.length; i++) {
      final day = targetDays[i];
      final workoutType = workoutTypes[i];

      final hasWorkout = await WeeklyPlannerService.hasWorkoutForDate(day);
      if (hasWorkout) continue;

      final prompt = _buildWorkoutPrompt(workoutType, durationMinutes);
      final result = await AIWorkoutGenerationService.generateWorkout(
        userRequest: prompt,
        durationMinutes: durationMinutes,
      );

      if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
        final workoutName = _getWorkoutTypeName(workoutType, langCode);
        await WeeklyPlannerService.addPlannedWorkout(
          plannedDate: day,
          workoutName: '$workoutName - ${durationMinutes}min',
          exercises: result.exercises!,
          durationMinutes: durationMinutes,
          userPrompt: prompt,
          isAiGenerated: true,
        );
        createdWorkouts.add('${_formatDayName(day, langCode)}: $workoutName');
      }
    }

    if (createdWorkouts.isEmpty) {
      return PlannerActionResult.error(_getMessage(langCode, 'workout_generation_failed'));
    }

    return PlannerActionResult.success(
      _getDefaultWorkoutMessage(langCode, createdWorkouts),
      items: createdWorkouts,
    );
  }

  /// Parser un jour unique
  static DateTime? _parseSingleDay(String dayStr) {
    final weekStart = getCurrentWeekStart();
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
    return weekStart.add(Duration(days: offset));
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

  /// Construire le prompt pour générer un workout selon le type
  static String _buildWorkoutPrompt(String workoutType, int durationMinutes) {
    final prompts = {
      'Full Body': 'Full body workout targeting all major muscle groups, $durationMinutes minutes',
      'Push': 'Push workout focusing on chest, shoulders, and triceps, $durationMinutes minutes',
      'Pull': 'Pull workout focusing on back and biceps, $durationMinutes minutes',
      'Legs': 'Leg workout focusing on quads, hamstrings, glutes and calves, $durationMinutes minutes',
      'Upper Body': 'Upper body workout for chest, back, shoulders and arms, $durationMinutes minutes',
      'Lower Body': 'Lower body workout for legs and glutes, $durationMinutes minutes',
    };

    return prompts[workoutType] ?? prompts['Full Body']!;
  }

  /// Obtenir le nom localisé d'un type de workout
  static String _getWorkoutTypeName(String workoutType, String langCode) {
    final names = {
      'Full Body': {'fr': 'Full Body', 'en': 'Full Body', 'de': 'Ganzkörper'},
      'Push': {'fr': 'Push (Poussée)', 'en': 'Push', 'de': 'Push (Drücken)'},
      'Pull': {'fr': 'Pull (Tirage)', 'en': 'Pull', 'de': 'Pull (Ziehen)'},
      'Legs': {'fr': 'Legs (Jambes)', 'en': 'Legs', 'de': 'Beine'},
      'Upper Body': {'fr': 'Haut du corps', 'en': 'Upper Body', 'de': 'Oberkörper'},
      'Lower Body': {'fr': 'Bas du corps', 'en': 'Lower Body', 'de': 'Unterkörper'},
    };

    return names[workoutType]?[langCode] ?? names[workoutType]?['en'] ?? workoutType;
  }

  /// Message par défaut pour la confirmation
  static String _getDefaultWorkoutMessage(String langCode, List<String> createdWorkouts) {
    final header = {
      'fr': 'Parfait ! J\'ai créé ton programme personnalisé 💪\n\n',
      'en': 'Perfect! I created your personalized program 💪\n\n',
      'de': 'Perfekt! Ich habe dein personalisiertes Programm erstellt 💪\n\n',
    };

    final workoutsList = createdWorkouts.map((w) => '• $w').join('\n');
    return '${header[langCode] ?? header['en']}$workoutsList';
  }

  /// Gérer une demande de cardio
  static Future<PlannerActionResult> _handleCardioRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final activityName = info['activity_name'] as String? ?? 'Course';
      final activityKey = _getActivityKey(activityName);
      final targetMinutes = info['target_minutes'] as int?;
      final targetKm = info['target_km'] as double?;
      final days = info['days'] as List<DateTime>?;

      final targetDays = days ?? [DateTime.now()];
      final createdItems = <String>[];

      for (final day in targetDays) {
        // Vérifier si la date est valide
        if (!isDateEditable(day) || !isInCurrentWeek(day)) {
          continue;
        }

        final cardioData = PlannedCardioData(
          activityName: activityName,
          activityKey: activityKey,
          targetMinutes: targetMinutes,
          targetKm: targetKm,
        );

        final activity = await WeeklyPlannerService.addPlannedActivity(
          plannedDate: day,
          activityType: PlannedActivityType.cardio,
          activityData: cardioData.toJson(),
          isAiGenerated: true,
        );

        if (activity != null) {
          createdItems.add(_formatDayName(day, langCode));
        }
      }

      if (createdItems.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'cardio_creation_failed'),
        );
      }

      return PlannerActionResult.success(
        _getMessage(langCode, 'cardio_created')
            .replaceAll('{activity}', activityName)
            .replaceAll('{days}', createdItems.join(', ')),
        items: createdItems,
      );
    } catch (e) {
      debugPrint('❌ _handleCardioRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'cardio_error'),
      );
    }
  }

  /// Gérer une demande de repas - Nouveau flow avec preview
  static Future<PlannerActionResult> _handleMealRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final meals = info['meals'] as List?;
      final responseMessage = info['response_message'] as String?;

      // Nouveau format: tableau de repas générés par l'IA
      if (meals != null && meals.isNotEmpty) {
        final pendingMeals = <PendingMeal>[];
        final weekStart = getCurrentWeekStart();

        for (final mealData in meals) {
          final dayStr = mealData['day'] as String? ?? 'monday';
          final mealTypeStr = mealData['meal_type'] as String? ?? 'breakfast';
          final dishName = mealData['dish_name'] as String? ?? 'Repas';
          final dishDescription = mealData['dish_description'] as String? ?? '';
          final proteins = (mealData['proteins'] as num?)?.toDouble() ?? 0.0;
          final carbs = (mealData['carbs'] as num?)?.toDouble() ?? 0.0;
          final fats = (mealData['fats'] as num?)?.toDouble() ?? 0.0;
          final quantityG = (mealData['quantity_g'] as num?)?.toDouble() ?? 200.0;
          final reasoning = mealData['reasoning'] as String?;
          // IMPORTANT: Calculer les calories avec la formule au lieu de prendre la valeur IA
          // Formule standard: protéines × 4 + glucides × 4 + lipides × 9
          final calories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

          // Convertir le jour en DateTime
          final dayIndex = _dayStringToIndex(dayStr);
          final plannedDate = weekStart.add(Duration(days: dayIndex));

          // Vérifier que la date n'est pas passée
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (plannedDate.isBefore(today)) continue;

          // Convertir le type de repas
          final mealType = _getMealActivityType(mealTypeStr);

          pendingMeals.add(PendingMeal(
            plannedDate: plannedDate,
            mealType: mealType,
            dishName: dishName,
            dishDescription: dishDescription,
            calories: calories,
            proteins: proteins,
            carbs: carbs,
            fats: fats,
            estimatedQuantityG: quantityG,
            aiReasoning: reasoning,
          ));
        }

        if (pendingMeals.isEmpty) {
          return PlannerActionResult.error(
            _getMessage(langCode, 'no_valid_meals'),
          );
        }

        // Retourner le preview pour confirmation
        return PlannerActionResult.mealPreview(
          message: responseMessage ?? _buildMealPreviewMessage(pendingMeals, langCode),
          meals: pendingMeals,
        );
      }

      // Ancien format: description simple (backward compatibility)
      final foodDescription = info['food_description'] as String?;
      final mealType = info['meal_type'] as String? ?? 'breakfast';
      final days = info['days'] as List<DateTime>?;

      if (foodDescription == null || foodDescription.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'meal_description_required'),
        );
      }

      final targetDays = days ?? [DateTime.now()];
      final pendingMeals = <PendingMeal>[];
      final activityType = _getMealActivityType(mealType);

      // Analyser le repas avec Gemini pour estimer les macros
      final analysisResult = await GeminiAnalysisServiceV2.analyzeTextDescription(
        foodDescription,
      );

      int totalCalories = 300; // Default
      double totalProteins = 20.0;
      double totalCarbs = 30.0;
      double totalFats = 15.0;

      if (analysisResult.success && analysisResult.detectedFoods.isNotEmpty) {
        totalCalories = 0;
        totalProteins = 0;
        totalCarbs = 0;
        totalFats = 0;

        for (final food in analysisResult.detectedFoods) {
          totalCalories += food.calories;
          totalProteins += food.nutrition.proteins;
          totalCarbs += food.nutrition.carbs;
          totalFats += food.nutrition.fats;
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final day in targetDays) {
        if (!isInCurrentWeek(day)) continue;
        final normalizedDay = DateTime(day.year, day.month, day.day);
        if (normalizedDay.isBefore(today)) continue;

        pendingMeals.add(PendingMeal(
          plannedDate: normalizedDay,
          mealType: activityType,
          dishName: foodDescription,
          dishDescription: '',
          calories: totalCalories,
          proteins: totalProteins,
          carbs: totalCarbs,
          fats: totalFats,
          estimatedQuantityG: 200.0,
        ));
      }

      if (pendingMeals.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'no_valid_meals'),
        );
      }

      return PlannerActionResult.mealPreview(
        message: responseMessage ?? _buildMealPreviewMessage(pendingMeals, langCode),
        meals: pendingMeals,
      );
    } catch (e) {
      debugPrint('❌ _handleMealRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'meal_error'),
      );
    }
  }

  /// Convertir un jour string en index (0 = lundi)
  static int _dayStringToIndex(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 0;
      case 'tuesday': return 1;
      case 'wednesday': return 2;
      case 'thursday': return 3;
      case 'friday': return 4;
      case 'saturday': return 5;
      case 'sunday': return 6;
      default: return 0;
    }
  }

  /// Construire un message de preview pour les repas
  static String _buildMealPreviewMessage(List<PendingMeal> meals, String langCode) {
    final buffer = StringBuffer();

    if (langCode == 'fr') {
      buffer.writeln('Voici les repas que je te propose :');
    } else {
      buffer.writeln('Here are the meals I suggest:');
    }

    // Grouper par jour
    final mealsByDay = <String, List<PendingMeal>>{};
    for (final meal in meals) {
      final dayName = meal.dayName;
      mealsByDay.putIfAbsent(dayName, () => []).add(meal);
    }

    for (final entry in mealsByDay.entries) {
      buffer.writeln('\n📅 ${entry.key}:');
      for (final meal in entry.value) {
        buffer.writeln('  • ${meal.mealTypeName}: ${meal.dishName}');
        buffer.writeln('    ${meal.calories} kcal - ${meal.proteins.toStringAsFixed(0)}g P / ${meal.carbs.toStringAsFixed(0)}g C / ${meal.fats.toStringAsFixed(0)}g L');
      }
    }

    return buffer.toString();
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

      // Incrémenter le compteur UNE SEULE FOIS par session (même si plusieurs repas confirmés)
      await _incrementUsageOncePerSession();

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

  /// Gérer une demande d'utilisation de template sauvegardé
  static Future<PlannerActionResult> _handleUseTemplateRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final templateId = info['template_id'] as String?;
      // templateName is used for display if we can't find by ID
      final targetDayStr = info['target_day'] as String?;

      if (templateId == null || templateId.isEmpty) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'template_not_found'),
        );
      }

      if (targetDayStr == null || targetDayStr.isEmpty) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'day_required'),
        );
      }

      final targetDay = _parseSingleDay(targetDayStr);
      if (targetDay == null) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'invalid_day'),
        );
      }

      // Vérifier si un workout existe déjà ce jour
      final hasWorkout = await WeeklyPlannerService.hasWorkoutForDate(targetDay);
      if (hasWorkout) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'day_occupied'),
        );
      }

      // Récupérer le template depuis la BDD
      final client = Supabase.instance.client;

      // D'abord récupérer le template de base
      final templateData = await client
          .from('user_workout_templates')
          .select('id, name, estimated_duration_minutes')
          .eq('id', templateId)
          .maybeSingle();

      if (templateData == null) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'template_not_found'),
        );
      }

      // Ensuite récupérer les exercices du template séparément
      final templateExercisesData = await client
          .from('user_workout_template_exercises')
          .select('order_index, suggested_sets, suggested_reps_min, suggested_reps_max, exercise_id, custom_exercise_id')
          .eq('template_id', templateId)
          .order('order_index', ascending: true);

      final exercises = <WorkoutExercise>[];

      for (final templateEx in (templateExercisesData as List)) {
        final exerciseId = templateEx['exercise_id'] as String?;
        final customExerciseId = templateEx['custom_exercise_id'] as String?;

        Map<String, dynamic>? exerciseData;

        // Récupérer les détails de l'exercice
        if (exerciseId != null) {
          final exData = await client
              .from('exercises')
              .select('id, name, muscle_group, equipment')
              .eq('id', exerciseId)
              .maybeSingle();
          exerciseData = exData;
        } else if (customExerciseId != null) {
          final exData = await client
              .from('custom_exercises')
              .select('id, name, muscle_group, equipment')
              .eq('id', customExerciseId)
              .maybeSingle();
          exerciseData = exData;
        }

        if (exerciseData == null) continue;

        final suggestedSets = templateEx['suggested_sets'] as int? ?? 3;
        final suggestedRepsMax = templateEx['suggested_reps_max'] as int? ?? 12;

        // Créer l'exercice
        final exercise = Exercise(
          id: exerciseData['id'] ?? '',
          name: exerciseData['name'] ?? '',
          muscleGroup: exerciseData['muscle_group'] ?? '',
          equipment: exerciseData['equipment'],
        );

        // Créer les sets par défaut
        final sets = List<ExerciseSet>.generate(suggestedSets, (i) => ExerciseSet(
          reps: suggestedRepsMax,
          weight: 0.0, // Sera rempli par l'utilisateur ou avec l'historique
        ));

        exercises.add(WorkoutExercise(
          exercise: exercise,
          sets: sets,
        ));
      }

      if (exercises.isEmpty) {
        return PlannerActionResult(
          success: true,
          message: _getTemplateErrorMessage(langCode, 'template_empty'),
        );
      }

      // Créer le workout planifié
      final workoutName = templateData['name'] as String? ?? 'Custom Workout';
      final duration = templateData['estimated_duration_minutes'] as int? ?? 45;

      final workout = await WeeklyPlannerService.addPlannedWorkout(
        plannedDate: targetDay,
        workoutName: workoutName,
        exercises: exercises,
        durationMinutes: duration,
        userPrompt: 'Template: $workoutName',
        isAiGenerated: false,
      );

      if (workout == null) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'workout_generation_failed'),
        );
      }

      final dayName = _formatDayName(targetDay, langCode);
      return PlannerActionResult.success(
        _getTemplateSuccessMessage(langCode, workoutName, dayName),
        items: [dayName],
      );
    } catch (e) {
      debugPrint('❌ _handleUseTemplateRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
    }
  }

  /// Gérer une demande de déplacement de workout
  static Future<PlannerActionResult> _handleMoveWorkoutRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final sourceDayStr = info['source_day'] as String?;
      final targetDayStr = info['target_day'] as String?;
      final responseMessage = info['response_message'] as String?;

      if (sourceDayStr == null || targetDayStr == null) {
        return PlannerActionResult(
          success: true,
          message: _getMoveErrorMessage(langCode, 'days_required'),
        );
      }

      final sourceDay = _parseSingleDay(sourceDayStr);
      final targetDay = _parseSingleDay(targetDayStr);

      if (sourceDay == null || targetDay == null) {
        return PlannerActionResult(
          success: true,
          message: _getMoveErrorMessage(langCode, 'invalid_day'),
        );
      }

      // Trouver le workout à déplacer
      final workout = await WeeklyPlannerService.findPlannedWorkoutForDate(sourceDay);
      if (workout == null) {
        return PlannerActionResult(
          success: true,
          message: _getMoveErrorMessage(langCode, 'no_workout_source'),
        );
      }

      // Vérifier si le jour cible est libre
      final hasWorkoutOnTarget = await WeeklyPlannerService.hasWorkoutForDate(targetDay);
      if (hasWorkoutOnTarget) {
        return PlannerActionResult(
          success: true,
          message: _getMoveErrorMessage(langCode, 'day_occupied'),
        );
      }

      // Déplacer le workout
      final success = await WeeklyPlannerService.movePlannedWorkout(workout.id, targetDay);
      if (!success) {
        return PlannerActionResult.error(
          _getMoveErrorMessage(langCode, 'move_failed'),
        );
      }

      final sourceDayName = _formatDayName(sourceDay, langCode);
      final targetDayName = _formatDayName(targetDay, langCode);

      return PlannerActionResult.success(
        responseMessage ?? _getMoveSuccessMessage(langCode, workout.workoutName, sourceDayName, targetDayName),
        items: [targetDayName],
      );
    } catch (e) {
      debugPrint('❌ _handleMoveWorkoutRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
    }
  }

  /// Gérer une demande de suppression de workout
  static Future<PlannerActionResult> _handleDeleteWorkoutRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final deleteDayStr = info['delete_day'] as String?;
      final responseMessage = info['response_message'] as String?;

      if (deleteDayStr == null) {
        return PlannerActionResult(
          success: true,
          message: _getDeleteErrorMessage(langCode, 'day_required'),
        );
      }

      final deleteDay = _parseSingleDay(deleteDayStr);
      if (deleteDay == null) {
        return PlannerActionResult(
          success: true,
          message: _getDeleteErrorMessage(langCode, 'invalid_day'),
        );
      }

      // Trouver le workout à supprimer
      final workout = await WeeklyPlannerService.findPlannedWorkoutForDate(deleteDay);
      if (workout == null) {
        return PlannerActionResult(
          success: true,
          message: _getDeleteErrorMessage(langCode, 'no_workout'),
        );
      }

      // Supprimer le workout
      final success = await WeeklyPlannerService.deletePlannedWorkout(workout.id);
      if (!success) {
        return PlannerActionResult.error(
          _getDeleteErrorMessage(langCode, 'delete_failed'),
        );
      }

      final dayName = _formatDayName(deleteDay, langCode);

      return PlannerActionResult.success(
        responseMessage ?? _getDeleteSuccessMessage(langCode, workout.workoutName, dayName),
        items: [dayName],
      );
    } catch (e) {
      debugPrint('❌ _handleDeleteWorkoutRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
    }
  }

  /// Gérer une demande de modification de workout
  static Future<PlannerActionResult> _handleModifyWorkoutRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      // Pour l'instant, on supprime l'ancien workout et on en crée un nouveau
      // L'IA devrait avoir inclus 'delete_day' et 'workouts' dans l'info
      final modifyDayStr = info['delete_day'] as String? ?? info['source_day'] as String?;

      if (modifyDayStr != null) {
        final modifyDay = _parseSingleDay(modifyDayStr);
        if (modifyDay != null) {
          // Supprimer l'ancien workout
          final existingWorkout = await WeeklyPlannerService.findPlannedWorkoutForDate(modifyDay);
          if (existingWorkout != null) {
            await WeeklyPlannerService.deletePlannedWorkout(existingWorkout.id);
          }
        }
      }

      // Créer le nouveau workout via le handler standard
      return await _handleWorkoutRequest(info, langCode);
    } catch (e) {
      debugPrint('❌ _handleModifyWorkoutRequest error: $e');
      return PlannerActionResult.error(
        _getErrorMessage(langCode, 'workout_error'),
      );
    }
  }

  /// Messages d'erreur pour les templates
  static String _getTemplateErrorMessage(String langCode, String key) {
    final messages = {
      'template_not_found': {
        'fr': 'Je n\'ai pas trouvé cette séance. Vérifie le nom exact.',
        'en': 'I couldn\'t find that workout. Check the exact name.',
        'de': 'Ich konnte dieses Training nicht finden. Überprüfe den genauen Namen.',
      },
      'day_required': {
        'fr': 'Quel jour veux-tu planifier cette séance ?',
        'en': 'Which day do you want to schedule this workout?',
        'de': 'An welchem Tag möchtest du dieses Training planen?',
      },
      'invalid_day': {
        'fr': 'Ce jour n\'est pas valide. Choisis un jour de cette semaine.',
        'en': 'That day is not valid. Choose a day this week.',
        'de': 'Dieser Tag ist nicht gültig. Wähle einen Tag dieser Woche.',
      },
      'day_occupied': {
        'fr': 'Il y a déjà une séance ce jour-là. Veux-tu la remplacer ?',
        'en': 'There\'s already a workout that day. Do you want to replace it?',
        'de': 'An diesem Tag gibt es bereits ein Training. Möchtest du es ersetzen?',
      },
      'template_empty': {
        'fr': 'Cette séance n\'a pas d\'exercices. Choisis-en une autre.',
        'en': 'This workout has no exercises. Choose another one.',
        'de': 'Dieses Training hat keine Übungen. Wähle ein anderes.',
      },
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  /// Message de succès pour les templates
  static String _getTemplateSuccessMessage(String langCode, String workoutName, String dayName) {
    final messages = {
      'fr': '"$workoutName" planifié pour $dayName 💪',
      'en': '"$workoutName" scheduled for $dayName 💪',
      'de': '"$workoutName" für $dayName geplant 💪',
    };
    return messages[langCode] ?? messages['en']!;
  }

  /// Messages d'erreur pour le déplacement
  static String _getMoveErrorMessage(String langCode, String key) {
    final messages = {
      'days_required': {
        'fr': 'De quel jour à quel jour veux-tu déplacer la séance ?',
        'en': 'From which day to which day do you want to move the workout?',
        'de': 'Von welchem Tag zu welchem Tag möchtest du das Training verschieben?',
      },
      'invalid_day': {
        'fr': 'Un des jours n\'est pas valide.',
        'en': 'One of the days is not valid.',
        'de': 'Einer der Tage ist nicht gültig.',
      },
      'no_workout_source': {
        'fr': 'Il n\'y a pas de séance ce jour-là à déplacer.',
        'en': 'There\'s no workout on that day to move.',
        'de': 'An diesem Tag gibt es kein Training zum Verschieben.',
      },
      'day_occupied': {
        'fr': 'Le jour de destination a déjà une séance. Supprime-la d\'abord.',
        'en': 'The destination day already has a workout. Delete it first.',
        'de': 'Der Zieltag hat bereits ein Training. Lösche es zuerst.',
      },
      'move_failed': {
        'fr': 'Impossible de déplacer la séance. Réessaie.',
        'en': 'Couldn\'t move the workout. Try again.',
        'de': 'Das Training konnte nicht verschoben werden. Versuche es erneut.',
      },
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  /// Message de succès pour le déplacement
  static String _getMoveSuccessMessage(String langCode, String workoutName, String from, String to) {
    final messages = {
      'fr': '"$workoutName" déplacé de $from à $to ✓',
      'en': '"$workoutName" moved from $from to $to ✓',
      'de': '"$workoutName" von $from nach $to verschoben ✓',
    };
    return messages[langCode] ?? messages['en']!;
  }

  /// Messages d'erreur pour la suppression
  static String _getDeleteErrorMessage(String langCode, String key) {
    final messages = {
      'day_required': {
        'fr': 'Quel jour veux-tu supprimer la séance ?',
        'en': 'Which day do you want to delete the workout from?',
        'de': 'Von welchem Tag möchtest du das Training löschen?',
      },
      'invalid_day': {
        'fr': 'Ce jour n\'est pas valide.',
        'en': 'That day is not valid.',
        'de': 'Dieser Tag ist nicht gültig.',
      },
      'no_workout': {
        'fr': 'Il n\'y a pas de séance ce jour-là.',
        'en': 'There\'s no workout on that day.',
        'de': 'An diesem Tag gibt es kein Training.',
      },
      'delete_failed': {
        'fr': 'Impossible de supprimer la séance. Réessaie.',
        'en': 'Couldn\'t delete the workout. Try again.',
        'de': 'Das Training konnte nicht gelöscht werden. Versuche es erneut.',
      },
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  /// Message de succès pour la suppression
  static String _getDeleteSuccessMessage(String langCode, String workoutName, String dayName) {
    final messages = {
      'fr': '"$workoutName" supprimé de $dayName ✓',
      'en': '"$workoutName" deleted from $dayName ✓',
      'de': '"$workoutName" von $dayName gelöscht ✓',
    };
    return messages[langCode] ?? messages['en']!;
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
      final weekStart = getCurrentWeekStart();
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
        if (!day.isBefore(today) && !daysWithWorkout.contains(day.weekday)) {
          availableDays.add(dayNames[i]);
        }
      }

      // Récupérer l'historique des performances (30 derniers jours)
      final performanceHistory = await _getPerformanceHistory(client, user.id);

      // Récupérer les templates sauvegardés par l'utilisateur
      final userTemplates = await _getUserWorkoutTemplates(client, user.id);

      // Formater les workouts planifiés cette semaine (pour move/delete/modify)
      final plannedWorkoutsThisWeek = _formatPlannedWorkouts(existingData.workouts, langCode);

      // Formater les cardios planifiés cette semaine
      final plannedCardioThisWeek = _formatPlannedCardio(existingData.activities, langCode);

      // Formater les repas planifiés cette semaine
      final plannedMealsThisWeek = _formatPlannedMeals(existingData.activities, langCode);

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
        'fitness_goal': user.fitnessGoal ?? 'general_fitness',
        'activity_level': user.activityLevel ?? 'moderate',
        'gender': user.gender ?? 'unknown',
        'weight_kg': user.weight,
        'available_days': availableDays,
        'days_with_workout': daysWithWorkout.map((d) => dayNames[d - 1]).toList(),
        'days_with_cardio': daysWithCardio.map((d) => dayNames[d - 1]).toList(),
        'exercises_already_planned': plannedExercises.toSet().toList(),
        'performance_history': performanceHistory,
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
      };
    } catch (e) {
      debugPrint('❌ _getUserContext error: $e');
      return {};
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

  /// Récupérer l'historique des performances de l'utilisateur (poids utilisés par exercice)
  /// Note: Cette fonction est désactivée temporairement car les requêtes imbriquées
  /// ne fonctionnent pas avec le schéma actuel. L'IA fonctionne sans ces données.
  static Future<List<Map<String, dynamic>>> _getPerformanceHistory(
    SupabaseClient client,
    String userId,
  ) async {
    // Désactivé temporairement - retourne une liste vide
    // L'historique des performances sera récupéré via AIWorkoutGenerationService
    return [];
  }

  /// Prompt spécialisé pour la planification des REPAS uniquement
  static Future<String> _buildMealsIntentPrompt(String userMessage, String langCode) async {
    final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';
    final context = await _getNutritionContext();
    final plannedWorkouts = await _getPlannedWorkoutsForWeek();
    final dietaryRestrictions = context['dietary_restrictions'] ?? 'None';

    return '''
You are Ryze, an expert NUTRITION coach AI. You help plan SPECIFIC meals with estimated macros.

## Your Specialty
You create detailed meal plans with:
- SPECIFIC dish names and descriptions
- Accurate macro estimates (calories, proteins, carbs, fats)
- Meal types: breakfast, lunch, dinner, snack

You CANNOT help with workouts or cardio. If asked, redirect politely.

## User Nutritional Profile
- Daily Calorie Target: ${context['calorie_target'] ?? 2000} kcal
- Daily Macros: ${context['protein_target'] ?? 100}g protein, ${context['carbs_target'] ?? 250}g carbs, ${context['fats_target'] ?? 70}g fats
- Fitness Goal: ${context['fitness_goal'] ?? 'general fitness'}
- Dietary Restrictions: $dietaryRestrictions

## Today's Status
- Calories consumed: ${context['calories_today'] ?? 0} kcal
- Remaining: ${context['remaining_calories'] ?? context['calorie_target'] ?? 2000} kcal

## This Week's Planned Workouts (adjust carbs on training days)
$plannedWorkouts

## Available Days This Week
${context['available_days'] ?? ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']}

## User Request
"$userMessage"

## Response Format (JSON)
{
  "intent": "meal",
  "is_complete": true | false,
  "meals": [
    {
      "day": "monday",
      "meal_type": "breakfast",
      "dish_name": "Short name (max 25 chars)",
      "dish_description": "Main ingredients list",
      "calories": 450,
      "proteins": 32.0,
      "carbs": 15.0,
      "fats": 28.0,
      "quantity_g": 300,
      "reasoning": "Brief explanation why this fits their goals"
    }
  ],
  "response_message": "Friendly message in $languageName summarizing what you're proposing",
  "follow_up_question": "Only if is_complete=false (in $languageName)"
}

## CRITICAL Rules
1. EACH dish is a SEPARATE entry in the meals array
2. Provide REALISTIC macro estimates based on typical portions
3. On workout days: increase carbs (+20%), reduce fats slightly
4. RESPECT dietary restrictions STRICTLY (vegetarian, vegan, allergies, etc.)
5. Provide VARIED meals - no repetition within the same week
6. Meal order in response: breakfast → lunch → snack → dinner
7. MAXIMUM calories per meal:
   - Breakfast: ~25% of daily target
   - Lunch: ~35% of daily target
   - Dinner: ~30% of daily target
   - Snack: ~10% of daily target
8. If user asks for "une semaine de repas", generate ALL 4 meal types for remaining days
9. ASK for clarification if meal type or days not specified
10. 🔴 RESPECT USER'S SPECIFIC FOOD - If user mentions a specific food (whey, chicken, salmon, etc.), you MUST use THAT food in the dish! Example: "30g de whey" = create a dish WITH whey protein, NOT something else!

## Examples

User: "Un petit-déj protéiné pour demain"
→ Single breakfast entry with high protein (~30g+)

User: "Planifie mes repas de la semaine"
→ All 4 meal types for all remaining days (up to 28 entries)

User: "Déjeuner et dîner pour lundi et mardi"
→ 4 entries (lunch + dinner for both days)

User: "30g de whey pour ma collation"
→ Single snack entry WITH whey protein (e.g., "Whey Protein Shake" with 30g whey, ~120kcal, ~24g protein)
→ NEVER substitute whey with eggs or other food!

User: "3 séances de musculation"
→ intent: "unknown", redirect to workout button
''';
  }

  /// Prompt spécialisé pour la planification des SÉANCES uniquement
  static Future<String> _buildWorkoutsIntentPrompt(String userMessage, String langCode) async {
    final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';
    final context = await _getUserContext();

    // Formater l'historique des performances
    final performanceHistory = context['performance_history'] as List? ?? [];
    final performanceStr = performanceHistory.isNotEmpty
        ? performanceHistory.map((p) =>
            "• ${p['exercise']}: ${p['typical_weight_kg']}kg typical, ${p['best_weight_kg']}kg PR (${p['best_reps']} reps)"
          ).join('\n')
        : 'No history yet (new user)';

    return '''
You are Ryze, an expert FITNESS coach AI. You ONLY help with workout and cardio planning.

## Your Specialty
You are a fitness specialist. You can ONLY plan:
- Strength training sessions (musculation / Krafttraining)
- Cardio sessions (running, cycling, swimming, HIIT, etc.)
- Sports activities

You CANNOT help with meal planning or nutrition. If the user asks about food/meals, politely redirect them.

## User Fitness Context
- Fitness Goal: ${context['fitness_goal'] ?? 'general fitness'}
- Activity Level: ${context['activity_level'] ?? 'moderate'}
- Gender: ${context['gender'] ?? 'unknown'}
- Body Weight: ${context['weight_kg'] ?? 'unknown'} kg

## This Week's Planned Workouts (can be moved/deleted/modified)
${context['planned_workouts_this_week'] ?? 'No workouts planned yet'}

## Available Days This Week (no workout yet)
${context['available_days'] ?? []}

## User's Saved Workout Templates (can be reused)
${context['user_templates'] ?? 'No saved templates'}

## User's Performance History (last 30 days)
$performanceStr

${_getFormattedHistory()}
## User Request
"$userMessage"

## Response Format (JSON)
{
  "intent": "workout" | "cardio" | "use_template" | "move_workout" | "delete_workout" | "modify_workout",
  "is_complete": true | false,
  "extracted_info": {
    // For NEW workout generation:
    "clear_week_first": true | false,  // Set to true if user wants to DELETE ALL existing workouts first (e.g. "enlève tout et programme...")
    "workouts": [
      {
        "day": "monday" | "tuesday" | etc,
        "workout_type": "SHORT name IN $languageName (e.g. 'Haut du corps', 'Jambes', 'Full Body', 'Push')",
        "workout_prompt": "detailed prompt for generating this specific workout IN ENGLISH (for the AI generator)",
        "duration_minutes": integer (any value between 15-120, use user's exact request)
      }
    ],
    // For USING an existing template:
    "template_id": "uuid of the template to use",
    "template_name": "name of the template",
    "target_day": "monday" | "tuesday" | etc,
    // For MOVING a workout:
    "source_day": "current day of the workout",
    "target_day": "new day to move to",
    // For DELETING a workout:
    "delete_day": "day of workout to delete",  // Use "all" to delete ALL workouts this week
    // For cardio:
    "cardio_sessions": [
      {
        "day": "monday",
        "activity_name": "Running",
        "activity_key": "running",
        "target_minutes": 30,
        "target_km": 5
      }
    ]
  },
  "response_message": "friendly message in $languageName explaining the program",
  "follow_up_question": "only if you need more info (in $languageName)"
}

## CRITICAL: is_complete rules
Set "is_complete": false and ask a follow_up_question if ANY of these are missing:
- Duration not specified for NEW workouts (ask: "Combien de temps pour cette séance ?" or "Combien de temps par séance ?")
- Day not specified (ask: "Quel jour ?")
- Workout type unclear (ask what kind of training)

ONLY set "is_complete": true when you have ALL required info to generate/execute the action!

## IMPORTANT - workout_type language
The "workout_type" field MUST be in $languageName:
- French: "Haut du corps", "Bas du corps", "Jambes", "Dos & Biceps", "Pectoraux & Triceps", "Épaules", "Full Body", "Push", "Pull"
- English: "Upper Body", "Lower Body", "Legs", "Back & Biceps", "Chest & Triceps", "Shoulders", "Full Body", "Push", "Pull"
- German: "Oberkörper", "Unterkörper", "Beine", "Rücken & Bizeps", "Brust & Trizeps", "Schultern", "Ganzkörper", "Push", "Pull"

## IMPORTANT - Duration
If the user doesn't specify duration, ask them! Default durations by type:
- Quick workout: 30 min
- Standard workout: 45 min
- Full workout: 60 min
- Long/detailed workout: 90 min

Ask about duration ONLY if not specified. Adapt your question to the context:
- ONE session: "Combien de temps pour cette séance ?" / "How long for this session?"
- MULTIPLE sessions: "Combien de temps par séance ?" / "How long per session?"
NEVER use "chaque séance" if the user only asked for ONE session!

## Rules
1. If user asks about meals/food, return intent: "unknown" with a polite redirection message
2. Space workouts 48-72h apart for recovery
3. Adapt to user's gender (more glutes/hamstrings for women, more upper body for men)
4. Use their performance history to suggest appropriate weights
5. AVOID exercises already planned this week - provide variety
6. **CRITICAL**: COMPLETED sessions count towards weekly totals! If user says "3 sessions this week" and 1 is already completed, only plan 2 more
7. **CRITICAL**: Only plan on FUTURE days (today or later). Never plan on past days
8. When planning complementary sessions to existing ones, ensure muscle group balance (don't repeat same muscles within 48h)

## Gender-Specific Adaptations
For WOMEN: More emphasis on glutes, hamstrings, core. Include hip thrusts, glute bridges, RDLs.
For MEN: More emphasis on chest, back, shoulders. Include bench press, rows, overhead press.

## Examples

User: "3 séances de muscu cette semaine"
→ intent: "workout", create optimized 3-day program based on their goal/gender

User: "Du cardio mardi et jeudi"
→ intent: "cardio", plan cardio sessions for those days

User: "Supprime ma séance de lundi" / "Delete my Monday workout"
→ intent: "delete_workout", delete_day: "monday", is_complete: true

User: "Enlève la séance du mardi" / "Remove Tuesday's session"
→ intent: "delete_workout", delete_day: "tuesday", is_complete: true

User: "Décale ma séance de lundi à mercredi" / "Move my Monday workout to Wednesday"
→ intent: "move_workout", source_day: "monday", target_day: "wednesday", is_complete: true

User: "Met ma séance A mardi" / "Put my Session A on Tuesday"
→ intent: "use_template", search for template named "Séance A" in user_templates, target_day: "tuesday"

User: "Remplace la séance de mardi par du full body"
→ intent: "modify_workout", current_day: "tuesday", new_workout_type: "Full Body"
IMPORTANT: Use ONLY modify_workout, do NOT call delete_workout first!

User: "Enlève toutes mes séances et programme 5 séances" / "Clear my week and add 5 workouts"
→ intent: "workout", clear_week_first: true, workouts: [...5 workouts for different days...]
IMPORTANT: When user says "enlève tout" + "programme X séances", use intent "workout" with clear_week_first: true, NOT delete_workout!

User: "Supprime tout et refais moi un programme push/pull/legs"
→ intent: "workout", clear_week_first: true, workouts: [...PPL split workouts...]

User: "Un petit-déjeuner protéiné"
→ intent: "unknown", message: "Je suis ton coach fitness ! Pour les repas, utilise le bouton 'Planifier mes repas'. Ici, dis-moi quelle séance tu veux planifier 💪"
''';
  }

  /// Récupérer le contexte nutritionnel de l'utilisateur
  static Future<Map<String, dynamic>> _getNutritionContext() async {
    try {
      final user = AuthService().currentUser;
      if (user == null) return {};

      // Récupérer les objectifs caloriques
      final calorieTarget = user.dailyCalories ?? 2000;
      final proteinTarget = ((calorieTarget * 0.25) / 4).round(); // 25% des calories
      final carbsTarget = ((calorieTarget * 0.45) / 4).round(); // 45% des calories
      final fatsTarget = ((calorieTarget * 0.30) / 9).round(); // 30% des calories

      // Récupérer les préférences alimentaires (allergies, restrictions)
      String dietaryRestrictions = 'None';
      try {
        final prefs = await CoachPreferenceExtractor.instance.getUserPreferences();
        if (prefs != null) {
          final restrictions = <String>[];
          if (prefs.allergies.isNotEmpty) {
            restrictions.addAll(prefs.allergies.map((a) => 'allergic to $a'));
          }
          if (prefs.dietaryRestrictions.isNotEmpty) {
            restrictions.addAll(prefs.dietaryRestrictions);
          }
          if (restrictions.isNotEmpty) {
            dietaryRestrictions = restrictions.join(', ');
          }
        }
      } catch (_) {
        // Ignorer si erreur - utiliser la valeur par défaut
      }

      // Récupérer les calories consommées aujourd'hui
      int caloriesToday = 0;
      try {
        final todayMeals = await FoodEntriesService.getFoodEntriesForDate(
          user.id,
          DateTime.now(),
        );
        // Sommer les calories de tous les items de tous les repas
        for (final meal in todayMeals) {
          for (final item in meal.items) {
            caloriesToday += item.calories;
          }
        }
      } catch (_) {
        // Ignorer si erreur réseau
      }

      // Jours disponibles
      final weekStart = getCurrentWeekStart();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final availableDays = <String>[];
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        if (!day.isBefore(today)) {
          availableDays.add(dayNames[i]);
        }
      }

      return {
        'calorie_target': calorieTarget,
        'protein_target': proteinTarget,
        'carbs_target': carbsTarget,
        'fats_target': fatsTarget,
        'fitness_goal': user.fitnessGoal ?? 'general_fitness',
        'calories_today': caloriesToday,
        'remaining_calories': calorieTarget - caloriesToday,
        'available_days': availableDays,
        'dietary_restrictions': dietaryRestrictions,
      };
    } catch (e) {
      debugPrint('❌ _getNutritionContext error: $e');
      return {};
    }
  }

  /// Récupérer les workouts planifiés cette semaine (pour adapter les glucides)
  static Future<String> _getPlannedWorkoutsForWeek() async {
    try {
      final data = await WeeklyPlannerService.getWeekData();
      if (data.workouts.isEmpty) {
        return 'No workouts planned this week';
      }

      final buffer = StringBuffer();
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

      for (final workout in data.workouts) {
        final dayIndex = workout.plannedDate.weekday - 1;
        final dayName = dayNames[dayIndex];
        buffer.writeln('• $dayName: ${workout.workoutName} (${workout.durationMinutes ?? 45}min)');
      }

      // Ajouter les cardios aussi
      final cardios = data.activities.where((a) => a.activityType == PlannedActivityType.cardio).toList();
      for (final cardio in cardios) {
        final dayIndex = cardio.plannedDate.weekday - 1;
        final dayName = dayNames[dayIndex];
        final cardioData = cardio.cardioData;
        if (cardioData != null) {
          buffer.writeln('• $dayName: ${cardioData.activityName} (${cardioData.targetMinutes ?? 30}min cardio)');
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint('❌ _getPlannedWorkoutsForWeek error: $e');
      return 'Unable to fetch planned workouts';
    }
  }

  static Future<String> _buildIntentPrompt(String userMessage, String langCode) async {
    final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';
    final context = await _getUserContext();

    // Formater l'historique des performances
    final performanceHistory = context['performance_history'] as List? ?? [];
    final performanceStr = performanceHistory.isNotEmpty
        ? performanceHistory.map((p) =>
            "• ${p['exercise']}: ${p['typical_weight_kg']}kg typical, ${p['best_weight_kg']}kg PR (${p['best_reps']} reps)"
          ).join('\n')
        : 'No history yet (new user)';

    return '''
You are Ryze, an expert fitness coach AI. Analyze the user's request and create an INTELLIGENT workout program.

## User Context
- Fitness Goal: ${context['fitness_goal'] ?? 'general fitness'}
- Activity Level: ${context['activity_level'] ?? 'moderate'}
- Gender: ${context['gender'] ?? 'unknown'}
- Body Weight: ${context['weight_kg'] ?? 'unknown'} kg
- Days already with workout this week: ${context['days_with_workout'] ?? []}
- Available days this week: ${context['available_days'] ?? []}
- Exercises already planned this week: ${context['exercises_already_planned'] ?? []}

## User's Performance History (last 30 days)
$performanceStr

## User Request
"$userMessage"

## Your Task
Based on the user's request and context, create an optimal workout program. YOU decide:
1. How many sessions (based on their goal and request)
2. Which days (from available days, well-spaced for recovery)
3. What type of workout for EACH day (tailored to their specific goal)

## Response Format (JSON)
{
  "intent": "workout" | "cardio" | "meal" | "unknown",
  "is_complete": true | false,
  "extracted_info": {
    // For workout - YOU CREATE THE OPTIMAL PROGRAM:
    "workouts": [
      {
        "day": "monday" | "tuesday" | etc,
        "workout_type": "string describing the focus (e.g., 'Glutes & Hamstrings', 'Push - Chest focus', 'Full Body')",
        "workout_prompt": "detailed prompt for generating this specific workout",
        "duration_minutes": 45
      }
    ],

    // For cardio:
    "cardio_sessions": [
      {
        "day": "monday",
        "activity_name": "Running",
        "activity_key": "running",
        "target_minutes": 30,
        "target_km": 5
      }
    ],

    // For meal:
    "food_description": "string",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "days": ["monday", ...]
  },
  "response_message": "friendly message in $languageName explaining what you created and why",
  "follow_up_question": "only if you need critical info (in $languageName)"
}

## Intelligence Rules

### IMPORTANT: Exercises Already Planned
- Check "Exercises already planned this week" list
- AVOID repeating the same exercises if possible
- Provide VARIETY - use different exercises targeting same muscles
- Example: If "Squat" is already planned, use "Leg Press" or "Bulgarian Split Squat" instead

### Gender-Specific Adaptations
For WOMEN:
- More emphasis on glutes, hamstrings, and overall lower body
- Include hip thrusts, glute bridges, Romanian deadlifts
- For upper body: focus on toning (moderate weight, higher reps)
- Add core/ab work

For MEN:
- More emphasis on chest, back, shoulders
- Include bench press, rows, overhead press
- For legs: balanced quads/hamstrings/glutes
- Progressive overload focus

### For muscle-specific goals (e.g., "muscler mes fesses", "bigger arms"):
- Create 2-3 sessions focusing on that muscle group
- Include compound AND isolation exercises
- Space sessions 48-72h apart for recovery
- Example for glutes: Day1: Glutes & Quads, Day2: Glutes & Hamstrings, Day3: Full Lower Body

### For general fitness / weight loss:
- Mix of full body and cardio
- 3-4 sessions per week
- Variety to prevent boredom

### For muscle gain / strength:
- PPL or Upper/Lower split
- 4-5 sessions if available days allow
- Progressive overload focus

### For beginners (activity_level = sedentary/light):
- 2-3 Full Body sessions
- Lower intensity, focus on form
- More rest days

### For advanced (activity_level = very_active):
- Can handle 5-6 sessions
- More volume and intensity
- Specialized splits

### Weight Suggestions (use performance history)
- If user has history for an exercise, suggest weights based on their typical_weight_kg
- For new exercises without history, estimate based on similar exercises
- For new users: suggest conservative weights based on body weight

## Examples

User: "Je veux muscler mes fesses"
→ Create 3 glute-focused sessions:
  - Day 1: "Glutes & Quads" (squats, lunges, leg press, hip thrusts)
  - Day 2: "Glutes & Hamstrings" (RDL, hip thrusts, cable kickbacks, hamstring curls)
  - Day 3: "Glute Isolation" (hip thrusts, glute bridges, abductions, kickbacks)

User: "3 séances pour perdre du poids"
→ Create 3 fat-burning sessions:
  - Day 1: "Full Body HIIT Style" (compound movements, short rest)
  - Day 2: "Upper Body Circuit" (supersets, high reps)
  - Day 3: "Lower Body Metabolic" (leg circuits, finisher cardio)

User: "Programme pour prendre de la masse"
→ Create PPL or Upper/Lower based on available days

IMPORTANT:
- Always set is_complete: true if you can create a program
- Only ask follow_up_question if you REALLY need info (e.g., user says "sport" with no context)
- The response_message should be enthusiastic and explain the program logic
''';
  }

  static IntentAnalysis _parseIntentResponse(
    Map<String, dynamic> response,
    String langCode,
  ) {
    try {
      final intentStr = response['intent'] as String? ?? 'unknown';
      final isComplete = response['is_complete'] as bool? ?? false;
      final extractedInfo = response['extracted_info'] as Map<String, dynamic>? ?? {};
      final followUpQuestion = response['follow_up_question'] as String?;
      final responseMessage = response['response_message'] as String?;

      PlannerIntent intent;
      switch (intentStr.toLowerCase()) {
        case 'workout':
          intent = PlannerIntent.workout;
          break;
        case 'cardio':
          intent = PlannerIntent.cardio;
          break;
        case 'meal':
          intent = PlannerIntent.meal;
          break;
        case 'use_template':
          intent = PlannerIntent.useTemplate;
          break;
        case 'move_workout':
          intent = PlannerIntent.moveWorkout;
          break;
        case 'delete_workout':
          intent = PlannerIntent.deleteWorkout;
          break;
        case 'modify_workout':
          intent = PlannerIntent.modifyWorkout;
          break;
        default:
          intent = PlannerIntent.unknown;
      }

      // Parser les jours si présents (ancien format)
      if (extractedInfo['days'] != null) {
        final dayStrings = extractedInfo['days'] as List;
        extractedInfo['days'] = _parseDays(dayStrings.cast<String>());
      }

      // Parser le tableau meals au niveau racine (nouveau format pour meal intent)
      if (response['meals'] != null) {
        extractedInfo['meals'] = response['meals'];
      }

      // Ajouter le response_message dans extractedInfo pour le handler
      if (responseMessage != null) {
        extractedInfo['response_message'] = responseMessage;
      }

      return IntentAnalysis(
        intent: intent,
        extractedInfo: extractedInfo,
        followUpQuestion: followUpQuestion,
        responseMessage: responseMessage,
        isComplete: isComplete,
      );
    } catch (e) {
      debugPrint('❌ _parseIntentResponse error: $e');
      return IntentAnalysis(
        intent: PlannerIntent.unknown,
        extractedInfo: {},
        followUpQuestion: _getErrorMessage(langCode, 'parse_error'),
      );
    }
  }

  static Future<Map<String, dynamic>?> _callGeminiAPI(String prompt) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Utiliser le modèle plus performant pour le planner (gemini-2.5-flash)
        final url = Uri.parse(
          '${GeminiConfig.plannerApiUrl}?key=${GeminiConfig.geminiApiKey}',
        );

        final body = {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) {
          debugPrint('❌ Gemini API error (attempt $attempt/$maxRetries): ${response.statusCode}');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        final responseData = jsonDecode(response.body);
        final text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text == null) {
          debugPrint('⚠️ No text in Gemini response (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        // Extraire le JSON de la réponse
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch == null) {
          debugPrint('⚠️ No JSON in Gemini response (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return null;
        }

        return jsonDecode(jsonMatch.group(0)!);
      } catch (e) {
        debugPrint('❌ _callGeminiAPI error (attempt $attempt/$maxRetries): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        return null;
      }
    }

    return null;
  }

  // =====================================================
  // FUNCTION CALLING - Nouvelle approche
  // =====================================================

  /// Définition des tools disponibles pour le planner
  // Stocker la dernière action pour permettre l'annulation
  static Map<String, dynamic>? _lastAction;
  static List<Map<String, dynamic>>? _lastDeletedItems;

  // Action en attente de confirmation
  static Map<String, dynamic>? _pendingAction;

  // Actions supplémentaires à exécuter après confirmation
  static List<Map<String, dynamic>>? _pendingFollowUpActions;

  static List<Map<String, dynamic>> get _plannerTools => [
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
  static List<Map<String, dynamic>> get _mealTools => [
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
- breakfast: Morning meal - target ~20-25% daily calories
- lunch: Midday meal - target ~30-35% daily calories
- dinner: Evening meal - target ~30-35% daily calories
- snack: Light snack - target ~10-15% daily calories (optional)

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

        // Calculer les repas SUGGÉRÉS pour aujourd'hui selon l'heure
        // (utilisé uniquement pour les suggestions automatiques, pas pour bloquer l'utilisateur)
        final List<String> suggestedMealsToday = [];
        if (currentHour < 10) suggestedMealsToday.add('breakfast');
        if (currentHour < 14) suggestedMealsToday.add('lunch');
        if (currentHour < 21) suggestedMealsToday.add('dinner');
        suggestedMealsToday.add('snack');

        final suggestedMealsInfo = suggestedMealsToday.isEmpty
            ? 'snack only (late night)'
            : suggestedMealsToday.join(', ');

        // Calculer la distribution calorique et macros recommandée
        final dailyCalorieTarget = context['calorie_target'] ?? 2000;
        final dailyProteinTarget = (context['protein_target'] as num?)?.toDouble() ?? 100.0;
        final dailyCarbsTarget = (context['carbs_target'] as num?)?.toDouble() ?? 250.0;
        final dailyFatTarget = (context['fat_target'] as num?)?.toDouble() ?? 65.0;

        // Distribution par repas (25% breakfast, 35% lunch, 35% dinner, 5% snack)
        final breakfastCal = (dailyCalorieTarget * 0.25).round();
        final breakfastProt = (dailyProteinTarget * 0.25).round();
        final breakfastCarbs = (dailyCarbsTarget * 0.25).round();
        final breakfastFat = (dailyFatTarget * 0.25).round();

        final lunchCal = (dailyCalorieTarget * 0.35).round();
        final lunchProt = (dailyProteinTarget * 0.35).round();
        final lunchCarbs = (dailyCarbsTarget * 0.35).round();
        final lunchFat = (dailyFatTarget * 0.35).round();

        final dinnerCal = (dailyCalorieTarget * 0.35).round();
        final dinnerProt = (dailyProteinTarget * 0.35).round();
        final dinnerCarbs = (dailyCarbsTarget * 0.35).round();
        final dinnerFat = (dailyFatTarget * 0.35).round();

        final snackCal = (dailyCalorieTarget * 0.05).round();
        final snackProt = (dailyProteinTarget * 0.05).round();
        final snackCarbs = (dailyCarbsTarget * 0.05).round();
        final snackFat = (dailyFatTarget * 0.05).round();

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

DAILY TARGETS:
- Calories: $dailyCalorieTarget kcal
- Proteins: ${dailyProteinTarget.round()}g
- Carbs: ${dailyCarbsTarget.round()}g
- Fats: ${dailyFatTarget.round()}g

🔴 TARGET MACROS PER MEAL (aim for these ranges, NOT exact values!):
┌─────────────┬──────────────────┬──────────────────┬──────────────────┬──────────────────┐
│ Meal        │ Calories         │ Proteins         │ Carbs            │ Fats             │
├─────────────┼──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ breakfast   │ ${(breakfastCal * 0.9).round()}-${(breakfastCal * 1.1).round()} kcal │ ${(breakfastProt * 0.85).round()}-${(breakfastProt * 1.15).round()}g │ ${(breakfastCarbs * 0.85).round()}-${(breakfastCarbs * 1.15).round()}g │ ${(breakfastFat * 0.85).round()}-${(breakfastFat * 1.15).round()}g │
│ lunch       │ ${(lunchCal * 0.9).round()}-${(lunchCal * 1.1).round()} kcal │ ${(lunchProt * 0.85).round()}-${(lunchProt * 1.15).round()}g │ ${(lunchCarbs * 0.85).round()}-${(lunchCarbs * 1.15).round()}g │ ${(lunchFat * 0.85).round()}-${(lunchFat * 1.15).round()}g │
│ dinner      │ ${(dinnerCal * 0.9).round()}-${(dinnerCal * 1.1).round()} kcal │ ${(dinnerProt * 0.85).round()}-${(dinnerProt * 1.15).round()}g │ ${(dinnerCarbs * 0.85).round()}-${(dinnerCarbs * 1.15).round()}g │ ${(dinnerFat * 0.85).round()}-${(dinnerFat * 1.15).round()}g │
│ snack       │ ${(snackCal * 0.8).round()}-${(snackCal * 1.2).round()} kcal │ ${(snackProt * 0.8).round()}-${(snackProt * 1.2).round()}g │ ${(snackCarbs * 0.8).round()}-${(snackCarbs * 1.2).round()}g │ ${(snackFat * 0.8).round()}-${(snackFat * 1.2).round()}g │
└─────────────┴──────────────────┴──────────────────┴──────────────────┴──────────────────┘

⚠️ IMPORTANT - REALISTIC MACROS:
- Use REALISTIC quantities (100g, 150g, 2 eggs, 1 chicken breast) NOT decimal values (127.3g)
- Each meal's macros should vary naturally based on the actual recipe
- Daily totals should be within 90-110% of target (${(dailyCalorieTarget * 0.9).round()}-${(dailyCalorieTarget * 1.1).round()} kcal)
- It's OK if each day has slightly different totals - that's realistic!
- Prioritize recipe authenticity over hitting exact numbers

TODAY'S INTAKE (already consumed):
- Calories: ${context['today_calories'] ?? 0}/$dailyCalorieTarget kcal
- Remaining today: ${context['remaining_calories'] ?? dailyCalorieTarget} kcal

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
        tools = _mealTools;
      } else {
        // Mode sport (défaut) : utiliser le prompt fitness
        tools = _plannerTools;
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
              'mode': 'ANY',  // Force the model to call at least one function
            }
          },
          'generationConfig': {
            'temperature': 0.4,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192, // Increased to allow full week meal planning (21+ function calls)
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
            durationMinutes: duration,
          );

          if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
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
          final weekStart = getCurrentWeekStart();
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
            final weekStart = getCurrentWeekStart();
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
              durationMinutes: duration,
            );

            if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
              // Sauvegarder directement
              await WeeklyPlannerService.addPlannedWorkout(
                plannedDate: currentDay,
                workoutName: '$newType - ${duration}min',
                exercises: result.exercises!,
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
            // Supprimer le workout existant
            await WeeklyPlannerService.deletePlannedWorkout(existingWorkout.id);
            // Déterminer le type de cardio
            final dayStr = _getDayString(currentDay);
            String activityKey = 'running'; // Par défaut
            if (lowerType.contains('bike') || lowerType.contains('vélo') || lowerType.contains('velo') || lowerType.contains('cycling')) {
              activityKey = 'bike';
            } else if (lowerType.contains('walk') || lowerType.contains('marche')) {
              activityKey = 'walking';
            } else if (lowerType.contains('swim') || lowerType.contains('natation') || lowerType.contains('nager')) {
              activityKey = 'swimming';
            }
            return await _executeToolCall('create_cardio', {
              'day': dayStr,
              'activity': activityKey,
            }, langCode);
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
            durationMinutes: duration,
          );

          if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
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
          final errorMsg = langCode == 'fr'
              ? '❌ Type d\'activité non reconnu: $activityKey\nEssaie: course, vélo, marche'
              : '❌ Unknown activity type: $activityKey\nTry: running, bike, walking';
          return {'success': false, 'message': errorMsg};
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

  /// Générer le message de preview pour les repas
  static String _getMealsPreviewMessage(String langCode, List<PendingMeal> meals) {
    final buffer = StringBuffer();

    if (langCode == 'fr') {
      buffer.writeln('📋 **Voici les repas que je vais ajouter :**\n');
    } else if (langCode == 'de') {
      buffer.writeln('📋 **Hier sind die Mahlzeiten, die ich hinzufügen werde:**\n');
    } else {
      buffer.writeln('📋 **Here are the meals I will add:**\n');
    }

    // Grouper par jour
    final mealsByDay = <DateTime, List<PendingMeal>>{};
    for (final meal in meals) {
      final date = DateTime(meal.plannedDate.year, meal.plannedDate.month, meal.plannedDate.day);
      mealsByDay[date] = mealsByDay[date] ?? [];
      mealsByDay[date]!.add(meal);
    }

    // Trier les jours
    final sortedDays = mealsByDay.keys.toList()..sort();

    for (final day in sortedDays) {
      final dayName = _formatDayName(day, langCode);
      buffer.writeln('**$dayName:**');

      // Calculer le total du jour
      final dayMeals = mealsByDay[day]!;
      final dayProteins = dayMeals.fold<double>(0, (sum, m) => sum + m.proteins);
      final dayCarbs = dayMeals.fold<double>(0, (sum, m) => sum + m.carbs);
      final dayFats = dayMeals.fold<double>(0, (sum, m) => sum + m.fats);

      for (final meal in dayMeals) {
        final mealTypeName = _getMealTypeName(meal.mealType, langCode);
        final mealCalc = ((meal.proteins * 4) + (meal.carbs * 4) + (meal.fats * 9)).round();
        buffer.writeln('  • $mealTypeName: ${meal.dishName}');
        buffer.writeln('    ~$mealCalc kcal | ${'proteins'.tr(langCode)[0]}: ${meal.proteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${meal.carbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${meal.fats.toInt()}g');
      }

      // Total du jour - recalculer les calories
      final dayCaloriesCalc = dayMeals.fold<int>(0, (sum, m) => sum + ((m.proteins * 4) + (m.carbs * 4) + (m.fats * 9)).round());
      buffer.writeln('  📊 **Total jour:** ~$dayCaloriesCalc kcal | ${'proteins'.tr(langCode)[0]}: ${dayProteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${dayCarbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${dayFats.toInt()}g');
      buffer.writeln();
    }

    if (langCode == 'fr') {
      buffer.writeln('✅ Confirmes-tu ces repas ?');
    } else if (langCode == 'de') {
      buffer.writeln('✅ Bestätigst du diese Mahlzeiten?');
    } else {
      buffer.writeln('✅ Do you confirm these meals?');
    }

    return buffer.toString();
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
      final oldMealResult = await Supabase.instance.client
          .from('planned_activities')
          .select()
          .eq('user_id', user.id)
          .eq('activity_type', mealType.value)
          .gte('planned_date', startOfDay.toIso8601String().split('T')[0])
          .lt('planned_date', endOfDay.toIso8601String().split('T')[0])
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

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final normalizedStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
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

  /// Obtient la description de la prochaine action en attente
  static String? _getNextActionDescription(String langCode) {
    if (_pendingFollowUpActions == null || _pendingFollowUpActions!.isEmpty) {
      return null;
    }
    final next = _pendingFollowUpActions!.first;
    final nextName = next['name'] as String;
    final nextRawArgs = next['args'];
    final Map<String, dynamic> nextArgs = nextRawArgs is Map
        ? Map<String, dynamic>.from(nextRawArgs)
        : {};
    return _buildConfirmationMessage(nextName, nextArgs, langCode);
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

  /// Générer un message de succès spécifique pour le cardio
  static String _getCardioSuccessMessage(String langCode, String activityName, int? duration, double? distance, String dayName) {
    // Construire la partie détails
    String details = '';
    if (distance != null && duration != null) {
      // Les deux fournis
      details = langCode == 'fr' ? '${distance.toStringAsFixed(1)} km / $duration min'
          : langCode == 'de' ? '${distance.toStringAsFixed(1)} km / $duration min'
          : '${distance.toStringAsFixed(1)} km / $duration min';
    } else if (distance != null) {
      details = '${distance.toStringAsFixed(1)} km';
    } else if (duration != null) {
      details = '$duration min';
    }

    // Construire le message
    if (langCode == 'fr') {
      return '✅ $activityName ($details) ajouté le $dayName';
    } else if (langCode == 'de') {
      return '✅ $activityName ($details) am $dayName hinzugefügt';
    } else {
      return '✅ $activityName ($details) added on $dayName';
    }
  }

  static List<DateTime> _parseDays(List<String> dayStrings) {
    final weekStart = getCurrentWeekStart();
    final dayMap = {
      'monday': 0, 'lundi': 0, 'montag': 0,
      'tuesday': 1, 'mardi': 1, 'dienstag': 1,
      'wednesday': 2, 'mercredi': 2, 'mittwoch': 2,
      'thursday': 3, 'jeudi': 3, 'donnerstag': 3,
      'friday': 4, 'vendredi': 4, 'freitag': 4,
      'saturday': 5, 'samedi': 5, 'samstag': 5,
      'sunday': 6, 'dimanche': 6, 'sonntag': 6,
    };

    final days = <DateTime>[];
    for (final dayStr in dayStrings) {
      final offset = dayMap[dayStr.toLowerCase()];
      if (offset != null) {
        days.add(weekStart.add(Duration(days: offset)));
      }
    }

    return days;
  }

  static List<DateTime> _getAvailableDays(int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = getCurrentWeekStart().add(const Duration(days: 6));

    final available = <DateTime>[];
    var current = today;

    while (current.isBefore(weekEnd) || current == weekEnd) {
      if (available.length >= count) break;
      available.add(current);
      current = current.add(const Duration(days: 2)); // Espacement
    }

    return available.take(count).toList();
  }

  static String _getActivityKey(String activityName) {
    final mapping = {
      'course': 'running', 'running': 'running', 'laufen': 'running',
      'vélo': 'bike', 'cycling': 'bike', 'bike': 'bike', 'radfahren': 'bike',
      'marche': 'walking', 'walking': 'walking', 'gehen': 'walking',
      'natation': 'swimming', 'swimming': 'swimming', 'schwimmen': 'swimming',
      'hiit': 'hiit',
    };

    return mapping[activityName.toLowerCase()] ?? 'running';
  }

  static PlannedActivityType _getMealActivityType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
      case 'petit-déjeuner':
      case 'frühstück':
        return PlannedActivityType.breakfast;
      case 'lunch':
      case 'déjeuner':
      case 'mittagessen':
        return PlannedActivityType.lunch;
      case 'dinner':
      case 'dîner':
      case 'abendessen':
        return PlannedActivityType.dinner;
      default:
        return PlannedActivityType.snack;
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

  static String _getFollowUpQuestion(String langCode) {
    final questions = {
      'fr': 'Peux-tu me donner plus de détails ?',
      'en': 'Can you give me more details?',
      'de': 'Kannst du mir mehr Details geben?',
    };

    return questions[langCode] ?? questions['en']!;
  }

  // =====================================================
  // RECALCUL DES MACROS POUR INGREDIENTS MODIFIES
  // =====================================================

  /// Recalcule les macros d'un repas basé sur les ingrédients modifiés
  /// Retourne les données complètes du plat (nom, description, macros) comme le planificateur
  static Future<Map<String, dynamic>?> recalculateMealMacros({
    required String dishName,
    required String ingredients,
    required String langCode,
    String? originalDescription,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: GeminiConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 2048,
        ),
      );

      final languageName = langCode == 'fr' ? 'French' : langCode == 'de' ? 'German' : 'English';

      debugPrint('🧮 Recalcul - Dish: $dishName');
      debugPrint('🧮 Recalcul - Ingredients provided: $ingredients');

      final prompt = '''
You are a macronutrient calculator. The user has provided an EXACT list of ingredients.

RESPOND IN $languageName.

═══════════════════════════════════════════════════════════════
                    🚨 STRICT RULES 🚨
═══════════════════════════════════════════════════════════════

1. USE EXACTLY the ingredients provided - DO NOT MODIFY, DO NOT REMOVE ANY
2. ALL ingredients MUST appear in dish_description
3. Calculate macros for EACH ingredient separately, then ADD them up
4. ONE ingredient per line
   - NEVER: "- 1 egg + 1 yolk" or "- Salt, pepper"
   - ALWAYS: Separate lines for each ingredient

═══════════════════════════════════════════════════════════════
                    DATA TO PROCESS
═══════════════════════════════════════════════════════════════

Base dish: $dishName
EXACT LIST OF INGREDIENTS (must be respected exactly):
$ingredients

═══════════════════════════════════════════════════════════════
                    NUTRITIONAL VALUES REFERENCE
═══════════════════════════════════════════════════════════════

Cheeses:
- Camembert: 300 kcal/100g, 20g protein, 0.5g carbs, 25g fat
- Emmental: 380 kcal/100g, 28g protein, 0g carbs, 30g fat
- Parmesan: 430 kcal/100g, 38g protein, 0g carbs, 30g fat

Starches (cooked):
- Pasta: 130 kcal/100g, 5g protein, 25g carbs, 1g fat
- Rice: 130 kcal/100g, 3g protein, 28g carbs, 0.5g fat

Meats:
- Bacon/Lardons: 250 kcal/100g, 15g protein, 1g carbs, 20g fat
- Chicken: 165 kcal/100g, 31g protein, 0g carbs, 3.5g fat

Others:
- Egg: 155 kcal/100g (1 egg ~75 kcal)
- Heavy cream: 300 kcal/100g, 2g protein, 3g carbs, 30g fat

═══════════════════════════════════════════════════════════════
                    CALCULATION EXAMPLE
═══════════════════════════════════════════════════════════════

If ingredients = "200g pasta, 100g bacon, 150g camembert":
- Pasta 200g: 260 kcal, 10g protein, 50g carbs, 2g fat
- Bacon 100g: 250 kcal, 15g protein, 1g carbs, 20g fat
- Camembert 150g: 450 kcal, 30g protein, 0.75g carbs, 37.5g fat
TOTAL: 960 kcal, 55g protein, 51.75g carbs, 59.5g fat

═══════════════════════════════════════════════════════════════
                    RESPONSE FORMAT
═══════════════════════════════════════════════════════════════

Use section names in user's language ($languageName):
- French: INGRÉDIENTS, RECETTE, ASTUCE
- English: INGREDIENTS, RECIPE, TIP
- German: ZUTATEN, REZEPT, TIPP

Respond ONLY with valid JSON (no markdown, no \`\`\`):

{
  "dish_name": "Short name (max 25 chars)",
  "dish_description": "Description---INGREDIENTS:\\n- 200g pasta\\n- 100g bacon\\n- 150g camembert\\n...---RECIPE:\\n1. Step 1\\n2. Step 2---TIP: cooking tip",
  "calories": 960,
  "proteins": 55.0,
  "carbs": 51.75,
  "fats": 59.5
}

CALCULATE NOW with the EXACT ingredients provided:
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      debugPrint('🧮 Recalcul complet response: $text');

      // Nettoyer la réponse (enlever ```json si présent)
      String cleanedJson = text;
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```json?\s*'), '');
        cleanedJson = cleanedJson.replaceFirst(RegExp(r'\s*```$'), '');
      }

      final json = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // Extraire les macros de l'IA
      final proteins = (json['proteins'] as num).toDouble();
      final carbs = (json['carbs'] as num).toDouble();
      final fats = (json['fats'] as num).toDouble();

      // IMPORTANT: Calculer les calories avec la formule au lieu de prendre la valeur IA
      // Formule standard: protéines × 4 + glucides × 4 + lipides × 9
      final calculatedCalories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

      debugPrint('🧮 Calories IA: ${json['calories']} vs Calculées: $calculatedCalories');

      return {
        'success': true,
        'dish_name': json['dish_name'] as String? ?? dishName,
        'dish_description': json['dish_description'] as String? ?? '',
        'calories': calculatedCalories,
        'proteins': proteins,
        'carbs': carbs,
        'fats': fats,
      };
    } catch (e) {
      debugPrint('❌ Error recalculating macros: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =====================================================
  // NOUVEAU: FLOW MULTI-SESSIONS AVEC QUESTIONS SÉQUENTIELLES
  // =====================================================

  /// Continuer le planning après une réponse de l'utilisateur
  static Future<PlannerActionResult> continueSessionPlanning(
    SessionPlanningState state,
    String userAnswer,
    String langCode,
  ) async {
    try {
      // 1. Appliquer la réponse à la session concernée
      final questionIdx = state.nextQuestionIndex;
      if (questionIdx >= 0) {
        state.applyAnswerToSession(questionIdx, userAnswer);
        state.answerCurrentQuestion(userAnswer);
      }

      // 2. Vérifier s'il reste des questions
      final nextQuestion = state.nextQuestion;
      if (nextQuestion != null) {
        return PlannerActionResult.question(
          questionText: nextQuestion.questionText,
          question: nextQuestion,
          planningState: state,
        );
      }

      // 3. Toutes les questions sont répondues → générer les sessions
      return await _generateSessionsFromState(state, langCode);
    } catch (e) {
      debugPrint('❌ continueSessionPlanning error: $e');
      return PlannerActionResult.error('Erreur lors de la planification: $e');
    }
  }

  /// Générer les sessions finales depuis l'état complété
  static Future<PlannerActionResult> _generateSessionsFromState(
    SessionPlanningState state,
    String langCode,
  ) async {
    try {
      final pendingSessions = <PendingSession>[];

      for (final partial in state.sessions) {
        if (partial.isWorkout) {
          // Générer le workout avec l'IA
          final pendingWorkout = partial.toPendingWorkout();
          final result = await AIWorkoutGenerationService.generateWorkout(
            userRequest: pendingWorkout.workoutPrompt,
            durationMinutes: pendingWorkout.durationMinutes,
          );

          if (result.success && result.exercises != null && result.exercises!.isNotEmpty) {
            final workoutWithExercises = pendingWorkout.copyWithExercises(result.exercises!);
            pendingSessions.add(PendingSession.fromWorkout(workoutWithExercises));
          }
        } else {
          // Cardio: pas de génération, juste créer le PendingCardio
          final pendingCardio = partial.toPendingCardio();
          pendingSessions.add(PendingSession.fromCardio(pendingCardio));
        }
      }

      if (pendingSessions.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'workout_generation_failed'),
        );
      }

      // Trier: par date puis workout avant cardio
      pendingSessions.sort((a, b) {
        final dateCompare = a.plannedDate.compareTo(b.plannedDate);
        if (dateCompare != 0) return dateCompare;
        // Workouts avant cardios pour le même jour
        if (a.isWorkout && b.isCardio) return -1;
        if (a.isCardio && b.isWorkout) return 1;
        return 0;
      });

      return PlannerActionResult.sessionPreview(
        message: _getSessionPreviewMessage(langCode, pendingSessions),
        sessions: pendingSessions,
      );
    } catch (e) {
      debugPrint('❌ _generateSessionsFromState error: $e');
      return PlannerActionResult.error('Erreur lors de la génération: $e');
    }
  }

  /// Message de preview pour les sessions
  static String _getSessionPreviewMessage(String langCode, List<PendingSession> sessions) {
    final workoutCount = sessions.where((s) => s.isWorkout).length;
    final cardioCount = sessions.where((s) => s.isCardio).length;

    if (langCode == 'fr') {
      final parts = <String>[];
      if (workoutCount > 0) {
        parts.add('$workoutCount séance${workoutCount > 1 ? 's' : ''} de musculation');
      }
      if (cardioCount > 0) {
        parts.add('$cardioCount séance${cardioCount > 1 ? 's' : ''} de cardio');
      }
      return 'Voici ton programme ! ${parts.join(' et ')} 👇\nValide chaque séance une par une.';
    }

    final parts = <String>[];
    if (workoutCount > 0) {
      parts.add('$workoutCount workout session${workoutCount > 1 ? 's' : ''}');
    }
    if (cardioCount > 0) {
      parts.add('$cardioCount cardio session${cardioCount > 1 ? 's' : ''}');
    }
    return 'Here\'s your program! ${parts.join(' and ')} 👇\nValidate each session one by one.';
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
          // Incrémenter le compteur une fois par session de chat
          await _incrementUsageOncePerSession();
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
          // Incrémenter le compteur une fois par session de chat
          await _incrementUsageOncePerSession();
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

  /// Créer un état de planning depuis une analyse d'intent avec questions
  static SessionPlanningState? createPlanningStateFromIntent(
    Map<String, dynamic> info,
    String langCode,
  ) {
    final sessions = <PartialSession>[];
    final questions = <PendingQuestion>[];

    // 1. Parser les workouts
    final workouts = info['workouts'] as List?;
    if (workouts != null) {
      for (int i = 0; i < workouts.length; i++) {
        final w = workouts[i] as Map<String, dynamic>;
        final dayStr = w['day'] as String?;
        final day = _parseSingleDay(dayStr ?? '');
        if (day == null) continue;

        final workoutType = w['workout_type'] as String? ?? 'Full Body';
        final durationMinutes = w['duration_minutes'] as int?;

        sessions.add(PartialSession(
          type: PendingSessionType.workout,
          plannedDate: day,
          workoutType: workoutType,
          durationMinutes: durationMinutes,
          workoutPrompt: w['workout_prompt'] as String? ?? 'Séance de $workoutType',
        ));

        // Si durée manquante, ajouter une question
        if (durationMinutes == null) {
          final questionText = langCode == 'fr'
              ? 'Quelle durée pour ta séance de $workoutType ?'
              : 'How long for your $workoutType session?';
          questions.add(PendingQuestion(
            sessionIndex: sessions.length - 1,
            questionType: 'duration',
            questionText: questionText,
          ));
        }
      }
    }

    // 2. Parser les cardios
    final cardios = info['cardios'] as List?;
    if (cardios != null) {
      for (int i = 0; i < cardios.length; i++) {
        final c = cardios[i] as Map<String, dynamic>;
        final dayStr = c['day'] as String?;
        final day = _parseSingleDay(dayStr ?? '');
        if (day == null) continue;

        final activityName = c['activity_name'] as String? ?? 'Cardio';
        final activityKey = _getActivityKey(activityName);
        final distanceKm = (c['target_km'] as num?)?.toDouble();
        final durationMinutes = c['target_minutes'] as int?;

        sessions.add(PartialSession(
          type: PendingSessionType.cardio,
          plannedDate: day,
          activityName: activityName,
          activityKey: activityKey,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
        ));

        // Si ni distance ni durée, ajouter une question
        if (distanceKm == null && durationMinutes == null) {
          final questionText = langCode == 'fr'
              ? 'Tu veux un objectif de distance ou de durée pour ton $activityName ?'
              : 'Do you want a distance or duration target for your $activityName?';
          questions.add(PendingQuestion(
            sessionIndex: sessions.length - 1,
            questionType: 'distance',
            questionText: questionText,
          ));
        }
      }
    }

    // 3. Gérer l'ancien format (single cardio)
    final singleActivityName = info['activity_name'] as String?;
    if (singleActivityName != null && cardios == null) {
      final daysList = info['days'] as List<DateTime>?;
      final targetKm = info['target_km'] as double?;
      final targetMinutes = info['target_minutes'] as int?;

      for (final day in daysList ?? [DateTime.now()]) {
        sessions.add(PartialSession(
          type: PendingSessionType.cardio,
          plannedDate: day,
          activityName: singleActivityName,
          activityKey: _getActivityKey(singleActivityName),
          distanceKm: targetKm,
          durationMinutes: targetMinutes,
        ));

        if (targetKm == null && targetMinutes == null) {
          final questionText = langCode == 'fr'
              ? 'Tu veux un objectif de distance ou de durée pour ton $singleActivityName ?'
              : 'Do you want a distance or duration target for your $singleActivityName?';
          questions.add(PendingQuestion(
            sessionIndex: sessions.length - 1,
            questionType: 'distance',
            questionText: questionText,
          ));
        }
      }
    }

    if (sessions.isEmpty) return null;

    return SessionPlanningState(
      sessions: sessions,
      questions: questions,
    );
  }
}
