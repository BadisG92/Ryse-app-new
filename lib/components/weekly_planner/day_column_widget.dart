import 'package:flutter/material.dart';
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
class DayColumnWidget extends StatelessWidget {
  final DateTime date;
  final String dayName;
  final DayPlanData? dayPlan;
  final VoidCallback? onDataRefresh; // Callback pour recharger les données après une action
  final Function(PlannedActivity)? onActivityTap;
  final Function(PlannedWorkout)? onWorkoutTap;
  final bool isCompact; // Mode compact pour le chat (2 colonnes, petites icônes)
  final ActivityFilter filter; // Filtre pour les types d'activités

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
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isToday = normalizedDate == today;
    final isPast = normalizedDate.isBefore(today);

    return Opacity(
      opacity: isPast ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header du jour
            _buildDayHeader(isToday, isPast),
            const SizedBox(height: 6),
            // Activités du jour - liste verticale
            _buildActivitiesGrid(context, isToday, isPast),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(bool isToday, bool isPast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF0B132B)
            : isPast
                ? const Color(0xFFF1F5F9)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white
                  : isPast
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? Colors.white
                  : isPast
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0B132B),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une liste d'icônes (1 par ligne en normal, 2 colonnes en compact)
  Widget _buildActivitiesGrid(BuildContext context, bool isToday, bool isPast) {
    // Tailles selon le mode
    final emptyWidth = isCompact ? 28.0 : 36.0;
    final emptyHeight = isCompact ? 28.0 : 40.0;

    if (dayPlan == null || !dayPlan!.hasActivities) {
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
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        ),
      );
    }

    // Construire la liste des données d'activités selon le filtre
    final List<_ActivityData> activities = [];

    // Ajouter les repas (triés par type) - seulement si filter = all ou meals
    if (filter == ActivityFilter.all || filter == ActivityFilter.meals) {
      final meals = List<PlannedActivity>.from(dayPlan!.meals);
      meals.sort((a, b) {
        final order = ['breakfast', 'lunch', 'dinner', 'snack'];
        return order.indexOf(a.activityType.value).compareTo(order.indexOf(b.activityType.value));
      });

      for (final meal in meals) {
        activities.add(_ActivityData(activity: meal));
      }
    }

    // Ajouter les cardios - seulement si filter = all ou workouts
    if (filter == ActivityFilter.all || filter == ActivityFilter.workouts) {
      for (final cardio in dayPlan!.cardios) {
        activities.add(_ActivityData(activity: cardio));
      }
    }

    // Ajouter les workouts - seulement si filter = all ou workouts
    if (filter == ActivityFilter.all || filter == ActivityFilter.workouts) {
      for (final workout in dayPlan!.workouts) {
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
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        ),
      );
    }

    final totalCount = activities.length;

    if (isCompact) {
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
          color: isToday
              ? const Color(0xFF0B132B).withOpacity(0.05)
              : isPast
                  ? const Color(0xFFF8FAFC)
                  : Colors.white,
          border: Border.all(
            color: isToday
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

    // Mode normal : 1 icône par ligne
    final hasMore = totalCount > 5;
    final displayCount = hasMore ? 4 : totalCount;
    final remainingCount = totalCount - displayCount;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF0B132B).withOpacity(0.05)
            : isPast
                ? const Color(0xFFF8FAFC)
                : Colors.white,
        border: Border.all(
          color: isToday
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
        isCompact: isCompact,
      );
    } else if (data.activity != null) {
      return MiniActivitySquare(
        activityType: data.activity!.activityType,
        status: data.activity!.status,
        onTap: () => _showActivityPager(context, index),
        isCompact: isCompact,
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
    if (dayPlan == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayActivitiesPagerSheet(
        date: date,
        dayPlan: dayPlan!,
        initialIndex: index,
        onActivityChanged: onDataRefresh ?? () {}, // Utiliser onDataRefresh pour recharger les données
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

  _ActivityData({this.activity, this.workout});
}
