import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cardio_service.dart';
import '../services/global_state_manager.dart';
import '../services/sport_dashboard_service.dart';
import '../services/weekly_planner_service.dart';
import 'sport_goal.dart';

/// Une séance est un anneau ; la forme ne change pas, la famille si.
enum SportKind { strength, cardio }

/// Une séance passée, telle que l'onglet la lit — quelle que soit la table.
class SportSessionRow {
  const SportSessionRow({
    required this.id,
    required this.kind,
    required this.name,
    required this.date,
    required this.minutes,
    required this.kcal,
    this.distanceKm,
    this.activityType,
    this.intensity,
  });

  final String id;
  final SportKind kind;
  final String name;
  final DateTime date;
  final int minutes;
  final int kcal;
  final double? distanceKm;
  final String? activityType;
  final String? intensity;

  String get dayKey => SportData.dayKey(date);
}

/// La semaine en cours, en quatre chiffres — et l'objectif si l'utilisateur
/// en a fixé un. Nul sinon : un objectif qu'on n'a pas choisi n'en est pas un.
class SportWeek {
  const SportWeek({required this.sessions, required this.minutes, required this.kcal, required this.streak, required this.goal});

  final int sessions;
  final int minutes;
  final int kcal;
  final int streak;
  final int? goal;

  static const empty = SportWeek(sessions: 0, minutes: 0, kcal: 0, streak: 0, goal: null);
}

/// Ce que l'onglet savait la derniere fois : de quoi dessiner la semaine
/// avant le premier aller-retour.
class SportSnapshot {
  const SportSnapshot({required this.week, required this.kinds});

  final SportWeek week;
  final Map<String, Set<SportKind>> kinds;
}

