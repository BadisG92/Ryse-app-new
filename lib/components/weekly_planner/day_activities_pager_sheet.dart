import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../models/sport_models.dart';
import '../../models/cardio_session_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/meal_planner_sync_service.dart';
import '../../screens/workout_session_screen.dart';
import '../../screens/cardio_tracking_screen.dart';
import '../../screens/hiit_session_screen.dart';
import '../../models/hiit_models.dart';
import 'planned_meal_detail_page.dart';
import 'meal_validation_bottom_sheet.dart';
import 'day_column_widget.dart' show ActivityFilter;

/// Bottom sheet avec PageView pour naviguer entre les activités d'un jour
class DayActivitiesPagerSheet extends StatefulWidget {
  final DateTime date;
  final DayPlanData dayPlan;
  final int initialIndex;
  final VoidCallback onActivityChanged;
  final ActivityFilter filter; // Filtre pour les types d'activités à afficher

  const DayActivitiesPagerSheet({
    super.key,
    required this.date,
    required this.dayPlan,
    required this.initialIndex,
    required this.onActivityChanged,
    this.filter = ActivityFilter.all,
  });

  @override
  State<DayActivitiesPagerSheet> createState() => _DayActivitiesPagerSheetState();
}

class _DayActivitiesPagerSheetState extends State<DayActivitiesPagerSheet> {
  late PageController _pageController;
  late int _currentIndex;
  late List<_ActivityItem> _activities;
  late DayPlanData _dayPlan; // Copie locale qui peut être mise à jour

