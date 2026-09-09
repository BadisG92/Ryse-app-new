import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sport_models.dart';
import '../config/supabase_config.dart';
import 'database_service.dart' as db;
import 'localization_service.dart';
import 'ryze_connectivity.dart';

/// Le catalogue d'exercices et de programmes, disponible sans réseau.
///
/// Ce service faisait trois choses : détecter le réseau, cacher le catalogue,
/// et garder les séances en attente. La première est passée à
/// [RyzeConnectivity] (une souscription pour toute l'app au lieu d'une par
/// séance) ; la troisième à [WorkoutSessionStore] (une file qui ne perd rien
/// et ne supprime jamais une séance sur échec). Il ne reste que le catalogue,
/// qui marchait déjà bien.
class OfflineWorkoutService {
  static final OfflineWorkoutService _instance = OfflineWorkoutService._internal();
  factory OfflineWorkoutService() => _instance;
  OfflineWorkoutService._internal();

  static SupabaseClient get _client => SupabaseConfig.client;

  static const String _exercisesCacheKey = 'offline_exercises_cache';

  /// La langue dans laquelle le cache des exercices a été écrit.
  ///
  /// Il n'en gardait aucune trace. Une fois rempli, il resservait les mêmes
  /// noms indéfiniment : un compte français continuait de voir « Bench Press »
  /// et « Barbell Curl », et ces noms partaient dans l'historique des séances
  /// à chaque enregistrement.
  static const String _exercisesCacheLangKey = 'offline_exercises_cache_lang';
  static const String _customExercisesCacheKey = 'offline_custom_exercises';
  static const String _templatesCacheKey = 'offline_templates_cache';
  static const String _cacheTimestampKey = 'offline_cache_timestamp';

  bool get isOnline => RyzeConnectivity.instance.online.value;

  bool _initialized = false;
  DateTime? _lastCacheRefresh;

