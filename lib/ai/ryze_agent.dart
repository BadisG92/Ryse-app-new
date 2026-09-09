import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/gemini_config.dart';
import 'ryze_persona.dart';
import 'ryze_transport.dart';

/// Ce qui sort de l'agent pendant qu'il répond.
sealed class RyzeEvent {
  const RyzeEvent();
}

/// Un morceau de texte, tel qu'il arrive.
class RyzeTextDelta extends RyzeEvent {
  const RyzeTextDelta(this.text);
  final String text;
}

/// Le modèle demande un outil. L'agent ne l'exécute pas lui-même : la surface
/// décide, parce qu'elle seule sait montrer une carte de validation.
class RyzeToolCall extends RyzeEvent {
  const RyzeToolCall(this.name, this.args, this.rawPart);

  final String name;
  final Map<String, dynamic> args;

  /// La part JSON complète, signature comprise. Elle doit repartir telle
  /// quelle dans l'historique, sinon Gemini 3 refuse le tour suivant.
  final Map<String, dynamic> rawPart;
}

/// La réponse est finie.
class RyzeDone extends RyzeEvent {
  const RyzeDone(this.usage, {this.truncated = false});
  final RyzeUsage usage;

  /// Vrai quand le modèle a été coupé par la limite de sortie.
  final bool truncated;
}

/// Quelque chose s'est mal passé, dit en une clé de traduction.
class RyzeError extends RyzeEvent {
  const RyzeError(this.messageKey, {this.detail});
  final String messageKey;
  final String? detail;
}

/// Les réglages de génération d'une surface.
class RyzeGenerationConfig {
  const RyzeGenerationConfig({
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.maxOutputTokens = 1024,
  });

  final double temperature;
  final int topK;
  final double topP;
  final int maxOutputTokens;

  /// La conversation : chaleureuse, et assez large pour une recette entière.
  /// Elle était plafonnée à 400 tokens, ce qui coupait les recettes au milieu.
  static const coach = RyzeGenerationConfig();

  /// Le planificateur : plus sobre, et large parce qu'une semaine de repas
  /// avec recettes tient difficilement en moins.
  static const planner = RyzeGenerationConfig(temperature: 0.4, maxOutputTokens: 8192);

  /// Le bilan hebdomadaire : court par nature.
  static const bilan = RyzeGenerationConfig(maxOutputTokens: 700);

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'maxOutputTokens': maxOutputTokens,
      };
}

/// Le moteur de Ryze : un historique, une instruction système, un flux.
///
/// L'historique est gardé ici, en JSON Gemini brut, plutôt que confié à une
/// session du SDK. Trois choses le demandent : renvoyer les parts d'appels
/// d'outils **avec leur signature**, reconstruire l'instruction système sans
/// perdre le fil de la conversation, et choisir ce qui repart au modèle.
///
/// Reconstruire l'instruction était justement le point noir : changer de ton
/// ou sauver une préférence recréait la session Gemini entière, et la
/// conversation repartait de zéro pour le modèle.
class RyzeAgent {
  RyzeAgent({
    required this.config,
    RyzeTransport? transport,
    this.model,
    this.surface = RyzeSurface.coach,
  }) : _transport = transport ?? RyzeTransport();

  final RyzeGenerationConfig config;
  final RyzeTransport _transport;
  final String? model;

  /// D'où vient la demande. Le transport le dit à la fonction serveur, qui
  /// range la consommation par surface.
  final RyzeSurface surface;

  /// L'historique, au format Gemini.
  final List<Map<String, dynamic>> _history = [];

  /// L'instruction système, relue à chaque envoi.
  Future<String> Function()? systemInstructionBuilder;

  /// Les déclarations d'outils, vides tant que le lot des outils n'est pas là.
  List<Map<String, dynamic>> tools = const [];

  /// Combien de tours d'outils au maximum pour un seul message.
  static const int maxToolRounds = 4;

  /// Combien de tours l'historique garde.
  ///
  /// L'écran en seme trente à l'ouverture, mais rien ne les rognait ensuite :
  /// une conversation longue renvoyait tout, à chaque message, et deux fois
  /// par message puisqu'un appel d'outil demande un second tour. Ce qui part
  /// au modèle finissait par peser plus que la persona et les outils réunis.
  static const int maxHistoryTurns = 40;

  /// Rogne l'historique par le début, sans couper un appel de sa réponse.
  ///
  /// Un tour `model` porteur d'un `functionCall` doit rester collé au tour
  /// `user` qui porte sa `functionResponse` : les séparer fait refuser la
  /// requête entière.
  void _trimHistory() {
    if (_history.length <= maxHistoryTurns) return;

    var from = _history.length - maxHistoryTurns;

    // On ne commence jamais sur une réponse d'outil orpheline.
    while (from < _history.length && _startsWithToolResponse(_history[from])) {
      from++;
    }
    if (from <= 0) return;
    _history.removeRange(0, from);
  }

  static bool _startsWithToolResponse(Map<String, dynamic> turn) {
    final parts = turn['parts'];
    if (parts is! List || parts.isEmpty) return false;
    final first = parts.first;
    return first is Map && first.containsKey('functionResponse');
  }

