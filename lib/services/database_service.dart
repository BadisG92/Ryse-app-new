import 'package:supabase_flutter/supabase_flutter.dart';
import '../types/database_types.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user language preference (default to 'en')
  static String _getUserLanguage() {
    // TODO: Get from user preferences or device locale
    return 'fr'; // Default to French for now
  }

  // EXERCISES
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
    final lang = language ?? _getUserLanguage();
    
    final response = await _client
        .rpc('get_foods_localized', params: {'user_language': lang});
    
    if (response == null) return [];
    
    return (response as List)
        .map((json) => Food.fromJson(json))
        .toList();
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

  // CUSTOM CONTENT CREATION
  static Future<Exercise?> createCustomExercise(Exercise exercise) async {
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

  // ERROR HANDLING
  static void _handleError(dynamic error) {
    print('Database Service Error: $error');
    // TODO: Implement proper error handling/logging
  }
} 