import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sport_models.dart';
import 'sport_cards.dart';
import '../../widgets/exercise/exercise_list_bottom_sheet.dart';

// Section principale des statistiques de la semaine
class WeeklyStatsSection extends StatefulWidget {
  const WeeklyStatsSection({super.key});

  @override
  State<WeeklyStatsSection> createState() => _WeeklyStatsSectionState();
}

class _WeeklyStatsSectionState extends State<WeeklyStatsSection> {
  WeeklyStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _stats = const WeeklyStats(sessions: '0', weight: '0 kg', calories: '0');
          _loading = false;
        });
        return;
      }

      final now = DateTime.now();
      // Lundi = 1, ... Dimanche = 7 → début de semaine = lundi
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final startOfWeek = todayMidnight.subtract(Duration(days: (now.weekday - 1)));
      final startIso = startOfWeek.toIso8601String();

      // Get unique history_session_ids from workout_set_history for this week
      final uniqueSessionIds = await client
          .from('workout_set_history')
          .select('history_session_id')
          .eq('user_id', userId)
          .gte('performed_at', startIso);

      // Debug
      // ignore: avoid_print
      print('📊 WeeklyStats: Found ${uniqueSessionIds is List ? uniqueSessionIds.length : 'null'} workout_set_history records');

      Set<String> sessionIdSet = {};
      if (uniqueSessionIds is List) {
        for (final record in uniqueSessionIds) {
          final sessionId = record['history_session_id']?.toString();
          if (sessionId != null && sessionId.isNotEmpty) {
            sessionIdSet.add(sessionId);
          }
        }
      }

      // ignore: avoid_print
      print('📊 WeeklyStats: ${sessionIdSet.length} unique history_session_ids: ${sessionIdSet.toList()}');

      // Now get summaries for these specific session IDs
      int sessions = 0;
      double totalVolume = 0;
      int totalCalories = 0;

      if (sessionIdSet.isNotEmpty) {
        final rows = await client
            .from('workout_session_summaries')
            .select('history_session_id, duration_minutes, total_volume_kg, calories_burned, session_name')
            .eq('user_id', userId)
            .filter('history_session_id', 'in', '(${sessionIdSet.join(',')})');

        // ignore: avoid_print
        print('📊 WeeklyStats summaries for ${sessionIdSet.length} session IDs -> ${rows is List ? rows.length : 'null'} found');
        // ignore: avoid_print
        print('📊 Summaries: $rows');

        if (rows is List) {
          sessions = rows.length;
          // ignore: avoid_print
          print('📊 Processing ${rows.length} workout sessions:');
          for (final r in rows) {
            final sessionId = r['history_session_id']?.toString() ?? '';
            final sessionName = r['session_name']?.toString() ?? '';
            final volume = ((r['total_volume_kg'] as num?)?.toDouble() ?? 0);
            final calories = (r['calories_burned'] as int?) ?? 0;
            final duration = (r['duration_minutes'] as int?) ?? 0;
            // ignore: avoid_print
            print('  - ID: $sessionId, Name: "$sessionName", Volume: ${volume}kg, Calories: $calories, Duration: ${duration}min');
            totalVolume += volume;
            totalCalories += calories;
          }
          // ignore: avoid_print
          print('📊 TOTALS: Sessions=$sessions, Volume=${totalVolume}kg, Calories=$totalCalories');
        }

        // Check for missing summaries
        final foundSessionIds = (rows as List).map((r) => r['history_session_id']?.toString()).where((id) => id != null).toSet();
        final missingIds = sessionIdSet.difference(foundSessionIds.cast<String>());
        if (missingIds.isNotEmpty) {
          // ignore: avoid_print
          print('⚠️ Missing summaries for session IDs: $missingIds');
        }
      }

      setState(() {
        _stats = WeeklyStats(
          sessions: sessions.toString(),
          weight: '${totalVolume.toStringAsFixed(0)} kg',
          calories: totalCalories.toString(),
        );
        _loading = false;
      });
    } catch (_) {
      // ignore: avoid_print
      print('❌ WeeklyStats error');
      setState(() {
        _stats = const WeeklyStats(sessions: '0', weight: '0 kg', calories: '0');
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

class _WeekHistorySectionState extends State<WeekHistorySection> {
  List<WorkoutSession> _sessions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekHistory();
  }

  Future<void> _loadWeekHistory() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _sessions = const []; _loading = false; });
        return;
      }

      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)); // lundi
      final startDateStr = startOfWeek.toIso8601String().split('T').first;

      // Step 1: Get ALL unique history_session_ids from workout_set_history for this week
      final uniqueSessionIds = await client
          .from('workout_set_history')
          .select('history_session_id')
          .eq('user_id', userId)
          .gte('performed_at', startOfWeek.toIso8601String());

      Set<String> sessionIdSet = {};
      if (uniqueSessionIds is List) {
        for (final record in uniqueSessionIds) {
          final sessionId = record['history_session_id']?.toString();
          if (sessionId != null && sessionId.isNotEmpty) {
            sessionIdSet.add(sessionId);
          }
        }
      }

      // Debug
      // ignore: avoid_print
      print('🗓️ WeekHistory: Found ${uniqueSessionIds is List ? uniqueSessionIds.length : 'null'} workout_set_history records');
      // ignore: avoid_print
      print('🗓️ WeekHistory: ${sessionIdSet.length} unique history_session_ids: ${sessionIdSet.toList()}');

      List<dynamic> summaries = [];
      if (sessionIdSet.isNotEmpty) {
        // Step 2: Get summaries for these specific session IDs
        summaries = await client
            .from('workout_session_summaries')
            .select('history_session_id, session_name, performed_at, calories_burned, duration_minutes, total_volume_kg')
            .eq('user_id', userId)
            .filter('history_session_id', 'in', '(${sessionIdSet.join(',')})')
            .order('performed_at', ascending: false);
      }

      // Debug
      // ignore: avoid_print
      print('🗓️ WeekHistory summaries for ${sessionIdSet.length} session IDs -> ${summaries is List ? summaries.length : 'null'} found');
      // ignore: avoid_print
      print('🗓️ Summaries: $summaries');

      // Check for missing summaries
      if (summaries is List) {
        final foundSessionIds = summaries.map((s) => s['history_session_id']?.toString()).where((id) => id != null).toSet();
        final missingIds = sessionIdSet.difference(foundSessionIds.cast<String>());
        if (missingIds.isNotEmpty) {
          // ignore: avoid_print
          print('⚠️ WeekHistory: Missing summaries for session IDs: $missingIds');
        }
      }

      final List<WorkoutSession> result = [];
      if (summaries is List) {
        // ignore: avoid_print
        print('🗓️ Processing ${summaries.length} session summaries for WeekHistory:');
        for (final s in summaries) {
          final sessionId = s['history_session_id']?.toString();
          final name = s['session_name']?.toString() ?? '';
          final performedAt = DateTime.tryParse(s['performed_at']?.toString() ?? '') ?? now;
          final calories = (s['calories_burned'] as int?) ?? 0;
          final dayLabel = _dayLabel(performedAt.weekday);
          final lastUsed = _relativeDays(performedAt);
          final durationMin = (s['duration_minutes'] as int?) ?? 0;
          final totalVolume = (s['total_volume_kg'] as num?)?.toDouble() ?? 0.0;
          
          // ignore: avoid_print
          print('  📝 Processing: "$name" (ID: $sessionId) - ${performedAt.toString()} - ${totalVolume}kg');

          // Fetch aggregated exercises for this session
          final List<dynamic> sets = sessionId == null
              ? const []
              : await client
                  .from('workout_set_history')
                  // Pas de jointures; on lit aussi weight et best_set
                  .select('exercise_name, reps, weight, best_set')
                  .eq('history_session_id', sessionId)
                  .limit(200);

          // ignore: avoid_print
          print('  • Session $sessionId -> sets: ${sets is List ? sets.length : 'null'}');

          final Map<String, Map<String, dynamic>> agg = {};
          if (sets is List) {
            for (final r in sets) {
              final String title = (r['exercise_name']?.toString() ?? '').trim();
              
              if (title.isEmpty) continue;
              final reps = (r['reps'] as int?) ?? 0;
              final weight = (r['weight'] as num?)?.toDouble();
              final isBest = (r['best_set'] as bool?) ?? false;
              final current = agg[title] ?? {'series': 0, 'reps': 0, 'best': null};
              current['series'] = (current['series'] ?? 0) + 1;
              current['reps'] = (current['reps'] ?? 0) + reps;
              if (isBest) {
                current['best'] = {'weight': weight, 'reps': reps};
              }
              agg[title] = current;
            }
          }

          final items = agg.entries.map((e) {
            final series = e.value['series'] as int? ?? 0;
            final best = e.value['best'] as Map<String, dynamic>?;
            final bestReps = best?['reps'] as int? ?? 0;
            final bestWeight = (best?['weight'] as num?)?.toDouble();
            return SessionExerciseBest(
              name: e.key,
              setsCount: series,
              reps: bestReps,
              weightKg: bestWeight,
            );
          }).toList();

          // ignore: avoid_print
          print('  ✓ Add session card: name=$name day=$dayLabel kcal=$calories exercises=${items.length}');

          result.add(WorkoutSession(
            name: name,
            day: dayLabel,
            calories: calories,
            durationMinutes: durationMin,
            totalVolumeKg: totalVolume,
            items: items,
            lastUsed: lastUsed,
          ));
        }
      }

      // ignore: avoid_print
      print('✅ WeekHistory built ${result.length} items');
      setState(() { _sessions = result; _loading = false; });
    } catch (_) {
      setState(() { _sessions = const []; _loading = false; });
    }
  }

  static String _dayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lundi';
      case DateTime.tuesday:
        return 'Mardi';
      case DateTime.wednesday:
        return 'Mercredi';
      case DateTime.thursday:
        return 'Jeudi';
      case DateTime.friday:
        return 'Vendredi';
      case DateTime.saturday:
        return 'Samedi';
      case DateTime.sunday:
      default:
        return 'Dimanche';
    }
  }

  static String _relativeDays(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff <= 0) return "Aujourd'hui";
    if (diff == 1) return 'Il y a 1 jour';
    return 'Il y a $diff jours';
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
                const Text(
                  'Historique de la semaine',
                  style: TextStyle(
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
              const Text('Aucune séance cette semaine', style: TextStyle(color: Color(0xFF64748B)))
            else ..._sessions.map((s) => WorkoutHistoryCard(session: s)).toList(),
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

class _ExerciseProgressSectionState extends State<ExerciseProgressSection> {
  List<ExerciseProgress> _exercises = [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadExerciseProgress();
  }

  Future<void> _loadExerciseProgress() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _exercises = [];
          _loading = false;
        });
        return;
      }

      // Requête pour récupérer les stats par exercice avec history_session_id
      final exerciseStats = await client
          .from('workout_set_history')
          .select('exercise_name, weight, reps, performed_at, best_set, history_session_id')
          .eq('user_id', userId)
          .order('performed_at', ascending: false);

      final Map<String, Map<String, dynamic>> aggByExercise = {};
      
      if (exerciseStats is List) {
        for (final row in exerciseStats) {
          final exerciseName = row['exercise_name']?.toString()?.trim() ?? '';
          final sessionId = row['history_session_id']?.toString() ?? '';
          if (exerciseName.isEmpty || sessionId.isEmpty) continue;

          final current = aggByExercise[exerciseName] ?? {
            'sessions': <String>{}, // Set des history_session_id uniques
            'lastBestWeight': null,
            'lastBestReps': 0,
            'performedAt': null,
          };

          // Compter les sessions uniques via history_session_id
          (current['sessions'] as Set<String>).add(sessionId);

          // Récupérer le dernier best set et la date la plus récente
          final performedAt = DateTime.tryParse(row['performed_at']?.toString() ?? '');
          final isBest = row['best_set'] as bool? ?? false;
          
          if (isBest) {
            final weight = (row['weight'] as num?)?.toDouble();
            final reps = row['reps'] as int? ?? 0;
            
            // Mettre à jour si c'est le premier best ou si c'est plus récent
            if (current['performedAt'] == null || 
                (performedAt != null && performedAt.isAfter(current['performedAt'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0)))) {
              current['lastBestWeight'] = weight;
              current['lastBestReps'] = reps;
              current['performedAt'] = performedAt;
            }
          }

          aggByExercise[exerciseName] = current;
        }
      }

      String _fmtWeight(double w) {
        if (w <= 0) return '';
        if ((w % 1).abs() < 1e-6) {
          return '${w.toInt()} kg';
        }
        return '${w.toStringAsFixed(1)} kg';
      }

      // Transformer en modèle ExerciseProgress
      final allExercises = aggByExercise.entries.map((e) {
        final sessions = (e.value['sessions'] as Set<String>).length;
        final lastWeight = e.value['lastBestWeight'] as double?;
        final lastReps = e.value['lastBestReps'] as int? ?? 0;
        
        String current = '';
        if (lastWeight != null && lastWeight > 0) {
          current = _fmtWeight(lastWeight);
        } else if (lastReps > 0) {
          current = '$lastReps reps';
        } else {
          current = 'N/A';
        }

        return ExerciseProgress(
          name: e.key,
          current: current,
          progress: '', // Pas de calcul de progression pour l'instant
          sessions: sessions,
        );
      }).where((ex) => ex.sessions > 0).toList();

      // Trier par nombre de sessions décroissant
      allExercises.sort((a, b) => b.sessions.compareTo(a.sessions));

      // Debug
      // ignore: avoid_print
      print('🏆 Top exercices par fréquence:');
      for (int i = 0; i < allExercises.length && i < 10; i++) {
        final ex = allExercises[i];
        // ignore: avoid_print
        print('  ${i + 1}. ${ex.name}: ${ex.sessions} séances - ${ex.current}');
      }

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
                    const Text(
                      'Top exercices par fréquence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
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
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_exercises.isEmpty)
              const Text('Aucun exercice trouvé', style: TextStyle(color: Color(0xFF64748B)))
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
      (sum, exercise) => sum + (exercise['sets'] as List).where((set) => set['completed'] == true).length,
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
                      value: '${currentExercises.length} exercices',
                    ),
                    const SizedBox(width: 16),
                    SessionStat(
                      icon: LucideIcons.check,
                      value: '$completedSets/$totalSets séries',
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
            child: const Text(
              'Terminer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
            const Text(
              'Commencer une séance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.play, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Commencer une séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
