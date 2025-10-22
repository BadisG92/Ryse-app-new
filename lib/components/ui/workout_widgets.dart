import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sport_models.dart';
import 'sport_cards.dart';
import '../../widgets/exercise/exercise_list_bottom_sheet.dart';
import '../../services/workout_cache_service.dart';
import '../../services/sport_dashboard_service.dart';
import '../../services/global_state_manager.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import 'package:provider/provider.dart';

// Section principale des statistiques de la semaine
class WeeklyStatsSection extends StatefulWidget {
  const WeeklyStatsSection({super.key});

  @override
  State<WeeklyStatsSection> createState() => _WeeklyStatsSectionState();
}

class _WeeklyStatsSectionState extends State<WeeklyStatsSection> with GlobalStateListener<WeeklyStatsSection> {
  WeeklyStats? _stats;
  bool _loading = true;

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // Rafraîchir quand les données sport changent
    _loadWeeklyStats();
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _stats = const WeeklyStats(sessions: '0', weight: '0 kg', calories: '0 kcal');
          _loading = false;
        });
        return;
      }

      // Utilise le service de cache optimisé
      final statsData = await WorkoutCacheService.getWeeklyStats(userId);

      final sessions = (statsData['sessions'] ?? 0).toString();
      final totalVolume = (statsData['total_volume'] ?? 0).toDouble();
      final totalCalories = (statsData['total_calories'] ?? 0).toString();

      setState(() {
        _stats = WeeklyStats(
          sessions: sessions,
          weight: '${totalVolume.toStringAsFixed(0)} kg',
          calories: '$totalCalories kcal',
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ WeeklyStats error: $e');
      setState(() {
        _stats = const WeeklyStats(sessions: '0', weight: '0 kg', calories: '0 kcal');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const WeeklyStatsCard(
        stats: WeeklyStats(sessions: '—', weight: '—', calories: '—'),
      );
    }
    return WeeklyStatsCard(stats: _stats!);
  }
}

// Section historique des séances de la semaine
class WeekHistorySection extends StatefulWidget {
  const WeekHistorySection({super.key});

  @override
  State<WeekHistorySection> createState() => _WeekHistorySectionState();
}

class _WeekHistorySectionState extends State<WeekHistorySection> with GlobalStateListener<WeekHistorySection> {
  List<WorkoutSession> _sessions = const [];
  bool _loading = true;

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    debugPrint('🔄 WeekHistorySection: GlobalState mis à jour, rechargement historique...');
    _loadWeekHistory();
  }

  @override
  void initState() {
    super.initState();
    _loadWeekHistory();
  }

  Future<void> _loadWeekHistory() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _sessions = const []; _loading = false; });
        return;
      }

      // Utilise le service de cache optimisé
      final sessionsData = await WorkoutCacheService.getWeeklyHistory(userId);
      final now = DateTime.now();

      final List<WorkoutSession> result = [];
      for (final s in sessionsData) {
        final sessionId = s['id']?.toString(); // ⚡ FIX: Use 'id' (primary key), not 'history_session_id'
        final name = s['session_name']?.toString() ?? '';
        final performedAt = DateTime.tryParse(s['performed_at']?.toString() ?? '') ?? now;
        final calories = (s['calories_burned'] as int?) ?? 0;
        final dayLabel = _dayLabel(performedAt.weekday);
        final lastUsed = _relativeDays(performedAt);
        final durationMin = (s['duration_minutes'] as int?) ?? 0;
        final totalVolume = (s['total_volume_kg'] as num?)?.toDouble() ?? 0.0;

        // Traite les exercices déjà agrégés
        final exercises = s['exercises'] as List? ?? [];
        final items = exercises.map((e) {
          final bestWeight = (e['best_weight'] as num?)?.toDouble();
          final bestReps = (e['best_reps'] as int?) ?? 0;
          final setsCount = (e['sets_count'] as int?) ?? 0;

          return SessionExerciseBest(
            name: e['localized_exercise_name']?.toString() ?? e['exercise_name']?.toString() ?? '',
            setsCount: setsCount,
            reps: bestReps,
            weightKg: bestWeight,
          );
        }).toList();

        result.add(WorkoutSession(
          sessionId: sessionId,
          name: name,
          day: dayLabel,
          calories: calories,
          durationMinutes: durationMin,
          totalVolumeKg: totalVolume,
          items: items,
          lastUsed: lastUsed,
        ));
      }

      setState(() { _sessions = result; _loading = false; });
    } catch (e) {
      debugPrint('❌ WeekHistory error: $e');
      setState(() { _sessions = const []; _loading = false; });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      debugPrint('🗑️ Suppression de la séance de musculation: $sessionId');

      final db = Supabase.instance.client;
      final userId = db.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // ⚡ SIMPLIFIÉ: Grâce à ON DELETE CASCADE, supprimer le résumé supprime automatiquement les sets!
      await db
          .from('workout_session_summaries')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', userId);

      debugPrint('✅ Séance supprimée avec succès (CASCADE a supprimé les sets automatiquement)');

      // Invalider TOUS les caches
      WorkoutCacheService.invalidateUserCache(userId);
      SportDashboardService.invalidateCache();
      GlobalStateManager.instance.invalidateWeeklyData();

      // Recharger les séances
      await _loadWeekHistory();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.instance.currentLanguageCode == 'fr'
                  ? 'Séance supprimée avec succès'
                  : 'Session deleted successfully'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.instance.currentLanguageCode == 'fr'
                  ? 'Erreur lors de la suppression de la séance'
                  : 'Error deleting session'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _dayLabel(int weekday) {
    final locService = LocalizationService.instance;
    switch (weekday) {
      case DateTime.monday:
        return 'workout_monday'.tr(locService.currentLanguageCode);
      case DateTime.tuesday:
        return 'workout_tuesday'.tr(locService.currentLanguageCode);
      case DateTime.wednesday:
        return 'workout_wednesday'.tr(locService.currentLanguageCode);
      case DateTime.thursday:
        return 'workout_thursday'.tr(locService.currentLanguageCode);
      case DateTime.friday:
        return 'workout_friday'.tr(locService.currentLanguageCode);
      case DateTime.saturday:
        return 'workout_saturday'.tr(locService.currentLanguageCode);
      case DateTime.sunday:
      default:
        return 'workout_sunday'.tr(locService.currentLanguageCode);
    }
  }

  static String _relativeDays(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    final locService = LocalizationService.instance;
    if (diff <= 0) return 'workout_today'.tr(locService.currentLanguageCode);
    if (diff == 1) return 'workout_one_day_ago'.tr(locService.currentLanguageCode);
    return 'workout_days_ago'.tr(locService.currentLanguageCode).replaceAll('{count}', '$diff');
  }

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
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_week_history'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_sessions.isEmpty)
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_no_session_this_week'.tr(locService.currentLanguageCode),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else ..._sessions.map((s) => WorkoutHistoryCard(
              session: s,
              onDelete: _deleteSession,
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// Section progression des exercices
class ExerciseProgressSection extends StatefulWidget {
  const ExerciseProgressSection({super.key});

  @override
  State<ExerciseProgressSection> createState() => _ExerciseProgressSectionState();
}

class _ExerciseProgressSectionState extends State<ExerciseProgressSection> with GlobalStateListener<ExerciseProgressSection> {
  List<ExerciseProgress> _exercises = [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // Rafraîchir quand les données sport changent
    _loadExerciseProgress();
  }

  @override
  void initState() {
    super.initState();
    _loadExerciseProgress();
  }

  Future<void> _loadExerciseProgress() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _exercises = [];
          _loading = false;
        });
        return;
      }

      // Utilise le service de cache optimisé
      final exercisesData = await WorkoutCacheService.getTopExercises(userId);

      final allExercises = exercisesData.map<ExerciseProgress>((e) {
        return ExerciseProgress(
          name: e['localized_name']?.toString() ?? e['name']?.toString() ?? '',
          current: e['current']?.toString() ?? 'N/A',
          progress: '', // Pas de calcul de progression pour l'instant
          sessions: (e['sessions'] as int?) ?? 0,
        );
      }).where((ex) => ex.sessions > 0 && ex.name.trim().isNotEmpty).toList();

      setState(() {
        _exercises = allExercises;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading exercise progress: $e');
      setState(() {
        _exercises = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedExercises = _showAll ? _exercises : _exercises.take(5).toList();
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.trendingUp,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                    const SizedBox(width: 12),
                    Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_exercise_progression'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ExerciseListBottomSheet.show(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                  ),
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'workout_see_all'.tr(locService.currentLanguageCode),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_exercises.isEmpty)
              Consumer<LocalizationService>(
                builder: (context, locService, _) => Text(
                  'workout_no_exercise_found'.tr(locService.currentLanguageCode),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              )
            else
              ...displayedExercises.map((progress) => ExerciseProgressCard(progress: progress)).toList(),
          ],
        ),
      ),
    );
  }
}

