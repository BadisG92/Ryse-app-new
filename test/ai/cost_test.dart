@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:ryze_app/ai/ryze_persona.dart';
import 'package:ryze_app/ai/ryze_tools/ryze_tools.dart';
import 'package:ryze_app/services/gemini_analysis_service_v2.dart';

/// Ce que Ryze coûte, appel par appel.
///
/// Les jetons ne s'estiment pas : quatre caractères par jeton est faux dès
/// qu'il y a des accents, et une photo ne se compte pas en caractères du tout.
/// Ce banc envoie donc les vrais corps de requête au compteur de Google et
/// lit ce qu'il répond.
///
/// Il ne tourne pas avec la suite ordinaire :
///
///   flutter test test/ai/cost_test.dart --run-skipped --tags live
///
/// Ce qu'il faut relancer après avoir touché à un prompt : c'est la seule
/// façon de voir tout de suite ce qu'une section en plus a coûté.
void main() {
  final key = _apiKey();
  const model = 'gemini-3.1-flash-lite';

  // Tarif public de gemini-3.1-flash-lite, palier standard, en dollars par
  // million de jetons. À revérifier si Google le change.
  const prixEntree = 0.25;
  const prixSortie = 1.50;

  final releve = <_Mesure>[];

  setUpAll(() {
    if (key == null) return;
  });

  /// Le nombre exact de jetons que ce corps de requête représente.
  ///
  /// `countTokens` est gratuit et compte tout : l'instruction système, les
  /// déclarations d'outils, l'historique et les images.
  Future<int> jetonsDe(Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:countTokens'),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': key!},
      body: jsonEncode({'generateContentRequest': {...body, 'model': 'models/$model'}}),
    );
    expect(r.statusCode, 200, reason: r.body);
    return (jsonDecode(r.body) as Map<String, dynamic>)['totalTokens'] as int;
  }

  /// Un vrai appel, pour connaître la longueur de la réponse.
  Future<({int entree, int sortie})> appelReel(Map<String, dynamic> body) async {
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

    final u = (jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>)['usageMetadata']
        as Map<String, dynamic>;
    return (
      entree: (u['promptTokenCount'] as num).toInt(),
      // La pensée du modèle se facture au prix de la sortie.
      sortie: (u['candidatesTokenCount'] as num? ?? 0).toInt() +
          (u['thoughtsTokenCount'] as num? ?? 0).toInt(),
    );
  }

  void noter(String quoi, int entree, int sortie, {String? note}) {
    releve.add(_Mesure(quoi, entree, sortie, note));
    final cout = entree / 1e6 * prixEntree + sortie / 1e6 * prixSortie;
    // ignore: avoid_print
    print('  $quoi : $entree entrée + $sortie sortie '
        '= ${(cout * 100).toStringAsFixed(4)} cents');
  }

  /// Le contexte que l'application colle sous la persona, à sa taille réelle.
  ///
  /// Pas un contexte réduit : c'est justement sa taille qui est en cause.
  String contexteComplet() {
    // Le vrai catalogue, exporté de la base : 365 noms français, quatorze
    // groupes. Une liste inventée fausserait le compte — des noms numérotés
    // coûtent moitié plus cher en jetons que de vrais noms.
    final exercices = StringBuffer('## MOUVEMENTS DÉJÀ CONNUS\n')
      ..writeln('Quand le mouvement est dans cette liste, écris son nom exactement '
          'comme il y figure. La liste est incomplète : si ce que tu veux proposer '
          'n\'y est pas, nomme-le librement.')
      ..writeln()
      ..write(File('test/ai/catalogue_fr.txt').readAsStringSync());

    return '''
## DATE ET HEURE
mercredi 9 septembre 2026, 09:52 (UTC+2)
Demain, c'est jeudi 10 septembre.

## AUJOURD'HUI
Calories : 340 / 2100 kcal
Protéines : 22 / 150 g · Glucides : 40 / 210 g · Lipides : 9 / 70 g
Eau : 0.5/2.5 L

## REPAS DU JOUR
- Petit-déjeuner : Yaourt grec et fruits rouges, 340 kcal

## PROFIL
Homme, 30 ans · Objectif : perte de poids · 82.4 kg vers 76.0 kg
Activité : modérée · Série en cours : 12 jours

## HABITUDES (14 DERNIERS JOURS)
Moyenne 1980 kcal, 138 g de protéines. Petit-déjeuner noté 12 jours sur 14.
Les dîners dépassent souvent la cible le week-end.

## DERNIÈRES SÉANCES
- Lundi : Haut du corps, 52 min, 6 exercices
- Samedi : Course, 34 min, 5.2 km
- Vendredi : Jambes, 61 min, 5 exercices

## LA SEMAINE PLANIFIÉE
Lundi : séance haut du corps (faite) · Mardi : repos
Mercredi : rien de prévu · Jeudi : séance jambes (prévue)
Vendredi : rien de prévu · Samedi : course (prévue) · Dimanche : repos

## POIDS
82.4 kg aujourd'hui · 83.9 kg il y a quatre semaines · cible 76.0 kg

## CE QUE TU SAIS DE LUI
- Allergique aux fruits à coque
- Ne mange pas de porc
- Genou droit sensible en flexion profonde
- Préfère s'entraîner le soir
- N'aime pas le poisson blanc

$exercices''';
  }

  Future<Map<String, dynamic>> corpsCoach(String phrase, {int sortieMax = 1024}) async {
    final instruction = await RyzePersona.build(
      lang: 'fr',
      surface: RyzeSurface.coach,
      userName: 'Badis',
      gender: 'male',
      age: 30,
      context: contexteComplet(),
      tone: 'Tu es un coach chaleureux. Tu tutoies.',
    );

    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': phrase}
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': instruction}
        ]
      },
      'tools': [
        {'function_declarations': ryzeTools.declarationsFor(RyzeSurface.coach)}
      ],
      'tool_config': {
        'function_calling_config': {'mode': 'AUTO'}
      },
      'generationConfig': {'temperature': 0.8, 'maxOutputTokens': sortieMax},
    };
  }

  group('Où vont les jetons', () {
    test('la part de chaque morceau du prompt', () async {
      if (key == null) return;

      Map<String, dynamic> corps({String? instruction, bool outils = false}) => {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': 'ok'}
                ]
              }
            ],
            if (instruction != null)
              'systemInstruction': {
                'parts': [
                  {'text': instruction}
                ]
              },
            if (outils)
              'tools': [
                {'function_declarations': ryzeTools.declarationsFor(RyzeSurface.coach)}
              ],
          };

      Future<String> personaAvec(String contexte) => RyzePersona.build(
            lang: 'fr',
            surface: RyzeSurface.coach,
            userName: 'Badis',
            gender: 'male',
            age: 30,
            context: contexte,
            tone: 'Tu es un coach chaleureux. Tu tutoies.',
          );

      final contexte = contexteComplet();
      final sansExercices = contexte.split('## MOUVEMENTS').first;

      final enveloppe = await jetonsDe(corps());
      final avecOutils = await jetonsDe(corps(outils: true));
      final personaSeule = await jetonsDe(corps(instruction: await personaAvec('')));
      final avecContexte = await jetonsDe(corps(instruction: await personaAvec(sansExercices)));
      final tout = await jetonsDe(corps(instruction: await personaAvec(contexte), outils: true));

      final parts = {
        'persona': personaSeule - enveloppe,
        'contexte (jour, profil, semaine, mémoire)': avecContexte - personaSeule,
        'liste des exercices': tout - (avecOutils - enveloppe) - avecContexte,
        'déclarations des ${ryzeTools.declarationsFor(RyzeSurface.coach).length} outils':
            avecOutils - enveloppe,
      };

      final lignes = parts.entries.map((e) =>
          '  ${e.key.padRight(42)} ${e.value.toString().padLeft(6)}  '
          '${(e.value * 100 / tout).toStringAsFixed(0).padLeft(3)} %');

      // ignore: avoid_print
      print('\n─── un message de chat, à l\'entrée ───\n${lignes.join('\n')}\n'
          '  ${'TOTAL'.padRight(42)} ${tout.toString().padLeft(6)}\n');

      // Le prompt n'a pas vocation à enfler sans qu'on le voie.
      expect(tout, lessThan(12000),
          reason: 'le prompt d\'entrée a franchi douze mille jetons');
    });
  });

  group('Ce que coûte un tour', () {
    test('le chat, une phrase courte', () async {
      if (key == null) return;
      final body = await corpsCoach('J\'ai bu un grand verre d\'eau');
      final u = await appelReel(body);
      noter('chat, phrase courte', u.entree, u.sortie);
    });

    test('le chat, une séance à créer', () async {
      if (key == null) return;
      final body = await corpsCoach(
        'Fais-moi une séance dos et biceps pour demain soir, une heure',
      );
      final u = await appelReel(body);
      noter('chat, séance créée', u.entree, u.sortie);
    });

    test('le chat, une semaine de repas', () async {
      if (key == null) return;
      // Une phrase qui ne laisse rien à demander : sinon le modèle pose une
      // question, ce qu'il fait souvent et qui ne coûte presque rien. Ce
      // qu'on veut connaître ici, c'est le tour où il génère vraiment.
      final body = await corpsCoach(
        'Planifie petit-déjeuner, déjeuner, dîner et collation pour lundi, mardi, '
        'mercredi, jeudi, vendredi, samedi et dimanche prochains. Ne me pose aucune '
        'question, crée tout maintenant avec les ingrédients et la préparation de '
        'chaque plat.',
        sortieMax: 8192,
      );
      final u = await appelReel(body);
      noter('chat, semaine de repas', u.entree, u.sortie,
          note: 'le plus gros appel de l\'application');
    });
  });

  group('Ce que coûte une analyse', () {
    /// Une photo à la taille que l'application envoie : 1024 px sur le grand
    /// côté, JPEG qualité 85. Le contenu ne change pas le compte de jetons,
    /// seule la dimension le fait.
    String photoDeTest() {
      final image = img.Image(width: 1024, height: 768);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          image.setPixelRgb(x, y, (x * 7) % 256, (y * 5) % 256, ((x + y) * 3) % 256);
        }
      }
      return base64Encode(img.encodeJpg(image, quality: 85));
    }

    test('une photo de repas', () async {
      if (key == null) return;

      final prompt = GeminiAnalysisServiceV2.buildImagePrompt(
        userNote: 'Il y a 150 g de purée',
        countryName: 'France',
        cultureContext: 'French',
        languageCode: 'fr',
      );

      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': photoDeTest()}
              },
            ]
          }
        ],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 2000},
      };

      final entree = await jetonsDe(body);
      // La sortie d'une analyse est une liste d'aliments : cinq à dix lignes.
      noter('photo de repas', entree, 320,
          note: 'sortie estimée à 320 jetons, la photo de test n\'a rien à décrire');
    });

    test('un repas décrit à l\'écrit', () async {
      if (key == null) return;

      final prompt = GeminiAnalysisServiceV2.buildTextPrompt(
        textDescription: 'Deux œufs brouillés, une tranche de pain complet et un café',
        countryName: 'France',
        languageCode: 'fr',
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
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 2000},
      };

      final u = await appelReel(body);
      noter('repas décrit à l\'écrit', u.entree, u.sortie);
    });
  });

  group('Le relevé', () {
    test('ce qu\'un utilisateur normal dépense en un mois', () async {
      if (key == null) return;
      expect(releve, isNotEmpty, reason: 'les mesures tournent avant celle-ci');

      double centsDe(String quoi) {
        final m = releve.firstWhere((m) => m.quoi == quoi);
        return (m.entree / 1e6 * prixEntree + m.sortie / 1e6 * prixSortie) * 100;
      }

      // Un usage plausible, pas un usage extrême. À corriger dès que la table
      // ryze_ai_usage aura des vraies lignes.
      const parMois = {
        'chat, phrase courte': 60, // deux échanges par jour
        'chat, séance créée': 8,
        'chat, semaine de repas': 4,
        'photo de repas': 45, // une photo et demie par jour
        'repas décrit à l\'écrit': 30,
      };

      var total = 0.0;
      final lignes = <String>[];
      parMois.forEach((quoi, n) {
        final c = centsDe(quoi) * n;
        total += c;
        lignes.add('  ${quoi.padRight(26)} × $n = ${(c / 100).toStringAsFixed(3)} \$');
      });

      // ignore: avoid_print
      print('\n─── par utilisateur et par mois ───\n${lignes.join('\n')}\n'
          '  ${'TOTAL'.padRight(26)}     ${(total / 100).toStringAsFixed(3)} \$\n');

      // Le seuil qui compte : un abonnement ne doit pas être mangé par l'IA.
      expect(total / 100, lessThan(1.0),
          reason: 'plus d\'un dollar par utilisateur et par mois : à revoir');
    });
  });
}

class _Mesure {
  _Mesure(this.quoi, this.entree, this.sortie, this.note);
  final String quoi;
  final int entree;
  final int sortie;
  final String? note;
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
