import 'package:supabase_flutter/supabase_flutter.dart';
import '../types/database_types.dart' as db;
import '../models/sport_models.dart' as models;
import '../models/nutrition_models.dart';
import '../models/hiit_models.dart';
import '../models/cardio_session_models.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user language preference (default to 'en')
  static String _getUserLanguage() {
    // TODO: Get from user preferences or device locale
    return 'fr'; // Default to French for now
  }

  // EXERCISES
  static Future<List<models.Exercise>> getExercises({String? language}) async {
    final lang = language ?? _getUserLanguage();
    
    try {
      // Utiliser la nouvelle fonction pour récupérer les exercices système
      final response = await _client
          .rpc('get_system_exercises_localized', params: {'user_lang': lang});
      
      if (response == null) return [];
      
      return (response as List)
          .map((json) => _convertDbExerciseToModel(json, lang))
          .toList();
    } catch (e) {
      print('❌ DatabaseService.getExercises: Erreur lors du chargement: $e');
      
      // Fallback avec des exercices de base en cas d'erreur
      return _getFallbackExercises();
    }
  }

  // Convertir l'exercice de la DB vers le modèle utilisé par l'UI
  static models.Exercise _convertDbExerciseToModel(Map<String, dynamic> json, String language) {
    return models.Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '', // Le RPC retourne déjà le nom localisé
      muscleGroup: models.MuscleGroups.normalize(json['muscle_group'] ?? ''),
      equipment: json['equipment'] ?? '',
      description: json['description'] ?? '',
      isCustom: false, // Les exercices système ne sont jamais custom
    );
  }

  // Méthode de fallback pour les exercices
  static List<models.Exercise> _getFallbackExercises() {
    return [
      models.Exercise(
        id: '1',
        name: 'Pompes',
        muscleGroup: 'Pectoraux',
        equipment: 'Poids du corps',
        description: 'Exercice de base pour le haut du corps',
      ),
      models.Exercise(
        id: '2',
        name: 'Squats',
        muscleGroup: 'Jambes',
        equipment: 'Poids du corps',
        description: 'Exercice fondamental pour les jambes',
      ),
      models.Exercise(
        id: '3',
        name: 'Planche',
        muscleGroup: 'Tronc',
        equipment: 'Poids du corps',
        description: 'Exercice isométrique pour le core',
      ),
    ];
  }

  static Future<models.Exercise?> getExerciseById(String id, {String? language}) async {
    final exercises = await getExercises(language: language);
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<models.Exercise>> getExercisesByMuscleGroup(String muscleGroup, {String? language}) async {
    final exercises = await getExercises(language: language);
    return exercises.where((exercise) => exercise.muscleGroup == muscleGroup).toList();
  }

  // FOODS
  static Future<List<db.Food>> getFoods({String? language}) async {
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
      
      final foods = response.map((json) => db.Food.fromJson(json)).toList();
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
  static List<db.Food> _getFallbackFoods() {
    return [
      db.Food(
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
      db.Food(
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
      db.Food(
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
      db.Food(
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
      db.Food(
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

  static Future<db.Food?> getFoodById(String id, {String? language}) async {
    final foods = await getFoods(language: language);
    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<List<db.Food>> searchFoods(String query, {String? language}) async {
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
          .select('daily_calories, daily_protein, daily_carbs, daily_fat, daily_water_goal')
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

      // Si aucune donnée n'est trouvée, garder les valeurs à zéro
      if (foodEntriesResponse.isEmpty) {
        debugPrint('⚠️ Aucune donnée trouvée, conservation des valeurs par défaut à zéro');
      }

      // Récupérer les vrais objectifs de macronutriments de l'utilisateur
      final targetProtein = userResponse?['daily_protein'] as int? ?? ((targetCalories * 0.175) / 4).round();
      final targetCarbs = userResponse?['daily_carbs'] as int? ?? ((targetCalories * 0.50) / 4).round();
      final targetFat = userResponse?['daily_fat'] as int? ?? ((targetCalories * 0.325) / 9).round();
      
      debugPrint('🔍 Objectifs macros utilisateur:');
      debugPrint('   - Protéines: ${targetProtein}g');
      debugPrint('   - Glucides: ${targetCarbs}g');
      debugPrint('   - Lipides: ${targetFat}g');

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
        'currentCalories': 0,
        'targetProtein': 109,
        'currentProtein': 0,
        'targetCarbs': 312,
        'currentCarbs': 0,
        'targetFat': 90,
        'currentFat': 0,
        'mealCalories': {
          'breakfast': 0,
          'lunch': 0,
          'snack': 0,
          'dinner': 0,
        },
        'currentWaterMl': 0,
        'targetWaterMl': 2000,
      };
    }
  }

} 