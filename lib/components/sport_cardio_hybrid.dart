import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/cardio_models.dart';
import 'ui/cardio_cards.dart';
import 'ui/cardio_widgets.dart';
import '../models/hiit_models.dart';
import '../models/cardio_session_models.dart';
import '../screens/hiit_session_screen.dart';
import '../screens/hiit_config_screen.dart';
import '../screens/cardio_tracking_screen.dart';
import '../screens/manual_cardio_entry_screen.dart';

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
          
          // Gestion spéciale pour HIIT
          if (activityType == 'hiit') {
            _handleHiitSelection(context, format);
          } else if (format.configurable) {
            _showConfigurationModal(context, format, activityTitle);
          } else {
            _showRecordingChoiceModal(context, format.title, format.trackable);
          }
        },
      ),
    );
  }

  void _handleHiitSelection(BuildContext context, ActivityFormat format) {
    if (format.configurable && format.configType == 'hiit') {
      // HIIT personnalisé
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HiitConfigScreen(),
        ),
      );
    } else {
      // HIIT prédéfini
      HiitWorkout? workout;
      
      switch (format.title) {
        case 'HIIT débutant':
          workout = HiitWorkouts.getWorkoutById('hiit_beginner');
          break;
        case 'HIIT intense':
          workout = HiitWorkouts.getWorkoutById('hiit_intense');
          break;
        case 'Tabata':
          workout = HiitWorkouts.getWorkoutById('tabata');
          break;
      }
      
      if (workout != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HiitSessionScreen(workout: workout!),
          ),
        );
      }
    }
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
          
          // Créer l'objectif selon le type
          CardioObjective? objective;
          if (config.type == 'distance') {
            objective = CardioObjective(
              type: 'distance',
              targetDistance: double.tryParse(value) ?? 0.0,
              activityType: format.title.toLowerCase(),
              formatTitle: '${format.title} ($value ${config.unit})',
            );
          } else if (config.type == 'duration') {
            objective = CardioObjective(
              type: 'duration',
              targetDuration: Duration(minutes: int.tryParse(value) ?? 0),
              activityType: format.title.toLowerCase(),
              formatTitle: '${format.title} ($value ${config.unit})',
            );
          }
          
          _showRecordingChoiceModal(
            context, 
            '${format.title} ($value ${config.unit})', 
            format.trackable,
            objective: objective,
          );
        },
      ),
    );
  }

  void _showRecordingChoiceModal(BuildContext context, String formatTitle, bool trackable, {CardioObjective? objective}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordingChoiceModal(
        formatTitle: formatTitle,
        trackable: trackable,
        onTrackPressed: () {
          Navigator.pop(context);
          _startTracking(context, formatTitle, objective);
        },
        onDeclarePressed: () {
          Navigator.pop(context);
          _openManualEntry(context, formatTitle);
        },
      ),
    );
  }

  void _startTracking(BuildContext context, String formatTitle, CardioObjective? objective) {
    // Extraire le type d'activité depuis le formatTitle
    String activityType = 'running'; // défaut
    String activityTitle = 'Course à pied'; // défaut
    
    if (formatTitle.toLowerCase().contains('vélo') || formatTitle.toLowerCase().contains('bike')) {
      activityType = 'bike';
      activityTitle = 'Vélo';
    } else if (formatTitle.toLowerCase().contains('marche') || formatTitle.toLowerCase().contains('walk')) {
      activityType = 'walking';
      activityTitle = 'Marche';
    } else if (formatTitle.toLowerCase().contains('course') || formatTitle.toLowerCase().contains('running')) {
      activityType = 'running';
      activityTitle = 'Course à pied';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioTrackingScreen(
          activityType: activityType,
          activityTitle: activityTitle,
          formatTitle: formatTitle,
          objective: objective,
        ),
      ),
    );
  }

  void _openManualEntry(BuildContext context, String formatTitle) {
    // Extraire le type d'activité depuis le formatTitle
    String activityType = 'running'; // défaut
    String activityTitle = 'Course à pied'; // défaut
    
    if (formatTitle.toLowerCase().contains('vélo') || formatTitle.toLowerCase().contains('bike')) {
      activityType = 'bike';
      activityTitle = 'Vélo';
    } else if (formatTitle.toLowerCase().contains('marche') || formatTitle.toLowerCase().contains('walk')) {
      activityType = 'walking';
      activityTitle = 'Marche';
    } else if (formatTitle.toLowerCase().contains('course') || formatTitle.toLowerCase().contains('running')) {
      activityType = 'running';
      activityTitle = 'Course à pied';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualCardioEntryScreen(
          activityType: activityType,
          activityTitle: activityTitle,
          formatTitle: formatTitle,
        ),
      ),
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
