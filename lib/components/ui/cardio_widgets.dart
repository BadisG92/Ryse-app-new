import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'cardio_models.dart';
import 'cardio_cards.dart';

// Section des statistiques hebdomadaires
class WeeklyStatsSection extends StatelessWidget {
  final WeeklyCardioStats stats;

  const WeeklyStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cette semaine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.distanceText,
                    subtitle: 'Distance',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.durationText,
                    subtitle: 'Temps',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeeklyStatCard(
                    title: stats.caloriesText,
                    subtitle: 'Calories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Section de sélection d'activités
class ActivitySelectionSection extends StatelessWidget {
  final Function(String activityType, String activityTitle) onActivitySelected;

  const ActivitySelectionSection({
    super.key,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.play,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Choisir une activité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: CardioData.activityTypes.map((activity) {
                return ActivityCard(
                  icon: activity.icon,
                  title: activity.title,
                  onTap: () => onActivitySelected(activity.id, activity.title),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Section des sessions de la semaine
class WeekSessionsSection extends StatelessWidget {
  final List<CardioSession> sessions;

  const WeekSessionsSection({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vos séances de la semaine',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des séances
            ...sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              final isLast = index == sessions.length - 1;
              
              return Column(
                children: [
                  WeekSessionItem(session: session),
                  if (!isLast) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Modal de sélection de formats d'activité
class ActivityFormatsModal extends StatelessWidget {
  final String activityTitle;
  final List<ActivityFormat> formats;
  final Function(ActivityFormat) onFormatSelected;

  const ActivityFormatsModal({
    super.key,
    required this.activityTitle,
    required this.formats,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Choisir un format de séance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            Text(
              activityTitle,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formats pour cette activité
            ...formats.map((format) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ActivityFormatCard(
                format: format,
                onTap: () => onFormatSelected(format),
              ),
            )).toList(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Modal de configuration d'activité
class ActivityConfigModal extends StatelessWidget {
  final ActivityConfig config;
  final Function(String value) onConfigSubmitted;

  const ActivityConfigModal({
    super.key,
    required this.config,
    required this.onConfigSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                config.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Champ de saisie avec validation numérique
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: config.hint,
                        hintStyle: const TextStyle(color: Color(0xFF888888)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0B132B)),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      config.unit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Bouton valider
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      onConfigSubmitted(controller.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Valider',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal de choix d'enregistrement (suivre ou déclarer)
class RecordingChoiceModal extends StatelessWidget {
  final String formatTitle;
  final bool trackable;
  final VoidCallback onTrackPressed;
  final VoidCallback onDeclarePressed;

  const RecordingChoiceModal({
    super.key,
    required this.formatTitle,
    required this.trackable,
    required this.onTrackPressed,
    required this.onDeclarePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Comment veux-tu enregistrer\nta séance ?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            Text(
              formatTitle,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'actions
            if (trackable) ...[
              // Bouton suivre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTrackPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.play, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Démarrer la séance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Bouton déclarer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDeclarePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0B132B),
                  side: const BorderSide(color: Color(0xFF0B132B)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.pencil, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Déclarer la séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Widget d'accès à l'historique
class HistoryAccessWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const HistoryAccessWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 16,
              color: Color(0xFF0B132B),
            ),
            SizedBox(width: 8),
            Text(
              'Voir tout mon journal cardio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
