import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'dashboard_service.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('fr');
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isFrench => _currentLocale.languageCode == 'fr';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
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
      final systemLanguage = systemLocales.isNotEmpty ? systemLocales.first.languageCode : 'en';
      
      // Si le système est en français, utiliser français, sinon anglais par défaut
      savedLanguage = systemLanguage == 'fr' ? 'fr' : 'en';
      
      // Sauvegarder ce choix
      await prefs.setString(_languageKey, savedLanguage);
      
      print('🌍 Langue système détectée: $systemLanguage -> Application configurée en: $savedLanguage');
    }
    
    _currentLocale = Locale(savedLanguage);
    notifyListeners();
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      // Vider le cache des objectifs pour forcer le rechargement avec la nouvelle langue
      DashboardService.clearGoalsCache();
      notifyListeners();
    }
  }
  
  String getColumnSuffix() {
    return isFrench ? '_fr' : '_en';
  }
  
  String getTextFromColumns(String? frenchText, String? englishText) {
    if (isFrench) {
      return frenchText ?? englishText ?? '';
    } else {
      return englishText ?? frenchText ?? '';
    }
  }
}