import 'package:flutter/material.dart';
import '../../models/weekly_planner_models.dart';

/// Chip représentant une activité (repas ou cardio) dans le planner
class ActivityChipWidget extends StatelessWidget {
  final PlannedActivityType activityType;
  final PlannedStatus status;
  final bool isCompact;
  final VoidCallback? onTap;
  final String? label;

  const ActivityChipWidget({
    super.key,
    required this.activityType,
    this.status = PlannedStatus.planned,
    this.isCompact = false,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = activityType.color;
    final isCompleted = status == PlannedStatus.completed;
    final isMissed = status == PlannedStatus.missed;

    if (isCompact) {
      return _buildCompactChip(baseColor, isCompleted, isMissed);
    }

    return _buildFullChip(baseColor, isCompleted, isMissed);
  }

  Widget _buildCompactChip(Color baseColor, bool isCompleted, bool isMissed) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 20,
        decoration: BoxDecoration(
          color: isMissed
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? baseColor.withOpacity(0.2)
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? null
                  : Border.all(
                      color: baseColor.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activityType.icon,
              size: 12,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : baseColor,
            ),
            if (isCompleted) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.check,
                size: 10,
                color: baseColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullChip(Color baseColor, bool isCompleted, bool isMissed) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMissed
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? baseColor.withOpacity(0.15)
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? Border.all(color: baseColor.withOpacity(0.3))
                  : Border.all(
                      color: baseColor.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activityType.icon,
              size: 16,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : baseColor,
            ),
            if (label != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isMissed
                        ? const Color(0xFFEF4444)
                        : baseColor,
                    decoration: isMissed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip représentant un workout dans le planner
class WorkoutChipWidget extends StatelessWidget {
  final PlannedWorkout workout;
  final bool isCompact;
  final VoidCallback? onTap;

  const WorkoutChipWidget({
    super.key,
    required this.workout,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = workout.color;
    final isCompleted = workout.status == PlannedStatus.completed;
    final isMissed = workout.status == PlannedStatus.missed;

    if (isCompact) {
      return _buildCompactChip(baseColor, isCompleted, isMissed);
    }

    return _buildFullChip(baseColor, isCompleted, isMissed);
  }

  Widget _buildCompactChip(Color baseColor, bool isCompleted, bool isMissed) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 20,
        decoration: BoxDecoration(
          color: isMissed
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? baseColor.withOpacity(0.2)
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? null
                  : Border.all(
                      color: baseColor.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              workout.icon,
              size: 12,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : baseColor,
            ),
            if (isCompleted) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.check,
                size: 10,
                color: baseColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullChip(Color baseColor, bool isCompleted, bool isMissed) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMissed
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? baseColor.withOpacity(0.15)
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? Border.all(color: baseColor.withOpacity(0.3))
                  : Border.all(
                      color: baseColor.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              workout.icon,
              size: 16,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : baseColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    workout.workoutName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isMissed
                          ? const Color(0xFFEF4444)
                          : baseColor,
                      decoration: isMissed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (workout.durationMinutes != null)
                    Text(
                      '${workout.durationMinutes} min • ${workout.totalExercises} ex.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMissed
                            ? const Color(0xFFEF4444).withOpacity(0.7)
                            : baseColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip sélectionnable pour le type d'activité (dans AddActivityBottomSheet)
class ActivityTypeChip extends StatelessWidget {
  final PlannedActivityType activityType;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityTypeChip({
    super.key,
    required this.activityType,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = activityType.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? baseColor.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? baseColor
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activityType.icon,
                size: 20,
                color: baseColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? baseColor
                      : const Color(0xFF0B132B),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: baseColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip pour workout type (dans AddActivityBottomSheet)
class WorkoutTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const WorkoutTypeChip({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF0B132B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? baseColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? baseColor
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 20,
                color: baseColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? baseColor
                      : const Color(0xFF0B132B),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: baseColor,
              ),
          ],
        ),
      ),
    );
  }
}
