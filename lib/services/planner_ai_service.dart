import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/gemini_config.dart';
import '../models/weekly_planner_models.dart';
import '../models/sport_models.dart';
import '../models/ai_analysis_models.dart';
import '../models/user_model.dart';
import 'weekly_planner_service.dart';
import 'gemini_analysis_service_v2.dart';
import 'ai_workout_generation_service.dart';
import 'food_entries_service.dart';
import 'localization_service.dart';
import 'auth_service.dart';
import 'unified_subscription_service.dart';

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

/// Résultat d'une action de planification
class PlannerActionResult {
  final bool success;
  final String message;
  final List<String>? createdItems;
  final String? error;
  final bool isPaywallRequired;
  final int? remainingFreeUses;
  final bool requiresConfirmation; // Pour le mode preview
  final List<PendingWorkout>? pendingWorkouts; // Workouts à valider
  final bool hasMoreActions; // Il reste des actions à exécuter
  final bool canUndo; // Dernière action peut être annulée
  final String? nextActionDescription; // Description de la prochaine action

  PlannerActionResult({
    required this.success,
    required this.message,
    this.createdItems,
    this.error,
    this.isPaywallRequired = false,
    this.remainingFreeUses,
    this.requiresConfirmation = false,
    this.pendingWorkouts,
    this.hasMoreActions = false,
    this.canUndo = false,
    this.nextActionDescription,
  });

  factory PlannerActionResult.success(String message, {List<String>? items}) {
    return PlannerActionResult(
      success: true,
      message: message,
      createdItems: items,
    );
  }

  factory PlannerActionResult.error(String error) {
    return PlannerActionResult(
      success: false,
      message: error,
      error: error,
    );
  }

  factory PlannerActionResult.paywall(String message) {
    return PlannerActionResult(
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
      success: true,
      message: message,
      requiresConfirmation: true,
      pendingWorkouts: workouts,
    );
  }
}

/// Workout en attente de confirmation
class PendingWorkout {
  final DateTime plannedDate;
  final String workoutName;
  final String workoutType;
  final int durationMinutes;
  final String workoutPrompt;
  final List<WorkoutExercise>? exercises; // Générés par l'IA

  PendingWorkout({
    required this.plannedDate,
    required this.workoutName,
    required this.workoutType,
    required this.durationMinutes,
    required this.workoutPrompt,
    this.exercises,
  });
}

/// Service d'IA pour le planificateur hebdomadaire
class PlannerAIService {
  // =====================================================
  // FREE TIER LIMITS - 3 planifications IA par semaine
  // =====================================================
  static const int _freeWeeklyLimit = 3;
  static const String _prefKeyWeekStart = 'ai_planner_week_start';
  static const String _prefKeyUsageCount = 'ai_planner_usage_count';

  /// Vérifier si l'utilisateur peut utiliser l'IA (premium ou quota restant)
  static Future<bool> canUseAI() async {
    // Premium = accès illimité
    if (UnifiedSubscriptionService().isPremium) {
      return true;
    }
    // Mode test = accès illimité (sans décompte)
    if (UnifiedSubscriptionService().testMode) {
      return true;
    }
    // Free = vérifier le quota
    final remaining = await getRemainingFreeUses();
    return remaining > 0;
  }

  /// Obtenir le nombre d'utilisations restantes pour les utilisateurs free
  static Future<int> getRemainingFreeUses() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier si on est dans une nouvelle semaine
    final currentWeekStart = getCurrentWeekStart();
    final savedWeekStart = prefs.getString(_prefKeyWeekStart);

    if (savedWeekStart == null || savedWeekStart != currentWeekStart.toIso8601String().split('T')[0]) {
      // Nouvelle semaine, reset le compteur
      await prefs.setString(_prefKeyWeekStart, currentWeekStart.toIso8601String().split('T')[0]);
      await prefs.setInt(_prefKeyUsageCount, 0);
      return _freeWeeklyLimit;
    }

