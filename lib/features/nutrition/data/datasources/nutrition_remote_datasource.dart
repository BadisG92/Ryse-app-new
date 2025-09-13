import '../../../../core/data/datasources/remote_data_source.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../../../../components/ui/dashboard_models.dart';
import '../../../../models/nutrition_models.dart';
import '../../../../services/localization_service.dart';
import '../../../../services/translations.dart';

/// Data source remote pour la nutrition
/// Encapsule tous les appels Supabase liés à la nutrition
class NutritionRemoteDataSource extends RemoteDataSource {
  
  /// Récupère les données consolidées du dashboard
  Future<NutritionDashboardData> getDashboardData(DateTime date) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    
    // Utiliser executeWithRetry pour la fiabilité
    return executeWithRetry(() async {
      // Requêtes parallèles optimisées
      final futures = await Future.wait<dynamic>([
        // 1. Entrées de nourriture
        select('food_entries', 
          columns: 'calories, meal_id',
          filters: {
            'user_id': userId,
            'created_at': _getDateFilter(date),
          }
        ),
        
        // 2. Entrées d'eau
        select('water_entries',
          columns: 'amount',
          filters: {
            'user_id': userId,
            'consumed_at': _getDateFilter(date),
          }
        ),
        
        // 3. Profil utilisateur
        select('users',
          columns: 'daily_calories, daily_water_goal',
          filters: {'id': userId},
          limit: 1
        ),
        
        // 4. Repas du jour
        _getMealsData(date),
      ]);
      
      // Traitement des données
      final foodEntries = futures[0] as List;
      final waterEntries = futures[1] as List;
      final userProfile = (futures[2] as List).isNotEmpty ? futures[2][0] : {};
      final meals = futures[3] as List<Meal>;
      
      // Calculs
      final totalCalories = foodEntries.fold<double>(
        0, (sum, entry) => sum + (entry['calories'] ?? 0)
      );
      
      final totalWaterMl = waterEntries.fold<int>(
        0, (sum, entry) => sum + ((entry['amount'] ?? 0) as int)
      );
      
      final targetCalories = (userProfile['daily_calories'] ?? 2000).toDouble();
      final targetWaterL = ((userProfile['daily_water_goal'] ?? 2000) / 1000.0);
      
      // Construire les objectifs
      final goals = _buildDailyGoals(
        totalCalories: totalCalories,
        targetCalories: targetCalories,
        currentWaterL: totalWaterMl / 1000.0,
        targetWaterL: targetWaterL,
        mealsCount: meals.length,
      );
      
      return NutritionDashboardData(
        currentCalories: totalCalories,
        targetCalories: targetCalories,
        currentWaterL: totalWaterMl / 1000.0,
        targetWaterL: targetWaterL,
        mealsCount: meals.length,
        goals: goals,
        todayMeals: meals,
      );
    });
  }
  
  /// Récupère uniquement les objectifs quotidiens
  Future<List<DailyGoal>> getDailyGoals(DateTime date) async {
    final data = await getDashboardData(date);
    return data.goals;
  }
  
  /// Ajoute une entrée de nourriture
  Future<bool> addFoodEntry({
    required String userId,
    required String mealName,
    required FoodItem foodItem,
    required DateTime consumedAt,
    String? mealId,
  }) async {
    return executeQuery(() async {
      final data = {
        'user_id': userId,
        'meal_name': mealName,
        'meal_id': mealId ?? _generateMealId(mealName, consumedAt),
        'food_name': foodItem.name,
        'calories': foodItem.calories,
        'protein': foodItem.proteins,
        'carbs': foodItem.carbs,
        'fat': foodItem.fats,
        'quantity': foodItem.referenceQuantity ?? 1,
        'unit': foodItem.portion,
        'created_at': consumedAt.toIso8601String(),
      };
      
      if (foodItem.id != null) {
        data['food_id'] = foodItem.id!;
      }
      
      await insert('food_entries', data);
      return true;
    });
  }
  
  /// Ajoute une entrée d'eau
  Future<bool> addWaterEntry({
    required int amount,
    String sourceType = 'manual',
    String? notes,
    DateTime? consumedAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    
    return executeQuery(() async {
      await insert('water_entries', {
        'user_id': userId,
        'amount': amount,
        'source_type': sourceType,
        'notes': notes,
        'consumed_at': (consumedAt ?? DateTime.now()).toIso8601String(),
      });
      return true;
    });
  }
  
  /// Récupère les repas pour une date
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    return _getMealsData(date);
  }
  
  // === Méthodes privées helper ===
  
  String _getDateFilter(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
  
  String _generateMealId(String mealName, DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${mealName}_${dateStr}_$timestamp';
  }
  
  Future<List<Meal>> _getMealsData(DateTime date) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    final response = await select('food_entries',
      columns: '''
        meal_id,
        meal_name,
        food_name,
        calories,
        protein,
        carbs,
        fat,
        quantity,
        unit,
        created_at
      ''',
      filters: {
        'user_id': userId,
        'created_at': _getDateFilter(date),
      },
      orderBy: 'created_at',
    );
    
    // Grouper par meal_id
    final mealsMap = <String, List<Map<String, dynamic>>>{};
    for (final entry in response) {
      final mealId = entry['meal_id'] ?? 'unknown';
      mealsMap.putIfAbsent(mealId, () => []).add(entry);
    }
    
    // Convertir en objets Meal
    return mealsMap.entries.map((entry) {
      final mealEntries = entry.value;
      final firstEntry = mealEntries.first;
      
      // Créer les FoodItem
      final foods = mealEntries.map((e) => FoodItem(
        name: e['food_name'] ?? '',
        calories: e['calories'] ?? 0,
        proteins: e['protein']?.toDouble() ?? 0,
        carbs: e['carbs']?.toDouble() ?? 0,
        fats: e['fat']?.toDouble() ?? 0,
        portion: e['unit'] ?? 'portion',
        referenceQuantity: e['quantity']?.toDouble(),
      )).toList();
      
      return Meal(
        id: entry.key,
        name: firstEntry['meal_name'] ?? 'Repas',
        time: DateTime.parse(firstEntry['created_at']).toString(),
        items: foods,
      );
    }).toList();
  }
  
  List<DailyGoal> _buildDailyGoals({
    required double totalCalories,
    required double targetCalories,
    required double currentWaterL,
    required double targetWaterL,
    required int mealsCount,
  }) {
    final locService = LocalizationService.instance;
    final languageCode = locService.currentLanguageCode;
    
    return [
      DailyGoal(
        id: 'calories',
        label: 'reach_calorie_goal'.tr(languageCode),
        progress: ((totalCalories / targetCalories) * 100).round().clamp(0, 100),
        xp: 25,
        completed: totalCalories >= targetCalories * 0.9,
        currentValue: totalCalories,
        targetValue: targetCalories,
        unit: 'kcal',
      ),
      DailyGoal(
        id: 'water',
        label: 'drink_water_goal'.tr(languageCode),
        progress: ((currentWaterL / targetWaterL) * 100).round().clamp(0, 100),
        xp: 25,
        completed: currentWaterL >= targetWaterL,
        currentValue: currentWaterL,
        targetValue: targetWaterL,
        unit: 'L',
      ),
      DailyGoal(
        id: 'meals',
        label: 'track_meals_today'.tr(languageCode),
        progress: ((mealsCount / 3) * 100).round().clamp(0, 100),
        xp: 25,
        completed: mealsCount >= 3,
        currentValue: mealsCount.toDouble(),
        targetValue: 3,
        unit: 'repas',
      ),
    ];
  }
}