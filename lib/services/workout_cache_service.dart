import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  /// Récupère les données du dashboard hebdomadaire (optimisé)
  static Future<Map<String, dynamic>> getWeeklyDashboardData(String userId) async {
    final key = 'weekly_dashboard_$userId';
    final cached = _cache[key];
    
    if (cached != null && !cached.isExpired) {
      return cached.data as Map<String, dynamic>;
    }
    
    try {
      // Utilise la fonction PostgreSQL optimisée
      final result = await _client.rpc('get_weekly_dashboard_data', 
        params: {'target_user_id': userId});
      
      final data = result as Map<String, dynamic>;
      
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
      // Requête directe pour les exercices les plus fréquents (6 derniers mois)
      final result = await _client.rpc('get_top_exercises_data', 
        params: {'target_user_id': userId});
      
      final data = result as List<dynamic>? ?? [];
      
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
    
    try {
      // Requête optimisée pour un exercice spécifique
      final rows = await _client
          .from('workout_set_history')
          .select('history_session_id, performed_at, weight, reps, best_set, set_order')
          .eq('user_id', userId)
          .eq('exercise_name', exerciseName)
          .order('performed_at', ascending: true)
          .order('set_order', ascending: true);
      
      // Traitement côté client (inchangé pour compatibilité)
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
      if ((w % 1).abs() < 1e-6) return '${w.toInt()} kg';
      return '${w.toStringAsFixed(1)} kg';
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
          formattedSets.add('${setWeight % 1 == 0 ? setWeight.toInt() : setWeight.toStringAsFixed(1)} kg x $setReps');
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
  
  /// Force le rechargement des données (pour debug/test)
  static Future<void> forceRefresh(String userId) async {
    invalidateUserCache(userId);
    cleanExpiredCache();
  }
}
