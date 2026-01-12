import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'custom_card.dart';
import 'cardio_models.dart';
import 'numeric_text_field.dart';
import '../../services/cardio_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../services/weekly_planner_service.dart';
import 'cardio_cards.dart';

// Section des statistiques hebdomadaires (connectée à Supabase)
class WeeklyStatsSection extends StatefulWidget {
  const WeeklyStatsSection({super.key});

  @override
  State<WeeklyStatsSection> createState() => _WeeklyStatsSectionState();
}

class _WeeklyStatsSectionState extends State<WeeklyStatsSection> {
  CardioWeeklyStats? _stats;
  bool _loading = true;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locService = LocalizationService.instance;
    if (_currentLanguage != locService.currentLanguageCode) {
      _currentLanguage = locService.currentLanguageCode;
      // Recharger les données pour la nouvelle langue
      _loadWeeklyStats();
    }
  }

  Future<void> _loadWeeklyStats() async {
    try {
      debugPrint('📊 WeeklyStatsSection: Chargement des stats hebdomadaires...');
      final stats = await CardioService.getWeeklyStats();
      debugPrint('📊 WeeklyStatsSection: Stats reçues: ${stats.sessionsCount} sessions, ${stats.totalCalories} kcal, ${stats.totalDistance} km');
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ WeeklyStatsSection: Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          // Fallback vers des stats vides
          _stats = const CardioWeeklyStats(
            totalDistance: 0,
            totalDuration: Duration.zero,
            totalCalories: 0,
            sessionsCount: 0,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
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
                  Text(
                    'cardio_this_week'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_stats != null)
                Row(
                  children: [
                    Expanded(
                      child: WeeklyStatCard(
                        title: _stats!.distanceText,
                        subtitle: 'cardio_distance'.tr(locService.currentLanguageCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WeeklyStatCard(
                        title: _stats!.durationText,
                        subtitle: 'cardio_time'.tr(locService.currentLanguageCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WeeklyStatCard(
                        title: _stats!.caloriesText,
                        subtitle: 'cardio_calories'.tr(locService.currentLanguageCode),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Text(
                    'cardio_no_data_available'.tr(locService.currentLanguageCode),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section de sélection d'activités (connectée à Supabase)
class ActivitySelectionSection extends StatefulWidget {
  final Function(CardioActivityType activity) onActivitySelected;

  const ActivitySelectionSection({
    super.key,
    required this.onActivitySelected,
  });

  @override
  State<ActivitySelectionSection> createState() => _ActivitySelectionSectionState();
}

class _ActivitySelectionSectionState extends State<ActivitySelectionSection> {
  List<CardioActivityType> _activities = [];
  bool _loading = true;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locService = LocalizationService.instance;
    if (_currentLanguage != locService.currentLanguageCode) {
      _currentLanguage = locService.currentLanguageCode;
      // Invalider le cache et recharger les activités
      CardioService.invalidateCache();
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    try {
      final locService = LocalizationService.instance;
      final activities = await CardioService.getCardioActivities(language: locService.currentLanguageCode);
      if (mounted) {
        setState(() {
          _activities = activities;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
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
                  Text(
                    'cardio_choose_activity'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_activities.isEmpty)
                Center(
                  child: Text(
                    'cardio_no_activity_available'.tr(locService.currentLanguageCode),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: _activities.map((activity) {
                    return ActivityCard(
                      icon: _getIconFromName(activity.iconName),
                      title: activity.name,
                      onTap: () => widget.onActivitySelected(activity),
                    );
                  }).toList(),
                ),
            ],
          ),
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
}

// Section de la dernière séance (connectée à Supabase)
class LastSessionSection extends StatefulWidget {
  final VoidCallback? onDetailsTap;

  const LastSessionSection({
    super.key,
    this.onDetailsTap,
  });

  @override
  State<LastSessionSection> createState() => _LastSessionSectionState();
}

class _LastSessionSectionState extends State<LastSessionSection> {
  CompletedCardioSession? _lastSession;
  bool _loading = true;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadLastSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locService = LocalizationService.instance;
    if (_currentLanguage != locService.currentLanguageCode) {
      _currentLanguage = locService.currentLanguageCode;
      // Recharger les données pour la nouvelle langue
      _loadLastSession();
    }
  }

  Future<void> _loadLastSession() async {
    try {
      debugPrint('🔍 LastSessionSection: Chargement de la dernière séance...');
      final session = await CardioService.getLastSession();
      if (session != null) {
        debugPrint('🔍 LastSessionSection: Dernière séance trouvée: ${session.activityTitle} - ${session.timeAgo} - ${session.caloriesText}');
      } else {
        debugPrint('🔍 LastSessionSection: Aucune séance trouvée');
      }
      if (mounted) {
        setState(() {
          _lastSession = session;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ LastSessionSection: Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
        key: widget.key, // ✅ Transférer la key à la CustomCard pour le tutorial
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'cardio_last_session'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_lastSession != null)
                _buildSessionContent(_lastSession!, locService)
              else
                Center(
                  child: Text(
                    'cardio_no_session_recorded'.tr(locService.currentLanguageCode),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionContent(CompletedCardioSession session, LocalizationService locService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Informations principales
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.activityTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.timeAgo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Grille des données
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetric('cardio_duration'.tr(locService.currentLanguageCode), session.durationText, LucideIcons.clock),
                  ),
                  if (session.distance != null && session.distance! > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetric('cardio_distance'.tr(locService.currentLanguageCode), session.distanceText, LucideIcons.mapPin),
                    ),
                  ] else if (session.intensity != null && session.intensity!.isNotEmpty) ...[
                    // Afficher l'intensité si pas de distance
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetric('cardio_intensity_label'.tr(locService.currentLanguageCode), session.intensity!, LucideIcons.zap),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetric('cardio_calories'.tr(locService.currentLanguageCode), session.caloriesText, LucideIcons.flame),
                  ),
                  if (session.paceText.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetric('cardio_pace'.tr(locService.currentLanguageCode), session.paceText, LucideIcons.gauge),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0B132B)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
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
}

// Section des sessions de la semaine (connectée à Supabase)
class WeekSessionsSection extends StatefulWidget {
  const WeekSessionsSection({super.key});

  @override
  State<WeekSessionsSection> createState() => _WeekSessionsSectionState();
}

class _WeekSessionsSectionState extends State<WeekSessionsSection> {
  List<CompletedCardioSession> _sessions = [];
  bool _loading = true;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadWeekSessions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locService = LocalizationService.instance;
    if (_currentLanguage != locService.currentLanguageCode) {
      _currentLanguage = locService.currentLanguageCode;
      // Recharger les données pour la nouvelle langue
      _loadWeekSessions();
    }
  }

  Future<void> _loadWeekSessions() async {
    try {
      debugPrint('📋 WeekSessionsSection: Chargement des séances de la semaine...');
      final sessions = await CardioService.getWeekSessions();
      debugPrint('📋 WeekSessionsSection: ${sessions.length} séance(s) trouvée(s)');
      for (var i = 0; i < sessions.length; i++) {
        final s = sessions[i];
        debugPrint('   [$i] ${s.activityTitle} - ${s.timeAgo} - ${s.caloriesText}');
      }
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ WeekSessionsSection: Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final locService = LocalizationService.instance;

    // Afficher confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_session'.tr(locService.currentLanguageCode)),
        content: Text('delete_session_confirm'.tr(locService.currentLanguageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'cancel'.tr(locService.currentLanguageCode),
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'delete'.tr(locService.currentLanguageCode),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Supprimer la séance de l'historique
      await CardioService.deleteCardioSession(sessionId);

      // Suppression bidirectionnelle: supprimer aussi du planificateur si lié
      try {
        final linkedPlanned = await WeeklyPlannerService.findPlannedCardioBySessionId(sessionId);
        if (linkedPlanned != null) {
          await WeeklyPlannerService.deletePlannedActivity(linkedPlanned.id);
          debugPrint('✅ Suppression planificateur cardio liée effectuée');
        }
      } catch (plannerError) {
        debugPrint('⚠️ Erreur suppression planificateur cardio: $plannerError');
      }

      // Recharger la liste
      await _loadWeekSessions();

      // Afficher message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_session_success'.tr(locService.currentLanguageCode)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression cardio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_session_error'.tr(locService.currentLanguageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.activity,
                    size: 20,
                    color: Color(0xFF0B132B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'cardio_week_sessions'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_sessions.isEmpty)
                Text(
                  'cardio_no_session_this_week'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                )
              else
                // Liste des séances
                ..._sessions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final session = entry.value;
                  final isLast = index == _sessions.length - 1;
                  
                  return Column(
                    children: [
                      _buildWeekSessionItem(session, locService),
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
      ),
    );
  }

  Widget _buildWeekSessionItem(CompletedCardioSession session, LocalizationService locService) {
    return Row(
      children: [
        // Petite icône simple sans encadré
        Icon(
          _getActivityIcon(session.activityType),
          color: const Color(0xFF0B132B),
          size: 20,
        ),

        const SizedBox(width: 12),

        // Informations de la séance
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre : HIIT - Tabata (activityTitle - formatTitle)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: session.activityTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    TextSpan(
                      text: ' - ${session.formatTitle}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Jour de la semaine
              Text(
                _getDayText(session.startTime, locService),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSessionStat(LucideIcons.clock, session.durationText),
                  if (session.distance != null && session.distance! > 0) ...[
                    const SizedBox(width: 16),
                    _buildSessionStat(LucideIcons.mapPin, session.distanceText),
                  ] else if (session.intensity != null && session.intensity!.isNotEmpty) ...[
                    // Afficher l'intensité si pas de distance
                    const SizedBox(width: 16),
                    _buildSessionStat(LucideIcons.zap, session.intensity!),
                  ],
                  const SizedBox(width: 16),
                  _buildSessionStat(LucideIcons.flame, session.caloriesText),
                ],
              ),
            ],
          ),
        ),

        // Bouton de suppression
        GestureDetector(
          onTap: () => _deleteSession(session.id),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  String _getDayText(DateTime date, LocalizationService locService) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'cardio_today'.tr(locService.currentLanguageCode);
    if (difference == 1) return 'cardio_yesterday'.tr(locService.currentLanguageCode);
    
    final weekDays = ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'];
    return weekDays[date.weekday - 1].tr(locService.currentLanguageCode);
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'running':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'walking':
        return LucideIcons.footprints;
      case 'hiit':
        return LucideIcons.flame;
      default:
        return LucideIcons.activity;
    }
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
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Container(
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
                'cardio_choose_session_format'.tr(locService.currentLanguageCode),
                style: const TextStyle(
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

  String _getConfigTitle(String type, String languageCode) {
    final configs = CardioData.getLocalizedActivityConfigs(languageCode);
    return configs[type]?.title ?? '';
  }

  String _getConfigHint(String type, String languageCode) {
    final configs = CardioData.getLocalizedActivityConfigs(languageCode);
    return configs[type]?.hint ?? '';
  }

  String _getConfigUnit(String type, String languageCode) {
    final configs = CardioData.getLocalizedActivityConfigs(languageCode);
    return configs[type]?.unit ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Padding(
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
                _getConfigTitle(config.type, locService.currentLanguageCode),
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
                    child: NumericTextField(
                      controller: controller,
                      allowDecimals: false,
                      decoration: InputDecoration(
                        hintText: _getConfigHint(config.type, locService.currentLanguageCode),
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
                      _getConfigUnit(config.type, locService.currentLanguageCode),
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
                  child: Text(
                    'cardio_validate'.tr(locService.currentLanguageCode),
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
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Container(
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
              'cardio_how_record_session'.tr(locService.currentLanguageCode),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.play, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'cardio_start_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.pencil, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'cardio_declare_session'.tr(locService.currentLanguageCode),
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
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Center(
        child: TextButton(
          onPressed: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: Color(0xFF0B132B),
              ),
              const SizedBox(width: 8),
              Text(
                'cardio_view_journal'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0B132B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
