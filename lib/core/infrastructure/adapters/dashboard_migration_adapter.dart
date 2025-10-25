import 'package:flutter/foundation.dart';
import '../../../features/nutrition/domain/repositories/nutrition_repository.dart';
import '../../../features/nutrition/data/repositories/nutrition_repository_impl.dart';
import '../../../features/nutrition/data/datasources/nutrition_remote_datasource.dart';
import '../../../components/ui/dashboard_models.dart';
import '../../../services/dashboard_service.dart';
import '../cache/unified_cache_manager.dart';

/// Adaptateur pour migrer progressivement du DashboardService vers le Repository Pattern
/// Sans casser l'existant, permet une transition en douceur
class DashboardMigrationAdapter {
  static DashboardMigrationAdapter? _instance;
  
  late final NutritionRepository _nutritionRepository;
  bool _isInitialized = false;
  
  // Mode de migration : permet de basculer progressivement
  static bool useNewArchitecture = false;
  
  DashboardMigrationAdapter._() {
    _initialize();
  }
  
  static DashboardMigrationAdapter get instance {
    _instance ??= DashboardMigrationAdapter._();
    return _instance!;
  }
  
  void _initialize() {
    if (_isInitialized) return;
    
    // Initialiser le nouveau système en parallèle de l'ancien
    final remoteDataSource = NutritionRemoteDataSource();
    _nutritionRepository = NutritionRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    
    _isInitialized = true;
    debugPrint('🔄 DashboardMigrationAdapter initialisé');
  }
  
  /// Récupère les objectifs journaliers
  /// Utilise le nouveau système si activé, sinon l'ancien
  Future<List<DailyGoal>> getDailyGoals() async {
    if (!useNewArchitecture) {
      // Utiliser l'ancien système
      return DashboardService.getDailyGoals();
    }
    
    try {
      // Utiliser le nouveau système
      debugPrint('🆕 Utilisation du nouveau système Repository');
      final result = await _nutritionRepository.getDailyGoals(DateTime.now());
      
      if (result.isSuccess) {
        return result.data ?? [];
      } else {
        // Fallback sur l'ancien système en cas d'erreur
        debugPrint('⚠️ Erreur nouveau système, fallback sur ancien: ${result.error}');
        return DashboardService.getDailyGoals();
      }
    } catch (e) {
      debugPrint('❌ Exception dans nouveau système: $e');
      // Fallback sur l'ancien système
      return DashboardService.getDailyGoals();
    }
  }
  
  /// Ajoute une entrée d'eau avec le nouveau système
  Future<bool> addWaterEntry({
    required int amount,
    String sourceType = 'manual',
    String? notes,
    DateTime? consumedAt,
  }) async {
    if (!useNewArchitecture) {
      // Utiliser l'ancien système (appel direct Supabase dans le service)
      // Pour l'instant, on retourne true car l'ancien système n'a pas cette méthode
      return true;
    }
    
    try {
      final result = await _nutritionRepository.addWaterEntry(
        amount: amount,
        sourceType: sourceType,
        notes: notes,
        consumedAt: consumedAt,
      );
      
      return result.isSuccess && (result.data ?? false);
    } catch (e) {
      debugPrint('❌ Erreur ajout eau: $e');
      return false;
    }
  }
  
  /// Invalide et rafraîchit les objectifs
  Future<void> invalidateAndRefreshGoals() async {
    if (!useNewArchitecture) {
      // Utiliser l'ancien système
      await DashboardService.invalidateAndRefreshGoals();
      return;
    }
    
    try {
      // Avec le nouveau système, invalider le cache unifié
      UnifiedCacheManager.instance.invalidatePattern('daily_goals');
      UnifiedCacheManager.instance.invalidatePattern('nutrition_dashboard');
      
      // Recharger les objectifs
      await getDailyGoals();
    } catch (e) {
      debugPrint('❌ Erreur invalidation: $e');
      // Fallback sur l'ancien système
      await DashboardService.invalidateAndRefreshGoals();
    }
  }
  
  /// Active progressivement le nouveau système
  static void enableNewArchitecture() {
    useNewArchitecture = true;
    debugPrint('✅ Nouvelle architecture activée');
  }
  
  /// Désactive le nouveau système (pour rollback si nécessaire)
  static void disableNewArchitecture() {
    useNewArchitecture = false;
    debugPrint('🔙 Retour à l\'ancienne architecture');
  }
  
  /// Test pour vérifier que le nouveau système fonctionne
  Future<bool> testNewArchitecture() async {
    try {
      debugPrint('🧪 Test du nouveau système...');
      
      // Tester la récupération des objectifs
      final result = await _nutritionRepository.getDailyGoals(DateTime.now());
      if (!result.isSuccess) {
        debugPrint('❌ Test échoué: ${result.error}');
        return false;
      }
      
      debugPrint('✅ Test réussi: ${result.data?.length} objectifs récupérés');
      return true;
    } catch (e) {
      debugPrint('❌ Test échoué avec exception: $e');
      return false;
    }
  }
  
  /// Compare les résultats entre ancien et nouveau système
  Future<void> compareSystemsOutput() async {
    try {
      debugPrint('📊 Comparaison ancien vs nouveau système...');
      
      // Récupérer avec l'ancien système
      final oldGoals = await DashboardService.getDailyGoals();
      
      // Récupérer avec le nouveau système
      final newResult = await _nutritionRepository.getDailyGoals(DateTime.now());
      final newGoals = newResult.data ?? [];
      
      debugPrint('📊 Résultats:');
      debugPrint('   Ancien système: ${oldGoals.length} objectifs');
      debugPrint('   Nouveau système: ${newGoals.length} objectifs');
      
      // Comparer chaque objectif
      for (int i = 0; i < oldGoals.length && i < newGoals.length; i++) {
        final old = oldGoals[i];
        final new_ = newGoals[i];
        
        if (old.id == new_.id) {
          final match = old.currentValue == new_.currentValue &&
                       old.targetValue == new_.targetValue;
          debugPrint('   ${old.id}: ${match ? "✅ MATCH" : "❌ DIFF"}');
          if (!match) {
            debugPrint('      Ancien: ${old.currentValue}/${old.targetValue}');
            debugPrint('      Nouveau: ${new_.currentValue}/${new_.targetValue}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur comparaison: $e');
    }
  }
}

/// Extension pour faciliter l'utilisation dans les widgets existants
extension DashboardServiceMigration on DashboardService {
  /// Wrapper pour utiliser progressivement le nouveau système
  static Future<List<DailyGoal>> getDailyGoalsWithMigration() async {
    return DashboardMigrationAdapter.instance.getDailyGoals();
  }
  
  /// Wrapper pour invalider avec le nouveau système si activé
  static Future<void> invalidateWithMigration() async {
    await DashboardMigrationAdapter.instance.invalidateAndRefreshGoals();
  }
}