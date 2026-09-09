import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ryze_app/ai/ryze_agent.dart';
import 'package:ryze_app/ai/ryze_transport.dart';

/// Un serveur de mensonge : il rend les morceaux qu'on lui a donnés.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.rounds);

  /// Un lot de morceaux SSE par tour de génération attendu.
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
    return http.StreamedResponse(
      Stream.value(utf8.encode(lines)),
      200,
      request: request,
    );
  }
}

Map<String, dynamic> texte(String t) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': t}
            ]
          }
        }
      ]
    };

Map<String, dynamic> fin({int prompt = 100, int sortie = 20, String? raison}) => {
      'candidates': [
        {'content': <String, dynamic>{}, if (raison != null) 'finishReason': raison}
      ],
      'usageMetadata': {'promptTokenCount': prompt, 'candidatesTokenCount': sortie},
    };

Map<String, dynamic> appel(String nom, Map<String, dynamic> args, {String? signature}) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'functionCall': {'name': nom, 'args': args},
                if (signature != null) 'thoughtSignature': signature,
              }
            ]
          }
        }
      ]
    };

void main() {
  RyzeAgent agentAvec(List<List<Map<String, dynamic>>> rounds, {_FakeClient? client}) {
    final c = client ?? _FakeClient(rounds);
    return RyzeAgent(
      config: RyzeGenerationConfig.coach,
      transport: RyzeTransport(client: c),
    );
  }

  group('Une réponse en texte', () {
    test('arrive morceau par morceau, dans l\'ordre', () async {
      final agent = agentAvec([
        [texte('Il te reste '), texte('750 kcal.'), fin()]
      ]);

      final morceaux = <String>[];
      RyzeDone? fini;
      await for (final e in agent.send('combien il me reste ?')) {
        if (e is RyzeTextDelta) morceaux.add(e.text);
        if (e is RyzeDone) fini = e;
      }

      expect(morceaux, ['Il te reste ', '750 kcal.']);
      expect(fini, isNotNull);
      expect(fini!.usage.total, 120);
    });

    test('rejoint l\'historique une fois finie', () async {
      final agent = agentAvec([
        [texte('Salut.'), fin()]
      ]);
      await agent.send('bonjour').drain<void>();

      expect(agent.historyLength, 2);
      expect(agent.history.first['role'], 'user');
      expect(agent.history.last['role'], 'model');
    });

    test('une coupure par la limite de sortie se signale', () async {
      final agent = agentAvec([
        [texte('Une recette qui commence'), fin(raison: 'MAX_TOKENS')]
      ]);

      RyzeDone? fini;
      await for (final e in agent.send('une recette')) {
        if (e is RyzeDone) fini = e;
      }
      expect(fini!.truncated, isTrue);
    });
  });

  group('Un appel d\'outil', () {
    test('ressort avec sa signature intacte', () async {
      final agent = agentAvec([
        [appel('journal.log_water', {'amount_ml': 500}, signature: 'sig-42')]
      ]);

      final appels = <RyzeToolCall>[];
      await for (final e in agent.send("j'ai bu 50cl")) {
        if (e is RyzeToolCall) appels.add(e);
      }

      expect(appels, hasLength(1));
      expect(appels.first.name, 'journal.log_water');
      expect(appels.first.args['amount_ml'], 500);
      expect(appels.first.rawPart['thoughtSignature'], 'sig-42');
    });

    test('la signature repart telle quelle au tour suivant', () async {
      // C'est la raison d'être du transport maison : Gemini 3 exige de revoir
      // la signature, et la sérialisation du SDK la perd.
      final client = _FakeClient([
        [appel('journal.log_water', {'amount_ml': 500}, signature: 'sig-42')],
        [texte('Noté.'), fin()],
      ]);
      final agent = agentAvec(const [], client: client);

      await for (final e in agent.send("j'ai bu 50cl")) {
        if (e is RyzeToolCall) {
          agent.addToolResults([(name: e.name, response: {'ok': true})]);
        }
      }

      expect(client.calls, 2, reason: 'le second tour doit partir');
      final second = client.sentPayloads[1];
      final contents = second['contents'] as List;
      final tourModele = contents.firstWhere((c) => c['role'] == 'model') as Map;
      final part = (tourModele['parts'] as List).first as Map;
      expect(part['thoughtSignature'], 'sig-42');
    });

    test('sans résultat rendu, la boucle s\'arrête au lieu de tourner à vide', () async {
      final client = _FakeClient([
        [appel('plan.create_meal', const {})],
        [texte('ne devrait pas arriver'), fin()],
      ]);
      final agent = agentAvec(const [], client: client);

      await agent.send('planifie').drain<void>();

      expect(client.calls, 1);
    });
  });

  group('Ce que le corps de requête contient', () {
    test('l\'instruction système est un vrai champ, pas un faux tour', () async {
      // Elle était injectée comme premier message utilisateur, suivi d'un faux
      // accusé de réception du modèle, en français pour tout le monde.
      final client = _FakeClient([
        [texte('ok'), fin()]
      ]);
      final agent = agentAvec(const [], client: client)
        ..systemInstructionBuilder = () async => 'Tu es Ryze.';

      await agent.send('salut').drain<void>();

      final payload = client.sentPayloads.first;
      expect(payload['systemInstruction'], isNotNull);
      final parts = (payload['systemInstruction'] as Map)['parts'] as List;
      expect((parts.first as Map)['text'], 'Tu es Ryze.');

      // Et l'historique ne contient que le vrai message.
      expect((payload['contents'] as List), hasLength(1));
    });

    test('elle est relue à chaque envoi, sans casser l\'historique', () async {
      // Changer de ton reconstruisait la session entière : la conversation
      // repartait de zéro pour le modèle.
      var version = 1;
      final client = _FakeClient([
        [texte('a'), fin()],
        [texte('b'), fin()],
      ]);
      final agent = agentAvec(const [], client: client)
        ..systemInstructionBuilder = () async => 'version $version';

      await agent.send('un').drain<void>();
      version = 2;
      await agent.send('deux').drain<void>();

      final second = client.sentPayloads[1];
      final instruction = ((second['systemInstruction'] as Map)['parts'] as List).first as Map;
      expect(instruction['text'], 'version 2');
      expect((second['contents'] as List).length, greaterThan(2),
          reason: "l'historique doit survivre au changement d'instruction");
    });

    test('sans outils, aucune configuration d\'outils n\'est envoyée', () async {
      final client = _FakeClient([
        [texte('ok'), fin()]
      ]);
      await agentAvec(const [], client: client).send('salut').drain<void>();

      expect(client.sentPayloads.first.containsKey('tools'), isFalse);
      expect(client.sentPayloads.first.containsKey('tool_config'), isFalse);
    });

    test('avec des outils, le mode est AUTO et non ANY', () async {
      final client = _FakeClient([
        [texte('ok'), fin()]
      ]);
      final agent = agentAvec(const [], client: client)
        ..tools = [
          {'name': 'journal.log_water', 'description': 'x', 'parameters': const {}}
        ];

      await agent.send('salut').drain<void>();

      final config = (client.sentPayloads.first['tool_config'] as Map)['function_calling_config'] as Map;
      expect(config['mode'], 'AUTO',
          reason: 'ANY tordait « merci » en demande de clarification');
    });

    test('les réglages de sécurité partent avec la requête', () async {
      final client = _FakeClient([
        [texte('ok'), fin()]
      ]);
      await agentAvec(const [], client: client).send('salut').drain<void>();

      expect(client.sentPayloads.first['safetySettings'], isNotEmpty);
    });

    test('la conversation a de quoi écrire une recette entière', () {
      // 400 tokens coupaient les recettes au milieu.
      expect(RyzeGenerationConfig.coach.maxOutputTokens, greaterThanOrEqualTo(1024));
      expect(RyzeGenerationConfig.planner.maxOutputTokens, greaterThan(RyzeGenerationConfig.coach.maxOutputTokens));
    });
  });

  group('Un message caché', () {
    test('part au modèle sans que le texte visible change', () async {
      final client = _FakeClient([
        [texte('Voici ton bilan.'), fin()]
      ]);
      final agent = agentAvec(const [], client: client);

      await agent.send('Faire mon bilan', hidden: '[INSTRUCTION] Résume la semaine').drain<void>();

      final contents = client.sentPayloads.first['contents'] as List;
      final envoye = ((contents.first as Map)['parts'] as List).first as Map;
      expect(envoye['text'], contains('INSTRUCTION'));
    });
  });

  group('L\'historique ne grandit pas sans fin', () {
    // Rien ne le rognait : une longue conversation renvoyait tout, deux fois
    // par message, et finissait par peser plus que la persona et les outils.
    test('il s\'arrête au plafond', () {
      final agent = RyzeAgent(config: RyzeGenerationConfig.coach);
      for (var i = 0; i < 200; i++) {
        agent.addUserText('message $i');
      }
      expect(agent.historyLength, lessThanOrEqualTo(RyzeAgent.maxHistoryTurns));
    });

    test('il garde les derniers, pas les premiers', () {
      final agent = RyzeAgent(config: RyzeGenerationConfig.coach);
      for (var i = 0; i < 100; i++) {
        agent.addUserText('message $i');
      }
      final dernier = agent.history.last['parts'] as List;
      expect((dernier.first as Map)['text'], 'message 99');
    });

    test('il ne commence jamais sur une réponse d\'outil orpheline', () {
      // Un `functionResponse` séparé de son `functionCall` fait refuser la
      // requête entière.
      final agent = RyzeAgent(config: RyzeGenerationConfig.coach);
      for (var i = 0; i < 60; i++) {
        agent.addUserText('message $i');
        agent.addToolResults([(name: 'journal.log_water', response: const {'ok': true})]);
      }

      final premier = agent.history.first['parts'] as List;
      expect((premier.first as Map).containsKey('functionResponse'), isFalse);
    });
  });


  group('L\'historique', () {
    test('se remplit à partir de messages déjà échangés', () {
      final agent = agentAvec(const []);
      agent.seed([
        (fromUser: true, text: 'salut'),
        (fromUser: false, text: 'salut !'),
        (fromUser: true, text: '   '),
      ]);

      expect(agent.historyLength, 2, reason: 'un message vide ne compte pas');
      expect(agent.history.first['role'], 'user');
      expect(agent.history[1]['role'], 'model');
    });

    test('une note passe côté utilisateur, entre crochets', () {
      final agent = agentAvec(const [])..note('validé : 3 repas de mardi');
      final parts = agent.history.first['parts'] as List;
      expect((parts.first as Map)['text'], startsWith('['));
    });
  });
}
