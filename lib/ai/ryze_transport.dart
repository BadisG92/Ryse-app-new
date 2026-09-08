import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/gemini_config.dart';
import '../config/supabase_config.dart';
import '../core/config/feature_flags.dart';
import 'ryze_persona.dart';

/// Ce qu'un tour de génération a coûté.
class RyzeUsage {
  const RyzeUsage({this.promptTokens = 0, this.outputTokens = 0});

  final int promptTokens;
  final int outputTokens;

  int get total => promptTokens + outputTokens;

  RyzeUsage operator +(RyzeUsage other) => RyzeUsage(
        promptTokens: promptTokens + other.promptTokens,
        outputTokens: outputTokens + other.outputTokens,
      );

  @override
  String toString() => '$promptTokens + $outputTokens';
}

/// Un morceau de réponse, tel qu'il arrive.
class RyzeChunk {
  const RyzeChunk({this.text, this.functionCalls = const [], this.usage, this.finishReason});

  /// Le texte de ce morceau, s'il y en a.
  final String? text;

  /// Les appels d'outils de ce morceau, **avec leur `thoughtSignature`**.
  ///
  /// Chaque entrée est la part JSON brute, conservée telle quelle : c'est ce
  /// qu'il faudra renvoyer au modèle au tour suivant.
  final List<Map<String, dynamic>> functionCalls;

  final RyzeUsage? usage;
  final String? finishReason;

  bool get isEmpty => (text == null || text!.isEmpty) && functionCalls.isEmpty;
}

/// Une panne du transport, dite en une phrase.
class RyzeTransportException implements Exception {
  const RyzeTransportException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Vaut-il la peine de réessayer ?
  bool get isRetryable =>
      statusCode == null || statusCode == 429 || (statusCode! >= 500 && statusCode! < 600);

  @override
  String toString() => 'RyzeTransportException($statusCode): $message';
}

/// Par où passent les requêtes.
enum RyzeTransportMode {
  /// Directement vers Google, avec la clé compilée dans l'application.
  direct,

  /// Par la fonction serveur, qui détient la clé.
  edge,
}

/// Le seul point de contact avec le modèle.
///
/// Écrit à la main plutôt que posé sur le SDK, pour trois raisons.
///
/// D'abord, Gemini 3 attache une `thoughtSignature` à ses appels d'outils et
/// exige qu'on la lui rende au tour suivant, dès qu'on répond à un appel. Les
/// classes du SDK sont `final` et leur sérialisation ne garde que le nom et
/// les arguments : la signature se perd, et le second tour est refusé.
///
/// Ensuite, le SDK lève « Unhandled format for Content » sur un morceau de flux
/// qui n'a pas de `parts` — ce qui arrive en fin de génération. C'est le bug
/// que la reprise cassée du chat tentait de rattraper.
///
/// Enfin, le jour où la clé passera côté serveur, seule l'adresse et l'en-tête
/// changeront ici. Les surfaces, l'agent et les outils ne bougeront pas.
class RyzeTransport {
  RyzeTransport({
    http.Client? client,
    RyzeTransportMode? mode,
  })  : _client = client ?? http.Client(),
        mode = mode ??
            (FeatureFlags.RYZE_VIA_EDGE
                ? RyzeTransportMode.edge
                : RyzeTransportMode.direct);

  final http.Client _client;

  /// Par où sort cette instance. Par défaut, ce que dit le drapeau.
  final RyzeTransportMode mode;

  /// Sans premier octet passé ce délai, la requête est perdue.
  static const Duration firstByteTimeout = Duration(seconds: 20);

  /// Et sans rien de nouveau passé celui-là, le flux est considéré mort.
  static const Duration idleTimeout = Duration(seconds: 30);

  /// Le nombre de reprises, avant le premier octet seulement : une fois le
  /// texte parti chez l'utilisateur, on ne recommence pas derrière son dos.
  static const int maxRetries = 2;

