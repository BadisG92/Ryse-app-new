import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce qui est réellement utilisé, compté plutôt que journalisé.
///
/// Le but est de répondre à trois questions : qu'est-ce qui sert, à combien de
/// monde, et combien de fois. Une ligne par événement donnerait en plus les
/// séquences et les entonnoirs — Firebase le fait déjà et le fait mieux — au
/// prix d'une table qui grossit à chaque tap. Ici, une ligne par utilisateur,
/// par geste et par semaine, incrémentée : trente gestes pour cent
/// utilisateurs tiennent en trois mille lignes hebdomadaires, et la question
/// se pose en une requête.
///
/// Rien n'est envoyé au moment du geste. Les comptes s'accumulent en mémoire,
/// partent par lots, et survivent à une fermeture de l'app : le tampon est
/// écrit sur le téléphone à chaque mise en veille. Un envoi qui échoue est
/// remis dans le tampon, jamais perdu, jamais réessayé en boucle.
class UsageStats {
  UsageStats._();

  static const String _bufferKey = 'usage_pending_v1';

  /// Au-delà, on envoie sans attendre l'horloge.
  static const int _flushAt = 40;

  /// Et de toute façon, à intervalle régulier.
  static const Duration _every = Duration(seconds: 45);

  /// Un tampon qui ne part pas — hors ligne prolongé — ne doit pas enfler sans
  /// fin. Au-delà, les gestes les plus rares sont abandonnés.
  static const int _maxEvents = 400;

  static final Map<String, int> _pending = {};
  static Timer? _timer;
  static bool _sending = false;
  static bool _started = false;

  /// À appeler une fois au lancement : reprend ce que la dernière exécution
  /// n'a pas eu le temps d'envoyer.
  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_bufferKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) => _pending[k] = (_pending[k] ?? 0) + (v as num).toInt());
        await prefs.remove(_bufferKey);
      }
    } catch (_) {
      // un tampon illisible ne vaut pas un plantage au lancement
    }
    unawaited(flush());
  }

  /// Un geste vient d'avoir lieu.
  ///
  /// Ne fait rien d'autre qu'incrémenter un entier : c'est appelé depuis des
  /// chemins d'interface, ça ne doit jamais attendre quoi que ce soit.
  static void bump(String event, {int by = 1}) {
    final name = event.trim();
    if (name.isEmpty || by <= 0) return;
    if (_pending.length >= _maxEvents && !_pending.containsKey(name)) return;
    _pending[name] = (_pending[name] ?? 0) + by;

    _timer ??= Timer(_every, () {
      _timer = null;
      unawaited(flush());
    });
    if (_pending.length >= _flushAt) unawaited(flush());
  }

  /// Envoie ce qui est en attente. Appelé aussi quand l'app passe en veille.
  static Future<void> flush() async {
    if (_sending || _pending.isEmpty) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    _sending = true;
    final batch = Map<String, int>.from(_pending);
    _pending.clear();
    _timer?.cancel();
    _timer = null;

    try {
      await client.rpc('bump_usage', params: {
        'events': [
          for (final e in batch.entries) {'event': e.key, 'count': e.value},
        ],
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      // Remis dans le tampon : ce qui n'est pas parti n'est pas perdu, et le
      // prochain lot le reprendra.
      batch.forEach((k, v) => _pending[k] = (_pending[k] ?? 0) + v);
      if (kDebugMode) debugPrint('⚠️ [USAGE] $e');
    } finally {
      _sending = false;
    }
  }

  /// L'app part en arrière-plan : on écrit le tampon sur le téléphone après
  /// avoir tenté un dernier envoi.
  static Future<void> park() async {
    await flush();
    if (_pending.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bufferKey, jsonEncode(_pending));
    } catch (_) {
      // tant pis : ce sont des compteurs, pas des données de l'utilisateur
    }
  }
}
