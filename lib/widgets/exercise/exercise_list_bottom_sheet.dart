import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../services/workout_cache_service.dart';
import '../../services/unit_service.dart';
import 'exercise_detail_page.dart';

class ExerciseListBottomSheet extends StatefulWidget {
  const ExerciseListBottomSheet({super.key});

  @override
  State<ExerciseListBottomSheet> createState() => _ExerciseListBottomSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseListBottomSheet(),
    );
  }
}

class _ExerciseListBottomSheetState extends State<ExerciseListBottomSheet> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _items = []; _loading = false; });
        return;
      }

      final locService = LocalizationService.instance;
      final suffix = locService.getColumnSuffix();
      
      // Récupérer d'abord toutes les données workout_set_history
      final historyRows = await client
          .from('workout_set_history')
          .select('history_session_id, exercise_name, exercise_id, custom_exercise_id, weight, reps, performed_at, best_set')
          .eq('user_id', userId)
          .order('performed_at', ascending: false);

      // Récupérer tous les exercices système avec noms localisés
      final exercisesMap = <String, String>{};
      final exerciseRows = await client
          .from('exercises')
          .select('id, name$suffix');
      for (final row in exerciseRows) {
        exercisesMap[row['id']] = row['name$suffix'] ?? '';
      }

      // Récupérer tous les exercices custom
      final customExercisesMap = <String, String>{};
      final customRows = await client
          .from('custom_exercises')
          .select('id, name');
      for (final row in customRows) {
        customExercisesMap[row['id']] = row['name'] ?? '';
      }

      // Combiner les données avec les noms localisés
      final rows = historyRows.map((row) {
        String localizedName = '';
        
        // Priorité 1: exercice système avec nom localisé
        if (row['exercise_id'] != null && exercisesMap.containsKey(row['exercise_id'])) {
          localizedName = exercisesMap[row['exercise_id']]!;
        }
        // Priorité 2: exercice custom
        else if (row['custom_exercise_id'] != null && customExercisesMap.containsKey(row['custom_exercise_id'])) {
          localizedName = customExercisesMap[row['custom_exercise_id']]!;
        }
        // Priorité 3: nom brut dans exercise_name
        else {
          localizedName = row['exercise_name']?.toString() ?? '';
        }
        
        return {
          ...row,
          'localized_exercise_name': localizedName,
        };
      }).toList();

      final Map<String, Map<String, dynamic>> agg = {};
      if (rows is List) {
        for (final r in rows) {
          // Utiliser le nom localisé que nous avons calculé
          String name = (r['localized_exercise_name']?.toString() ?? '').trim();
          
          if (name.isEmpty) continue;
          final sid = r['history_session_id']?.toString() ?? '';
          final performedAt = DateTime.tryParse(r['performed_at']?.toString() ?? '');
          final weight = (r['weight'] as num?)?.toDouble() ?? 0.0;
          final reps = (r['reps'] as int?) ?? 0;
          final isBest = (r['best_set'] as bool?) ?? false;

          final current = agg[name] ?? {
            'name': name,
            'sessionsSet': <String>{}, // distinct session ids
            'lastWeightLabel': 'N/A',
            'lastSeen': DateTime.fromMillisecondsSinceEpoch(0),
            'perSession': <String, Map<String, dynamic>>{},
          };

          if (performedAt != null && sid.isNotEmpty) {
            (current['sessionsSet'] as Set<String>).add(sid);
            final Map<String, dynamic> perSess = (current['perSession'] as Map<String, dynamic>)[sid] ?? {
              'date': performedAt,
              'weight': 0.0,
              'reps': 0,
              'score': 0.0,
              'isBest': false,
            };
            final double score = weight > 0 ? (weight * reps) : reps.toDouble();
            if (isBest || (!perSess['isBest'] && score > (perSess['score'] as double))) {
              perSess['date'] = performedAt;
              perSess['weight'] = weight;
              perSess['reps'] = reps;
              perSess['score'] = score;
              perSess['isBest'] = isBest || perSess['isBest'];
              (current['perSession'] as Map<String, dynamic>)[sid] = perSess;
            } else {
              (current['perSession'] as Map<String, dynamic>)[sid] = perSess;
            }
          }

          agg[name] = current;
        }
      }

      String _fmtWeight(double w) {
        if (w <= 0) return '';
        return UnitService.instance.formatWeight(w, decimals: (w % 1).abs() < 1e-6 ? 0 : 1);
      }

      final list = agg.values.map((m) {
        final sessionsCount = (m['sessionsSet'] as Set<String>).length;
        // Trouver la session la plus récente et son best
        String label = 'N/A';
        DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
        (m['perSession'] as Map<String, dynamic>).forEach((sid, data) {
          final dt = data['date'] as DateTime;
          if (dt.isAfter(latest)) {
            latest = dt;
            final w = (data['weight'] as double);
            final r = (data['reps'] as int);
            label = w > 0 ? _fmtWeight(w) : (r > 0 ? '$r reps' : 'N/A');
          }
        });

        return {
          'name': m['name'],
          'sessions': sessionsCount,
          'lastWeight': label,
          'progress': '',
        };
      }).where((e) => (e['sessions'] as int) > 0).toList()
        ..sort((a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));

      setState(() { _items = list; _loading = false; });
    } catch (_) {
      setState(() { _items = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header avec indicateur de drag
          Container(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Titre et bouton fermer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'tracked_exercises'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'select_exercise_to_view_progress'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des exercices
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final exercise = _items[index];
                      return _buildExerciseItem(context, exercise);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(BuildContext context, Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context); // Fermer le bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailPage(exerciseName: exercise['name'] as String),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'sessions_count'.tr(locService.currentLanguageCode)
                              .replaceAll('{count}', exercise['sessions'].toString()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      exercise['lastWeight'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      exercise['progress'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseListBottomSheet(),
    );
  }
} 
