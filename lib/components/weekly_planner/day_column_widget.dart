import 'package:flutter/material.dart';
import '../../models/weekly_planner_models.dart';
import 'activity_chip_widget.dart';

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
          // Activités du jour
          Expanded(
            child: _buildActivitiesColumn(isToday, isPast),
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

  Widget _buildActivitiesColumn(bool isToday, bool isPast) {
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

    // Construire la liste des chips
    final List<Widget> chips = [];

    // Ajouter les repas (triés par type)
    final meals = dayPlan!.meals;
    meals.sort((a, b) {
      final order = ['breakfast', 'lunch', 'dinner', 'snack'];
      return order.indexOf(a.activityType.value).compareTo(order.indexOf(b.activityType.value));
    });

    for (final meal in meals) {
      chips.add(
        ActivityChipWidget(
          activityType: meal.activityType,
          status: meal.status,
          isCompact: true,
          onTap: onActivityTap != null ? () => onActivityTap!(meal) : null,
        ),
      );
    }

    // Ajouter les cardios
    for (final cardio in dayPlan!.cardios) {
      chips.add(
        ActivityChipWidget(
          activityType: PlannedActivityType.cardio,
          status: cardio.status,
          isCompact: true,
          onTap: onActivityTap != null ? () => onActivityTap!(cardio) : null,
        ),
      );
    }

    // Ajouter les workouts
    for (final workout in dayPlan!.workouts) {
      chips.add(
        WorkoutChipWidget(
          workout: workout,
          isCompact: true,
          onTap: onWorkoutTap != null ? () => onWorkoutTap!(workout) : null,
        ),
      );
    }

    // Limiter à 4 chips visibles max
    final displayChips = chips.take(4).toList();
    final hasMore = chips.length > 4;

    return Container(
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
        children: [
          ...displayChips.map((chip) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: chip,
              )),
          if (hasMore)
            Text(
              '+${chips.length - 4}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }
}
