import '../cache/unified_cache_manager.dart';
import '../adapters/dashboard_migration_adapter.dart';

/// Contrôleur central pour gérer la migration progressive
/// Permet d'activer/désactiver les nouvelles fonctionnalités sans risque
class MigrationController {
  static final MigrationController _instance = MigrationController._internal();
  static MigrationController get instance => _instance;
  
  MigrationController._internal();
  
  // Flags de feature pour activation progressive
  bool _useUnifiedCache = false;
  bool _useRepositoryPattern = false;
  bool _useOptimisticUpdates = true; // Déjà en place
  
  /// Initialise le système de migration
  Future<void> initialize() async {
    print('🚀 Initialisation du système de migration...');
    
    // Toujours initialiser le cache unifié (en parallèle de l'ancien)
    await UnifiedCacheManager.instance.initialize();
    
    // Initialiser l'adaptateur de migration
    DashboardMigrationAdapter.instance;
    
    print('✅ Système de migration prêt');
  }
  
  /// Active le cache unifié progressivement
  void enableUnifiedCache() {
    _useUnifiedCache = true;
    print('✅ Cache unifié activé');
  }
  
  /// Active le Repository Pattern progressivement
  void enableRepositoryPattern() {
    _useRepositoryPattern = true;
    DashboardMigrationAdapter.enableNewArchitecture();
    print('✅ Repository Pattern activé');
  }
  
  /// Test complet du nouveau système
  Future<bool> testNewArchitecture() async {
    print('🧪 Test complet du nouveau système...');
    
    try {
      // 1. Test du cache unifié
      print('📦 Test du cache unifié...');
      UnifiedCacheManager.instance.set('test_key', 'test_value', CacheType.shortLived);
      final cached = UnifiedCacheManager.instance.get<String>('test_key', CacheType.shortLived);
      if (cached != 'test_value') {
        print('❌ Échec test cache');
        return false;
      }
      print('✅ Cache unifié OK');
      
      // 2. Test du Repository Pattern
      print('🏗️ Test du Repository Pattern...');
      final adapterTest = await DashboardMigrationAdapter.instance.testNewArchitecture();
      if (!adapterTest) {
        print('❌ Échec test Repository');
        return false;
      }
      print('✅ Repository Pattern OK');
      
      // 3. Comparaison des résultats
      print('📊 Comparaison ancien vs nouveau...');
      await DashboardMigrationAdapter.instance.compareSystemsOutput();
      
      print('✅ Tous les tests passent!');
      return true;
      
    } catch (e) {
      print('❌ Erreur pendant les tests: $e');
      return false;
    }
  }
  
  /// Active tout le nouveau système (après tests réussis)
  void enableAllNewFeatures() {
    enableUnifiedCache();
    enableRepositoryPattern();
    print('🎉 Toutes les nouvelles fonctionnalités activées!');
  }
  
  /// Rollback complet en cas de problème
  void rollbackToOldSystem() {
    _useUnifiedCache = false;
    _useRepositoryPattern = false;
    DashboardMigrationAdapter.disableNewArchitecture();
    print('🔙 Retour au système ancien');
  }
  
  /// Status actuel de la migration
  Map<String, bool> get status => {
    'unified_cache': _useUnifiedCache,
    'repository_pattern': _useRepositoryPattern,
    'optimistic_updates': _useOptimisticUpdates,
  };
  
  /// Vérifie si une feature est activée
  bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'unified_cache':
        return _useUnifiedCache;
      case 'repository_pattern':
        return _useRepositoryPattern;
      case 'optimistic_updates':
        return _useOptimisticUpdates;
      default:
        return false;
    }
  }
}