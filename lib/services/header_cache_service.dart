import 'package:flutter/foundation.dart';
import '../components/ui/global_progress_models.dart';

/// Service de cache global pour le header
/// Évite les rechargements et scintillements entre les pages
/// OPTIMISATION: Cache infini - invalidation uniquement par événements
class HeaderCacheService {
  static HeaderStats? _cachedHeaderStats;
  static DateTime? _lastUpdate; // Pour logs uniquement

  /// Récupère les stats du header depuis le cache
  static HeaderStats? getCachedHeaderStats() {
    return _cachedHeaderStats;
  }

  /// Met à jour le cache avec de nouvelles stats
  static void updateCache(HeaderStats headerStats) {
    _cachedHeaderStats = headerStats;
    _lastUpdate = DateTime.now();
    final age = _lastUpdate != null ? DateTime.now().difference(_lastUpdate!).inSeconds : 0;
    debugPrint('💾 Header cache mis à jour: ${headerStats.dailyStreak} (age: ${age}s)');
  }

  /// Vérifie si le cache est encore valide
  /// OPTIMISATION: Toujours valide - invalidation par événements uniquement
  static bool _isCacheValid() {
    return _cachedHeaderStats != null;
  }
  
  /// Force l'invalidation du cache
  static void clearCache() {
    _cachedHeaderStats = null;
    _lastUpdate = null;
    debugPrint('🗑️ Header cache vidé');
  }
  
  /// Vérifie si on a des données en cache
  static bool hasValidCache() {
    return _cachedHeaderStats != null && _isCacheValid();
  }
}
