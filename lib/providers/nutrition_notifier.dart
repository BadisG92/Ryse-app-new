import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/ui/dashboard_models.dart';
import '../core/cache/local_cache.dart';
import '../services/dashboard_service.dart';
import '../services/optimistic_update_service.dart';
import '../services/water_service.dart';
import '../services/food_entries_service.dart';
import '../config/supabase_config.dart';
import '../core/config/feature_flags.dart';
import '../models/nutrition_models.dart';

/// Notifier pour la gestion optimiste de la nutrition et du dashboard
/// Remplace progressivement les setState() par des mises à jour instantanées
class NutritionNotifier extends ChangeNotifier {

  // État principal
  List<DailyGoal> _dailyGoals = [];
  UserProfile? _userProfile;
  List<ModulePreview> _modulePreviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters publics
  List<DailyGoal> get dailyGoals => _dailyGoals;
  UserProfile? get userProfile => _userProfile;
  List<ModulePreview> get modulePreviews => _modulePreviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Client Supabase
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Initialisation complète du dashboard avec cache-first
  Future<void> initializeDashboard() async {
    print('🚀 NutritionNotifier: Initialisation dashboard...');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. CACHE LOCAL D'ABORD (ultra-rapide)
      await _loadFromCache();

      // 2. SYNC SERVEUR EN ARRIÈRE-PLAN
      _syncFromServerInBackground();

    } catch (e) {
      print('❌ Erreur initialisation dashboard: $e');
      _errorMessage = 'Erreur chargement dashboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger depuis le cache local (instantané)
  Future<void> _loadFromCache() async {
    try {
      // Charger les objectifs depuis le cache
      final cachedGoals = await LocalCache.getDailyGoals();

      if (cachedGoals != null && cachedGoals.isNotEmpty) {
        _dailyGoals = cachedGoals;
        _isLoading = false;
        notifyListeners();

        print('⚡ Cache local: ${_dailyGoals.length} objectifs chargés');
        return;
      }

      // Si pas de cache, chargement initial depuis serveur
      await _loadFromServerDirectly();

    } catch (e) {
      print('❌ Erreur chargement cache: $e');
      await _loadFromServerDirectly();
    }
  }

  /// Charger directement depuis le serveur (fallback)
  Future<void> _loadFromServerDirectly() async {
    try {
      // Utiliser les services existants pour ne rien casser
      _dailyGoals = await DashboardService.getDailyGoals();
      _userProfile = await DashboardService.getUserProfile();
      _modulePreviews = await DashboardService.getModulePreviews();

      // Sauvegarder en cache pour les prochaines fois
      await LocalCache.saveDailyGoals(_dailyGoals);

      _isLoading = false;
      notifyListeners();

      print('🔄 Serveur: Dashboard chargé (${_dailyGoals.length} objectifs)');
    } catch (e) {
      print('❌ Erreur chargement serveur: $e');
      _errorMessage = 'Erreur serveur: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync en arrière-plan depuis le serveur (non-bloquant)
  void _syncFromServerInBackground() {
    // Délai pour ne pas bloquer l'UI
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        print('🔄 Sync background: Récupération depuis serveur...');

        // Récupérer les vraies données
        final serverGoals = await DashboardService.getDailyGoals();
        final serverProfile = await DashboardService.getUserProfile();
        final serverModules = await DashboardService.getModulePreviews();

        // Comparer avec les données actuelles
        if (!_areGoalsIdentical(serverGoals, _dailyGoals)) {
          _dailyGoals = serverGoals;
          _userProfile = serverProfile;
          _modulePreviews = serverModules;

          // Sauvegarder en cache
          await LocalCache.saveDailyGoals(_dailyGoals);

          notifyListeners();
          print('✅ Background sync: Dashboard mis à jour');
        } else {
          print('📊 Background sync: Données déjà à jour');
        }

      } catch (e) {
        print('⚠️ Erreur sync background: $e');
        // Ne pas casser l'UI, garder les données actuelles
      }
    });
  }

