import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'global_state_manager.dart';
import 'meal_widget_data_provider.dart';
import 'ryze_connectivity.dart';

/// Ce qui empêche un verre d'eau de se perdre.
///
/// L'eau n'avait aucune file : hors ligne, le verre s'affichait, l'écriture
/// échouait, le verre disparaissait. La musculation, elle, garde ses séances
/// sur le téléphone depuis longtemps — c'est le même mécanisme, en plus petit.
///
/// L'ordre ne peut pas perdre de données :
/// 1. l'opération est **écrite sur le téléphone** ;
/// 2. seulement alors on tente Supabase ; en cas de succès elle sort de la
///    file, sinon elle y reste et sera rejouée.
///
/// L'identifiant de la ligne est tiré ici, pas en base : un rejeu après une
/// application tuée entre l'insertion et le retrait de la file retombe sur la
/// même clé primaire, et ne peut donc pas ajouter le verre deux fois.
class WaterQueue {
  WaterQueue._();

  static final WaterQueue instance = WaterQueue._();

  static const _key = 'water_pending_v1';

  /// Combien d'opérations attendent. Les surfaces l'affichent.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  bool _initialized = false;
  VoidCallback? _onlineListener;

  SupabaseClient get _client => Supabase.instance.client;

  /// Compte ce qui attend et lance un premier envoi. Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      pendingCount.value = (await _read()).length;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EAU] init: $e');
    }
    _onlineListener ??= () {
      if (RyzeConnectivity.instance.online.value) unawaited(flush());
    };
    RyzeConnectivity.instance.online.addListener(_onlineListener!);
    unawaited(flush());
  }

  // ------------------------------------------------------------------ ajout

  /// Garde un verre pour plus tard. Rend l'identifiant de la ligne à venir,
  /// pour que l'appelant puisse l'annuler sans réseau.
  Future<String> keepAdd({
    required String userId,
    required int amount,
    required String sourceType,
    String? notes,
    required DateTime consumedAt,
    String? id,
  }) async {
    final op = _WaterOp(
      id: id ?? const Uuid().v4(),
      kind: _Kind.add,
      userId: userId,
      amount: amount,
      sourceType: sourceType,
      notes: notes,
      at: consumedAt,
      createdAt: DateTime.now(),
    );
    final list = await _read();
    list.add(op);
    await _write(list);
    if (kDebugMode) debugPrint('💧 [EAU] $amount ml gardés sur le téléphone (${list.length} en attente)');
    return op.id;
  }

  /// Garde une suppression pour plus tard.
  Future<void> keepDelete({required String entryId, required int amount, required DateTime at}) async {
    final list = await _read();
    // Une ligne encore en attente d'envoi n'a jamais existé côté serveur :
    // il suffit de la retirer de la file, personne n'a rien à supprimer.
    final pendingAdd = list.indexWhere((o) => o.kind == _Kind.add && o.id == entryId);
    if (pendingAdd >= 0) {
      list.removeAt(pendingAdd);
      await _write(list);
      if (kDebugMode) debugPrint('💧 [EAU] verre retiré avant d\'avoir été envoyé');
      return;
    }
    list.add(_WaterOp(
      id: entryId,
      kind: _Kind.remove,
      userId: '',
      amount: amount,
      sourceType: '',
      notes: null,
      at: at,
      createdAt: DateTime.now(),
    ));
    await _write(list);
  }

  /// Le verre le plus récent qui attend encore, s'il y en a un. Sert au geste
  /// « je retire un verre » quand celui qu'on retire n'est pas encore parti.
  Future<String?> lastPendingAddId() async {
    final list = await _read();
    for (var i = list.length - 1; i >= 0; i--) {
      if (list[i].kind == _Kind.add) return list[i].id;
    }
    return null;
  }

  // ------------------------------------------------------------- le compte

  /// Ce que la file ajoute au total d'un jour donné, en millilitres.
  ///
  /// Sans cela, une relecture depuis la base pendant que la file n'est pas
  /// vide ferait retomber le compteur : la base ne connaît pas encore ces
  /// verres. Les suppressions en attente comptent en négatif.
  Future<int> pendingMlOn(DateTime day) async {
    try {
      final list = await _read();
      var total = 0;
      for (final op in list) {
        if (!_sameDay(op.at, day)) continue;
        total += op.kind == _Kind.add ? op.amount : -op.amount;
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EAU] lecture du compte: $e');
      return 0;
    }
  }

  /// Les verres d'un jour qui attendent encore d'être envoyés.
  ///
  /// Le journal lit ses entrées dans la base pour savoir lesquelles retirer.
  /// Hors ligne cette lecture rend une liste vide, donc retirer un verre
  /// qu'on venait d'ajouter ne faisait rien : il faut que ceux-là s'y voient.
  Future<List<PendingGlass>> pendingAddsOn(DateTime day) async {
    final list = await _read();
    return [
      for (final op in list)
        if (op.kind == _Kind.add && _sameDay(op.at, day))
          PendingGlass(id: op.id, amount: op.amount, at: op.at),
    ];
  }

  // ------------------------------------------------------------------ envoi

  /// Envoie ce qui attend. Gardé contre la réentrance, sort si l'interface est
  /// coupée, et ne supprime **jamais** une opération sur échec : elle attend
  /// son tour suivant.
  Future<void> flush({bool force = false}) async {
    if (syncing.value) return;
    if (!RyzeConnectivity.instance.online.value) return;
    var list = await _read();
    if (list.isEmpty) {
      pendingCount.value = 0;
      return;
    }

    syncing.value = true;
    var sent = 0;
    try {
      final now = DateTime.now();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final op in list) {
        if (!force && op.nextAttemptAt != null && op.nextAttemptAt!.isAfter(now)) continue;
        final ok = await _send(op);
        list = await _read();
        final idx = list.indexWhere((e) => e.id == op.id && e.kind == op.kind);
        if (idx < 0) continue;
        if (ok) {
          list.removeAt(idx);
          sent++;
        } else {
          final attempts = op.attempts + 1;
          list[idx] = op.copyWith(
            attempts: attempts,
            nextAttemptAt: now.add(Duration(minutes: math.min(math.pow(2, attempts).toInt(), 60))),
          );
        }
        await _write(list);
      }
    } finally {
      pendingCount.value = (await _read()).length;
      syncing.value = false;
    }

    // Le total du jour se relit une fois la file vidée.
    //
    // Sans cela, un envoi qui se termine entre la lecture de la base et celle
    // de la file donnait un compteur trop bas : la base n'avait pas encore le
    // verre au moment de la lecture, et la file ne l'avait déjà plus au moment
    // du compte. La relecture tranche.
    if (sent > 0) {
      try {
        await GlobalStateManager.instance.refreshNutrition();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [EAU] relecture après envoi: $e');
      }
      unawaited(MealWidgetDataProvider.updateWidgetData());
    }
  }

  /// Le « Réessayer » de l'utilisateur : sans délai d'attente.
  Future<void> retryNow() => flush(force: true);

  Future<bool> _send(_WaterOp op) async {
    try {
      if (op.kind == _Kind.add) {
        await _client.from('water_entries').insert({
          'id': op.id,
          'user_id': op.userId,
          'amount': op.amount,
          'source_type': op.sourceType,
          'notes': op.notes,
          'consumed_at': op.at.toIso8601String(),
        }).timeout(const Duration(seconds: 10));
      } else {
        await _client.from('water_entries').delete().eq('id', op.id).timeout(const Duration(seconds: 10));
      }
      return true;
    } catch (e) {
      final text = e.toString().toLowerCase();
      // Déjà écrite : c'est un rejeu, pas un échec. La clé primaire vient de
      // nous, donc un doublon ne peut vouloir dire que ça.
      if (text.contains('duplicate key') || text.contains('23505')) {
        if (kDebugMode) debugPrint('💧 [EAU] ${op.id} déjà en base, rejeu');
        return true;
      }
      if (kDebugMode) debugPrint('📵 [EAU] envoi ${op.id}: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------- disque

  Future<List<_WaterOp>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => _WaterOp.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EAU] lecture file: $e');
      return [];
    }
  }

  Future<void> _write(List<_WaterOp> list) async {
    final prefs = await SharedPreferences.getInstance();
    if (list.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(list.map((o) => o.toJson()).toList()));
    }
    pendingCount.value = list.length;
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Un verre gardé sur le téléphone, tel que les écrans le voient.
class PendingGlass {
  const PendingGlass({required this.id, required this.amount, required this.at});

