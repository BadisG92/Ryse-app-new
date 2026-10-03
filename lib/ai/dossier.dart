import '../services/coach_personality_service.dart';

/// Le dossier : ce que Ryze a retenu de quelqu'un, écrit dans sa voix, et le
/// tampon qui tombe dessus.
///
/// C'est la première chose de l'application faite pour sortir d'elle. Les
/// faits sont ceux de la mémoire et du journal ; le modèle les choisit et les
/// formule, l'outil compte et vérifie, la carte les montre. Le tampon n'est
/// jamais écrit librement : il est pris dans une liste fermée, un ou deux
/// mots, pour que le spectateur apprenne les mots et les reconnaisse d'un
/// post à l'autre.

/// Ce que le tampon dit du dossier.
enum DossierMood { toFix, good }

/// Un tampon : une identité stable, un ton, un mot par langue.
class DossierStamp {
  const DossierStamp({
    required this.id,
    required this.mood,
    required this.persona,
    required this.fr,
    required this.en,
    required this.de,
  });

  final String id;
  final DossierMood mood;

  /// Le ton dont c'est le mot ; nul pour un mot que tous peuvent prendre.
  final CoachPersonalityType? persona;

  final String fr;
  final String en;
  final String de;

  String word(String lang) => switch (lang) {
        'fr' => fr,
        'de' => de,
        _ => en,
      };

  List<String> get words => [fr, en, de];
}

/// Le vocabulaire fermé des tampons.
class DossierStamps {
  DossierStamps._();

  /// Seize caractères au plus : au-delà, le mot ne tient plus en deux lignes
  /// dans le cadre d'une carte de chat.
  static const int maxLength = 16;

  static const List<DossierStamp> all = [
    // Coach strict
    DossierStamp(id: 'insufficient', mood: DossierMood.toFix, persona: CoachPersonalityType.strict, fr: 'INSUFFISANT', en: 'NOT ENOUGH', de: 'UNGENÜGEND'),
    DossierStamp(id: 'acceptable', mood: DossierMood.good, persona: CoachPersonalityType.strict, fr: 'ACCEPTABLE', en: 'ACCEPTABLE', de: 'AKZEPTABEL'),
    // Taquin
    DossierStamp(id: 'could_do_better', mood: DossierMood.toFix, persona: CoachPersonalityType.sassy, fr: 'PEUT MIEUX FAIRE', en: 'COULD DO BETTER', de: 'GEHT BESSER'),
    DossierStamp(id: 'ill_allow_it', mood: DossierMood.good, persona: CoachPersonalityType.sassy, fr: 'ÇA PASSE', en: "I'LL ALLOW IT", de: 'GEHT DURCH'),
    // Bon pote
    DossierStamp(id: 'again', mood: DossierMood.toFix, persona: CoachPersonalityType.friendly, fr: 'ENCORE', en: 'AGAIN', de: 'NOCHMAL'),
    DossierStamp(id: 'not_bad', mood: DossierMood.good, persona: CoachPersonalityType.friendly, fr: 'PAS MAL', en: 'NOT BAD', de: 'NICHT SCHLECHT'),
    // Rassurant
    DossierStamp(id: 'keep_going', mood: DossierMood.toFix, persona: CoachPersonalityType.supportive, fr: 'ON AVANCE', en: 'KEEP GOING', de: 'WEITER SO'),
    DossierStamp(id: 'proud_of_you', mood: DossierMood.good, persona: CoachPersonalityType.supportive, fr: 'FIER DE TOI', en: 'PROUD OF YOU', de: 'STOLZ AUF DICH'),
    // Direct
    DossierStamp(id: 'seen', mood: DossierMood.toFix, persona: CoachPersonalityType.direct, fr: 'VU.', en: 'SEEN.', de: 'GESEHEN.'),
    DossierStamp(id: 'locked_in', mood: DossierMood.good, persona: CoachPersonalityType.direct, fr: 'VALIDÉ', en: 'LOCKED IN', de: 'GESCHAFFT'),
  ];

  /// Le tampon neutre, quand le modèle a écrit un mot hors liste.
  static DossierStamp get fallback => byId('seen')!;

