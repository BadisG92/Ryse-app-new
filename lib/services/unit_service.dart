import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service central pour la gestion des unités de mesure (métrique/impérial)
///
/// RÈGLE D'OR: Les données sont TOUJOURS stockées en métrique (kg, km, cm)
/// La conversion se fait uniquement à l'affichage et à la saisie
class UnitService extends ChangeNotifier {
  static const String _unitKey = 'measurement_unit';

  // Constantes de conversion
  static const double _kgToLbs = 2.20462;
  static const double _kmToMiles = 0.621371;
  static const double _cmToInches = 0.393701;

  bool _isImperial = false;
  bool _isInitialized = false;

  // Getters
  bool get isImperial => _isImperial;
  bool get isMetric => !_isImperial;
  bool get isInitialized => _isInitialized;

  // Singleton
  static UnitService? _instance;
  static UnitService get instance {
    _instance ??= UnitService._();
    return _instance!;
  }

  UnitService._();

  /// Initialise le service en chargeant la préférence sauvegardée
  /// Priorité: 1) SharedPreferences (local), 2) Supabase (remote), 3) Défaut (métrique)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString(_unitKey);

    // Si on a une valeur locale, l'utiliser
    if (savedUnit != null) {
      _isImperial = savedUnit == 'Impérial' || savedUnit == 'imperial';
      _isInitialized = true;
      debugPrint('📏 UnitService initialisé (local): ${_isImperial ? "Impérial" : "Métrique"}');
      notifyListeners();
      return;
    }

    // Sinon, essayer de récupérer depuis Supabase (pour les utilisateurs existants)
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('users')
            .select('is_metric')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

