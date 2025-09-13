import 'dart:async';
import '../components/ui/dashboard_models.dart';

/// Service de cache ultra-rapide en mémoire
/// Permet d'avoir des données toujours disponibles instantanément
class FastCacheService {
  static final FastCacheService _instance = FastCacheService._internal();
  factory FastCacheService() => _instance;
  FastCacheService._internal();

  // Cache en mémoire pour accès instantané
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Durées de cache par type de données
  static const Duration _shortCacheDuration = Duration(seconds: 30);
  static const Duration _mediumCacheDuration = Duration(minutes: 2);
  static const Duration _longCacheDuration = Duration(minutes: 10);
  
  /// Stocke une valeur dans le cache avec TTL
  static void set(String key, dynamic value, {Duration? ttl}) {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    
    // Auto-expiration du cache
    if (ttl != null) {
      Timer(ttl, () {
        if (_cacheTimestamps[key] != null) {
          final age = DateTime.now().difference(_cacheTimestamps[key]!);
          if (age >= ttl) {
            _memoryCache.remove(key);
            _cacheTimestamps.remove(key);
            print('🗑️ Cache expiré: $key');
          }
        }
      });
    }
  }
  
  /// Récupère une valeur du cache si elle est valide
  static T? get<T>(String key, {Duration? maxAge}) {
    if (!_memoryCache.containsKey(key)) {
      return null;
    }
    
    // Vérifier l'âge du cache si spécifié
    if (maxAge != null && _cacheTimestamps.containsKey(key)) {
      final age = DateTime.now().difference(_cacheTimestamps[key]!);
      if (age > maxAge) {
        // Cache trop vieux
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
        return null;
      }
    }
    
    return _memoryCache[key] as T?;
  }
  
  /// Cache les objectifs journaliers
  static void cacheGoals(List<DailyGoal> goals) {
    set('daily_goals', goals, ttl: _shortCacheDuration);
    print('📦 Goals mis en cache (30s)');
  }
  
  /// Récupère les objectifs depuis le cache
  static List<DailyGoal>? getCachedGoals() {
    return get<List<DailyGoal>>('daily_goals', maxAge: _shortCacheDuration);
  }
  
  /// Cache le profil utilisateur
  static void cacheUserProfile(UserProfile profile) {
    set('user_profile', profile, ttl: _mediumCacheDuration);
    print('📦 Profil mis en cache (2min)');
  }
  
  /// Récupère le profil depuis le cache
  static UserProfile? getCachedUserProfile() {
    return get<UserProfile>('user_profile', maxAge: _mediumCacheDuration);
  }
  
  /// Cache les modules de prévisualisation
  static void cacheModules(List<ModulePreview> modules) {
    set('module_previews', modules, ttl: _shortCacheDuration);
    print('📦 Modules mis en cache (30s)');
  }
  
  /// Récupère les modules depuis le cache
  static List<ModulePreview>? getCachedModules() {
    return get<List<ModulePreview>>('module_previews', maxAge: _shortCacheDuration);
  }
  
  /// Invalide une clé spécifique
  static void invalidate(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    print('🔄 Cache invalidé: $key');
  }
  
  /// Invalide tout le cache lié au dashboard
  static void invalidateDashboard() {
    invalidate('daily_goals');
    invalidate('user_profile');
    invalidate('module_previews');
    print('🔄 Cache dashboard complètement invalidé');
  }
  
  /// Nettoie les entrées expirées
  static void cleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _longCacheDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      print('🧹 Cache nettoyé: ${keysToRemove.length} entrées supprimées');
    }
  }
  
  /// Précharge les données importantes
  static Future<void> preloadDashboardData() async {
    try {
      // Cette méthode peut être appelée au démarrage pour précharger
      print('🚀 Préchargement du cache dashboard...');
      
      // Le DashboardService va automatiquement mettre en cache
      // lors du premier appel
    } catch (e) {
      print('⚠️ Erreur préchargement: $e');
    }
  }
}