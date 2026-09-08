import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'exercise_resolver.dart';
import 'localization_service.dart';
import 'unit_service.dart';

/// Cache entry avec timestamp pour TTL
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  
  _CacheEntry(this.data, this.timestamp, this.ttl);
  
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Service de cache unifié pour optimiser les performances de la section musculation
/// sans impacter l'UI existante
class WorkoutCacheService {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultTTL = Duration(minutes: 5);
  static const Duration _exerciseDetailTTL = Duration(minutes: 10);
  
  static final _client = Supabase.instance.client;
  
  /// Récupère le nom localisé d'un exercice de façon optimisée
  static Future<String> getLocalizedExerciseName(String exerciseName) async {
    try {
      final locService = LocalizationService.instance;
      
      // Chercher l'exercice dans la table exercises avec un seul appel
      final exerciseData = await _client
        .from('exercises')
        .select('name_fr, name_en, name_de')
        .or('name_fr.eq.$exerciseName,name_en.eq.$exerciseName,name_de.eq.$exerciseName')
        .limit(1)
        .maybeSingle();

      if (exerciseData != null) {
        return locService.getTextFromColumns(
          exerciseData['name_fr'],
          exerciseData['name_en'],
          exerciseData['name_de']
        );
      } else {
        // Fallback : chercher dans les exercices custom
        final customExerciseData = await _client
          .from('custom_exercises')
          .select('name')
          .eq('name', exerciseName)
          .limit(1)
          .maybeSingle();
          
        return customExerciseData?['name'] ?? exerciseName;
      }
    } catch (e) {
      return exerciseName;
    }
  }
  