  final String id;
  final int amount;
  final DateTime at;
}

enum _Kind { add, remove }

/// Un verre qui attend Supabase, ou son retrait.
class _WaterOp {
  const _WaterOp({
    required this.id,
    required this.kind,
    required this.userId,
    required this.amount,
    required this.sourceType,
    required this.notes,
    required this.at,
    required this.createdAt,
    this.attempts = 0,
    this.nextAttemptAt,
  });

  /// Pour un ajout, la clé primaire de la ligne à venir : c'est elle qui rend
  /// le rejeu idempotent. Pour un retrait, la ligne à supprimer.
  final String id;
  final _Kind kind;
  final String userId;
  final int amount;
  final String sourceType;
  final String? notes;
  final DateTime at;
  final DateTime createdAt;
  final int attempts;
  final DateTime? nextAttemptAt;

  _WaterOp copyWith({int? attempts, DateTime? nextAttemptAt}) => _WaterOp(
        id: id,
        kind: kind,
        userId: userId,
        amount: amount,
        sourceType: sourceType,
        notes: notes,
        at: at,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'userId': userId,
        'amount': amount,
        'sourceType': sourceType,
        'notes': notes,
        'at': at.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'nextAttemptAt': nextAttemptAt?.toIso8601String(),
      };

  factory _WaterOp.fromJson(Map<String, dynamic> m) => _WaterOp(
        id: m['id'] as String,
        kind: m['kind'] == 'remove' ? _Kind.remove : _Kind.add,
        userId: m['userId'] as String? ?? '',
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        sourceType: m['sourceType'] as String? ?? 'manual',
        notes: m['notes'] as String?,
        at: DateTime.tryParse(m['at'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        attempts: (m['attempts'] as num?)?.toInt() ?? 0,
        nextAttemptAt: DateTime.tryParse(m['nextAttemptAt'] as String? ?? ''),
      );
}
