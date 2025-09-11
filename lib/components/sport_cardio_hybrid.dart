import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ui/cardio_models.dart';
import 'ui/cardio_widgets.dart';
import '../models/hiit_models.dart';
import '../models/cardio_session_models.dart';
import '../screens/hiit_session_screen.dart';
import '../screens/hiit_config_screen.dart';
import '../screens/cardio_tracking_screen.dart';
import '../screens/manual_cardio_entry_screen.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/cardio_service.dart';

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
            // 1. Bloc "Cette semaine" avec statistiques (connecté à Supabase)
            const WeeklyStatsSection(),
            
            const SizedBox(height: 16),
            
            // 2. Bloc "Choisir une activité"
            ActivitySelectionSection(
              onActivitySelected: (activity) =>
                  _showActivityFormatsModal(context, activity),
            ),
            
            const SizedBox(height: 16),
            
            // 3. Bloc "Dernière séance enregistrée" (connecté à Supabase)
            LastSessionSection(
              onDetailsTap: () => _showSessionDetails(context),
            ),
            
            const SizedBox(height: 16),
            
            // 4. Bloc "Vos séances de la semaine" (connecté à Supabase)
            const WeekSessionsSection(),
            
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

  /// Convertit le nom d'icône en IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'activity':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'footprints':
        return LucideIcons.footprints;
      case 'flame':
        return LucideIcons.flame;
      case 'zap':
        return LucideIcons.zap;
      case 'target':
        return LucideIcons.target;
      case 'clock':
        return LucideIcons.clock;
      case 'mountain':
        return LucideIcons.mountain;
      case 'trending-up':
        return LucideIcons.trendingUp;
      case 'timer':
        return LucideIcons.timer;
      default:
        return LucideIcons.activity; // icône par défaut
    }
  }


  void _showActivityFormatsModal(BuildContext context, CardioActivityType activity) {
    // Utiliser directement les formats Supabase qui ont déjà les traductions
    final formats = activity.formats.map((supabaseFormat) {
      return ActivityFormat(
        icon: _getIconFromName(supabaseFormat.iconName),
        title: supabaseFormat.name, // Utiliser directement le nom traduit depuis Supabase
        description: supabaseFormat.description ?? '', // Utiliser directement la description traduite
        trackable: supabaseFormat.isTrackable,
        configurable: supabaseFormat.isConfigurable,
        configType: supabaseFormat.configType ?? '',
        supabaseFormat: supabaseFormat, // Garder la référence originale
      );
    }).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFormatsModal(
        activityTitle: activity.name,
        formats: formats,
        onFormatSelected: (format) {
          Navigator.pop(context);
          
          // Gestion spéciale pour HIIT
          if (activity.activityKey == 'hiit') {
            _handleHiitSelection(context, format);
          } else if (format.configurable) {
            _showConfigurationModal(context, format, activity);
          } else {
            _showRecordingChoiceModal(context, format.title, format.trackable, activity: activity);
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
      // HIIT prédéfini - Créer le workout depuis les données Supabase
      HiitWorkout? workout;
      
      // Utiliser les données du format Supabase pour créer le HiitWorkout
      final supabaseFormat = format.supabaseFormat;
      if (supabaseFormat != null && supabaseFormat.isHiit) {
        workout = HiitWorkout(
          id: supabaseFormat.id,
          title: format.title, // Titre déjà traduit depuis Supabase
          description: format.description, // Description déjà traduite depuis Supabase
          workDuration: supabaseFormat.hiitWorkSeconds ?? 30,
          restDuration: supabaseFormat.hiitRestSeconds ?? 30,
          totalDuration: supabaseFormat.defaultDurationMinutes ?? 15,
          totalRounds: supabaseFormat.hiitRounds ?? 15,
        );
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

  void _showConfigurationModal(BuildContext context, ActivityFormat format, CardioActivityType activity) {
    final locService = LocalizationService.instance;
    final config = CardioData.getLocalizedActivityConfigs(locService.currentLanguageCode)[format.configType];
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
            activity: activity,
            objective: objective,
          );
        },
      ),
    );
  }

  void _showRecordingChoiceModal(BuildContext context, String formatTitle, bool trackable, {required CardioActivityType activity, CardioObjective? objective}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordingChoiceModal(
        formatTitle: formatTitle,
        trackable: trackable,
        onTrackPressed: () {
          Navigator.pop(context);
          _startTracking(context, formatTitle, activity, objective);
        },
        onDeclarePressed: () {
          Navigator.pop(context);
          _openManualEntry(context, formatTitle, activity);
        },
      ),
    );
  }

  void _startTracking(BuildContext context, String formatTitle, CardioActivityType activity, CardioObjective? objective) {
    // Utiliser directement les informations de l'activité Supabase
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioTrackingScreen(
          activityType: activity.activityKey,
          activityTitle: activity.name,
          formatTitle: formatTitle,
          objective: objective,
        ),
      ),
    );
  }

  void _openManualEntry(BuildContext context, String formatTitle, CardioActivityType activity) {
    // Utiliser directement les informations de l'activité Supabase
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualCardioEntryScreen(
          activityType: activity.activityKey,
          activityTitle: activity.name,
          formatTitle: formatTitle,
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context) {
    // TODO: Afficher les détails de la dernière session
    final locService = LocalizationService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('session_details_display'.tr(locService.currentLanguageCode))),
    );
  }

  void _openCardioJournal(BuildContext context) {
    // TODO: Ouvrir le journal cardio complet
    final locService = LocalizationService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('cardio_journal_opening'.tr(locService.currentLanguageCode))),
    );
  }
} 
