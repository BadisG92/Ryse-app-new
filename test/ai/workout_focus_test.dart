@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ryze_app/services/ai_workout_generation_service.dart';

/// La séance générée traite-t-elle ce qu'on lui a demandé ?
///
/// Une séance « Shoulders & Arms » est arrivée avec, dans l'ordre : Bench
/// Press, Barbell Row, Overhead Press. Les deux premiers sont des pectoraux et
/// du dos — et surtout, ce sont mot pour mot les trois exercices de l'exemple
/// que le prompt donnait pour illustrer le calcul des charges. Le modèle ne
/// composait pas une séance, il recopiait l'exemple.
///
///   flutter test test/ai/workout_focus_test.dart --run-skipped --tags live
void main() {
  final key = _apiKey();
  const model = 'gemini-3.1-flash-lite';

  // Un catalogue réduit mais complet sur les groupes en jeu : si le modèle
  // sort ces noms-là, ce n'est pas faute de choix.
  const catalogue = '''
CATALOGUE (24 exercises we already know):

Shoulder:
  - Overhead Press
  - Dumbbell Shoulder Press
  - Dumbbell Lateral Raise
  - Cable Lateral Raise
  - Front Raise
  - Face Pull
  - Reverse Fly
  - Arnold Press

Bicep:
  - Barbell Curl
  - Dumbbell Curl
  - Hammer Curl
  - Preacher Curl
  - Concentration Curl
  - Cable Curl

Triceps:
  - Triceps Pushdown
  - Overhead Triceps Extension
  - Skull Crusher
  - Close Grip Bench Press
  - Bench Dips

Chest:
  - Bench Press
  - Incline Dumbbell Press
  - Cable Fly

Back:
  - Barbell Row
  - Lat Pulldown
''';

  const historique = '''
USER STRENGTH LEVEL: INTERMEDIATE
Recent sessions:
- Bench Press: 4 sets, average 50 kg (Suggested weight: 45 kg)
- Barbell Row: 4 sets, average 45 kg (Suggested weight: 40 kg)
- Overhead Press: 3 sets, average 35 kg (Suggested weight: 30 kg)
''';

  /// Les exercices que le modèle rend pour cette demande.
  Future<List<String>> seancePour(String demande) async {
    final prompt = AIWorkoutGenerationService.buildGeminiPrompt(
      userRequest: demande,
      exercisesList: catalogue,
      userContext: historique,
      userLanguage: 'English',
      durationMinutes: 45,
    );

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 3072},
    };

    late http.Response r;
    for (var essai = 1; essai <= 4; essai++) {
      r = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': key!},
        body: jsonEncode(body),
      );
      if (r.statusCode != 503 && r.statusCode != 429) break;
      await Future<void>.delayed(Duration(milliseconds: 800 * essai));
    }
    expect(r.statusCode, 200, reason: r.body);

    final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final texte = (((json['candidates'] as List).first as Map)['content'] as Map)['parts']
        .map((p) => p['text'] ?? '')
        .join() as String;

    final propre = texte.replaceAll(RegExp(r'```json|```'), '').trim();
    final decode = jsonDecode(propre) as Map<String, dynamic>;
    return [
      for (final e in decode['exercises'] as List) '${(e as Map)['exercise_name']}',
    ];
  }

  /// Les mouvements qui n'ont rien à faire dans une séance épaules et bras.
  const horsSujet = ['bench press', 'barbell row', 'lat pulldown', 'incline', 'cable fly', 'squat', 'deadlift'];

  group('La séance traite ce qu\'on lui demande', () {
    test('épaules et bras : ni pectoraux ni dos', () async {
      if (key == null) return;

      final noms = await seancePour('Shoulders and arms');
      // ignore: avoid_print
      print('\n  → ${noms.join(', ')}\n');

      expect(noms, isNotEmpty);

      final fautifs = <String>[];
      for (final nom in noms) {
        final bas = nom.toLowerCase();
        // « Close Grip Bench Press » est un triceps : il a le droit d'être là.
        if (bas.contains('close grip')) continue;
        if (horsSujet.any(bas.contains)) fautifs.add(nom);
      }

      expect(fautifs, isEmpty, reason: 'hors sujet : $fautifs\ndans : $noms');
    });

    test('jambes : le haut du corps reste dehors', () async {
      if (key == null) return;

      final noms = await seancePour('Legs, 45 minutes');
      // ignore: avoid_print
      print('\n  → ${noms.join(', ')}\n');

      final fautifs = noms
          .where((n) => ['bench press', 'barbell row', 'curl', 'lateral raise', 'pushdown']
              .any(n.toLowerCase().contains))
          .toList();
      expect(fautifs, isEmpty, reason: 'hors sujet : $fautifs\ndans : $noms');
    });
  });
}

String? _apiKey() {
  const compiled = String.fromEnvironment('GEMINI_API_KEY');
  if (compiled.isNotEmpty) return compiled;

  for (final chemin in ['.env.local', '../.env.local']) {
    final f = File(chemin);
    if (!f.existsSync()) continue;
    for (final ligne in f.readAsLinesSync()) {
      final t = ligne.trim();
      if (!t.startsWith('GEMINI_API_KEY=')) continue;
      final v = t.substring('GEMINI_API_KEY='.length).trim().replaceAll('"', '');
      if (v.isNotEmpty) return v;
    }
  }
  return null;
}