        if (response != null && response['is_metric'] != null) {
          final isMetric = response['is_metric'] as bool;
          _isImperial = !isMetric;

          // Synchroniser avec SharedPreferences pour les prochains lancements
          await prefs.setString(_unitKey, _isImperial ? 'Impérial' : 'Métrique');
          debugPrint('📏 UnitService initialisé (Supabase): ${_isImperial ? "Impérial" : "Métrique"}');
        } else {
          // Pas de données utilisateur, utiliser métrique par défaut
          _isImperial = false;
          debugPrint('📏 UnitService initialisé (défaut): Métrique');
        }
      } else {
        // Pas d'utilisateur connecté, utiliser métrique par défaut
        _isImperial = false;
        debugPrint('📏 UnitService initialisé (pas connecté): Métrique');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lecture unité depuis Supabase: $e');
      // En cas d'erreur, utiliser métrique par défaut
      _isImperial = false;
      debugPrint('📏 UnitService initialisé (erreur fallback): Métrique');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Change le système d'unités
  /// Sauvegarde dans SharedPreferences ET Supabase pour synchronisation
  Future<void> setImperial(bool imperial) async {
    if (_isImperial != imperial) {
      _isImperial = imperial;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unitKey, imperial ? 'Impérial' : 'Métrique');

      // Synchroniser avec Supabase pour persistance cross-device
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase
              .from('users')
              .update({'is_metric': !imperial})
              .eq('id', user.id);
          debugPrint('📏 Unité synchronisée avec Supabase: ${imperial ? "Impérial" : "Métrique"}');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur sync unité Supabase: $e');
        // Continue sans erreur - la valeur locale est sauvegardée
      }

      debugPrint('📏 Unité changée: ${imperial ? "Impérial" : "Métrique"}');
      notifyListeners();
    }
  }

  // ============================================
  // CONVERSIONS DE POIDS (kg <-> lbs)
  // ============================================

  /// Convertit des kg vers l'unité d'affichage (kg ou lbs)
  double displayWeight(double kg) {
    if (!_isImperial) return kg;
    return kg * _kgToLbs;
  }

  /// Convertit une valeur saisie vers kg pour stockage
  double storageWeight(double value) {
    if (!_isImperial) return value;
    return value / _kgToLbs;
  }

  /// Formate un poids pour l'affichage avec unité
  /// [kg] - la valeur en kg (depuis la DB)
  /// [decimals] - nombre de décimales (défaut: 1)
  String formatWeight(double kg, {int decimals = 1}) {
    final value = displayWeight(kg);
    final unit = weightUnit;
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  /// Formate un poids sans unité (juste la valeur)
  String formatWeightValue(double kg, {int decimals = 1}) {
    return displayWeight(kg).toStringAsFixed(decimals);
  }

  /// Label de l'unité de poids
  String get weightUnit => _isImperial ? 'lbs' : 'kg';

  // ============================================
  // CONVERSIONS DE DISTANCE (km <-> miles)
  // ============================================

  /// Convertit des km vers l'unité d'affichage (km ou miles)
  double displayDistance(double km) {
    if (!_isImperial) return km;
    return km * _kmToMiles;
  }

  /// Convertit une valeur saisie vers km pour stockage
  double storageDistance(double value) {
    if (!_isImperial) return value;
    return value / _kmToMiles;
  }

  /// Formate une distance pour l'affichage avec unité
  String formatDistance(double km, {int decimals = 2}) {
    final value = displayDistance(km);
    final unit = distanceUnit;
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  /// Formate une distance sans unité
  String formatDistanceValue(double km, {int decimals = 2}) {
    return displayDistance(km).toStringAsFixed(decimals);
  }

  /// Label de l'unité de distance
  String get distanceUnit => _isImperial ? 'mi' : 'km';

  // ============================================
  // CONVERSIONS DE VITESSE (km/h <-> mph)
  // ============================================

  /// Convertit km/h vers l'unité d'affichage
  double displaySpeed(double kmh) {
    if (!_isImperial) return kmh;
    return kmh * _kmToMiles;
  }

  /// Convertit une vitesse saisie vers km/h pour stockage
  double storageSpeed(double value) {
    if (!_isImperial) return value;
    return value / _kmToMiles;
  }

  /// Formate une vitesse pour l'affichage
  String formatSpeed(double kmh, {int decimals = 1}) {
    final value = displaySpeed(kmh);
    final unit = speedUnit;
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  /// Label de l'unité de vitesse
  String get speedUnit => _isImperial ? 'mph' : 'km/h';

  // ============================================
  // CONVERSIONS D'ALLURE (min/km <-> min/mile)
  // ============================================

  /// Convertit une allure min/km vers l'unité d'affichage
  /// L'allure impériale est plus longue (1 mile > 1 km)
  double displayPace(double minPerKm) {
    if (!_isImperial) return minPerKm;
    // min/km -> min/mile (multiplier par 1.60934)
    return minPerKm / _kmToMiles;
  }

  /// Convertit une allure saisie vers min/km pour stockage
  double storagePace(double value) {
    if (!_isImperial) return value;
    return value * _kmToMiles;
  }

  /// Formate une allure pour l'affichage (format mm:ss)
  String formatPace(double minPerKm) {
    final paceValue = displayPace(minPerKm);
    final minutes = paceValue.floor();
    final seconds = ((paceValue - minutes) * 60).round();
    final unit = paceUnit;
    return '$minutes:${seconds.toString().padLeft(2, '0')} $unit';
  }

  /// Label de l'unité d'allure
  String get paceUnit => _isImperial ? '/mi' : '/km';

  // ============================================
  // CONVERSIONS DE TAILLE (cm <-> inches/feet)
  // ============================================

  /// Convertit cm vers inches
  double displayHeight(double cm) {
    if (!_isImperial) return cm;
    return cm * _cmToInches;
  }

  /// Convertit une taille saisie vers cm pour stockage
  double storageHeight(double value) {
    if (!_isImperial) return value;
    return value / _cmToInches;
  }

  /// Formate une taille pour l'affichage
  /// En impérial: format feet'inches" (ex: 5'10")
  /// En métrique: cm
  String formatHeight(double cm) {
    if (!_isImperial) {
      return '${cm.round()} cm';
    }
    final totalInches = cm * _cmToInches;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  /// Label de l'unité de taille (pour affichage formaté)
  String get heightUnit => _isImperial ? 'in' : 'cm';

  /// Label de l'unité de taille pour le résumé (feet'inches")
  String get heightUnitFull => _isImperial ? 'ft/in' : 'cm';

  // ============================================
  // HELPERS POUR LES PROMPTS IA
  // ============================================

  /// Retourne le contexte d'unité pour les prompts Gemini
  String getUnitContextForPrompt() {
    if (_isImperial) {
      return 'L\'utilisateur utilise le système impérial (lbs pour le poids, miles pour les distances, mph pour la vitesse).';
    }
    return 'L\'utilisateur utilise le système métrique (kg pour le poids, km pour les distances, km/h pour la vitesse).';
  }

  /// Retourne le contexte d'unité en anglais pour les prompts
  String getUnitContextForPromptEn() {
    if (_isImperial) {
      return 'The user uses the imperial system (lbs for weight, miles for distance, mph for speed).';
    }
    return 'The user uses the metric system (kg for weight, km for distance, km/h for speed).';
  }
}
