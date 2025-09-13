import 'dart:async';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/nutrition_remote_datasource.dart';
import '../../../../core/infrastructure/cache/unified_cache_manager.dart';
import '../../../../core/infrastructure/cache/cache_invalidation_strategy.dart';
import '../../../../core/infrastructure/offline/offline_queue.dart';
import '../../../../core/infrastructure/logging/app_logger.dart';
import '../../../../core/domain/repositories/base_repository.dart';
import '../../../../components/ui/dashboard_models.dart';
import '../../../../models/nutrition_models.dart';
import '../../../../services/optimistic_update_service.dart';
import '../../../../providers/goals_notifier.dart';

/// Implémentation concrète du repository nutrition
class NutritionRepositoryImpl implements NutritionRepository {
  final NutritionRemoteDataSource _remoteDataSource;
  final UnifiedCacheManager _cacheManager;
  final CacheInvalidationStrategy _cacheInvalidation;
  final OfflineQueue _offlineQueue;
  final AppLogger _logger;
  
  // Controllers pour les streams
  final _goalsStreamController = StreamController<List<DailyGoal>>.broadcast();
  final _mealsStreamController = StreamController<List<Meal>>.broadcast();
  
  NutritionRepositoryImpl({
    required NutritionRemoteDataSource remoteDataSource,
    UnifiedCacheManager? cacheManager,
    CacheInvalidationStrategy? cacheInvalidation,
    OfflineQueue? offlineQueue,
    AppLogger? logger,
  })  : _remoteDataSource = remoteDataSource,
        _cacheManager = cacheManager ?? UnifiedCacheManager.instance,
        _cacheInvalidation = cacheInvalidation ?? CacheInvalidationStrategy.instance,
        _offlineQueue = offlineQueue ?? OfflineQueue.instance,
        _logger = logger ?? AppLogger.instance;
  
  @override
  Future<RepositoryResult<NutritionDashboardData>> getDashboardData(DateTime date) async {
    final cacheKey = 'nutrition_dashboard_${date.toIso8601String().split('T')[0]}';
    
    try {
      // 1. Essayer le cache d'abord
      final cached = _cacheManager.get<NutritionDashboardData>(
        cacheKey,
        CacheType.nutritionData,
      );
      
      if (cached != null) {
        _logger.d('Dashboard nutrition from cache', tag: 'NUTRITION');
        // Lancer une mise à jour en arrière-plan
        _refreshInBackground(date);
        return RepositoryResult.success(cached, isFromCache: true);
      }
      
      // 2. Récupérer depuis la source remote
      final data = await _remoteDataSource.getDashboardData(date);
      
      // 3. Stocker dans le cache
      _cacheManager.set(cacheKey, data, CacheType.nutritionData);
      
      return RepositoryResult.success(data);
      
    } catch (e) {
      // En cas d'erreur, essayer de retourner le cache même expiré
      final staleCache = _cacheManager.get<NutritionDashboardData>(
        cacheKey,
        CacheType.longLived,
      );
      
      if (staleCache != null) {
        return RepositoryResult.success(staleCache, isFromCache: true);
      }
      
      return RepositoryResult.failure(e.toString());
    }
  }
  