  /// Envoie une requête et rend les morceaux au fur et à mesure.
  ///
  /// [payload] est le corps Gemini complet : `contents`, `systemInstruction`,
  /// `tools`, `generationConfig`, `safetySettings`.
  Stream<RyzeChunk> stream(
    Map<String, dynamic> payload, {
    String? model,
    RyzeSurface surface = RyzeSurface.coach,
  }) async* {
    var attempt = 0;

    while (true) {
      try {
        yield* _once(payload, model: model, surface: surface);
        return;
      } on RyzeTransportException catch (e) {
        attempt++;
        if (!e.isRetryable || attempt > maxRetries) rethrow;
        if (kDebugMode) {
          debugPrint('🔄 RyzeTransport: reprise $attempt après ${e.statusCode ?? 'timeout'}');
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  Stream<RyzeChunk> _once(
    Map<String, dynamic> payload, {
    String? model,
    required RyzeSurface surface,
  }) async* {
    final name = model ?? GeminiConfig.modelName;

    final request = http.Request('POST', _uri(name))
      ..headers.addAll(_headers())
      ..body = jsonEncode(bodyFor(mode, payload, model: name, surface: surface));

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(firstByteTimeout);
    } on TimeoutException {
      throw const RyzeTransportException('pas de réponse dans le délai');
    } catch (e) {
      throw RyzeTransportException('$e');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw RyzeTransportException(
        body.length > 300 ? body.substring(0, 300) : body,
        statusCode: response.statusCode,
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(idleTimeout, onTimeout: (sink) {
      sink.addError(const RyzeTransportException('flux interrompu'));
      sink.close();
    });

    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final raw = line.substring(5).trim();
      if (raw.isEmpty || raw == '[DONE]') continue;

      final chunk = parseChunk(raw);
      if (chunk != null) yield chunk;
    }
  }

  /// Ce qui part dans la requête.
  ///
  /// Vers Google, c'est le corps Gemini tel quel. Vers la fonction serveur,
  /// il est enveloppé : elle a besoin du modèle pour choisir l'adresse et de
  /// la surface pour ranger la consommation. Le corps lui-même n'est pas
  /// touché — ce qui parle au modèle reste écrit dans l'application.
  @visibleForTesting
  static Map<String, dynamic> bodyFor(
    RyzeTransportMode mode,
    Map<String, dynamic> payload, {
    required String model,
    required RyzeSurface surface,
  }) =>
      mode == RyzeTransportMode.edge
          ? {'model': model, 'surface': surface.name, 'payload': payload}
          : payload;

  Uri _uri(String name) {
    if (mode == RyzeTransportMode.edge) {
      return Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/ryze-ai');
    }
    return Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$name:streamGenerateContent?alt=sse',
    );
  }

  Map<String, String> _headers() {
    if (mode == RyzeTransportMode.edge) {
      // Plus de clé Gemini ici : la fonction serveur la détient, et c'est le
      // jeton de la session qui dit qui appelle.
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      return {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.supabaseAnonKey,
        if (token != null) 'Authorization': 'Bearer $token',
      };
    }

    return {
      'Content-Type': 'application/json',
      // La clé voyage dans un en-tête plutôt que dans l'adresse : une URL
      // se retrouve dans les journaux, les rapports de plantage et les
      // traces réseau, un en-tête beaucoup moins.
      'x-goog-api-key': GeminiConfig.geminiApiKey,
    };
  }

  /// Lit un morceau de flux.
  ///
  /// Rend `null` sur un morceau vide plutôt que de lever : un `candidate` sans
  /// `parts` arrive normalement en fin de génération, et c'est exactement ce
  /// qui faisait tomber le SDK.
  @visibleForTesting
  static RyzeChunk? parseChunk(String raw) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final usage = _usageOf(json['usageMetadata']);
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return usage == null ? null : RyzeChunk(usage: usage);
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final finish = candidate['finishReason'] as String?;
    final content = candidate['content'];

    final buffer = StringBuffer();
    final calls = <Map<String, dynamic>>[];

    if (content is Map<String, dynamic>) {
      final parts = content['parts'];
      if (parts is List) {
        for (final part in parts) {
          if (part is! Map<String, dynamic>) continue;

          final text = part['text'];
          if (text is String && text.isNotEmpty) buffer.write(text);

          if (part['functionCall'] != null) {
            // La part entière est conservée : elle porte la signature que le
            // modèle voudra revoir au tour suivant.
            calls.add(Map<String, dynamic>.from(part));
          }
        }
      }
    }

    final chunk = RyzeChunk(
      text: buffer.isEmpty ? null : buffer.toString(),
      functionCalls: calls,
      usage: usage,
      finishReason: finish,
    );
    return chunk.isEmpty && usage == null && finish == null ? null : chunk;
  }

  static RyzeUsage? _usageOf(dynamic meta) {
    if (meta is! Map<String, dynamic>) return null;
    final prompt = meta['promptTokenCount'];
    final output = meta['candidatesTokenCount'];
    if (prompt == null && output == null) return null;
    return RyzeUsage(
      promptTokens: prompt is num ? prompt.toInt() : 0,
      outputTokens: output is num ? output.toInt() : 0,
    );
  }

  void close() => _client.close();
}