  @override
  void initState() {
    super.initState();
    _dayPlan = widget.dayPlan;
    _activities = _buildActivityList();
    _currentIndex = widget.initialIndex.clamp(0, _activities.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Rafraîchit les données du jour depuis la base de données
  Future<void> _refreshDayPlan() async {
    try {
      final weekData = await WeeklyPlannerService.getWeekData(forceRefresh: true);
      final normalizedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);

      // Récupérer le DayPlanData depuis le map
      final updatedDay = weekData.getDayPlan(normalizedDate) ?? _dayPlan;

      if (mounted) {
        setState(() {
          _dayPlan = updatedDay;
          _activities = _buildActivityList();
          // S'assurer que l'index reste valide
          if (_currentIndex >= _activities.length) {
            _currentIndex = _activities.isEmpty ? 0 : _activities.length - 1;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error refreshing day plan: $e');
    }
  }

  static const _mealTypesOrder = ['breakfast', 'lunch', 'dinner', 'snack'];

  List<_ActivityItem> _buildActivityList() {
    final List<_ActivityItem> items = [];
    final filter = widget.filter;

    // Ajouter les repas si le filtre le permet
    if (filter == ActivityFilter.all || filter == ActivityFilter.meals) {
      // Grouper les repas planifiés par type
      final mealsByType = <String, List<PlannedActivity>>{};
      for (final meal in _dayPlan.meals) {
        final type = meal.activityType.value;
        mealsByType.putIfAbsent(type, () => []);
        mealsByType[type]!.add(meal);
      }

      // Collecter les IDs des food_entries liées aux repas planifiés validés
      final linkedFoodEntryIds = <String>{};
      for (final meal in _dayPlan.meals) {
        final linkedId = meal.mealData?.linkedFoodEntryId;
        if (linkedId != null) {
          linkedFoodEntryIds.add(linkedId);
        }
      }

      // Grouper les journal entries par type NORMALISÉ
      // (snack_1, snack_2, collation 1, etc. → tous groupés sous "snack")
      // EXCLURE les entries qui sont liées à des repas planifiés (éviter doublons)
      final journalByType = <String, List<JournalFoodEntry>>{};
      for (final entry in _dayPlan.journalEntries) {
        // Skip si cette entry est liée à un repas planifié
        if (linkedFoodEntryIds.contains(entry.id)) {
          continue;
        }
        final normalizedType = _normalizeMealType(entry.mealType);
        journalByType.putIfAbsent(normalizedType, () => []);
        journalByType[normalizedType]!.add(entry);
      }

      // Créer une page par type de repas (si au moins 1 item)
      for (final mealType in _mealTypesOrder) {
        final plannedMeals = mealsByType[mealType] ?? [];
        final journalEntries = journalByType[mealType] ?? [];

        // N'ajouter la page que s'il y a au moins un item
        if (plannedMeals.isNotEmpty || journalEntries.isNotEmpty) {
          items.add(_ActivityItem(
            mealTypePage: _MealTypePage(
              mealType: mealType,
              plannedMeals: plannedMeals,
              journalEntries: journalEntries,
            ),
          ));
        }
      }
    }

    // Ajouter les cardios si le filtre le permet (pages séparées)
    if (filter == ActivityFilter.all || filter == ActivityFilter.workouts) {
      for (final cardio in _dayPlan.cardios) {
        items.add(_ActivityItem(activity: cardio));
      }

      // Ajouter les workouts (pages séparées)
      for (final workout in _dayPlan.workouts) {
        items.add(_ActivityItem(workout: workout));
      }
    }

    return items;
  }

  /// Normalise le type de repas pour regrouper les variantes
  /// Ex: "snack_1", "snack_2", "collation 1" → "snack"
  /// Ex: "breakfast_1", "petit_dejeuner" → "breakfast"
  String _normalizeMealType(String mealType) {
    final lower = mealType.toLowerCase();

    // Snack variants
    if (lower.contains('snack') || lower.contains('collation') || lower.contains('gouter') || lower.contains('goûter')) {
      return 'snack';
    }

    // Breakfast variants
    if (lower.contains('breakfast') || lower.contains('petit') || (lower.contains('dejeuner') && lower.contains('petit'))) {
      return 'breakfast';
    }

    // Lunch variants
    if (lower.contains('lunch') || (lower.contains('dejeuner') && !lower.contains('petit')) || lower.contains('déjeuner')) {
      return 'lunch';
    }

    // Dinner variants
    if (lower.contains('dinner') || lower.contains('diner') || lower.contains('dîner') || lower.contains('souper')) {
      return 'dinner';
    }

    // Default: return the base type without numbers
    // Remove trailing numbers and underscores (e.g., "snack_1" → "snack")
    final withoutNumbers = lower.replaceAll(RegExp(r'[_\s]*\d+$'), '');

    // Map to standard types
    if (_mealTypesOrder.contains(withoutNumbers)) {
      return withoutNumbers;
    }

    return 'snack'; // Default fallback
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
              height: 280,
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
                  } else if (item.mealTypePage != null) {
                    // Nouvelle page groupée par type de repas
                    return _buildMealTypePage(context, langCode, item.mealTypePage!);
                  } else if (item.activity != null) {
                    if (item.activity!.activityType == PlannedActivityType.cardio) {
                      return _buildCardioPage(context, langCode, item.activity!);
                    } else {
                      return _buildMealPage(context, langCode, item.activity!);
                    }
                  } else if (item.journalEntry != null) {
                    return _buildJournalEntryPage(context, langCode, item.journalEntry!);
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
                : const Color(0xFF0B132B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? LucideIcons.circleCheck : activityIcon,
            size: 24,
            color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF0B132B),
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
    // Si c'est un HIIT, afficher les objectifs HIIT
    if (cardioData.isHiit && cardioData.hiitConfig != null) {
      return _buildHiitObjectives(langCode, cardioData.hiitConfig!);
    }

    final hasDistance = cardioData.targetKm != null && cardioData.targetKm! > 0;
    final hasTime = cardioData.targetMinutes != null && cardioData.targetMinutes! > 0;

    if (!hasDistance && !hasTime) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (hasTime)
            Expanded(child: _buildStatItem(LucideIcons.clock, '${cardioData.targetMinutes}', 'min')),
          if (hasTime && hasDistance)
            Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          if (hasDistance)
            Expanded(child: _buildStatItem(LucideIcons.mapPin, cardioData.targetKm!.toStringAsFixed(1), 'km')),
        ],
      ),
    );
  }

  Widget _buildHiitObjectives(String langCode, HiitConfig hiitConfig) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Effort
          Expanded(
            child: _buildStatItem(
              LucideIcons.zap,
              '${hiitConfig.workSeconds}s',
              'planner_hiit_work'.tr(langCode),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          // Repos
          Expanded(
            child: _buildStatItem(
              LucideIcons.pause,
              '${hiitConfig.restSeconds}s',
              'planner_hiit_rest'.tr(langCode),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          // Rounds
          Expanded(
            child: _buildStatItem(
              LucideIcons.repeat,
              '${hiitConfig.rounds}',
              'rounds',
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          // Durée totale
          Expanded(
            child: _buildStatItem(
              LucideIcons.clock,
              '~${hiitConfig.totalMinutes}',
              'min',
            ),
          ),
        ],
      ),
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

  // ==================== MEAL TYPE PAGE (GROUPED) ====================
  /// Page groupant tous les items d'un même type de repas
  Widget _buildMealTypePage(BuildContext context, String langCode, _MealTypePage page) {
    final mealTypeName = _getMealNameFromString(page.mealType, langCode);
    final mealTypeIcon = _getMealTypeIcon(page.mealType);
    final mealTypeColor = _getMealTypeColor(page.mealType);

    // Calculer les totaux
    int totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    // Ajouter les macros des repas planifiés
    for (final meal in page.plannedMeals) {
      final mealData = meal.mealData;
      if (mealData != null) {
        final p = mealData.proteins ?? 0.0;
        final c = mealData.carbs ?? 0.0;
        final f = mealData.fats ?? 0.0;
        totalProteins += p;
        totalCarbs += c;
        totalFats += f;
        totalCalories += ((p * 4) + (c * 4) + (f * 9)).round();
      }
    }

    // Ajouter les macros des entrées journal
    for (final entry in page.journalEntries) {
      totalCalories += entry.calories;
      totalProteins += entry.proteins;
      totalCarbs += entry.carbs;
      totalFats += entry.fats;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du type de repas
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mealTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mealTypeIcon, size: 24, color: mealTypeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealTypeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      '${page.totalItems} ${'planner_items'.tr(langCode)}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bilan calorique total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildMacroItem(
                  label: 'kcal',
                  value: totalCalories.toString(),
                  color: const Color(0xFFF59E0B),
                ),
                _buildMacroDivider(),
                _buildMacroItem(
                  label: 'proteins'.tr(langCode)[0],
                  value: '${totalProteins.toInt()}g',
                  color: const Color(0xFFEF4444),
                ),
                _buildMacroDivider(),
                _buildMacroItem(
                  label: 'carbs'.tr(langCode)[0],
                  value: '${totalCarbs.toInt()}g',
                  color: const Color(0xFF3B82F6),
                ),
                _buildMacroDivider(),
                _buildMacroItem(
                  label: 'fats'.tr(langCode)[0],
                  value: '${totalFats.toInt()}g',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des repas planifiés (avec checkbox)
          ...page.plannedMeals.map((meal) => _buildPlannedMealItem(context, langCode, meal)),

          // Liste des entrées journal (sans checkbox, validées)
          ...page.journalEntries.map((entry) => _buildJournalEntryItem(context, langCode, entry)),
        ],
      ),
    );
  }

  /// Widget pour un repas planifié dans la liste groupée
  Widget _buildPlannedMealItem(BuildContext context, String langCode, PlannedActivity activity) {
    final mealData = activity.mealData;
    final dishName = mealData?.displayName ?? 'Repas planifié';
    final isValidated = MealPlannerSyncService.isMealValidated(activity);
    final canValidate = MealPlannerSyncService.canValidateMeal(activity);
    final isMissed = MealPlannerSyncService.isMealMissed(activity);

    final proteins = mealData?.proteins ?? 0.0;
    final carbs = mealData?.carbs ?? 0.0;
    final fats = mealData?.fats ?? 0.0;
    final calories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

    return GestureDetector(
      onTap: () {
        if (mealData != null) {
          _showMealDetailPage(context, langCode, activity, mealData);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isValidated
                ? const Color(0xFF10B981)
                : isMissed
                    ? const Color(0xFFEF4444).withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
            width: isValidated ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: isMissed ? 0.6 : 1.0,
          child: Row(
            children: [
              // Checkbox (si peut valider)
              if (canValidate)
                GestureDetector(
                  onTap: () => _toggleMealValidation(context, activity, isValidated),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isValidated ? const Color(0xFF10B981) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isValidated ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: isValidated
                        ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                )
              else if (isValidated)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: const Icon(LucideIcons.circleCheck, size: 24, color: Color(0xFF10B981)),
                )
              else if (isMissed)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: const Icon(LucideIcons.circleX, size: 24, color: Color(0xFFEF4444)),
                ),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dishName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isMissed ? const Color(0xFF64748B) : const Color(0xFF0B132B),
                        decoration: isMissed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$calories kcal • ${'proteins'.tr(langCode)[0]}: ${proteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${carbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${fats.toInt()}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: isMissed ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron pour voir les détails
              const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour une entrée journal dans la liste groupée (sans checkbox)
  Widget _buildJournalEntryItem(BuildContext context, String langCode, JournalFoodEntry entry) {
    return GestureDetector(
      onTap: () => _showJournalEntrySnackbar(context, langCode, entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Icône validé (toujours validé car vient du journal)
            const Icon(LucideIcons.circleCheck, size: 24, color: Color(0xFF10B981)),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                      // Tag "Journal"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'planner_journal_tag'.tr(langCode),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.quantity.toStringAsFixed(0)} ${entry.unit} • ${entry.calories} kcal • ${'proteins'.tr(langCode)[0]}: ${entry.proteins.toInt()}g | ${'carbs'.tr(langCode)[0]}: ${entry.carbs.toInt()}g | ${'fats'.tr(langCode)[0]}: ${entry.fats.toInt()}g',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir l'icône d'un type de repas (uniformisé avec les boutons d'ajout)
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return LucideIcons.sunrise;
      case 'lunch':
        return LucideIcons.sun;
      case 'dinner':
        return LucideIcons.sunset;
      case 'snack':
        return LucideIcons.milk;
      default:
        return LucideIcons.utensils;
    }
  }

  /// Obtenir la couleur d'un type de repas (bleu uniforme de l'app)
  Color _getMealTypeColor(String mealType) {
    // Couleur bleue uniforme pour tous les types de repas
    return const Color(0xFF0B132B);
  }

  // ==================== MEAL PAGE (SINGLE - LEGACY) ====================
  Widget _buildMealPage(BuildContext context, String langCode, PlannedActivity activity) {
    final mealData = activity.mealData;
    final mealName = _getMealName(activity.activityType, langCode);

    // États du repas
    final isValidated = MealPlannerSyncService.isMealValidated(activity);
    final canValidate = MealPlannerSyncService.canValidateMeal(activity);
    final isMissed = MealPlannerSyncService.isMealMissed(activity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isValidated
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : isMissed
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : activity.activityType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isValidated
                      ? LucideIcons.circleCheck
                      : isMissed
                          ? LucideIcons.circleX
                          : activity.activityType.icon,
                  size: 24,
                  color: isValidated
                      ? const Color(0xFF10B981)
                      : isMissed
                          ? const Color(0xFFEF4444)
                          : activity.activityType.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMissed ? const Color(0xFF64748B) : const Color(0xFF0B132B),
                        decoration: isMissed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      _formatDate(activity.plannedDate, langCode),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // Tag de statut
              if (isValidated)
                _buildStatusTag(langCode, 'completed')
              else if (isMissed)
                _buildStatusTag(langCode, 'missed'),
            ],
          ),
          const SizedBox(height: 24),

          // Carte du plat
          if (mealData != null) ...[
            _buildMealCard(context, langCode, activity, mealData, isValidated, canValidate, isMissed),
          ] else
            Center(
              child: Text(
                'planner_meal_planned'.tr(langCode),
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),

          // Bouton de suppression (si pas validé et pas manqué)
          if (!isValidated && !isMissed) ...[
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => _deleteMeal(context, langCode, activity),
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text('planner_delete_meal'.tr(langCode)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construire le tag de statut (Validé, Manqué)
  Widget _buildStatusTag(String langCode, String status) {
    final isCompleted = status == 'completed';
    final color = isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final text = status == 'completed'
        ? 'planner_validated'.tr(langCode)
        : 'planner_missed'.tr(langCode);
    final icon = isCompleted ? LucideIcons.check : LucideIcons.x;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  /// Construire la carte du repas avec macros et checkbox
  Widget _buildMealCard(
    BuildContext context,
    String langCode,
    PlannedActivity activity,
    PlannedMealData mealData,
    bool isValidated,
    bool canValidate,
    bool isMissed,
  ) {
    final dishName = mealData.displayName;
    // Extraire seulement la description (avant "---INGRÉDIENTS" ou "---")
    var dishDescription = mealData.displayDescription;
    if (dishDescription.contains('---')) {
      dishDescription = dishDescription.split('---').first.trim();
    }
    final proteins = mealData.proteins ?? 0.0;
    final carbs = mealData.carbs ?? 0.0;
    final fats = mealData.fats ?? 0.0;
    // Calculer les calories avec la formule standard au lieu d'utiliser la valeur stockée
    final calories = ((proteins * 4) + (carbs * 4) + (fats * 9)).round();

    return GestureDetector(
      onTap: () => _showMealDetailPage(context, langCode, activity, mealData),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValidated
              ? const Color(0xFF10B981)
              : isMissed
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
          width: isValidated ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isMissed ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec checkbox et bouton edit
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox (visible uniquement aujourd'hui)
                  if (canValidate) ...[
                    GestureDetector(
                      onTap: () => _toggleMealValidation(context, activity, isValidated),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isValidated
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isValidated
                                ? const Color(0xFF10B981)
                                : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isValidated
                            ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Nom du plat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dishName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isMissed ? const Color(0xFF64748B) : const Color(0xFF0B132B),
                            decoration: isMissed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (dishDescription.isNotEmpty)
                          Text(
                            dishDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              decoration: isMissed ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                ],
              ),
            ),

            // Ligne de séparation
            Container(
              height: 1,
              color: const Color(0xFFF1F5F9),
            ),

            // Macros
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildMacroItem(
                    label: 'kcal',
                    value: calories.toString(),
                    color: const Color(0xFFF59E0B),
                    isMissed: isMissed,
                  ),
                  _buildMacroDivider(),
                  _buildMacroItem(
                    label: 'proteins'.tr(langCode)[0], // P = Protéines/Proteins/Proteine
                    value: '${proteins.toStringAsFixed(0)}g',
                    color: const Color(0xFFEF4444),
                    isMissed: isMissed,
                  ),
                  _buildMacroDivider(),
                  _buildMacroItem(
                    label: 'carbs'.tr(langCode)[0], // G=Glucides, C=Carbs, K=Kohlenhydrate
                    value: '${carbs.toStringAsFixed(0)}g',
                    color: const Color(0xFF3B82F6),
                    isMissed: isMissed,
                  ),
                  _buildMacroDivider(),
                  _buildMacroItem(
                    label: 'fats'.tr(langCode)[0], // L=Lipides, F=Fats/Fette
                    value: '${fats.toStringAsFixed(0)}g',
                    color: const Color(0xFF10B981),
                    isMissed: isMissed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Naviguer vers la page de détails du repas
  void _showMealDetailPage(
    BuildContext context,
    String langCode,
    PlannedActivity activity,
    PlannedMealData mealData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannedMealDetailPage(
          activity: activity,
          mealData: mealData,
          langCode: langCode,
          onMealUpdated: () {
            // Rafraîchir le planner quand les macros sont mises à jour
            widget.onActivityChanged();
          },
        ),
      ),
    );
  }

  /// Widget pour un macro individuel
  Widget _buildMacroItem({
    required String label,
    required String value,
    required Color color,
    bool isMissed = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isMissed ? const Color(0xFF94A3B8) : color,
              decoration: isMissed ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMissed ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// Divider vertical entre les macros
  Widget _buildMacroDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE2E8F0),
    );
  }

  /// Toggle la validation d'un repas
  Future<void> _toggleMealValidation(BuildContext context, PlannedActivity activity, bool currentlyValidated) async {
    try {
      if (currentlyValidated) {
        // Récupérer l'activité fraîche avec le linked_food_entry_id à jour
        // (l'objet activity local peut être stale si la validation a été faite après le chargement)
        final freshActivity = await WeeklyPlannerService.getPlannedActivityById(activity.id);
        if (freshActivity != null) {
          await MealPlannerSyncService.unvalidateMeal(freshActivity);
        } else {
          // Fallback : utiliser l'activité locale si la récupération échoue
          await MealPlannerSyncService.unvalidateMeal(activity);
        }
        // Refresh les données localement (sans fermer le sheet)
        await _refreshDayPlan();
        // Aussi notifier le parent pour mettre à jour le calendrier
        widget.onActivityChanged();
      } else {
        // Valider : ouvrir le bottom sheet avec les ingrédients
        final mealData = activity.mealData;
        if (mealData == null) {
          debugPrint('❌ No meal data to validate');
          return;
        }

        final langCode = context.read<LocalizationService>().currentLanguageCode;

        // Ouvrir le bottom sheet de validation
        if (context.mounted) {
          await MealValidationBottomSheet.show(
            context: context,
            activity: activity,
            mealData: mealData,
            langCode: langCode,
            onValidated: () async {
              // Refresh les données localement (sans fermer le sheet)
              await _refreshDayPlan();
              // Aussi notifier le parent pour mettre à jour le calendrier
              widget.onActivityChanged();
            },
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Toggle meal validation error: $e');
    }
  }

  /// Supprimer un repas planifié
  Future<void> _deleteMeal(BuildContext context, String langCode, PlannedActivity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('planner_delete_meal_title'.tr(langCode)),
        content: Text('planner_delete_meal_message'.tr(langCode)),
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
    if (confirm == true && context.mounted) {
      await WeeklyPlannerService.deletePlannedActivity(activity.id);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onActivityChanged();
      }
    }
  }

  // ==================== JOURNAL ENTRY PAGE ====================
  Widget _buildJournalEntryPage(BuildContext context, String langCode, JournalFoodEntry entry) {
    final mealTypeName = _getMealNameFromString(entry.mealType, langCode);
    final normalizedMealType = _normalizeMealType(entry.mealType);
    final mealIcon = _getMealTypeIcon(normalizedMealType);
    final mealColor = _getMealTypeColor(normalizedMealType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mealColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mealIcon,
                  size: 24,
                  color: mealColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      '$mealTypeName - ${'planner_from_journal'.tr(langCode)}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // Tag "Journal"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.bookOpen, size: 14, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Text(
                      'planner_journal_tag'.tr(langCode),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Card avec les macros (style journal, sans checkbox)
          GestureDetector(
            onTap: () => _showJournalEntrySnackbar(context, langCode, entry),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantité et nom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Pas de checkbox pour les journal entries
                        const Icon(
                          LucideIcons.circleCheck,
                          size: 24,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B132B),
                                ),
                              ),
                              Text(
                                '${entry.quantity.toStringAsFixed(0)} ${entry.unit}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),

                  // Macros
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildMacroItem(
                          label: 'kcal',
                          value: entry.calories.toString(),
                          color: const Color(0xFFF59E0B),
                        ),
                        _buildMacroDivider(),
                        _buildMacroItem(
                          label: 'proteins'.tr(langCode)[0],
                          value: '${entry.proteins.toStringAsFixed(0)}g',
                          color: const Color(0xFFEF4444),
                        ),
                        _buildMacroDivider(),
                        _buildMacroItem(
                          label: 'carbs'.tr(langCode)[0],
                          value: '${entry.carbs.toStringAsFixed(0)}g',
                          color: const Color(0xFF3B82F6),
                        ),
                        _buildMacroDivider(),
                        _buildMacroItem(
                          label: 'fats'.tr(langCode)[0],
                          value: '${entry.fats.toStringAsFixed(0)}g',
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info text
          const SizedBox(height: 16),
          Center(
            child: Text(
              'planner_journal_entry_info'.tr(langCode),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Afficher un snackbar avec les détails du journal entry
  void _showJournalEntrySnackbar(BuildContext context, String langCode, JournalFoodEntry entry) {
    final proteinLabel = 'proteins'.tr(langCode)[0];
    final carbsLabel = 'carbs'.tr(langCode)[0];
    final fatsLabel = 'fats'.tr(langCode)[0];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${entry.name}: ${entry.calories} kcal | $proteinLabel: ${entry.proteins.toStringAsFixed(0)}g | $carbsLabel: ${entry.carbs.toStringAsFixed(0)}g | $fatsLabel: ${entry.fats.toStringAsFixed(0)}g',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Helper pour obtenir le nom du type de repas depuis une string
  String _getMealNameFromString(String mealType, String langCode) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'planner_breakfast'.tr(langCode);
      case 'lunch':
        return 'planner_lunch'.tr(langCode);
      case 'dinner':
        return 'planner_dinner'.tr(langCode);
      case 'snack':
        return 'planner_snack'.tr(langCode);
      default:
        return mealType;
    }
  }

  // ==================== HELPERS ====================
  String _getMealName(PlannedActivityType type, String langCode) {
    switch (type) {
      case PlannedActivityType.breakfast:
        return 'planner_breakfast'.tr(langCode);
      case PlannedActivityType.lunch:
        return 'planner_lunch'.tr(langCode);
      case PlannedActivityType.dinner:
        return 'planner_dinner'.tr(langCode);
      case PlannedActivityType.snack:
        return 'planner_snack'.tr(langCode);
      default:
        return 'planner_meal_planned'.tr(langCode);
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
    final dayName = 'day_${date.weekday}'.tr(langCode);
    return '$dayName ${date.day}/${date.month}';
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

    // Si c'est un HIIT, lancer l'écran HIIT
    if (cardioData != null && cardioData.isHiit && cardioData.hiitConfig != null) {
      _startHiit(context, cardioData);
      return;
    }

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

  void _startHiit(BuildContext context, PlannedCardioData cardioData) {
    final hiitConfig = cardioData.hiitConfig!;

    // Créer le workout HIIT avec la config stockée
    final hiitWorkout = HiitWorkout(
      id: hiitConfig.type,
      title: cardioData.activityName,
      description: '${hiitConfig.totalMinutes} min - ${hiitConfig.workSeconds}s effort / ${hiitConfig.restSeconds}s repos',
      workDuration: hiitConfig.workSeconds,
      restDuration: hiitConfig.restSeconds,
      totalDuration: hiitConfig.totalMinutes,
      totalRounds: hiitConfig.rounds,
    );

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiitSessionScreen(
          workout: hiitWorkout,
          isFromCustomConfig: hiitConfig.type == 'custom',
        ),
      ),
    ).then((_) => widget.onActivityChanged());
  }
}

class _ActivityItem {
  final PlannedWorkout? workout;
  final PlannedActivity? activity;
  final JournalFoodEntry? journalEntry;
  // Nouveau: Page groupée par type de repas
  final _MealTypePage? mealTypePage;

  _ActivityItem({this.workout, this.activity, this.journalEntry, this.mealTypePage});
}

/// Page groupant tous les items d'un même type de repas
class _MealTypePage {
  final String mealType; // breakfast, lunch, dinner, snack
  final List<PlannedActivity> plannedMeals;
  final List<JournalFoodEntry> journalEntries;

  _MealTypePage({
    required this.mealType,
    required this.plannedMeals,
    required this.journalEntries,
  });

  bool get hasItems => plannedMeals.isNotEmpty || journalEntries.isNotEmpty;
  int get totalItems => plannedMeals.length + journalEntries.length;
}
