import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../models/cardio_session_models.dart';
import '../../models/hiit_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../screens/cardio_tracking_screen.dart';
import '../../screens/hiit_session_screen.dart';

/// Bottom sheet pour afficher le récapitulatif d'une activité cardio planifiée
class CardioRecapBottomSheet extends StatelessWidget {
  final PlannedActivity activity;
  final VoidCallback onCardioStarted;
  final VoidCallback? onCardioDeleted;

  const CardioRecapBottomSheet({
    super.key,
    required this.activity,
    required this.onCardioStarted,
    this.onCardioDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;
    final isEditable = isDateEditable(activity.plannedDate);
    final isTodayCardio = isToday(activity.plannedDate);
    final isCompleted = activity.status == PlannedStatus.completed;
    final cardioData = activity.cardioData;

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
            _buildHeader(context, langCode, isCompleted, cardioData),

            // Objectifs
            if (cardioData != null) _buildObjectives(langCode, cardioData),

            // Boutons d'action (supprimer pour futur, commencer uniquement aujourd'hui)
            if (isEditable && !isCompleted)
              _buildActions(context, langCode, cardioData, isTodayCardio),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String langCode,
    bool isCompleted,
    PlannedCardioData? cardioData,
  ) {
    final activityName = cardioData?.activityName ?? 'Cardio';
    final activityIcon = _getActivityIcon(cardioData?.activityKey ?? '');

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
              isCompleted ? LucideIcons.circleCheck : activityIcon,
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
                  activityName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B132B),
                  ),
                ),
                Text(
                  _formatDate(activity.plannedDate, langCode),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectives(String langCode, PlannedCardioData cardioData) {
    // Si c'est un HIIT, afficher les objectifs HIIT
    if (cardioData.isHiit && cardioData.hiitConfig != null) {
      return _buildHiitObjectives(langCode, cardioData.hiitConfig!);
    }

    final hasDistance = cardioData.targetKm != null && cardioData.targetKm! > 0;
    final hasTime = cardioData.targetMinutes != null && cardioData.targetMinutes! > 0;

    if (!hasDistance && !hasTime) {
      return const SizedBox.shrink();
    }

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
            if (hasTime)
              Expanded(child: _buildStatItem(LucideIcons.clock, '${cardioData.targetMinutes}', 'min')),
            if (hasTime && hasDistance)
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
            if (hasDistance)
              Expanded(child: _buildStatItem(LucideIcons.mapPin, cardioData.targetKm!.toStringAsFixed(1), 'km')),
          ],
        ),
      ),
    );
  }

  Widget _buildHiitObjectives(String langCode, HiitConfig hiitConfig) {
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
            // Effort
            Expanded(
              child: _buildStatItem(
                LucideIcons.zap,
                '${hiitConfig.workSeconds}s',
                langCode == 'fr' ? 'effort' : 'work',
              ),
            ),
            Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
            // Repos
            Expanded(
              child: _buildStatItem(
                LucideIcons.pause,
                '${hiitConfig.restSeconds}s',
                langCode == 'fr' ? 'repos' : 'rest',
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
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
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

  Widget _buildActions(
    BuildContext context,
    String langCode,
    PlannedCardioData? cardioData,
    bool canStart,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Bouton supprimer (toujours disponible pour les jours éditables)
          if (onCardioDeleted != null)
            Expanded(
              flex: canStart ? 1 : 2,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(context, langCode);
                  if (confirm == true) {
                    // Suppression bidirectionnelle: planificateur + historique si lié
                    await WeeklyPlannerService.deleteCardioWithSync(activity.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      onCardioDeleted?.call();
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
          if (onCardioDeleted != null && canStart) const SizedBox(width: 12),

          // Bouton commencer (uniquement pour aujourd'hui)
          if (canStart)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startCardio(context, cardioData);
                },
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text('planner_start_cardio'.tr(langCode)),
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

  void _startCardio(BuildContext context, PlannedCardioData? cardioData) {
    final activityKey = cardioData?.activityKey ?? 'running';
    final activityName = cardioData?.activityName ?? 'Running';

    // Si c'est un HIIT, lancer l'écran HIIT
    if (cardioData != null && cardioData.isHiit && cardioData.hiitConfig != null) {
      _startHiit(context, cardioData);
      return;
    }

    // Créer l'objectif cardio si défini
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
    ).then((_) {
      onCardioStarted();
    });
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiitSessionScreen(
          workout: hiitWorkout,
          isFromCustomConfig: hiitConfig.type == 'custom',
        ),
      ),
    ).then((_) {
      onCardioStarted();
    });
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String langCode) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('planner_delete_cardio_title'.tr(langCode)),
        content: Text('planner_delete_cardio_message'.tr(langCode)),
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
      'de': ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
    };

    final days = dayNames[langCode] ?? dayNames['en']!;
    return '${days[date.weekday - 1]} ${date.day}/${date.month}';
  }
}
