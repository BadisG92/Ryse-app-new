import '../components/ui/global_progress_models.dart';

/// Service de cache global pour le header
/// Évite les rechargements et scintillements entre les pages
class HeaderCacheService {
  static HeaderStats? _cachedHeaderStats;
  static DateTime? _lastUpdate;
  
  /// Durée de validité du cache en minutes
  static const int _cacheDurationMinutes = 5;
  
  /// Récupère les stats du header depuis le cache ou les charge
  static HeaderStats? getCachedHeaderStats() {
    if (_cachedHeaderStats != null && _isCacheValid()) {
      return _cachedHeaderStats;
    }
    return null;
  }
  
  /// Met à jour le cache avec de nouvelles stats
  static void updateCache(HeaderStats headerStats) {
    _cachedHeaderStats = headerStats;
    _lastUpdate = DateTime.now();
    print('💾 Header cache mis à jour: ${headerStats.dailyStreak}');
  }
  
  /// Vérifie si le cache est encore valide
  static bool _isCacheValid() {
    if (_lastUpdate == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);
    return difference.inMinutes < _cacheDurationMinutes;
  }
  
  /// Force l'invalidation du cache
  static void clearCache() {
    _cachedHeaderStats = null;
    _lastUpdate = null;
    print('🗑️ Header cache vidé');
  }
  
  /// Vérifie si on a des données en cache
  static bool hasValidCache() {
    return _cachedHeaderStats != null && _isCacheValid();
  }
}
