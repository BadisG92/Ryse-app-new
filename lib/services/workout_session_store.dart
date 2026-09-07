import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/sport_models.dart';
import 'analytics_service.dart';
import 'dashboard_service.dart';
import 'database_service.dart' as db;
import 'global_state_manager.dart';
import 'notification_service.dart';
import 'offline_workout_service.dart';
import 'ryze_connectivity.dart';
import 'sport_dashboard_service.dart';
import 'streak_service.dart';
import 'weekly_planner_service.dart';

/// Ce qui empêche une séance de musculation de se perdre.
///
/// Avant, une séance terminée sans réseau disparaissait : le nom unique était
/// demandé à Supabase avant la moindre sauvegarde, la requête levait, rien
/// n'était mis en file, et l'app célébrait quand même. Ici l'ordre est
/// inversé et ne peut plus perdre de données :
///
/// 1. le payload complet est construit sans toucher au réseau ;
/// 2. il est **écrit sur le téléphone** dans une file durable ;
/// 3. seulement alors on tente Supabase ; en cas de succès l'entrée sort de
///    la file, sinon elle y reste et sera rejouée.
///
/// « Hors ligne » et « en ligne mais ça échoue » sont donc le même chemin.
/// Le store tient aussi le brouillon de la séance en cours, écrit à chaque
/// série, pour qu'une app tuée par iOS ne coûte plus rien.
class WorkoutSessionStore {
  WorkoutSessionStore._();

  static final WorkoutSessionStore instance = WorkoutSessionStore._();

  static const _draftKey = 'strength_session_draft_v1';
  static const _pendingKey = 'strength_pending_v2';
  static const _legacyPendingKey = 'offline_pending_sessions';

  /// Un brouillon plus vieux que ça n'est plus une séance en cours.
  static const _draftLife = Duration(hours: 36);

  /// Combien de séances attendent d'être envoyées. Les surfaces l'affichent.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  bool _initialized = false;
  VoidCallback? _onlineListener;

