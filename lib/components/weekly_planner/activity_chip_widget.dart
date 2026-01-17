import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/weekly_planner_models.dart';

/// Mini chip carré pour le grid layout du planner
class MiniActivitySquare extends StatelessWidget {
  final PlannedActivityType activityType;
  final PlannedStatus status;
  final VoidCallback? onTap;
  final bool isCompact;

  const MiniActivitySquare({
    super.key,
    required this.activityType,
    this.status = PlannedStatus.planned,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Couleurs selon le statut
    const plannedBlue = Color(0xFF0B132B); // Bleu des boutons pour planifié
    const completedGreen = Color(0xFF10B981);
    const missedRed = Color(0xFFEF4444);

    final isCompleted = status == PlannedStatus.completed;
    final isMissed = status == PlannedStatus.missed;

    final size = isCompact ? 18.0 : 28.0;
    final iconSize = isCompact ? 10.0 : 14.0;
    final borderRadius = isCompact ? 4.0 : 7.0;

    // Style selon le statut
    final Color bgColor;
    final Color iconColor;
    final Border? border;

    if (isMissed) {
      bgColor = missedRed.withOpacity(0.12);
      iconColor = missedRed;
      border = Border.all(color: missedRed.withOpacity(0.3), width: 1);
    } else if (isCompleted) {
      bgColor = completedGreen.withOpacity(0.15);
      iconColor = completedGreen;
      border = Border.all(color: completedGreen.withOpacity(0.3), width: 1);
    } else {
      // Planifié: outline bleu discret
      bgColor = Colors.transparent;
      iconColor = plannedBlue;
      border = Border.all(color: plannedBlue.withOpacity(0.3), width: 1);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        child: Center(
          child: Icon(
            activityType.icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Mini chip carré pour workout dans le grid layout
class MiniWorkoutSquare extends StatelessWidget {
  final PlannedWorkout workout;
  final VoidCallback? onTap;
  final bool isCompact;

  const MiniWorkoutSquare({
    super.key,
    required this.workout,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Couleurs selon le statut
    const plannedBlue = Color(0xFF0B132B); // Bleu des boutons pour planifié
    const completedGreen = Color(0xFF10B981);
    const missedRed = Color(0xFFEF4444);

    final isCompleted = workout.status == PlannedStatus.completed;
    final isMissed = workout.status == PlannedStatus.missed;

    final size = isCompact ? 18.0 : 28.0;
    final iconSize = isCompact ? 10.0 : 14.0;
    final borderRadius = isCompact ? 4.0 : 7.0;

    // Style selon le statut
    final Color bgColor;
    final Color iconColor;
    final Border? border;

    if (isMissed) {
      bgColor = missedRed.withOpacity(0.12);
      iconColor = missedRed;
      border = Border.all(color: missedRed.withOpacity(0.3), width: 1);
    } else if (isCompleted) {
      bgColor = completedGreen.withOpacity(0.15);
      iconColor = completedGreen;
      border = Border.all(color: completedGreen.withOpacity(0.3), width: 1);
    } else {
      // Planifié: outline bleu discret
      bgColor = Colors.transparent;
      iconColor = plannedBlue;
      border = Border.all(color: plannedBlue.withOpacity(0.3), width: 1);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
        ),
        child: Center(
          child: Icon(
            LucideIcons.dumbbell,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

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
    // Utiliser vert pour les séances complétées (plus visible)
    final displayColor = isCompleted ? const Color(0xFF10B981) : baseColor;

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
                  ? const Color(0xFF10B981).withOpacity(0.2) // Vert clair pour complété
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? Border.all(color: const Color(0xFF10B981).withOpacity(0.5)) // Bordure verte
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
              isCompleted ? Icons.check : workout.icon, // Icône check si complété
              size: 12,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : displayColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullChip(Color baseColor, bool isCompleted, bool isMissed) {
    // Couleur verte pour les séances complétées (plus visible)
    const completedColor = Color(0xFF10B981);
    final displayColor = isCompleted ? completedColor : baseColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMissed
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? completedColor.withOpacity(0.15) // Fond vert clair
                  : baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isMissed
              ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.5))
              : isCompleted
                  ? Border.all(color: completedColor.withOpacity(0.5)) // Bordure verte
                  : Border.all(
                      color: baseColor.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : workout.icon, // Icône check pour complété
              size: 16,
              color: isMissed
                  ? const Color(0xFFEF4444)
                  : displayColor,
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
                          : displayColor,
                      decoration: isMissed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (workout.durationMinutes != null)
                    Text(
                      isCompleted
                          ? '✓ Terminée'
                          : '${workout.durationMinutes} min • ${workout.totalExercises} ex.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMissed
                            ? const Color(0xFFEF4444).withOpacity(0.7)
                            : displayColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
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
