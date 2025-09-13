import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Type de cache avec leurs politiques de durée
enum CacheType {
  dashboard(Duration(minutes: 5)),
  userProfile(Duration(hours: 1)),
  nutritionData(Duration(minutes: 10)),
  workoutData(Duration(minutes: 15)),
  recipeData(Duration(hours: 24)),
  shortLived(Duration(seconds: 30)),
  mediumLived(Duration(minutes: 5)),
  longLived(Duration(hours: 1));

  final Duration ttl;
  const CacheType(this.ttl);
}

/// Gestionnaire de cache unifié pour toute l'application
class UnifiedCacheManager {
  static final UnifiedCacheManager _instance = UnifiedCacheManager._internal();
  static UnifiedCacheManager get instance => _instance;
  UnifiedCacheManager._internal();
  
  // Cache en mémoire pour accès ultra-rapide
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // Préférences partagées pour persistance
  SharedPreferences? _prefs;
  
  /// Initialise le cache (à appeler au démarrage de l'app)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromDisk();
    print('🎯 UnifiedCacheManager initialisé');
  }
  
  /// Récupère une donnée du cache
  T? get<T>(String key, CacheType type) {
    final entry = _memoryCache[key];
    
    if (entry == null) {
      return null;
    }
    
    // Vérifier l'expiration
    if (entry.isExpired) {
      _memoryCache.remove(key);
      _removeFromDisk(key);
      return null;
    }
    
    try {
      return entry.data as T;
    } catch (e) {
      print('⚠️ Erreur de cast dans le cache pour $key: $e');
      return null;
    }
  }
  
  /// Stocke une donnée dans le cache
  void set<T>(String key, T data, CacheType type, {Duration? customTTL}) {
    final ttl = customTTL ?? type.ttl;
    final expiry = DateTime.now().add(ttl);
    
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiry: expiry,
      type: type,
    );
    
    // Persister sur disque pour les caches de longue durée
    if (ttl.inMinutes > 5) {
      _saveToDisk(key, data, expiry);
    }
  }
  
  /// Invalide un cache spécifique
  void invalidate(String key) {
    _memoryCache.remove(key);
    _removeFromDisk(key);
  }
  
  /// Invalide tous les caches d'un type donné
  void invalidateType(CacheType type) {
    _memoryCache.removeWhere((key, entry) => entry.type == type);
    // Note: Pour la persistance disque, on devrait stocker le type aussi
  }
  
  /// Invalide les caches correspondant à un pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    _memoryCache.removeWhere((key, entry) => regex.hasMatch(key));
  }
  
  /// Nettoie tous les caches
  void clearAll() {
    _memoryCache.clear();
    _prefs?.clear();
    print('🧹 Tous les caches vidés');
  }
  
  /// Nettoie les entrées expirées
  void cleanExpired() {
    _memoryCache.removeWhere((key, entry) => entry.isExpired);
  }
  
  /// Précharge des données dans le cache
  void preload<T>(String key, T data, CacheType type) {
    set(key, data, type);
    print('📦 Données préchargées dans le cache: $key');
  }
  
  /// Récupère ou calcule une valeur (cache-aside pattern)
  Future<T> getOrCompute<T>(
    String key,
    CacheType type,
    Future<T> Function() compute,
  ) async {
    // Vérifier le cache d'abord
    final cached = get<T>(key, type);
    if (cached != null) {
      print('⚡ Cache hit pour: $key');
      return cached;
    }
    
    // Calculer la valeur
    print('🔄 Cache miss pour: $key - calcul en cours...');
    final value = await compute();
    
    // Stocker dans le cache
    set(key, value, type);
    
    return value;
  }
  
  // === Méthodes privées pour la persistance disque ===
  
  void _saveToDisk<T>(String key, T data, DateTime expiry) {
    if (_prefs == null) return;
    
    try {
      final entry = {
        'data': jsonEncode(data),
        'expiry': expiry.toIso8601String(),
      };
      _prefs!.setString('cache_$key', jsonEncode(entry));
    } catch (e) {
      // Pas critique si la persistance échoue
      print('⚠️ Impossible de persister le cache: $e');
    }
  }
  
  void _removeFromDisk(String key) {
    _prefs?.remove('cache_$key');
  }
  
  void _loadFromDisk() {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      try {
        final json = _prefs!.getString(key);
        if (json != null) {
          final entry = jsonDecode(json);
          final expiry = DateTime.parse(entry['expiry']);
          
          if (expiry.isAfter(DateTime.now())) {
            final actualKey = key.replaceFirst('cache_', '');
            _memoryCache[actualKey] = _CacheEntry(
              data: jsonDecode(entry['data']),
              expiry: expiry,
              type: CacheType.longLived, // Par défaut
            );
          }
        }
      } catch (e) {
        // Ignorer les entrées corrompues
      }
    }
  }
}

/// Entrée de cache interne
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  final CacheType type;
  
  const _CacheEntry({
    required this.data,
    required this.expiry,
    required this.type,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Extension pour faciliter l'utilisation
extension CacheExtensions on UnifiedCacheManager {
  /// Récupère un objet JSON du cache
  Map<String, dynamic>? getJson(String key, CacheType type) {
    return get<Map<String, dynamic>>(key, type);
  }
  
  /// Récupère une liste du cache
  List<T>? getList<T>(String key, CacheType type) {
    final data = get<List>(key, type);
    return data?.cast<T>();
  }
}