@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ryze_app/ai/ryze_persona.dart';
import 'package:ryze_app/ai/ryze_tools/ryze_tools.dart';

/// Ce que le vrai modèle fait du vrai prompt.
///
/// Tout le reste se teste hors ligne : les schémas, les bornes, les rendus.
/// Ce qui ne se teste pas hors ligne, c'est le choix. Est-ce qu'il appelle le
/// bon outil ? Est-ce qu'il en appelle deux quand la phrase en contient deux ?
/// Est-ce qu'il redemande la permission ? Ces questions n'ont de réponse
/// qu'en interrogeant le modèle avec exactement ce que l'application lui
/// envoie.
///
/// Ne tourne pas avec la suite ordinaire : il coûte des jetons et il dépend du
/// réseau. Pour le lancer :
///
///   flutter test test/ai/live_model_test.dart --run-skipped --tags live --dart-define-from-file=.env.local
///
/// Sans clé, tout est ignoré plutôt que rouge : un test d'intégration qui
/// échoue faute de secret ne dit rien de l'application.
void main() {
  final key = _apiKey();
  const model = 'gemini-3.1-flash-lite';

  /// Le contexte que l'application colle sous la persona, réduit à ce dont le
  /// choix d'outil dépend : la date, et l'état du jour.
  String contexteDu(DateTime now) {
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final j = jours[now.weekday - 1];
    final demain = now.add(const Duration(days: 1));
    final d = jours[demain.weekday - 1];

    return '''
## DATE ET HEURE
$j ${now.day} ${mois[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} (UTC+02:00)
« aujourd'hui » = $j ${now.day} ${mois[now.month - 1]}. « demain » = $d ${demain.day} ${mois[demain.month - 1]}.

## AUJOURD'HUI
Objectif : 2200 kcal
Mangé : 0 kcal
Reste : 2200 kcal
P 0/165 g · G 0/220 g · L 0/73 g
Eau : 0.0/2.5 L

## LA SEMAINE
Rien de prévu.''';
  }

  Future<_Tour> demande(String phrase, {DateTime? now}) async {
    final instruction = await RyzePersona.build(
      lang: 'fr',
      surface: RyzeSurface.coach,
      userName: 'Badis',
      gender: 'male',
      age: 30,
      context: contexteDu(now ?? DateTime.now()),
      tone: 'Tu es un coach chaleureux. Tu tutoies.',
    );

    final body = {
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
      'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 1024},
    };

    // Le modèle rend parfois 503 « high demand ». Ce n'est pas un défaut de
    // l'application, et un banc qui rougit là-dessus ne dit plus rien.
    final started = DateTime.now();
    late http.Response response;
    for (var essai = 1; essai <= 4; essai++) {
      response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': key!},
        body: jsonEncode(body),
      );
      if (response.statusCode != 503 && response.statusCode != 429) break;
      await Future<void>.delayed(Duration(milliseconds: 700 * essai));
    }
    final elapsed = DateTime.now().difference(started);

    expect(response.statusCode, 200, reason: response.body);

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final parts = (((json['candidates'] as List).first as Map)['content'] as Map)['parts'] as List? ?? [];

    final calls = <_Appel>[];
    final texte = StringBuffer();
    for (final part in parts) {
      final p = part as Map<String, dynamic>;
      if (p['text'] is String) texte.write(p['text']);
      final fc = p['functionCall'];
      if (fc is Map) {
        calls.add(_Appel('${fc['name']}', Map<String, dynamic>.from(fc['args'] as Map? ?? {})));
      }
    }

    final tour = _Tour(phrase, calls, texte.toString().trim(), elapsed);
    // ignore: avoid_print
    print(tour);
    return tour;
  }

  group('Ce que le prompt pèse', skip: key == null ? 'sans GEMINI_API_KEY' : null, () {
    test('la taille de ce qu\'on envoie à chaque message', () async {
      final instruction = await RyzePersona.build(
        lang: 'fr',
        surface: RyzeSurface.coach,
        userName: 'Badis',
        context: contexteDu(DateTime.now()),
        tone: 'Tu es un coach chaleureux. Tu tutoies.',
      );
      final outils = jsonEncode(ryzeTools.declarationsFor(RyzeSurface.coach));

      // ignore: avoid_print
      print('\n  instruction : ${instruction.length} caractères'
          '\n  outils      : ${outils.length} caractères (${ryzeTools.declarationsFor(RyzeSurface.coach).length} déclarations)'
          '\n  total       : ${instruction.length + outils.length} caractères, soit ~${((instruction.length + outils.length) / 4).round()} jetons\n');

      // Un garde-fou large : au-delà, la latence se voit.
      expect(instruction.length + outils.length, lessThan(24000));
    });
  });

  group('Ce que le modèle choisit', skip: key == null ? 'sans GEMINI_API_KEY' : null, () {
    test('un verre d\'eau se note', () async {
      final tour = await demande('J\'ai bu deux grands verres d\'eau');

      expect(tour.noms, contains('journal.log_water'));
      expect(tour.premier('journal.log_water')!.args['amount_ml'], greaterThanOrEqualTo(500));
    });

    test('sans jour dit, la séance tombe aujourd\'hui', () async {
      // Le défaut vu à quatre heures du matin : « demain » sorti de nulle part.
      final mardi = DateTime(2026, 9, 8, 20, 0);
      final tour = await demande(
        'Planifie-moi une séance de dos de 45 minutes',
        now: mardi,
      );

      final appel = tour.premier('plan.create_workout');
      expect(appel, isNotNull, reason: 'aucune séance créée');
      expect(appel!.args['day'], 'tuesday');
    });

    test('« demain » se calcule, il ne se devine pas', () async {
      final mardi = DateTime(2026, 9, 8, 20, 0);
      final tour = await demande('Planifie-moi une séance de dos de 45 min demain', now: mardi);

      expect(tour.premier('plan.create_workout')?.args['day'], 'wednesday');
    });

    test('deux repas dans une phrase font deux appels', () async {
      // Vu sur appareil : le déjeuner était ignoré.
      final tour = await demande(
        'Au petit déjeuner j\'ai mangé trois œufs brouillés et un bol de céréales, '
        'et au déjeuner un hamburger avec des frites et un coca',
      );

      expect(tour.noms.where((n) => n == 'journal.log_food_text').length, 2,
          reason: 'un seul appel ne peut pas porter deux repas');
    });

    test('la séance créée porte ses exercices', () async {
      // Sans eux, un second modèle les choisit et Ryze raconte autre chose.
      final tour = await demande('Fais-moi un full body de 30 minutes sans matériel pour aujourd\'hui');

      final appel = tour.premier('plan.create_workout');
      expect(appel, isNotNull);
      final exercices = appel!.args['exercises'];
      expect(exercices, isA<List>());
      expect((exercices as List).length, greaterThanOrEqualTo(3));
      expect((exercices.first as Map)['canonical_name_en'], isNotNull);
    });

    test('une contrainte durable se retient', () async {
      final tour = await demande('Je suis allergique aux fruits à coque');
      expect(tour.noms, contains('memory.remember'));
    });

    test('une question n\'appelle aucun outil', () async {
      // `AUTO` et non `ANY` : « merci » ne doit rien déclencher.
      final tour = await demande('Merci, tu gères !');
      expect(tour.noms, isEmpty);
      expect(tour.texte, isNotEmpty);
    });

    test('Ryze ne demande pas la permission d\'agir', () async {
      final tour = await demande('Ajoute un yaourt grec aux fruits rouges à mon petit déjeuner');

      expect(tour.noms, contains('plan.create_meal'));
      // « Veux-tu que je l'ajoute ? » : la carte pose déjà la question.
      final texte = tour.texte.toLowerCase();
      expect(texte.contains('veux-tu que je') || texte.contains('souhaites-tu que je'), isFalse,
          reason: 'il repose une question que l\'application pose : ${tour.texte}');
    });
  });

  group('La recette est complète, même depuis la conversation', () {
    test('les quatre parties y sont', () async {
      // Badis : « via le chat il n'y a pas le même niveau de détail sur la
      // recette et les ingrédients que si c'est le planificateur ».
      final tour = await demande('Prévois-moi un dîner ce soir, un truc simple avec du saumon');

      final appel = tour.premier('plan.create_meal');
      expect(appel, isNotNull, reason: 'aucun repas créé');

      // Chaque partie a son champ : c'est ce qui a fait la différence. Une
      // consigne de mise en forme au milieu d'une description de paramètre se
      // perd, un champ vide se voit.
      final ingredients = '${appel!.args['ingredients'] ?? ''}'.trim();
      final method = '${appel.args['method'] ?? ''}'.trim();
      final resume = '${appel.args['dish_description'] ?? ''}'.trim();

      expect(resume, isNotEmpty, reason: 'pas de description');
      expect(ingredients, isNotEmpty, reason: 'pas d\'ingrédients');
      expect(method, isNotEmpty, reason: 'pas de préparation');

      // Les ingrédients viennent en lignes, pas en paragraphe.
      expect(ingredients.split('\n').length, greaterThanOrEqualTo(2),
          reason: 'les ingrédients tiennent en une ligne : $ingredients');
    });
  });

  group('La séance porte ses charges', () {
    test('chaque exercice a ses séries, ses répétitions et son poids', () async {
      final tour = await demande('Planifie-moi une séance de pecs de 45 minutes en salle');

      final appel = tour.premier('plan.create_workout');
      expect(appel, isNotNull);

      final exercices = (appel!.args['exercises'] as List).cast<Map<String, dynamic>>();
      // ignore: avoid_print
      print('\n  ${exercices.length} exercices, '
          'avec poids : ${exercices.where((e) => e['suggested_weight_kg'] != null).length}\n');

      expect(exercices.length, greaterThanOrEqualTo(4));
      for (final e in exercices) {
        expect(e['sets'], isNotNull, reason: '${e['exercise_name']} sans séries');
        expect(e['target_reps'], isNotNull, reason: '${e['exercise_name']} sans répétitions');
      }
    });
  });

  group('Le temps de réponse', skip: key == null ? 'sans GEMINI_API_KEY' : null, () {
    test('un tour simple aboutit dans un délai tenable', () async {
      // Le nombre est imprimé à chaque passage : c'est lui qui informe, pas le
      // seuil. Mesuré entre 1,4 et 4 s quand Google est calme, 13 s quand il
      // renvoie des 503 et que la reprise s'ajoute. Le seuil est donc large :
      // il n'attrape qu'une panne franche, pas une mauvaise journée chez eux.
      final tour = await demande('J\'ai bu un verre d\'eau');
      expect(tour.noms, contains('journal.log_water'));
      expect(tour.duree.inSeconds, lessThan(25), reason: '${tour.duree.inMilliseconds} ms');
    });
  });
}

/// La clé, prise là où l'application la prend.
String? _apiKey() {
  const compiled = String.fromEnvironment('GEMINI_API_KEY');
  if (compiled.isNotEmpty) return compiled;

  // Sans `--dart-define-from-file`, on lit le même fichier que l'application.
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

class _Appel {
  _Appel(this.nom, this.args);
  final String nom;
  final Map<String, dynamic> args;

  @override
  String toString() => '$nom(${jsonEncode(args)})';
}

class _Tour {
  _Tour(this.phrase, this.appels, this.texte, this.duree);

  final String phrase;
  final List<_Appel> appels;
  final String texte;
  final Duration duree;

  List<String> get noms => appels.map((a) => a.nom).toList();

  _Appel? premier(String nom) {
    for (final a in appels) {
      if (a.nom == nom) return a;
    }
    return null;
  }

  @override
  String toString() => '''

─────────────────────────────────────────────
» $phrase
  ${duree.inMilliseconds} ms
  outils : ${appels.isEmpty ? '(aucun)' : appels.join(', ')}
  texte  : ${texte.isEmpty ? '(aucun)' : texte}
─────────────────────────────────────────────''';
}