  /// Idempotent : l'écran de séance l'appelait à chaque ouverture, et chaque
  /// appel empilait un abonnement réseau de plus.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (isOnline) {
      refreshCache().catchError((e) {
        debugPrint('⚠️ Erreur rafraîchissement cache au démarrage: $e');
      });
    } else {
      debugPrint('📵 Démarrage hors ligne - cache existant utilisé');
    }
  }

  /// Rafraîchit le cache depuis Supabase, au plus une fois par minute.
  Future<void> refreshCache() async {
    if (!isOnline) return;

    final now = DateTime.now();
    if (_lastCacheRefresh != null && now.difference(_lastCacheRefresh!) < const Duration(minutes: 1)) {
      return;
    }
    _lastCacheRefresh = now;

    try {
      final exercises = await _loadExercisesDirectly();
      final templates = await db.DatabaseService.getWorkoutTemplates(includePublic: true);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_exercisesCacheKey, jsonEncode(exercises.map(_exerciseToJson).toList()));
      await prefs.setString(_exercisesCacheLangKey, LocalizationService.instance.currentLanguageCode);

      final templatesJson = templates.map((t) => {
        'id': t.id,
        'name': t.name,
        'description': t.description,
        'type': t.type,
        'estimatedDuration': t.estimatedDuration,
        'exercises': t.exercises.map((e) => {
          'exercise': _exerciseToJson(e.exercise),
          'sets': e.sets,
          'suggestedRepsMin': e.suggestedRepsMin,
          'suggestedRepsMax': e.suggestedRepsMax,
        }).toList(),
        'isCustom': t.isCustom,
      }).toList();
      await prefs.setString(_templatesCacheKey, jsonEncode(templatesJson));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('✅ Cache exercices/programmes rafraîchi');
    } catch (e) {
      debugPrint('❌ Erreur lors du rafraîchissement du cache: $e');
    }
  }

  static Map<String, dynamic> _exerciseToJson(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'muscleGroup': e.muscleGroup,
        'equipment': e.equipment,
        'description': e.description,
        'isCustom': e.isCustom,
      };

  /// Charge les exercices directement depuis Supabase (sans passer par
  /// getSystemExercises, qui retomberait sur ce cache).
  Future<List<Exercise>> _loadExercisesDirectly() async {
    final List<Exercise> exercises = [];

    try {
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

  /// Les exercices tels qu'ils ont été mis en cache la dernière fois.
  Future<List<Exercise>> getCachedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_exercisesCacheKey);
    if (jsonString == null) return [];

    // Un cache écrit dans une autre langue ne sert à rien : ses noms
    // partiraient tels quels dans l'historique. Mieux vaut rien, et laisser
    // l'appelant relire la base.
    final cacheLang = prefs.getString(_exercisesCacheLangKey);
    if (cacheLang != null && cacheLang != LocalizationService.instance.currentLanguageCode) {
      debugPrint('🌍 Cache des exercices en $cacheLang, ignoré');
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Exercise(
                id: json['id'] ?? '',
                name: json['name'] ?? '',
                muscleGroup: json['muscleGroup'] ?? '',
                equipment: json['equipment'] ?? '',
                description: json['description'] ?? '',
                isCustom: json['isCustom'] ?? false,
              ))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du décodage du cache: $e');
      return [];
    }
  }

  /// Les programmes tels qu'ils ont été mis en cache la dernière fois. Écrit
  /// à chaque rafraîchissement, lu par la page Programmes quand le réseau
  /// manque.
  Future<List<WorkoutProgram>> getCachedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesCacheKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => WorkoutProgram(
                id: json['id'] ?? '',
                name: json['name'] ?? '',
                description: json['description'] ?? '',
                type: json['type'] ?? '',
                estimatedDuration: json['estimatedDuration'] ?? 45,
                exercises: (json['exercises'] as List)
                    .map((e) => ProgramExercise(
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
                        ))
                    .toList(),
                isCustom: json['isCustom'] ?? false,
              ))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du décodage des templates: $e');
      return [];
    }
  }

  /// Un exercice créé sans réseau : un id temporaire, remplacé par le vrai
  /// à la prochaine synchronisation.
  Future<Exercise> createOfflineCustomExercise({
    required String name,
    required String muscleGroup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

    final exercise = Exercise(
      id: tempId,
      name: name,
      muscleGroup: muscleGroup,
      isCustom: true,
    );

    final exercises = await getCachedExercises()..add(exercise);
    await prefs.setString(_exercisesCacheKey, jsonEncode(exercises.map(_exerciseToJson).toList()));

    final customJson = prefs.getString(_customExercisesCacheKey);
    final List<dynamic> customExercises = customJson != null ? jsonDecode(customJson) : [];
    customExercises.add({
      'tempId': tempId,
      'name': name,
      'muscleGroup': muscleGroup,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_customExercisesCacheKey, jsonEncode(customExercises));

    return exercise;
  }

  /// Envoie les exercices créés hors ligne et remplace leurs ids temporaires.
  /// Appelé par le store avant chaque envoi de séance.
  Future<void> syncCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString(_customExercisesCacheKey);
    if (customJson == null) return;

    final List<dynamic> customExercises = jsonDecode(customJson);
    final List<dynamic> remaining = [];

    for (final exercise in customExercises) {
      try {
        final created = await db.DatabaseService.createCustomExercise(
          name: exercise['name'],
          muscleGroup: exercise['muscleGroup'],
        );
        if (created != null) {
          await _replaceExerciseId(exercise['tempId'], created.id);
        } else {
          remaining.add(exercise);
        }
      } catch (e) {
        debugPrint('❌ Erreur sync exercice custom: $e');
        remaining.add(exercise);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_customExercisesCacheKey);
    } else {
      await prefs.setString(_customExercisesCacheKey, jsonEncode(remaining));
    }
  }

  Future<void> _replaceExerciseId(String tempId, String realId) async {
    final exercises = await getCachedExercises();
    final index = exercises.indexWhere((e) => e.id == tempId);
    if (index == -1) return;
    exercises[index] = exercises[index].copyWith(id: realId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exercisesCacheKey, jsonEncode(exercises.map(_exerciseToJson).toList()));
  }

  /// Vide le catalogue. **Ne touche à aucune séance en attente** : changer de
  /// langue effaçait auparavant les séances non synchronisées.
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exercisesCacheKey);
    await prefs.remove(_customExercisesCacheKey);
    await prefs.remove(_templatesCacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
