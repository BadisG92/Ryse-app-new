import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ryze_app/ai/ryze_agent.dart';
import 'package:ryze_app/ai/ryze_transport.dart';

/// Un appel d'outil que Google n'a pas su lire.
///
/// Il arrive sans aucune part, avec `MALFORMED_FUNCTION_CALL` pour seule
/// trace : l'écran ne voyait rien et le modèle ne savait pas qu'il avait
/// échoué. Le premier dossier demandé sur appareil a pu finir ainsi. L'agent
/// le dit maintenant au modèle et lui laisse un tour pour recommencer.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.rounds);

  final List<List<Map<String, dynamic>>> rounds;
  int calls = 0;
  final List<Map<String, dynamic>> sentPayloads = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await (request as http.Request).finalize().bytesToString();
    sentPayloads.add(jsonDecode(body) as Map<String, dynamic>);
    final chunks = calls < rounds.length ? rounds[calls] : <Map<String, dynamic>>[];
    calls++;
    final lines = chunks.map((c) => 'data: ${jsonEncode(c)}\n\n').join();
    return http.StreamedResponse(Stream.value(utf8.encode(lines)), 200, request: request);
  }
}

Map<String, dynamic> fin({String? raison}) => {
      'candidates': [
        {'content': <String, dynamic>{}, if (raison != null) 'finishReason': raison}
      ],
      'usageMetadata': {'promptTokenCount': 100, 'candidatesTokenCount': 0},
    };

Map<String, dynamic> appel(String nom, Map<String, dynamic> args) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'functionCall': {'name': nom, 'args': args}
              }
            ]
          }
        }
      ]
    };

void main() {
  test('un appel mal formé est redemandé, et la reprise ressort', () async {
    final client = _FakeClient([
      [fin(raison: 'MALFORMED_FUNCTION_CALL')],
      [
        appel('memory.dossier', {
          'lines': ['A promis : plus de tacos après minuit'],
          'stamp': 'VU.',
          'verdict': 'Noté.'
        })
      ],
    ]);
    final agent = RyzeAgent(config: RyzeGenerationConfig.coach, transport: RyzeTransport(client: client));

    final appels = <RyzeToolCall>[];
    await for (final e in agent.send('mon dossier')) {
      if (e is RyzeToolCall) appels.add(e);
    }

    expect(appels.map((a) => a.name), ['memory.dossier']);
    expect(client.calls, 2);

    // Le second envoi porte la consigne de reprise, côté utilisateur, en
    // dernier.
    final contents = client.sentPayloads[1]['contents'] as List;
    final last = contents.last as Map<String, dynamic>;
    expect(last['role'], 'user');
    expect((last['parts'] as List).first['text'], RyzeAgent.malformedCallNote);
  });

  test('on ne redemande pas sans fin', () async {
    final client = _FakeClient([
      for (var i = 0; i < 6; i++) [fin(raison: 'MALFORMED_FUNCTION_CALL')],
    ]);
    final agent = RyzeAgent(config: RyzeGenerationConfig.coach, transport: RyzeTransport(client: client));

    RyzeDone? fini;
    await for (final e in agent.send('mon dossier')) {
      if (e is RyzeDone) fini = e;
    }

    expect(fini, isNotNull);
    expect(client.calls, RyzeAgent.maxToolRounds);
  });

  test('une fin ordinaire sans appel ne déclenche rien', () async {
    final client = _FakeClient([
      [fin(raison: 'STOP')],
    ]);
    final agent = RyzeAgent(config: RyzeGenerationConfig.coach, transport: RyzeTransport(client: client));
    await agent.send('salut').drain<void>();
    expect(client.calls, 1);
  });
}
