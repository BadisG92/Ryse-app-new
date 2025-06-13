import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/cardio_session_models.dart';

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
  final Random _random = Random(); // Pour simuler les données

  @override
  void initState() {
    super.initState();
    _initializeSession();
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
    super.dispose();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Simuler l'augmentation du temps
        _session = _session.copyWith(
          duration: Duration(seconds: _session.duration.inSeconds + 1),
        );

        // Simuler l'augmentation de distance et pas (selon l'activité)
        double speedIncrement;
        int stepsIncrement = 0;
        
        switch (widget.activityType) {
          case 'running':
            speedIncrement = _random.nextDouble() * 0.003 + 0.002; // ~8-12 km/h
            break;
          case 'bike':
            speedIncrement = _random.nextDouble() * 0.005 + 0.004; // ~15-25 km/h
            break;
          case 'walking':
            speedIncrement = _random.nextDouble() * 0.001 + 0.001; // ~4-6 km/h
            stepsIncrement = _random.nextInt(3) + 1; // 1-3 pas par seconde
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

  void _pauseTracking() {
    _timer?.cancel();
    setState(() {
      _session = _session.copyWith(isRunning: false, isPaused: true);
    });
  }

  void _resumeTracking() {
    _startTracking();
  }

  void _stopTracking() {
    _timer?.cancel();
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
        title: const Row(
          children: [
            Icon(LucideIcons.trophy, color: Color(0xFFFFB000)),
            SizedBox(width: 8),
            Text('Objectif atteint !'),
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
                Text(
                  'Séance terminée !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Excellent travail ! Voici le résumé de votre séance.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
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
                            child: _buildSummaryMetric(
                              'Durée',
                              _formatDuration(_session.duration),
                              LucideIcons.clock,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildSummaryMetric(
                              'Distance',
                              '${_session.distance.toStringAsFixed(2)} km',
                              LucideIcons.mapPin,
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
                                ? _buildSummaryMetric(
                                    'Pas',
                                    '${_session.steps}',
                                    LucideIcons.footprints,
                                  )
                                : _buildSummaryMetric(
                                    'Vitesse moy.',
                                    '${_session.averageSpeed.toStringAsFixed(1)} km/h',
                                    LucideIcons.gauge,
                                  ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildSummaryMetric(
                              'Calories',
                              '${_session.calories} kcal',
                              LucideIcons.flame,
                            ),
                          ),
                        ],
                      ),
                      
                      // Métrique supplémentaire pour la marche
                      if (widget.activityType == 'walking') ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                        _buildSummaryMetric(
                          'Pas par minute',
                          '${_session.calculateStepsPerMinute().toStringAsFixed(0)}',
                          LucideIcons.activity,
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
                    onPressed: () {
                      Navigator.pop(context); // Fermer dialog
                      Navigator.pop(context); // Retourner au cardio
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Terminer la séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
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
                      Text(
                        widget.activityTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
                            const Text(
                              'DURÉE',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                letterSpacing: 1,
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetric(
                                'Distance',
                                '${_session.distance.toStringAsFixed(2)} km',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              // Affichage différent selon l'activité
                              widget.activityType == 'walking'
                                  ? _buildMetric(
                                      'Pas',
                                      '${_session.steps}',
                                    )
                                  : _buildMetric(
                                      'Vitesse',
                                      '${_session.currentSpeed.toStringAsFixed(1)} km/h',
                                    ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Affichage différent selon l'activité
                              widget.activityType == 'walking'
                                  ? _buildMetric(
                                      'Pas/min',
                                      '${_session.calculateStepsPerMinute().toStringAsFixed(0)}',
                                    )
                                  : _buildMetric(
                                      'Moy.',
                                      '${_session.averageSpeed.toStringAsFixed(1)} km/h',
                                    ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              _buildMetric(
                                'Calories',
                                '${_session.calories} kcal',
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

                  // Bouton stop
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
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
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

  String _getObjectiveText() {
    if (widget.objective?.targetDistance != null) {
      final remaining = widget.objective!.targetDistance! - _session.distance;
      if (remaining > 0) {
        return 'Objectif: ${remaining.toStringAsFixed(2)} km restants';
      } else {
        return 'Objectif atteint !';
      }
    } else if (widget.objective?.targetDuration != null) {
      final remaining = widget.objective!.targetDuration!.inSeconds - _session.duration.inSeconds;
      if (remaining > 0) {
        return 'Objectif: ${_formatDuration(Duration(seconds: remaining))} restants';
      } else {
        return 'Objectif atteint !';
      }
    }
    return '';
  }
} 
