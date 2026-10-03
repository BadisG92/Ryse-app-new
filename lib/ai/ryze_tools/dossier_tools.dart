import 'dart:async';
import 'dart:convert';

import '../../models/coach_chat_models.dart';
import '../../services/analytics_service.dart';
import '../../services/coach_personality_service.dart';
import '../../services/coach_preference_extractor.dart';
import '../../services/global_state_manager.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../dossier.dart';
import '../ryze_memory.dart';
import 'ryze_tool.dart';

/// Le dossier : Ryze compile ce qu'il sait de l'utilisateur, dans sa voix.
///
/// Le modèle a déjà tout sous les yeux quand il répond : sa mémoire, les
/// réponses de l'onboarding, les dernières séances et les records, la
/// tendance du poids, la semaine prévue et faite, l'arc. L'outil ne va donc
/// rien chercher de plus : il reçoit les lignes que le modèle a choisies,
/// vérifie qu'aucune ne touche à la santé, ramène le tampon à la liste,
/// compte honnêtement ce qui est retenu, et rend la carte à la surface.
class DossierTools {
  DossierTools._();

  static String get _lang => LocalizationService.instance.currentLanguageCode;

  /// En dessous, ce n'est pas un dossier, c'est une remarque.
  static const int minLines = 3;
  static const int maxLines = 8;

  /// Une ligne est un fait, pas un paragraphe.
  static const int maxLineLength = 90;

  static final dossier = RyzeTool(
    name: 'memory.dossier',
    declaration: toolSchema(
      name: 'memory.dossier',
      description:
          "Compile the user's file: what you have remembered about them and what their "
          'own log shows, with one stamp on it. Call it when they ask what you know or '
          'remember about them, ask for their file or dossier, or ask why they are not '
          'getting anywhere when the honest answer sits in their own record. '
          'Unlike other tools, everything you pass here is shown to the user word for '
          'word on a card, so write it in your tone, the exact personality you were '
          'given at the top of your instructions (a custom one included), not as '
          'neutral data. Between 4 and 8 lines, each one fact in the user\'s language, '
          'at most 70 characters, written the way you would say it: short, concrete, '
          'with your tone\'s edge, never invented ("Promised: no tacos after midnight. '
          'Twice.", "Trains in a garage with two dumbbells and big dreams", "Bench '
          'press record: 80 kg on 28 Sept", "3 dinners out of 7 logged after 10 pm"). '
          'Draw them from the memory block and the context: promises, preferences, '
          'equipment, habits, records, weight trend, planned versus done, the arc. '
          'Never an allergy, a diet, an injury or anything medical, even if it is in '
          'memory. The stamp is a one or two word verdict picked from the list, in the '
          'user\'s language, matching your tone and the file. Then the card is on '
          'screen with the lines and the stamp, and the ONE sentence you say next is '
          'printed on the card under your name as the verdict: the line people quote, '
          'a jab that sums the file up in your tone, at most 14 words, which may turn '
          'one of the user\'s own words against them. Say that sentence and nothing '
          'else: no greeting, no recap of the lines, no question.',
      properties: {
        'lines': {
          'type': 'array',
          'description': '4 to 8 facts, one per item, in the user\'s language and in your tone, at most 70 characters each.',
          'items': {'type': 'string'},
        },
        'stamp': {
          'type': 'string',
          'description': 'The stamp word, exactly as listed, in the user\'s language.',
          'enum': DossierStamps.enumWords(),
        },
      },
      required: ['lines', 'stamp'],
    ),
    execute: (args) async {
      final lang = _lang;
      final raw = linesArg(args['lines']);

      final prefs = await RyzeMemory.instance.load();
      final health = <String>[
        ...?prefs?.allergies,
        ...?prefs?.dietaryRestrictions,
        ...?prefs?.fitnessConstraints,
      ];
      final lines = sanitize(raw, exclude: health);

      if (lines.length < minLines) {
        return RyzeToolResult(
          ok: false,
          summary: 'ryze_dossier_failed'.tr(lang),
          data: {
            'error': 'need at least $minLines usable lines; '
                '${raw.length - lines.length} were dropped (empty, too long, or medical)',
          },
        );
      }

      final stamp = pickStamp('${args['stamp'] ?? ''}');

      final personality = await CoachPersonalityService.instance.getPersonality();
      final personaLabel = personality.type == CoachPersonalityType.custom
          ? 'coach_ryze'.tr(lang)
          : CoachPersonalityService.getLocalizedLabel(personality.type, lang);

      final d = RyzeDossier(
        name: firstName(GlobalStateManager.instance.userName),
        lines: lines,
        stampId: stamp.id,
        stampWord: stamp.word(lang),
        // Le verdict est la phrase que le coach dira après la carte : la
        // surface l'y posera. Demandé ici, il sortait plat.
        verdict: '',
        count: countFacts(prefs),
        personaLabel: personaLabel,
        lang: lang,
        at: DateTime.now(),
      );

      unawaited(AnalyticsService.logEvent('dossier_compiled', parameters: {
        'lines': lines.length,
        'stamp': stamp.id,
      }));

      return RyzeToolResult(
        ok: true,
        summary: 'dossier_compiled'.tr(lang),
        data: {
          'shown_lines': lines.length,
          'stamp': d.stampWord,
          'facts_on_file': d.count,
          'note': 'The card with the lines and the stamp is on screen. The one '
              'sentence you say now is printed on it as the verdict: a jab that sums '
              'the file up in your tone, at most 14 words, nothing else.',
        },
        payload: d,
      );
    },
  );

