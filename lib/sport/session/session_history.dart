import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/sport_models.dart';
import '../../services/ryze_connectivity.dart';

/// Une série de la dernière fois.
class LastSet {
  const LastSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;

  Map<String, dynamic> toJson() => {'w': weightKg, 'r': reps};

  factory LastSet.fromJson(Map<String, dynamic> m) =>
      LastSet(weightKg: (m['w'] as num?)?.toDouble() ?? 0, reps: (m['r'] as num?)?.toInt() ?? 0);
}

/// Ce qu'on a fait la dernière fois sur un exercice, pour l'écrire en
/// fantôme dans chaque série.
///
/// Trois sources, dans l'ordre : la mémoire, le téléphone, Supabase. Le
/// téléphone est écrit à chaque séance terminée, donc « la dernière fois »
/// marche hors ligne pour tout ce qui a été fait dans cette app.
class LastSets {
  LastSets._();

  static const _key = 'session_last_sets_v1';
  static const _prKey = 'session_personal_records_v1';
  static final Map<String, List<LastSet>> _memory = {};

  /// Le plus lourd jamais soulevé sur un exercice, par clé d'exercice.
  static final Map<String, double> _records = {};

  static String keyOf(Exercise e) => e.id.isNotEmpty ? e.id : e.name.toLowerCase();

  static Future<List<LastSet>?> load(Exercise exercise) async {
    final key = keyOf(exercise);
    final cached = _memory[key];
    if (cached != null) return cached;

    final onDisk = await _readDisk();
    final local = onDisk[key];
    if (local != null && local.isNotEmpty) {
      _memory[key] = local;
      // on rafraîchit quand même depuis le réseau, sans attendre
      if (RyzeConnectivity.instance.online.value) _refresh(exercise, key, onDisk);
      return local;
    }

    if (!RyzeConnectivity.instance.online.value) return null;
    return _refresh(exercise, key, onDisk);
  }

  static Future<List<LastSet>?> _refresh(Exercise exercise, String key, Map<String, List<LastSet>> onDisk) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      var query = client.from('workout_set_history').select('history_session_id, weight, reps, set_order, performed_at').eq('user_id', userId);
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(exercise.id);
      if (isUuid) {
        query = exercise.isCustom ? query.eq('custom_exercise_id', exercise.id) : query.eq('exercise_id', exercise.id);
      } else {
        query = query.eq('exercise_name', exercise.name);
      }
      final rows = await query.order('performed_at', ascending: false).limit(12).timeout(const Duration(seconds: 4));
      if (rows.isEmpty) return null;

      final sessionId = rows.first['history_session_id'];
      final sets = rows.where((r) => r['history_session_id'] == sessionId).toList()
        ..sort((a, b) => ((a['set_order'] as num?) ?? 0).compareTo((b['set_order'] as num?) ?? 0));
      final out = sets
          .map((r) => LastSet(weightKg: (r['weight'] as num?)?.toDouble() ?? 0, reps: (r['reps'] as num?)?.toInt() ?? 0))
          .toList();
      if (out.isEmpty) return null;

      _memory[key] = out;
      onDisk[key] = out;
      await _writeDisk(onDisk);
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [LAST SETS] $e');
      return null;
    }
  }

  /// Le record personnel sur un exercice : le plus lourd de tous les temps,
  /// pas le plus lourd de la dernière fois.
  ///
  /// La pastille de record se décrochait sur « plus lourd que la séance
  /// précédente » : une charge montée il y a six mois puis abandonnée ne
  /// comptait pas, et une reprise se faisait féliciter comme un record. La
  /// pastille est la seule chose de la séance qui a le droit de se faire
  /// remarquer ; si elle ment, elle ne vaut plus rien.
  ///
  /// Mémoire, téléphone, puis Supabase — comme la dernière fois, et pour la
  /// même raison : ça doit marcher en salle, sans réseau.
  static Future<double> best(Exercise exercise) async {
    final key = keyOf(exercise);
    final cached = _records[key];
    if (cached != null) return cached;

    final onDisk = await _readRecords();
    final local = onDisk[key];
    if (local != null) {
      _records[key] = local;
      if (RyzeConnectivity.instance.online.value) unawaited(_refreshBest(exercise, key, onDisk));
      return local;
    }

    if (!RyzeConnectivity.instance.online.value) return 0;
    return await _refreshBest(exercise, key, onDisk) ?? 0;
  }

  static Future<double?> _refreshBest(Exercise exercise, String key, Map<String, double> onDisk) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      var query = client.from('workout_set_history').select('weight').eq('user_id', userId);
      final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(exercise.id);
      if (isUuid) {
        query = exercise.isCustom ? query.eq('custom_exercise_id', exercise.id) : query.eq('exercise_id', exercise.id);
      } else {
        query = query.eq('exercise_name', exercise.name);
      }
      final rows = await query.order('weight', ascending: false).limit(1).timeout(const Duration(seconds: 4));
      final top = rows.isEmpty ? 0.0 : ((rows.first['weight'] as num?)?.toDouble() ?? 0);

      _records[key] = top;
      onDisk[key] = top;
      await _writeRecords(onDisk);
      return top;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [PR] $e');
      return null;
    }
  }

  /// Une séance vient d'être terminée : ses séries deviennent « la dernière
  /// fois » de chacun de ses exercices.
  static Future<void> remember(WorkoutSession session) async {
    try {
      final onDisk = await _readDisk();
      // Les records connus sont relus avant d'être comparés : la mémoire peut
      // être vide sur cet exercice, et un record de l'an dernier ne doit pas
      // se faire écraser par la séance du jour.
      final stored = await _readRecords();
      var improved = false;
      for (final e in session.exercises) {
        final sets = e.sets.where((s) => s.reps > 0).map((s) => LastSet(weightKg: s.weight, reps: s.reps)).toList();
        if (sets.isEmpty) continue;
        final key = keyOf(e.exercise);
        _memory[key] = sets;
        onDisk[key] = sets;
        // Le record de la journée devient le record tout court, sans attendre
        // que le serveur le confirme : la séance suivante peut être hors ligne.
        final heaviest = sets.map((s) => s.weightKg).reduce((a, b) => a > b ? a : b);
        if (heaviest > (stored[key] ?? _records[key] ?? 0)) {
          stored[key] = heaviest;
          _records[key] = heaviest;
          improved = true;
        }
      }
      await _writeDisk(onDisk);
      if (improved) await _writeRecords(stored);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [LAST SETS] remember: $e');
    }
  }

  static Future<Map<String, List<LastSet>>> _readDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as List).map((s) => LastSet.fromJson(Map<String, dynamic>.from(s as Map))).toList()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeDisk(Map<String, List<LastSet>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()))));
  }

  static Future<Map<String, double>> _readRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prKey);
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeRecords(Map<String, double> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prKey, jsonEncode(data));
  }
}
