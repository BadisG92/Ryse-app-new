import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../models/sport_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../screens/workout_session_screen.dart';

/// Bottom sheet pour afficher le récapitulatif d'un workout planifié
/// Peut aussi être utilisé en mode preview (sans actions ni handle bar)
class WorkoutRecapBottomSheet extends StatelessWidget {
  final PlannedWorkout workout;
  final VoidCallback? onWorkoutStarted;
  final VoidCallback? onWorkoutDeleted;
  final bool isPreview; // Mode preview: sans actions, handle bar, ni bouton close

  const WorkoutRecapBottomSheet({
    super.key,
    required this.workout,
    this.onWorkoutStarted,
    this.onWorkoutDeleted,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;
    final isEditable = isDateEditable(workout.plannedDate);
    final isTodayWorkout = isToday(workout.plannedDate);
    final isCompleted = workout.status == PlannedStatus.completed;

    // En mode preview, tout le contenu est scrollable (pas de fond blanc, le parent gère)
    if (isPreview) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderPreview(context, langCode, isCompleted),
            _buildStatsPreview(langCode),
            _buildExercisesListPreview(langCode),
          ],
        ),
      );
    }

    // Mode normal (bottom sheet modal)
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            _buildHeader(context, langCode, isCompleted),

            // Stats
            _buildStats(langCode),

            // Liste des exercices
            _buildExercisesList(langCode),

            // Boutons d'action
            if (isEditable && !isCompleted) _buildActions(context, langCode, isTodayWorkout),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String langCode, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFF0B132B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? LucideIcons.circleCheck : LucideIcons.dumbbell,
              size: 24,
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  _formatDate(workout.plannedDate, langCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'planner_completed'.tr(langCode),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          // Bouton close (masqué en mode preview)
          if (!isPreview)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  /// Header pour le mode preview (sans date, sans bouton close)
  Widget _buildHeaderPreview(BuildContext context, String langCode, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.dumbbell,
              size: 20,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              workout.workoutName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(String langCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: LucideIcons.clock,
                value: '${workout.durationMinutes ?? 45}',
                label: 'min',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: _buildStatItem(
                icon: LucideIcons.dumbbell,
                value: '${workout.totalExercises}',
                label: 'planner_exercises'.tr(langCode),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: _buildStatItem(
                icon: LucideIcons.repeat,
                value: '${workout.totalSets}',
                label: 'planner_sets'.tr(langCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stats pour le mode preview (padding réduit)
  Widget _buildStatsPreview(String langCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItemCompact(
                icon: LucideIcons.clock,
                value: '${workout.durationMinutes ?? 45}',
                label: 'min',
              ),
            ),
            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
            Expanded(
              child: _buildStatItemCompact(
                icon: LucideIcons.dumbbell,
                value: '${workout.totalExercises}',
                label: 'exos',
              ),
            ),
            Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
            Expanded(
              child: _buildStatItemCompact(
                icon: LucideIcons.repeat,
                value: '${workout.totalSets}',
                label: 'séries',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemCompact({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
        ),
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

  Widget _buildExercisesList(String langCode) {
    if (workout.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'planner_exercises_list'.tr(langCode),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workout.exercises.length,
              itemBuilder: (context, index) {
                final exercise = workout.exercises[index];
                return _buildExerciseItem(exercise, index + 1, langCode);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Version preview: pas de contrainte de hauteur (parent scrollable)
  Widget _buildExercisesListPreview(String langCode) {
    if (workout.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'planner_exercises_list'.tr(langCode),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          // Pas de ListView, juste une Column car le parent est scrollable
          ...workout.exercises.asMap().entries.map((entry) {
            return _buildExerciseItem(entry.value, entry.key + 1, langCode);
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutExercise exercise, int index, String langCode) {
    final repsRange = '${exercise.suggestedRepsMin ?? 8}-${exercise.suggestedRepsMax ?? 12}';
    final detailsText = 'planner_exercise_details'.tr(langCode)
        .replaceAll('{sets}', '${exercise.sets.length}')
        .replaceAll('{reps}', repsRange);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  detailsText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, String langCode, bool canStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Bouton supprimer (toujours disponible pour les jours éditables)
          if (onWorkoutDeleted != null)
            Expanded(
              flex: canStart ? 1 : 2,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(context, langCode);
                  if (confirm == true) {
                    // Suppression bidirectionnelle: planificateur + historique si lié
                    await WeeklyPlannerService.deleteWorkoutWithSync(workout.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      onWorkoutDeleted?.call();
                    }
                  }
                },
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: Text('planner_delete'.tr(langCode)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (onWorkoutDeleted != null && canStart) const SizedBox(width: 12),

          // Bouton commencer (uniquement pour aujourd'hui)
          if (canStart)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startWorkout(context);
                },
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text('planner_start_workout'.tr(langCode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: workout.workoutName,
          exercises: workout.exercises,
          isFromProgram: false,
          isFromAI: workout.isAiGenerated,
          plannedWorkoutId: workout.id, // Lier au workout planifié pour la complétion
        ),
      ),
    ).then((_) {
      onWorkoutStarted?.call();
    });
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String langCode) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('planner_delete_workout_title'.tr(langCode)),
        content: Text('planner_delete_workout_message'.tr(langCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('planner_cancel'.tr(langCode)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text('planner_delete'.tr(langCode)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, String langCode) {
    final dayName = 'day_${date.weekday}'.tr(langCode);
    return '$dayName ${date.day}/${date.month}';
  }
}
