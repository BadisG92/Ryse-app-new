import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une seule réponse à « est-on en ligne ? » pour toute l'app.
///
/// Avant, chaque ouverture de l'écran de séance empilait un nouvel abonnement
/// à `connectivity_plus` sans annuler le précédent, et le statut était diffusé
/// dans un flux sans rejeu : qui s'abonnait après le premier événement ne
/// savait rien. Ici, une souscription, et une valeur qu'on peut lire à tout
/// moment et écouter.
///
/// `connectivity_plus` ne dit que si une interface réseau existe. Un Wi-Fi de
/// salle avec portail captif est « en ligne » à ses yeux et pourtant rien ne
/// passe. [reachable] tranche vraiment, en frappant le point de santé de
/// Supabase — et sait s'effacer si ce point est bloqué, pour ne jamais figer
/// une synchronisation.
class RyzeConnectivity {
  RyzeConnectivity._();

  static final RyzeConnectivity instance = RyzeConnectivity._();

  /// Vrai tant que le téléphone a une interface réseau. Rejoue sa dernière
  /// valeur à tout nouvel abonné, ce que le flux d'avant ne faisait pas.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;

  /// Combien de fois de suite la sonde a répondu « injoignable » alors que
  /// l'interface disait le contraire. Au-delà de trois, on la saute : une
  /// écriture qui échoue vaut mieux qu'une sonde qui bloque tout.
  int _probeFailures = 0;

  /// Idempotent : une seule souscription, quel que soit le nombre d'appels.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final results = await Connectivity().checkConnectivity();
      online.value = _isUp(results);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CONNECTIVITY] lecture initiale: $e');
    }
    _sub = Connectivity().onConnectivityChanged.listen(
      (results) => online.value = _isUp(results),
      onError: (Object e) {
        if (kDebugMode) debugPrint('⚠️ [CONNECTIVITY] flux: $e');
      },
    );
  }

  static bool _isUp(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.contains(ConnectivityResult.none);

  /// Supabase répond-il vraiment ? Vrai seulement sur un 200 dont le corps
  /// est celui du service d'auth : un portail captif renvoie un 200 avec du
  /// HTML, et échoue ce test.
  ///
  /// [force] ignore le compteur d'échecs : c'est le « Réessayer » de
  /// l'utilisateur, qui a le droit d'insister.
  Future<bool> reachable({Duration timeout = const Duration(seconds: 3), bool force = false}) async {
    if (!online.value) return false;
    if (!force && _probeFailures >= 3) {
      // La sonde a menti trois fois : on laisse l'écriture elle-même juger.
      _probeFailures = 0;
      return true;
    }
    try {
      final uri = Uri.parse('${_baseUrl()}/auth/v1/health');
      final response = await http.get(uri).timeout(timeout);
      final ok = response.statusCode == 200 && response.body.contains('GoTrue');
      _probeFailures = ok ? 0 : _probeFailures + 1;
      return ok;
    } catch (e) {
      _probeFailures++;
      if (kDebugMode) debugPrint('📵 [CONNECTIVITY] sonde: $e');
      return false;
    }
  }

  /// L'origine du projet, déduite du client déjà configuré : aucune clé, aucun
  /// second endroit où écrire l'URL.
  static String _baseUrl() {
    final rest = Supabase.instance.client.rest.url;
    final cut = rest.indexOf('/rest/v1');
    return cut > 0 ? rest.substring(0, cut) : rest;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
