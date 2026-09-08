import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ryze_app/ai/ryze_persona.dart';
import 'package:ryze_app/ai/ryze_transport.dart';

/// La lecture du flux.
///
/// Deux cas justifient à eux seuls d'avoir écrit ce transport plutôt que de
/// s'appuyer sur le SDK : un morceau sans `parts`, qui le fait lever, et la
/// `thoughtSignature` attachée aux appels d'outils, que sa sérialisation perd.
void main() {
  String sse(Map<String, dynamic> json) => jsonEncode(json);

  group('Un morceau de texte', () {
    test('se lit', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Il te reste 750 kcal.'}
              ]
            }
          }
        ]
      }));

      expect(chunk, isNotNull);
      expect(chunk!.text, 'Il te reste 750 kcal.');
      expect(chunk.functionCalls, isEmpty);
    });

    test('plusieurs parts de texte se recollent dans l\'ordre', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Il te reste '},
                {'text': '750 kcal.'},
              ]
            }
          }
        ]
      }));

      expect(chunk!.text, 'Il te reste 750 kcal.');
    });
  });

  group('Les morceaux que le SDK ne supporte pas', () {
    test('un contenu sans parts ne fait pas tomber la lecture', () {
      // C'est « Unhandled format for Content », l'erreur que la reprise
      // cassée du chat tentait de rattraper.
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {'content': <String, dynamic>{}, 'finishReason': 'STOP'}
        ]
      }));

      expect(chunk, isNotNull);
      expect(chunk!.text, isNull);
      expect(chunk.finishReason, 'STOP');
    });

    test('un candidat sans contenu du tout passe aussi', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {'finishReason': 'MAX_TOKENS'}
        ]
      }));
      expect(chunk!.finishReason, 'MAX_TOKENS');
    });

    test('un morceau vide est ignoré plutôt que rendu', () {
      expect(RyzeTransport.parseChunk(sse({'candidates': []})), isNull);
      expect(RyzeTransport.parseChunk('pas du json'), isNull);
      expect(RyzeTransport.parseChunk(''), isNull);
    });
  });

  group('La signature de raisonnement', () {
    test('est conservée telle quelle sur un appel d\'outil', () {
      // Gemini 3 exige de la revoir au tour suivant. La sérialisation du SDK
      // ne garde que `name` et `args` : la signature se perd et le second tour
      // est refusé. C'est la raison d'être de ce transport.
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'functionCall': {
                    'name': 'journal.log_water',
                    'args': {'amount_ml': 500},
                  },
                  'thoughtSignature': 'CiQBb2s...signature',
                }
              ]
            }
          }
        ]
      }));

      expect(chunk!.functionCalls, hasLength(1));
      final part = chunk.functionCalls.first;
      expect(part['thoughtSignature'], 'CiQBb2s...signature');
      expect((part['functionCall'] as Map)['name'], 'journal.log_water');
      expect(((part['functionCall'] as Map)['args'] as Map)['amount_ml'], 500);
    });

    test('un appel sans signature reste lisible', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'functionCall': {'name': 'plan.create_meal', 'args': <String, dynamic>{}}
                }
              ]
            }
          }
        ]
      }));

      expect(chunk!.functionCalls, hasLength(1));
      expect(chunk.functionCalls.first.containsKey('thoughtSignature'), isFalse);
    });

    test('texte et appel d\'outil dans le même morceau', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Je note ça.'},
                {
                  'functionCall': {'name': 'journal.log_water', 'args': <String, dynamic>{}},
                  'thoughtSignature': 'abc',
                },
              ]
            }
          }
        ]
      }));

      expect(chunk!.text, 'Je note ça.');
      expect(chunk.functionCalls, hasLength(1));
    });
  });

  group('Le comptage des tokens', () {
    test('se lit sur le morceau qui le porte', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'candidates': [
          {'content': {'parts': [{'text': 'ok'}]}}
        ],
        'usageMetadata': {'promptTokenCount': 4210, 'candidatesTokenCount': 118},
      }));

      expect(chunk!.usage!.promptTokens, 4210);
      expect(chunk.usage!.outputTokens, 118);
      expect(chunk.usage!.total, 4328);
    });

    test('un morceau qui ne porte que le compte est quand même rendu', () {
      final chunk = RyzeTransport.parseChunk(sse({
        'usageMetadata': {'promptTokenCount': 100, 'candidatesTokenCount': 20},
      }));
      expect(chunk, isNotNull);
      expect(chunk!.usage!.total, 120);
    });

    test('les tours s\'additionnent', () {
      const a = RyzeUsage(promptTokens: 100, outputTokens: 20);
      const b = RyzeUsage(promptTokens: 300, outputTokens: 50);
      expect((a + b).promptTokens, 400);
      expect((a + b).outputTokens, 70);
    });
  });

  group('Ce qui part dans la requête', () {
    final payload = {
      'contents': [
        {'role': 'user', 'parts': [{'text': 'salut'}]}
      ],
    };

    test('vers Google, le corps Gemini tel quel', () {
      final body = RyzeTransport.bodyFor(
        RyzeTransportMode.direct,
        payload,
        model: 'gemini-3.1-flash-lite',
        surface: RyzeUsageLabel.coach,
      );
      expect(body, same(payload));
      expect(body.containsKey('model'), isFalse);
    });

    test('vers la fonction serveur, enveloppé avec le modèle et la surface', () {
      // La fonction choisit l'adresse avec le modèle et range la
      // consommation par surface ; le corps du modèle n'est pas touché.
      final body = RyzeTransport.bodyFor(
        RyzeTransportMode.edge,
        payload,
        model: 'gemini-3.1-flash-lite',
        surface: RyzeUsageLabel.planner,
      );
      expect(body['model'], 'gemini-3.1-flash-lite');
      expect(body['surface'], 'planner');
      expect(body['stream'], isTrue);
      expect(body['payload'], same(payload));
    });

    test('une analyse ponctuelle demande une réponse d\'un seul tenant', () {
      // La photo d'un repas n'a rien à streamer : elle attend un objet entier.
      final body = RyzeTransport.bodyFor(
        RyzeTransportMode.edge,
        payload,
        model: 'gemini-3.1-flash-lite',
        surface: RyzeUsageLabel.scan,
        stream: false,
      );
      expect(body['stream'], isFalse);
      expect(body['surface'], 'scan');
    });

    test("les étiquettes sont celles que la fonction accepte", () {
      // Un nom qui change ici fait une erreur 400 à chaque message, et une
      // surface qui manque là-bas fait la même.
      expect(RyzeSurface.coach.name, RyzeUsageLabel.coach);
      expect(RyzeSurface.planner.name, RyzeUsageLabel.planner);

      expect(RyzeUsageLabel.all, {
        'coach', 'planner', 'scan', 'workout', 'nutrition', 'exercise', 'memory',
      });
    });
  });

  group('Quand vaut-il la peine de réessayer', () {
    test('un débit dépassé ou une panne serveur, oui', () {
      expect(const RyzeTransportException('quota', statusCode: 429).isRetryable, isTrue);
      expect(const RyzeTransportException('boom', statusCode: 500).isRetryable, isTrue);
      expect(const RyzeTransportException('boom', statusCode: 503).isRetryable, isTrue);
    });

    test('un délai dépassé sans code, oui', () {
      expect(const RyzeTransportException('timeout').isRetryable, isTrue);
    });

    test('une requête refusée ou une clé invalide, non', () {
      expect(const RyzeTransportException('bad', statusCode: 400).isRetryable, isFalse);
      expect(const RyzeTransportException('nope', statusCode: 403).isRetryable, isFalse);
    });
  });
}
