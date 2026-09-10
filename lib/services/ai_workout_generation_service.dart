import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ryze_oneshot.dart';
import '../ai/ryze_transport.dart';
import '../config/gemini_config.dart';
import '../models/sport_models.dart';
import 'database_service.dart';
import 'exercise_resolver.dart';
import 'localization_service.dart';
import 'unit_service.dart';

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
    List<String>? constraints,
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
      final prompt = buildGeminiPrompt(
        userRequest: userRequest,
        constraints: constraints,
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

      // Si l'API échoue, utiliser le fallback
      if (response == null) {
        debugPrint('⚠️ Gemini API failed, using fallback template');
        final fallbackResult = await _generateFallbackWorkout(
          userRequest: userRequest,
          allExercises: allExercises,
          locService: locService,
          durationMinutes: durationMinutes,
        );

        stopwatch.stop();

        if (fallbackResult != null && fallbackResult.isNotEmpty) {
          debugPrint('✅ Fallback workout generated with ${fallbackResult.length} exercises');
          return AIWorkoutResult.success(
            exercises: fallbackResult,
            processingTime: stopwatch.elapsedMilliseconds / 1000.0,
            aiSuggestions: locService.isFrench
                ? 'Séance générée à partir de nos modèles (Coach Ryze était occupé)'
                : 'Workout generated from templates (Coach Ryze was busy)',
          );
        }

        return AIWorkoutResult.error(
          error: locService.isFrench
              ? 'Coach Ryze est temporairement indisponible, réessayez dans quelques instants'
              : 'Coach Ryze is temporarily unavailable, please try again shortly',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      // Parser et valider la réponse avec retry si exercices non trouvés
      final workoutExercises = await _parseAndValidateWorkout(
        response,
        allExercises,
        locService,
      );

      stopwatch.stop();

      // Si le parsing échoue, utiliser le fallback
      if (workoutExercises.isEmpty) {
        debugPrint('⚠️ Failed to parse AI response, using fallback template');
        final fallbackResult = await _generateFallbackWorkout(
          userRequest: userRequest,
          allExercises: allExercises,
          locService: locService,
          durationMinutes: durationMinutes,
        );

        if (fallbackResult != null && fallbackResult.isNotEmpty) {
          debugPrint('✅ Fallback workout generated with ${fallbackResult.length} exercises');
          return AIWorkoutResult.success(
            exercises: fallbackResult,
            processingTime: stopwatch.elapsedMilliseconds / 1000.0,
            aiSuggestions: locService.isFrench
                ? 'Séance générée à partir de nos modèles'
                : 'Workout generated from templates',
          );
        }

        return AIWorkoutResult.error(
          error: 'No valid exercises generated',
          processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        );
      }

      return AIWorkoutResult.success(
        exercises: workoutExercises,
        processingTime: stopwatch.elapsedMilliseconds / 1000.0,
        aiSuggestions: response['suggestions'] ?? '',
        sessionName: response['session_name'] as String?,
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
          buffer.writeln('    → Suggested weight: ${suggestedWeight.toStringAsFixed(1)}kg');
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

  /// Les noms du catalogue, groupe musculaire par groupe musculaire.
  ///
  /// Le générateur de séance a toujours eu cette liste sous les yeux ; le chat
  /// ne l'avait jamais vue. Il nommait donc les exercices de mémoire, et
  /// « bent over row » ne rejoignait pas « Rowing barre » : le même mouvement
  /// devenait deux lignes, avec deux historiques de charge.
  ///
  /// La liste ne restreint pas le choix — le catalogue est incomplet et Ryze
  /// doit pouvoir en sortir. Elle fixe l'orthographe de ce qui s'y trouve
  /// déjà, ce qui n'est pas la même chose.
  static Future<Map<String, List<String>>> catalogueByGroup() async {
    final exercises = await _getExercisesWithCache();
    final out = <String, List<String>>{};
    for (final e in exercises) {
      final name = e.name.trim();
      if (name.isEmpty) continue;
      out.putIfAbsent(e.muscleGroup.trim(), () => []).add(name);
    }
    out.remove('');
    return out;
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

    buffer.writeln('CATALOGUE (${exercises.length} exercises we already know):');
    buffer.writeln();

    // Les identifiants ne partent plus dans le prompt. Ils pesaient plus lourd
    // que les noms eux-mêmes, environ treize mille caractères sur vingt-six
    // mille, et le résolveur retrouve l'exercice à partir du seul nom.
    for (final entry in groupedExercises.entries) {
      buffer.writeln('${entry.key}:');
      for (final exercise in entry.value) {
        buffer.writeln('  - ${exercise.name}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Construire le prompt Gemini complet avec instructions améliorées
  /// Le prompt tel qu'il part, pour que le banc mesure ce que le modèle en
  /// fait plutôt qu'une copie qui dériverait.
  @visibleForTesting
  static String buildGeminiPrompt({
    required String userRequest,
    required String exercisesList,
    required String userContext,
    required String userLanguage,
    List<String>? constraints,
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
    // Les blessures dites au coach : elles étaient stockées et n'arrivaient
    // jamais jusqu'ici, si bien qu'un genou douloureux n'empêchait pas une
    // séance de squats.
    final constraintsText = constraints != null && constraints.isNotEmpty
        ? '''

⚠️ PHYSICAL CONSTRAINTS: ${constraints.join(', ')}
AVOID exercises that load these areas. Pick alternatives from the list that work the same muscle group without stressing them.
'''
        : '';

    return '''
You are an expert personal trainer with access to a database of exercises and the user's training history.

USER REQUEST: "$userRequest"

PARAMETERS:
- Duration: $durationText
- Intensity: $intensityText
- Focus: $focusText
- Equipment: $equipmentText
$constraintsText
$userContext

$exercisesList

CRITICAL REQUIREMENTS:
1. **PREFER THE CATALOGUE.** If the movement you want is in the list above, use its name exactly as written, in $userLanguage. A catalogue exercise comes with instructions and a tutorial link; an invented one does not.
2. **You MAY name an exercise that is not in the catalogue** when nothing in it fits what the user asked for. Do not distort the session to stay inside the list.
3. For EVERY exercise, catalogue or not, always fill "canonical_name_en" with the standard English name of the movement (e.g. "bench press", "russian twist", "hanging leg raise"). This is how the app recognises the same exercise across languages and spellings, so it must be the common English name, never a translation you invented.
4. Match the requested duration - adjust number of exercises proportionally:
   - ~15-30 min: 2-3 exercises
   - ~30-45 min: 3-5 exercises
   - ~45-60 min: 4-6 exercises
   - ~60-90 min: 6-8 exercises
   - ~90-120 min: 8-10 exercises
   Scale smoothly between these ranges based on exact duration requested
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
  "session_name": "Plain name for this session, in $userLanguage, at most 28 characters. Say what it is: the muscle groups, the goal the user asked for, or simply Full body. No superlative, no emoji, no exclamation mark.",
  "description": "Brief workout description",
  "estimated_duration_minutes": $durationText (use the EXACT requested duration),
  "exercises": [
    {
      "exercise_name": "Name in $userLanguage, exactly as in the catalogue when it is there",
      "canonical_name_en": "Standard English name of the movement - ALWAYS required",
      "muscle_group": "Primary muscle group",
      "equipment": "Main equipment, or bodyweight",
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
      "canonical_name_en": "bench press",
      "sets": 4,
      "target_reps": 10,
      "suggested_weight_kg": 35.0,
      "notes": "Poids basé sur ton historique (40kg moy → 35kg suggéré)"
    },
    {
      "exercise_name": "Rowing barre",
      "canonical_name_en": "barbell row",
      "sets": 4,
      "target_reps": 12,
      "suggested_weight_kg": 30.0,
      "notes": "Dos droit, tirez vers le nombril"
    },
    {
      "exercise_name": "Développé militaire",
      "canonical_name_en": "overhead press",
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

  /// Appeler le modèle, avec reprise et délai croissant.
  ///
  /// Trois essais : composer une séance est long, et une coupure réseau au
  /// milieu ne doit pas rendre l'écran bredouille. Le transport commun
  /// remplace le client qui posait la clé dans l'adresse.
  static Future<Map<String, dynamic>?> _callGeminiAPI(String prompt) async {
    const int maxRetries = 3;
    const Duration initialTimeout = Duration(seconds: 20);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🤖 Gemini API call attempt $attempt/$maxRetries');

        // Le délai s'allonge à chaque essai : un modèle lent finit souvent
        // par répondre si on lui laisse le temps.
        final timeout = Duration(seconds: initialTimeout.inSeconds + (attempt - 1) * 5);

        final text = await RyzeOneShot.text(
          prompt: prompt,
          surface: RyzeUsageLabel.workout,
          temperature: 0.5, // précis sur les noms d'exercices
          maxOutputTokens: 3072, // une séance entière avec ses charges
          timeout: timeout,
        );

        if (text == null) {
          debugPrint('⚠️ Aucune réponse (essai $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
          return null;
        }

        final parsed = _parseGeminiResponse(text);
        if (parsed == null) {
          debugPrint('⚠️ Réponse illisible (essai $attempt/$maxRetries)');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
          return null;
        }

        debugPrint('✅ Gemini API success on attempt $attempt');
        return parsed;
      } catch (e) {
        debugPrint('❌ Gemini API error (attempt $attempt/$maxRetries): $e');

        if (attempt < maxRetries) {
          final delay = Duration(seconds: attempt);
          debugPrint('⏳ Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }
        return null;
      }
    }

    return null;
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

  /// Arrondir le poids aux incréments de salle.
  ///
  /// C'était le multiple de 2,5 kg quelle que soit l'unité de
  /// l'utilisateur : une suggestion tombait donc sur 5,5 ou 16,5 livres,
  /// des nombres qu'aucun disque ne fait. Le service d'unités connaît le
  /// bon pas des deux côtés.
  static double _roundToGymWeight(double weight) => UnitService.instance.gymWeight(weight);

  /// Bâtir une séance à partir d'une liste d'exercices déjà choisie.
  ///
  /// La conversation compose elle-même la séance et la dicte : elle sait ce
  /// qu'elle vient d'annoncer à l'utilisateur, ce qu'un second modèle appelé
  /// dans son dos ne lui rendait jamais. Ryze énumérait alors des exercices
  /// qui n'étaient pas ceux enregistrés, et finissait par l'avouer.
  ///
  /// Chaque nom passe par le résolveur : le catalogue d'abord, sinon un
  /// exercice créé pour cet utilisateur, sans doublon possible.
  static Future<List<WorkoutExercise>> buildExercises(List<dynamic> exercises) async {
    if (exercises.isEmpty) return const [];
    final catalogue = await _getExercisesWithCache();
    final construits = await _parseAndValidateWorkout(
      {'exercises': exercises},
      catalogue,
      LocalizationService.instance,
    );
    return _withHistoryWeights(construits);
  }

  /// Recale les charges sur ce que l'utilisateur soulève vraiment.
  ///
  /// Quand le générateur composait la séance, il recevait l'historique et
  /// proposait des charges tirées des moyennes. La conversation, elle, écrit
  /// les exercices sans rien connaître de personne : elle a proposé soixante
  /// kilos au développé couché sans savoir à qui. Le chiffre du modèle ne sert
  /// donc que d'ultime repli, derrière ce que la personne a réellement porté.
  ///
  /// La règle est celle du générateur : quatre-vingt-dix pour cent de la
  /// moyenne récente, arrondie aux incréments de salle.
  static Future<List<WorkoutExercise>> _withHistoryWeights(List<WorkoutExercise> exercises) async {
    if (exercises.isEmpty) return exercises;

    final suggestions = await _suggestedWeights();
    if (suggestions.isEmpty) return exercises;

    return [
      for (final e in exercises)
        () {
          // L'identifiant d'abord : « Bench Press » et « Développé couché »
          // sont le même mouvement, et une moyenne par nom en ferait deux.
          final connu = suggestions[e.exercise.id] ??
              suggestions[ExerciseResolver.normalize(e.exercise.name)];
          if (connu == null || connu <= 0) return e;
          if (e.sets.isEmpty) return e;

          // Le poids du corps reste au poids du corps.
          if (e.sets.first.weight <= 0 && connu <= 0) return e;

          return e.copyWith(
            sets: [for (final s in e.sets) ExerciseSet(reps: s.reps, weight: connu, isCompleted: false)],
          );
        }(),
    ];
  }

  /// Ce que l'utilisateur porte, par exercice, d'après ses séries passées.
  static Future<Map<String, double>> _suggestedWeights() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const {};

    try {
      final rows = await Supabase.instance.client
          .from('workout_set_history')
          .select('exercise_id, exercise_name, weight')
          .eq('user_id', userId)
          .order('performed_at', ascending: false)
          .limit(200);

      final total = <String, double>{};
      final compte = <String, int>{};

      void ajoute(String? cle, double poids) {
        if (cle == null || cle.isEmpty) return;
        total[cle] = (total[cle] ?? 0) + poids;
        compte[cle] = (compte[cle] ?? 0) + 1;
      }

      for (final row in rows) {
        final poids = (row['weight'] as num?)?.toDouble() ?? 0;
        if (poids <= 0) continue;

        // Deux clés pour la même série : l'identifiant, qui réunit les
        // langues, et le nom normalisé pour les vieilles lignes qui n'en ont
        // pas. Chaque clé garde sa propre moyenne.
        ajoute(row['exercise_id'] as String?, poids);

        final nom = row['exercise_name'] as String?;
        if (nom != null && nom.trim().isNotEmpty) {
          ajoute(ExerciseResolver.normalize(nom), poids);
        }
      }

      return {
        for (final cle in total.keys)
          cle: _roundToGymWeight(total[cle]! / compte[cle]! * 0.9),
      };
    } catch (e) {
      debugPrint('⚠️ _suggestedWeights: $e');
      return const {};
    }
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

        // L'exercice que le catalogue ne connaît pas n'est plus jeté.
        //
        // Cette ligne faisait `continue` : une séance abdo proposée par Ryze
        // perdait en silence tout ce qui n'était pas au catalogue, et
        // l'utilisateur recevait une séance plus courte sans savoir pourquoi.
        // Le résolveur rend toujours un exercice réel, du catalogue ou créé
        // pour cet utilisateur, et le dédoublonnage est garanti par la base.
        foundExercise ??= await ExerciseResolver.resolve(
          name: exerciseName,
          canonicalEnglishName: exerciseData['canonical_name_en'] as String?,
          muscleGroup: exerciseData['muscle_group'] as String?,
          equipment: exerciseData['equipment'] as String?,
        );

        if (foundExercise == null) {
          debugPrint('⚠️ Exercise unresolved: $exerciseName (ID: $exerciseId)');
          continue;
        }

        // Créer les séries avec le poids suggéré par Gemini (arrondi aux incréments de salle)
        // Note: Gemini peut retourner des strings ou des ints, gérer les deux cas
        final setsRaw = exerciseData['sets'];
        final sets = setsRaw is int ? setsRaw : (int.tryParse(setsRaw?.toString() ?? '') ?? 3);

        final repsRaw = exerciseData['target_reps'];
        final targetReps = repsRaw is int ? repsRaw : (int.tryParse(repsRaw?.toString() ?? '') ?? 10);

        final weightRaw = exerciseData['suggested_weight_kg'];
        final rawWeight = weightRaw is num ? weightRaw.toDouble() : (double.tryParse(weightRaw?.toString() ?? '') ?? 0);
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

  // =====================================================
  // FALLBACK TEMPLATES
  // Utilisés quand l'IA n'est pas disponible
  // =====================================================

  /// Générer un workout de fallback basé sur des templates
  /// Analyse la demande utilisateur pour sélectionner le bon template
  static Future<List<WorkoutExercise>?> _generateFallbackWorkout({
    required String userRequest,
    required List<Exercise> allExercises,
    required LocalizationService locService,
    int? durationMinutes,
  }) async {
    try {
      debugPrint('🔄 Generating fallback workout for: $userRequest');

      // Analyser la demande pour déterminer le type de séance
      final requestLower = userRequest.toLowerCase();

      // Mapper les groupes musculaires par mots-clés
      String workoutType = 'full_body'; // Défaut

      // Push / Pecs / Épaules / Triceps
      if (_matchesKeywords(requestLower, ['push', 'pec', 'chest', 'poitrine', 'épaule', 'shoulder', 'tricep'])) {
        workoutType = 'push';
      }
      // Pull / Dos / Biceps
      else if (_matchesKeywords(requestLower, ['pull', 'dos', 'back', 'bicep', 'tirage'])) {
        workoutType = 'pull';
      }
      // Legs / Jambes
      else if (_matchesKeywords(requestLower, ['leg', 'jambe', 'squat', 'cuisse', 'fessier', 'glute', 'quad'])) {
        workoutType = 'legs';
      }
      // Upper body
      else if (_matchesKeywords(requestLower, ['upper', 'haut du corps', 'bras', 'arm'])) {
        workoutType = 'upper';
      }
      // Lower body
      else if (_matchesKeywords(requestLower, ['lower', 'bas du corps'])) {
        workoutType = 'legs';
      }
      // Full body
      else if (_matchesKeywords(requestLower, ['full', 'complet', 'total', 'entier'])) {
        workoutType = 'full_body';
      }

      debugPrint('📋 Detected workout type: $workoutType');

      // Sélectionner les exercices du template
      final templateExercises = _getTemplateExercises(workoutType, allExercises, locService);

      if (templateExercises.isEmpty) {
        debugPrint('❌ No exercises found for template: $workoutType');
        return null;
      }

      // Construire les WorkoutExercise avec des poids par défaut
      final workoutExercises = <WorkoutExercise>[];

      for (final exercise in templateExercises) {
        // Poids par défaut basé sur le groupe musculaire
        final defaultWeight = _getDefaultWeight(exercise);

        final sets = List.generate(3, (_) => ExerciseSet(
          reps: 10,
          weight: defaultWeight,
          isCompleted: false,
        ));

        workoutExercises.add(WorkoutExercise(
          exercise: exercise,
          sets: sets,
          suggestedRepsMin: 8,
          suggestedRepsMax: 12,
        ));
      }

      debugPrint('✅ Fallback generated ${workoutExercises.length} exercises');
      return workoutExercises;

    } catch (e) {
      debugPrint('❌ Error generating fallback workout: $e');
      return null;
    }
  }

  /// Vérifie si le texte contient un des mots-clés
  static bool _matchesKeywords(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Retourne les exercices pour un type de workout
  static List<Exercise> _getTemplateExercises(
    String workoutType,
    List<Exercise> allExercises,
    LocalizationService locService,
  ) {
    // Mapper des groupes musculaires à rechercher
    final Map<String, List<String>> muscleGroups = {
      'push': ['chest', 'pectoraux', 'shoulders', 'épaules', 'triceps'],
      'pull': ['back', 'dos', 'biceps', 'lats'],
      'legs': ['quadriceps', 'hamstrings', 'glutes', 'fessiers', 'calves', 'mollets', 'jambes'],
      'upper': ['chest', 'pectoraux', 'back', 'dos', 'shoulders', 'épaules', 'biceps', 'triceps'],
      'full_body': ['chest', 'pectoraux', 'back', 'dos', 'quadriceps', 'jambes', 'shoulders', 'épaules'],
    };

    final targetGroups = muscleGroups[workoutType] ?? muscleGroups['full_body']!;
    final selectedExercises = <Exercise>[];
    final usedMuscleGroups = <String>{};

    // Sélectionner 4-6 exercices variés
    for (final exercise in allExercises) {
      if (selectedExercises.length >= 6) break;

      final muscleGroup = exercise.muscleGroup.toLowerCase();

      // Vérifier si l'exercice correspond aux groupes cibles
      for (final target in targetGroups) {
        if (muscleGroup.contains(target.toLowerCase())) {
          // Éviter trop d'exercices du même groupe
          if (!usedMuscleGroups.contains(muscleGroup) || usedMuscleGroups.length >= 3) {
            selectedExercises.add(exercise);
            usedMuscleGroups.add(muscleGroup);
            break;
          }
        }
      }
    }

    // Si pas assez d'exercices, compléter avec des exercices de base
    if (selectedExercises.length < 4) {
      for (final exercise in allExercises) {
        if (selectedExercises.length >= 4) break;
        if (!selectedExercises.contains(exercise)) {
          selectedExercises.add(exercise);
        }
      }
    }

    return selectedExercises;
  }

  /// Retourne un poids par défaut basé sur le groupe musculaire
  static double _getDefaultWeight(Exercise exercise) {
    final muscleGroup = exercise.muscleGroup.toLowerCase();

    // Jambes = plus lourd
    if (muscleGroup.contains('quad') ||
        muscleGroup.contains('hamstring') ||
        muscleGroup.contains('glute') ||
        muscleGroup.contains('jambe') ||
        muscleGroup.contains('fessier')) {
      return 30.0;
    }

    // Dos / Pecs = moyen
    if (muscleGroup.contains('back') ||
        muscleGroup.contains('dos') ||
        muscleGroup.contains('chest') ||
        muscleGroup.contains('pec')) {
      return 20.0;
    }

    // Épaules
    if (muscleGroup.contains('shoulder') || muscleGroup.contains('épaule')) {
      return 12.5;
    }

    // Bras = plus léger
    if (muscleGroup.contains('bicep') || muscleGroup.contains('tricep')) {
      return 10.0;
    }

    // Défaut
    return 15.0;
  }
}

/// Résultat de la génération de séance
class AIWorkoutResult {
  final bool success;
  final List<WorkoutExercise> exercises;
  final String? error;
  final double processingTime;
  final String? aiSuggestions;

  /// Le nom que le modèle donne à la séance, dans la langue du compte.
  ///
  /// Il était demandé dans le format de sortie depuis toujours, le modèle le
  /// renvoyait, et rien ici ne l'accueillait : on payait des jetons pour un
  /// nom jeté, puis on nommait la séance en comptant ses groupes
  /// musculaires. « Séance de foot » redevenait « Legs & Abs ».
  final String? sessionName;

  AIWorkoutResult({
    required this.success,
    required this.exercises,
    this.error,
    required this.processingTime,
    this.aiSuggestions,
    this.sessionName,
  });

  factory AIWorkoutResult.success({
    required List<WorkoutExercise> exercises,
    required double processingTime,
    String? aiSuggestions,
    String? sessionName,
  }) {
    return AIWorkoutResult(
      success: true,
      exercises: exercises,
      processingTime: processingTime,
      aiSuggestions: aiSuggestions,
      sessionName: sessionName,
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