/// Les lectures de l'onglet Sport, sur les deux tables vivantes :
/// `workout_session_summaries` pour la musculation, `cardio_sessions` pour
/// tout le reste (le HIIT y compris). Rien n'est calculé ici qui ne vienne
/// d'une ligne ; la suppression passe par les chemins du planificateur
/// existants pour que la case cochée du jour disparaisse avec la séance.
class SportData {
  SportData._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Le lundi de la semaine en cours.
  static DateTime monday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - (n.weekday - 1));
  }

  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ------------------------------------------------------ ce qu'on sait deja

  static const String _weekKey = 'sport_week_v1';

  /// La semaine et les sept anneaux, gardes sur le telephone.
  ///
  /// Le tableau de bord ne vit qu'en memoire : apres un lancement, la premiere
  /// ouverture de l'onglet attendait le reseau et montrait des zeros en
  /// attendant, la ou Nutrition ouvre sur l'etat du jour deja restaure. Ce qui
  /// a ete lu une fois est ecrit ici et relu avant la premiere image. Date du
  /// lundi : une semaine finie ne se montre pas a la place de celle qui
  /// commence.
  static Future<void> remember(SportWeek w, Map<String, Set<SportKind>> kinds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _weekKey,
        jsonEncode({
          'monday': dayKey(monday()),
          'sessions': w.sessions,
          'minutes': w.minutes,
          'kcal': w.kcal,
          'streak': w.streak,
          'kinds': {for (final e in kinds.entries) e.key: [for (final k in e.value) k.name]},
        }),
      );
    } catch (e) {
      debugPrint('SportData.remember: $e');
    }
  }

  /// Ce qui a ete garde, si c'est bien de cette semaine. Nul sinon.
  static Future<SportSnapshot?> lastKnown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weekKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['monday'] != dayKey(monday())) return null;
      final goal = await SportGoal.load();
      return SportSnapshot(
        week: SportWeek(
          sessions: m['sessions'] as int? ?? 0,
          minutes: m['minutes'] as int? ?? 0,
          kcal: m['kcal'] as int? ?? 0,
          streak: m['streak'] as int? ?? 0,
          goal: goal,
        ),
        kinds: {
          for (final e in (m['kinds'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: {
              for (final k in (e.value as List? ?? const []))
                SportKind.values.firstWhere((v) => v.name == k, orElse: () => SportKind.strength),
            },
        },
      );
    } catch (e) {
      debugPrint('SportData.lastKnown: $e');
      return null;
    }
  }

  static Future<SportWeek> week() async {
    final goal = await SportGoal.load();
    try {
      final d = await SportDashboardService.getDashboardData();
      return SportWeek(sessions: d.totalSessions, minutes: d.totalDurationMinutes, kcal: d.totalCalories, streak: d.streak, goal: goal);
    } catch (e) {
      debugPrint('SportData.week: $e');
      return SportWeek(sessions: 0, minutes: 0, kcal: 0, streak: 0, goal: goal);
    }
  }

  /// Les dernières séances, toutes familles, la plus récente d'abord.
  static Future<List<SportSessionRow>> recent({int limit = 3}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final results = await Future.wait([
        _client
            .from('workout_session_summaries')
            .select('id, session_name, duration_minutes, calories_burned, session_date, created_at, intensity')
            .eq('user_id', userId)
            .order('session_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit),
        _client
            .from('cardio_sessions')
            .select('id, activity_type, activity_title, format_title, duration_seconds, calories, distance_km, intensity, session_date, created_at')
            .eq('user_id', userId)
            .eq('is_completed', true)
            .order('session_date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit),
      ]);
      final rows = [
        for (final r in results[0]) _strength(r),
        for (final r in results[1]) _cardio(r),
      ]..sort((a, b) => b.date.compareTo(a.date));
      return rows.take(limit).toList();
    } catch (e) {
      debugPrint('SportData.recent: $e');
      return const [];
    }
  }

  /// Les séances d'un jour.
  static Future<List<SportSessionRow>> onDay(DateTime day) async {
    try {
      final d = await SportDashboardService.getDaySessionDetails(dayKey(day));
      final rows = [
        for (final r in (d['musculation'] as List? ?? const [])) _strength(r as Map<String, dynamic>),
        for (final r in (d['cardio'] as List? ?? const [])) _cardio(r as Map<String, dynamic>),
      ]..sort((a, b) => b.date.compareTo(a.date));
      return rows;
    } catch (e) {
      debugPrint('SportData.onDay: $e');
      return const [];
    }
  }

  /// Quelle famille a une séance quel jour, sur une plage — pour la bande.
  static Future<Map<String, Set<SportKind>>> kinds({required DateTime from, required DateTime to}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const {};
    final a = dayKey(from), b = dayKey(to);
    try {
      final results = await Future.wait([
        _client.from('workout_session_summaries').select('session_date').eq('user_id', userId).gte('session_date', a).lte('session_date', b),
        _client.from('cardio_sessions').select('session_date').eq('user_id', userId).eq('is_completed', true).gte('session_date', a).lte('session_date', b),
      ]);
      final out = <String, Set<SportKind>>{};
      for (final r in results[0]) {
        out.putIfAbsent(r['session_date'] as String, () => {}).add(SportKind.strength);
      }
      for (final r in results[1]) {
        out.putIfAbsent(r['session_date'] as String, () => {}).add(SportKind.cardio);
      }
      return out;
    } catch (e) {
      debugPrint('SportData.kinds: $e');
      return const {};
    }
  }

  /// Supprime une séance et, si elle cochait un jour du planificateur, la
  /// case avec. Lève en cas d'échec : l'appelant le dit.
  static Future<void> delete(SportSessionRow row) async {
    switch (row.kind) {
      case SportKind.strength:
        final planned = await WeeklyPlannerService.findPlannedWorkoutBySessionId(row.id);
        if (planned != null) {
          final ok = await WeeklyPlannerService.deleteWorkoutWithSync(planned.id);
          if (!ok) throw Exception('deleteWorkoutWithSync failed');
        } else {
          await SportDashboardService.deleteMusculationSession(row.id);
        }
      case SportKind.cardio:
        final planned = await WeeklyPlannerService.findPlannedCardioBySessionId(row.id);
        if (planned != null) {
          final ok = await WeeklyPlannerService.deleteCardioWithSync(planned.id);
          if (!ok) throw Exception('deleteCardioWithSync failed');
        } else {
          await CardioService.deleteCardioSession(row.id);
        }
    }
    SportDashboardService.invalidateCache();
    try {
      await GlobalStateManager.instance.refreshSportData();
    } catch (_) {}
  }

  // ------------------------------------------------------------- mapping

  static DateTime _when(Map<String, dynamic> r) {
    final day = DateTime.tryParse('${r['session_date']}') ?? DateTime.now();
    final created = DateTime.tryParse('${r['created_at'] ?? ''}')?.toLocal();
    if (created != null && created.year == day.year && created.month == day.month && created.day == day.day) return created;
    return DateTime(day.year, day.month, day.day, 12);
  }

  static SportSessionRow _strength(Map<String, dynamic> r) => SportSessionRow(
        id: '${r['id']}',
        kind: SportKind.strength,
        name: '${r['session_name'] ?? ''}',
        date: _when(r),
        minutes: (r['duration_minutes'] as num?)?.round() ?? 0,
        kcal: (r['calories_burned'] as num?)?.round() ?? 0,
        intensity: r['intensity'] as String?,
      );

  static SportSessionRow _cardio(Map<String, dynamic> r) => SportSessionRow(
        id: '${r['id']}',
        kind: SportKind.cardio,
        name: '${r['activity_title'] ?? r['format_title'] ?? r['activity_type'] ?? ''}',
        date: _when(r),
        minutes: (((r['duration_seconds'] as num?)?.toDouble() ?? 0) / 60).round(),
        kcal: (r['calories'] as num?)?.round() ?? 0,
        distanceKm: (r['distance_km'] as num?)?.toDouble(),
        activityType: r['activity_type'] as String?,
        intensity: r['intensity'] as String?,
      );
}
