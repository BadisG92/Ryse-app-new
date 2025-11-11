import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service pour gérer le compteur de pas natif (iOS & Android)
///
/// Utilise le capteur de pas natif du téléphone pour un tracking précis.
/// Inclut un système de fallback pour les appareils sans capteur.
class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  // Streams pour les événements du pedometer
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;

  // État actuel
  int _sessionStartSteps = 0;
  int _currentTotalSteps = 0;
  bool _isTracking = false;
  bool _isPedometerAvailable = false;
  String _pedestrianStatus = 'unknown'; // 'walking', 'stopped', 'unknown'

  // Callbacks pour notifier les changements
  Function(int steps)? onStepCountChanged;
  Function(PedestrianStatus status)? onPedestrianStatusChanged;

  /// Vérifie si le pedometer est disponible sur cet appareil
  Future<bool> checkPedometerAvailability() async {
    if (kIsWeb) {
      debugPrint('⚠️ Pedometer: Non disponible sur Web');
      _isPedometerAvailable = false;
      return false;
    }

    try {
      // Vérifier les permissions
      PermissionStatus status;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS utilise Motion & Fitness permission
        status = await Permission.sensors.status;
        if (status.isDenied) {
          status = await Permission.sensors.request();
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android 10+ utilise Activity Recognition permission
        status = await Permission.activityRecognition.status;
        if (status.isDenied) {
          status = await Permission.activityRecognition.request();
        }
      } else {
        debugPrint('⚠️ Pedometer: Plateforme non supportée');
        _isPedometerAvailable = false;
        return false;
      }

      if (status.isGranted) {
        _isPedometerAvailable = true;
        debugPrint('✅ Pedometer: Disponible et permissions accordées');
        return true;
      } else {
        debugPrint('⚠️ Pedometer: Permissions refusées');
        _isPedometerAvailable = false;
        return false;
      }
    } catch (e) {
      debugPrint('❌ Pedometer: Erreur lors de la vérification - $e');
      _isPedometerAvailable = false;
      return false;
    }
  }

  /// Démarre le suivi des pas
  /// Retourne true si le pedometer natif est actif, false si fallback nécessaire
  Future<bool> startTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ Pedometer: Déjà en cours de tracking');
      return _isPedometerAvailable;
    }

    // Vérifier la disponibilité
    await checkPedometerAvailability();

    if (!_isPedometerAvailable) {
      debugPrint('⚠️ Pedometer: Non disponible, utiliser fallback GPS');
      return false;
    }

    try {
      // Initialiser le stream des pas
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Initialiser le stream du statut piéton
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isTracking = true;
      debugPrint('✅ Pedometer: Tracking démarré');
      return true;
    } catch (e) {
      debugPrint('❌ Pedometer: Erreur au démarrage - $e');
      _isPedometerAvailable = false;
      return false;
    }
  }

  /// Arrête le suivi des pas
  void stopTracking() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    _stepCountStream = null;
    _pedestrianStatusStream = null;
    _isTracking = false;
    debugPrint('🛑 Pedometer: Tracking arrêté');
  }

  /// Réinitialise le compteur pour une nouvelle session
  void resetSessionSteps() {
    _sessionStartSteps = _currentTotalSteps;
    debugPrint('🔄 Pedometer: Session réinitialisée (départ: $_sessionStartSteps pas)');
  }

  /// Retourne le nombre de pas depuis le début de la session
  int getSessionSteps() {
    if (_currentTotalSteps == 0 || _sessionStartSteps == 0) {
      return 0;
    }
    final sessionSteps = _currentTotalSteps - _sessionStartSteps;
    return sessionSteps > 0 ? sessionSteps : 0;
  }

  /// Callback appelé à chaque nouveau pas détecté
  void _onStepCount(StepCount event) {
    _currentTotalSteps = event.steps;
    final sessionSteps = getSessionSteps();

    debugPrint('👣 Pedometer: ${event.steps} pas totaux, $sessionSteps pas cette session');

    // Notifier le callback
    onStepCountChanged?.call(sessionSteps);
  }

  /// Callback appelé en cas d'erreur du step count
  void _onStepCountError(error) {
    debugPrint('❌ Pedometer StepCount Error: $error');
    _isPedometerAvailable = false;
  }

  /// Callback appelé lors du changement de statut piéton
  void _onPedestrianStatusChanged(PedestrianStatus status) {
    _pedestrianStatus = status.status;
    debugPrint('🚶 Pedometer: Statut piéton - ${status.status}');

    // Notifier le callback
    onPedestrianStatusChanged?.call(status);
  }

  /// Callback appelé en cas d'erreur du statut piéton
  void _onPedestrianStatusError(error) {
    debugPrint('⚠️ Pedometer PedestrianStatus Error: $error');
  }

  /// Vérifie si l'utilisateur marche actuellement
  bool isWalking() {
    return _pedestrianStatus == 'walking';
  }

  /// Vérifie si le pedometer est actif et fonctionnel
  bool get isAvailable => _isPedometerAvailable;

  /// Vérifie si le tracking est en cours
  bool get isTracking => _isTracking;

  /// Retourne le statut piéton actuel
  String get pedestrianStatus => _pedestrianStatus;

  /// Nettoie les ressources
  void dispose() {
    stopTracking();
    onStepCountChanged = null;
    onPedestrianStatusChanged = null;
  }
}

/// Extension pour faciliter la lecture du statut piéton
extension PedestrianStatusStringExtension on String {
  bool get isWalking => this == 'walking';
  bool get isStopped => this == 'stopped';
  bool get isUnknown => this == 'unknown';
}
