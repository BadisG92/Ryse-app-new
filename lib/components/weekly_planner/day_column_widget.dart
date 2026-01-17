import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/weekly_planner_models.dart';
import 'activity_chip_widget.dart';
import 'day_activities_pager_sheet.dart';

/// Filtre pour les types d'activités à afficher
enum ActivityFilter {
  all,      // Afficher tout (page d'accueil)
  meals,    // Afficher seulement les repas
  workouts, // Afficher seulement les séances (workouts + cardio)
}

/// Widget représentant une colonne de jour dans le planner
class DayColumnWidget extends StatefulWidget {
  final DateTime date;
  final String dayName;
  final DayPlanData? dayPlan;
  final VoidCallback? onDataRefresh; // Callback pour recharger les données après une action
  final Function(PlannedActivity)? onActivityTap;
  final Function(PlannedWorkout)? onWorkoutTap;
  final bool isCompact; // Mode compact pour le chat (2 colonnes, petites icônes)
  final ActivityFilter filter; // Filtre pour les types d'activités
  final int dailyCalorieTarget; // Objectif calorique journalier
  final bool animateProgress; // Animer le remplissage (pour le jour actuel après génération)

  const DayColumnWidget({
    super.key,
    required this.date,
    required this.dayName,
    required this.dayPlan,
    this.onDataRefresh,
    this.onActivityTap,
    this.onWorkoutTap,
    this.isCompact = false,
    this.filter = ActivityFilter.all,
    this.dailyCalorieTarget = 2000,
    this.animateProgress = false,
  });

  @override
  State<DayColumnWidget> createState() => _DayColumnWidgetState();
}

