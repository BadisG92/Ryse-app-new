import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/cardio_session_models.dart';
import '../services/cardio_service.dart';
import '../services/location_service.dart';
import '../services/cardio_calculator.dart';
import '../services/cardio_session_manager.dart';
import '../services/celebration_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/global_state_manager.dart';
import '../services/pedometer_service.dart';
import '../services/unit_service.dart';
import '../services/weekly_planner_service.dart';
import '../models/weekly_planner_models.dart';

class CardioTrackingScreen extends StatefulWidget {
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final CardioObjective? objective;

  const CardioTrackingScreen({
    super.key,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    this.objective,
  });

  @override
  State<CardioTrackingScreen> createState() => _CardioTrackingScreenState();
}

class _CardioTrackingScreenState extends State<CardioTrackingScreen> {
  late CardioSessionData _session;
  Timer? _timer;
  StreamSubscription<LocationPoint>? _locationSubscription;
  bool _useGPS = false;
  bool _gpsPermissionGranted = false;
  bool _sessionSaved = false; // Protection contre les doubles validations

  // Pedometer
  final PedometerService _pedometerService = PedometerService();
  bool _usePedometer = false;
  bool _pedometerAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _checkGPSPermissions();
    _checkPedometerAvailability();
  }

  void _initializeSession() {
    _session = CardioSessionData(
      activityType: widget.activityType,
      activityTitle: widget.activityTitle,
      formatTitle: widget.formatTitle,
      startTime: DateTime.now(),
      targetDistance: widget.objective?.targetDistance,
      targetDuration: widget.objective?.targetDuration,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    if (_useGPS) {
      LocationService.stopLocationTracking();
    }
    if (_usePedometer) {
      _pedometerService.stopTracking();
    }
    _pedometerService.dispose();
    super.dispose();
  }

  /// Vérifie la disponibilité du pedometer pour la marche
  Future<void> _checkPedometerAvailability() async {
    // Le pedometer n'est utile que pour la marche
    if (widget.activityType != 'walking') {
      setState(() {
        _pedometerAvailable = false;
        _usePedometer = false;
      });
      return;
    }

    final isAvailable = await _pedometerService.checkPedometerAvailability();
    setState(() {
      _pedometerAvailable = isAvailable;
      _usePedometer = isAvailable; // Activer par défaut si disponible
    });

    if (isAvailable) {
      debugPrint('✅ Pedometer: Activé pour le tracking des pas');
    } else {
      debugPrint('⚠️ Pedometer: Non disponible, utiliser fallback GPS/Simulation');
    }
  }

  /// Vérifie les permissions GPS au démarrage
  Future<void> _checkGPSPermissions() async {
    // Sur web, le GPS est moins fiable pour le tracking sportif
    if (kIsWeb) {
      _showWebTrackingLimitation();
      setState(() {
        _gpsPermissionGranted = false;
        _useGPS = false;
      });
      return;
    }

    final hasPermission = await LocationService.checkAndRequestPermissions();
    setState(() {
      _gpsPermissionGranted = hasPermission;
      if (hasPermission) {
        _useGPS = true; // Activer GPS par défaut si permissions accordées
      }
    });
    
    if (!hasPermission) {
      _showGPSPermissionDialog();
    }
  }

  /// Affiche un dialog pour expliquer les limitations web
  void _showWebTrackingLimitation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info, color: Color(0xFFFFB000)),
            const SizedBox(width: 8),
            Text('tracking_web_limitation_title'.tr(LocalizationService.instance.currentLanguageCode)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tracking_web_limitation_description'.tr(LocalizationService.instance.currentLanguageCode),
            ),
            const SizedBox(height: 12),
            Text(
              'tracking_web_recommendation'.tr(LocalizationService.instance.currentLanguageCode),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('tracking_understood'.tr(LocalizationService.instance.currentLanguageCode)),
          ),
        ],
      ),
    );
  }

  /// Affiche un dialog pour expliquer les permissions GPS
  void _showGPSPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFFFB000)),
            const SizedBox(width: 8),
            Text('tracking_gps_title'.tr(LocalizationService.instance.currentLanguageCode)),
          ],
        ),
        content: Text(
          'tracking_gps_description'.tr(LocalizationService.instance.currentLanguageCode),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('tracking_later'.tr(LocalizationService.instance.currentLanguageCode)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkGPSPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
            ),
            child: Text('tracking_allow'.tr(LocalizationService.instance.currentLanguageCode), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startTracking() async {
    // Démarrer le pedometer si disponible et c'est de la marche
    if (_usePedometer && _pedometerAvailable && widget.activityType == 'walking') {
      final pedometerStarted = await _pedometerService.startTracking();
      if (pedometerStarted) {
        _pedometerService.resetSessionSteps();

        // Callback pour mettre à jour les pas en temps réel
        _pedometerService.onStepCountChanged = (steps) {
          if (mounted) {
            setState(() {
              _session = _session.copyWith(steps: steps);
            });
          }
        };

        debugPrint('✅ Pedometer: Tracking des pas démarré');
      } else {
        debugPrint('⚠️ Pedometer: Échec du démarrage, utiliser fallback');
        _usePedometer = false;
      }
    }

    // Démarrer le suivi GPS si disponible
    if (_useGPS && _gpsPermissionGranted) {
      final gpsStarted = await LocationService.startLocationTracking();
      if (gpsStarted) {
        _locationSubscription = LocationService.locationStream?.listen(_onLocationUpdate);
      }
    }

    // Timer principal pour mettre à jour l'interface
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Mettre à jour le temps
        _session = _session.copyWith(
          duration: Duration(seconds: _session.duration.inSeconds + 1),
        );

        if (_useGPS && _gpsPermissionGranted) {
          // Utiliser les données GPS réelles
          debugPrint('🌍 Utilisation GPS réel - route points: ${LocationService.currentRoute.length}');
          _updateFromGPS();
        } else {
          // Mode simulation (fallback)
          debugPrint('⚠️ Mode simulation - GPS: $_useGPS, Permission: $_gpsPermissionGranted, Platform: ${kIsWeb ? "Web" : "Mobile"}');
          _updateWithSimulation();
        }

        // Vérifier si objectif atteint
        if (_session.isTargetReached()) {
          _showTargetReachedDialog();
        }
      });
    });

    setState(() {
      _session = _session.copyWith(isRunning: true, isPaused: false);
    });
  }

  /// Met à jour les données basées sur le GPS
  void _updateFromGPS() {
    final distance = LocationService.calculateTotalDistance();
    final averageSpeed = LocationService.calculateAverageSpeed();
    final currentSpeed = LocationService.calculateCurrentSpeed();
    final route = LocationService.currentRoute;

    debugPrint('📊 GPS Data - Distance: ${distance.toStringAsFixed(2)}km, Speed: ${currentSpeed.toStringAsFixed(1)}km/h, Points: ${route.length}');

    // Calculer les calories avec les vraies données
    final calories = CardioCalculator.calculateCalories(
      activityType: widget.activityType,
      duration: _session.duration,
      averageSpeed: averageSpeed,
      distance: distance,
    );

    // Calculer les pas pour la marche UNIQUEMENT si pedometer pas actif
    int steps = _session.steps;
    if (widget.activityType == 'walking' && !_usePedometer) {
      // FORMULE SCIENTIFIQUE: 1 km = ~1250 pas pour un adulte moyen (foulée ~0.8m)
      // Ajuster selon la vitesse pour plus de précision
      final strideLength = _calculateStrideLength(currentSpeed);
      steps = ((distance * 1000) / strideLength).round(); // distance en mètres / longueur foulée

      debugPrint('👣 GPS Fallback: $steps pas estimés (foulée: ${strideLength.toStringAsFixed(2)}m)');
    }

    _session = _session.copyWith(
      distance: distance,
      currentSpeed: currentSpeed,
      averageSpeed: averageSpeed,
      steps: steps,
      calories: calories,
      route: route,
    );
  }

  /// Calcule la longueur de foulée selon la vitesse
  /// Formule basée sur des études biomécaniques
  double _calculateStrideLength(double speedKmh) {
    // Longueur de foulée moyenne selon la vitesse (en mètres)
    // Source: Biomechanical studies on gait patterns
    if (speedKmh < 3.0) {
      return 0.60; // Marche très lente
    } else if (speedKmh < 4.0) {
      return 0.70; // Marche lente
    } else if (speedKmh < 5.0) {
      return 0.78; // Marche normale
    } else if (speedKmh < 6.0) {
      return 0.85; // Marche rapide
    } else {
      return 0.95; // Marche très rapide / transition vers course
    }
  }

  /// Met à jour avec des données simulées (fallback)
  void _updateWithSimulation() {
    final Random random = Random();
    double speedIncrement;
    int stepsIncrement = 0;

    switch (widget.activityType) {
      case 'running':
        speedIncrement = random.nextDouble() * 0.003 + 0.002; // ~8-12 km/h
        break;
      case 'bike':
        speedIncrement = random.nextDouble() * 0.005 + 0.004; // ~15-25 km/h
        break;
      case 'walking':
        if (!_usePedometer) {
          // Mode simulation: cadence réaliste de 100-120 pas/minute
          speedIncrement = random.nextDouble() * 0.001 + 0.001; // ~4-6 km/h

          // CORRECTION: 100-120 pas/minute = 1.67-2 pas/seconde
          // Utiliser une distribution plus réaliste
          final stepsPerSecond = 1.67 + (random.nextDouble() * 0.33); // 1.67-2.0 pas/sec
          stepsIncrement = stepsPerSecond.round(); // Arrondi pour éviter les fractions

          debugPrint('🎲 Simulation: +$stepsIncrement pas (${(stepsPerSecond * 60).toStringAsFixed(0)} pas/min)');
        } else {
          speedIncrement = random.nextDouble() * 0.001 + 0.001;
        }
        break;
      default:
        speedIncrement = 0.002;
    }

    _session = _session.copyWith(
      distance: _session.distance + speedIncrement,
      currentSpeed: speedIncrement * 3600, // convertir en km/h
      averageSpeed: _session.calculateAverageSpeed(),
      steps: _session.steps + stepsIncrement,
      calories: _session.calculateCalories(),
    );
  }

  /// Callback appelé à chaque nouvelle position GPS
  void _onLocationUpdate(LocationPoint locationPoint) {
    debugPrint('📍 Nouvelle position GPS: ${locationPoint.latitude}, ${locationPoint.longitude}');
    // Les calculs sont faits dans _updateFromGPS(), pas besoin d'action ici
  }

  void _pauseTracking() {
    _timer?.cancel();
    if (_useGPS) {
      LocationService.stopLocationTracking();
      _locationSubscription?.cancel();
    }
    setState(() {
      _session = _session.copyWith(isRunning: false, isPaused: true);
    });
  }

  void _resumeTracking() {
    _startTracking();
  }

  void _stopTracking() {
    _timer?.cancel();
    if (_useGPS) {
      LocationService.stopLocationTracking();
      _locationSubscription?.cancel();
    }
    setState(() {
      _session = _session.copyWith(
        isRunning: false,
        endTime: DateTime.now(),
      );
    });
    _showSessionSummary();
  }

  void _showTargetReachedDialog() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.trophy, color: Color(0xFFFFB000)),
            const SizedBox(width: 8),
            Text('tracking_objective_reached'.tr(LocalizationService.instance.currentLanguageCode)),
          ],
        ),
        content: const Text('Félicitations ! Tu as atteint ton objectif. Veux-tu continuer ou terminer la séance ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeTracking();
            },
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
            ),
            child: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 32,
                    color: Color(0xFF10B981),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Titre
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'tracking_session_finished'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'tracking_session_finished_subtitle'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Métriques en grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Première ligne
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'tracking_summary_duration'.tr(locService.currentLanguageCode),
                                _formatDuration(_session.duration),
                                LucideIcons.clock,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'tracking_summary_distance'.tr(locService.currentLanguageCode),
                                UnitService.instance.formatDistance(_session.distance),
                                LucideIcons.mapPin,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      
                      // Deuxième ligne
                      Row(
                        children: [
                          Expanded(
                            child: widget.activityType == 'walking'
                                ? Consumer<LocalizationService>(
                                    builder: (context, locService, _) => _buildSummaryMetric(
                                      'tracking_summary_steps'.tr(locService.currentLanguageCode),
                                      '${_session.steps}',
                                      LucideIcons.footprints,
                                    ),
                                  )
                                : Consumer<LocalizationService>(
                                    builder: (context, locService, _) => _buildSummaryMetric(
                                      'tracking_summary_average_speed'.tr(locService.currentLanguageCode),
                                      UnitService.instance.formatSpeed(_session.averageSpeed),
                                      LucideIcons.gauge,
                                    ),
                                  ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => _buildSummaryMetric(
                                'tracking_summary_calories'.tr(locService.currentLanguageCode),
                                '${_session.calories} kcal',
                                LucideIcons.flame,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Métrique supplémentaire pour la marche
                      if (widget.activityType == 'walking') ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => _buildSummaryMetric(
                            'tracking_steps_per_minute'.tr(locService.currentLanguageCode),
                            '${_session.calculateStepsPerMinute().toStringAsFixed(0)}',
                            LucideIcons.activity,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sessionSaved ? null : () async {
                      // Protection contre double clic
                      if (_sessionSaved) {
                        debugPrint('⚠️ Session déjà sauvegardée, ignorer');
                        return;
                      }

                      setState(() {
                        _sessionSaved = true;
                      });

                      // Historiser la session avec GPS dans Supabase
                      try {
                        String? sessionId;
                        if (_useGPS && _gpsPermissionGranted) {
                          sessionId = await CardioSessionManager.completeCardioSessionWithGPS(
                            sessionData: _session,
                            intensity: 'Modéré',
                            notes: null,
                          );
                        } else {
                          sessionId = await _saveSessionToSupabase();
                        }
                        debugPrint('✅ Session cardio sauvegardée (id: $sessionId)');

                        // UNE SEULE mise à jour du GlobalState pour éviter les doublons
                        GlobalStateManager.instance.updateWorkout(true);
                        debugPrint('✅ GlobalStateManager: Cardio marqué comme complété');

                        // WEEKLY PLANNER SYNC: Synchroniser avec le planificateur
                        if (sessionId != null) {
                          try {
                            await WeeklyPlannerService.syncCardioSessionToPlanner(
                              sessionId: sessionId,
                              activityType: widget.activityType,
                              activityTitle: widget.activityTitle,
                              sessionDate: DateTime.now(),
                              durationMinutes: _session.duration.inMinutes,
                              distanceKm: _session.distance > 0 ? _session.distance : null,
                            );
                            debugPrint('✅ Weekly Planner: Cardio sync effectuée');
                          } catch (plannerError) {
                            debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
                          }
                        }

                        // Marquer pour afficher le popup après retour écran
                        CelebrationService().celebrateCardioCompletionGlobal(
                          activityTitle: widget.activityTitle,
                          duration: _session.duration,
                          distanceKm: _session.distance,
                        );
                      } catch (e) {
                        debugPrint('❌ Erreur sauvegarde session: $e');
                        setState(() {
                          _sessionSaved = false; // Réinitialiser en cas d'erreur
                        });
                        // Continuer même en cas d'erreur pour ne pas bloquer l'utilisateur
                      }

                      if (mounted) {
                        Navigator.pop(context); // Fermer écran résultat
                        Navigator.pop(context); // Retourner au cardio (se rafraîchira automatiquement)
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'session_end_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0B132B),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _session.getActivityColor(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.activityTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Indicateur Mode de tracking
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTrackingModeColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTrackingModeColor(),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTrackingModeIcon(),
                                  size: 12,
                                  color: _getTrackingModeColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getTrackingModeLabel(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getTrackingModeColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.formatTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Bouton toggle GPS (si permissions refusées)
                      if (!_gpsPermissionGranted)
                        IconButton(
                          onPressed: _checkGPSPermissions,
                          icon: const Icon(
                            LucideIcons.mapPin,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          if (_session.isRunning) {
                            _pauseTracking();
                          }
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Métriques principales
              Expanded(
                child: Column(
                  children: [
                    // Durée principale
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDuration(_session.duration),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'tracking_duration'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Métriques secondaires
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Consumer<LocalizationService>(
                                  builder: (context, locService, _) => _buildMetric(
                                    'tracking_distance'.tr(locService.currentLanguageCode),
                                    UnitService.instance.formatDistance(_session.distance),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: widget.activityType == 'walking'
                                    ? Consumer<LocalizationService>(
                                        builder: (context, locService, _) => _buildMetric(
                                          'tracking_steps'.tr(locService.currentLanguageCode),
                                          '${_session.steps}',
                                        ),
                                      )
                                    : Consumer<LocalizationService>(
                                        builder: (context, locService, _) => _buildMetric(
                                          'tracking_speed'.tr(locService.currentLanguageCode),
                                          UnitService.instance.formatSpeed(_session.currentSpeed),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: widget.activityType == 'walking'
                                    ? Consumer<LocalizationService>(
                                        builder: (context, locService, _) => _buildMetric(
                                          'tracking_steps_per_minute'.tr(locService.currentLanguageCode),
                                          '${_session.calculateStepsPerMinute().toStringAsFixed(0)}',
                                        ),
                                      )
                                    : Consumer<LocalizationService>(
                                        builder: (context, locService, _) => _buildMetric(
                                          'tracking_average'.tr(locService.currentLanguageCode),
                                          UnitService.instance.formatSpeed(_session.averageSpeed),
                                        ),
                                      ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: Consumer<LocalizationService>(
                                  builder: (context, locService, _) => _buildMetric(
                                    'tracking_calories'.tr(locService.currentLanguageCode),
                                    '${_session.calories} kcal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Objectif (si défini)
                    if (widget.objective != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.target,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getObjectiveText(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Boutons de contrôle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton pause/play
                  if (!_session.isRunning && !_session.isPaused)
                    _buildControlButton(
                      icon: LucideIcons.play,
                      onPressed: _startTracking,
                      isPrimary: true,
                    )
                  else if (_session.isRunning)
                    _buildControlButton(
                      icon: LucideIcons.pause,
                      onPressed: _pauseTracking,
                      isPrimary: true,
                    )
                  else
                    _buildControlButton(
                      icon: LucideIcons.play,
                      onPressed: _resumeTracking,
                      isPrimary: true,
                    ),

                  // Bouton stop - visible uniquement si session démarrée (isRunning ou isPaused)
                  if (_session.isRunning || _session.isPaused)
                    _buildControlButton(
                      icon: LucideIcons.square,
                      onPressed: _stopTracking,
                      isPrimary: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.2),
          border: !isPrimary ? Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ) : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? _session.getActivityColor() : Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Sauvegarde la session dans Supabase
  /// Retourne l'ID de la session créée pour la synchronisation avec le planner
  Future<String> _saveSessionToSupabase() async {
    try {
      final sessionId = await CardioService.saveCompletedCardioSession(
        sessionData: _session,
        intensity: 'Modéré', // Valeur par défaut, pourrait être demandée à l'utilisateur
        notes: null,
      );

      // Invalider le cache pour rafraîchir les données
      CardioService.invalidateCache();

      return sessionId;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  String _getObjectiveText() {
    final locService = LocalizationService.instance;
    if (widget.objective?.targetDistance != null) {
      final remaining = widget.objective!.targetDistance! - _session.distance;
      if (remaining > 0) {
        return '${'tracking_objective_distance_remaining'.tr(locService.currentLanguageCode)}: ${remaining.toStringAsFixed(2)} ${'tracking_distance_remaining'.tr(locService.currentLanguageCode)}';
      } else {
        return 'tracking_objective_reached'.tr(locService.currentLanguageCode);
      }
    } else if (widget.objective?.targetDuration != null) {
      final remaining = widget.objective!.targetDuration!.inSeconds - _session.duration.inSeconds;
      if (remaining > 0) {
        return '${'tracking_objective_time_remaining'.tr(locService.currentLanguageCode)}: ${_formatDuration(Duration(seconds: remaining))} ${'tracking_time_remaining'.tr(locService.currentLanguageCode)}';
      } else {
        return 'tracking_objective_reached'.tr(locService.currentLanguageCode);
      }
    }
    return '';
  }

  /// Retourne la couleur de l'indicateur selon le mode de tracking actif
  Color _getTrackingModeColor() {
    if (_usePedometer && _pedometerAvailable) {
      return Colors.blue; // Pedometer = bleu (le plus précis)
    } else if (_useGPS && _gpsPermissionGranted) {
      return Colors.green; // GPS = vert (précis)
    } else {
      return Colors.orange; // Simulation = orange (estimation)
    }
  }

  /// Retourne l'icône de l'indicateur selon le mode de tracking actif
  IconData _getTrackingModeIcon() {
    if (_usePedometer && _pedometerAvailable) {
      return LucideIcons.footprints; // Pedometer = empreintes
    } else if (_useGPS && _gpsPermissionGranted) {
      return LucideIcons.satellite; // GPS = satellite
    } else {
      return LucideIcons.wifiOff; // Simulation = pas de signal
    }
  }

  /// Retourne le label de l'indicateur selon le mode de tracking actif
  String _getTrackingModeLabel() {
    if (_usePedometer && _pedometerAvailable) {
      return 'STEPS'; // Pedometer
    } else if (_useGPS && _gpsPermissionGranted) {
      return 'GPS'; // GPS
    } else {
      return 'SIMU'; // Simulation
    }
  }
} 
