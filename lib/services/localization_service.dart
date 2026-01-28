import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'ai_workout_generation_service.dart';
import 'dashboard_service.dart';
import 'global_state_manager.dart';
import 'header_cache_service.dart';
import 'offline_workout_service.dart';
import 'progress_service_v2.dart';
import 'recipe_service.dart';
import 'sport_dashboard_service.dart';
import 'widget_sync_service.dart';
import 'workout_cache_service.dart';
import 'ai_notification_service.dart';
import 'notification_service.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('fr');
  bool _isInitialized = false;
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isFrench => _currentLocale.languageCode == 'fr';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isGerman => _currentLocale.languageCode == 'de';
  bool get isInitialized => _isInitialized;
  
  static LocalizationService? _instance;
  static LocalizationService get instance {
    _instance ??= LocalizationService._();
    return _instance!;
  }
  
  LocalizationService._();
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Si l'utilisateur a déjà fait un choix de langue, l'utiliser
    String? savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage == null) {
      // Première fois : détecter la langue du système
      final systemLocales = ui.PlatformDispatcher.instance.locales;
      debugPrint('🌍 Locales système disponibles: $systemLocales');
      final systemLanguage = systemLocales.isNotEmpty ? systemLocales.first.languageCode : 'en';
      debugPrint('🌍 Langue système première: $systemLanguage');

      // Détecter français, allemand, sinon anglais par défaut
      savedLanguage = systemLanguage == 'fr' ? 'fr'
                    : systemLanguage == 'de' ? 'de'
                    : 'en';

      // Sauvegarder ce choix
      await prefs.setString(_languageKey, savedLanguage);

      debugPrint('🌍 Langue système détectée: $systemLanguage -> Application configurée en: $savedLanguage');
    } else {
      debugPrint('🌍 Langue déjà sauvegardée dans SharedPreferences: $savedLanguage');
    }
    
    _currentLocale = Locale(savedLanguage);
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Sauvegarder dans Supabase pour les notifications IA
      await _saveLanguageToSupabase(languageCode);

      // TRIGGER: Vider les caches pour forcer le rechargement avec la nouvelle langue
      DashboardService.clearGoalsCache();
      WorkoutCacheService.clearCache();
      SportDashboardService.invalidateCache();
      HeaderCacheService.clearCache();
      AIWorkoutGenerationService.invalidateCache();
      ProgressServiceV2.forceRefresh();
      GlobalStateManager.instance.invalidateWeeklyData();
      await OfflineWorkoutService().clearAllCache();
      await RecipeService.invalidateCache();

      // Vider les notifications IA (elles seront régénérées dans la bonne langue)
      await AiNotificationService.instance.clearUnusedMessages();

      // Replanifier toutes les notifications avec la nouvelle langue
      await NotificationService().scheduleAllNotifications(force: true);

      notifyListeners();

      // Mettre à jour le widget repas pour refléter la nouvelle langue
      await WidgetSyncService.refreshMealWidget(force: true);
    }
  }

  /// Sauvegarder la langue dans Supabase (pour les notifications IA)
  Future<void> _saveLanguageToSupabase(String languageCode) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ Language save failed: No user logged in');
        return;
      }

      debugPrint('🔄 Saving language to Supabase: $languageCode for user ${user.id}');

      final response = await Supabase.instance.client
          .from('users')
          .update({'language': languageCode})
          .eq('id', user.id)
          .select();

      debugPrint('✅ Language saved to Supabase: $languageCode, response: $response');
    } catch (e) {
      debugPrint('❌ Error saving language to Supabase: $e');
    }
  }

  /// Synchroniser la langue locale avec Supabase (appelé après login)
  Future<void> syncLanguageToSupabase() async {
    debugPrint('🌍 syncLanguageToSupabase: currentLocale = ${_currentLocale.languageCode}');
    await _saveLanguageToSupabase(_currentLocale.languageCode);
  }
  
  String getColumnSuffix() {
    return isFrench ? '_fr' : isGerman ? '_de' : '_en';
  }

  String getTextFromColumns(String? frenchText, String? englishText, [String? germanText]) {
    if (isFrench) {
      return frenchText ?? englishText ?? germanText ?? '';
    } else if (isGerman) {
      return germanText ?? englishText ?? frenchText ?? '';
    } else {
      return englishText ?? frenchText ?? germanText ?? '';
    }
  }
}