class _DayColumnWidgetState extends State<DayColumnWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _setupAnimation();
  }

  @override
  void didUpdateWidget(DayColumnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculer l'animation si les données changent
    if (oldWidget.dayPlan != widget.dayPlan ||
        oldWidget.dailyCalorieTarget != widget.dailyCalorieTarget) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    final targetProgress = _calculateProgress();

    if (widget.animateProgress && _isToday) {
      // Animation du remplissage pour le jour actuel
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: targetProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _animationController.forward(from: 0.0).then((_) {
        // Vérifier si on a atteint 100% pour déclencher les confettis
        if (targetProgress >= 1.0 && !_hasTriggeredConfetti) {
          _hasTriggeredConfetti = true;
          _confettiController.play();
        }
      });
    } else {
      // Pas d'animation, afficher directement
      _progressAnimation = AlwaysStoppedAnimation(targetProgress);
    }

    _previousProgress = targetProgress;
  }

  bool get _isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
    return normalizedDate == today;
  }

  bool get _isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
    return normalizedDate.isBefore(today);
  }

  /// Calculer le pourcentage de progression basé sur les calories validées
  double _calculateProgress() {
    if (widget.dayPlan == null || widget.dailyCalorieTarget <= 0) return 0.0;

    int validatedCalories = 0;

    // Calories des repas planifiés validés (status = completed)
    for (final meal in widget.dayPlan!.meals) {
      if (meal.status == PlannedStatus.completed) {
        validatedCalories += meal.mealData?.calories ?? 0;
      }
    }

    // Calories des journal entries (repas non planifiés mais consommés)
    for (final entry in widget.dayPlan!.journalEntries) {
      validatedCalories += entry.calories;
    }

    // Calculer le ratio (plafonné à 1.0 - ne jamais dépasser 100%)
    final progress = validatedCalories / widget.dailyCalorieTarget;
    return progress.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isPast ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header du jour avec indicateur de progression
            _buildDayHeader(),
            const SizedBox(height: 6),
            // Activités du jour - liste verticale
            _buildActivitiesGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Container principal avec gradient pour le fill - MÊME STRUCTURE QUE L'ORIGINAL
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animatedProgress = widget.animateProgress && _isToday
                ? _progressAnimation.value
                : _calculateProgress();

            // Plafonner à 1.0 (100%)
            final clampedProgress = animatedProgress.clamp(0.0, 1.0);

            // Couleurs
            const fillColor = Color(0xFF0B132B); // Bleu foncé - toujours la même
            const backgroundColor = Color(0xFFF1F5F9); // Gris clair

            // Décoration avec gradient pour le fill progressif
            // IMPORTANT: Tous les jours ont une bordure de 2px (visible ou transparente)
            // pour maintenir un alignement parfait des éléments en-dessous
            BoxDecoration decoration;
            if (_isToday || _isPast) {
              if (clampedProgress > 0) {
                // Avec fill : gradient du bas (fill) vers le haut (fond)
                decoration = BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isToday ? const Color(0xFF0B132B) : Colors.transparent,
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [clampedProgress, clampedProgress],
                    colors: const [fillColor, backgroundColor],
                  ),
                );
              } else {
                // Sans fill : fond gris simple
                decoration = BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isToday ? const Color(0xFF0B132B) : Colors.transparent,
                    width: 2,
                  ),
                );
              }
            } else {
              // Jour futur : transparent avec bordure transparente pour l'alignement
              decoration = BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.transparent,
                  width: 2,
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: decoration,
              child: Column(
                children: [
                  Text(
                    widget.dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: clampedProgress >= 0.5
                          ? Colors.white
                          : _isToday
                              ? const Color(0xFF0B132B)
                              : _isPast
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.date.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: clampedProgress >= 0.3
                          ? Colors.white
                          : _isToday
                              ? const Color(0xFF0B132B)
                              : _isPast
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0B132B),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Confettis pour 100%
        if (_isToday)
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                maxBlastForce: 8,
                minBlastForce: 4,
                emissionFrequency: 0.08,
                numberOfParticles: 8,
                gravity: 0.2,
                particleDrag: 0.05,
                colors: const [
                  Color(0xFF22C55E),
                  Color(0xFF3B82F6),
                  Color(0xFFF59E0B),
                  Color(0xFFEC4899),
                  Color(0xFF8B5CF6),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Construit une liste d'icônes (1 par ligne en normal, 2 colonnes en compact)
  Widget _buildActivitiesGrid(BuildContext context) {
    // Tailles selon le mode
    final emptyWidth = widget.isCompact ? 28.0 : 36.0;
    final emptyHeight = widget.isCompact ? 28.0 : 40.0;

    if (widget.dayPlan == null || !widget.dayPlan!.hasActivities) {
      // Jour vide - pas de tap
      return Container(
        width: emptyWidth,
        height: emptyHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
        ),
      );
    }

    // Construire la liste des données d'activités selon le filtre
    final List<_ActivityData> activities = [];

    // Ajouter les repas (triés par type) - seulement si filter = all ou meals
    if (widget.filter == ActivityFilter.all || widget.filter == ActivityFilter.meals) {
      final meals = List<PlannedActivity>.from(widget.dayPlan!.meals);

      // Créer un map des planned meals par type normalisé
      final plannedByType = <String, List<PlannedActivity>>{};
      for (final meal in meals) {
        final normalizedType = _normalizeMealType(meal.activityType.value);
        plannedByType.putIfAbsent(normalizedType, () => []).add(meal);
      }

      // Collecter les IDs des food_entries liées aux repas planifiés validés
      final linkedFoodEntryIds = <String>{};
      for (final meal in meals) {
        final linkedId = meal.mealData?.linkedFoodEntryId;
        if (linkedId != null) {
          linkedFoodEntryIds.add(linkedId);
        }
      }

      // Filtrer les journal entries non liées à des repas planifiés
      final unlinkedJournalEntries = widget.dayPlan!.journalEntries
          .where((e) => !linkedFoodEntryIds.contains(e.id))
          .toList();

      // Créer un set des types de repas qui ont des journal entries NON LIÉES
      final journalMealTypes = unlinkedJournalEntries.map((e) => _normalizeMealType(e.mealType)).toSet();

      // Itérer dans l'ordre standard et ajouter UNE SEULE icône par type de repas
      final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
      for (final mealType in mealOrder) {
        // Si on a des planned activities pour ce type, ajouter UNE SEULE icône
        if (plannedByType.containsKey(mealType)) {
          final mealsOfType = plannedByType[mealType]!;
          // Calculer le status du groupe : completed si TOUS les repas sont validés
          final allCompleted = mealsOfType.every((m) => m.status == PlannedStatus.completed);
          final groupStatus = allCompleted ? PlannedStatus.completed : PlannedStatus.planned;

          // Ajouter une seule entrée avec le premier meal et le groupe complet
          activities.add(_ActivityData(
            activity: mealsOfType.first,
            mealGroup: mealsOfType,
            groupStatus: groupStatus,
          ));
        }
        // Sinon, si on a des journal entries NON LIÉES pour ce type, ajouter une icône journal
        else if (journalMealTypes.contains(mealType)) {
          activities.add(_ActivityData(journalMealType: mealType));
        }
      }
    }

    // Ajouter les cardios - seulement si filter = all ou workouts
    if (widget.filter == ActivityFilter.all || widget.filter == ActivityFilter.workouts) {
      for (final cardio in widget.dayPlan!.cardios) {
        activities.add(_ActivityData(activity: cardio));
      }
    }

    // Ajouter les workouts - seulement si filter = all ou workouts
    if (widget.filter == ActivityFilter.all || widget.filter == ActivityFilter.workouts) {
      for (final workout in widget.dayPlan!.workouts) {
        activities.add(_ActivityData(workout: workout));
      }
    }

    // Si aucune activité après filtrage, afficher jour vide
    if (activities.isEmpty) {
      return Container(
        width: emptyWidth,
        height: emptyHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
        ),
      );
    }

    final totalCount = activities.length;

    if (widget.isCompact) {
      // Mode compact : grille 2 colonnes, max 6 visible (3 lignes x 2)
      final hasMore = totalCount > 6;
      final displayCount = hasMore ? 5 : totalCount;
      final remainingCount = totalCount - displayCount;

      // Construire les lignes de 2
      final List<Widget> rows = [];
      for (int i = 0; i < displayCount; i += 2) {
        final hasSecond = i + 1 < displayCount;
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < displayCount || hasMore ? 2 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniSquare(context, activities[i], i),
                if (hasSecond) ...[
                  const SizedBox(width: 2),
                  _buildMiniSquare(context, activities[i + 1], i + 1),
                ],
              ],
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: _isToday
              ? const Color(0xFF0B132B).withOpacity(0.05)
              : _isPast
                  ? const Color(0xFFF8FAFC)
                  : Colors.white,
          border: Border.all(
            color: _isToday
                ? const Color(0xFF0B132B).withOpacity(0.2)
                : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...rows,
            if (hasMore) _buildMoreBadge(context, remainingCount),
          ],
        ),
      );
    }

    // Mode normal : 1 icône par ligne (max 6 carrés visibles)
    // À 7+ items: 5 icônes + badge "+X" = 6 positions
    final hasMore = totalCount > 6;
    final displayCount = hasMore ? 5 : totalCount;
    final remainingCount = totalCount - displayCount;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: _isToday
            ? const Color(0xFF0B132B).withOpacity(0.05)
            : _isPast
                ? const Color(0xFFF8FAFC)
                : Colors.white,
        border: Border.all(
          color: _isToday
              ? const Color(0xFF0B132B).withOpacity(0.2)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Afficher les activités (1 par ligne)
          ...List.generate(displayCount, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < displayCount - 1 ? 4 : 0),
              child: _buildMiniSquare(context, activities[index], index),
            );
          }),
          // Badge "+N" si plus d'activités
          if (hasMore) ...[
            const SizedBox(height: 4),
            _buildMoreBadge(context, remainingCount),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniSquare(BuildContext context, _ActivityData data, int index) {
    if (data.workout != null) {
      return MiniWorkoutSquare(
        workout: data.workout!,
        onTap: () => _showActivityPager(context, index),
        isCompact: widget.isCompact,
      );
    } else if (data.activity != null) {
      // Utiliser le groupStatus si disponible (pour les repas groupés), sinon le status individuel
      final status = data.groupStatus ?? data.activity!.status;
      return MiniActivitySquare(
        activityType: data.activity!.activityType,
        status: status,
        onTap: () => _showActivityPager(context, index),
        isCompact: widget.isCompact,
      );
    } else if (data.journalMealType != null) {
      // Afficher les journal entries avec status completed (déjà consommé)
      return MiniActivitySquare(
        activityType: PlannedActivityTypeExtension.fromString(data.journalMealType!),
        status: PlannedStatus.completed, // Journal = déjà consommé
        onTap: () => _showActivityPager(context, index),
        isCompact: widget.isCompact,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMoreBadge(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => _showAllActivities(context),
      child: Container(
        width: 28,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '+$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityPager(BuildContext context, int index) {
    if (widget.dayPlan == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayActivitiesPagerSheet(
        date: widget.date,
        dayPlan: widget.dayPlan!,
        initialIndex: index,
        onActivityChanged: widget.onDataRefresh ?? () {},
      ),
    );
  }

  void _showAllActivities(BuildContext context) {
    // Le bouton "+" ouvre le pager à la première activité (zoom de la journée)
    _showActivityPager(context, 0);
  }
}

/// Classe helper pour stocker les données d'activité
class _ActivityData {
  final PlannedActivity? activity;
  final PlannedWorkout? workout;
  final String? journalMealType; // Pour les types de repas qui n'ont que des journal entries
  final List<PlannedActivity>? mealGroup; // Groupe de repas du même type (pour afficher une seule icône)
  final PlannedStatus? groupStatus; // Status calculé du groupe (completed si tous validés)

  _ActivityData({this.activity, this.workout, this.journalMealType, this.mealGroup, this.groupStatus});
}

/// Normalise le type de repas pour regrouper les variations
String _normalizeMealType(String mealType) {
  final lower = mealType.toLowerCase().trim();

  // Breakfast variations
  if (lower.contains('breakfast') || lower.contains('petit') || lower.contains('déjeuner') && !lower.contains('diner') && !lower.contains('dîner')) {
    if (lower == 'déjeuner' || lower == 'lunch') return 'lunch';
    return 'breakfast';
  }

  // Lunch variations
  if (lower.contains('lunch') || lower == 'déjeuner') {
    return 'lunch';
  }

  // Dinner variations
  if (lower.contains('dinner') || lower.contains('diner') || lower.contains('dîner') || lower.contains('souper')) {
    return 'dinner';
  }

  // Snack variations (collation, snack_1, snack_2, etc.)
  if (lower.contains('snack') || lower.contains('collation') || lower.contains('goûter') || lower.contains('gouter')) {
    return 'snack';
  }

  return mealType;
}