// Widget pour les stats de session
class SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const SessionStat({
    super.key,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Card de tracking de session
class SessionTrackingCard extends StatelessWidget {
  final String sessionName;
  final DateTime sessionStartTime;
  final List<Map<String, dynamic>> currentExercises;
  final VoidCallback onComplete;

  const SessionTrackingCard({
    super.key,
    required this.sessionName,
    required this.sessionStartTime,
    required this.currentExercises,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duration = now.difference(sessionStartTime);
    final totalSets = currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).length,
    );
    final completedSets = currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).where((set) => (set['reps'] ?? 0) > 0).length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SessionStat(
                      icon: LucideIcons.clock,
                      value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 16),
                    SessionStat(
                      icon: LucideIcons.dumbbell,
                      value: '${currentExercises.length} ${'workout_exercises'.tr(LocalizationService.instance.currentLanguageCode)}',
                    ),
                    const SizedBox(width: 16),
                    SessionStat(
                      icon: LucideIcons.check,
                      value: '$completedSets/$totalSets ${'workout_sets'.tr(LocalizationService.instance.currentLanguageCode)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B132B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_finish'.tr(locService.currentLanguageCode),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bouton principal pour commencer une séance
class StartSessionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartSessionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, _) => Text(
                'workout_start_session_button'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.play, size: 20),
                    const SizedBox(width: 8),
                    Consumer<LocalizationService>(
                      builder: (context, locService, _) => Text(
                        'workout_start_session_button'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
