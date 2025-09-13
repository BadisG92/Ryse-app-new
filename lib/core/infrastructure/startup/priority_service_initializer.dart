import 'dart:async';
import '../logging/app_logger.dart';
import '../../../config/supabase_config.dart';
import '../../../services/localization_service.dart';
import '../migration/migration_controller.dart';

/// Service d'initialisation par priorités pour optimiser le démarrage
/// Applique la stratégie "Critical Path First" pour la performance
class PriorityServiceInitializer {
  static final PriorityServiceInitializer _instance = PriorityServiceInitializer._internal();
  static PriorityServiceInitializer get instance => _instance;
  
  PriorityServiceInitializer._internal();
  
  final AppLogger _logger = AppLogger.instance;
  bool _isInitialized = false;
  
  /// Phase 1: Services critiques (bloquants pour l'UI)
  /// Durée max: 2 secondes
  Future<void> initializeCriticalServices() async {
    if (_isInitialized) return;
    
    final stopwatch = Stopwatch()..start();
    _logger.i('🚀 Phase 1: Services critiques', tag: 'STARTUP');
    
    try {
      await Future.wait([
        _initializeLocalization(),
        _initializeBasicAuth(),
      ]).timeout(const Duration(seconds: 2));
      
      _logger.performance('critical_services_init', stopwatch.elapsed);
      _logger.i('✅ Services critiques initialisés en ${stopwatch.elapsedMilliseconds}ms', tag: 'STARTUP');
      
    } catch (e) {
      _logger.e('❌ Échec services critiques (app continue)', error: e, tag: 'STARTUP');
      // L'app continue même en cas d'échec
    }
  }
  
  /// Phase 2: Services importants (non-bloquants)
  /// Durée max: 5 secondes, en arrière-plan
  Future<void> initializeImportantServices() async {
    final stopwatch = Stopwatch()..start();
    _logger.i('🔄 Phase 2: Services importants (background)', tag: 'STARTUP');
    
    // Exécuter en arrière-plan sans bloquer l'UI
    unawaited(_runImportantServicesInBackground(stopwatch));
  }
  
  /// Phase 3: Services optionnels (complètement asynchrones)
  /// Aucune limite de temps, chargement à la demande
  Future<void> initializeOptionalServices() async {
    _logger.i('⚡ Phase 3: Services optionnels (lazy loading)', tag: 'STARTUP');
    
    // Exécuter complètement en arrière-plan
    unawaited(_runOptionalServicesInBackground());
  }
  
  /// Initialise TOUS les services avec la stratégie de priorité
  Future<void> initializeAll() async {
    final globalStopwatch = Stopwatch()..start();
    _logger.i('🎯 Démarrage optimisé avec priorités', tag: 'STARTUP');
    
    // Phase 1: Critiques (bloquant)
    await initializeCriticalServices();
    
    // Phase 2 & 3: Asynchrones (non-bloquant)
    unawaited(initializeImportantServices());
    unawaited(initializeOptionalServices());
    
    _isInitialized = true;
    _logger.performance('total_startup_time', globalStopwatch.elapsed);
    _logger.i('🎉 Initialisation terminée en ${globalStopwatch.elapsedMilliseconds}ms', tag: 'STARTUP');
  }
  
  // === SERVICES CRITIQUES (Phase 1) ===
  
  Future<void> _initializeLocalization() async {
    try {
      await LocalizationService.instance.initialize()
          .timeout(const Duration(seconds: 1));
      _logger.i('✅ Localisation OK', tag: 'STARTUP');
    } catch (e) {
      _logger.w('⚠️ Localisation échoué (valeurs par défaut utilisées)', error: e, tag: 'STARTUP');
    }
  }
  
  Future<void> _initializeBasicAuth() async {
    try {
      // Juste vérifier que Supabase est accessible
      // L'auth complète se fera plus tard
      await SupabaseConfig.initialize()
          .timeout(const Duration(seconds: 1));
      _logger.i('✅ Connexion Supabase OK', tag: 'STARTUP');
    } catch (e) {
      _logger.w('⚠️ Supabase non accessible (mode offline)', error: e, tag: 'STARTUP');
    }
  }
  
