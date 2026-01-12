import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../models/sport_models.dart';
import '../../models/cardio_session_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../screens/workout_session_screen.dart';
import '../../screens/cardio_tracking_screen.dart';

/// Bottom sheet avec PageView pour naviguer entre les activités d'un jour
class DayActivitiesPagerSheet extends StatefulWidget {
  final DateTime date;
  final DayPlanData dayPlan;
  final int initialIndex;
  final VoidCallback onActivityChanged;

  const DayActivitiesPagerSheet({
    super.key,
    required this.date,
    required this.dayPlan,
    required this.initialIndex,
    required this.onActivityChanged,
  });

  @override
  State<DayActivitiesPagerSheet> createState() => _DayActivitiesPagerSheetState();
}

class _DayActivitiesPagerSheetState extends State<DayActivitiesPagerSheet> {
  late PageController _pageController;
  late int _currentIndex;
  late List<_ActivityItem> _activities;

  @override
  void initState() {
    super.initState();
    _activities = _buildActivityList();
    _currentIndex = widget.initialIndex.clamp(0, _activities.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_ActivityItem> _buildActivityList() {
    final List<_ActivityItem> items = [];

    // Ajouter les workouts
    for (final workout in widget.dayPlan.workouts) {
      items.add(_ActivityItem(workout: workout));
    }

    // Ajouter les cardios
    for (final cardio in widget.dayPlan.cardios) {
      items.add(_ActivityItem(activity: cardio));
    }

    // Ajouter les repas
    for (final meal in widget.dayPlan.meals) {
      items.add(_ActivityItem(activity: meal));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Indicateur de page (si plusieurs activités)
            if (_activities.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flèche gauche
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      icon: Icon(
                        LucideIcons.chevronLeft,
                        color: _currentIndex > 0
                            ? const Color(0xFF0B132B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    // Dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_activities.length, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex
                                ? const Color(0xFF0B132B)
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }),
                    ),
                    // Flèche droite
                    IconButton(
                      onPressed: _currentIndex < _activities.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: _currentIndex < _activities.length - 1
                            ? const Color(0xFF0B132B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),

            // PageView pour swipe
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _activities.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _activities[index];
                  if (item.workout != null) {
                    return _buildWorkoutPage(context, langCode, item.workout!);
                  } else if (item.activity != null) {
                    if (item.activity!.activityType == PlannedActivityType.cardio) {
                      return _buildCardioPage(context, langCode, item.activity!);
                    } else {
                      return _buildMealPage(context, langCode, item.activity!);
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WORKOUT PAGE ====================
  Widget _buildWorkoutPage(BuildContext context, String langCode, PlannedWorkout workout) {
    final isEditable = isDateEditable(workout.plannedDate);
    final isTodayWorkout = isToday(workout.plannedDate);
    final isCompleted = workout.status == PlannedStatus.completed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildWorkoutHeader(context, langCode, workout, isCompleted),
          const SizedBox(height: 16),

          // Stats
          _buildWorkoutStats(langCode, workout),
          const SizedBox(height: 16),

          // Exercices
          if (workout.exercises.isNotEmpty) ...[
            Text(
              'planner_exercises_list'.tr(langCode),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            ...workout.exercises.asMap().entries.map((entry) {
              return _buildExerciseItem(entry.value, entry.key + 1, langCode);
            }),
          ],

          // Actions
          if (isEditable && !isCompleted) ...[
            const SizedBox(height: 16),
            _buildWorkoutActions(context, langCode, workout, isTodayWorkout),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutHeader(BuildContext context, String langCode, PlannedWorkout workout, bool isCompleted) {
    return Row(
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
            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF0B132B),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
      ],
    );
  }

  Widget _buildWorkoutStats(String langCode, PlannedWorkout workout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(LucideIcons.clock, '${workout.durationMinutes ?? 45}', 'min')),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          Expanded(child: _buildStatItem(LucideIcons.dumbbell, '${workout.totalExercises}', 'planner_exercises'.tr(langCode))),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          Expanded(child: _buildStatItem(LucideIcons.repeat, '${workout.totalSets}', 'planner_sets'.tr(langCode))),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B132B))),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
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
              child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B132B))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exercise.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B132B))),
                Text(detailsText, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutActions(BuildContext context, String langCode, PlannedWorkout workout, bool canStart) {
    return Row(
      children: [
        Expanded(
          flex: canStart ? 1 : 2,
          child: OutlinedButton.icon(
            onPressed: () => _deleteWorkout(context, langCode, workout),
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text('planner_delete'.tr(langCode)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (canStart) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _startWorkout(context, workout),
              icon: const Icon(LucideIcons.play, size: 18),
              label: Text('planner_start_workout'.tr(langCode)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== CARDIO PAGE ====================
  Widget _buildCardioPage(BuildContext context, String langCode, PlannedActivity activity) {
    final isEditable = isDateEditable(activity.plannedDate);
    final isTodayCardio = isToday(activity.plannedDate);
    final isCompleted = activity.status == PlannedStatus.completed;
    final cardioData = activity.cardioData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardioHeader(context, langCode, activity, cardioData, isCompleted),
          const SizedBox(height: 16),
          if (cardioData != null) _buildCardioObjectives(langCode, cardioData),
          if (isEditable && !isCompleted) ...[
            const SizedBox(height: 16),
            _buildCardioActions(context, langCode, activity, cardioData, isTodayCardio),
          ],
        ],
      ),
    );
  }

  Widget _buildCardioHeader(BuildContext context, String langCode, PlannedActivity activity, PlannedCardioData? cardioData, bool isCompleted) {
    final activityName = cardioData?.activityName ?? 'Cardio';
    final activityIcon = _getActivityIcon(cardioData?.activityKey ?? '');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? LucideIcons.circleCheck : activityIcon,
            size: 24,
            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activityName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B132B))),
              Text(_formatDate(activity.plannedDate, langCode), style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
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
                Text('planner_completed'.tr(langCode), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardioObjectives(String langCode, PlannedCardioData cardioData) {
    final hasDistance = cardioData.targetKm != null && cardioData.targetKm! > 0;
    final hasTime = cardioData.targetMinutes != null && cardioData.targetMinutes! > 0;

    if (!hasDistance && !hasTime) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('planner_objectives'.tr(langCode), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasTime)
                Expanded(child: _buildObjectiveItem(LucideIcons.clock, '${cardioData.targetMinutes}', 'min', const Color(0xFF3B82F6))),
              if (hasTime && hasDistance)
                Container(width: 1, height: 50, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFE2E8F0)),
              if (hasDistance)
                Expanded(child: _buildObjectiveItem(LucideIcons.mapPin, cardioData.targetKm!.toStringAsFixed(1), 'km', const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B132B))),
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  Widget _buildCardioActions(BuildContext context, String langCode, PlannedActivity activity, PlannedCardioData? cardioData, bool canStart) {
    return Row(
      children: [
        Expanded(
          flex: canStart ? 1 : 2,
          child: OutlinedButton.icon(
            onPressed: () => _deleteCardio(context, langCode, activity),
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text('planner_delete'.tr(langCode)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (canStart) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _startCardio(context, cardioData),
              icon: const Icon(LucideIcons.play, size: 18),
              label: Text('planner_start_cardio'.tr(langCode)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== MEAL PAGE ====================
  Widget _buildMealPage(BuildContext context, String langCode, PlannedActivity activity) {
    final isCompleted = activity.status == PlannedStatus.completed;
    final mealName = _getMealName(activity.activityType, langCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : activity.activityType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.circleCheck : activity.activityType.icon,
                  size: 24,
                  color: isCompleted ? const Color(0xFF10B981) : activity.activityType.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B132B))),
                    Text(_formatDate(activity.plannedDate, langCode), style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
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
                      Text('planner_completed'.tr(langCode), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'planner_meal_planned'.tr(langCode),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  String _getMealName(PlannedActivityType type, String langCode) {
    switch (type) {
      case PlannedActivityType.breakfast:
        return langCode == 'fr' ? 'Petit-déjeuner' : 'Breakfast';
      case PlannedActivityType.lunch:
        return langCode == 'fr' ? 'Déjeuner' : 'Lunch';
      case PlannedActivityType.dinner:
        return langCode == 'fr' ? 'Dîner' : 'Dinner';
      case PlannedActivityType.snack:
        return langCode == 'fr' ? 'Collation' : 'Snack';
      default:
        return langCode == 'fr' ? 'Repas' : 'Meal';
    }
  }

  IconData _getActivityIcon(String activityKey) {
    switch (activityKey.toLowerCase()) {
      case 'running':
      case 'course':
        return LucideIcons.footprints;
      case 'bike':
      case 'vélo':
      case 'cycling':
        return LucideIcons.bike;
      case 'walking':
      case 'marche':
        return LucideIcons.footprints;
      case 'swimming':
      case 'natation':
        return LucideIcons.waves;
      case 'hiit':
        return LucideIcons.zap;
      default:
        return LucideIcons.activity;
    }
  }

  String _formatDate(DateTime date, String langCode) {
    final dayNames = {
      'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    };
    final days = dayNames[langCode] ?? dayNames['en']!;
    return '${days[date.weekday - 1]} ${date.day}/${date.month}';
  }

  Future<void> _deleteWorkout(BuildContext context, String langCode, PlannedWorkout workout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('planner_delete_workout_title'.tr(langCode)),
        content: Text('planner_delete_workout_message'.tr(langCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('planner_cancel'.tr(langCode))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text('planner_delete'.tr(langCode)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await WeeklyPlannerService.deleteWorkoutWithSync(workout.id);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onActivityChanged();
      }
    }
  }

  Future<void> _deleteCardio(BuildContext context, String langCode, PlannedActivity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('planner_delete_cardio_title'.tr(langCode)),
        content: Text('planner_delete_cardio_message'.tr(langCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('planner_cancel'.tr(langCode))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: Text('planner_delete'.tr(langCode)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await WeeklyPlannerService.deleteCardioWithSync(activity.id);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onActivityChanged();
      }
    }
  }

  void _startWorkout(BuildContext context, PlannedWorkout workout) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          sessionName: workout.workoutName,
          exercises: workout.exercises,
          isFromProgram: false,
          isFromAI: workout.isAiGenerated,
          plannedWorkoutId: workout.id,
        ),
      ),
    ).then((_) => widget.onActivityChanged());
  }

  void _startCardio(BuildContext context, PlannedCardioData? cardioData) {
    final activityKey = cardioData?.activityKey ?? 'running';
    final activityName = cardioData?.activityName ?? 'Running';

    CardioObjective? objective;
    if (cardioData != null) {
      if (cardioData.targetKm != null && cardioData.targetKm! > 0) {
        objective = CardioObjective(
          type: 'distance',
          targetDistance: cardioData.targetKm,
          activityType: activityKey,
          formatTitle: '$activityName (${cardioData.targetKm} km)',
        );
      } else if (cardioData.targetMinutes != null && cardioData.targetMinutes! > 0) {
        objective = CardioObjective(
          type: 'duration',
          targetDuration: Duration(minutes: cardioData.targetMinutes!),
          activityType: activityKey,
          formatTitle: '$activityName (${cardioData.targetMinutes} min)',
        );
      }
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioTrackingScreen(
          activityType: activityKey,
          activityTitle: activityName,
          formatTitle: activityName,
          objective: objective,
        ),
      ),
    ).then((_) => widget.onActivityChanged());
  }
}

class _ActivityItem {
  final PlannedWorkout? workout;
  final PlannedActivity? activity;

  _ActivityItem({this.workout, this.activity});
}