    final usageCount = prefs.getInt(_prefKeyUsageCount) ?? 0;
    return (_freeWeeklyLimit - usageCount).clamp(0, _freeWeeklyLimit);
  }

  /// Incrémenter le compteur d'utilisation (appelé après une planification réussie)
  static Future<void> incrementUsageCount() async {
    // Ne pas incrémenter pour les premium
    if (UnifiedSubscriptionService().isPremium) {
      return;
    }

    // Ne pas incrémenter en mode test
    if (UnifiedSubscriptionService().testMode) {
      debugPrint('📊 AI Planner: Mode test - pas de décompte');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_prefKeyUsageCount) ?? 0;
    await prefs.setInt(_prefKeyUsageCount, currentCount + 1);
    debugPrint('📊 AI Planner usage: ${currentCount + 1}/$_freeWeeklyLimit');
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

      // Pour les workouts: ne pas incrémenter maintenant (fait dans confirmWorkouts)
      // Pour les autres: incrémenter si succès et pas de preview
      if (result.success && !result.requiresConfirmation) {
        await incrementUsageCount();
      }

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

      // Incrémenter le compteur d'utilisation seulement après confirmation
      await incrementUsageCount();

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

  /// Gérer une demande de repas
  static Future<PlannerActionResult> _handleMealRequest(
    Map<String, dynamic> info,
    String langCode,
  ) async {
    try {
      final foodDescription = info['food_description'] as String?;
      final mealType = info['meal_type'] as String? ?? 'breakfast';
      final days = info['days'] as List<DateTime>?;

      if (foodDescription == null || foodDescription.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'meal_description_required'),
        );
      }

      final targetDays = days ?? [DateTime.now()];
      final createdItems = <String>[];

      // Analyser le repas avec Gemini
      final analysisResult = await GeminiAnalysisServiceV2.analyzeTextDescription(
        foodDescription,
      );

      if (!analysisResult.success || analysisResult.detectedFoods.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'meal_analysis_failed'),
        );
      }

      // Calculer les macros totaux
      int totalCalories = 0;
      double totalProteins = 0;
      double totalCarbs = 0;
      double totalFats = 0;

      for (final food in analysisResult.detectedFoods) {
        totalCalories += food.calories;
        totalProteins += food.nutrition.proteins;
        totalCarbs += food.nutrition.carbs;
        totalFats += food.nutrition.fats;
      }

      final activityType = _getMealActivityType(mealType);

      for (final day in targetDays) {
        if (!isInCurrentWeek(day)) continue;

        final mealData = PlannedMealData(
          foodDescription: foodDescription,
          calories: totalCalories,
          proteins: totalProteins,
          carbs: totalCarbs,
          fats: totalFats,
        );

        final activity = await WeeklyPlannerService.addPlannedActivity(
          plannedDate: day,
          activityType: activityType,
          activityData: mealData.toJson(),
          isAiGenerated: true,
        );

        if (activity != null) {
          createdItems.add(_formatDayName(day, langCode));
        }
      }

      if (createdItems.isEmpty) {
        return PlannerActionResult.error(
          _getMessage(langCode, 'meal_creation_failed'),
        );
      }

      return PlannerActionResult.success(
        _getMessage(langCode, 'meal_created')
            .replaceAll('{meal}', foodDescription)
            .replaceAll('{days}', createdItems.join(', ')),
        items: createdItems,
      );
    } catch (e) {
      debugPrint('❌ _handleMealRequest error: $e');
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

    final buffer = StringBuffer();
    for (final workout in workouts) {
      final dayName = _formatDayName(workout.plannedDate, 'en').toLowerCase();
      final status = workout.status.value;
      final exerciseCount = workout.exercises.length;

      buffer.writeln('• $dayName (id: ${workout.id}): "${workout.workoutName}" - $exerciseCount exercises, status: $status');
    }

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

    return '''
You are Ryze, an expert NUTRITION coach AI. You ONLY help with meal planning.

## Your Specialty
You are a nutrition specialist. You can ONLY plan:
- Breakfast (petit-déjeuner / Frühstück)
- Lunch (déjeuner / Mittagessen)
- Dinner (dîner / Abendessen)
- Snacks (collation / Snack)

You CANNOT help with workouts, cardio, or any fitness activities. If the user asks about those, politely redirect them.

## User Nutritional Context
- Daily Calorie Target: ${context['calorie_target'] ?? 2000} kcal
- Protein Target: ${context['protein_target'] ?? 100}g
- Carbs Target: ${context['carbs_target'] ?? 250}g
- Fats Target: ${context['fats_target'] ?? 70}g
- Fitness Goal: ${context['fitness_goal'] ?? 'general fitness'}
- Calories consumed today: ${context['calories_today'] ?? 0} kcal
- Remaining calories: ${context['remaining_calories'] ?? context['calorie_target'] ?? 2000} kcal

## Available Days This Week
${context['available_days'] ?? ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']}

${_getFormattedHistory()}
## User Request
"$userMessage"

## Response Format (JSON)
{
  "intent": "meal",
  "is_complete": true | false,
  "extracted_info": {
    "food_description": "detailed description of the meal",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "days": ["monday", "tuesday", ...]
  },
  "response_message": "friendly message in $languageName confirming what you're planning",
  "follow_up_question": "only if you need more info (in $languageName)"
}

## Rules
1. If user asks about workouts/cardio, return intent: "unknown" with a polite redirection message
2. Always suggest meals that fit their calorie/macro targets
3. Ask for meal type if not specified (breakfast, lunch, dinner, snack)
4. Ask for which day(s) if not specified
5. Be creative with meal suggestions based on their goals

## Examples

User: "Un petit-déj protéiné pour demain"
→ intent: "meal", meal_type: "breakfast", create high-protein breakfast suggestion

User: "Je veux des repas équilibrés pour la semaine"
→ Ask follow-up: which meals specifically (all? just lunches?)

User: "3 séances de musculation"
→ intent: "unknown", message: "Je suis ton coach nutrition ! Pour les séances de sport, utilise le bouton 'Planifier mes séances'. Ici, dis-moi quel repas tu veux planifier 🍽️"
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
        "duration_minutes": 30 | 45 | 60 | 90
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
→ intent: "modify_workout", delete_day: "tuesday" (delete existing), then create new workout for tuesday

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
      };
    } catch (e) {
      debugPrint('❌ _getNutritionContext error: $e');
      return {};
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
    try {
      final url = Uri.parse(
        '${GeminiConfig.geminiApiUrl}?key=${GeminiConfig.geminiApiKey}',
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
        debugPrint('❌ Gemini API error: ${response.statusCode}');
        return null;
      }

      final responseData = jsonDecode(response.body);
      final text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null) return null;

      // Extraire le JSON de la réponse
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) return null;

      return jsonDecode(jsonMatch.group(0)!);
    } catch (e) {
      debugPrint('❌ _callGeminiAPI error: $e');
      return null;
    }
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
            'enum': ['delete_all_workouts', 'delete_all_cardio', 'delete_workout', 'delete_cardio'],
          },
          'action_description': {
            'type': 'string',
            'description': 'Human-readable description of what will be deleted (in user language)',
          },
          'action_args': {
            'type': 'object',
            'description': 'REQUIRED for delete_cardio/delete_workout: must include {"day": "monday|tuesday|wednesday|thursday|friday|saturday|sunday"}',
            'properties': {
              'day': {
                'type': 'string',
                'description': 'Day for single delete (required for delete_cardio and delete_workout)',
                'enum': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
              },
            },
          },
        },
        'required': ['action_type', 'action_description'],
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
            'description': 'Duration in minutes - REQUIRED. User must specify: 30, 45, 60, or 90. Do NOT use default values.',
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
      'name': 'create_cardio',
      'description': 'Create a cardio session for a specific day. IMPORTANT: You need either duration_minutes OR target_km. If user provides neither, use ask_clarification to ask. If user provides one, use only that one. If user provides both, use both.',
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
            'description': 'Type of cardio activity',
            'enum': ['running', 'cycling', 'swimming', 'walking', 'hiit', 'rowing', 'elliptical'],
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration in minutes. Only provide if user specified a duration.',
          },
          'target_km': {
            'type': 'number',
            'description': 'Target distance in kilometers. Only provide if user specified a distance.',
          },
        },
        'required': ['day', 'activity'],
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

      final systemPrompt = '''
You are Ryze, a friendly fitness coach AI assistant. You help users plan their weekly workouts and cardio.

⚠️ CRITICAL - DISTINGUISH BETWEEN TWO DIFFERENT TYPES:
1. **WORKOUT** = musculation, strength training, séance de muscu, gym, poids, exercices
   - Use: delete_all_workouts, delete_workout, create_workout, move_workout
2. **CARDIO** = course, running, vélo, cycling, natation, marche, HIIT, cardio
   - Use: delete_all_cardio, delete_cardio, create_cardio, move_cardio

EXAMPLES:
- "supprime mes séances de cardio" → delete_all_cardio (NOT delete_all_workouts!)
- "supprime mes séances de musculation" → delete_all_workouts
- "supprime mes séances" (ambiguous) → ask_clarification to know if cardio or workout
- "du vélo vendredi" → ask_clarification "Combien de temps ou quelle distance?" (NO duration/distance given)
- "30 min de vélo vendredi" → create_cardio(day="friday", activity="cycling", duration_minutes=30) (only duration)
- "5km de course lundi" → create_cardio(day="monday", activity="running", target_km=5) (only distance)
- "45 min de natation" → ask_clarification for the day, then create_cardio with duration_minutes=45
- "ajoute un Full Body lundi 45min" → create_workout(day="monday", workout_type="Full Body", duration_minutes=45)
- "une séance de muscu mardi" → ask_clarification "Quel type de séance (Pecs, Dos, Jambes, Full Body...) et combien de temps?"
- "une séance pecs" → ask_clarification for the day and duration
- "3 séances de sport" → ask_clarification for types and days
- "déplace ma séance de muscu du lundi au mercredi" → move_workout(from_day="monday", to_day="wednesday")
- "déplace mon cardio du jeudi au samedi" → move_cardio(from_day="thursday", to_day="saturday")
- "mets ma course de vendredi à dimanche" → move_cardio(from_day="friday", to_day="sunday")
- "annule" / "undo" / "reviens en arrière" / "annule ça" → undo_last_action

MULTIPLE ACTIONS IN ONE MESSAGE (call ALL tools together):
- "supprime mes séances et ajoute du cardio mardi 30min" → [request_confirmation(delete_all_workouts), create_cardio(tuesday, 30min)]
- "efface la séance de lundi et crée un Full Body mercredi" → [request_confirmation(delete_workout, monday), create_workout(wednesday)]
- "supprime tout et refais moi 3 séances" → [request_confirmation(delete_all_workouts), create_workout(x3)]

CONFIRMATION FORMAT:
When using request_confirmation, action_description MUST include the action verb:
- "supprimer toutes les séances de cardio de la semaine"
- "supprimer toutes les séances de musculation de la semaine"
- "supprimer la séance de cardio du lundi"
- "supprimer la séance de musculation du mardi"

IMPORTANT - action_args for single deletes:
When action_type is "delete_cardio" or "delete_workout", you MUST include the day in action_args:
- request_confirmation(action_type="delete_cardio", action_description="...", action_args={"day": "thursday"})
- request_confirmation(action_type="delete_workout", action_description="...", action_args={"day": "monday"})
The day must be in English lowercase: monday, tuesday, wednesday, thursday, friday, saturday, sunday

RULES:
1. ALWAYS respond in $languageName
2. For ANY DELETE, FIRST use request_confirmation with the ACTION you will perform
3. When creating multiple items, call the tool multiple times
4. If unclear whether cardio or workout, ASK with ask_clarification
5. For CARDIO: you NEED either duration_minutes OR target_km (or both). If user didn't specify either, use ask_clarification to ask "Combien de temps ou quelle distance?" BEFORE creating. Only provide the values the user actually gave you - NEVER add default values.
6. For WORKOUT/MUSCU: you NEED workout_type AND duration_minutes. If user didn't specify these, use ask_clarification to ask "Quel type de séance (Pecs, Dos, Jambes, Full Body...) et combien de temps?" BEFORE creating. NEVER use default values.
7. IMPORTANT - MULTIPLE ACTIONS: When user asks for multiple things (e.g. "delete X and create Y"), you MUST call ALL tools in the SAME response:
   - First: request_confirmation for the delete
   - Then: create_cardio or create_workout for the creations
   Example: "supprime mes séances et ajoute un jogging mardi 10km" → call request_confirmation AND create_cardio in the same response

CONTEXT:
- Today: ${DateTime.now().toIso8601String().split('T')[0]}
- Days with WORKOUTS (musculation): ${context['days_with_workout'] ?? 'none'}
- Days with CARDIO: ${context['days_with_cardio'] ?? 'none'}
- Available days: ${context['available_days'] ?? 'all'}

THIS WEEK'S PLANNING:
WORKOUTS: ${context['planned_workouts_this_week'] ?? 'No workouts planned'}
CARDIO: ${context['planned_cardio_this_week'] ?? 'No cardio planned'}

${_getFormattedHistory()}

USER REQUEST: "$userMessage"
''';

      // Appeler l'API avec les tools
      final result = await _callGeminiWithTools(systemPrompt, userMessage);

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
      final pendingWorkouts = <PendingWorkout>[];

      for (int i = 0; i < toolCalls.length; i++) {
        final toolCall = toolCalls[i];
        final functionName = toolCall['name'] as String;
        final args = toolCall['args'] as Map<String, dynamic>? ?? {};

        debugPrint('🔧 Executing tool: $functionName with args: $args');

        final toolResult = await _executeToolCall(functionName, args, langCode);
        executionResults.add(toolResult['message'] as String);

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

        if (functionName == 'ask_clarification') {
          // Retourner la question de clarification
          final question = args['question'] as String? ?? 'Could you provide more details?';
          addToHistory('assistant', question);
          return PlannerActionResult(success: true, message: question);
        }
      }

      // Si on a des workouts à créer, retourner en mode preview
      if (hasWorkoutCreations && pendingWorkouts.isNotEmpty) {
        final previewMessage = responseText ?? _getPreviewMessage(langCode, pendingWorkouts);
        addToHistory('assistant', previewMessage);
        return PlannerActionResult.preview(
          message: previewMessage,
          workouts: pendingWorkouts,
        );
      }

      // Retourner le résultat final
      final finalMessage = responseText ?? executionResults.join('\n');
      addToHistory('assistant', finalMessage);

      // Incrémenter le compteur si des actions ont été effectuées
      if (toolCalls.isNotEmpty) {
        await incrementUsageCount();
      }

      return PlannerActionResult.success(finalMessage);

    } catch (e) {
      debugPrint('❌ processRequestWithTools error: $e');
      return PlannerActionResult.error(_getErrorMessage(langCode, 'api_error'));
    }
  }

  /// Appeler Gemini API avec function calling
  static Future<Map<String, dynamic>?> _callGeminiWithTools(
    String systemPrompt,
    String userMessage,
  ) async {
    try {
      final url = Uri.parse(
        '${GeminiConfig.geminiApiUrl}?key=${GeminiConfig.geminiApiKey}',
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
            'function_declarations': _plannerTools,
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
          'maxOutputTokens': 2048,
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final responseData = jsonDecode(response.body);
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

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
      debugPrint('❌ _callGeminiWithTools error: $e');
      return null;
    }
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
        return {'success': false, 'message': _getToolMessage(langCode, 'no_cardio')};

      case 'create_workout':
        final dayStr = args['day'] as String? ?? '';
        final workoutType = args['workout_type'] as String?;
        final duration = args['duration_minutes'] as int?;
        final focus = args['focus'] as String? ?? workoutType ?? '';

        final day = _parseSingleDay(dayStr);
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Vérifier que le type et la durée sont fournis
        if (workoutType == null || workoutType.isEmpty || duration == null) {
          final askMsg = langCode == 'fr'
              ? 'Quel type de séance veux-tu (ex: Pecs, Dos, Jambes, Full Body, Push, Pull...) et combien de temps?'
              : langCode == 'de'
                  ? 'Welche Art von Training möchtest du (z.B. Brust, Rücken, Beine, Ganzkörper, Push, Pull...) und wie lange?'
                  : 'What type of workout do you want (e.g. Chest, Back, Legs, Full Body, Push, Pull...) and how long?';
          return {'success': true, 'message': askMsg};
        }

        // Générer le workout avec l'IA
        final result = await AIWorkoutGenerationService.generateWorkout(
          userRequest: '$workoutType workout, $focus',
          durationMinutes: duration,
        );

        if (result.success && result.exercises != null) {
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
        return {'success': false, 'message': 'Failed to generate workout'};

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
        return {'success': false, 'message': _getToolMessage(langCode, 'no_cardio')};

      case 'create_cardio':
        final dayStr = args['day'] as String? ?? '';
        final activityKey = args['activity'] as String? ?? 'running';
        final duration = args['duration_minutes'] as int?;
        final targetKm = args['target_km'] as num?;

        final day = _parseSingleDay(dayStr);
        if (day == null) return {'success': false, 'message': 'Invalid day'};

        // Vérifier qu'au moins une valeur (durée ou distance) est fournie
        if (duration == null && targetKm == null) {
          // L'IA aurait dû demander avant, mais au cas où
          final askMsg = langCode == 'fr'
              ? 'Combien de temps ou quelle distance veux-tu faire?'
              : langCode == 'de'
                  ? 'Wie lange oder welche Distanz möchtest du machen?'
                  : 'How long or what distance do you want to do?';
          return {'success': true, 'message': askMsg};
        }

        // Traduire le nom de l'activité
        final activityName = _getCardioActivityName(activityKey, langCode);

        // Construire les données cardio avec uniquement les valeurs fournies
        final Map<String, dynamic> cardioActivityData = {
          'activity_key': activityKey,
          'activity_name': activityName,
        };
        if (duration != null) cardioActivityData['target_minutes'] = duration;
        if (targetKm != null) cardioActivityData['target_km'] = targetKm.toDouble();

        final createdCardio = await WeeklyPlannerService.addPlannedActivity(
          plannedDate: day,
          activityType: PlannedActivityType.cardio,
          activityData: cardioActivityData,
          isAiGenerated: true,
        );

        // Stocker pour undo
        if (createdCardio != null) {
          _lastAction = {
            'type': 'create_cardio',
            'created_cardio_id': createdCardio.id,
          };
        }

        // Message de succès spécifique
        final dayName = _getDayName(day, langCode);
        final successMessage = _getCardioSuccessMessage(langCode, activityName, duration, targetKm?.toDouble(), dayName);
        return {'success': true, 'message': successMessage};

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

      default:
        return {'success': false, 'message': 'Unknown function: $functionName'};
    }
  }

  /// Message de confirmation pour les actions destructrices
  static String _getActionConfirmMessage(String langCode, String description) {
    final templates = {
      'fr': '⚠️ Je vais: $description',
      'en': '⚠️ I will: $description',
      'de': '⚠️ Ich werde: $description',
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
    final actionMessage = result['message'] as String;

    // Vérifier s'il y a des actions de suivi
    if (_pendingFollowUpActions != null && _pendingFollowUpActions!.isNotEmpty) {
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
          // Préparer l'action réelle comme pending
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
            message: actionMessage,
            canUndo: _lastAction != null,
            hasMoreActions: true,
            requiresConfirmation: true,
            nextActionDescription: confirmMessage,
          );
        }
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
          message: actionMessage,
          canUndo: _lastAction != null,
          hasMoreActions: true,
          requiresConfirmation: true,
          nextActionDescription: confirmMessage,
        );
      } else {
        // Exécuter directement et continuer avec les suivantes
        final nextResult = await _executeToolCall(nextName, nextArgs, langCode);
        final combinedMessage = '$actionMessage\n${nextResult['message']}';

        // S'il reste encore des actions, continuer récursivement
        if (_pendingFollowUpActions!.isNotEmpty) {
          return PlannerActionResult(
            success: true,
            message: combinedMessage,
            canUndo: _lastAction != null,
            hasMoreActions: true,
            nextActionDescription: _getNextActionDescription(langCode),
          );
        }

        // Plus d'actions
        _pendingFollowUpActions = null;
        return PlannerActionResult(
          success: result['success'] == true,
          message: combinedMessage,
          canUndo: _lastAction != null,
          hasMoreActions: false,
        );
      }
    }

    // Pas d'actions de suivi
    _pendingFollowUpActions = null;
    if (result['success'] == true) {
      return PlannerActionResult(
        success: true,
        message: actionMessage,
        canUndo: _lastAction != null,
      );
    }
    return PlannerActionResult.error(actionMessage);
  }

  /// Vérifie si une action nécessite une confirmation
  static bool _actionRequiresConfirmation(String actionName, Map<String, dynamic> args) {
    // Actions qui nécessitent toujours une confirmation
    if (actionName == 'delete_all_workouts' || actionName == 'delete_all_cardio') {
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
    };
    return messages[key]?[langCode] ?? messages[key]?['en'] ?? key;
  }

  /// Traduire le nom de l'activité cardio
  static String _getCardioActivityName(String activityKey, String langCode) {
    final names = {
      'running': {'fr': 'Course à pied', 'en': 'Running', 'de': 'Laufen'},
      'cycling': {'fr': 'Vélo', 'en': 'Cycling', 'de': 'Radfahren'},
      'swimming': {'fr': 'Natation', 'en': 'Swimming', 'de': 'Schwimmen'},
      'walking': {'fr': 'Marche', 'en': 'Walking', 'de': 'Gehen'},
      'hiit': {'fr': 'HIIT', 'en': 'HIIT', 'de': 'HIIT'},
      'rowing': {'fr': 'Rameur', 'en': 'Rowing', 'de': 'Rudern'},
      'elliptical': {'fr': 'Elliptique', 'en': 'Elliptical', 'de': 'Crosstrainer'},
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
}
