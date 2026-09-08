import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/gemini_config.dart';
import 'ryze_transport.dart';

/// Une question au modèle, une réponse, rien entre les deux.
///
/// La conversation et le planificateur streament, parce qu'on lit leur
/// réponse pendant qu'elle s'écrit. Les analyses ponctuelles, non : une photo
/// de repas, une séance à composer, un bilan d'exercice attendent un objet
/// entier et le lisent d'un coup.
///
/// Elles avaient chacune leur façon de le demander : deux passaient par le
/// SDK, deux par un client HTTP brut avec la clé dans l'adresse, avec des
/// délais d'expiration différents ou absents. Elles passent maintenant toutes
/// par le même transport, donc par la fonction serveur dès que le drapeau
/// l'ordonne, et leurs jetons se comptent comme les autres.
class RyzeOneShot {
  RyzeOneShot._();

  static RyzeTransport? _transport;

  /// Le transport partagé. Un seul client HTTP pour toutes les analyses.
  static RyzeTransport get transport => _transport ??= RyzeTransport();

  @visibleForTesting
  static set transport(RyzeTransport value) => _transport = value;

  /// Demande une réponse et rend son texte, ou `null` si rien n'est venu.
  ///
  /// [surface] est l'étiquette de comptabilité, l'une de [RyzeUsageLabel].
  static Future<String?> text({
    required String prompt,
    required String surface,
    Uint8List? imageJpeg,
    double? temperature,
    int? maxOutputTokens,
    bool jsonMode = false,
    String? model,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      if (imageJpeg != null)
        {
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Encode(imageJpeg),
          }
        },
    ];

    final payload = <String, dynamic>{
      'contents': [
        {'role': 'user', 'parts': parts}
      ],
      'generationConfig': {
        'temperature': temperature ?? GeminiConfig.temperature,
        'topK': GeminiConfig.topK,
        'topP': GeminiConfig.topP,
        'maxOutputTokens': maxOutputTokens ?? GeminiConfig.maxOutputTokens,
        if (jsonMode) 'responseMimeType': 'application/json',
      },
      'safetySettings': GeminiConfig.safetySettingsList,
    };

    try {
      final response = await transport.generate(
        payload,
        model: model,
        surface: surface,
        timeout: timeout,
      );
      return RyzeTransport.textOf(response);
    } on RyzeTransportException catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeOneShot[$surface] : $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeOneShot[$surface] : $e');
      return null;
    }
  }

  /// La même chose, mais le texte attendu est un objet JSON.
  ///
  /// Le mode JSON est demandé au modèle, donc la réponse en est déjà un. Le
  /// découpage entre la première et la dernière accolade reste comme filet :
  /// un modèle qui glisse une phrase avant son objet ne fait plus tout rater.
  static Future<Map<String, dynamic>?> jsonObject({
    required String prompt,
    required String surface,
    Uint8List? imageJpeg,
    double? temperature,
    int? maxOutputTokens,
    String? model,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final raw = await text(
      prompt: prompt,
      surface: surface,
      imageJpeg: imageJpeg,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
      jsonMode: true,
      model: model,
      timeout: timeout,
    );
    return decode(raw);
  }

  /// Lit un objet JSON dans une réponse, même mal emballée.
  @visibleForTesting
  static Map<String, dynamic>? decode(String? raw) {
    if (raw == null) return null;

    final text = raw.trim();
    for (final candidate in [text, _betweenBraces(text)]) {
      if (candidate == null) continue;
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String? _betweenBraces(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}
