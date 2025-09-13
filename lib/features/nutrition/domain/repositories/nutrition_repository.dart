import '../../../../core/domain/repositories/base_repository.dart';
import '../../../../components/ui/dashboard_models.dart';
import '../../../../models/nutrition_models.dart';

/// Interface du repository nutrition
abstract class NutritionRepository {
  /// Récupère les données du dashboard nutrition pour une date
  Future<RepositoryResult<NutritionDashboardData>> getDashboardData(DateTime date);
  
  /// Récupère les objectifs nutritionnels quotidiens
  Future<RepositoryResult<List<DailyGoal>>> getDailyGoals(DateTime date);
  
  /// Ajoute une entrée de nourriture
  Future<RepositoryResult<bool>> addFoodEntry({
    required String userId,
    required String mealName,
    required FoodItem foodItem,
    required DateTime consumedAt,
    String? mealId,
  });
  
  /// Ajoute une entrée d'eau
  Future<RepositoryResult<bool>> addWaterEntry({
    required int amount,
    String sourceType,
    String? notes,
    DateTime? consumedAt,
  });
  
  /// Récupère les repas pour une date
  Future<RepositoryResult<List<Meal>>> getMealsForDate(DateTime date);
  
  /// Observe les changements des objectifs
  Stream<List<DailyGoal>> watchDailyGoals(DateTime date);
  
  /// Observe les changements des repas
  Stream<List<Meal>> watchMeals(DateTime date);
}

/// Données du dashboard nutrition
class NutritionDashboardData {
  final double currentCalories;
  final double targetCalories;
  final double currentWaterL;
  final double targetWaterL;
  final int mealsCount;
  final List<DailyGoal> goals;
  final List<Meal> todayMeals;
  
  const NutritionDashboardData({
    required this.currentCalories,
    required this.targetCalories,
    required this.currentWaterL,
    required this.targetWaterL,
    required this.mealsCount,
    required this.goals,
    required this.todayMeals,
  });
  
  /// Crée une copie avec modifications
  NutritionDashboardData copyWith({
    double? currentCalories,
    double? targetCalories,
    double? currentWaterL,
    double? targetWaterL,
    int? mealsCount,
    List<DailyGoal>? goals,
    List<Meal>? todayMeals,
  }) {
    return NutritionDashboardData(
      currentCalories: currentCalories ?? this.currentCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      currentWaterL: currentWaterL ?? this.currentWaterL,
      targetWaterL: targetWaterL ?? this.targetWaterL,
      mealsCount: mealsCount ?? this.mealsCount,
      goals: goals ?? this.goals,
      todayMeals: todayMeals ?? this.todayMeals,
    );
  }
}