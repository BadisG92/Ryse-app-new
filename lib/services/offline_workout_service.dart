import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sport_models.dart';
import '../config/supabase_config.dart';
import 'database_service.dart' as db;
import 'package:uuid/uuid.dart';
import 'localization_service.dart';

/// Service de gestion du mode hors ligne pour les séances de musculation
class OfflineWorkoutService {
  static final OfflineWorkoutService _instance = OfflineWorkoutService._internal();
  factory OfflineWorkoutService() => _instance;
  OfflineWorkoutService._internal();

  static SupabaseClient get _client => SupabaseConfig.client;

  static const String _exercisesCacheKey = 'offline_exercises_cache';
  static const String _customExercisesCacheKey = 'offline_custom_exercises';
  static const String _templatesCacheKey = 'offline_templates_cache';
  static const String _pendingSessionsKey = 'offline_pending_sessions';
  static const String _cacheTimestampKey = 'offline_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(days: 7);

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  final _statusController = StreamController<OfflineStatus>.broadcast();
  Stream<OfflineStatus> get statusStream => _statusController.stream;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastCacheRefresh;

  /// Initialise le service et démarre la surveillance réseau
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    
    // IMPORTANT: Toujours charger le cache existant au démarrage
    // même si on est hors ligne, pour utiliser le dernier cache disponible
    await _loadExistingCache();
    
