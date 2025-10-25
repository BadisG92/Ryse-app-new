import 'package:flutter/foundation.dart';
/// Configuration des feature flags pour migration progressive
/// Permet d'activer/désactiver les nouvelles fonctionnalités en toute sécurité
class FeatureFlags {

  // ✅ DASHBOARD OPTIMISTIC UPDATES
  // Mise à jour instantanée des objectifs journaliers
  static const bool USE_OPTIMISTIC_DASHBOARD = true; // 🚀 ACTIVÉ pour UI instantanée

  // ✅ WATER OPTIMISTIC UPDATES
  // Ajout d'eau avec mise à jour instantanée
  static const bool USE_OPTIMISTIC_WATER = true; // 🚀 ACTIVÉ pour UI instantanée

  // ✅ FOOD OPTIMISTIC UPDATES
  // Ajout d'aliments avec mise à jour instantanée
  static const bool USE_OPTIMISTIC_FOOD = true; // 🚀 ACTIVÉ pour UI instantanée

  // ✅ WORKOUT OPTIMISTIC UPDATES
  // Séances sport avec mise à jour instantanée
  static const bool USE_OPTIMISTIC_WORKOUT = true; // 🚀 ACTIVÉ pour UI instantanée
  static const bool USE_OPTIMISTIC_SPORT = USE_OPTIMISTIC_WORKOUT; // Alias pour cohérence

  // ✅ WEIGHT OPTIMISTIC UPDATES
  // Pesées avec mise à jour instantanée
  static const bool USE_OPTIMISTIC_WEIGHT = true; // 🚀 ACTIVÉ pour UI instantanée

  // 🔧 DEBUG FLAGS
  // Activer les logs détaillés
  static const bool ENABLE_DEBUG_LOGS = true;

  // Vider le cache au démarrage (utile pour développement)
  static const bool CLEAR_CACHE_ON_START = false;

  // Simuler des délais réseau (pour tester les optimistic updates)
  static const bool SIMULATE_NETWORK_DELAY = false;
  static const int NETWORK_DELAY_MS = 2000;

  // 📊 MIGRATION FLAGS
  // Utiliser les anciens services en fallback si les nouveaux échouent
  static const bool USE_LEGACY_FALLBACK = true;

  // Afficher les indicateurs visuels pour les mises à jour en cours
  static const bool SHOW_PENDING_INDICATORS = true;

  /// Vérifier si une fonctionnalité est activée
  static bool isEnabled(String feature) {
    switch (feature) {
      case 'optimistic_dashboard':
        return USE_OPTIMISTIC_DASHBOARD;
      case 'optimistic_water':
        return USE_OPTIMISTIC_WATER;
      case 'optimistic_food':
        return USE_OPTIMISTIC_FOOD;
      case 'optimistic_workout':
        return USE_OPTIMISTIC_WORKOUT;
      case 'optimistic_weight':
        return USE_OPTIMISTIC_WEIGHT;
      case 'debug_logs':
        return ENABLE_DEBUG_LOGS;
      case 'clear_cache_start':
        return CLEAR_CACHE_ON_START;
      case 'simulate_delay':
        return SIMULATE_NETWORK_DELAY;
      case 'legacy_fallback':
        return USE_LEGACY_FALLBACK;
      case 'pending_indicators':
        return SHOW_PENDING_INDICATORS;
      default:
        return false;
    }
  }

  /// Log conditionnel basé sur les feature flags
  static void debugLog(String message) {
    if (ENABLE_DEBUG_LOGS) {
      debugPrint('🔧 [FEATURE] $message');
    }
  }

  /// Simuler un délai réseau si activé
  static Future<void> simulateNetworkDelay() async {
    if (SIMULATE_NETWORK_DELAY) {
      debugLog('Simulation délai réseau: ${NETWORK_DELAY_MS}ms');
      await Future.delayed(Duration(milliseconds: NETWORK_DELAY_MS));
    }
  }

  /// Affichage debug de tous les flags
  static void printAllFlags() {
    if (!ENABLE_DEBUG_LOGS) return;

    debugPrint('🚩 FEATURE FLAGS ACTUELS:');
    debugPrint('   📊 Dashboard optimistic: $USE_OPTIMISTIC_DASHBOARD');
    debugPrint('   💧 Water optimistic: $USE_OPTIMISTIC_WATER');
    debugPrint('   🍎 Food optimistic: $USE_OPTIMISTIC_FOOD');
    debugPrint('   🏋️ Workout optimistic: $USE_OPTIMISTIC_WORKOUT');
    debugPrint('   ⚖️ Weight optimistic: $USE_OPTIMISTIC_WEIGHT');
    debugPrint('   🔧 Debug logs: $ENABLE_DEBUG_LOGS');
    debugPrint('   🧹 Clear cache: $CLEAR_CACHE_ON_START');
    debugPrint('   ⏱️ Network delay: $SIMULATE_NETWORK_DELAY (${NETWORK_DELAY_MS}ms)');
    debugPrint('   🔄 Legacy fallback: $USE_LEGACY_FALLBACK');
    debugPrint('   ⏳ Pending indicators: $SHOW_PENDING_INDICATORS');
  }
}