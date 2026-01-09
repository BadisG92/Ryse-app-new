import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../types/database_types.dart';

/// Service de cache persistant pour la base de données des aliments
/// Permet de réduire la consommation de données mobiles en cachant les aliments localement
class FoodCacheService {
  static const String _cacheKey = 'foods_cache_v2'; // v2: ajout support name_de
  static const String _cacheTimestampKey = 'foods_cache_timestamp_v2';
  static const Duration _cacheValidityDuration = Duration(days: 7); // Cache valide 7 jours

  /// Récupère les aliments depuis le cache local
  /// Retourne null si le cache n'existe pas ou est expiré
  static Future<List<Food>?> getCachedFoods() async {
    try {
      debugPrint('🔍 FoodCacheService: Vérification du cache local...');

      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) {
        debugPrint('⚠️ FoodCacheService: Aucun cache trouvé');
        return null;
      }

      // Vérifier l'âge du cache
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final cacheAgeDuration = Duration(milliseconds: cacheAge);

      if (cacheAge > _cacheValidityDuration.inMilliseconds) {
        debugPrint('⚠️ FoodCacheService: Cache expiré (âge: ${cacheAgeDuration.inDays} jours)');
        return null;
      }

      debugPrint('✅ FoodCacheService: Cache valide (âge: ${cacheAgeDuration.inHours}h)');

      // Récupérer les données du cache
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('⚠️ FoodCacheService: Cache vide');
        return null;
      }

      // Désérialiser les données
      final List<dynamic> jsonList = json.decode(jsonString);
      final foods = jsonList.map((json) => Food.fromJson(json)).toList();

      debugPrint('✅ FoodCacheService: ${foods.length} aliments chargés depuis le cache');
      return foods;

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors de la lecture du cache: $e');
      return null;
    }
  }

  /// Sauvegarde les aliments dans le cache local
  static Future<bool> cacheFoods(List<Food> foods) async {
    try {
      debugPrint('💾 FoodCacheService: Sauvegarde de ${foods.length} aliments dans le cache...');

      final prefs = await SharedPreferences.getInstance();

      // Sérialiser les données
      final jsonList = foods.map((food) => food.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Sauvegarder les données et le timestamp
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      // Calculer la taille approximative du cache (en KB)
      final cacheSizeKB = (jsonString.length / 1024).toStringAsFixed(2);
      debugPrint('✅ FoodCacheService: Cache sauvegardé avec succès (~$cacheSizeKB KB)');

      return true;

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors de la sauvegarde du cache: $e');
      return false;
    }
  }

  /// Vérifie si le cache est valide (existe et n'est pas expiré)
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheValidityDuration.inMilliseconds;

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors de la vérification du cache: $e');
      return false;
    }
  }

  /// Obtient l'âge du cache
  static Future<Duration?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return null;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return Duration(milliseconds: cacheAge);

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors du calcul de l\'âge du cache: $e');
      return null;
    }
  }

  /// Invalide le cache (force un nouveau téléchargement au prochain accès)
  static Future<void> invalidateCache() async {
    try {
      debugPrint('🗑️ FoodCacheService: Invalidation du cache...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);

      debugPrint('✅ FoodCacheService: Cache invalidé avec succès');

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors de l\'invalidation du cache: $e');
    }
  }

  /// Obtient la taille approximative du cache (en KB)
  static Future<double?> getCacheSizeKB() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString == null || jsonString.isEmpty) return null;

      return jsonString.length / 1024;

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors du calcul de la taille du cache: $e');
      return null;
    }
  }

  /// Obtient des informations sur le cache (pour debug/monitoring)
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final isValid = await isCacheValid();
      final age = await getCacheAge();
      final sizeKB = await getCacheSizeKB();
      final cachedFoods = await getCachedFoods();

      return {
        'isValid': isValid,
        'ageHours': age?.inHours,
        'ageDays': age?.inDays,
        'sizeKB': sizeKB?.toStringAsFixed(2),
        'foodsCount': cachedFoods?.length ?? 0,
        'expiresInDays': isValid && age != null
          ? (_cacheValidityDuration.inDays - age.inDays)
          : 0,
      };

    } catch (e) {
      debugPrint('❌ FoodCacheService: Erreur lors de la récupération des infos du cache: $e');
      return {};
    }
  }
}
