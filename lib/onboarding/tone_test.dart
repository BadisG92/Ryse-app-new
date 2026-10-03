import '../ai/ryze_oneshot.dart';
import '../ai/ryze_persona.dart';
import '../ai/ryze_transport.dart';
import '../services/coach_personality_service.dart';

/// L'excuse de la personne, et les répliques écrites d'avance qui y
/// répondent dans les cinq tons.
class OnbToneScript {
  OnbToneScript._();

  /// Les raisons du chapitre 2 (« ce qui t'a fait lâcher »), sans leur
  /// préfixe : chacune a son excuse et ses cinq répliques.
  static const List<String> excuses = ['time', 'motiv', 'diet', 'know', 'slow', 'none'];

  /// La première raison cochée. C'est l'excuse de la personne, sans rien lui
  /// demander ; sans raison cochée (le ton repris plus tard, depuis l'app),
  /// la plus universelle.
  static String excuseKey(List<String> obstacles) {
    for (final o in obstacles) {
      final key = o.replaceFirst('obs_', '');
      if (excuses.contains(key)) return key;
    }
    return 'none';
  }

  /// Le prénom à sa place, ou retiré proprement quand on ne l'a pas :
  /// « Pas la force de bouger, {n}, mais… » devient « Pas la force de
  /// bouger, mais… », jamais « bouger, , mais… ».
  static String withName(String text, String? name) {
    final n = (name ?? '').trim();
    if (n.isNotEmpty) return text.replaceAll('{n}', n);
    return text.replaceAll(RegExp(r',?\s*\{n\}'), '');
  }

  /// L'excuse entre les guillemets de la langue.
  static String quoted(String text, String lang) => switch (lang) {
        'fr' => '«\u00A0$text\u00A0»',
        'de' => '„$text“',
        _ => '“$text”',
      };
}

/// La réponse du vrai coach au ton qu'on vient d'écrire.
///
/// Les cinq tons prédéfinis ont leur réplique écrite d'avance : instantanée,
/// sans réseau, et travaillée pour que chacun fasse un geste différent. Le
/// ton écrit à la main, lui, ne peut pas s'écrire d'avance : ici c'est le
/// vrai coach, avec la même identité, les mêmes règles qui ne se négocient
/// pas et la même consigne de ton que dans l'app, appliquée à l'excuse de la
/// personne. Il se voit ainsi avant l'achat.
///
/// Peu de jetons, et un plafond par onboarding : c'est une démonstration,
/// pas une conversation.
class OnbToneTest {
  OnbToneTest._();

  /// Au-delà, le coach ne répond plus ici : la feuille garde le ton, la
  /// carte affiche une réplique de repli.
  static const int maxReplies = 6;

  /// Une excuse se dit en une phrase.
  static const int maxExcuseLength = 120;

  static const Map<String, String> _task = {
    'fr': '''## CE MESSAGE
La personne choisit ton ton avant de commencer, et te teste avec une excuse. Réponds à cette excuse dans ton ton, en une ou deux phrases courtes (40 mots au plus). Reste de son côté : pas de leçon, pas de plan, pas de chiffre, aucun outil, rien que tu devrais faire ensuite. Pas de salutation.''',
    'en': '''## THIS MESSAGE
The user is choosing your tone before starting, and is testing you with an excuse. Answer the excuse in your tone, in one or two short sentences (40 words at most). Stay on their side: no lecture, no plan, no numbers, no tool, nothing you would have to do afterwards. No greeting.''',
    'de': '''## DIESE NACHRICHT
Die Person wählt deinen Ton, bevor sie anfängt, und testet dich mit einer Ausrede. Antworte auf die Ausrede in deinem Ton, in ein oder zwei kurzen Sätzen (höchstens 40 Wörter). Bleib auf ihrer Seite: keine Belehrung, kein Plan, keine Zahlen, kein Werkzeug, nichts, was du danach tun müsstest. Keine Begrüßung.''',
  };

  static const Map<String, String> _excuseLabel = {'fr': 'Son excuse :', 'en': 'Their excuse:', 'de': 'Die Ausrede:'};

  /// La réponse du coach, ou `null` si rien n'est venu.
  ///
  /// [gender] est celui de l'onboarding (`Homme` / `Femme`).
  static Future<String?> reply({
    required CoachPersonalityType type,
    required String customText,
    required String excuse,
    required String lang,
    String? name,
    String? gender,
    int? age,
  }) async {
    final s = RyzePersona.of(lang);
    final g = gender == 'Femme' ? 'female' : (gender == 'Homme' ? 'male' : null);
    final tone = CoachPersonalityService.instructionFor(type, customText.trim(), lang, gender: g);
    final said = excuse.trim();
    final prompt = [
      s.identity((name ?? '').trim()),
      '',
      s.nonNegotiables,
      '',
      s.styleFrame,
      tone.trim(),
      '',
      s.genderRule(g),
      s.ageRule(age),
      '',
      _task[lang] ?? _task['en']!,
      '',
      '${_excuseLabel[lang] ?? _excuseLabel['en']!} "${said.length > maxExcuseLength ? said.substring(0, maxExcuseLength) : said}"',
      '',
      '## LANGUE / LANGUAGE / SPRACHE',
      s.languageRule,
    ].join('\n');

    final text = await RyzeOneShot.text(
      prompt: prompt,
      surface: RyzeUsageLabel.coach,
      temperature: 0.9,
      maxOutputTokens: 200,
      timeout: const Duration(seconds: 15),
    );
    final out = text?.trim();
    return (out == null || out.isEmpty) ? null : out;
  }
}