  static DossierStamp? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Retrouve un tampon par son mot, dans n'importe quelle langue. Casse,
  /// espaces et point final ne comptent pas : le modèle écrit « vu » ou
  /// « Peut mieux faire » aussi bien que le mot exact.
  static DossierStamp? byWord(String word) {
    final key = _norm(word);
    if (key.isEmpty) return null;
    for (final s in all) {
      for (final w in s.words) {
        if (_norm(w) == key) return s;
      }
    }
    return null;
  }

  /// Les deux mots d'un ton, dans l'ordre : à corriger, puis validé.
  static List<DossierStamp> forPersona(CoachPersonalityType type) =>
      all.where((s) => s.persona == type).toList();

  /// Tous les mots, toutes langues confondues, sans doublon : c'est la liste
  /// que le modèle reçoit. Les déclarations d'outils se construisent une fois
  /// et la langue peut changer ensuite ; l'exécuteur ramène le mot choisi à
  /// son identité et le réécrit dans la langue du compte.
  static List<String> enumWords() {
    final out = <String>[];
    final seen = <String>{};
    for (final s in all) {
      for (final w in s.words) {
        if (seen.add(_norm(w))) out.add(w);
      }
    }
    return out;
  }

  static String _norm(String w) => w.trim().toUpperCase().replaceAll(RegExp(r'[.\s]+$'), '').replaceAll(RegExp(r'\s+'), ' ');
}

/// Un dossier compilé, tel qu'il est montré et gardé.
class RyzeDossier {
  const RyzeDossier({
    required this.name,
    required this.lines,
    required this.stampId,
    required this.stampWord,
    required this.verdict,
    required this.count,
    required this.personaLabel,
    required this.lang,
    required this.at,
  });

  /// Le prénom, tel que la carte l'écrit.
  final String name;

  /// Quatre à huit faits, dans la langue du compte.
  final List<String> lines;

  /// L'identité du tampon, et le mot tel qu'il a été posé.
  final String stampId;
  final String stampWord;

  /// Une phrase du coach, dans son ton.
  final String verdict;

  /// Combien de faits il détient en tout : les lignes de sa mémoire et de
  /// l'onboarding, pas seulement celles montrées. Jamais inventé.
  final int count;

  /// Le ton qui signe : « Coach strict », « Taquin », ou Ryze.
  final String personaLabel;

  final String lang;
  final DateTime at;

  /// La clé du genre de ligne dans `coach_messages.metadata`.
  static const String kind = 'dossier';

  /// Au-delà, ce n'est plus une vanne, c'est un paragraphe.
  static const int maxVerdictLength = 160;

  /// La phrase dite par le coach, prête à être imprimée : sans guillemets
  /// d'encadrement, sans puces, sur une ligne, bornée.
  static String tidyVerdict(String spoken) {
    var v = spoken.replaceAll(RegExp(r'\s+'), ' ').trim();
    v = v.replaceFirst(RegExp(r'^[-•*]\s*'), '');
    if (v.length >= 2 && RegExp(r'^[«"“]').hasMatch(v) && RegExp(r'[»"”]$').hasMatch(v)) {
      v = v.substring(1, v.length - 1).trim();
    }
    if (v.length <= maxVerdictLength) return v;
    final cut = v.substring(0, maxVerdictLength - 1);
    final space = cut.lastIndexOf(' ');
    return '${space > maxVerdictLength * 0.6 ? cut.substring(0, space) : cut}…';
  }

  Map<String, dynamic> toMetadata() => {
        'kind': kind,
        'name': name,
        'lines': lines,
        'stamp_id': stampId,
        'stamp': stampWord,
        'verdict': verdict,
        'count': count,
        'persona': personaLabel,
        'lang': lang,
        'at': at.toIso8601String(),
      };

  static RyzeDossier? fromMetadata(Map<String, dynamic> m) {
    if (m['kind'] != kind) return null;
    final lines = (m['lines'] as List?)?.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList() ?? const [];
    if (lines.isEmpty) return null;
    return RyzeDossier(
      name: '${m['name'] ?? ''}',
      lines: lines,
      stampId: '${m['stamp_id'] ?? DossierStamps.fallback.id}',
      stampWord: '${m['stamp'] ?? ''}',
      verdict: '${m['verdict'] ?? ''}',
      count: (m['count'] is num) ? (m['count'] as num).round() : lines.length,
      personaLabel: '${m['persona'] ?? ''}',
      lang: '${m['lang'] ?? 'fr'}',
      at: DateTime.tryParse('${m['at'] ?? ''}') ?? DateTime.now(),
    );
  }
}
