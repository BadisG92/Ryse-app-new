import 'package:flutter/material.dart';
import '../../models/weekly_planner_models.dart';
import 'activity_chip_widget.dart';
import 'day_activities_pager_sheet.dart';

/// Widget représentant une colonne de jour dans le planner
class DayColumnWidget extends StatelessWidget {
  final DateTime date;
  final String dayName;
  final DayPlanData? dayPlan;
  final VoidCallback onTap;
  final Function(PlannedActivity)? onActivityTap;
  final Function(PlannedWorkout)? onWorkoutTap;

  const DayColumnWidget({
    super.key,
    required this.date,
    required this.dayName,
    required this.dayPlan,
    required this.onTap,
    this.onActivityTap,
    this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isToday = normalizedDate == today;
    final isPast = normalizedDate.isBefore(today);

    return Container(
      width: 48,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Header du jour - cliquable pour ajouter une activité
          GestureDetector(
            onTap: onTap,
            child: _buildDayHeader(isToday, isPast),
          ),
          const SizedBox(height: 8),
          // Activités du jour - grille 2x3
          Expanded(
            child: _buildActivitiesGrid(context, isToday, isPast),
          ),
        ],
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

  /// Construit une grille 2x3 avec les activités
  Widget _buildActivitiesGrid(BuildContext context, bool isToday, bool isPast) {
    if (dayPlan == null || !dayPlan!.hasActivities) {
      // Jour vide - boîte cliquable pour ajouter une activité
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    // Construire la liste des données d'activités (pas les widgets)
    final List<_ActivityData> activities = [];

    // Ajouter les repas (triés par type)
    final meals = List<PlannedActivity>.from(dayPlan!.meals);
    meals.sort((a, b) {
      final order = ['breakfast', 'lunch', 'dinner', 'snack'];
      return order.indexOf(a.activityType.value).compareTo(order.indexOf(b.activityType.value));
    });

    for (final meal in meals) {
      activities.add(_ActivityData(activity: meal));
    }

    // Ajouter les cardios
    for (final cardio in dayPlan!.cardios) {
      activities.add(_ActivityData(activity: cardio));
    }

    // Ajouter les workouts
    for (final workout in dayPlan!.workouts) {
      activities.add(_ActivityData(workout: workout));
    }

    final totalCount = activities.length;
    final hasMore = totalCount > 6;

    // Si plus de 6, on affiche 5 + bouton "+"
    final displayCount = hasMore ? 5 : totalCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rangée 1 (2 carrés)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (displayCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: _buildMiniSquare(context, activities[0], 0),
                  ),
                if (displayCount > 1)
                  _buildMiniSquare(context, activities[1], 1),
              ],
            ),
            // Rangée 2 (2 carrés)
            if (displayCount > 2) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: _buildMiniSquare(context, activities[2], 2),
                  ),
                  if (displayCount > 3)
                    _buildMiniSquare(context, activities[3], 3),
                ],
              ),
            ],
            // Rangée 3 (2 carrés ou 1 carré + bouton "+")
            if (displayCount > 4 || hasMore) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (displayCount > 4)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _buildMiniSquare(context, activities[4], 4),
                    ),
                  if (hasMore)
                    _buildExpandButton(context)
                  else if (displayCount > 5)
                    _buildMiniSquare(context, activities[5], 5),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSquare(BuildContext context, _ActivityData data, int index) {
    if (data.workout != null) {
      return MiniWorkoutSquare(
        workout: data.workout!,
        onTap: () => _showActivityPager(context, index),
      );
    } else if (data.activity != null) {
      return MiniActivitySquare(
        activityType: data.activity!.activityType,
        status: data.activity!.status,
        onTap: () => _showActivityPager(context, index),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildExpandButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAllActivities(context),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 10,
            color: Color(0xFF0B132B),
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
        onActivityChanged: onTap,
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