  /// Migre la file de l'ancien service, compte, et lance un premier envoi.
  /// Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _migrateLegacyQueue();
      pendingCount.value = (await _readPending()).length;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] init: $e');
    }
    // Un retour en ligne déclenche l'envoi. Une seule écoute, retirée si le
    // store est réinitialisé.
    _onlineListener ??= () {
      if (RyzeConnectivity.instance.online.value) unawaited(syncPending());
    };
    RyzeConnectivity.instance.online.addListener(_onlineListener!);
    unawaited(syncPending());
  }

  // ------------------------------------------------------------ brouillon

  /// La séance en cours, telle qu'elle est. Appelé à chaque changement de
  /// série et au passage en arrière-plan.
  Future<void> saveDraft(Map<String, dynamic> sessionJson, {int current = 0, DateTime? restEndsAt}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _draftKey,
        jsonEncode({
          'session': sessionJson,
          'current': current,
          'restEndsAt': restEndsAt?.toIso8601String(),
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] brouillon: $e');
    }
  }

  Future<SessionDraft?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(map['savedAt'] as String? ?? '') ?? DateTime.now();
      if (DateTime.now().difference(savedAt) > _draftLife) {
        await prefs.remove(_draftKey);
        return null;
      }
      return SessionDraft(
        session: Map<String, dynamic>.from(map['session'] as Map),
        current: (map['current'] as num?)?.toInt() ?? 0,
        restEndsAt: DateTime.tryParse(map['restEndsAt'] as String? ?? ''),
        savedAt: savedAt,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] lecture brouillon: $e');
      return null;
    }
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- source

  /// D'où vient la séance, pour l'historique. Le même raisonnement qu'avant,
  /// sauf que la question posée à Supabase ne peut plus bloquer : trois
  /// secondes, puis on tranche sans elle.
  static Future<({String source, String? templateId})> resolveSource({
    required bool isFromAI,
    required bool isFromProgram,
    String? guidedTemplateId,
  }) async {
    if (isFromAI) return (source: 'ai_coach', templateId: null);
    if (!isFromProgram) return (source: 'manual', templateId: null);
    var fromAI = false;
    if (guidedTemplateId != null) {
      try {
        fromAI = await db.DatabaseService.isTemplateFromAI(guidedTemplateId).timeout(const Duration(seconds: 3));
      } catch (_) {
        fromAI = false;
      }
    }
    return fromAI ? (source: 'ai_coach', templateId: null) : (source: 'guided_template', templateId: guidedTemplateId);
  }

  // ------------------------------------------------------------------- fin

  /// Termine une séance. Retourne [FinishOutcome.synced] si Supabase l'a
  /// reçue tout de suite, [FinishOutcome.queued] sinon — et dans ce cas elle
  /// est déjà à l'abri sur le téléphone.
  Future<FinishOutcome> finish({
    required WorkoutSession session,
    required String sessionSource,
    String? guidedTemplateId,
    String? plannedWorkoutId,
    required String intensity,
    required int durationMinutes,
    required int caloriesBurned,
    bool saveAsProgram = false,
    bool isFromAI = false,
  }) async {
    final pending = PendingWorkout(
      id: const Uuid().v4(),
      historySessionId: const Uuid().v4(),
      session: session,
      sessionSource: sessionSource,
      guidedTemplateId: guidedTemplateId,
      plannedWorkoutId: plannedWorkoutId,
      intensity: intensity,
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      saveAsProgram: saveAsProgram,
      isFromAI: isFromAI,
      createdAt: DateTime.now(),
    );

    // 1. À l'abri d'abord. Tout ce qui suit peut échouer sans rien perdre.
    await enqueue(pending);
    await clearDraft();

    // 2. Ce qui est local se fait tout de suite : l'app doit refléter la
    //    séance même sans réseau.
    try {
      GlobalStateManager.instance.updateWorkout(true);
    } catch (_) {}
    unawaited(NotificationService().updateLastActivity());
    unawaited(NotificationService().cancelPlannedActivityReminder());
    unawaited(NotificationService().cancelActivityBasedReminders());
    unawaited(AnalyticsService.logWorkoutCompleted(
      workoutType: 'strength',
      durationMinutes: durationMinutes,
      exerciseCount: session.exercises.length,
      caloriesBurned: caloriesBurned,
    ));

    // 3. Puis le réseau, sans sonde : l'écriture elle-même dira.
    await syncPending(probe: false, onlyId: pending.id);
    final still = await _readPending();
    return still.any((p) => p.id == pending.id) ? FinishOutcome.queued : FinishOutcome.synced;
  }

  // ------------------------------------------------------------------ file

  Future<void> enqueue(PendingWorkout pending) async {
    final list = await _readPending();
    list.add(pending);
    await _writePending(list);
  }

  /// Envoie ce qui attend. Gardé contre la réentrance ; sort si l'interface
  /// est coupée ; sonde Supabase si demandé ; ne supprime **jamais** une
  /// entrée sur échec — elle attend son tour suivant, un peu plus tard.
  Future<void> syncPending({bool probe = true, String? onlyId, bool force = false}) async {
    if (syncing.value) return;
    if (!RyzeConnectivity.instance.online.value) return;
    var list = await _readPending();
    if (list.isEmpty) {
      pendingCount.value = 0;
      return;
    }
    if (probe && !await RyzeConnectivity.instance.reachable(force: force)) return;

    syncing.value = true;
    try {
      // Les exercices créés hors ligne d'abord, pour que leurs ids temporaires
      // deviennent réels avant que les séries y fassent référence.
      try {
        await OfflineWorkoutService().syncCustomExercises();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [SESSION STORE] exercices custom: $e');
      }

      final now = DateTime.now();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final p in list) {
        if (onlyId != null && p.id != onlyId) continue;
        if (!force && onlyId == null && p.nextAttemptAt != null && p.nextAttemptAt!.isAfter(now)) continue;
        final ok = await _persistOne(p);
        list = await _readPending();
        final idx = list.indexWhere((e) => e.id == p.id);
        if (idx < 0) continue;
        if (ok) {
          list.removeAt(idx);
        } else {
          final attempts = p.attempts + 1;
          list[idx] = p.copyWith(
            attempts: attempts,
            nextAttemptAt: now.add(Duration(minutes: math.min(math.pow(2, attempts).toInt(), 60))),
          );
        }
        await _writePending(list);
      }
    } finally {
      pendingCount.value = (await _readPending()).length;
      syncing.value = false;
    }
  }

  /// Le tap « Réessayer » : sans compteur, sans délai.
  Future<void> retryNow() => syncPending(probe: false, force: true);

  /// Une entrée vers Supabase, puis tout ce qui doit suivre — chaque étape
  /// dans son propre try/catch, pour qu'un planificateur muet ne fasse pas
  /// rejouer une séance déjà écrite.
  Future<bool> _persistOne(PendingWorkout p) async {
    Map<String, String>? result;
    try {
      result = await db.DatabaseService.persistCompletedWorkoutAsHistory(
        session: p.session,
        guidedTemplateId: p.guidedTemplateId,
        sessionSource: p.sessionSource,
        intensity: p.intensity,
        durationMinutes: p.durationMinutes,
        caloriesBurned: p.caloriesBurned,
        historySessionId: p.historySessionId,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (kDebugMode) debugPrint('📵 [SESSION STORE] envoi ${p.id}: $e');
      return false;
    }
    if (result == null) return false;

    final summaryId = result['summaryId'] ?? '';
    final sessionDate = p.session.endTime ?? p.createdAt;

    try {
      await WeeklyPlannerService.syncWorkoutSessionToPlanner(
        sessionId: summaryId,
        workoutName: p.session.name,
        sessionDate: sessionDate,
        durationMinutes: p.durationMinutes,
        historySessionId: p.historySessionId,
        plannedWorkoutId: p.plannedWorkoutId,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] planificateur: $e');
    }

    // Une séance de musculation terminée fait avancer la série, comme le
    // cardio, la nourriture et l'eau le font déjà.
    try {
      await StreakService.notifyActivity();
    } catch (_) {}

    if (p.saveAsProgram) {
      try {
        await db.DatabaseService.saveUserWorkoutTemplate(p.session, isFromAI: p.isFromAI);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [SESSION STORE] programme: $e');
      }
    }

    try {
      SportDashboardService.forceInvalidateAllCaches();
      DashboardService.invalidateAndRefreshAfterWorkout();
      await GlobalStateManager.instance.refreshSportData();
    } catch (_) {}

    return true;
  }

  // ---------------------------------------------------------------- disque

  Future<List<PendingWorkout>> _readPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => PendingWorkout.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] lecture file: $e');
      return [];
    }
  }

  Future<void> _writePending(List<PendingWorkout> list) async {
    final prefs = await SharedPreferences.getInstance();
    if (list.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(list.map((p) => p.toJson()).toList()));
    }
    pendingCount.value = list.length;
  }

  /// L'ancien service gardait ses séances sous une autre clé, dans un autre
  /// format. Un utilisateur qui en a une coincée ne doit pas la perdre.
  Future<void> _migrateLegacyQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyPendingKey);
    if (raw == null) return;
    try {
      final legacy = jsonDecode(raw) as List;
      final list = await _readPending();
      for (final e in legacy) {
        final m = Map<String, dynamic>.from(e as Map);
        list.add(PendingWorkout(
          id: m['id'] as String? ?? const Uuid().v4(),
          historySessionId: const Uuid().v4(),
          session: WorkoutSession.fromJson(Map<String, dynamic>.from(m['session'] as Map)),
          sessionSource: m['sessionSource'] as String? ?? 'manual',
          guidedTemplateId: m['guidedTemplateId'] as String?,
          plannedWorkoutId: null,
          intensity: m['intensity'] as String? ?? 'Modéré',
          durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 0,
          caloriesBurned: (m['caloriesBurned'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        ));
      }
      await _writePending(list);
      await prefs.remove(_legacyPendingKey);
      if (kDebugMode) debugPrint('✅ [SESSION STORE] ${legacy.length} séance(s) migrée(s)');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [SESSION STORE] migration: $e');
    }
  }
}

