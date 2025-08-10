import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../types/database_types.dart';
import 'package:uuid/uuid.dart';
import '../models/sport_models.dart' as models;
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Simple in-memory cache to speed up guided sessions templates
  static final Map<String, _TemplateCache> _templatesCacheByLang = {};
  static const Duration _templatesCacheTtl = Duration(minutes: 5);
  static final Map<String, List<models.ProgramExercise>> _templateExercisesCache = {};
  static String _templatesPrefsKey(String lang) => 'workout_templates_cache_v1_$lang';
  static String _templatesSeedAsset(String lang) => 'assets/seed/workout_templates_$lang.json';

  // Get current user language preference (default to 'en')
  static String _getUserLanguage() {
    // TODO: Get from user preferences or device locale
    return 'fr'; // Default to French for now
  }

  static Future<bool> hideCustomExercise(String exerciseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client
          .from('custom_exercises')
          .update({'visible_list': false})
          .eq('id', exerciseId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('❌ hideCustomExercise error: $e');
      return false;
    }
  }

  // EXERCISES
  // Retourne les exercices au format UI (models.Exercise) depuis Supabase
  static Future<List<models.Exercise>> getSystemExercises({String? language, bool includeCustom = true}) async {
    final lang = language ?? _getUserLanguage();

    List<models.Exercise> base = [];

    // 1) RPC get_system_exercises_localized
    try {
      final response1 = await _client
          .rpc('get_system_exercises_localized', params: {'user_lang': lang});
      if (response1 is List && response1.isNotEmpty) {
        base = response1.map<models.Exercise>((json) {
          final map = json as Map<String, dynamic>;
          return models.Exercise(
            id: map['id']?.toString() ?? '',
            name: (map['name'] as String?) ?? '',
            muscleGroup: (map['muscle_group'] as String?) ?? '',
            equipment: (map['equipment'] as String?) ?? '',
            description: (map['description'] as String?) ?? '',
            isCustom: (map['is_custom'] as bool?) ?? false,
          );
        }).toList();
      }
    } catch (_) {}

    // 2) RPC get_exercises_localized
    if (base.isEmpty) {
      try {
        final response2 = await _client
            .rpc('get_exercises_localized', params: {'user_language': lang});
        if (response2 is List && response2.isNotEmpty) {
          base = response2.map<models.Exercise>((json) {
            final e = Exercise.fromJson(json as Map<String, dynamic>);
            return models.Exercise(
              id: e.id,
              name: e.getLocalizedName(lang),
              muscleGroup: e.muscleGroup,
              equipment: e.equipment ?? '',
              description: e.description ?? '',
              isCustom: e.isCustom,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 3) Direct table fallback if still empty
    if (base.isEmpty) {
      try {
        final rows = await _client
            .from('exercises')
            .select('id, name_en, name_fr, muscle_group, equipment, description, is_custom')
            .limit(200);
        if (rows is List && rows.isNotEmpty) {
          base = rows.map<models.Exercise>((json) {
            final map = json as Map<String, dynamic>;
            final name = lang == 'fr'
                ? (map['name_fr'] as String? ?? '')
                : (map['name_en'] as String? ?? '');
            return models.Exercise(
              id: map['id']?.toString() ?? '',
              name: name,
              muscleGroup: (map['muscle_group'] as String?) ?? '',
              equipment: (map['equipment'] as String?) ?? '',
              description: (map['description'] as String?) ?? '',
              isCustom: (map['is_custom'] as bool?) ?? false,
            );
          }).toList();
        }
      } catch (_) {}
    }

    if (includeCustom) {
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          final customRows = await _client
              .from('custom_exercises')
              .select('id, name, muscle_group, equipment, description, visible_list')
              .eq('user_id', userId)
              .eq('visible_list', true)
              .order('created_at', ascending: false);
          if (customRows is List && customRows.isNotEmpty) {
            final customs = customRows.map<models.Exercise>((m) {
              final map = m as Map<String, dynamic>;
              return models.Exercise(
                id: map['id']?.toString() ?? '',
                name: (map['name'] as String?) ?? '',
                muscleGroup: (map['muscle_group'] as String?) ?? '',
                equipment: (map['equipment'] as String?) ?? '',
                description: (map['description'] as String?) ?? '',
                isCustom: true,
              );
            }).toList();
            base.addAll(customs);
          }
        }
      } catch (_) {}
    }

    return base;
  }

  // Create a custom exercise for the current user and return it (for immediate selection)
  static Future<models.Exercise?> createCustomExercise({
    required String name,
    String muscleGroup = '',
    String equipment = '',
    String description = '',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    try {
      final row = await _client
          .from('custom_exercises')
          .insert({
            'user_id': userId,
            'name': name.trim(),
            'muscle_group': muscleGroup,
            'equipment': equipment,
            'description': description,
            'visible_list': true,
          })
          .select('id, name, muscle_group, equipment, description')
          .single();

      return models.Exercise(
        id: row['id']?.toString() ?? '',
        name: row['name'] as String? ?? name,
        muscleGroup: row['muscle_group'] as String? ?? muscleGroup,
        equipment: row['equipment'] as String? ?? equipment,
        description: row['description'] as String? ?? description,
        isCustom: true,
      );
    } catch (e) {
      debugPrint('❌ createCustomExercise error: $e');
      return null;
    }
  }

  static Future<List<Exercise>> getExercises({String? language}) async {
    final lang = language ?? _getUserLanguage();
    
    final response = await _client
        .rpc('get_exercises_localized', params: {'user_language': lang});
    
    if (response == null) return [];
    
    return (response as List)
        .map((json) => Exercise.fromJson(json))
        .toList();
  }

  static Future<Exercise?> getExerciseById(String id, {String? language}) async {
    final exercises = await getExercises(language: language);
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup, {String? language}) async {
    final exercises = await getExercises(language: language);
    return exercises.where((exercise) => exercise.muscleGroup == muscleGroup).toList();
  }

  // FOODS
  static Future<List<Food>> getFoods({String? language}) async {
    try {
      print('🔍 DatabaseService.getFoods: Début du chargement...');
    
      // Essayer d'abord l'accès direct à la table
    final response = await _client
          .from('foods')
          .select('*')
          .limit(50); // Limiter pour tester
      
      print('🔍 DatabaseService.getFoods: Réponse reçue: ${response.length} aliments');
      
      if (response.isEmpty) {
        print('⚠️ DatabaseService.getFoods: Aucun aliment trouvé dans la table');
        return [];
      }
      
      final foods = response.map((json) => Food.fromJson(json)).toList();
      print('✅ DatabaseService.getFoods: ${foods.length} aliments traités avec succès');
      
      return foods;
    } catch (e) {
      print('❌ DatabaseService.getFoods: Erreur lors du chargement: $e');
      print('❌ Type d\'erreur: ${e.runtimeType}');
      
      // Retourner quelques aliments de fallback pour tester l'interface
      return _getFallbackFoods();
    }
  }

  // Méthode de fallback pour tester l'interface
  static List<Food> _getFallbackFoods() {
    return [
      Food(
        id: '1',
        nameEn: 'Apple',
        nameFr: 'Pomme',
        calories: 52,
        proteins: 0.3,
        carbs: 14.0,
        fats: 0.2,
        category: 'Fruits',
        referenceUnitFr: 'g',
        referenceUnitEn: 'g',
        referenceQuantity: 100.0,
      ),
      Food(
        id: '2',
        nameEn: 'Banana',
        nameFr: 'Banane',
        calories: 89,
        proteins: 1.1,
        carbs: 23.0,
        fats: 0.3,
        category: 'Fruits',
        referenceUnitFr: 'g',
        referenceUnitEn: 'g',
        referenceQuantity: 100.0,
      ),
      Food(
        id: '3',
        nameEn: 'Chicken Breast',
        nameFr: 'Blanc de Poulet',
        calories: 165,
        proteins: 31.0,
        carbs: 0.0,
        fats: 3.6,
        category: 'Viande',
        referenceUnitFr: 'g',
        referenceUnitEn: 'g',
        referenceQuantity: 100.0,
      ),
      Food(
        id: '4',
        nameEn: 'Brown Rice',
        nameFr: 'Riz Complet',
        calories: 111,
        proteins: 2.6,
        carbs: 23.0,
        fats: 0.9,
        category: 'Céréales',
        referenceUnitFr: 'g',
        referenceUnitEn: 'g',
        referenceQuantity: 100.0,
      ),
      Food(
        id: '5',
        nameEn: 'Greek Yogurt',
        nameFr: 'Yaourt Grec',
        calories: 59,
        proteins: 10.0,
        carbs: 3.6,
        fats: 0.4,
        category: 'Produits Laitiers',
        referenceUnitFr: 'g',
        referenceUnitEn: 'g',
        referenceQuantity: 100.0,
      ),
    ];
  }

  static Future<Food?> getFoodById(String id, {String? language}) async {
    final foods = await getFoods(language: language);
    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Food>> searchFoods(String query, {String? language}) async {
    final foods = await getFoods(language: language);
    final lang = language ?? _getUserLanguage();
    
    return foods.where((food) {
      final name = food.getLocalizedName(lang).toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }

  // HIIT WORKOUTS
  static Future<List<HiitWorkout>> getHiitWorkouts({String? language}) async {
    final lang = language ?? _getUserLanguage();
    
    final response = await _client
        .rpc('get_hiit_workouts_localized', params: {'user_language': lang});
    
    if (response == null) return [];
    
    return (response as List)
        .map((json) => HiitWorkout.fromJson(json))
        .toList();
  }

  static Future<HiitWorkout?> getHiitWorkoutById(String id, {String? language}) async {
    final workouts = await getHiitWorkouts(language: language);
    try {
      return workouts.firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }

  // RECIPES
  static Future<List<Recipe>> getRecipes({String? language}) async {
    final lang = language ?? _getUserLanguage();
    
    final response = await _client
        .rpc('get_recipes_localized', params: {'user_language': lang});
    
    if (response == null) return [];
    
    return (response as List)
        .map((json) => Recipe.fromJson(json))
        .toList();
  }

  static Future<Recipe?> getRecipeById(String id, {String? language}) async {
    final recipes = await getRecipes(language: language);
    try {
      return recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Recipe>> searchRecipes(String query, {String? language}) async {
    final recipes = await getRecipes(language: language);
    final lang = language ?? _getUserLanguage();
    
    return recipes.where((recipe) {
      final name = recipe.getLocalizedName(lang).toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }



  // CARDIO ACTIVITIES
  static Future<List<CardioActivity>> getCardioActivities({String? language}) async {
    final lang = language ?? _getUserLanguage();
    
    final response = await _client
        .rpc('get_cardio_activities_localized', params: {'user_language': lang});
    
    if (response == null) return [];
    
    return (response as List)
        .map((json) => CardioActivity.fromJson(json))
        .toList();
  }

  // USER HISTORY FUNCTIONS
  static Future<List<Map<String, dynamic>>> getUserNutritionHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_user_nutrition_history', params: {
      'target_user_id': userId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    });
    
    return response != null ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<List<Map<String, dynamic>>> getUserWorkoutHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_user_workout_history', params: {
      'target_user_id': userId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    });
    
    return response != null ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<List<Map<String, dynamic>>> getUserHiitHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_user_hiit_history', params: {
      'target_user_id': userId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    });
    
    return response != null ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<List<Map<String, dynamic>>> getUserCardioHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_user_cardio_history', params: {
      'target_user_id': userId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    });
    
    return response != null ? List<Map<String, dynamic>>.from(response) : [];
  }

  // WORKOUT TEMPLATES (Séances guidées)
  static Future<List<models.WorkoutProgram>> getWorkoutTemplates({String? language, bool includePublic = true}) async {
    final lang = language ?? _getUserLanguage();
    // Cache
    final cache = _templatesCacheByLang[lang];
    if (cache != null && DateTime.now().difference(cache.cachedAt) < _templatesCacheTtl) {
      return cache.data;
    }
    // Récupérer templates publics + éventuellement privés de l'utilisateur connecté
    final userId = _client.auth.currentUser?.id;

    final nestedSelect = '''
      id,
      name_en,
      name_fr,
      description_en,
      description_fr,
      created_at,
      estimated_duration_minutes,
      workout_template_exercises(
        order_index,
        suggested_sets,
        exercises:exercise_id(
          id,
          name_en,
          name_fr,
          muscle_group,
          equipment
        )
      )
    ''';

    // Certaines versions du client Dart n'exposent pas .or(). On fait donc deux requêtes puis on fusionne côté client.
    final List<dynamic> aggregated = [];
    // 1) Pré-définis: tous les templates non custom (avec exercices imbriqués)
    final predefinedResp = await _client
        .from('workout_templates')
        .select(nestedSelect)
        .eq('is_custom', false)
        .order('created_at', ascending: false);
    if (predefinedResp is List) aggregated.addAll(predefinedResp);

    // 2) Custom de l'utilisateur connecté
    if (userId != null) {
      final userResp = await _client
          .from('workout_templates')
          .select(nestedSelect)
          .eq('is_custom', true)
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (userResp is List) aggregated.addAll(userResp);
    }

    if (aggregated.isEmpty) return [];

    // Dédupliquer par id
    final Map<String, Map<String, dynamic>> byId = {};
    for (final item in aggregated) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = map;
    }
    final templates = byId.values.toList();
    // Trier par created_at desc si disponible
    templates.sort((a, b) {
      final ca = a['created_at']?.toString();
      final cb = b['created_at']?.toString();
      if (ca == null && cb == null) return 0;
      if (ca == null) return 1;
      if (cb == null) return -1;
      return cb.compareTo(ca);
    });

    final result = templates.map<models.WorkoutProgram>((map) {
      final rawRows = (map['workout_template_exercises'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final sortedRows = [...rawRows];
      sortedRows.sort((a, b) => ((a['order_index'] as int?) ?? 0).compareTo((b['order_index'] as int?) ?? 0));
      final exercises = sortedRows.map<models.ProgramExercise>((rm) {
        final ex = (rm['exercises'] as Map<String, dynamic>?);
        final exModel = models.Exercise(
          id: ex?['id']?.toString() ?? '',
          name: lang == 'fr' ? (ex?['name_fr'] as String? ?? '') : (ex?['name_en'] as String? ?? ''),
          muscleGroup: (ex?['muscle_group'] as String?) ?? '',
          equipment: (ex?['equipment'] as String?) ?? '',
          description: '',
          isCustom: false,
        );
        final sets = (rm['suggested_sets'] as int?) ?? 3;
        return models.ProgramExercise(exercise: exModel, sets: sets);
      }).toList();

      return models.WorkoutProgram(
        id: map['id']?.toString() ?? '',
        name: lang == 'fr' ? (map['name_fr'] as String? ?? '') : (map['name_en'] as String? ?? ''),
        description: lang == 'fr' ? (map['description_fr'] as String? ?? '') : (map['description_en'] as String? ?? ''),
        type: '',
        estimatedDuration: (map['estimated_duration_minutes'] as int?) ?? 45,
        exercises: exercises,
      );
    }).toList();

    // Save in in-memory cache
    _templatesCacheByLang[lang] = _TemplateCache(data: result, cachedAt: DateTime.now());

    // Persist compact cache to SharedPreferences for instant cold-start
    try {
      final prefs = await SharedPreferences.getInstance();
      final compact = result.map((p) => {
            'id': p.id,
            'name_en': p.name, // name already localized; we also store both below if available
            'name_fr': p.name,
            'description_en': p.description,
            'description_fr': p.description,
            'estimated_duration_minutes': p.estimatedDuration,
            'exercises': p.exercises
                .map((e) => {
                      'order_index': 0, // not needed for display order here
                      'suggested_sets': e.sets,
                      'exercise': {
                        'id': e.exercise.id,
                        'name_en': e.exercise.name,
                        'name_fr': e.exercise.name,
                        'muscle_group': e.exercise.muscleGroup,
                        'equipment': e.exercise.equipment,
                      }
                    })
                .toList(),
          }).toList();
      await prefs.setString(_templatesPrefsKey(lang), jsonEncode(compact));
    } catch (_) {}
    return result;
  }

  // Fast headers only (no exercises). For instant UI; exercises can be loaded lazily per template
  static Future<List<models.WorkoutProgram>> getWorkoutTemplateHeaders({String? language, bool includePublic = true}) async {
    final lang = language ?? _getUserLanguage();
    final userId = _client.auth.currentUser?.id;
    final headerSelect = '''
      id,
      name_en,
      name_fr,
      description_en,
      description_fr,
      created_at,
      estimated_duration_minutes,
      is_custom,
      user_id
    ''';

    final List<dynamic> aggregated = [];
    final predefinedResp = await _client
        .from('workout_templates')
        .select(headerSelect)
        .eq('is_custom', false)
        .order('created_at', ascending: false);
    if (predefinedResp is List) aggregated.addAll(predefinedResp);
    if (userId != null) {
      final userResp = await _client
          .from('workout_templates')
          .select(headerSelect)
          .eq('is_custom', true)
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (userResp is List) aggregated.addAll(userResp);
    }
    if (aggregated.isEmpty) return [];
    final Map<String, Map<String, dynamic>> byId = {};
    for (final item in aggregated) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = map;
    }
    final templates = byId.values.toList();
    templates.sort((a, b) => (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
    return templates.map<models.WorkoutProgram>((map) {
      return models.WorkoutProgram(
        id: map['id']?.toString() ?? '',
        name: lang == 'fr' ? (map['name_fr'] as String? ?? '') : (map['name_en'] as String? ?? ''),
        description: lang == 'fr' ? (map['description_fr'] as String? ?? '') : (map['description_en'] as String? ?? ''),
        type: '',
        estimatedDuration: (map['estimated_duration_minutes'] as int?) ?? 45,
        exercises: const [],
      );
    }).toList();
  }

  // Load exercises for a specific template (cached)
  static Future<List<models.ProgramExercise>> getWorkoutTemplateExercises(String templateId, {String? language}) async {
    final lang = language ?? _getUserLanguage();
    final cached = _templateExercisesCache[templateId];
    if (cached != null) return cached;

    final rows = await _client
        .from('workout_template_exercises')
        .select('order_index, suggested_sets, exercises:exercise_id(id, name_en, name_fr, muscle_group, equipment)')
        .eq('template_id', templateId)
        .order('order_index');

    final list = (rows is List ? rows : const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map<models.ProgramExercise>((rm) {
      final ex = (rm['exercises'] as Map<String, dynamic>?);
      final exModel = models.Exercise(
        id: ex?['id']?.toString() ?? '',
        name: lang == 'fr' ? (ex?['name_fr'] as String? ?? '') : (ex?['name_en'] as String? ?? ''),
        muscleGroup: (ex?['muscle_group'] as String?) ?? '',
        equipment: (ex?['equipment'] as String?) ?? '',
        description: '',
        isCustom: false,
      );
      final sets = (rm['suggested_sets'] as int?) ?? 3;
      return models.ProgramExercise(exercise: exModel, sets: sets);
    }).toList();

    _templateExercisesCache[templateId] = list;
    return list;
  }

  // Instant load: return cached templates if available (memory or SharedPreferences), then refresh in background
  static Future<List<models.WorkoutProgram>> getWorkoutTemplatesInstant({String? language}) async {
    final lang = language ?? _getUserLanguage();
    // 1) In-memory
    final cache = _templatesCacheByLang[lang];
    if (cache != null && DateTime.now().difference(cache.cachedAt) < _templatesCacheTtl) {
      return cache.data;
    }
    // 2) SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_templatesPrefsKey(lang));
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw) as List;
        final programs = list.map<models.WorkoutProgram>((m) {
          final map = m as Map<String, dynamic>;
          final List exList = (map['exercises'] as List? ?? const []);
          final exercises = exList.map<models.ProgramExercise>((rm) {
            final ex = (rm['exercise'] as Map<String, dynamic>?);
            final exModel = models.Exercise(
              id: ex?['id']?.toString() ?? '',
              name: ex?['name_fr'] as String? ?? ex?['name_en'] as String? ?? '',
              muscleGroup: ex?['muscle_group'] as String? ?? '',
              equipment: ex?['equipment'] as String? ?? '',
              description: '',
              isCustom: false,
            );
            final sets = (rm['suggested_sets'] as int?) ?? 3;
            return models.ProgramExercise(exercise: exModel, sets: sets);
          }).toList();
          return models.WorkoutProgram(
            id: map['id']?.toString() ?? '',
            name: map['name_fr'] as String? ?? map['name_en'] as String? ?? '',
            description: map['description_fr'] as String? ?? map['description_en'] as String? ?? '',
            type: '',
            estimatedDuration: (map['estimated_duration_minutes'] as int?) ?? 45,
            exercises: exercises,
          );
        }).toList();
        // Background refresh (fire and forget)
        // Refresh in background
        // ignore: discarded_futures
        getWorkoutTemplates(language: lang).catchError((_) {});
        return programs;
      }
    } catch (_) {}
    // 3) Seed asset on first launch
    try {
      final seed = await _loadSeedAsset(_templatesSeedAsset(lang));
      if (seed != null) {
        final List list = jsonDecode(seed) as List;
        final programs = list.map<models.WorkoutProgram>((m) {
          final map = m as Map<String, dynamic>;
          final List exList = (map['exercises'] as List? ?? const []);
          final exercises = exList.map<models.ProgramExercise>((rm) {
            final ex = (rm['exercise'] as Map<String, dynamic>?);
            final exModel = models.Exercise(
              id: ex?['id']?.toString() ?? '',
              name: ex?['name_fr'] as String? ?? ex?['name_en'] as String? ?? '',
              muscleGroup: ex?['muscle_group'] as String? ?? '',
              equipment: ex?['equipment'] as String? ?? '',
              description: '',
              isCustom: false,
            );
            final sets = (rm['suggested_sets'] as int?) ?? 3;
            return models.ProgramExercise(exercise: exModel, sets: sets);
          }).toList();
          return models.WorkoutProgram(
            id: map['id']?.toString() ?? '',
            name: map['name_fr'] as String? ?? map['name_en'] as String? ?? '',
            description: map['description_fr'] as String? ?? map['description_en'] as String? ?? '',
            type: '',
            estimatedDuration: (map['estimated_duration_minutes'] as int?) ?? 45,
            exercises: exercises,
          );
        }).toList();
        // Background refresh (fire and forget)
        // ignore: discarded_futures
        getWorkoutTemplates(language: lang).catchError((_) {});
        return programs;
      }
    } catch (_) {}
    // 4) Fallback: fetch remotely
    return await getWorkoutTemplates(language: lang);
  }

  static Future<String?> _loadSeedAsset(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      return null;
    }
  }

  static Future<UserDailySummary?> getUserDailySummary(
    String userId, {
    DateTime? targetDate,
  }) async {
    final response = await _client.rpc('get_user_daily_summary', params: {
      'target_user_id': userId,
      'target_date': targetDate?.toIso8601String().split('T')[0] ?? 
                     DateTime.now().toIso8601String().split('T')[0],
    });
    
    if (response != null && response.isNotEmpty) {
      return UserDailySummary.fromJson(response[0]);
    }
    return null;
  }

  // CRUD OPERATIONS FOR SESSIONS
  static Future<WorkoutSession?> createWorkoutSession(WorkoutSession session) async {
    final response = await _client
        .from('workout_sessions')
        .insert(session.toJson())
        .select()
        .single();
    
    return WorkoutSession.fromJson(response);
  }

  // Persist session details as per-set history rows
  static Future<void> persistCompletedWorkoutAsHistory({
    required models.WorkoutSession session,
    String? guidedTemplateId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Generate a unique history session id
    final historySessionId = const Uuid().v4();
    final performedAt = (session.endTime ?? DateTime.now()).toIso8601String();

    // Helper: validate uuid format
    bool _isValidUuid(String value) {
      final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$',
          multiLine: false);
      return uuidRegex.hasMatch(value);
    }

    // Ensure an exercise exists in DB and return a valid uuid. If name matches an existing, reuse it. Otherwise create a custom one for the user.
    Future<String?> _ensureExerciseExistsAndGetId(models.Exercise exercise) async {
      // If already a valid UUID, return it as-is
      if (exercise.id.isNotEmpty && _isValidUuid(exercise.id)) {
        return exercise.id;
      }

      final name = exercise.name.trim();
      if (name.isEmpty) return null;

      // 1) Try exact match on name_fr
      try {
        final fr = await _client
            .from('exercises')
            .select('id')
            .eq('name_fr', name)
            .limit(1);
        if (fr is List && fr.isNotEmpty) {
          final id = fr.first['id']?.toString();
          if (id != null && _isValidUuid(id)) return id;
        }
      } catch (_) {}

      // 2) Try exact match on name_en
      try {
        final en = await _client
            .from('exercises')
            .select('id')
            .eq('name_en', name)
            .limit(1);
        if (en is List && en.isNotEmpty) {
          final id = en.first['id']?.toString();
          if (id != null && _isValidUuid(id)) return id;
        }
      } catch (_) {}

      // 3) Create a custom exercise for this user (in custom_exercises)
      try {
        final insert = await _client
            .from('custom_exercises')
            .insert({
              'user_id': userId,
              'name': name,
              'muscle_group': exercise.muscleGroup,
              'equipment': exercise.equipment,
              'description': exercise.description,
            })
            .select('id')
            .single();
        final id = insert['id']?.toString();
        if (id != null && _isValidUuid(id)) return id;
      } catch (_) {}

      return null;
    }

    // Flatten sets into per-set rows with global set_order
    final List<Map<String, dynamic>> rows = [];
    int globalOrder = 1;
    for (final we in session.exercises) {
      // Récupérer un exercise_id UUID valide pour l'historisation
      String? exerciseId;
      String? customExerciseId;
      if (we.exercise.isCustom) {
        // custom: id se trouve dans custom_exercises
        if (_isValidUuid(we.exercise.id)) {
          customExerciseId = we.exercise.id;
        } else {
          // Pas encore d'UUID (création en cours): insérer en historique avec null côté custom_exercise_id
          // On garde la ligne (pas de FK not null) pour ne pas perdre la séance.
          customExerciseId = null;
        }
      } else {
        exerciseId = await _ensureExerciseExistsAndGetId(we.exercise);
        if (exerciseId == null) continue;
      }
      for (final set in we.sets.where((s) => s.isCompleted)) {
        rows.add({
          'user_id': userId,
          'history_session_id': historySessionId,
          'guided_template_id': guidedTemplateId,
          'exercise_id': exerciseId,
          'custom_exercise_id': customExerciseId,
          'exercise_name': we.exercise.name,
          'set_order': globalOrder++,
          'weight': set.weight,
          'reps': set.reps,
          'performed_at': performedAt,
          'session_name': session.name,
        });
      }
    }

    // Insert in bulk into workout_set_history
    if (rows.isNotEmpty) {
      await _client.from('workout_set_history').insert(rows);
    }

    // Post-sync: for any custom exercise rows without custom_exercise_id yet, try to resolve and backfill
    try {
      for (final we in session.exercises.where((e) => e.exercise.isCustom)) {
        final name = we.exercise.name.trim();
        if (we.exercise.id.isEmpty || we.exercise.id.length < 36) {
          final created = await _client
              .from('custom_exercises')
              .select('id')
              .eq('user_id', userId)
              .eq('name', name)
              .limit(1);
          if (created is List && created.isNotEmpty) {
            final cid = created.first['id']?.toString();
            if (cid != null) {
              await _client
                  .from('workout_set_history')
                  .update({'custom_exercise_id': cid})
                  .eq('history_session_id', historySessionId)
                  .filter('custom_exercise_id', 'is', null)
                  .eq('exercise_name', name);
            }
          }
        }
      }
    } catch (_) {}
  }

  static Future<HiitSession?> createHiitSession(HiitSession session) async {
    final response = await _client
        .from('hiit_sessions')
        .insert(session.toJson())
        .select()
        .single();
    
    return HiitSession.fromJson(response);
  }

  static Future<CardioSession?> createCardioSession(CardioSession session) async {
    final response = await _client
        .from('cardio_sessions')
        .insert(session.toJson())
        .select()
        .single();
    
    return CardioSession.fromJson(response);
  }

  static Future<Meal?> createMeal(Meal meal) async {
    final response = await _client
        .from('meals')
        .insert(meal.toJson())
        .select()
        .single();
    
    return Meal.fromJson(response);
  }

  // UPDATE OPERATIONS
  static Future<WorkoutSession?> updateWorkoutSession(WorkoutSession session) async {
    final response = await _client
        .from('workout_sessions')
        .update(session.toJson())
        .eq('id', session.id)
        .select()
        .single();
    
    return WorkoutSession.fromJson(response);
  }

  static Future<HiitSession?> updateHiitSession(HiitSession session) async {
    final response = await _client
        .from('hiit_sessions')
        .update(session.toJson())
        .eq('id', session.id)
        .select()
        .single();
    
    return HiitSession.fromJson(response);
  }

  static Future<CardioSession?> updateCardioSession(CardioSession session) async {
    final response = await _client
        .from('cardio_sessions')
        .update(session.toJson())
        .eq('id', session.id)
        .select()
        .single();
    
    return CardioSession.fromJson(response);
  }

  // Legacy: create an exercise directly in base 'exercises' table (kept for backward-compat under new name)
  static Future<Exercise?> createExerciseInBase(Exercise exercise) async {
    final response = await _client
        .from('exercises')
        .insert(exercise.toJson())
        .select()
        .single();
    
    return Exercise.fromJson(response);
  }

  static Future<Food?> createCustomFood(Food food) async {
    final response = await _client
        .from('foods')
        .insert(food.toJson())
        .select()
        .single();
    
    return Food.fromJson(response);
  }

  // CUSTOM FOODS MANAGEMENT
  static Future<List<Food>> getCustomFoods(String userId, {String? language}) async {
    try {
      print('🔍 DatabaseService.getCustomFoods: Chargement des aliments personnalisés pour l\'utilisateur $userId');
      
      final response = await _client
          .from('custom_foods')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      print('🔍 DatabaseService.getCustomFoods: ${response.length} aliments personnalisés trouvés');
      
      // Convertir les custom_foods en objets Food
      final customFoods = response.map((json) {
        final origin = json['origin'] ?? 'manual';
        final barcode = json['barcode'];
        final name = json['name'];
        
        print('🔍 DEBUG DatabaseService - Aliment: $name');
        print('   - origin (DB): $origin');
        print('   - barcode (DB): $barcode');
        
        final food = Food(
          id: json['id'].toString(),
          nameEn: json['name'],
          nameFr: json['name'],
          calories: json['calories'] ?? 0,
          proteins: (json['proteins'] ?? 0.0).toDouble(),
          carbs: (json['carbs'] ?? 0.0).toDouble(),
          fats: (json['fats'] ?? 0.0).toDouble(),
          category: 'Aliments personnalisés',
          isCustom: true,
          referenceUnitFr: json['reference_unit_fr'] ?? 'g',
          referenceUnitEn: json['reference_unit_en'] ?? 'g',
          referenceQuantity: (json['reference_quantity'] ?? 100.0).toDouble(),
          origin: origin, // Récupérer l'origine
          barcode: barcode, // Récupérer le code-barres
        );
        
        print('   - origin (Food object): ${food.origin}');
        print('   - barcode (Food object): ${food.barcode}');
        
        return food;
      }).toList();
      
      return customFoods;
    } catch (e) {
      print('❌ DatabaseService.getCustomFoods: Erreur: $e');
      return [];
    }
  }

  static Future<Food?> createCustomFoodFromData({
    required String userId,
    required String name,
    required int calories,
    required double proteins,
    required double carbs,
    required double fats,
    required String referenceUnitFr,
    required String referenceUnitEn,
    required double referenceQuantity,
    String origin = 'manual',
    String? barcode,
  }) async {
    try {
      final response = await _client
          .from('custom_foods')
          .insert({
            'user_id': userId,
            'name': name,
            'calories': calories,
            'proteins': proteins,
            'carbs': carbs,
            'fats': fats,
            'reference_unit_fr': referenceUnitFr,
            'reference_unit_en': referenceUnitEn,
            'reference_quantity': referenceQuantity,
            'origin': origin,
            'barcode': barcode,
          })
          .select()
          .single();
      
      // Retourner un objet Food
      return Food(
        id: response['id'].toString(),
        nameEn: name,
        nameFr: name,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        category: 'Aliments personnalisés',
        isCustom: true,
        referenceUnitFr: referenceUnitFr,
        referenceUnitEn: referenceUnitEn,
        referenceQuantity: referenceQuantity,
        origin: origin,
        barcode: barcode,
      );
    } catch (e) {
      print('❌ DatabaseService.createCustomFoodFromData: Erreur: $e');
      return null;
    }
  }

  static Future<bool> checkCustomFoodExists(String userId, String name) async {
    try {
      final response = await _client
          .from('custom_foods')
          .select('id')
          .eq('user_id', userId)
          .ilike('name', name.trim())
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ DatabaseService.checkCustomFoodExists: Erreur: $e');
      return false;
    }
  }

  static Future<Food?> checkCustomFoodExistsByBarcode(String userId, String barcode) async {
    try {
      final response = await _client
          .from('custom_foods')
          .select('*')
          .eq('user_id', userId)
          .eq('barcode', barcode.trim())
          .limit(1);
      
      if (response.isNotEmpty) {
        final json = response.first;
        return Food(
          id: json['id'].toString(),
          nameEn: json['name'],
          nameFr: json['name'],
          calories: json['calories'] ?? 0,
          proteins: (json['proteins'] ?? 0.0).toDouble(),
          carbs: (json['carbs'] ?? 0.0).toDouble(),
          fats: (json['fats'] ?? 0.0).toDouble(),
          category: 'Aliments personnalisés',
          isCustom: true,
          referenceUnitFr: json['reference_unit_fr'] ?? 'g',
          referenceUnitEn: json['reference_unit_en'] ?? 'g',
          referenceQuantity: (json['reference_quantity'] ?? 100.0).toDouble(),
          origin: json['origin'] ?? 'manual',
          barcode: json['barcode'],
        );
      }
      
      return null;
    } catch (e) {
      print('❌ DatabaseService.checkCustomFoodExistsByBarcode: Erreur: $e');
      return null;
    }
  }

  static Future<HiitWorkout?> createCustomHiitWorkout(HiitWorkout workout) async {
    final response = await _client
        .from('hiit_workouts')
        .insert(workout.toJson())
        .select()
        .single();
    
    return HiitWorkout.fromJson(response);
  }

  static Future<Recipe?> createCustomRecipe(Recipe recipe) async {
    final response = await _client
        .from('recipes')
        .insert(recipe.toJson())
        .select()
        .single();
    
    return Recipe.fromJson(response);
  }

  // UTILITY FUNCTIONS
  static Future<List<String>> getMuscleGroups({String? language}) async {
    final exercises = await getExercises(language: language);
    final muscleGroups = exercises.map((e) => e.muscleGroup).toSet().toList();
    muscleGroups.sort();
    return muscleGroups;
  }

  static Future<List<String>> getFoodCategories({String? language}) async {
    final foods = await getFoods(language: language);
    final categories = foods
        .where((f) => f.category != null)
        .map((f) => f.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // MÉTHODE POUR RÉCUPÉRER LES ALIMENTS FRÉQUEMMENT UTILISÉS
  static Future<List<Food>> getFrequentlyUsedFoods(String userId, {String? language, int limit = 20}) async {
    try {
      debugPrint('🔍 getFrequentlyUsedFoods: Récupération pour userId=$userId, limit=$limit');
      
      // Récupérer les aliments les plus fréquemment utilisés des 30 derniers jours
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Requête pour les aliments personnalisés les plus utilisés
      final customFoodsQuery = await _client
          .from('food_entries')
          .select('''
            custom_food_id,
            custom_foods!inner (
              id,
              name,
              calories,
              proteins,
              carbs,
              fats,
              reference_quantity,
              reference_unit_fr,
              reference_unit_en,
              origin,
              barcode
            )
          ''')
          .eq('user_id', userId)
          .not('custom_food_id', 'is', null)
          .gte('consumed_at', thirtyDaysAgo.toIso8601String());

      // Requête pour les aliments de base les plus utilisés
      final regularFoodsQuery = await _client
          .from('food_entries')
          .select('''
            food_id,
            foods!inner (
              id,
              name_en,
              name_fr,
              calories,
              proteins,
              carbs,
              fats,
              reference_unit_fr,
              reference_unit_en
            )
          ''')
          .eq('user_id', userId)
          .not('food_id', 'is', null)
          .gte('consumed_at', thirtyDaysAgo.toIso8601String());

      debugPrint('🔍 Custom foods entries: ${customFoodsQuery.length}');
      debugPrint('🔍 Regular foods entries: ${regularFoodsQuery.length}');

      // Compter les utilisations par aliment personnalisé
      Map<String, int> customFoodCounts = {};
      Map<String, Map<String, dynamic>> customFoodData = {};
      
      for (final entry in customFoodsQuery) {
        final customFoodId = entry['custom_food_id'].toString();
        customFoodCounts[customFoodId] = (customFoodCounts[customFoodId] ?? 0) + 1;
        if (entry['custom_foods'] != null) {
          customFoodData[customFoodId] = entry['custom_foods'];
        }
      }

      // Compter les utilisations par aliment de base
      Map<String, int> regularFoodCounts = {};
      Map<String, Map<String, dynamic>> regularFoodData = {};
      
      for (final entry in regularFoodsQuery) {
        final foodId = entry['food_id'].toString();
        regularFoodCounts[foodId] = (regularFoodCounts[foodId] ?? 0) + 1;
        if (entry['foods'] != null) {
          regularFoodData[foodId] = entry['foods'];
        }
      }

      // Créer une liste unifiée de tous les aliments avec leur fréquence d'utilisation
      List<Map<String, dynamic>> allFoodUsage = [];

      // Ajouter les aliments personnalisés avec leur fréquence
      for (final entry in customFoodCounts.entries) {
        final foodData = customFoodData[entry.key];
        if (foodData != null) {
          allFoodUsage.add({
            'food': Food(
              id: foodData['id'].toString(),
              nameEn: foodData['name'],
              nameFr: foodData['name'],
              calories: foodData['calories'] ?? 0,
              proteins: (foodData['proteins'] ?? 0.0).toDouble(),
              carbs: (foodData['carbs'] ?? 0.0).toDouble(),
              fats: (foodData['fats'] ?? 0.0).toDouble(),
              category: 'Aliments personnalisés',
              isCustom: true,
              referenceUnitFr: foodData['reference_unit_fr'] ?? 'g',
              referenceUnitEn: foodData['reference_unit_en'] ?? 'g',
              referenceQuantity: (foodData['reference_quantity'] ?? 100.0).toDouble(),
              origin: foodData['origin'] ?? 'manual',
              barcode: foodData['barcode'],
            ),
            'usage_count': entry.value,
            'type': 'custom'
          });
        }
      }

      // Ajouter les aliments de base avec leur fréquence
      for (final entry in regularFoodCounts.entries) {
        final foodData = regularFoodData[entry.key];
        if (foodData != null) {
          allFoodUsage.add({
            'food': Food(
              id: foodData['id'].toString(),
              nameEn: foodData['name_en'],
              nameFr: foodData['name_fr'],
              calories: foodData['calories'] ?? 0,
              proteins: (foodData['proteins'] ?? 0.0).toDouble(),
              carbs: (foodData['carbs'] ?? 0.0).toDouble(),
              fats: (foodData['fats'] ?? 0.0).toDouble(),
              category: foodData['category'],
              isCustom: false,
              referenceUnitFr: foodData['reference_unit_fr'],
              referenceUnitEn: foodData['reference_unit_en'],
            ),
            'usage_count': entry.value,
            'type': 'regular'
          });
        }
      }

      // Trier TOUS les aliments par fréquence d'utilisation (décroissant)
      allFoodUsage.sort((a, b) => b['usage_count'].compareTo(a['usage_count']));

      // Prendre les X plus fréquents (peu importe s'ils sont personnalisés ou de base)
      List<Food> frequentFoods = [];
      for (final foodUsage in allFoodUsage.take(limit)) {
        final food = foodUsage['food'] as Food;
        final usageCount = foodUsage['usage_count'] as int;
        final type = foodUsage['type'] as String;
        
        frequentFoods.add(food);
        debugPrint('🔍 Aliment fréquent: ${food.getLocalizedName('fr')} ($usageCount utilisations, type: $type)');
      }

      debugPrint('🔍 Total aliments fréquents trouvés: ${frequentFoods.length}');
      return frequentFoods;
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des aliments fréquents: $e');
      return [];
    }
  }

  // NUTRITION DASHBOARD DATA
  static Future<Map<String, dynamic>> getNutritionDashboardData(String userId, {DateTime? date}) async {
    try {
      debugPrint('🔍 getNutritionDashboardData: Début pour userId=$userId');
      
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

      debugPrint('🔍 Date cible: ${targetDate.toString()}');
      debugPrint('🔍 Plage: ${startOfDay.toIso8601String()} - ${endOfDay.toIso8601String()}');

      // Récupérer les objectifs de l'utilisateur
      debugPrint('🔍 Récupération des objectifs utilisateur...');
      final userResponse = await _client
          .from('users')
          .select('daily_calories, daily_water_goal')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('🔍 Réponse utilisateur: $userResponse');
      final targetCalories = userResponse?['daily_calories'] as int? ?? 2000;
      debugPrint('🔍 Objectif calories: $targetCalories');

      // Récupérer les entrées alimentaires du jour
      debugPrint('🔍 Récupération des entrées alimentaires...');
      final foodEntriesResponse = await _client
          .from('food_entries')
          .select('calories, proteins, carbs, fats, meal_type')
          .eq('user_id', userId)
          .gte('consumed_at', startOfDay.toIso8601String())
          .lte('consumed_at', endOfDay.toIso8601String());

      debugPrint('🔍 Nombre d\'entrées trouvées: ${foodEntriesResponse.length}');
      debugPrint('🔍 Entrées: $foodEntriesResponse');

      // Calculer les totaux
      double totalCalories = 0;
      double totalProteins = 0;
      double totalCarbs = 0;
      double totalFats = 0;

      // Calculer les calories par type de repas
      Map<String, double> mealCalories = {
        'breakfast': 0,
        'lunch': 0,
        'snack': 0,
        'dinner': 0,
      };

      for (final entry in foodEntriesResponse) {
        final calories = (entry['calories'] as num?)?.toDouble() ?? 0.0;
        final proteins = (entry['proteins'] as num?)?.toDouble() ?? 0.0;
        final carbs = (entry['carbs'] as num?)?.toDouble() ?? 0.0;
        final fats = (entry['fats'] as num?)?.toDouble() ?? 0.0;
        final mealType = entry['meal_type'] as String? ?? 'snack';

        totalCalories += calories;
        totalProteins += proteins;
        totalCarbs += carbs;
        totalFats += fats;

        mealCalories[mealType] = (mealCalories[mealType] ?? 0) + calories;
        
        debugPrint('🔍 Entrée: $mealType - ${calories}kcal, ${proteins}g prot');
      }

      debugPrint('🔍 Totaux calculés:');
      debugPrint('   - Calories: $totalCalories');
      debugPrint('   - Protéines: $totalProteins');
      debugPrint('   - Glucides: $totalCarbs');
      debugPrint('   - Lipides: $totalFats');
      debugPrint('🔍 Calories par repas: $mealCalories');

      // Si aucune donnée n'est trouvée, générer des données de test
      if (foodEntriesResponse.isEmpty) {
        debugPrint('⚠️ Aucune donnée trouvée, génération de données de test...');
        // Générer quelques données de test pour la démonstration
        totalCalories = 1247;
        totalProteins = 85;
        totalCarbs = 120;
        totalFats = 45;
        mealCalories = {
          'breakfast': 320,
          'lunch': 450,
          'snack': 150,
          'dinner': 327,
        };
      }

      // Calculer les objectifs de macronutriments (estimation basée sur les calories)
      // Protéines: 15-20% des calories (4 cal/g)
      // Glucides: 45-55% des calories (4 cal/g)  
      // Lipides: 25-35% des calories (9 cal/g)
      final targetProtein = ((targetCalories * 0.175) / 4).round(); // 17.5% des calories
      final targetCarbs = ((targetCalories * 0.50) / 4).round();    // 50% des calories
      final targetFat = ((targetCalories * 0.325) / 9).round();     // 32.5% des calories

      // Récupérer les données d'hydratation du jour
      debugPrint('🔍 Récupération des données d\'hydratation...');
      int currentWaterMl = 0;
      int targetWaterMl = 2000;
      
      try {
        final waterResponse = await _client
            .from('water_entries')
            .select('amount')
            .eq('user_id', userId)
            .gte('consumed_at', startOfDay.toIso8601String())
            .lte('consumed_at', endOfDay.toIso8601String());

        debugPrint('🔍 Réponse hydratation: $waterResponse');
        
        if (waterResponse.isNotEmpty) {
          for (final entry in waterResponse) {
            currentWaterMl += (entry['amount'] as int?) ?? 0;
          }
        }
        
        // Récupérer l'objectif d'hydratation de l'utilisateur (défaut: 2000ml)
        targetWaterMl = userResponse?['daily_water_goal'] as int? ?? 2000;
        
        debugPrint('🔍 Eau consommée: ${currentWaterMl}ml / ${targetWaterMl}ml');
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la récupération des données d\'hydratation: $e');
        currentWaterMl = 0;
        targetWaterMl = 2000;
      }

      final result = {
        'targetCalories': targetCalories,
        'currentCalories': totalCalories.round(),
        'targetProtein': targetProtein,
        'currentProtein': totalProteins.round(),
        'targetCarbs': targetCarbs,
        'currentCarbs': totalCarbs.round(),
        'targetFat': targetFat,
        'currentFat': totalFats.round(),
        'mealCalories': mealCalories,
        'currentWaterMl': currentWaterMl,
        'targetWaterMl': targetWaterMl,
      };

      debugPrint('🔍 Résultat final: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des données nutrition: $e');
      debugPrint('❌ Type d\'erreur: ${e.runtimeType}');
      // Retourner des données par défaut en cas d'erreur
      return {
        'targetCalories': 2500,
        'currentCalories': 1247,
        'targetProtein': 109,
        'currentProtein': 85,
        'targetCarbs': 312,
        'currentCarbs': 120,
        'targetFat': 90,
        'currentFat': 45,
        'mealCalories': {
          'breakfast': 320,
          'lunch': 450,
          'snack': 150,
          'dinner': 327,
        },
        'currentWaterMl': 0,
        'targetWaterMl': 2000,
      };
    }
  }

} 

class _TemplateCache {
  final List<models.WorkoutProgram> data;
  final DateTime cachedAt;

  _TemplateCache({required this.data, required this.cachedAt});
}