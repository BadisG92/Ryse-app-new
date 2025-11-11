import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/cardio_session_models.dart';

/// Service pour gérer la géolocalisation et les calculs GPS pour le cardio
class LocationService {
  // Cache pays pour l'existant
  static String? _cachedCountryCode;
  static String? _cachedCountryName;
  static bool _locationPermissionDenied = false; // Track if permission was denied

  // GPS Tracking pour cardio
  static StreamController<LocationPoint>? _locationController;
  static StreamSubscription<Position>? _positionSubscription;
  static List<LocationPoint> _currentRoute = [];
  static DateTime? _lastCalculationTime;

  // === NOUVELLES FONCTIONNALITÉS (SAFE, DÉSACTIVABLES) ===

  // Configuration des améliorations (désactivables sans risque)
  static bool _enableAutoPauseDetection = true;
  static bool _enableKalmanFilter = true;

  // Détection automatique des pauses
  static bool _isAutoPaused = false;
  static DateTime? _pauseStartTime;
  static const double _autoPauseSpeedThreshold = 0.5; // km/h
  static const int _autoPauseDelaySec = 3; // secondes

  // Filtre de Kalman simplifié
  static double? _kalmanEstimate; // Estimation de la vitesse
  static double _kalmanError = 1.0; // Erreur d'estimation
  static const double _processNoise = 0.1; // Bruit du processus
  static const double _measurementNoise = 4.0; // Bruit de mesure GPS

  /// Returns true if location permission was denied and app is using FR default
  static bool get isUsingDefaultCountry => _locationPermissionDenied;

  /// Stream des points de géolocalisation
  static Stream<LocationPoint>? get locationStream => _locationController?.stream;

  /// Liste des points de la route actuelle
  static List<LocationPoint> get currentRoute => List.unmodifiable(_currentRoute);

  /// État de la pause automatique
  static bool get isAutoPaused => _isAutoPaused;

  /// Active/Désactive la détection automatique des pauses
  static void setAutoPauseEnabled(bool enabled) {
    _enableAutoPauseDetection = enabled;
    if (!enabled) {
      _isAutoPaused = false;
      _pauseStartTime = null;
    }
  }

  /// Active/Désactive le filtre de Kalman
  static void setKalmanFilterEnabled(bool enabled) {
    _enableKalmanFilter = enabled;
    if (!enabled) {
      _kalmanEstimate = null;
      _kalmanError = 1.0;
    }
  }

  // === MÉTHODES EXISTANTES POUR LE PAYS ===
  
  /// Get user's country code (simple and cached approach)
  static Future<String> getUserCountryCode() async {
    // Return cached value if available
    if (_cachedCountryCode != null) {
      return _cachedCountryCode!;
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Default to International (no specific country) if no permission
        _locationPermissionDenied = true;
        if (kDebugMode) {
          debugPrint('⚠️ Location permission denied. Using international defaults.');
          debugPrint('ℹ️ User should be informed via: permission_location_denied_info');
          debugPrint('ℹ️ Caller can check: LocationService.isUsingDefaultCountry');
        }
        _cachedCountryCode = 'INT'; // International code
        _cachedCountryName = 'International';
        return 'INT';
      }

      // Get current position with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Low accuracy is fine for country
        timeLimit: const Duration(seconds: 10),
      );

      // Get country from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode ?? 'FR';
        final countryName = placemarks.first.country ?? 'France';
        
        // Cache the result
        _cachedCountryCode = countryCode;
        _cachedCountryName = countryName;
        
