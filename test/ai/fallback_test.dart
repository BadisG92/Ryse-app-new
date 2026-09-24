import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ryze_app/ai/ryze_transport.dart';
import 'package:ryze_app/config/gemini_config.dart';

/// La bascule sur le modèle de secours.
///
/// Relevé du 23 septembre 2026 : gemini-3.1-flash-lite répondait 503 « high
/// demand » à 5 appels sur 5, et l'application affichait « Something went
/// wrong » à chaque besoin d'IA. Ces tests figent le plan B, avec un faux
/// serveur qui refuse le premier modèle et répond sur le second.
void main() {
  const overloaded = '{"error":{"code":503,"message":"This model is currently experiencing high demand.","status":"UNAVAILABLE"}}';

  Map<String, dynamic> answer(String text) => {
        'candidates': [
          {
            'content': {
              'role': 'model',
              'parts': [
                {'text': text}
              ]
            },
            'finishReason': 'STOP',
          }
        ],
      };

  final payload = <String, dynamic>{
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': 'Bonjour'}
        ]
      }
    ],
    'generationConfig': {'maxOutputTokens': 2000},
  };

  /// Le modèle visé par une requête, lu dans son adresse.
  String modelOf(http.Request r) => r.url.pathSegments.last.split(':').first;

  // Le repos du principal est partagé : chaque test repart d'un principal
  // disponible.
  setUp(RyzeTransport.resetHealth);

  group('L\'aller-retour', () {
    test('un 503 sur le modèle principal bascule sur le secours et réussit', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(modelOf(request));
        if (modelOf(request) == GeminiConfig.modelName) return http.Response(overloaded, 503);
        return http.Response(jsonEncode(answer('Salut !')), 200);
      });

      final transport = RyzeTransport(client: client, mode: RyzeTransportMode.direct);
      final out = await transport.generate(payload, surface: RyzeUsageLabel.scan);

      expect(RyzeTransport.textOf(out), 'Salut !');
      expect(asked, [GeminiConfig.modelName, GeminiConfig.fallbackModelName]);
    });

    test('le secours reçoit la réflexion coupée, le principal non', () async {
      final bodies = <String, Map<String, dynamic>>{};
      final client = MockClient((request) async {
        bodies[modelOf(request)] = jsonDecode(request.body) as Map<String, dynamic>;
        if (modelOf(request) == GeminiConfig.modelName) return http.Response(overloaded, 503);
        return http.Response(jsonEncode(answer('ok')), 200);
      });

      await RyzeTransport(client: client, mode: RyzeTransportMode.direct).generate(payload, surface: RyzeUsageLabel.scan);

      final primary = bodies[GeminiConfig.modelName]!['generationConfig'] as Map;
      final fallback = bodies[GeminiConfig.fallbackModelName]!['generationConfig'] as Map;
      expect(primary.containsKey('thinkingConfig'), isFalse);
      expect(fallback['thinkingConfig'], {'thinkingBudget': 0});
      // le reste de la configuration passe tel quel
      expect(fallback['maxOutputTokens'], 2000);
    });

    test('les trois modèles refusent : l\'erreur ne remonte qu\'après toute la chaîne', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(modelOf(request));
        return http.Response(overloaded, 503);
      });

      await expectLater(
        RyzeTransport(client: client, mode: RyzeTransportMode.direct).generate(payload, surface: RyzeUsageLabel.scan),
        throwsA(isA<RyzeTransportException>().having((e) => e.statusCode, 'statusCode', 503)),
      );
      // Le principal une fois, le secours deux fois, le dernier recours trois.
      expect(asked, [
        GeminiConfig.modelName,
        GeminiConfig.fallbackModelName,
        GeminiConfig.fallbackModelName,
        GeminiConfig.lastResortModelName,
        GeminiConfig.lastResortModelName,
        GeminiConfig.lastResortModelName,
      ]);
    });

    test('un refus isolé du secours est repris, pas affiché', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(modelOf(request));
        final nth = asked.where((m) => m == GeminiConfig.fallbackModelName).length;
        if (modelOf(request) == GeminiConfig.modelName || nth == 1) return http.Response(overloaded, 503);
        return http.Response(jsonEncode(answer('ok')), 200);
      });

      final out = await RyzeTransport(client: client, mode: RyzeTransportMode.direct).generate(payload, surface: RyzeUsageLabel.scan);
      expect(RyzeTransport.textOf(out), 'ok');
      expect(asked, [GeminiConfig.modelName, GeminiConfig.fallbackModelName, GeminiConfig.fallbackModelName]);
    });

    test('un principal saturé se repose : la requête suivante part du secours', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(modelOf(request));
        if (modelOf(request) == GeminiConfig.modelName) return http.Response(overloaded, 503);
        return http.Response(jsonEncode(answer('ok')), 200);
      });
      final transport = RyzeTransport(client: client, mode: RyzeTransportMode.direct);

      await transport.generate(payload, surface: RyzeUsageLabel.scan);
      asked.clear();
      await transport.generate(payload, surface: RyzeUsageLabel.scan);

      expect(asked, [GeminiConfig.fallbackModelName]);
    });

    test('une vraie erreur de requête ne bascule pas', () async {
      final asked = <String>[];
      final client = MockClient((request) async {
        asked.add(modelOf(request));
        return http.Response('{"error":{"code":400,"message":"bad request"}}', 400);
      });

      await expectLater(
        RyzeTransport(client: client, mode: RyzeTransportMode.direct).generate(payload, surface: RyzeUsageLabel.scan),
        throwsA(isA<RyzeTransportException>()),
      );
      expect(asked, [GeminiConfig.modelName]);
    });
  });

  group('Le flux', () {
    test('un 503 sur le modèle principal bascule sur le secours, sans texte en double', () async {
      final asked = <String>[];
      final client = MockClient.streaming((request, _) async {
        final model = modelOf(request as http.Request);
        asked.add(model);
        if (model == GeminiConfig.modelName) {
          return http.StreamedResponse(Stream.value(utf8.encode(overloaded)), 503);
        }
        final sse = 'data: ${jsonEncode(answer('Bonjour, prêt ?'))}\n\n';
        return http.StreamedResponse(Stream.value(utf8.encode(sse)), 200);
      });

      final chunks = await RyzeTransport(client: client, mode: RyzeTransportMode.direct)
          .stream(payload, surface: RyzeUsageLabel.coach)
          .toList();

      expect(chunks.map((c) => c.text).whereType<String>().join(), 'Bonjour, prêt ?');
      expect(asked, [GeminiConfig.modelName, GeminiConfig.fallbackModelName]);
    });
  });

  group('Ce qui compte comme une saturation', () {
    test('les refus de capacité', () {
      for (final code in [429, 500, 502, 503, 504]) {
        expect(RyzeTransport.isOverloaded(code), isTrue, reason: '$code');
      }
    });

    test('pas les erreurs de la requête elle-même, ni l\'abonnement', () {
      for (final code in [null, 400, 401, 402, 403, 404]) {
        expect(RyzeTransport.isOverloaded(code), isFalse, reason: '$code');
      }
    });

    test('le modèle principal garde son corps de requête intact', () {
      expect(identical(RyzeTransport.forModel(payload, GeminiConfig.modelName), payload), isTrue);
    });
  });

  group('Les appels d\'outils venus du secours', () {
    // Relevé le 24 septembre : 3.1 refuse en 400 un appel d'outil sans
    // signature, avant même de regarder sa capacité. Un tour commencé sur le
    // secours et repris sur 3.1 finissait en erreur.
    final history = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Ajoute un verre'}
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'functionCall': {'name': 'add_water', 'args': {'ml': 250}}
            },
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'functionCall': {'name': 'log_weight', 'args': {'kg': 70}},
              'thoughtSignature': 'vraie'
            },
          ],
        },
      ],
    };

    List<Map> calls(Map<String, dynamic> p) => [
          for (final c in p['contents'] as List)
            for (final part in (c as Map)['parts'] as List)
              if ((part as Map).containsKey('functionCall')) part,
        ];

    test('Gemini 3 reçoit une signature de remplacement sur l\'appel qui n\'en a pas', () {
      final out = RyzeTransport.forModel(history, GeminiConfig.modelName);
      expect(calls(out)[0]['thoughtSignature'], RyzeTransport.foreignSignature);
    });

    test('une vraie signature n\'est jamais remplacée', () {
      final out = RyzeTransport.forModel(history, GeminiConfig.modelName);
      expect(calls(out)[1]['thoughtSignature'], 'vraie');
    });

    test('l\'historique d\'origine n\'est pas touché', () {
      RyzeTransport.forModel(history, GeminiConfig.modelName);
      expect(calls(history)[0].containsKey('thoughtSignature'), isFalse);
    });
  });
}
