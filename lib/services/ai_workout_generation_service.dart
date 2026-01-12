import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/gemini_config.dart';
import '../models/sport_models.dart';
import 'database_service.dart';
import 'localization_service.dart';

/// Service pour générer des séances d'entraînement avec Gemini AI
class AIWorkoutGenerationService {
  // Cache des exercices pour éviter les appels répétés à la DB
  static List<Exercise>? _cachedExercises;
  static String? _cachedExercisesLanguage; // Langue du cache
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(hours: 1);

  // Cache du contexte utilisateur (historique)
  static String? _cachedUserContext;
  static String? _cachedUserId;
  static DateTime? _userContextTimestamp;
  static const _userContextCacheDuration = Duration(minutes: 5);

  /// Générer une séance d'entraînement personnalisée avec Gemini
  static Future<AIWorkoutResult> generateWorkout({
    required String userRequest,
    int? durationMinutes,
    double? intensity, // 0.0 à 1.0
    String? focus, // 'Force', 'Hypertrophie', 'Endurance'
    List<String>? equipment,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Vérifier si Gemini est configuré
      if (!GeminiConfig.isConfigured) {
        return AIWorkoutResult.error(
          error: 'Gemini API not configured',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Récupérer tous les exercices disponibles (avec cache)
      final allExercises = await _getExercisesWithCache();
      if (allExercises.isEmpty) {
        return AIWorkoutResult.error(
          error: 'No exercises available in database',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Récupérer le profil utilisateur et son historique DÉTAILLÉ (avec cache)
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final userContext = userId != null
          ? await _getUserContextWithCache(userId)
          : 'No user history available - suggest beginner-friendly weights (10-15kg for upper body, 20-30kg for lower body)';

      // Obtenir la langue de l'utilisateur
      final locService = LocalizationService.instance;
      final userLanguage = locService.isFrench ? 'French' : locService.isGerman ? 'German' : 'English';

      // Construire la liste d'exercices disponibles AVEC IDs pour le prompt
      final exercisesList = _buildExercisesList(allExercises, locService);

      // Construire le prompt pour Gemini
      final prompt = _buildGeminiPrompt(
        userRequest: userRequest,
        exercisesList: exercisesList,
        userContext: userContext,
        userLanguage: userLanguage,
        durationMinutes: durationMinutes,
        intensity: intensity,
        focus: focus,
        equipment: equipment,
      );

      // Faire l'appel API à Gemini
      final response = await _callGeminiAPI(prompt);

      stopwatch.stop();

      if (response == null) {
        return AIWorkoutResult.error(
          error: 'Coach Ryze est occupé, réessayez dans quelques instants',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Parser et valider la réponse avec retry si exercices non trouvés
      final workoutExercises = await _parseAndValidateWorkout(
        response,
        allExercises,
        locService,
      );

      if (workoutExercises.isEmpty) {
        return AIWorkoutResult.error(
          error: 'No valid exercises generated',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      return AIWorkoutResult.success(
        exercises: workoutExercises,
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        aiSuggestions: response['suggestions'] ?? '',
      );

    } catch (e) {
      stopwatch.stop();
      return AIWorkoutResult.error(
        error: 'Workout generation failed: $e',
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
      );
    }
  }

  /// Récupérer les exercices avec cache (évite les appels DB répétés)
  static Future<List<Exercise>> _getExercisesWithCache() async {
    final currentLanguage = LocalizationService.instance.currentLanguageCode;

    // Vérifier si le cache est valide ET dans la bonne langue
    if (_cachedExercises != null &&
        _cacheTimestamp != null &&
        _cachedExercisesLanguage == currentLanguage &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      debugPrint('✅ Using cached exercises (${_cachedExercises!.length} exercises, lang: $currentLanguage)');
      return _cachedExercises!;
    }

    // Cache expiré, inexistant ou langue différente, récupérer depuis la DB
    debugPrint('🔄 Fetching exercises from database (lang: $currentLanguage)...');
    _cachedExercises = await DatabaseService.getSystemExercises(language: currentLanguage);
    _cachedExercisesLanguage = currentLanguage;
    _cacheTimestamp = DateTime.now();
    debugPrint('✅ Cached ${_cachedExercises!.length} exercises (lang: $currentLanguage, valid for ${_cacheDuration.inMinutes} minutes)');

    return _cachedExercises!;
  }

  /// Récupérer le contexte utilisateur avec cache (évite les appels DB répétés)
  static Future<String> _getUserContextWithCache(String userId) async {
    // Vérifier si le cache est valide pour ce user
    if (_cachedUserContext != null &&
        _cachedUserId == userId &&
        _userContextTimestamp != null &&
        DateTime.now().difference(_userContextTimestamp!) < _userContextCacheDuration) {
      debugPrint('✅ Using cached user context for user $userId');
      return _cachedUserContext!;
    }

    // Cache expiré ou inexistant, récupérer depuis la DB
    debugPrint('🔄 Fetching user context from database...');
    _cachedUserContext = await _getUserContext(userId);
    _cachedUserId = userId;
    _userContextTimestamp = DateTime.now();
    debugPrint('✅ Cached user context (valid for ${_userContextCacheDuration.inMinutes} minutes)');

    return _cachedUserContext!;
  }

  /// Invalider le cache (utile après une séance terminée ou changement de langue)
  static void invalidateCache() {
    _cachedExercises = null;
    _cachedExercisesLanguage = null;
    _cacheTimestamp = null;
    _cachedUserContext = null;
    _cachedUserId = null;
    _userContextTimestamp = null;
    debugPrint('🗑️ Cache invalidated');
  }

  /// Récupérer le contexte utilisateur avec performances DÉTAILLÉES
  static Future<String> _getUserContext(String userId) async {
    try {
      // Récupérer les sessions uniques (comptage)
      final recentSessions = await Supabase.instance.client
          .from('workout_session_summaries')
          .select('id, performed_at')
          .eq('user_id', userId)
          .order('performed_at', ascending: false)
          .limit(50);

      final sessionCount = recentSessions.length;

      // Récupérer les performances détaillées par exercice depuis workout_set_history
      final performanceHistory = await Supabase.instance.client
          .from('workout_set_history')
          .select('exercise_id, exercise_name, weight, reps, performed_at')
          .eq('user_id', userId)
          .order('performed_at', ascending: false)
          .limit(100); // Optimisé : 100 séries suffisent pour une bonne analyse

      // Analyser les performances par exercice
      final Map<String, Map<String, dynamic>> exerciseStats = {};

      for (final setData in performanceHistory) {
        final exerciseName = setData['exercise_name'] as String?;
        final weight = (setData['weight'] as num?)?.toDouble() ?? 0;
        final reps = (setData['reps'] as int?) ?? 0;

        if (exerciseName == null || exerciseName.isEmpty) continue;

        if (weight > 0 && reps > 0) {
          if (!exerciseStats.containsKey(exerciseName)) {
            exerciseStats[exerciseName] = {
              'max_weight': weight,
              'max_reps': reps,
              'avg_weight': weight,
              'avg_reps': reps,
              'count': 1,
              'total_weight': weight,
              'total_reps': reps,
            };
          } else {
            final stats = exerciseStats[exerciseName]!;
            stats['max_weight'] = (stats['max_weight'] as double) > weight
                ? stats['max_weight']
                : weight;
            stats['max_reps'] = (stats['max_reps'] as int) > reps
                ? stats['max_reps']
                : reps;
            stats['count'] = (stats['count'] as int) + 1;
            stats['total_weight'] = (stats['total_weight'] as double) + weight;
            stats['total_reps'] = (stats['total_reps'] as int) + reps;
            stats['avg_weight'] = (stats['total_weight'] as double) / (stats['count'] as int);
            stats['avg_reps'] = ((stats['total_reps'] as int) / (stats['count'] as int)).round();
          }
        }
      }

      // Construire le contexte détaillé
      final buffer = StringBuffer();
      buffer.writeln('USER TRAINING HISTORY:');
      buffer.writeln('- Total sessions: $sessionCount');
      buffer.writeln('- Experience level: ${sessionCount > 20 ? 'Advanced' : sessionCount > 10 ? 'Intermediate' : 'Beginner'}');
      buffer.writeln();

      if (exerciseStats.isNotEmpty) {
        buffer.writeln('RECENT PERFORMANCE BY EXERCISE (use this to suggest appropriate weights/reps):');
        buffer.writeln('IMPORTANT: Suggest weights based on these records. For exercises not in this list, suggest beginner weights.');
        buffer.writeln();

        // Trier par fréquence d'utilisation
        final sortedExercises = exerciseStats.entries.toList()
          ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

        for (final entry in sortedExercises.take(20)) {
          final name = entry.key;
          final stats = entry.value;
          final avgWeight = stats['avg_weight'] as double;
          final suggestedWeight = _roundToGymWeight(avgWeight * 0.9);

          buffer.writeln('  - $name:');
          buffer.writeln('    * Best performance: ${stats['max_weight']}kg × ${stats['max_reps']} reps');
          buffer.writeln('    * Average: ${avgWeight.toStringAsFixed(1)}kg × ${stats['avg_reps']} reps');
          buffer.writeln('    * Times performed: ${stats['count']}');
          buffer.writeln('    → Suggested weight: ${suggestedWeight}kg');
        }
        // Calculer le niveau de force global de l'utilisateur
        final allWeights = exerciseStats.values.map((s) => s['avg_weight'] as double).toList();
        final avgOverallWeight = allWeights.isNotEmpty
            ? allWeights.reduce((a, b) => a + b) / allWeights.length
            : 0.0;
        final isStrong = avgOverallWeight > 30;
        final isIntermediate = avgOverallWeight > 15;

        buffer.writeln();
        buffer.writeln('USER STRENGTH LEVEL: ${isStrong ? "ADVANCED" : isIntermediate ? "INTERMEDIATE" : "BEGINNER"}');
        buffer.writeln('Average weight across all exercises: ${avgOverallWeight.toStringAsFixed(1)}kg');
        buffer.writeln();
        buffer.writeln('For exercises NOT in this list, EXTRAPOLATE weights based on:');
        buffer.writeln('1. Similar exercises in the same muscle group (use ~80% of that weight)');
        buffer.writeln('2. The user\'s overall strength level shown above');
        buffer.writeln();
        if (isStrong) {
          buffer.writeln('This is an ADVANCED lifter. Suggest meaningful weights:');
          buffer.writeln('- Compound upper body (bench, rows, OHP): 30-50kg');
          buffer.writeln('- Isolation upper body (curls, extensions): 10-20kg');
          buffer.writeln('- Compound lower body (squat, deadlift, leg press): 60-100kg');
          buffer.writeln('- Isolation lower body (leg curl, calf raise): 30-50kg');
        } else if (isIntermediate) {
          buffer.writeln('This is an INTERMEDIATE lifter. Suggest appropriate weights:');
          buffer.writeln('- Compound upper body: 20-35kg');
          buffer.writeln('- Isolation upper body: 8-15kg');
          buffer.writeln('- Compound lower body: 40-70kg');
          buffer.writeln('- Isolation lower body: 20-35kg');
        } else {
          buffer.writeln('Lighter weights recorded - suggest conservative weights:');
          buffer.writeln('- Compound upper body: 10-20kg');
          buffer.writeln('- Isolation upper body: 5-10kg');
          buffer.writeln('- Compound lower body: 20-40kg');
          buffer.writeln('- Isolation lower body: 10-20kg');
        }
      } else {
        buffer.writeln('No previous performance data available.');
        buffer.writeln('This appears to be a NEW USER. Suggest beginner-friendly weights:');
        buffer.writeln('- Compound upper body exercises (bench, rows): 15-20kg');
        buffer.writeln('- Isolation upper body (curls, extensions): 5-10kg');
        buffer.writeln('- Compound lower body (squat, leg press): 20-40kg');
        buffer.writeln('- Isolation lower body: 10-20kg');
        buffer.writeln('- Core exercises: bodyweight or 5-10kg');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error fetching user context: $e');
      return 'No training history available. SUGGEST BEGINNER-FRIENDLY WEIGHTS (10-15kg upper body, 20-30kg lower body).';
    }
  }

  /// Construire la liste d'exercices disponibles AVEC IDs pour le prompt
  static String _buildExercisesList(List<Exercise> exercises, LocalizationService locService) {
    final isFrench = locService.isFrench;
    final buffer = StringBuffer();

    // Grouper par groupe musculaire
    final Map<String, List<Exercise>> groupedExercises = {};
    for (final exercise in exercises) {
      final isGerman = locService.isGerman;
      final group = exercise.muscleGroup.isNotEmpty
          ? exercise.muscleGroup
          : (isFrench ? 'Autre' : isGerman ? 'Andere' : 'Other');

      groupedExercises.putIfAbsent(group, () => []);
      groupedExercises[group]!.add(exercise);
    }

    buffer.writeln('AVAILABLE EXERCISES (${exercises.length} total) - USE EXACT NAMES:');
    buffer.writeln();

    // Lister TOUS les exercices par groupe avec IDs
    for (final entry in groupedExercises.entries) {
      buffer.writeln('${entry.key}:');
      for (final exercise in entry.value) {
        buffer.writeln('  - "${exercise.name}" (ID: ${exercise.id})');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Construire le prompt Gemini complet avec instructions améliorées
  static String _buildGeminiPrompt({
    required String userRequest,
    required String exercisesList,
    required String userContext,
    required String userLanguage,
    int? durationMinutes,
    double? intensity,
    String? focus,
    List<String>? equipment,
  }) {
    final durationText = durationMinutes != null ? '$durationMinutes minutes' : 'optimal duration';
    final intensityText = intensity != null
        ? (intensity < 0.33 ? 'Light' : intensity < 0.67 ? 'Moderate' : 'Intense')
        : 'Moderate';
    final focusText = focus ?? 'Hypertrophy';
    final equipmentText = equipment != null && equipment.isNotEmpty
        ? equipment.join(', ')
        : 'All available equipment';

    return '''
You are an expert personal trainer with access to a database of exercises and the user's training history.

USER REQUEST: "$userRequest"

PARAMETERS:
- Duration: $durationText
- Intensity: $intensityText
- Focus: $focusText
- Equipment: $equipmentText

$userContext

$exercisesList

CRITICAL REQUIREMENTS:
1. **USE ONLY EXERCISES FROM THE PROVIDED LIST ABOVE** - NEVER invent exercise names
2. Return exercise names EXACTLY as they appear between quotes in the list (matching $userLanguage language)
3. If you cannot find an exact match, choose the CLOSEST equivalent from the list
4. Match the requested duration (typically 4-6 exercises for 45-60 min, 3-4 for 30 min, 6-8 for 90 min)
5. Order exercises logically: compound movements first, isolation exercises later
6. Consider muscle group balance and recovery
7. **CRITICAL - WEIGHT SUGGESTIONS**:
   - For exercises the user has done: use the "Suggested weight" value provided in the history
   - For NEW exercises: EXTRAPOLATE based on user's strength level:
     * Look at similar exercises in the same muscle group (use ~80% of that weight)
     * Consider the USER STRENGTH LEVEL indicated (ADVANCED/INTERMEDIATE/BEGINNER)
     * An advanced lifter doing a new exercise should NOT get beginner weights!
   - **ALWAYS round to gym increments**: 2.5kg, 5kg, 7.5kg, 10kg, 12.5kg, 15kg, 17.5kg, 20kg, etc.
   - NEVER suggest weights like 16.4kg or 18.7kg - only multiples of 2.5kg
   - Example: If user benches 60kg avg, suggest ~25-30kg for OHP (not 10kg!)
8. Suggest appropriate reps (6-15) based on focus:
   - Strength: 4-6 reps, heavier weights
   - Hypertrophy: 8-12 reps, moderate weights
   - Endurance: 12-15 reps, lighter weights

OUTPUT FORMAT (JSON):
{
  "session_name": "Creative name for this workout in $userLanguage",
  "description": "Brief workout description",
  "estimated_duration_minutes": 45,
  "exercises": [
    {
      "exercise_name": "EXACT name from list (in quotes)",
      "exercise_id": "ID from the list",
      "muscle_group": "Primary muscle group",
      "sets": 4,
      "target_reps": 10,
      "suggested_weight_kg": 15.0,
      "rest_seconds": 90,
      "notes": "Execution tips in $userLanguage"
    }
  ],
  "suggestions": "1-2 SHORT personalized tips about THIS specific workout (focus, progression, technique) in $userLanguage - max 2 sentences"
}

EXAMPLE (if user requests "Haut du corps" and has done "Développé couché" at 40kg average - INTERMEDIATE level):
{
  "exercises": [
    {
      "exercise_name": "Développé couché",
      "exercise_id": "xxx-yyy-zzz",
      "sets": 4,
      "target_reps": 10,
      "suggested_weight_kg": 35.0,
      "notes": "Poids basé sur ton historique (40kg moy → 35kg suggéré)"
    },
    {
      "exercise_name": "Rowing barre",
      "exercise_id": "aaa-bbb-ccc",
      "sets": 4,
      "target_reps": 12,
      "suggested_weight_kg": 30.0,
      "notes": "Dos droit, tirez vers le nombril"
    },
    {
      "exercise_name": "Développé militaire",
      "exercise_id": "bbb-ccc-ddd",
      "sets": 3,
      "target_reps": 10,
      "suggested_weight_kg": 20.0,
      "notes": "Nouvel exercice - extrapolé de ton développé couché (~50% du bench)"
    }
  ],
  "suggestions": "Cette séance équilibre push et pull. Le poids au développé militaire est estimé à partir de ton bench - ajuste si trop lourd/léger."
}

GOOD SUGGESTIONS EXAMPLES:
- "Séance focalisée sur l'hypertrophie avec temps sous tension élevé. Garde 60-90s de repos entre les séries."
- "Tu progresses bien sur le squat (25kg aujourd'hui vs 22.5kg la semaine dernière). Continue comme ça!"
- "Séance full body pour maximiser les calories brûlées. Pense à bien t'échauffer 5-10min avant."
- "Les poids sont plus légers aujourd'hui pour perfectionner ta technique. Focus sur la connexion esprit-muscle."
- "Programme push-pull-legs classique. Assure-toi de bien manger des protéines après cette séance intensive."

BAD SUGGESTIONS (too generic):
- "N'oubliez pas de vous échauffer et de vous hydrater."
- "Mangez des protéines pour la récupération."
- "Reposez-vous bien entre les séries."

NOTE: All weights are multiples of 2.5kg (gym standard increments).

**IF AN EXERCISE NAME IS NOT IN THE LIST, REPLACE IT WITH THE CLOSEST EQUIVALENT FROM THE LIST.**

Generate the workout now as valid JSON:
''';
  }

  /// Appeler l'API Gemini
  static Future<Map<String, dynamic>?> _callGeminiAPI(String prompt) async {
    try {
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          ...GeminiConfig.generationConfig,
          'temperature': 0.5, // Réduit pour plus de précision sur les noms
          'maxOutputTokens': 3072, // Augmenté pour accueillir plus d'exercices et poids
        },
        'safetySettings': GeminiConfig.safetySettingsList,
      };

      final response = await http.post(
        Uri.parse(GeminiConfig.fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Gemini API request timeout after 15 seconds');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final candidates = jsonResponse['candidates'] as List?;

        if (candidates == null || candidates.isEmpty) {
          return null;
        }

        final textResponse = candidates[0]['content']['parts'][0]['text'] as String;
        return _parseGeminiResponse(textResponse);
      }

      return null;
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      return null;
    }
  }

  /// Parser la réponse JSON de Gemini
  static Map<String, dynamic>? _parseGeminiResponse(String textResponse) {
    try {
      // Chercher le JSON dans la réponse
      final jsonStartIndex = textResponse.indexOf('{');
      final jsonEndIndex = textResponse.lastIndexOf('}') + 1;

      if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
        final jsonString = textResponse.substring(jsonStartIndex, jsonEndIndex);
        return json.decode(jsonString) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      return null;
    }
  }

  /// Arrondir le poids aux incréments de salle (2.5kg, 5kg, 7.5kg, 10kg, etc.)
  static double _roundToGymWeight(double weight) {
    if (weight <= 0) return 0;

    // Arrondir au multiple de 2.5kg le plus proche
    // Ex: 16.4 → 15.0, 18.7 → 20.0
    return (weight / 2.5).round() * 2.5;
  }

  /// Parser et valider la séance générée avec poids suggérés
  static Future<List<WorkoutExercise>> _parseAndValidateWorkout(
    Map<String, dynamic> response,
    List<Exercise> availableExercises,
    LocalizationService locService,
  ) async {
    final List<WorkoutExercise> workoutExercises = [];

    try {
      final exercisesData = response['exercises'] as List?;
      if (exercisesData == null) return [];

      // Créer une map pour lookup rapide des exercices (par nom ET par ID)
      final exerciseMapByName = <String, Exercise>{};
      final exerciseMapById = <String, Exercise>{};
      for (final ex in availableExercises) {
        exerciseMapByName[ex.name.toLowerCase().trim()] = ex;
        exerciseMapById[ex.id] = ex;
      }

      for (final exerciseData in exercisesData) {
        final exerciseName = (exerciseData['exercise_name'] as String?)?.trim() ?? '';
        final exerciseId = (exerciseData['exercise_id'] as String?)?.trim();

        // Chercher l'exercice par ID d'abord, puis par nom
        Exercise? foundExercise;

        if (exerciseId != null && exerciseMapById.containsKey(exerciseId)) {
          foundExercise = exerciseMapById[exerciseId];
        } else {
          foundExercise = exerciseMapByName[exerciseName.toLowerCase()];
        }

        if (foundExercise == null) {
          debugPrint('⚠️ Exercise not found: $exerciseName (ID: $exerciseId)');
          continue; // Skip si l'exercice n'existe pas
        }

        // Créer les séries avec le poids suggéré par Gemini (arrondi aux incréments de salle)
        final sets = (exerciseData['sets'] as int?) ?? 3;
        final targetReps = (exerciseData['target_reps'] as int?) ?? 10;
        final rawWeight = (exerciseData['suggested_weight_kg'] as num?)?.toDouble() ?? 0;
        final suggestedWeight = _roundToGymWeight(rawWeight);

        final workoutSets = List.generate(sets, (index) => ExerciseSet(
          reps: targetReps,
          weight: suggestedWeight, // Poids arrondi aux incréments de salle
          isCompleted: false,
        ));

        workoutExercises.add(WorkoutExercise(
          exercise: foundExercise,
          sets: workoutSets,
          suggestedRepsMin: targetReps - 2,
          suggestedRepsMax: targetReps + 2,
        ));
      }

      debugPrint('✅ Generated ${workoutExercises.length} valid exercises from AI with suggested weights');
      return workoutExercises;

    } catch (e) {
      debugPrint('Error parsing workout exercises: $e');
      return [];
    }
  }
}

/// Résultat de la génération de séance
class AIWorkoutResult {
  final bool success;
  final List<WorkoutExercise> exercises;
  final String? error;
  final double processingTime;
  final String? aiSuggestions;

  AIWorkoutResult({
    required this.success,
    required this.exercises,
    this.error,
    required this.processingTime,
    this.aiSuggestions,
  });

  factory AIWorkoutResult.success({
    required List<WorkoutExercise> exercises,
    required double processingTime,
    String? aiSuggestions,
  }) {
    return AIWorkoutResult(
      success: true,
      exercises: exercises,
      processingTime: processingTime,
      aiSuggestions: aiSuggestions,
    );
  }

  factory AIWorkoutResult.error({
    required String error,
    required double processingTime,
  }) {
    return AIWorkoutResult(
      success: false,
      exercises: [],
      error: error,
      processingTime: processingTime,
    );
  }
}
