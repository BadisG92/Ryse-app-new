import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/cardio_models.dart';
import 'ui/cardio_cards.dart';
import 'ui/cardio_widgets.dart';

class SportCardioHybrid extends StatelessWidget {
  const SportCardioHybrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Bloc "Cette semaine" avec statistiques
            WeeklyStatsSection(
              stats: CardioData.weeklyStats,
            ),
            
            const SizedBox(height: 16),
            
            // 2. Bloc "Choisir une activité"
            ActivitySelectionSection(
              onActivitySelected: (activityType, activityTitle) =>
                  _showActivityFormatsModal(context, activityType, activityTitle),
            ),
            
            const SizedBox(height: 16),
            
            // 3. Bloc "Dernière séance enregistrée"
            SessionCard(
              session: CardioData.lastSession,
              onDetailsTap: () => _showSessionDetails(context),
            ),
            
            const SizedBox(height: 16),
            
            // 4. Bloc "Vos séances de la semaine"
            WeekSessionsSection(
              sessions: CardioData.weekSessions,
            ),
            
            const SizedBox(height: 16),
            
            // 5. Footer / CTA
            HistoryAccessWidget(
              onTap: () => _openCardioJournal(context),
            ),
            
            // Padding bottom pour éviter la coupure
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showActivityFormatsModal(BuildContext context, String activityType, String activityTitle) {
    final formats = CardioData.activityFormats[activityType]?.map((format) => format).toList() ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFormatsModal(
        activityTitle: activityTitle,
        formats: formats,
        onFormatSelected: (format) {
          Navigator.pop(context);
          if (format.configurable) {
            _showConfigurationModal(context, format, activityTitle);
          } else {
            _showRecordingChoiceModal(context, format.title, format.trackable);
          }
        },
      ),
    );
  }

  void _showConfigurationModal(BuildContext context, ActivityFormat format, String activityTitle) {
    final config = CardioData.activityConfigs[format.configType];
    if (config == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityConfigModal(
        config: config,
        onConfigSubmitted: (value) {
          Navigator.pop(context);
          _showRecordingChoiceModal(
            context, 
            '${format.title} ($value ${config.unit})', 
            format.trackable,
          );
        },
      ),
    );
  }

  void _showRecordingChoiceModal(BuildContext context, String formatTitle, bool trackable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordingChoiceModal(
        formatTitle: formatTitle,
        trackable: trackable,
        onTrackPressed: () {
          Navigator.pop(context);
          _startTracking(context, formatTitle);
        },
        onDeclarePressed: () {
          Navigator.pop(context);
          _openManualEntry(context, formatTitle);
        },
      ),
    );
  }

  void _startTracking(BuildContext context, String formatTitle) {
    // TODO: Démarrer le suivi GPS/chrono
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Démarrage du suivi pour $formatTitle')),
    );
  }

  void _openManualEntry(BuildContext context, String formatTitle) {
    // TODO: Ouvrir le formulaire de saisie manuelle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ouverture du formulaire pour $formatTitle')),
    );
  }

  void _showSessionDetails(BuildContext context) {
    // TODO: Afficher les détails de la dernière session
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Affichage des détails de la session')),
    );
  }

  void _openCardioJournal(BuildContext context) {
    // TODO: Ouvrir le journal cardio complet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture du journal cardio')),
    );
  }
} 