enum FinishOutcome { synced, queued }

/// La séance en cours, telle qu'elle a été écrite la dernière fois.
class SessionDraft {
  const SessionDraft({required this.session, required this.current, required this.restEndsAt, required this.savedAt});

  final Map<String, dynamic> session;
  final int current;
  final DateTime? restEndsAt;
  final DateTime savedAt;
}

/// Une séance terminée qui attend Supabase. Tout ce que l'écriture réclame
/// est là, y compris ce que l'ancienne file laissait tomber : le repas
/// planifié à cocher, et le souhait d'en faire un programme.
class PendingWorkout {
  const PendingWorkout({
    required this.id,
    required this.historySessionId,
    required this.session,
    required this.sessionSource,
    required this.guidedTemplateId,
    required this.plannedWorkoutId,
    required this.intensity,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.saveAsProgram = false,
    this.isFromAI = false,
    required this.createdAt,
    this.attempts = 0,
    this.nextAttemptAt,
    this.lastError,
  });

  final String id;

  /// Généré une fois, ici : c'est lui qui rend le rejeu idempotent côté base.
  final String historySessionId;
  final WorkoutSession session;
  final String sessionSource;
  final String? guidedTemplateId;
  final String? plannedWorkoutId;
  final String intensity;
  final int durationMinutes;
  final int caloriesBurned;
  final bool saveAsProgram;
  final bool isFromAI;
  final DateTime createdAt;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;

