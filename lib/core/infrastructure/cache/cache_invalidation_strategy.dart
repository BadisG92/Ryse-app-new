import 'dart:async';
import '../logging/app_logger.dart';
import 'unified_cache_manager.dart';

/// Stratégie d'invalidation intelligente du cache
/// Invalide automatiquement les données liées après une mutation
class CacheInvalidationStrategy {
  static final CacheInvalidationStrategy _instance = CacheInvalidationStrategy._internal();
  static CacheInvalidationStrategy get instance => _instance;
  
  CacheInvalidationStrategy._internal();
  
  final AppLogger _logger = AppLogger.instance;
  final UnifiedCacheManager _cache = UnifiedCacheManager.instance;
  
  // Règles d'invalidation : quand X change, invalider Y
  final Map<String, List<String>> _invalidationRules = {
    // Nutrition
    'food_entry_added': [
      'nutrition_dashboard_*',
      'daily_goals_*',
      'meals_*',
      'calories_summary_*',
    ],
    'water_entry_added': [
      'nutrition_dashboard_*',
      'daily_goals_*',
      'water_summary_*',
    ],
    'meal_deleted': [
      'nutrition_dashboard_*',
      'daily_goals_*',
      'meals_*',
    ],
    
    // Sport
    'workout_completed': [
      'sport_dashboard_*',
      'daily_goals_*',
      'workout_stats_*',
      'calories_burned_*',
    ],
    'cardio_session_added': [
      'sport_dashboard_*',
      'daily_goals_*',
      'cardio_stats_*',
    ],
    
    // Profile
    'profile_updated': [
      'user_profile_*',
      'daily_goals_*', // Les objectifs dépendent du profil
      'nutrition_dashboard_*',
    ],
    'goals_updated': [
      'daily_goals_*',
      'nutrition_dashboard_*',
      'user_profile_*',
    ],
    
    // Global
    'language_changed': [
      '*', // Tout invalider lors d'un changement de langue
    ],
  };
  
  // Dépendances entre caches (graphe de dépendances)
  final Map<String, Set<String>> _dependencies = {
    'daily_goals': {'nutrition_dashboard', 'sport_dashboard', 'user_profile'},
    'nutrition_dashboard': {'food_entries', 'water_entries', 'user_profile'},
    'sport_dashboard': {'workout_sessions', 'cardio_sessions', 'user_profile'},
  };
  
  // Timers pour l'invalidation différée
  final Map<String, Timer> _deferredInvalidations = {};
  
  /// Déclenche l'invalidation après un événement
  void onEvent(String eventType, {Map<String, dynamic>? metadata}) {
    _logger.d('Cache invalidation event: $eventType', tag: 'CACHE');
    
    final patterns = _invalidationRules[eventType];
    if (patterns == null) {
      _logger.w('No invalidation rules for event: $eventType', tag: 'CACHE');
      return;
    }
    
    for (final pattern in patterns) {
      if (pattern == '*') {
        // Invalider tout le cache
        _invalidateAll();
      } else {
        // Invalider selon le pattern
        _invalidatePattern(pattern, metadata: metadata);
      }
    }
    
    // Déclencher les invalidations en cascade
    _cascadeInvalidation(eventType);
  }
  
  /// Invalide un pattern spécifique
  void _invalidatePattern(String pattern, {Map<String, dynamic>? metadata}) {
    // Remplacer les wildcards avec les métadonnées si disponibles
    var finalPattern = pattern;
    
    if (metadata != null) {
      // Ex: 'daily_goals_*' avec metadata['date'] = '2024-01-15'
      // devient 'daily_goals_2024-01-15'
      if (metadata.containsKey('date')) {
        finalPattern = pattern.replaceAll('*', metadata['date']);
      } else if (metadata.containsKey('userId')) {
        finalPattern = pattern.replaceAll('*', metadata['userId']);
      }
    }
    
    _logger.v('Invalidating cache pattern: $finalPattern', tag: 'CACHE');
    _cache.invalidatePattern(finalPattern);
  }
  
  /// Invalide tout le cache
  void _invalidateAll() {
    _logger.i('Invalidating entire cache', tag: 'CACHE');
    _cache.clearAll();
  }
  
  /// Gère l'invalidation en cascade
  void _cascadeInvalidation(String source) {
    final affected = <String>{};
    final toProcess = <String>[source];
    
    while (toProcess.isNotEmpty) {
      final current = toProcess.removeLast();
      if (affected.contains(current)) continue;
      
      affected.add(current);
      
      // Trouver les dépendances
      _dependencies.forEach((key, deps) {
        if (deps.contains(current) && !affected.contains(key)) {
          toProcess.add(key);
          _logger.v('Cascade invalidation: $current -> $key', tag: 'CACHE');
        }
      });
    }
    
    // Invalider toutes les clés affectées
    for (final key in affected) {
      _cache.invalidatePattern('${key}_*');
    }
  }
  
  /// Planifie une invalidation différée
  void scheduleInvalidation(String pattern, Duration delay) {
    _logger.d('Scheduling invalidation for $pattern in ${delay.inSeconds}s', tag: 'CACHE');
    
    // Annuler l'invalidation précédente si elle existe
    _deferredInvalidations[pattern]?.cancel();
    
    _deferredInvalidations[pattern] = Timer(delay, () {
      _invalidatePattern(pattern);
      _deferredInvalidations.remove(pattern);
    });
  }
  
  /// Invalide intelligemment selon l'âge des données
  void invalidateStale({Duration maxAge = const Duration(hours: 24)}) {
    _logger.i('Invalidating stale cache entries older than ${maxAge.inHours}h', tag: 'CACHE');
    
    // Le UnifiedCacheManager gère déjà l'expiration via TTL
    // Cette méthode peut être utilisée pour forcer une vérification
    _cache.cleanExpired();
  }
  
  /// Précharge les données critiques
  Future<void> preloadCriticalData() async {
    _logger.i('Preloading critical data', tag: 'CACHE');
    
    try {
      // Les données critiques à précharger
      final criticalKeys = [
        'user_profile',
        'daily_goals_${_getTodayKey()}',
        'nutrition_dashboard_${_getTodayKey()}',
      ];
      
      for (final key in criticalKeys) {
        // Vérifier si déjà en cache
        if (_cache.get(key, CacheType.mediumLived) == null) {
          // Déclencher le chargement (sera fait par les repositories)
          _logger.v('Preloading: $key', tag: 'CACHE');
        }
      }
    } catch (e) {
      _logger.e('Failed to preload critical data', error: e, tag: 'CACHE');
    }
  }
  
  /// Optimise le cache en supprimant les données non utilisées
  void optimizeCache() {
    _logger.i('Optimizing cache', tag: 'CACHE');
    
    // Nettoyer les entrées expirées
    _cache.cleanExpired();
    
    // TODO: Implémenter LRU (Least Recently Used) pour limiter la taille
  }
  
  String _getTodayKey() {
    return DateTime.now().toIso8601String().split('T')[0];
  }
  
  /// Nettoie les ressources
  void dispose() {
    for (final timer in _deferredInvalidations.values) {
      timer.cancel();
    }
    _deferredInvalidations.clear();
  }
}

/// Extension pour faciliter l'usage
extension CacheInvalidationX on Object {
  void invalidateCache(String eventType, {Map<String, dynamic>? metadata}) {
    CacheInvalidationStrategy.instance.onEvent(eventType, metadata: metadata);
  }
}