  // === SERVICES IMPORTANTS (Phase 2) ===
  
  Future<void> _runImportantServicesInBackground(Stopwatch stopwatch) async {
    try {
      await Future.wait([
        _initializeArchitecture(),
        _preloadEssentialData(),
      ]).timeout(const Duration(seconds: 5));
      
      _logger.performance('important_services_init', stopwatch.elapsed);
      _logger.i('✅ Services importants initialisés en ${stopwatch.elapsedMilliseconds}ms', tag: 'STARTUP');
      
    } catch (e) {
      _logger.w('⚠️ Certains services importants ont échoué', error: e, tag: 'STARTUP');
    }
  }
  
  Future<void> _initializeArchitecture() async {
    try {
      await MigrationController.instance.initialize()
          .timeout(const Duration(seconds: 3));
      _logger.i('✅ Architecture avancée OK', tag: 'STARTUP');
    } catch (e) {
      _logger.w('⚠️ Architecture avancée échouée', error: e, tag: 'STARTUP');
    }
  }
  
  Future<void> _preloadEssentialData() async {
    try {
      // Précharger les données essentielles pour l'UX
      // (ex: paramètres utilisateur, cache critique)
      await Future.delayed(const Duration(milliseconds: 100)); // Simulation
      _logger.i('✅ Données essentielles préchargées', tag: 'STARTUP');
    } catch (e) {
      _logger.w('⚠️ Préchargement échoué', error: e, tag: 'STARTUP');
    }
  }
  
  // === SERVICES OPTIONNELS (Phase 3) ===
  
  Future<void> _runOptionalServicesInBackground() async {
    // Délai pour ne pas interférer avec l'UI
    await Future.delayed(const Duration(seconds: 2));
    
    _logger.i('🔧 Chargement services optionnels...', tag: 'STARTUP');
    
    // Services non critiques qui peuvent prendre du temps
    unawaited(_initializeAnalytics());
    unawaited(_initializeAdvancedFeatures());
    unawaited(_warmupCaches());
  }
  
  Future<void> _initializeAnalytics() async {
    try {
      // Analytics, crash reporting, etc.
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      _logger.i('📊 Analytics initialisées', tag: 'STARTUP');
    } catch (e) {
      _logger.w('📊 Analytics échouées', error: e, tag: 'STARTUP');
    }
  }
  
  Future<void> _initializeAdvancedFeatures() async {
    try {
      // Features avancées, IA, synchronisation complète, etc.
      await Future.delayed(const Duration(seconds: 3)); // Simulation
      _logger.i('🎯 Features avancées initialisées', tag: 'STARTUP');
    } catch (e) {
      _logger.w('🎯 Features avancées échouées', error: e, tag: 'STARTUP');
    }
  }
  
  Future<void> _warmupCaches() async {
    try {
      // Réchauffement des caches pour la performance
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      _logger.i('🔥 Caches réchauffés', tag: 'STARTUP');
    } catch (e) {
      _logger.w('🔥 Réchauffement échoué', error: e, tag: 'STARTUP');
    }
  }
  
  /// Vérifie l'état d'initialisation
  bool get isInitialized => _isInitialized;
  
  /// Diagnostic complet du système
  Future<Map<String, dynamic>> getDiagnostics() async {
    return {
      'initialized': _isInitialized,
      'supabase_available': SupabaseConfig.isAvailable,
      'localization_ready': LocalizationService.instance.isInitialized,
      'architecture_status': MigrationController.instance.status,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension pour faciliter l'usage
extension StartupHelpers on PriorityServiceInitializer {
  /// Initialisation express pour les tests
  Future<void> initializeForTesting() async {
    await initializeCriticalServices();
    // Skip les autres phases pour les tests
  }
  
  /// Initialisation complète avec monitoring
  Future<void> initializeWithMonitoring() async {
    final diagnostics = await getDiagnostics();
    AppLogger.instance.i('📋 État avant init: $diagnostics', tag: 'STARTUP');
    
    await initializeAll();
    
    final finalDiagnostics = await getDiagnostics();
    AppLogger.instance.i('📋 État après init: $finalDiagnostics', tag: 'STARTUP');
  }
}