  /// Les lignes telles que le modèle les a envoyées : un tableau, d'ordinaire,
  /// mais parfois une seule chaîne, soit un tableau JSON écrit en texte, soit
  /// des lignes séparées par des retours ou des puces.
  static List<String> linesArg(Object? v) {
    if (v is List) return v.map((e) => '$e').toList();
    if (v is! String) return const [];
    final s = v.trim();
    if (s.isEmpty) return const [];
    if (s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded.map((e) => '$e').toList();
      } catch (_) {
        // pas du JSON : on découpe comme du texte
      }
    }
    return s.split(RegExp(r'\n+|\s*[•▪]\s*')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  /// Les lignes telles que la carte les gardera : nettoyées, bornées, et
  /// sans rien de ce que [exclude] porte.
  ///
  /// L'exclusion compare sur la forme normalisée des faits, la même que le
  /// dédoublonnage de la mémoire : « Allergie : noix » et « allergique aux
  /// noix » se retrouvent.
  static List<String> sanitize(List<String> raw, {Iterable<String> exclude = const []}) {
    // Les mots qui portent un fait de santé : « allergique aux noix » donne
    // « allergique » et « noix », et toute ligne qui en reprend un tombe.
    final banned = <String>{
      for (final f in exclude)
        for (final t in CoachPreferenceExtractor.normalizeFact(f).split(' '))
          if (t.length >= 4 && !_stopWords.contains(t)) t,
    };

    final out = <String>[];
    final seen = <String>{};
    for (final r in raw) {
      var line = r.replaceAll(RegExp(r'\s+'), ' ').trim();
      line = line.replaceFirst(RegExp(r'^[-•*▪]\s*'), '');
      if (line.length < 3) continue;

      final key = CoachPreferenceExtractor.normalizeFact(line);
      if (touchesHealth(key, banned)) continue;
      if (!seen.add(key)) continue;

      out.add(clip(line, maxLineLength));
      if (out.length == maxLines) break;
    }
    return out;
  }

  /// Une ligne normalisée parle-t-elle de santé ? Soit elle reprend un mot
  /// d'un fait exclu, soit elle porte un mot médical, dans les trois langues.
  static bool touchesHealth(String normalizedLine, Set<String> bannedTokens) {
    if (_medical.any(normalizedLine.contains)) return true;
    final tokens = normalizedLine.split(' ');
    return tokens.any(bannedTokens.contains);
  }

  /// Des racines, sans accents, comme la normalisation les écrit.
  static const List<String> _medical = [
    'allerg', 'intoler', 'injur', 'blessur', 'verletz', 'douleur', 'schmerz',
    'diabet', 'medic', 'medik', 'tendin', 'herni', 'asthm', 'enceinte', 'pregnan',
    'schwanger', 'chirurg', 'surgery', 'fractur', 'bruch', 'maladie', 'illness',
    'krank', 'gluten', 'lactose', 'laktose',
  ];

  /// Les mots d'un fait qui ne disent rien de lui.
  static const Set<String> _stopWords = {
    'avec', 'sans', 'dans', 'pour', 'plus', 'pas', 'des', 'les', 'une', 'aux', 'apres', 'avant',
    'with', 'without', 'the', 'and', 'after', 'before', 'more', 'than', 'from', 'that',
    'mit', 'ohne', 'und', 'nicht', 'mehr', 'nach', 'vor', 'kein', 'keine', 'einen', 'eine',
    'jour', 'jours', 'days', 'week', 'semaine', 'woche', 'minuit', 'midnight', 'mitternacht',
    'matin', 'soir', 'morning', 'evening', 'morgens', 'abends', 'fois', 'times',
  };

  /// Le tampon demandé, ou le neutre si le mot n'est pas de la liste.
  static DossierStamp pickStamp(String word) => DossierStamps.byWord(word) ?? DossierStamps.fallback;

  /// Combien de faits Ryze détient : sa mémoire et l'onboarding. Les lignes
  /// mesurées (records, tendances) ne comptent pas, elles ne sont pas
  /// « retenues », elles sont relues.
  static int countFacts(UserCoachPreferences? prefs) {
    final insights = prefs?.onboardingInsights?.trim() ?? '';
    final insightLines = insights.isEmpty ? 0 : insights.split('\n').where((l) => l.trim().isNotEmpty).length;
    return RyzeMemory.itemsOf(prefs).length + insightLines;
  }

  /// Le prénom seul ; vide quand le profil n'en a pas.
  static String firstName(String userName) {
    final n = userName.trim();
    if (n.isEmpty || n.toLowerCase() == 'user') return '';
    return n.split(RegExp(r'\s+')).first;
  }

  static String clip(String s, int max) {
    if (s.length <= max) return s;
    final cut = s.substring(0, max - 1);
    final space = cut.lastIndexOf(' ');
    return '${space > max * 0.6 ? cut.substring(0, space) : cut}…';
  }

  static List<RyzeTool> get all => [dossier];
}
