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


} 