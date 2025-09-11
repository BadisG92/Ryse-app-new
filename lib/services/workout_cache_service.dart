import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization_service.dart';

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
      final suffix = locService.getColumnSuffix();
      
      // Chercher l'exercice dans la table exercises avec un seul appel
      final exerciseData = await _client
        .from('exercises')
        .select('name_fr, name_en')
        .or('name_fr.eq.$exerciseName,name_en.eq.$exerciseName')
        .limit(1)
        .maybeSingle();
        
      if (exerciseData != null) {
        return locService.getTextFromColumns(
          exerciseData['name_fr'], 
          exerciseData['name_en']
        ) ?? exerciseName;
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
      // Utilise la fonction PostgreSQL optimisée
      final result = await _client.rpc('get_weekly_dashboard_data', 
        params: {'target_user_id': userId});
      
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

    return sessions.map((session) {
      if (session is Map<String, dynamic>) {
        final exercises = session['exercises'] as List<dynamic>? ?? [];
        final localizedExercises = exercises.map((exercise) {
          if (exercise is Map<String, dynamic>) {
            String localizedName = exercise['exercise_name']?.toString() ?? '';
            
            // Chercher par nom exact dans les exercices système
            final matchingExercise = exercisesMap.entries
                .where((entry) => entry.value.toLowerCase() == localizedName.toLowerCase());
            
            if (matchingExercise.isNotEmpty) {
              localizedName = matchingExercise.first.value;
            } else {
              // Chercher dans les exercices custom
              final matchingCustom = customExercisesMap.entries
                  .where((entry) => entry.value.toLowerCase() == localizedName.toLowerCase());
              if (matchingCustom.isNotEmpty) {
                localizedName = matchingCustom.first.value;
              }
            }
            
            return {
              ...exercise,
              'localized_exercise_name': localizedName,
            };
          }
          return exercise;
        }).toList();
        
        return {
          ...session,
          'exercises': localizedExercises,
        };
      }
      return session;
    }).toList();
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
          .select('history_session_id, exercise_name, exercise_id, custom_exercise_id, weight, reps, performed_at')
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
        
        // Initialiser ou récupérer les stats de cet exercice
        if (!exerciseStats.containsKey(localizedName)) {
          exerciseStats[localizedName] = {
            'name': localizedName,
            'localized_name': localizedName,
            'sessions': <String>{},
            'maxWeight': 0.0,
            'maxReps': 0,
          };
        }
        
        // Ajouter cette session à la liste
        (exerciseStats[localizedName]!['sessions'] as Set<String>).add(sessionId);
        
        // Mettre à jour le max de poids et reps
        final weight = (row['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (row['reps'] as int?) ?? 0;
        
        if (weight > (exerciseStats[localizedName]!['maxWeight'] as double)) {
          exerciseStats[localizedName]!['maxWeight'] = weight;
        }
        if (reps > (exerciseStats[localizedName]!['maxReps'] as int)) {
          exerciseStats[localizedName]!['maxReps'] = reps;
        }
      }

      // Convertir en format attendu et trier par nombre de sessions
      final data = exerciseStats.values.map((stats) {
        final sessionsCount = (stats['sessions'] as Set<String>).length;
        final maxWeight = stats['maxWeight'] as double;
        final maxReps = stats['maxReps'] as int;
        
        String current = 'N/A';
        if (maxWeight > 0) {
          current = '${maxWeight.toInt()} kg';
        } else if (maxReps > 0) {
          current = '$maxReps reps';
        }
        
        return {
          'name': stats['localized_name'],
          'localized_name': stats['localized_name'],
          'sessions': sessionsCount,
          'current': current,
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

  /// Localise les noms d'exercices dans une liste de résultats
  static Future<List<dynamic>> _localizeExerciseList(List<dynamic> exerciseList) async {
    if (exerciseList.isEmpty) return exerciseList;
    
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

    // Localiser chaque exercice
    return exerciseList.map((exercise) {
      if (exercise is Map<String, dynamic>) {
        String localizedName = exercise['name']?.toString() ?? '';
        
        // Tenter de trouver le nom localisé en cherchant par nom dans les exercices système
        final matchingExercises = exercisesMap.entries
            .where((entry) => entry.value.toLowerCase() == localizedName.toLowerCase())
            .map((entry) => entry.key);
            
        if (matchingExercises.isNotEmpty) {
          final exerciseId = matchingExercises.first;
          localizedName = exercisesMap[exerciseId]!;
        } else {
          // Chercher dans les exercices custom
          final matchingCustom = customExercisesMap.entries
              .where((entry) => entry.value.toLowerCase() == localizedName.toLowerCase())
              .map((entry) => entry.key);
              
          if (matchingCustom.isNotEmpty) {
            final customId = matchingCustom.first;
            localizedName = customExercisesMap[customId]!;
          }
        }
        
        return {
          ...exercise,
          'localized_name': localizedName,
        };
      }
      return exercise;
    }).toList();
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
      // Utiliser les IDs pour récupérer l'historique au lieu des noms pour éviter les problèmes de traduction
      final locService = LocalizationService.instance;
      final suffix = locService.getColumnSuffix();
      
      // Récupérer l'ID de l'exercice basé sur son nom localisé
      String? exerciseId;
      String? customExerciseId;
      
      // Chercher dans les exercices système
      print('🔍 Recherche exercice: "$exerciseName" avec suffix: $suffix');
      print('🔍 Requête: exercises table, colonne: name$suffix, valeur: "$exerciseName"');
      
      final systemExercises = await _client
          .from('exercises')
          .select('id, name$suffix, name_fr, name_en')
          .eq('name$suffix', exerciseName);
      
      print('🏋️ Exercices système trouvés: ${systemExercises.length}');
      
      // Debug: Afficher quelques exercices pour comparaison si aucun trouvé
      if (systemExercises.isEmpty) {
        print('❌ Aucun exercice système trouvé avec le nom "$exerciseName"');
        print('🔍 Recherche d\'exercices similaires...');
        final similarExercises = await _client
            .from('exercises')
            .select('id, name_fr, name_en')
            .ilike('name$suffix', '%squat%')
            .limit(5);
        print('🔍 Exercices avec "squat" trouvés: $similarExercises');
      } else {
        print('✅ Exercice système trouvé: ${systemExercises.first}');
      }
      if (systemExercises.isNotEmpty) {
        exerciseId = systemExercises.first['id'];
        print('✅ Exercise ID trouvé: $exerciseId');
      } else {
        // Chercher dans les exercices custom
        final customExercises = await _client
            .from('custom_exercises')
            .select('id, name')
            .eq('name', exerciseName);
        
        print('🏋️ Exercices custom trouvés: ${customExercises.length}');
        if (customExercises.isNotEmpty) {
          customExerciseId = customExercises.first['id'];
          print('✅ Custom Exercise ID trouvé: $customExerciseId');
        }
      }
      
      // Construire la requête basée sur les IDs trouvés
      // Utiliser la même période que getTopExercises() pour la cohérence (6 derniers mois)
      final dateFilter = DateTime.now().subtract(const Duration(days: 180)).toIso8601String();
      
      List<dynamic> rows;
      if (exerciseId != null) {
        print('🔍 Recherche historique avec exercise_id: $exerciseId pour user: $userId');
        print('🔍 Date filter: $dateFilter');
        
        rows = await _client
            .from('workout_set_history')
            .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
            .eq('user_id', userId)
            .eq('exercise_id', exerciseId)
            .gte('performed_at', dateFilter)
            .order('performed_at', ascending: true)
            .order('set_order', ascending: true);
        
        print('🏋️ Historique trouvé: ${rows.length} lignes');
        if (rows.isNotEmpty) {
          print('📊 Premier résultat: ${rows.first}');
        } else {
          print('❌ Aucune donnée avec cet exercise_id, essai du fallback par nom...');
          
          // Si aucune donnée trouvée avec l'exercise_id, essayer le fallback par nom
          var fallbackRows = await _client
              .from('workout_set_history')
              .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
              .eq('user_id', userId)
              .eq('exercise_name', exerciseName)
              .gte('performed_at', dateFilter)
              .order('performed_at', ascending: true)
              .order('set_order', ascending: true);
          
          print('🔍 Recherche fallback par exercise_name="$exerciseName": ${fallbackRows.length} résultats');
          rows = fallbackRows;
        }
      } else if (customExerciseId != null) {
        rows = await _client
            .from('workout_set_history')
            .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
            .eq('user_id', userId)
            .eq('custom_exercise_id', customExerciseId)
            .gte('performed_at', dateFilter)
            .order('performed_at', ascending: true)
            .order('set_order', ascending: true);
      } else {
        print('❌ Aucun ID d\'exercice trouvé, utilisation du fallback par nom');
        
        // Fallback : utiliser la même logique que getTopExercises()
        // D'abord, essayer avec le nom tel que reçu
        var fallbackRows = await _client
            .from('workout_set_history')
            .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
            .eq('user_id', userId)
            .eq('exercise_name', exerciseName)
            .gte('performed_at', dateFilter)
            .order('performed_at', ascending: true)
            .order('set_order', ascending: true);
        
        print('🔍 Recherche par exercise_name="$exerciseName": ${fallbackRows.length} résultats');
        
        if (fallbackRows.isEmpty) {
          // Essayer avec le nom dans l'autre langue (FR si on cherche en EN et vice versa)
          final otherSuffix = suffix == '_fr' ? '_en' : '_fr';
          final possibleExercises = await _client
              .from('exercises')
              .select('name_fr, name_en')
              .eq('name$suffix', exerciseName);
          
          if (possibleExercises.isNotEmpty) {
            final rawName = possibleExercises.first['name$otherSuffix'];
            print('🔍 Essai avec nom dans autre langue: "$rawName"');
            if (rawName != null) {
              fallbackRows = await _client
                  .from('workout_set_history')
                  .select('history_session_id, performed_at, weight, reps, best_set, set_order, exercise_name')
                  .eq('user_id', userId)
                  .eq('exercise_name', rawName)
                  .gte('performed_at', dateFilter)
                  .order('performed_at', ascending: true)
                  .order('set_order', ascending: true);
            }
          }
        }
        
        rows = fallbackRows;
        print('🔍 Fallback terminé: ${fallbackRows.length} résultats trouvés au total');
      }
      
      print('🔍 Données finales pour traitement: ${rows.length} lignes');
      
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

  /// Méthode de debug pour examiner les données d'exercices
  static Future<void> debugExerciseData(String userId) async {
    print('🔍 === DEBUG EXERCISE DATA ===');
    
    // Vérifier les exercices dans la table exercises
    final exercisesData = await _client
        .from('exercises')
        .select('id, name_fr, name_en')
        .ilike('name_fr', '%squat%')
        .or('name_en.ilike.%squat%')
        .limit(10);
    
    print('🏋️ Exercices avec "squat" dans la table exercises:');
    for (final ex in exercisesData) {
      print('  - ID: ${ex['id']}, FR: "${ex['name_fr']}", EN: "${ex['name_en']}"');
    }
    
    // Vérifier l'historique des workouts pour cet utilisateur avec des noms contenant squat
    final historyData = await _client
        .from('workout_set_history')
        .select('exercise_id, exercise_name, performed_at')
        .eq('user_id', userId)
        .ilike('exercise_name', '%squat%')
        .limit(10);
    
    print('🏋️ Historique avec "squat" pour user $userId:');
    for (final hist in historyData) {
      print('  - Exercise ID: ${hist['exercise_id']}, Name: "${hist['exercise_name']}", Date: ${hist['performed_at']}');
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
    
    print('🏋️ Noms d\'exercices uniques dans l\'historique (${names.length} au total):');
    for (final name in names.take(20)) {
      print('  - "$name"');
    }
    
    print('🔍 === FIN DEBUG ===');
  }
  
  /// Force le rechargement des données (pour debug/test)
  static Future<void> forceRefresh(String userId) async {
    invalidateUserCache(userId);
    cleanExpiredCache();
  }
}