  PendingWorkout copyWith({int? attempts, DateTime? nextAttemptAt, String? lastError}) => PendingWorkout(
        id: id,
        historySessionId: historySessionId,
        session: session,
        sessionSource: sessionSource,
        guidedTemplateId: guidedTemplateId,
        plannedWorkoutId: plannedWorkoutId,
        intensity: intensity,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        saveAsProgram: saveAsProgram,
        isFromAI: isFromAI,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'historySessionId': historySessionId,
        'session': session.toJson(),
        'sessionSource': sessionSource,
        'guidedTemplateId': guidedTemplateId,
        'plannedWorkoutId': plannedWorkoutId,
        'intensity': intensity,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'saveAsProgram': saveAsProgram,
        'isFromAI': isFromAI,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'nextAttemptAt': nextAttemptAt?.toIso8601String(),
        'lastError': lastError,
      };

  factory PendingWorkout.fromJson(Map<String, dynamic> m) => PendingWorkout(
        id: m['id'] as String,
        historySessionId: m['historySessionId'] as String,
        session: WorkoutSession.fromJson(Map<String, dynamic>.from(m['session'] as Map)),
        sessionSource: m['sessionSource'] as String? ?? 'manual',
        guidedTemplateId: m['guidedTemplateId'] as String?,
        plannedWorkoutId: m['plannedWorkoutId'] as String?,
        intensity: m['intensity'] as String? ?? 'Modéré',
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 0,
        caloriesBurned: (m['caloriesBurned'] as num?)?.toInt() ?? 0,
        saveAsProgram: m['saveAsProgram'] as bool? ?? false,
        isFromAI: m['isFromAI'] as bool? ?? false,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        attempts: (m['attempts'] as num?)?.toInt() ?? 0,
        nextAttemptAt: DateTime.tryParse(m['nextAttemptAt'] as String? ?? ''),
        lastError: m['lastError'] as String?,
      );
}