  RyzeUsage _sessionUsage = const RyzeUsage();
  RyzeUsage get sessionUsage => _sessionUsage;

  int get historyLength => _history.length;

  @visibleForTesting
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  // ------------------------------------------------------------- historique

  /// Remplit l'historique à partir de messages déjà échangés.
  void seed(Iterable<({bool fromUser, String text})> messages) {
    _history.clear();
    for (final m in messages) {
      if (m.text.trim().isEmpty) continue;
      _history.add({
        'role': m.fromUser ? 'user' : 'model',
        'parts': [
          {'text': m.text}
        ],
      });
    }
  }

  void addUserText(String text) {
    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ],
    });
    _trimHistory();
  }

  void addModelParts(List<Map<String, dynamic>> parts) {
    if (parts.isEmpty) return;
    _history.add({'role': 'model', 'parts': parts});
  }

  /// Rend au modèle le résultat des outils qu'il a demandés.
  void addToolResults(List<({String name, Map<String, dynamic> response})> results) {
    if (results.isEmpty) return;
    _history.add({
      'role': 'user',
      'parts': [
        for (final r in results)
          {
            'functionResponse': {'name': r.name, 'response': r.response}
          }
      ],
    });
  }

  /// Une note courte, côté utilisateur, pour ce qui s'est passé hors modèle.
  ///
  /// Valider une carte n'a pas besoin d'un aller-retour : l'action est faite,
  /// le modèle doit seulement savoir qu'elle l'est.
  void note(String text) => addUserText('[$text]');

  void clear() {
    _history.clear();
    _sessionUsage = const RyzeUsage();
  }

  // ---------------------------------------------------------------- envoi

  /// Envoie un message et rend ce qui arrive.
  ///
  /// [hidden] remplace le texte envoyé au modèle sans rien ajouter à ce que
  /// l'utilisateur voit : c'est ainsi que le bilan hebdomadaire passe ses
  /// consignes.
  Stream<RyzeEvent> send(String text, {String? hidden}) async* {
    addUserText(hidden ?? text);

    var rounds = 0;
    while (true) {
      rounds++;

      final parts = <Map<String, dynamic>>[];
      final calls = <RyzeToolCall>[];
      var truncated = false;

      try {
        final payload = await _payload();

        await for (final chunk in _transport.stream(payload, model: model, surface: surface.name)) {
          if (chunk.usage != null) _sessionUsage = _sessionUsage + chunk.usage!;
          if (chunk.finishReason == 'MAX_TOKENS') truncated = true;

          if (chunk.text != null && chunk.text!.isNotEmpty) {
            parts.add({'text': chunk.text});
            yield RyzeTextDelta(chunk.text!);
          }

          for (final raw in chunk.functionCalls) {
            final call = raw['functionCall'] as Map<String, dynamic>;
            final tool = RyzeToolCall(
              '${call['name']}',
              Map<String, dynamic>.from(call['args'] as Map? ?? const {}),
              raw,
            );
            parts.add(raw);
            calls.add(tool);
          }
        }
      } on RyzeTransportException catch (e) {
        if (kDebugMode) debugPrint('❌ RyzeAgent: $e');
        yield RyzeError(
          e.statusCode == 429 ? 'coach_error_busy' : 'coach_error_generic',
          detail: e.message,
        );
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ RyzeAgent: $e');
        yield const RyzeError('coach_error_generic');
        return;
      }

      // Le tour du modèle rejoint l'historique tel qu'il est arrivé, parts
      // d'outils et signatures comprises.
      addModelParts(parts);

      if (calls.isEmpty) {
        yield RyzeDone(_sessionUsage, truncated: truncated);
        return;
      }

      for (final call in calls) {
        yield call;
      }

      // La surface a exécuté ce qu'elle voulait et rempli les résultats via
      // [addToolResults] ; s'il n'y en a pas, on s'arrête plutôt que de
      // boucler à vide.
      if (rounds >= maxToolRounds || !_lastTurnIsToolResult()) {
        yield RyzeDone(_sessionUsage, truncated: truncated);
        return;
      }
    }
  }

  bool _lastTurnIsToolResult() {
    if (_history.isEmpty) return false;
    final parts = _history.last['parts'];
    if (parts is! List || parts.isEmpty) return false;
    return parts.any((p) => p is Map && p.containsKey('functionResponse'));
  }

  Future<Map<String, dynamic>> _payload() async {
    final instruction = await systemInstructionBuilder?.call() ?? '';

    return {
      'contents': _history,
      if (instruction.trim().isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': instruction}
          ]
        },
      if (tools.isNotEmpty) ...{
        'tools': [
          {'function_declarations': tools}
        ],
        // AUTO et non ANY : forcer un appel à chaque tour tord une réponse
        // conversationnelle en demande de clarification.
        'tool_config': {
          'function_calling_config': {'mode': 'AUTO'}
        },
      },
      'safetySettings': GeminiConfig.safetySettingsList,
      'generationConfig': config.toJson(),
    };
  }

  void dispose() => _transport.close();
}
