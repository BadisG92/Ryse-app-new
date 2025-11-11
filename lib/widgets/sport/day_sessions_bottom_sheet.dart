import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/sport_dashboard_service.dart';
import '../../services/cardio_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../screens/workout_edit_screen.dart';
import '../../models/sport_models.dart';

/// Bottom sheet qui affiche les séances d'un jour spécifique avec option de suppression
class DaySessionsBottomSheet extends StatefulWidget {
  final String date; // Format: YYYY-MM-DD
  final String displayDate; // Format: "Lundi 15"
  final VoidCallback onSessionDeleted; // Callback pour rafraîchir après suppression

  const DaySessionsBottomSheet({
    super.key,
    required this.date,
    required this.displayDate,
    required this.onSessionDeleted,
  });

  @override
  State<DaySessionsBottomSheet> createState() => _DaySessionsBottomSheetState();
}

class _DaySessionsBottomSheetState extends State<DaySessionsBottomSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _cardioSessions = [];
  List<Map<String, dynamic>> _musculationSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
    });

    try {
      final sessions = await SportDashboardService.getDaySessionDetails(widget.date);
      setState(() {
        _cardioSessions = List<Map<String, dynamic>>.from(sessions['cardio'] ?? []);
        _musculationSessions = List<Map<String, dynamic>>.from(sessions['musculation'] ?? []);
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des séances: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _deleteCardioSession(String sessionId, int index) async {
    try {
      // Afficher confirmation
      final confirmed = await _showDeleteConfirmation();
      if (!confirmed) return;

      // Supprimer la séance
      await CardioService.deleteCardioSession(sessionId);

      // Mettre à jour la liste
      setState(() {
        _cardioSessions.removeAt(index);
      });

      // Notifier le parent
      widget.onSessionDeleted();

      // Afficher message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'delete_session_success'.tr(locService.currentLanguageCode),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression cardio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'delete_session_error'.tr(locService.currentLanguageCode),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editMusculationSession(String sessionId) async {
    try {
      // Charger les détails de la séance
      final sessionDetails = await SportDashboardService.getMusculationSessionDetails(sessionId);

      if (!mounted) return;

      // Convertir en format WorkoutExercise pour le screen
      final exercises = _convertToWorkoutExercises(sessionDetails['exercises'] as Map<String, List<Map<String, dynamic>>>);

      // Ouvrir le screen d'édition
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutEditScreen(
            sessionId: sessionId,
            historySessionId: sessionDetails['history_session_id'],
            sessionName: sessionDetails['session_name'],
            exercises: exercises,
            durationMinutes: sessionDetails['duration_minutes'] ?? 0,
            intensity: sessionDetails['intensity'],
            sessionDate: sessionDetails['session_date'],
          ),
        ),
      );

      // Si la séance a été modifiée, recharger
      if (result == true && mounted) {
        await _loadSessions();
        widget.onSessionDeleted(); // Réutiliser le callback pour rafraîchir
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'édition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement de la séance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<WorkoutExercise> _convertToWorkoutExercises(Map<String, List<Map<String, dynamic>>> exerciseGroups) {
    final List<WorkoutExercise> workoutExercises = [];

    for (final entry in exerciseGroups.entries) {
      final exerciseName = entry.key;
      final sets = entry.value;

      // Créer les sets
      final exerciseSets = sets.map((set) {
        return ExerciseSet(
          reps: set['reps'] as int,
          weight: (set['weight'] as num).toDouble(),
          isCompleted: true, // En mode édition, tous les sets sont déjà complétés
        );
      }).toList();

      // Créer l'exercice
      final exercise = Exercise(
        id: exerciseName, // On utilise le nom comme ID
        name: exerciseName,
        muscleGroup: '', // Pas nécessaire pour l'édition
        equipment: '',
        description: '',
        isCustom: false,
      );

      workoutExercises.add(WorkoutExercise(
        exercise: exercise,
        sets: exerciseSets,
      ));
    }

    return workoutExercises;
  }

  Future<void> _deleteMusculationSession(String sessionId, int index) async {
    try {
      // Afficher confirmation
      final confirmed = await _showDeleteConfirmation();
      if (!confirmed) return;

      // Supprimer la séance
      await SportDashboardService.deleteMusculationSession(sessionId);

      // Mettre à jour la liste
      setState(() {
        _musculationSessions.removeAt(index);
      });

      // Notifier le parent
      widget.onSessionDeleted();

      // Afficher message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'delete_session_success'.tr(locService.currentLanguageCode),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression musculation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'delete_session_error'.tr(locService.currentLanguageCode),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, locService, _) => AlertDialog(
          title: Text('delete_session'.tr(locService.currentLanguageCode)),
          content: Text('delete_session_confirm'.tr(locService.currentLanguageCode)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'cancel'.tr(locService.currentLanguageCode),
                style: const TextStyle(color: Color(0xFF888888)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'delete'.tr(locService.currentLanguageCode),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  String _formatDuration(int? seconds, int? minutes) {
    if (minutes != null && minutes > 0) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (hours > 0) {
        return remainingMinutes > 0 ? '${hours}h${remainingMinutes}min' : '${hours}h';
      }
      return '${minutes}min';
    }
    if (seconds != null && seconds > 0) {
      final totalMinutes = seconds ~/ 60;
      if (totalMinutes >= 60) {
        final hours = totalMinutes ~/ 60;
        final remainingMinutes = totalMinutes % 60;
        return remainingMinutes > 0 ? '${hours}h${remainingMinutes}min' : '${hours}h';
      }
      return '${totalMinutes}min';
    }
    return '0min';
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = _cardioSessions.length + _musculationSessions.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.displayDate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    '$totalSessions ${'sport_sessions'.tr(locService.currentLanguageCode).toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contenu
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0B132B),
                ),
              ),
            )
          else if (totalSessions == 0)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'no_sessions_this_day'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sessions de musculation
                    if (_musculationSessions.isNotEmpty) ...[
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'sport_muscle_training'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_musculationSessions.length, (index) {
                        final session = _musculationSessions[index];
                        return _buildSessionCard(
                          icon: LucideIcons.dumbbell,
                          title: session['session_name'] ?? 'Musculation',
                          duration: _formatDuration(null, session['duration_minutes']),
                          calories: session['calories_burned'] ?? 0,
                          color: const Color(0xFF0B132B),
                          onEdit: () => _editMusculationSession(session['id']),
                          onDelete: () => _deleteMusculationSession(session['id'], index),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Sessions cardio
                    if (_cardioSessions.isNotEmpty) ...[
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'sport_cardio'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_cardioSessions.length, (index) {
                        final session = _cardioSessions[index];
                        return _buildSessionCard(
                          icon: LucideIcons.activity,
                          title: session['activity_title'] ?? session['format_title'] ?? 'Cardio',
                          duration: _formatDuration(session['duration_seconds'], null),
                          calories: session['calories'] ?? 0,
                          color: const Color(0xFF1C2951),
                          distance: session['distance_km'] != null ? (session['distance_km'] as num).toDouble() : null,
                          intensity: session['intensity'],
                          onDelete: () => _deleteCardioSession(session['id'], index),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({
    required IconData icon,
    required String title,
    required String duration,
    required int calories,
    required Color color,
    double? distance,
    String? intensity,
    required VoidCallback onDelete,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    Text(
                      '$calories kcal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (distance != null && distance > 0) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      Text(
                        '${distance.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ] else if (intensity != null && intensity.isNotEmpty) ...[
                      // Afficher l'intensité si pas de distance
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      Text(
                        intensity,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Bouton modifier (si disponible)
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),

          // Bouton supprimer
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                LucideIcons.x,
                size: 16,
                color: Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
