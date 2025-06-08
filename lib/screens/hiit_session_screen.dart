import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/hiit_models.dart';

class HiitSessionScreen extends StatefulWidget {
  final HiitWorkout workout;
  final bool isFromCustomConfig; // Indique si on vient de la config personnalisée

  const HiitSessionScreen({
    super.key,
    required this.workout,
    this.isFromCustomConfig = false,
  });

  @override
  State<HiitSessionScreen> createState() => _HiitSessionScreenState();
}

class _HiitSessionScreenState extends State<HiitSessionScreen> {
  late HiitSession _session;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  void _initializeSession() {
    _session = HiitSession(
      workout: widget.workout,
      startTime: DateTime.now(),
      currentPhase: HiitPhase.work,
      currentRound: 1,
      phaseTimeRemaining: widget.workout.workDuration,
      totalTimeRemaining: widget.workout.totalDuration * 60,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_session.phaseTimeRemaining > 0) {
          _session.phaseTimeRemaining--;
          _session.totalTimeRemaining--;
        } else {
          _nextPhase();
        }
      });
    });

    setState(() {
      _session = _session.copyWith(isRunning: true, isPaused: false);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _session = _session.copyWith(isRunning: false, isPaused: true);
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopSession() {
    _timer?.cancel();
    
    // Si la session n'est pas terminée, afficher le résumé partiel
    if (_session.currentPhase != HiitPhase.finished) {
      _showSessionSummary();
    } else {
      // Session complètement terminée, fermer directement
      _exitSession();
    }
  }

  void _exitSession() {
    // Fermer la session HIIT
    Navigator.pop(context);
    
    // Si on vient de la config personnalisée, fermer aussi cet écran
    if (widget.isFromCustomConfig) {
      Navigator.pop(context);
    }
  }

  void _showSessionSummary() {
    // Calculer les métriques de la session
    final totalRoundsObjective = _session.workout.totalRounds;
    final roundsCompleted = _session.currentRound - 1; // Rounds complètement terminés
    final workoutDurationObjective = _session.workout.totalDuration;
    final actualDuration = workoutDurationObjective - _session.totalTimeRemaining;
    final completionPercentage = (actualDuration / workoutDurationObjective * 100).round();
    
    // Calculer les calories dépensées (environ 12 calories par minute d'effort HIIT)
    final caloriesBurned = (actualDuration / 60 * 12).round();
    
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
                // Icône selon le résultat
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: completionPercentage >= 50 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completionPercentage >= 50 ? LucideIcons.checkCircle : LucideIcons.clock,
                    size: 32,
                    color: completionPercentage >= 50 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Titre selon le résultat
                Text(
                  completionPercentage >= 50 ? 'Bonne séance !' : 'Séance interrompue',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  completionPercentage >= 50 
                      ? 'Vous avez réalisé une bonne partie de l\'objectif !'
                      : 'Pas de problème, chaque effort compte !',
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
                              'Temps réalisé',
                              _formatTime(actualDuration),
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
                              'Objectif',
                              _formatTime(workoutDurationObjective),
                              LucideIcons.target,
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
                            child: _buildSummaryMetric(
                              'Séries complètes',
                              '$roundsCompleted/$totalRoundsObjective',
                              LucideIcons.repeat,
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
                               '$caloriesBurned kcal',
                               LucideIcons.flame,
                             ),
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                                 // Bouton de validation
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () {
                       Navigator.pop(context); // Fermer le dialog
                       _exitSession(); // Puis fermer la session HIIT
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
                       'Terminer',
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

  void _nextPhase() {
    if (_session.currentPhase == HiitPhase.work) {
      // Passer au repos
      setState(() {
        _session = _session.copyWith(
          currentPhase: HiitPhase.rest,
          phaseTimeRemaining: _session.workout.restDuration,
        );
      });
    } else if (_session.currentPhase == HiitPhase.rest) {
      // Passer au prochain round ou terminer
      if (_session.currentRound < _session.workout.totalRounds) {
        setState(() {
          _session = _session.copyWith(
            currentPhase: HiitPhase.work,
            currentRound: _session.currentRound + 1,
            phaseTimeRemaining: _session.workout.workDuration,
          );
        });
      } else {
        // Session terminée
        _timer?.cancel();
        setState(() {
          _session = _session.copyWith(
            currentPhase: HiitPhase.finished,
            isRunning: false,
          );
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  Color _getPhaseColor() {
    switch (_session.currentPhase) {
      case HiitPhase.work:
        return const Color(0xFFDC2626); // Rouge pour l'effort
      case HiitPhase.rest:
        return const Color(0xFF059669); // Vert pour le repos
      case HiitPhase.finished:
        return const Color(0xFF0B132B); // Bleu pour terminé
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getPhaseText() {
    switch (_session.currentPhase) {
      case HiitPhase.work:
        return 'EFFORT';
      case HiitPhase.rest:
        return 'REPOS';
      case HiitPhase.finished:
        return 'TERMINÉ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getPhaseColor(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header avec titre et bouton fermer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.workout.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _stopSession,
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Phase actuelle
              Text(
                _getPhaseText(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              // Temps restant de la phase
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
                  child: Text(
                    _session.phaseTimeRemaining.toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Informations de session
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
                        _buildInfoItem(
                          'Série',
                          '${_session.currentRound}/${_session.workout.totalRounds}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildInfoItem(
                          'Temps total',
                          _formatTime(_session.totalTimeRemaining),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoItem(
                          'Effort',
                          '${_session.workout.workDuration}s',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildInfoItem(
                          'Repos',
                          '${_session.workout.restDuration}s',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Boutons de contrôle
              if (_session.currentPhase != HiitPhase.finished) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bouton pause/play
                    if (!_session.isRunning && !_session.isPaused)
                      _buildControlButton(
                        icon: LucideIcons.play,
                        onPressed: _startTimer,
                        isPrimary: true,
                      )
                    else if (_session.isRunning)
                      _buildControlButton(
                        icon: LucideIcons.pause,
                        onPressed: _pauseTimer,
                        isPrimary: true,
                      )
                    else
                      _buildControlButton(
                        icon: LucideIcons.play,
                        onPressed: _resumeTimer,
                        isPrimary: true,
                      ),

                    // Bouton stop
                    _buildControlButton(
                      icon: LucideIcons.square,
                      onPressed: _stopSession,
                      isPrimary: false,
                    ),
                  ],
                ),
              ] else ...[
                // Session terminée
                Column(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bravo !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Séance terminée avec succès',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _exitSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getPhaseColor(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terminer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
          color: isPrimary ? _getPhaseColor() : Colors.white,
          size: 28,
        ),
      ),
    );
  }
} 