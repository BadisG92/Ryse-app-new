import '../services/coach_personality_service.dart';
import 'prompts/persona_de.dart';
import 'prompts/persona_en.dart';
import 'prompts/persona_fr.dart';
import 'prompts/persona_strings.dart';

/// Quelle surface parle : la conversation, ou l'écran du planificateur.
enum RyzeSurface { coach, planner }

/// L'instruction système de Ryze.
///
/// L'ordre compte, et c'est tout l'objet de ce fichier.
///
/// 1. Qui parle et dans quoi.
/// 2. **Ce qui ne se négocie pas** : le périmètre, le médical, l'absence de
///    jugement, l'interdiction de prétendre qu'une action a eu lieu, et celle
///    d'inventer une donnée absente du contexte.
/// 3. Le **ton**, encadré : il change comment Ryze parle, jamais les règles
///    ni ce qu'il peut faire.
/// 4. Comment agir avec les outils, à la place des « va dans l'onglet Sport ».
/// 5. La longueur, puis la langue.
/// 6. Enfin les blocs de contexte, qui changent à chaque envoi.
///
/// Avant, le ton venait en premier sous le titre « PRIORITÉ ABSOLUE », et le
/// ton libre était encadré d'un « applique ceci à cent pour cent, ne reviens
/// jamais à un ton normal ». Deux cents caractères écrits par l'utilisateur
/// pouvaient donc primer sur la règle médicale.
class RyzePersona {
  RyzePersona._();

  static const Map<String, PersonaStrings> _byLang = {
    'fr': PersonaFr(),
    'en': PersonaEn(),
    'de': PersonaDe(),
  };

  /// Le texte de cette langue, l'anglais à défaut.
  static PersonaStrings of(String lang) => _byLang[lang] ?? const PersonaEn();

  /// Les langues pour lesquelles un texte existe.
  static Iterable<String> get languages => _byLang.keys;

  /// Construit l'instruction système.
  ///
  /// [context] est le bloc déjà rendu par `RyzeContext` ; il arrive en dernier
  /// parce qu'il est le seul à changer d'un envoi à l'autre.
  static Future<String> build({
    required String lang,
    required RyzeSurface surface,
    required String userName,
    String? gender,
    int? age,
    String context = '',
    String surfaceRules = '',
    String? tone,
  }) async {
    // Le ton choisi par l'utilisateur, réutilisé tel quel : ce texte existe
    // déjà dans les trois langues et il est bon.
    //
    // Il peut être fourni : le banc d'essai monte le prompt exact hors de
    // l'application, où le service de personnalité n'a ni base ni compte.
    final s = of(lang);
    tone ??= await CoachPersonalityService.instance
        .buildPersonalityInstruction(lang, gender: gender);

    final parts = <String>[
      s.identity(userName),
      '',
      s.nonNegotiables,
      '',
      s.styleFrame,
      tone.trim(),
      '',
      _adaptation(s, gender, age),
      '',
      s.toolGuidance,
    ];

    if (surfaceRules.trim().isNotEmpty) {
      parts..add('')..add(surfaceRules.trim());
    }

    parts..add('')..add(s.lengthRule);

    if (context.trim().isNotEmpty) {
      parts..add('')..add(context.trim());
    }

    // La langue en dernier : c'est la consigne que le modèle doit avoir le
    // plus fraîche en mémoire au moment de répondre.
    parts..add('')..add('## LANGUE / LANGUAGE / SPRACHE')..add(s.languageRule);

    return parts.join('\n');
  }

  static String _adaptation(PersonaStrings s, String? gender, int? age) {
    final lines = <String>[s.genderRule(gender)];
    final byAge = s.ageRule(age);
    if (byAge.isNotEmpty) lines.add(byAge);
    return lines.where((l) => l.trim().isNotEmpty).join('\n');
  }
}