    // Si en ligne, rafraîchir le cache et tenter une sync
    if (_isOnline) {
      _scheduleSyncAttempt();
      // Rafraîchir le cache en arrière-plan
      refreshCache().catchError((e) {
        debugPrint('⚠️ Erreur rafraîchissement cache au démarrage: $e');
      });
    } else {
      debugPrint('📵 Démarrage en mode hors ligne - Utilisation du cache existant');
    }
  }
  
  /// Charge le cache existant depuis SharedPreferences
  Future<void> _loadExistingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCache = prefs.containsKey(_exercisesCacheKey);
      
      if (hasCache) {
        debugPrint('✅ Cache existant trouvé et chargé');
        _updateStatus();
      } else {
        debugPrint('⚠️ Aucun cache trouvé - première utilisation');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache existant: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _statusController.close();
  }

  /// Vérifie la connectivité actuelle
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);
    _updateStatus();
  }

  /// Surveille les changements de connectivité
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      
      if (!wasOnline && _isOnline) {
        // Retour en ligne - tenter une synchronisation
        debugPrint('📡 Connexion rétablie - Tentative de synchronisation...');
        _scheduleSyncAttempt();
      }
      
      _updateStatus();
    });
  }

  /// Met à jour le statut et notifie les listeners
  void _updateStatus() {
    final pendingSessions = _getPendingSessionsCount();
    _statusController.add(OfflineStatus(
      isOnline: _isOnline,
      pendingSessionsCount: pendingSessions,
      isSyncing: _isSyncing,
      cacheValid: isCacheValid(),
    ));
  }

  /// Vérifie si le cache est valide
  bool isCacheValid() {
    final prefs = SharedPreferencesSync();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;
    
    final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheDate) < _cacheValidityDuration;
  }
  
  /// Vérifie si un cache existe (même expiré)
  bool hasCachedData() {
    final prefs = SharedPreferencesSync();
    return prefs.getString(_exercisesCacheKey) != null;
  }

  /// Charge le cache si nécessaire
  Future<void> _loadCacheIfNeeded() async {
    if (!isCacheValid() && _isOnline) {
      await refreshCache();
    }
  }

  /// Rafraîchit le cache depuis Supabase
  Future<void> refreshCache() async {
    if (!_isOnline) {
      debugPrint('⚠️ Impossible de rafraîchir le cache - Mode hors ligne');
      return;
    }

    // Éviter les rafraîchissements trop fréquents (max 1 par minute)
    final now = DateTime.now();
    if (_lastCacheRefresh != null && 
        now.difference(_lastCacheRefresh!) < const Duration(minutes: 1)) {
      debugPrint('🔄 Cache rafraîchi récemment - Ignoré pour éviter la surcharge');
      return;
    }

    _lastCacheRefresh = now;

    try {
      debugPrint('🔄 Rafraîchissement du cache des exercices...');
      
      // Charger les exercices directement depuis Supabase (pas via getSystemExercises pour éviter la boucle)
      final exercises = await _loadExercisesDirectly();
      
      // Charger les templates
      final templates = await db.DatabaseService.getWorkoutTemplates(includePublic: true);
      
      // Sauvegarder dans le cache
      final prefs = await SharedPreferences.getInstance();
      
      // Exercices système et custom
      final exercisesJson = exercises.map((e) => {
        'id': e.id,
        'name': e.name,
        'muscleGroup': e.muscleGroup,
        'equipment': e.equipment,
        'description': e.description,
        'isCustom': e.isCustom,
      }).toList();
      
      await prefs.setString(_exercisesCacheKey, jsonEncode(exercisesJson));
      
      // Templates
      final templatesJson = templates.map((t) => {
        'id': t.id,
        'name': t.name,
        'description': t.description,
        'type': t.type,
        'estimatedDuration': t.estimatedDuration,
        'exercises': t.exercises.map((e) => {
          'exercise': {
            'id': e.exercise.id,
            'name': e.exercise.name,
            'muscleGroup': e.exercise.muscleGroup,
            'equipment': e.exercise.equipment,
            'description': e.exercise.description,
            'isCustom': e.exercise.isCustom,
          },
          'sets': e.sets,
          'suggestedRepsMin': e.suggestedRepsMin,
          'suggestedRepsMax': e.suggestedRepsMax,
        }).toList(),
        'isCustom': t.isCustom,
      }).toList();
      
      await prefs.setString(_templatesCacheKey, jsonEncode(templatesJson));
      
      // Mettre à jour le timestamp
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('✅ Cache rafraîchi avec succès');
      _updateStatus();
    } catch (e) {
      debugPrint('❌ Erreur lors du rafraîchissement du cache: $e');
    }
  }

  /// Charge les exercices directement depuis Supabase (sans passer par getSystemExercises)
  Future<List<Exercise>> _loadExercisesDirectly() async {
    final List<Exercise> exercises = [];
    
    try {
      // Exercices système
      final locService = LocalizationService.instance;
      final suffix = locService.getColumnSuffix();
      final rows = await _client
          .from('exercises')
          .select('id, name_en, name_fr, name_de, muscle_group_fr, muscle_group_en, muscle_group_de, equipment, description, is_custom')
          .order('name$suffix', ascending: true)
          .limit(500);
          
      if (rows is List && rows.isNotEmpty) {
        exercises.addAll(rows.map<Exercise>((json) {
          final map = json as Map<String, dynamic>;
          
          return Exercise(
            id: map['id']?.toString() ?? '',
            name: locService.getTextFromColumns(map['name_fr'], map['name_en'], map['name_de']),
            muscleGroup: locService.getTextFromColumns(map['muscle_group_fr'], map['muscle_group_en'], map['muscle_group_de']),
            equipment: (map['equipment'] as String?) ?? '',
            description: (map['description'] as String?) ?? '',
            isCustom: (map['is_custom'] as bool?) ?? false,
          );
        }).toList());
      }

      // Exercices custom de l'utilisateur
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final customRows = await _client
            .from('custom_exercises')
            .select('id, name, muscle_group_fr, muscle_group_en, muscle_group_de, equipment, description, visible_list')
            .eq('user_id', userId)
            .eq('visible_list', true)
            .order('created_at', ascending: false);
            
        if (customRows is List && customRows.isNotEmpty) {
          exercises.addAll(customRows.map<Exercise>((m) {
            final map = m as Map<String, dynamic>;
            return Exercise(
              id: map['id']?.toString() ?? '',
              name: (map['name'] as String?) ?? '',
              muscleGroup: locService.getTextFromColumns(map['muscle_group_fr'], map['muscle_group_en'], map['muscle_group_de']),
              equipment: (map['equipment'] as String?) ?? '',
              description: (map['description'] as String?) ?? '',
              isCustom: true,
            );
          }).toList());
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement exercices: $e');
    }

    return exercises;
  }

  /// Récupère les exercices depuis le cache local
  Future<List<Exercise>> getCachedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_exercisesCacheKey);
    
    if (jsonString == null) {
      debugPrint('⚠️ Cache des exercices vide');
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Exercise(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        muscleGroup: json['muscleGroup'] ?? '',
        equipment: json['equipment'] ?? '',
        description: json['description'] ?? '',
        isCustom: json['isCustom'] ?? false,
      )).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du décodage du cache: $e');
      return [];
    }
  }

  /// Récupère les templates depuis le cache local
  Future<List<WorkoutProgram>> getCachedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesCacheKey);
    
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => WorkoutProgram(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        type: json['type'] ?? '',
        estimatedDuration: json['estimatedDuration'] ?? 45,
        exercises: (json['exercises'] as List).map((e) => ProgramExercise(
          exercise: Exercise(
            id: e['exercise']['id'] ?? '',
            name: e['exercise']['name'] ?? '',
            muscleGroup: e['exercise']['muscleGroup'] ?? '',
            equipment: e['exercise']['equipment'] ?? '',
            description: e['exercise']['description'] ?? '',
            isCustom: e['exercise']['isCustom'] ?? false,
          ),
          sets: e['sets'] ?? 3,
          suggestedRepsMin: e['suggestedRepsMin'],
          suggestedRepsMax: e['suggestedRepsMax'],
        )).toList(),
        isCustom: json['isCustom'] ?? false,
      )).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du décodage des templates: $e');
      return [];
    }
  }

  /// Sauvegarde une séance en attente de synchronisation
  Future<void> saveSessionForSync(WorkoutSession session, {
    String? guidedTemplateId,
    String sessionSource = 'manual',
    String? intensity,
    int? durationMinutes,
    int? caloriesBurned,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Récupérer les sessions en attente
    final pendingJson = prefs.getString(_pendingSessionsKey);
    final List<dynamic> pendingSessions = pendingJson != null
        ? jsonDecode(pendingJson)
        : [];

    // Créer l'entrée de session
    final sessionData = {
      'id': const Uuid().v4(),
      'session': _sessionToJson(session),
      'guidedTemplateId': guidedTemplateId,
      'sessionSource': sessionSource,
      'intensity': intensity,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };
    
    pendingSessions.add(sessionData);
    
    // Sauvegarder
    await prefs.setString(_pendingSessionsKey, jsonEncode(pendingSessions));
    
    debugPrint('💾 Séance sauvegardée localement (${pendingSessions.length} en attente)');
    _updateStatus();
    
    // Tenter une sync si en ligne
    if (_isOnline) {
      _scheduleSyncAttempt();
    }
  }

  /// Créer un exercice custom en mode hors ligne
  Future<Exercise> createOfflineCustomExercise({
    required String name,
    required String muscleGroup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Générer un ID temporaire
    final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    final exercise = Exercise(
      id: tempId,
      name: name,
      muscleGroup: muscleGroup,
      equipment: '',
      description: '',
      isCustom: true,
    );
    
    // Ajouter au cache local
    final exercises = await getCachedExercises();
    exercises.add(exercise);
    
    final exercisesJson = exercises.map((e) => {
      'id': e.id,
      'name': e.name,
      'muscleGroup': e.muscleGroup,
      'equipment': e.equipment,
      'description': e.description,
      'isCustom': e.isCustom,
    }).toList();
    
    await prefs.setString(_exercisesCacheKey, jsonEncode(exercisesJson));
    
    // Ajouter à la liste des exercices custom à synchroniser
    final customJson = prefs.getString(_customExercisesCacheKey);
    final List<dynamic> customExercises = customJson != null 
        ? jsonDecode(customJson) 
        : [];
    
    customExercises.add({
      'tempId': tempId,
      'name': name,
      'muscleGroup': muscleGroup,
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_customExercisesCacheKey, jsonEncode(customExercises));
    
    debugPrint('💾 Exercice custom créé en mode offline: $name');
    
    return exercise;
  }

  /// Programme une tentative de synchronisation
  void _scheduleSyncAttempt() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 5), () {
      synchronizePendingSessions();
    });
  }

  /// Synchronise les sessions en attente
  Future<void> synchronizePendingSessions() async {
    if (!_isOnline || _isSyncing) return;
    
    _isSyncing = true;
    _updateStatus();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Synchroniser les exercices custom d'abord
      await _syncCustomExercises(prefs);
      
      // Synchroniser les sessions
      final pendingJson = prefs.getString(_pendingSessionsKey);
      if (pendingJson == null) {
        _isSyncing = false;
        _updateStatus();
        return;
      }
      
      List<dynamic> pendingSessions = jsonDecode(pendingJson);
      final List<dynamic> failedSessions = [];
      
      for (final sessionData in pendingSessions) {
        try {
          debugPrint('📤 Synchronisation de la séance ${sessionData['id']}...');

          final session = _sessionFromJson(sessionData['session']);

          await db.DatabaseService.persistCompletedWorkoutAsHistory(
            session: session,
            guidedTemplateId: sessionData['guidedTemplateId'],
            sessionSource: sessionData['sessionSource'] ?? 'manual', // Default to manual for old sessions
            intensity: sessionData['intensity'],
            durationMinutes: sessionData['durationMinutes'],
            caloriesBurned: sessionData['caloriesBurned'],
          );

          debugPrint('✅ Séance synchronisée avec succès');
        } catch (e) {
          debugPrint('❌ Erreur de synchronisation: $e');
          sessionData['retryCount'] = (sessionData['retryCount'] ?? 0) + 1;
          
          // Garder les sessions qui ont échoué (max 3 tentatives)
          if (sessionData['retryCount'] < 3) {
            failedSessions.add(sessionData);
          }
        }
      }
      
      // Mettre à jour les sessions en attente
      if (failedSessions.isEmpty) {
        await prefs.remove(_pendingSessionsKey);
      } else {
        await prefs.setString(_pendingSessionsKey, jsonEncode(failedSessions));
      }
      
      debugPrint('📊 Synchronisation terminée: ${pendingSessions.length - failedSessions.length}/${pendingSessions.length} réussies');
      
    } catch (e) {
      debugPrint('❌ Erreur générale de synchronisation: $e');
    } finally {
      _isSyncing = false;
      _updateStatus();
    }
  }

  /// Synchronise les exercices custom créés hors ligne
  Future<void> _syncCustomExercises(SharedPreferences prefs) async {
    final customJson = prefs.getString(_customExercisesCacheKey);
    if (customJson == null) return;
    
    List<dynamic> customExercises = jsonDecode(customJson);
    final List<dynamic> remainingExercises = [];
    
    for (final exercise in customExercises) {
      try {
        final created = await db.DatabaseService.createCustomExercise(
          name: exercise['name'],
          muscleGroup: exercise['muscleGroup'],
        );
        
        if (created != null) {
          // Remplacer l'ID temporaire par le vrai ID dans le cache
          await _replaceExerciseId(exercise['tempId'], created.id);
        }
      } catch (e) {
        debugPrint('❌ Erreur sync exercice custom: $e');
        remainingExercises.add(exercise);
      }
    }
    
    if (remainingExercises.isEmpty) {
      await prefs.remove(_customExercisesCacheKey);
    } else {
      await prefs.setString(_customExercisesCacheKey, jsonEncode(remainingExercises));
    }
  }

  /// Remplace un ID temporaire par un ID réel dans le cache
  Future<void> _replaceExerciseId(String tempId, String realId) async {
    final exercises = await getCachedExercises();
    final index = exercises.indexWhere((e) => e.id == tempId);
    
    if (index != -1) {
      exercises[index] = exercises[index].copyWith(id: realId);
      
      final prefs = await SharedPreferences.getInstance();
      final exercisesJson = exercises.map((e) => {
        'id': e.id,
        'name': e.name,
        'muscleGroup': e.muscleGroup,
        'equipment': e.equipment,
        'description': e.description,
        'isCustom': e.isCustom,
      }).toList();
      
      await prefs.setString(_exercisesCacheKey, jsonEncode(exercisesJson));
    }
  }

  /// Compte le nombre de sessions en attente
  int _getPendingSessionsCount() {
    final prefs = SharedPreferencesSync();
    final pendingJson = prefs.getString(_pendingSessionsKey);
    if (pendingJson == null) return 0;
    
    try {
      final List<dynamic> pendingSessions = jsonDecode(pendingJson);
      return pendingSessions.length;
    } catch (_) {
      return 0;
    }
  }

  /// Convertit une session en JSON
  Map<String, dynamic> _sessionToJson(WorkoutSession session) {
    return {
      'id': session.id,
      'name': session.name,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'exercises': session.exercises.map((e) => {
        'exercise': {
          'id': e.exercise.id,
          'name': e.exercise.name,
          'muscleGroup': e.exercise.muscleGroup,
          'equipment': e.exercise.equipment,
          'description': e.exercise.description,
          'isCustom': e.exercise.isCustom,
        },
        'sets': e.sets.map((s) => {
          'weight': s.weight,
          'reps': s.reps,
          'isCompleted': s.isCompleted,
        }).toList(),
        'suggestedRepsMin': e.suggestedRepsMin,
        'suggestedRepsMax': e.suggestedRepsMax,
      }).toList(),
      'isCompleted': session.isCompleted,
    };
  }

  /// Reconstruit une session depuis JSON
  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      name: json['name'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      exercises: (json['exercises'] as List).map((e) => WorkoutExercise(
        exercise: Exercise(
          id: e['exercise']['id'],
          name: e['exercise']['name'],
          muscleGroup: e['exercise']['muscleGroup'],
          equipment: e['exercise']['equipment'],
          description: e['exercise']['description'],
          isCustom: e['exercise']['isCustom'],
        ),
        sets: (e['sets'] as List).map((s) => ExerciseSet(
          weight: s['weight'].toDouble(),
          reps: s['reps'],
          isCompleted: s['isCompleted'],
        )).toList(),
        suggestedRepsMin: e['suggestedRepsMin'],
        suggestedRepsMax: e['suggestedRepsMax'],
      )).toList(),
      isCompleted: json['isCompleted'],
    );
  }

  /// Force une synchronisation manuelle
  Future<void> forceSynchronization() async {
    if (_isOnline && !_isSyncing) {
      await synchronizePendingSessions();
    }
  }

  /// Nettoie toutes les données en cache
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exercisesCacheKey);
    await prefs.remove(_customExercisesCacheKey);
    await prefs.remove(_templatesCacheKey);
    await prefs.remove(_pendingSessionsKey);
    await prefs.remove(_cacheTimestampKey);
    _updateStatus();
  }
}

/// Statut du mode hors ligne
class OfflineStatus {
  final bool isOnline;
  final int pendingSessionsCount;
  final bool isSyncing;
  final bool cacheValid;

  OfflineStatus({
    required this.isOnline,
    required this.pendingSessionsCount,
    required this.isSyncing,
    required this.cacheValid,
  });

  bool get hasOfflineCapability => cacheValid || pendingSessionsCount > 0;
}

/// Extension pour SharedPreferences synchrone (pour certaines vérifications rapides)
class SharedPreferencesSync {
  static final _instance = SharedPreferencesSync._internal();
  factory SharedPreferencesSync() => _instance;
  SharedPreferencesSync._internal();
  
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
}