        return countryCode;
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting location: $e');
    }

    // Default fallback to international if error
    _cachedCountryCode = 'INT';
    _cachedCountryName = 'International';
    return 'INT';
  }

  /// Get user's country name for display
  static Future<String> getUserCountryName() async {
    // Ensure country code is loaded
    await getUserCountryCode();
    return _cachedCountryName ?? 'International';
  }

  /// Get country-specific food context for AI
  static Future<String> getFoodCultureContext() async {
    final countryCode = await getUserCountryCode();
    
    // Return culture-specific context for common countries
    switch (countryCode) {
      case 'FR':
        return 'French cuisine and portion sizes';
      case 'US':
        return 'American cuisine and portion sizes';
      case 'IT':
        return 'Italian cuisine and portion sizes';
      case 'ES':
        return 'Spanish cuisine and portion sizes';
      case 'DE':
        return 'German cuisine and portion sizes';
      case 'GB':
        return 'British cuisine and portion sizes';
      case 'JP':
        return 'Japanese cuisine and portion sizes';
      case 'CN':
        return 'Chinese cuisine and portion sizes';
      case 'IN':
        return 'Indian cuisine and portion sizes';
      case 'MX':
        return 'Mexican cuisine and portion sizes';
      case 'BR':
        return 'Brazilian cuisine and portion sizes';
      case 'CA':
        return 'Canadian cuisine and portion sizes';
      case 'AU':
        return 'Australian cuisine and portion sizes';
      case 'RU':
        return 'Russian cuisine and portion sizes';
      case 'KR':
        return 'Korean cuisine and portion sizes';
      case 'TH':
        return 'Thai cuisine and portion sizes';
      case 'VN':
        return 'Vietnamese cuisine and portion sizes';
      case 'TR':
        return 'Turkish cuisine and portion sizes';
      case 'GR':
        return 'Greek cuisine and portion sizes';
      case 'MA':
        return 'Moroccan cuisine and portion sizes';
      case 'EG':
        return 'Egyptian cuisine and portion sizes';
      case 'NG':
        return 'Nigerian cuisine and portion sizes';
      case 'ZA':
        return 'South African cuisine and portion sizes';
      case 'AR':
        return 'Argentinian cuisine and portion sizes';
      case 'CL':
        return 'Chilean cuisine and portion sizes';
      case 'PE':
        return 'Peruvian cuisine and portion sizes';
      default:
        return 'International cuisine and standard portion sizes';
    }
  }

  // === NOUVELLES MÉTHODES GPS POUR CARDIO ===

  /// Vérifie et demande les permissions de géolocalisation
  static Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de géolocalisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Services de géolocalisation désactivés');
      return false;
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permissions de géolocalisation refusées');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permissions de géolocalisation refusées définitivement');
      return false;
    }

    debugPrint('✅ Permissions de géolocalisation accordées');
    return true;
  }

  /// Démarre le suivi de géolocalisation pour une session cardio
  static Future<bool> startLocationTracking({
    int updateIntervalMs = 1000, // Mise à jour chaque seconde
    double distanceFilter = 1.0, // Filtre de distance minimale en mètres
  }) async {
    try {
      // Vérifier les permissions
      if (!await checkAndRequestPermissions()) {
        return false;
      }

      // Initialiser le controller s'il n'existe pas
      _locationController ??= StreamController<LocationPoint>.broadcast();
      _currentRoute.clear();

      // Configuration des paramètres de géolocalisation
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1, // Mise à jour tous les 1 mètres minimum
      );

      // Démarrer l'écoute des positions
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          final locationPoint = LocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            altitude: position.altitude,
            speed: position.speed > 0 ? position.speed : null, // m/s
          );

          _currentRoute.add(locationPoint);
          _locationController?.add(locationPoint);
          
          debugPrint('📍 Position: ${position.latitude}, ${position.longitude} - Vitesse: ${position.speed} m/s');
        },
        onError: (error) {
          debugPrint('❌ Erreur géolocalisation: $error');
        },
      );

      debugPrint('✅ Suivi de géolocalisation démarré');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de la géolocalisation: $e');
      return false;
    }
  }

  /// Arrête le suivi de géolocalisation
  static Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('⏹️ Suivi de géolocalisation arrêté');
  }

  /// Remet à zéro les données de route
  static void clearRoute() {
    _currentRoute.clear();
    _lastSmoothedSpeed = null; // Reset le cache de vitesse lissée
    _kalmanEstimate = null; // Reset le filtre de Kalman
    _kalmanError = 1.0;
    _isAutoPaused = false; // Reset la pause automatique
    _pauseStartTime = null;
  }

  /// Dispose des ressources
  static Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController?.close();
    _locationController = null;
    _currentRoute.clear();
    _lastSmoothedSpeed = null; // Reset le cache de vitesse lissée
    _kalmanEstimate = null; // Reset le filtre de Kalman
    _kalmanError = 1.0;
    _isAutoPaused = false; // Reset la pause automatique
    _pauseStartTime = null;
  }

  /// Calcule la distance totale parcourue en kilomètres
  static double calculateTotalDistance() {
    if (_currentRoute.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _currentRoute.length; i++) {
      totalDistance += calculateDistanceBetweenPoints(
        _currentRoute[i - 1],
        _currentRoute[i],
      );
    }

    return totalDistance / 1000; // Convertir en kilomètres
  }

  /// Calcule la vitesse moyenne en km/h
  static double calculateAverageSpeed() {
    if (_currentRoute.length < 2) return 0.0;

    final totalDistance = calculateTotalDistance(); // en km
    final duration = _currentRoute.last.timestamp.difference(_currentRoute.first.timestamp);
    
    if (duration.inSeconds == 0) return 0.0;
    
    return totalDistance / (duration.inMinutes / 60.0); // km/h
  }

  // Cache pour le lissage exponentiel de la vitesse
  static double? _lastSmoothedSpeed;
  static const double _smoothingFactor = 0.3; // 0-1, plus petit = plus lisse

  /// Calcule la vitesse instantanée en km/h basée sur les derniers points GPS
  /// Utilise un lissage exponentiel et une fenêtre glissante pour réduire la variabilité
  /// Option: Filtre de Kalman pour encore plus de précision
  static double calculateCurrentSpeed() {
    if (_currentRoute.length < 2) return 0.0;

    // Utiliser une fenêtre plus large (10 points = ~10 secondes) pour plus de stabilité
    final windowSize = _currentRoute.length >= 10 ? 10 : _currentRoute.length;
    final recentPoints = _currentRoute.sublist(_currentRoute.length - windowSize);

    if (recentPoints.length < 2) return 0.0;

    // Calculer la vitesse brute sur la fenêtre
    final distance = calculateDistanceBetweenPoints(
      recentPoints.first,
      recentPoints.last,
    ); // en mètres

    final timeDiff = recentPoints.last.timestamp.difference(recentPoints.first.timestamp);
    if (timeDiff.inSeconds == 0) return 0.0;

    final speedMs = distance / timeDiff.inSeconds; // m/s
    double rawSpeed = speedMs * 3.6; // km/h

    // Filtrer les vitesses aberrantes (> 50 km/h pour la course/vélo urbain)
    // Si vous faites du vélo de route, augmenter à 80 km/h
    if (rawSpeed > 50.0) {
      rawSpeed = _lastSmoothedSpeed ?? 0.0;
    }

    // === AMÉLIORATION 1: Filtre de Kalman (optionnel, désactivable) ===
    double filteredSpeed = rawSpeed;
    if (_enableKalmanFilter) {
      filteredSpeed = _applyKalmanFilter(rawSpeed);
    }

    // === AMÉLIORATION 2: Lissage exponentiel (existant, toujours actif) ===
    if (_lastSmoothedSpeed == null) {
      _lastSmoothedSpeed = filteredSpeed;
    } else {
      _lastSmoothedSpeed = (_smoothingFactor * filteredSpeed) +
                           ((1 - _smoothingFactor) * _lastSmoothedSpeed!);
    }

    // === AMÉLIORATION 3: Détection automatique des pauses (optionnel) ===
    if (_enableAutoPauseDetection) {
      _updateAutoPauseStatus(_lastSmoothedSpeed!);
    }

    return _lastSmoothedSpeed!;
  }

  /// Applique le filtre de Kalman pour lisser la vitesse
  /// Version simplifiée du filtre pour réduire le bruit GPS
  static double _applyKalmanFilter(double measurement) {
    // Initialisation au premier passage
    if (_kalmanEstimate == null) {
      _kalmanEstimate = measurement;
      return measurement;
    }

    // Étape 1: Prédiction (on suppose que la vitesse change peu)
    double prediction = _kalmanEstimate!;
    double predictionError = _kalmanError + _processNoise;

    // Étape 2: Mise à jour avec la mesure GPS
    double kalmanGain = predictionError / (predictionError + _measurementNoise);
    _kalmanEstimate = prediction + kalmanGain * (measurement - prediction);
    _kalmanError = (1 - kalmanGain) * predictionError;

    return _kalmanEstimate!;
  }

  /// Met à jour l'état de la pause automatique
  static void _updateAutoPauseStatus(double currentSpeed) {
    if (currentSpeed < _autoPauseSpeedThreshold) {
      // Vitesse faible, démarrer le compteur de pause
      _pauseStartTime ??= DateTime.now();

      final pauseDuration = DateTime.now().difference(_pauseStartTime!);
      if (pauseDuration.inSeconds >= _autoPauseDelaySec && !_isAutoPaused) {
        _isAutoPaused = true;
        debugPrint('⏸️ Pause automatique détectée (vitesse < $_autoPauseSpeedThreshold km/h)');
      }
    } else {
      // Vitesse normale, reprendre
      if (_isAutoPaused) {
        debugPrint('▶️ Reprise automatique (vitesse: ${currentSpeed.toStringAsFixed(1)} km/h)');
      }
      _isAutoPaused = false;
      _pauseStartTime = null;
    }
  }

  /// Calcule l'altitude actuelle
  static double? getCurrentAltitude() {
    return _currentRoute.isNotEmpty ? _currentRoute.last.altitude : null;
  }

  /// Calcule le dénivelé positif total
  static double calculateElevationGain() {
    if (_currentRoute.length < 2) return 0.0;

    double elevationGain = 0.0;
    for (int i = 1; i < _currentRoute.length; i++) {
      final current = _currentRoute[i].altitude;
      final previous = _currentRoute[i - 1].altitude;
      
      if (current != null && previous != null) {
        final diff = current - previous;
        if (diff > 0) {
          elevationGain += diff;
        }
      }
    }

    return elevationGain; // en mètres
  }

  /// Calcule l'allure (pace) en secondes par kilomètre
  static int? calculatePacePerKm() {
    final averageSpeed = calculateAverageSpeed(); // km/h
    if (averageSpeed == 0) return null;
    
    final paceMinutesPerKm = 60 / averageSpeed; // minutes par km
    return (paceMinutesPerKm * 60).round(); // secondes par km
  }

  /// Obtient la position actuelle unique
  static Future<LocationPoint?> getCurrentPosition() async {
    try {
      if (!await checkAndRequestPermissions()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        altitude: position.altitude,
        speed: position.speed > 0 ? position.speed : null,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Calcule la distance entre deux points GPS en mètres (formule haversine)
  static double calculateDistanceBetweenPoints(LocationPoint point1, LocationPoint point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Filtre les points GPS pour éviter les aberrations (points trop éloignés)
  static List<LocationPoint> filterGpsPoints(List<LocationPoint> points) {
    if (points.length <= 2) return points;

    final List<LocationPoint> filteredPoints = [points.first];
    
    for (int i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = filteredPoints.last;
      
      // Calculer la distance et le temps entre les points
      final distance = calculateDistanceBetweenPoints(previous, current);
      final timeDiff = current.timestamp.difference(previous.timestamp).inSeconds;
      
      // Filtrer les points qui impliqueraient une vitesse irréaliste (> 100 km/h)
      if (timeDiff > 0) {
        final speedMs = distance / timeDiff;
        final speedKmh = speedMs * 3.6;
        
        if (speedKmh <= 100) { // Vitesse maximale raisonnable
          filteredPoints.add(current);
        }
      }
    }
    
    return filteredPoints;
  }

  /// Lisse la trajectoire GPS pour réduire le bruit
  static List<LocationPoint> smoothGpsTrack(List<LocationPoint> points, {int windowSize = 3}) {
    if (points.length <= windowSize) return points;

    final List<LocationPoint> smoothedPoints = [];
    
    for (int i = 0; i < points.length; i++) {
      final start = (i - windowSize ~/ 2).clamp(0, points.length - 1);
      final end = (i + windowSize ~/ 2).clamp(0, points.length - 1);
      
      double latSum = 0, lonSum = 0, altSum = 0;
      int altCount = 0;
      
      for (int j = start; j <= end; j++) {
        latSum += points[j].latitude;
        lonSum += points[j].longitude;
        if (points[j].altitude != null) {
          altSum += points[j].altitude!;
          altCount++;
        }
      }
      
      final count = end - start + 1;
      smoothedPoints.add(LocationPoint(
        latitude: latSum / count,
        longitude: lonSum / count,
        timestamp: points[i].timestamp,
        altitude: altCount > 0 ? altSum / altCount : null,
        speed: points[i].speed,
      ));
    }
    
    return smoothedPoints;
  }

  /// Clear cached location data (useful for testing)
  static void clearCache() {
    _cachedCountryCode = null;
    _cachedCountryName = null;
  }
}