  @override
  Future<RepositoryResult<List<DailyGoal>>> getDailyGoals(DateTime date) async {
    final cacheKey = 'daily_goals_${date.toIso8601String().split('T')[0]}';
    
    try {
      // Utiliser la méthode getOrCompute pour simplifier
      final goals = await _cacheManager.getOrCompute(
        cacheKey,
        CacheType.dashboard,
        () => _remoteDataSource.getDailyGoals(date),
      );
      
      // Notifier les observateurs
      _goalsStreamController.add(goals);
      GoalsNotifier.instance.update(goals);
      
      return RepositoryResult.success(goals);
      
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
  
  @override
  Future<RepositoryResult<bool>> addFoodEntry({
    required String userId,
    required String mealName,
    required FoodItem foodItem,
    required DateTime consumedAt,
    String? mealId,
  }) async {
    try {
      // 1. Mise à jour optimiste immédiate
      await OptimisticUpdateService.updateCaloriesOptimistic(foodItem.calories.toDouble());
      
      // 2. Invalider le cache intelligent
      _cacheInvalidation.onEvent('food_entry_added', metadata: {
        'date': consumedAt.toIso8601String().split('T')[0],
        'userId': userId,
      });
      
      // 3. Appel remote avec queue offline si nécessaire
      bool success;
      try {
        success = await _remoteDataSource.addFoodEntry(
          userId: userId,
          mealName: mealName,
          foodItem: foodItem,
          consumedAt: consumedAt,
          mealId: mealId,
        );
      } catch (e) {
        // Si offline, ajouter à la queue
        _logger.w('Failed to add food entry, queuing for later', error: e, tag: 'NUTRITION');
        await _offlineQueue.enqueue(QueuedOperation(
          type: OperationType.addFood,
          data: {
            'userId': userId,
            'mealName': mealName,
            'foodItem': foodItem.toJson(),
            'consumedAt': consumedAt.toIso8601String(),
            'mealId': mealId,
          },
        ));
        // Considérer comme succès pour l'UI (optimistic)
        success = true;
      }
      
      if (success) {
        // 4. Rafraîchir les données
        await getDailyGoals(consumedAt);
        await getMealsForDate(consumedAt);
      }
      
      return RepositoryResult.success(success);
      
    } catch (e) {
      // Rollback optimiste en cas d'erreur
      await OptimisticUpdateService.rollback();
      return RepositoryResult.failure(e.toString());
    }
  }
  
  @override
  Future<RepositoryResult<bool>> addWaterEntry({
    required int amount,
    String sourceType = 'manual',
    String? notes,
    DateTime? consumedAt,
  }) async {
    try {
      // 1. Mise à jour optimiste
      await OptimisticUpdateService.updateWaterOptimistic(amount);
      
      // 2. Invalider les caches
      final date = consumedAt ?? DateTime.now();
      final dateKey = date.toIso8601String().split('T')[0];
      _cacheManager.invalidatePattern('nutrition_dashboard_$dateKey');
      _cacheManager.invalidatePattern('daily_goals_$dateKey');
      
      // 3. Appel remote
      final success = await _remoteDataSource.addWaterEntry(
        amount: amount,
        sourceType: sourceType,
        notes: notes,
        consumedAt: consumedAt,
      );
      
      if (success) {
        // 4. Rafraîchir les objectifs
        await getDailyGoals(date);
      }
      
      return RepositoryResult.success(success);
      
    } catch (e) {
      await OptimisticUpdateService.rollback();
      return RepositoryResult.failure(e.toString());
    }
  }
  
  @override
  Future<RepositoryResult<List<Meal>>> getMealsForDate(DateTime date) async {
    final cacheKey = 'meals_${date.toIso8601String().split('T')[0]}';
    
    try {
      final meals = await _cacheManager.getOrCompute(
        cacheKey,
        CacheType.nutritionData,
        () => _remoteDataSource.getMealsForDate(date),
      );
      
      // Notifier les observateurs
      _mealsStreamController.add(meals);
      
      return RepositoryResult.success(meals);
      
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
  
  @override
  Stream<List<DailyGoal>> watchDailyGoals(DateTime date) {
    // Charger les données initiales
    getDailyGoals(date);
    
    // Retourner le stream
    return _goalsStreamController.stream;
  }
  
  @override
  Stream<List<Meal>> watchMeals(DateTime date) {
    // Charger les données initiales
    getMealsForDate(date);
    
    // Retourner le stream
    return _mealsStreamController.stream;
  }
  
  /// Rafraîchit les données en arrière-plan
  void _refreshInBackground(DateTime date) {
    Future.microtask(() async {
      try {
        final data = await _remoteDataSource.getDashboardData(date);
        final cacheKey = 'nutrition_dashboard_${date.toIso8601String().split('T')[0]}';
        _cacheManager.set(cacheKey, data, CacheType.nutritionData);
        _logger.d('Cache refreshed in background', tag: 'NUTRITION');
      } catch (e) {
        // Pas critique, on garde le cache existant
        _logger.w('Could not refresh cache', error: e, tag: 'NUTRITION');
      }
    });
  }
  
  /// Nettoie les ressources
  void dispose() {
    _goalsStreamController.close();
    _mealsStreamController.close();
  }
  
  /// Singleton pattern avec gestion du cycle de vie
  static NutritionRepositoryImpl? _instance;
  
  static NutritionRepositoryImpl get instance {
    _instance ??= NutritionRepositoryImpl(
      remoteDataSource: NutritionRemoteDataSource(),
    );
    return _instance!;
  }
  
  static void cleanup() {
    _instance?.dispose();
    _instance = null;
  }
}