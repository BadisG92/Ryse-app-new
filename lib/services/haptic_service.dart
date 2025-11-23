import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé pour gérer les retours haptiques
/// Vérifie les préférences utilisateur avant de déclencher les vibrations
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  static HapticService get instance => _instance;

  bool _isEnabled = true;
  bool _isInitialized = false;

  /// Initialiser le service (charger les préférences)
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('haptic_feedback') ?? true;
    _isInitialized = true;
  }

  /// Activer/désactiver les retours haptiques
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', enabled);
  }

  /// Vérifier si les retours haptiques sont activés
  bool get isEnabled => _isEnabled;

  /// Feedback léger (selection, navigation)
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Feedback moyen (confirmation, boutons importants)
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Feedback fort (succès important, erreur)
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Feedback de sélection (switches, toggles)
  Future<void> selectionClick() async {
    if (!_isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibration générique (pour erreurs critiques)
  Future<void> vibrate() async {
    if (!_isEnabled) return;
    await HapticFeedback.vibrate();
  }
}