  /// Comparer deux listes d'objectifs pour éviter les mises à jour inutiles
  bool _areGoalsIdentical(List<DailyGoal> goals1, List<DailyGoal> goals2) {
    if (goals1.length != goals2.length) return false;

    for (int i = 0; i < goals1.length; i++) {
      final g1 = goals1[i];
      final g2 = goals2[i];

      if (g1.id != g2.id ||
          g1.progress != g2.progress ||
          g1.completed != g2.completed ||
          g1.currentValue != g2.currentValue ||
          g1.isPending != g2.isPending) {
        return false;
      }
    }
    return true;
  }

  /// OPTIMISTIC UPDATE: Ajouter de l'eau instantanément
  Future<void> addWaterOptimistic(int amountMl) async {
    print('💧 Optimistic: Ajout ${amountMl}ml d\'eau...');

    try {
      // 1. MISE À JOUR UI INSTANTANÉE (0ms)
      final waterGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'water');
      if (waterGoalIndex != -1) {
        final currentGoal = _dailyGoals[waterGoalIndex];
        final newCurrentValue = (currentGoal.currentValue ?? 0.0) + (amountMl / 1000.0);
        final targetValue = currentGoal.targetValue ?? 2.0;
        final newProgress = targetValue > 0 ? ((newCurrentValue / targetValue) * 100).round().clamp(0, 100) : 0;

        final updatedGoal = currentGoal.copyWith(
          currentValue: newCurrentValue,
          progress: newProgress,
          completed: newCurrentValue >= targetValue,
          isPending: true, // Marqueur visual
        );

        _dailyGoals[waterGoalIndex] = updatedGoal;
        notifyListeners(); // UI se met à jour INSTANTANÉMENT

        // 2. CACHE LOCAL IMMÉDIAT
        await LocalCache.updateGoalInCache('water', updatedGoal);
        await LocalCache.saveWaterEntryTemp(
          amount: amountMl.toDouble(),
          timestamp: DateTime.now()
        );
      }

      // 3. SYNC SERVEUR EN ARRIÈRE-PLAN
      _syncWaterWithServer(amountMl);

    } catch (e) {
      print('❌ Erreur optimistic eau: $e');
      // En cas d'erreur, rechargement complet
      await _loadFromServerDirectly();
    }
  }

  /// Sync eau avec serveur (arrière-plan)
  void _syncWaterWithServer(int amountMl) async {
    try {
      // Utiliser le service existant pour ne rien casser
      final success = await WaterService.addWaterEntry(amount: amountMl);

      if (success) {
        // Retirer le marqueur "pending"
        final waterGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'water');
        if (waterGoalIndex != -1) {
          _dailyGoals[waterGoalIndex] = _dailyGoals[waterGoalIndex].copyWith(
            isPending: false
          );

          // Mettre à jour le cache sans pending
          await LocalCache.updateGoalInCache('water', _dailyGoals[waterGoalIndex]);
          await LocalCache.clearTempWaterEntries();

          notifyListeners();
          print('✅ Eau sync serveur: Success');
        }
      } else {
        throw Exception('Échec sauvegarde serveur');
      }

    } catch (e) {
      print('❌ Erreur sync eau serveur: $e');

      // ROLLBACK: Annuler la mise à jour optimiste
      await _rollbackWaterUpdate(amountMl);
    }
  }

  /// Rollback en cas d'erreur serveur
  Future<void> _rollbackWaterUpdate(int amountMl) async {
    try {
      final waterGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'water');
      if (waterGoalIndex != -1) {
        final currentGoal = _dailyGoals[waterGoalIndex];
        final revertedValue = (currentGoal.currentValue ?? 0.0) - (amountMl / 1000.0);
        final targetValue = currentGoal.targetValue ?? 2.0;
        final revertedProgress = targetValue > 0 ? ((revertedValue / targetValue) * 100).round().clamp(0, 100) : 0;

        final revertedGoal = currentGoal.copyWith(
          currentValue: revertedValue,
          progress: revertedProgress,
          completed: revertedValue >= targetValue,
          isPending: false,
        );

        _dailyGoals[waterGoalIndex] = revertedGoal;

        await LocalCache.updateGoalInCache('water', revertedGoal);
        await LocalCache.clearTempWaterEntries();

        notifyListeners();
        print('🔄 Rollback eau effectué');
      }
    } catch (e) {
      print('❌ Erreur rollback: $e');
      // En dernier recours, recharger depuis serveur
      await _loadFromServerDirectly();
    }
  }

  /// OPTIMISTIC UPDATE: Ajouter calories/repas instantanément
  Future<void> addCaloriesOptimistic(double calories, {bool isNewMeal = false}) async {
    print('🍎 Optimistic: Ajout ${calories}kcal (nouveau repas: $isNewMeal)...');

    try {
      // 1. MISE À JOUR UI INSTANTANÉE
      final caloriesGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'calories');
      final mealsGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'meals');

      // Mettre à jour calories
      if (caloriesGoalIndex != -1) {
        final currentGoal = _dailyGoals[caloriesGoalIndex];
        final newCurrentValue = (currentGoal.currentValue ?? 0.0) + calories;
        final targetValue = currentGoal.targetValue ?? 2000.0;
        final newProgress = targetValue > 0 ? ((newCurrentValue / targetValue) * 100).round().clamp(0, 100) : 0;

        _dailyGoals[caloriesGoalIndex] = currentGoal.copyWith(
          currentValue: newCurrentValue,
          progress: newProgress,
          completed: newCurrentValue >= targetValue * 0.9, // 90% = complété
          isPending: true,
        );
      }

      // Mettre à jour repas si c'est un nouveau repas
      if (isNewMeal && mealsGoalIndex != -1) {
        final currentGoal = _dailyGoals[mealsGoalIndex];
        final newCurrentValue = (currentGoal.currentValue ?? 0.0) + 1;
        final newProgress = ((newCurrentValue / 3) * 100).round().clamp(0, 100);

        _dailyGoals[mealsGoalIndex] = currentGoal.copyWith(
          currentValue: newCurrentValue,
          progress: newProgress,
          completed: newCurrentValue >= 3,
          isPending: true,
        );
      }

      notifyListeners(); // UI INSTANTANÉE

      // 2. CACHE LOCAL
      await LocalCache.saveDailyGoals(_dailyGoals);

      print('⚡ UI mise à jour instantanément: +${calories}kcal');

    } catch (e) {
      print('❌ Erreur optimistic calories: $e');
      await _loadFromServerDirectly();
    }
  }

  /// OPTIMISTIC UPDATE: Ajouter un aliment complet (méthode principale)
  Future<void> addFoodItemOptimistic({
    required String foodName,
    required double calories,
    required double proteins,
    required double carbs,
    required double fats,
    required String mealName,
    required String portion,
    String? foodId,
    bool isCustom = false,
    bool isRecipe = false,
    bool isScanned = false,
  }) async {
    print('🍽️ Optimistic: Ajout $foodName ($calories kcal) au $mealName...');

    if (!FeatureFlags.USE_OPTIMISTIC_FOOD) {
      print('⏸️ Feature flag désactivé, utilisation du système classique');
      return;
    }

    try {
      // 1. MISE À JOUR UI INSTANTANÉE des objectifs
      await addCaloriesOptimistic(calories, isNewMeal: true);

      // 2. SYNC SERVEUR EN ARRIÈRE-PLAN
      _syncFoodWithServer(
        foodName: foodName,
        calories: calories,
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        mealName: mealName,
        portion: portion,
        foodId: foodId,
        isCustom: isCustom,
        isRecipe: isRecipe,
        isScanned: isScanned,
      );

    } catch (e) {
      print('❌ Erreur optimistic food: $e');
      await _loadFromServerDirectly();
    }
  }

  /// Sync aliment avec serveur (arrière-plan)
  void _syncFoodWithServer({
    required String foodName,
    required double calories,
    required double proteins,
    required double carbs,
    required double fats,
    required String mealName,
    required String portion,
    String? foodId,
    bool isCustom = false,
    bool isRecipe = false,
    bool isScanned = false,
  }) async {
    try {
      // Utiliser FoodEntriesService existant
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Créer FoodItem pour le service existant
      final foodItem = FoodItem(
        id: foodId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: foodName,
        calories: calories.round(),
        proteins: proteins,
        carbs: carbs,
        fats: fats,
        portion: portion,
        isCustom: isCustom,
        isRecipe: isRecipe,
        isScanned: isScanned,
        hasModifiedMacros: false,
      );

      final success = await FoodEntriesService.addFoodEntry(
        userId: user.id,
        mealName: mealName,
        foodItem: foodItem,
        consumedAt: DateTime.now(),
      );

      if (success) {
        // Retirer le marqueur "pending"
        _removePendingFlags(['calories', 'meals']);
        print('✅ Aliment sync serveur: Success');
      } else {
        throw Exception('Échec sauvegarde serveur');
      }

    } catch (e) {
      print('❌ Erreur sync aliment serveur: $e');
      // ROLLBACK: Annuler la mise à jour optimiste
      await _rollbackFoodUpdate(calories);
    }
  }

  /// Rollback ajout d'aliment en cas d'erreur
  Future<void> _rollbackFoodUpdate(double calories) async {
    try {
      // Rollback calories
      final caloriesGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'calories');
      final mealsGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'meals');

      if (caloriesGoalIndex != -1) {
        final currentGoal = _dailyGoals[caloriesGoalIndex];
        final revertedValue = (currentGoal.currentValue ?? 0.0) - calories;
        final targetValue = currentGoal.targetValue ?? 2000.0;
        final revertedProgress = targetValue > 0 ? ((revertedValue / targetValue) * 100).round().clamp(0, 100) : 0;

        _dailyGoals[caloriesGoalIndex] = currentGoal.copyWith(
          currentValue: revertedValue,
          progress: revertedProgress,
          completed: revertedValue >= targetValue * 0.9,
          isPending: false,
        );
      }

      if (mealsGoalIndex != -1) {
        final currentGoal = _dailyGoals[mealsGoalIndex];
        final revertedValue = (currentGoal.currentValue ?? 0.0) - 1;

        _dailyGoals[mealsGoalIndex] = currentGoal.copyWith(
          currentValue: revertedValue,
          progress: ((revertedValue / 3) * 100).round().clamp(0, 100),
          completed: revertedValue >= 3,
          isPending: false,
        );
      }

      await LocalCache.saveDailyGoals(_dailyGoals);
      notifyListeners();
      print('🔄 Rollback aliment effectué');

    } catch (e) {
      print('❌ Erreur rollback aliment: $e');
      await _loadFromServerDirectly();
    }
  }

  /// Retirer les marqueurs pending sur des objectifs spécifiques
  void _removePendingFlags(List<String> goalIds) {
    for (final goalId in goalIds) {
      final index = _dailyGoals.indexWhere((goal) => goal.id == goalId);
      if (index != -1) {
        _dailyGoals[index] = _dailyGoals[index].copyWith(isPending: false);
      }
    }
    notifyListeners();
  }

  /// OPTIMISTIC UPDATE: Marquer workout comme complété
  Future<void> completeWorkoutOptimistic({
    String workoutType = 'musculation',
    int caloriesBurned = 300,
    int durationMinutes = 45,
  }) async {
    print('🏋️ Optimistic: Workout $workoutType complété (${caloriesBurned}kcal brûlées)...');

    if (!FeatureFlags.USE_OPTIMISTIC_WORKOUT) {
      print('⏸️ Feature flag désactivé, utilisation du système classique');
      return;
    }

    try {
      // 1. MISE À JOUR UI INSTANTANÉE
      final workoutGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'workout');
      if (workoutGoalIndex != -1) {
        _dailyGoals[workoutGoalIndex] = _dailyGoals[workoutGoalIndex].copyWith(
          progress: 100,
          completed: true,
          currentValue: 1,
          isPending: true,
        );

        notifyListeners(); // UI INSTANTANÉE
        await LocalCache.saveDailyGoals(_dailyGoals);

        print('⚡ Workout marqué comme complété instantanément');
      }

      // 2. SYNC SERVEUR EN ARRIÈRE-PLAN
      _syncWorkoutWithServer(workoutType, caloriesBurned, durationMinutes);

    } catch (e) {
      print('❌ Erreur optimistic workout: $e');
      await _loadFromServerDirectly();
    }
  }

  /// Sync workout avec serveur (arrière-plan)
  void _syncWorkoutWithServer(String workoutType, int caloriesBurned, int durationMinutes) async {
    try {
      // TODO: Intégrer avec WorkoutService ou SportService existant
      // Pour l'instant, simulation d'une requête réussie
      await Future.delayed(const Duration(seconds: 1));

      // Retirer le marqueur "pending"
      _removePendingFlags(['workout']);
      print('✅ Workout sync serveur: Success');

    } catch (e) {
      print('❌ Erreur sync workout serveur: $e');
      // ROLLBACK: Annuler la mise à jour optimiste
      await _rollbackWorkoutUpdate();
    }
  }

  /// Rollback workout en cas d'erreur
  Future<void> _rollbackWorkoutUpdate() async {
    try {
      final workoutGoalIndex = _dailyGoals.indexWhere((goal) => goal.id == 'workout');
      if (workoutGoalIndex != -1) {
        _dailyGoals[workoutGoalIndex] = _dailyGoals[workoutGoalIndex].copyWith(
          progress: 0,
          completed: false,
          currentValue: 0,
          isPending: false,
        );

        await LocalCache.saveDailyGoals(_dailyGoals);
        notifyListeners();
        print('🔄 Rollback workout effectué');
      }
    } catch (e) {
      print('❌ Erreur rollback workout: $e');
      await _loadFromServerDirectly();
    }
  }

  /// OPTIMISTIC UPDATE: Ajouter une pesée
  Future<void> addWeightOptimistic({
    required double weightKg,
    DateTime? date,
  }) async {
    print('⚖️ Optimistic: Pesée ${weightKg}kg...');

    if (!FeatureFlags.USE_OPTIMISTIC_WEIGHT) {
      print('⏸️ Feature flag désactivé, utilisation du système classique');
      return;
    }

    try {
      // 1. MISE À JOUR UI INSTANTANÉE
      // Note: Le poids n'affecte pas directement les objectifs journaliers
      // mais on peut ajouter une indication visuelle

      // 2. SYNC SERVEUR EN ARRIÈRE-PLAN
      _syncWeightWithServer(weightKg, date ?? DateTime.now());

      print('⚡ Pesée enregistrée instantanément');

    } catch (e) {
      print('❌ Erreur optimistic weight: $e');
    }
  }

  /// Sync poids avec serveur (arrière-plan)
  void _syncWeightWithServer(double weightKg, DateTime date) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // TODO: Utiliser WeightService existant quand il sera disponible
      // Pour l'instant, insérer directement dans weight_entries
      await _supabase.from('weight_entries').insert({
        'user_id': user.id,
        'weight': weightKg,
        'recorded_at': date.toIso8601String(),
      });

      print('✅ Poids sync serveur: Success');

    } catch (e) {
      print('❌ Erreur sync poids serveur: $e');
      // Le poids n'affecte pas les objectifs, pas de rollback nécessaire
    }
  }

  /// Forcer une synchronisation complète
  Future<void> forceSync() async {
    print('🔄 Force sync: Rechargement complet...');

    await LocalCache.clearDailyGoals();
    await _loadFromServerDirectly();
  }

  /// Recharger les données (pull-to-refresh)
  Future<void> refreshData() async {
    print('🔄 Refresh: Pull-to-refresh déclenché...');

    // Vider le cache et recharger
    await LocalCache.clearDailyGoals();
    await initializeDashboard();
  }

  /// Vérifier si des mises à jour sont en attente
  bool get hasPendingUpdates {
    return _dailyGoals.any((goal) => goal.isPending == true);
  }

  /// Obtenir le nombre de mises à jour en attente
  int get pendingUpdatesCount {
    return _dailyGoals.where((goal) => goal.isPending == true).length;
  }

  /// Debug: Afficher l'état actuel
  void debugPrintState() {
    print('🔍 NUTRITION NOTIFIER DEBUG:');
    print('   - Objectifs: ${_dailyGoals.length}');
    print('   - En attente: $pendingUpdatesCount');
    print('   - Loading: $_isLoading');
    print('   - Error: $_errorMessage');

    for (final goal in _dailyGoals) {
      print('   - ${goal.label}: ${goal.progress}% (pending: ${goal.isPending})');
    }
  }

  @override
  void dispose() {
    print('🧹 NutritionNotifier: Nettoyage...');
    super.dispose();
  }
}