import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ryze_context.dart';
import '../config/supabase_config.dart';
import '../services/meal_widget_data_provider.dart';
import '../services/global_state_manager.dart';
import '../services/notification_service.dart';
import '../services/weekly_planner_service.dart';
import 'arc_banner.dart';
import 'arc_state.dart';

/// Le Winter Arc côté téléphone : il demande, il garde, il prévient.
///
/// Rien n'est calculé ici. La base décide ce qu'est une journée tenue, quand
/// elle se fige et ce que vaut la série (`arc_state()`, voir WINTER_ARC.md) ;
/// l'app se contente de redemander après chaque repas, verre ou séance, et de
/// garder la dernière réponse pour s'afficher tout de suite au lancement.
class ArcService extends ChangeNotifier {
  ArcService._();

  static final ArcService instance = ArcService._();

  ArcState? _state;
  String? _stateFor;
  StreamSubscription<StateChangeEvent>? _events;
  Timer? _debounce;
  Future<ArcState?>? _inflight;
  final Completer<void> _firstAnswer = Completer<void>();

  /// L'arc en cours, ou null tant que la base n'a pas répondu une fois.
  ArcState? get state {
    if (WeeklyPlannerService.isDemoMode) return ArcState.demo(DateTime.now());
    return _uid != null && _uid == _stateFor ? _state : null;
  }

  /// Se complète à la première réponse de la base, bonne ou non.
  Future<void> get firstAnswer => _firstAnswer.future;

  static String? get _uid => SupabaseConfig.client.auth.currentUser?.id;
  static String _cacheKey(String uid) => 'arc_state_v1_$uid';

  /// Lit la dernière réponse gardée, s'abonne aux changements et redemande.
  ///
  /// Idempotent : appelé à chaque montage de l'app principale.
  Future<void> start() async {
    _events ??= GlobalStateManager.instance.events.listen((e) {
      switch (e.type) {
        case ChangeType.meals:
        case ChangeType.water:
        case ChangeType.workout:
        case ChangeType.sport:
        case ChangeType.goals:
        case ChangeType.batch:
        case ChangeType.dayReset:
          refreshSoon();
        default:
          break;
      }
    });
    await _restore();
    await refresh();
  }

  /// Redemande un peu plus tard : un repas de quatre aliments ne fait qu'un
  /// appel.
  void refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => refresh());
  }

  /// Demande l'état à la base. Deux appels simultanés n'en font qu'un.
  Future<ArcState?> refresh() {
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<ArcState?> _fetch() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      String? tz;
      try {
        tz = await FlutterTimezone.getLocalTimezone();
      } catch (_) {}
      final raw = await SupabaseConfig.client.rpc('arc_state', params: {'p_tz': tz});
      if (raw is! Map) return state;
      final next = ArcState.fromJson(Map<String, dynamic>.from(raw));
      _apply(uid, next, fromCache: false);
      unawaited(_save(uid, next));
      return next;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ArcService: arc_state indisponible : $e');
      return state;
    } finally {
      if (!_firstAnswer.isCompleted) _firstAnswer.complete();
    }
  }

  /// La case qui vient d'être validée sous les yeux : l'accueil la remplit la
  /// prochaine fois qu'il la montre (voir [takeReveal]).
  ({DateTime day, int index})? _reveal;

  /// La case à remplir en animation, une seule fois, si elle est de ce jour.
  int? takeReveal(ArcState s) {
    final r = _reveal;
    if (r == null) return null;
    if (r.day.year != s.today.year || r.day.month != s.today.month || r.day.day != s.today.day) return null;
    if (r.index < 0 || r.index >= s.cells.length) return null;
    _reveal = null;
    return r.index;
  }

  void _apply(String uid, ArcState next, {required bool fromCache}) {
    final before = _stateFor == uid ? _state : null;
    final changed = before == null || jsonEncode(before.toJson()) != jsonEncode(next.toJson());
    _state = next;
    _stateFor = uid;
    if (!changed) return;
    // Posée avant de prévenir l'accueil, pour qu'il la voie en se redessinant.
    final validated = fromCache ? null : ArcBanner.detect(before, next);
    if (validated != null) {
      _reveal = (day: next.today, index: next.cells.length - (validated == ArcValidated.today ? 1 : 2));
    }
    notifyListeners();
    if (fromCache) return;
    if (validated != null) unawaited(ArcBanner.celebrate(validated, next));

    // Deux flammes : la normale garde sa règle, l'arc a la sienne. Ce qui
    // change ici ne concerne que le bloc de l'arc chez le coach et le widget.
    RyzeContext.instance.invalidate({RyzeBlock.arc});
    unawaited(MealWidgetDataProvider.updateWidgetData());
    unawaited(NotificationService().scheduleArcReminders(next));
  }

  Future<void> _restore() async {
    final uid = _uid;
    if (uid == null || _stateFor == uid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(uid));
      if (raw == null) return;
      _apply(uid, ArcState.fromJson(jsonDecode(raw) as Map<String, dynamic>), fromCache: true);
    } catch (_) {}
  }

  Future<void> _save(String uid, ArcState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(uid), jsonEncode(s.toJson()));
    } catch (_) {}
  }
}
