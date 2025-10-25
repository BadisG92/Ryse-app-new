import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dashboard_service.dart';
import 'recipe_service.dart';
import 'sport_dashboard_service.dart';
import 'fast_cache_service.dart';

/// Service de préchargement intelligent
/// Précharge les données en avance pour avoir zéro latence
class PreloadService {
  static Timer? _preloadTimer;
  static bool _isPreloading = false;
  
  /// Initialise le préchargement au démarrage de l'app
  static void initialize() {
    debugPrint('🚀 PreloadService: Initialisation du préchargement');
    
    // Précharger immédiatement les données essentielles
    _preloadEssentialData();
    
    // Planifier un préchargement périodique
    _schedulePeriodicPreload();
  }
  
  /// Précharge les données essentielles au démarrage
  static Future<void> _preloadEssentialData() async {
    if (_isPreloading) return;
    _isPreloading = true;
    
    try {
      debugPrint('📦 Préchargement des données essentielles...');
      
      // Lancer tous les préchargements en parallèle
      await Future.wait([
        // Dashboard et objectifs
        DashboardService.getDailyGoals().catchError((e) {
          debugPrint('⚠️ Erreur préchargement goals: $e');
        }),
        
        // Profil utilisateur
        DashboardService.getUserProfile().catchError((e) {
          debugPrint('⚠️ Erreur préchargement profil: $e');
        }),
        
        // Modules dashboard
        DashboardService.getModulePreviews().catchError((e) {
          debugPrint('⚠️ Erreur préchargement modules: $e');
        }),
        
        // Données sport (si l'utilisateur utilise cette fonctionnalité)
        SportDashboardService.getDashboardData().catchError((e) {
          debugPrint('⚠️ Erreur préchargement sport: $e');
        }),
      ]);
      
      debugPrint('✅ Préchargement initial terminé');
      
    } catch (e) {
      debugPrint('❌ Erreur préchargement global: $e');
    } finally {
      _isPreloading = false;
    }
  }
  
  /// Planifie un préchargement périodique des données
  static void _schedulePeriodicPreload() {
    // Annuler le timer existant s'il y en a un
    _preloadTimer?.cancel();
    
    // Précharger toutes les 30 secondes
    _preloadTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isPreloading) {
        debugPrint('🔄 Préchargement périodique...');
        _preloadLightData();
      }
    });
  }
  
  /// Précharge les données légères (juste les objectifs)
  static Future<void> _preloadLightData() async {
    try {
      // Juste rafraîchir les goals en arrière-plan
      await DashboardService.getDailyGoals();
    } catch (e) {
      debugPrint('⚠️ Erreur préchargement léger: $e');
    }
  }
  
  /// Précharge les données d'une page spécifique avant navigation
  static Future<void> preloadPageData(String pageName) async {
    debugPrint('📦 Préchargement pour page: $pageName');
    
    try {
      switch (pageName) {
        case 'dashboard':
          await Future.wait([
            DashboardService.getDailyGoals(),
            DashboardService.getUserProfile(),
            DashboardService.getModulePreviews(),
          ]);
          break;
          
        case 'recipes':
          // Les recettes sont déjà en cache statique
          RecipeService.getAllRecipes();
          break;
          
        case 'sport':
          await SportDashboardService.getDashboardData();
          break;
          
        case 'nutrition':
          // Précharger les entrées du jour
          await DashboardService.getDailyGoals();
          break;
          
        default:
          debugPrint('⚠️ Page non reconnue pour préchargement: $pageName');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur préchargement page $pageName: $e');
    }
  }
  
  /// Précharge avant une action prédictible
  static void predictivePreload(String actionType) {
    // Par exemple, si on sait que l'utilisateur va probablement
    // revenir au dashboard après avoir ajouté de l'eau
    if (actionType == 'water_add') {
      Future.delayed(const Duration(milliseconds: 500), () {
        DashboardService.getDailyGoals();
      });
    }
  }
  
  /// Nettoie les ressources
  static void dispose() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
  }
}