  /// Récupère les données du dashboard hebdomadaire (optimisé)
  static Future<Map<String, dynamic>> getWeeklyDashboardData(String userId) async {
    final key = 'weekly_dashboard_$userId';
    final cached = _cache[key];

    if (cached != null && !cached.isExpired) {
      return cached.data as Map<String, dynamic>;
    }

    try {
      // Calculer la semaine courante (lundi-dimanche) en heure LOCALE de l'utilisateur
      final now = DateTime.now(); // Heure locale
      final weekday = now.weekday; // 1=Lundi, 7=Dimanche
      final mondayThisWeek = now.subtract(Duration(days: weekday - 1));
      final weekStart = DateTime(mondayThisWeek.year, mondayThisWeek.month, mondayThisWeek.day);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      final weekEndStr = weekEnd.toIso8601String().split('T')[0];

      if (kDebugMode) debugPrint('📅 Musculation: Semaine courante (locale utilisateur): $weekStartStr -> $weekEndStr');

      // Utilise la fonction PostgreSQL optimisée avec les dates calculées
      final result = await _client.rpc('get_weekly_dashboard_data',
        params: {
          'target_user_id': userId,
          'week_start_date': weekStartStr,
          'week_end_date': weekEndStr,
        });

      final rawData = result as Map<String, dynamic>;

      // Localiser les noms d'exercices dans weekly_sessions
      final weeklySessions = rawData['weekly_sessions'] as List<dynamic>? ?? [];
      final localizedSessions = await _localizeWeeklySessionsData(weeklySessions);

      final data = {
        ...rawData,
        'weekly_sessions': localizedSessions,
      };

      _cache[key] = _CacheEntry(data, DateTime.now(), _defaultTTL);

      return data;
    } catch (e) {
      // Fallback sur les données cachées expirées si disponibles
      if (cached != null) {
        return cached.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  /// Localise les noms d'exercices dans les données de sessions hebdomadaires
  /// et récupère les exercices depuis workout_set_history
  static Future<List<dynamic>> _localizeWeeklySessionsData(List<dynamic> sessions) async {
    if (sessions.isEmpty) return sessions;

    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();

    // Récupérer tous les exercices système avec noms localisés
    final exercisesMap = <String, String>{};
    final exerciseRows = await _client
        .from('exercises')
        .select('id, name$suffix');
    for (final row in exerciseRows) {
      exercisesMap[row['id']] = row['name$suffix'] ?? '';
    }

    // Récupérer tous les exercices custom
    final customExercisesMap = <String, String>{};
    final customRows = await _client
        .from('custom_exercises')
        .select('id, name');
    for (final row in customRows) {
      customExercisesMap[row['id']] = row['name'] ?? '';
    }

    // Traiter chaque session
    final result = <Map<String, dynamic>>[];
    for (final session in sessions) {
      if (session is! Map<String, dynamic>) {
        result.add(session as Map<String, dynamic>);
        continue;
      }

      final historySessionId = session['history_session_id']?.toString();
      if (historySessionId == null) {
        result.add(session);
        continue;
      }

      // Récupérer les sets de cette session depuis workout_set_history
      if (kDebugMode) debugPrint('📊 Récupération des exercices pour session $historySessionId');
      final sets = await _client
          .from('workout_set_history')
          .select('exercise_id, custom_exercise_id, exercise_name, weight, reps')
          .eq('history_session_id', historySessionId)
          .order('set_order');

      if (kDebugMode) debugPrint('📊 ${sets.length} sets trouvés pour session $historySessionId');

      // Agréger par exercice (meilleur set par exercice)
      final Map<String, Map<String, dynamic>> exerciseStats = {};

      for (final set in sets) {
        String exerciseName = set['exercise_name']?.toString() ?? '';
        final exerciseId = set['exercise_id']?.toString();
        final customExerciseId = set['custom_exercise_id']?.toString();

        // Obtenir le nom localisé
        String localizedName = exerciseName;
        if (exerciseId != null && exercisesMap.containsKey(exerciseId)) {
          localizedName = exercisesMap[exerciseId]!;
        } else if (customExerciseId != null && customExercisesMap.containsKey(customExerciseId)) {
          localizedName = customExercisesMap[customExerciseId]!;
        }

        final weight = (set['weight'] as num?)?.toDouble() ?? 0;
        final reps = (set['reps'] as int?) ?? 0;

        // Utiliser le nom d'exercice comme clé pour grouper
        final key = exerciseName;

        if (!exerciseStats.containsKey(key)) {
          exerciseStats[key] = {
            'exercise_name': exerciseName,
            'localized_exercise_name': localizedName,
            'best_weight': weight,
            'best_reps': reps,
            'sets_count': 1,
          };
        } else {
          exerciseStats[key]!['sets_count'] = (exerciseStats[key]!['sets_count'] as int) + 1;

          // Mettre à jour le meilleur set (comparaison par poids, puis reps)
          final currentBestWeight = exerciseStats[key]!['best_weight'] as double;
          final currentBestReps = exerciseStats[key]!['best_reps'] as int;

          if (weight > currentBestWeight || (weight == currentBestWeight && reps > currentBestReps)) {
            exerciseStats[key]!['best_weight'] = weight;
            exerciseStats[key]!['best_reps'] = reps;
          }
        }
      }

      // Ajouter la session avec ses exercices
      final exercisesList = exerciseStats.values.toList();
      if (kDebugMode) debugPrint('📊 Session $historySessionId: ${exercisesList.length} exercice(s) agrégé(s)');

      result.add({
        ...session,
        'exercises': exercisesList,
      });
    }

    return result;
  }
  
  /// Récupère les statistiques hebdomadaires (pour WeeklyStatsSection)
  static Future<Map<String, dynamic>> getWeeklyStats(String userId) async {
    final dashboardData = await getWeeklyDashboardData(userId);
    return dashboardData['weekly_stats'] ?? {};
  }
  
  /// Récupère l'historique hebdomadaire (pour WeekHistorySection)
  static Future<List<dynamic>> getWeeklyHistory(String userId) async {
    final dashboardData = await getWeeklyDashboardData(userId);
    return dashboardData['weekly_sessions'] ?? [];
  }
  
  /// Récupère la progression des exercices (pour ExerciseProgressSection)
  static Future<List<dynamic>> getTopExercises(String userId) async {
    final key = 'top_exercises_$userId';
    final cached = _cache[key];
    
    if (cached != null && !cached.isExpired) {
      return cached.data as List<dynamic>;
    }
    
    try {
      final locService = LocalizationService.instance;
      final suffix = locService.getColumnSuffix();
      
      // Requête directe comme dans exercise_list_bottom_sheet.dart
      final historyRows = await _client
          .from('workout_set_history')
          .select('history_session_id, exercise_name, normalized_exercise_name, exercise_id, custom_exercise_id, weight, reps, performed_at')
          .eq('user_id', userId)
          .gte('performed_at', DateTime.now().subtract(const Duration(days: 180)).toIso8601String()) // 6 derniers mois
          .order('performed_at', ascending: false);

      // Récupérer tous les exercices système avec noms localisés
      final exercisesMap = <String, String>{};
      final exerciseRows = await _client
          .from('exercises')
          .select('id, name$suffix');
      for (final row in exerciseRows) {
        exercisesMap[row['id']] = row['name$suffix'] ?? '';
      }

      // Récupérer tous les exercices custom
      final customExercisesMap = <String, String>{};
      final customRows = await _client
          .from('custom_exercises')
          .select('id, name');
      for (final row in customRows) {
        customExercisesMap[row['id']] = row['name'] ?? '';
      }

      // Combiner les données avec les noms localisés et agréger
      final Map<String, Map<String, dynamic>> exerciseStats = {};
      
      for (final row in historyRows) {
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
        
        if (localizedName.trim().isEmpty) continue;

        final sessionId = row['history_session_id']?.toString() ?? '';
        if (sessionId.isEmpty) continue;

        // Le regroupement se fait sur le nom comparable, pas sur le nom
        // affiché.
        //
        // Le nom affiché vient de l'identifiant quand il y en a un, et du nom
        // brut sinon. Deux séries du même exercice, l'une avec identifiant et
        // l'autre sans, produisaient donc deux lignes dans « Tes exercices » —
        // « Curl à la barre · 1 fois » et « Barbell Curl · 1 fois » — et deux
        // détails ne montrant chacun que la moitié des séances.
        //
        // C'est la même clé que la lecture du détail, qui rassemble par
        // `normalized_exercise_name`. Les deux écrans racontent la même chose.
        final groupKey = row['normalized_exercise_name']?.toString().trim().isNotEmpty == true
            ? row['normalized_exercise_name'] as String
            : ExerciseResolver.normalize(localizedName);
        if (groupKey.isEmpty) continue;

        // Initialiser ou récupérer les stats de cet exercice
        if (!exerciseStats.containsKey(groupKey)) {
          exerciseStats[groupKey] = {
            'name': localizedName,
            'localized_name': localizedName,
            'named_from_id': row['exercise_id'] != null || row['custom_exercise_id'] != null,
            'sessions': <String>{},
            'maxWeight': 0.0,
            'maxReps': 0,
          };
        } else if (exerciseStats[groupKey]!['named_from_id'] != true &&
            (row['exercise_id'] != null || row['custom_exercise_id'] != null)) {
          // Le libellé traduit l'emporte sur le nom brut, dès qu'une des
          // séries du groupe en porte un.
          exerciseStats[groupKey]!['name'] = localizedName;
          exerciseStats[groupKey]!['localized_name'] = localizedName;
          exerciseStats[groupKey]!['named_from_id'] = true;
        }

        // Ajouter cette session à la liste
        (exerciseStats[groupKey]!['sessions'] as Set<String>).add(sessionId);

        // La meilleure série, gardée comme une série.
        //
        // Le poids et les répétitions étaient suivis chacun de leur côté, si
        // bien que la liste annonçait la charge d'une série avec les
        // répétitions d'une autre : « 80 kg × 20 » pour quelqu'un qui avait
        // fait 80 kg × 5 puis 40 kg × 20. Une série qui n'a jamais eu lieu.
        //
        // La plus lourde gagne ; à charge égale, celle qui a duré le plus.
        final weight = (row['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (row['reps'] as int?) ?? 0;

        final bestWeight = exerciseStats[groupKey]!['maxWeight'] as double;
        final bestReps = exerciseStats[groupKey]!['maxReps'] as int;

        if (weight > bestWeight || (weight == bestWeight && reps > bestReps)) {
          exerciseStats[groupKey]!['maxWeight'] = weight;
          exerciseStats[groupKey]!['maxReps'] = reps;
        }
      }

      // Convertir en format attendu et trier par nombre de sessions
      final data = exerciseStats.values.map((stats) {
        final sessionsCount = (stats['sessions'] as Set<String>).length;
        final maxWeight = stats['maxWeight'] as double;
        final maxReps = stats['maxReps'] as int;

        return {
          'name': stats['localized_name'],
          'localized_name': stats['localized_name'],
          'sessions': sessionsCount,
          'maxWeight': maxWeight,  // Valeur brute en kg pour formatage côté UI
          'maxReps': maxReps,
        };
      }).where((exercise) => (exercise['sessions'] as int) > 0)
        .toList()
        ..sort((a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));
      
      _cache[key] = _CacheEntry(data, DateTime.now(), _defaultTTL);
      
      return data;
    } catch (e) {
      // Fallback sur les données cachées expirées si disponibles
      if (cached != null) {
        return cached.data as List<dynamic>;
      }
      return [];
    }
  }

  
  /// Récupère les détails d'un exercice spécifique (pour ExerciseDetailPage)
  static Future<Map<String, dynamic>> getExerciseDetails(String userId, String exerciseName) async {
    final key = 'exercise_${userId}_$exerciseName';
    final cached = _cache[key];
    
    if (cached != null && !cached.isExpired) {
      return cached.data as Map<String, dynamic>;
    }
    
    // Debug pour comprendre le problème des données manquantes
    if (exerciseName.toLowerCase().contains('squat')) {
      await debugExerciseData(userId);
    }
    
    // Forcer la suppression du cache pour cet exercice pour tester le fix
    _cache.remove(key);

    try {
      // Toutes les séries de cet exercice, quelle que soit l'orthographe sous
      // laquelle elles ont été écrites.
      //
      // Cette lecture cherchait auparavant un identifiant d'exercice, puis
      // retombait sur le nom exact, puis essayait les autres langues une par
      // une en passant par le catalogue. Elle ne trouvait donc rien pour un
      // exercice absent du catalogue, et rien non plus quand deux séances
      // avaient été écrites « Développé couché » et « developpe-couche ».
      //
      // La base porte maintenant le nom normalisé de chaque série. Une seule
      // requête, sur toutes les variantes connues de cet exercice, rassemble
      // ce qui appartient au même mouvement.
      final aliases = await ExerciseResolver.aliasesFor(exerciseName);
      if (aliases.isEmpty) {
        final empty = _processExerciseData(const [], exerciseName);
        _cache[key] = _CacheEntry(empty, DateTime.now(), _exerciseDetailTTL);
        return empty;
      }

      // Même fenêtre que la liste des exercices, pour que les deux écrans
      // racontent la même chose.
      final dateFilter = DateTime.now().subtract(const Duration(days: 180)).toIso8601String();

      final rows = await _client
          .from('workout_set_history')
          .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
          .eq('user_id', userId)
          .inFilter('normalized_exercise_name', aliases)
          .gte('performed_at', dateFilter)
          .order('performed_at', ascending: true)
          .order('set_order', ascending: true);

      if (kDebugMode) {
        debugPrint('🏋️ "$exerciseName" : ${rows.length} séries sur ${aliases.length} variante(s)');
      }

      final processedData = _processExerciseData(rows, exerciseName);
      
      _cache[key] = _CacheEntry(processedData, DateTime.now(), _exerciseDetailTTL);
      
      return processedData;
    } catch (e) {
      if (cached != null) {
        return cached.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }
  
  /// Traite les données d'exercice (logique modifiée pour récupérer toutes les séries)
  static Map<String, dynamic> _processExerciseData(List<dynamic> rows, String exerciseName) {
    final Map<String, Map<String, dynamic>> bySession = {};
    final Map<String, List<Map<String, dynamic>>> allSetsBySession = {};
    
    if (rows is List) {
      for (final r in rows) {
        final sid = r['history_session_id']?.toString() ?? '';
        if (sid.isEmpty) continue;
        
        final performedAt = DateTime.tryParse(r['performed_at']?.toString() ?? '');
        final weight = (r['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (r['reps'] as int?) ?? 0;
        final isBest = (r['best_set'] as bool?) ?? false;
        final setOrder = (r['set_order'] as int?) ?? 0;

        // Stocker toutes les séries pour cette session
        final allSets = allSetsBySession[sid] ?? <Map<String, dynamic>>[];
        allSets.add({
          'weight': weight,
          'reps': reps,
          'isBest': isBest,
          'setOrder': setOrder,
        });
        allSetsBySession[sid] = allSets;

        final current = bySession[sid] ?? {
          'date': performedAt,
          'weight': 0.0,
          'reps': 0,
          'score': 0.0,
          'isBest': false,
          'totalVolume': 0.0,
        };

        final score = weight > 0 ? (weight * reps) : reps.toDouble();

        // Garder la meilleure série pour la progression/graphique
        if (isBest || (!current['isBest'] && score > (current['score'] as double))) {
          current['date'] = performedAt ?? current['date'];
          current['weight'] = weight;
          current['reps'] = reps;
          current['score'] = score;
          current['isBest'] = isBest || current['isBest'];
          bySession[sid] = current;
        }

        if (weight > 0 && reps > 0) {
          current['totalVolume'] = (current['totalVolume'] as double) + (weight * reps);
          bySession[sid] = current;
        }
      }
    }

    final sessions = bySession.values
        .where((v) => v['date'] != null)
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    String _fmtKg(double w) {
      if (w <= 0) return '—';
      return UnitService.instance.formatWeight(w, decimals: (w % 1).abs() < 1e-6 ? 0 : 1);
    }

    final List<double> bestSeries = [];
    final List<String> labels = [];
    final List<Map<String, dynamic>> history = [];
    
    // Calculer le nombre maximal de séries dans une session
    int maxSets = 0;
    for (final sessionId in allSetsBySession.keys) {
      final sets = allSetsBySession[sessionId] ?? [];
      if (sets.length > maxSets) {
        maxSets = sets.length;
      }
    }
    
    for (final s in sessions) {
      final double w = (s['weight'] as double);
      final int r = (s['reps'] as int);
      bestSeries.add(w > 0 ? w : r.toDouble());
      final dt = s['date'] as DateTime;
      
      // Trouver les sets pour cette session
      final sessionId = bySession.entries
          .where((entry) => entry.value == s)
          .map((entry) => entry.key)
          .first;
      final sets = allSetsBySession[sessionId] ?? [];
      
      // Trier les sets par set_order
      sets.sort((a, b) => (a['setOrder'] as int).compareTo(b['setOrder'] as int));
      
      // Formater toutes les séries
      final List<String> formattedSets = [];
      for (final set in sets) {
        final setWeight = set['weight'] as double;
        final setReps = set['reps'] as int;
        if (setWeight > 0) {
          final formattedWeight = UnitService.instance.formatWeight(setWeight, decimals: setWeight % 1 == 0 ? 0 : 1);
          formattedSets.add('$formattedWeight x $setReps');
        } else {
          formattedSets.add('$setReps reps');
        }
      }
      
      history.add({
        'date': dt.toIso8601String(),
        'weight': _fmtKg(w),
        'reps': '$r',
        'allSets': formattedSets,
        'sessionId': sessionId,
      });
      labels.add('${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}');
    }

    String lastWeightLabel = 'N/A';
    if (sessions.isNotEmpty) {
      final last = sessions.last;
      final lw = (last['weight'] as double);
      final lr = (last['reps'] as int);
      lastWeightLabel = lw > 0 ? _fmtKg(lw) : '${lr} reps';
    }

    return {
      'name': exerciseName,
      'muscleGroup': '',
      'sessions': sessions.length,
      'progress': '',
      'lastWeight': lastWeightLabel,
      'data_best': bestSeries,
      'labels': labels,
      'raw': sessions.map((s) => {
        'date': (s['date'] as DateTime).toIso8601String(),
        'best': ((s['weight'] as double) > 0 ? (s['weight'] as double) : (s['reps'] as int).toDouble()),
        'volume': (s['totalVolume'] as double),
      }).toList(),
      'sessionsFull': sessions
          .map((s) => {
                'date': (s['date'] as DateTime).toIso8601String(),
                'weight': (s['weight'] as double),
                'reps': (s['reps'] as int),
              })
          .toList(),
      'sessionHistory': history.take(10).toList().reversed.toList(),
      'maxSets': maxSets,
    };
  }
  
  /// Invalide le cache pour un utilisateur (à appeler après une nouvelle séance)
  static void invalidateUserCache(String userId) {
    _cache.removeWhere((key, _) => key.contains(userId));
  }
  
  /// Nettoie le cache expiré
  static void cleanExpiredCache() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
  
  /// Vide complètement le cache
  static void clearCache() {
    _cache.clear();
  }

  /// Méthode de debug pour examiner les données d'exercices
  static Future<void> debugExerciseData(String userId) async {
    if (kDebugMode) debugPrint('🔍 === DEBUG EXERCISE DATA ===');
    
    // Vérifier les exercices dans la table exercises
    final exercisesData = await _client
        .from('exercises')
        .select('id, name_fr, name_en, name_de')
        .ilike('name_fr', '%squat%')
        .or('name_en.ilike.%squat%,name_de.ilike.%squat%')
        .limit(10);

    if (kDebugMode) debugPrint('🏋️ Exercices avec "squat" dans la table exercises:');
    for (final ex in exercisesData) {
      if (kDebugMode) debugPrint('  - ID: ${ex['id']}, FR: "${ex['name_fr']}", EN: "${ex['name_en']}", DE: "${ex['name_de']}"');
    }
    
    // Vérifier l'historique des workouts pour cet utilisateur avec des noms contenant squat
    final historyData = await _client
        .from('workout_set_history')
        .select('exercise_id, exercise_name, performed_at')
        .eq('user_id', userId)
        .ilike('exercise_name', '%squat%')
        .limit(10);
    
    if (kDebugMode) debugPrint('🏋️ Historique avec "squat" pour user $userId:');
    for (final hist in historyData) {
      if (kDebugMode) debugPrint('  - Exercise ID: ${hist['exercise_id']}, Name: "${hist['exercise_name']}", Date: ${hist['performed_at']}');
    }
    
    // Vérifier les noms d'exercices uniques dans l'historique
    final uniqueNames = await _client
        .from('workout_set_history')
        .select('exercise_name')
        .eq('user_id', userId)
        .order('exercise_name');
    
    final names = <String>{};
    for (final item in uniqueNames) {
      if (item['exercise_name'] != null) {
        names.add(item['exercise_name']);
      }
    }
    
    if (kDebugMode) debugPrint('🏋️ Noms d\'exercices uniques dans l\'historique (${names.length} au total):');
    for (final name in names.take(20)) {
      if (kDebugMode) debugPrint('  - "$name"');
    }
    
    if (kDebugMode) debugPrint('🔍 === FIN DEBUG ===');
  }
  
  /// Force le rechargement des données (pour debug/test)
  static Future<void> forceRefresh(String userId) async {
    invalidateUserCache(userId);
    cleanExpiredCache();
  }
}
