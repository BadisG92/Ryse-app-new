/// Ce que Ryze est, dans une langue.
///
/// Le prompt du coach était un squelette français, quelle que soit la langue de
/// l'utilisateur : seules deux ou trois phrases d'exemple et la ligne finale
/// « Respond in English » changeaient. Un utilisateur allemand recevait donc un
/// texte français lui demandant de répondre en allemand, avec des jours de la
/// semaine en anglais au milieu.
///
/// Chaque langue a maintenant son texte, **écrit** et non traduit mot à mot.
/// L'interface garantit qu'aucune section ne manque : un test parcourt les
/// trois implémentations et vérifie que chacune répond à tout.
abstract class PersonaStrings {
  const PersonaStrings();

  /// Le code de langue de l'application auquel ce texte correspond.
  String get lang;

  /// Comment nommer cette langue au modèle, en anglais.
  String get languageName;

  // ------------------------------------------------------------ identité

  /// Qui parle, et dans quoi. [name] est le prénom de l'utilisateur.
  String identity(String name);

  /// Ce qui ne se négocie pas, quel que soit le ton choisi.
  ///
  /// Ce bloc passe **avant** le style. Il était placé après, sous un titre
  /// « PRIORITÉ ABSOLUE » qui donnait le dernier mot au ton : deux cents
  /// caractères écrits librement par l'utilisateur pouvaient primer sur la
  /// règle médicale et sur le périmètre du coach.
  String get nonNegotiables;

  /// Ce que le ton change, et ce qu'il ne change pas.
  String get styleFrame;

  /// Comment agir plutôt que d'expliquer où aller.
  String get toolGuidance;

  /// La longueur attendue d'une réponse.
  String get lengthRule;

  /// L'ordre de répondre dans cette langue, en dernier.
  String get languageRule;

  // ------------------------------------------------------- adaptation

  /// L'accord et le vocabulaire selon le genre. [gender] vaut `male`,
  /// `female`, ou autre chose quand il n'est pas renseigné.
  String genderRule(String? gender);

  /// Le registre selon l'âge. [age] est nul quand il n'est pas renseigné.
  String ageRule(int? age);

  // ------------------------------------------------------ intitulés

  /// Les titres des blocs de contexte, et les quelques mots qui les
  /// accompagnent. La clé est stable, la valeur est dans cette langue.
  String label(String key);
}

/// Les clés que [PersonaStrings.label] doit connaître.
///
/// Déclarées ici plutôt que dispersées : c'est sur cette liste que le test
/// vérifie qu'aucune langue n'a de trou.
const List<String> personaLabelKeys = [
  'section_now',
  'section_memory',
  'section_today',
  'section_meals',
  'section_profile',
  'section_history',
  'section_sessions',
  'section_week',
  'section_weight',
  'section_planner_window',
  'none_recorded',
  'no_meals_today',
  'no_history',
  'no_sessions',
  'no_cardio',
  'nothing_planned',
  'unavailable',
  'breakfast',
  'lunch',
  'dinner',
  'snack',
  'done',
  'missed',
  'planned',
  'eaten',
  'today',
  'past',
  'goal',
  'eaten_of',
  'remaining',
  'water',
  'streak_days',
  'gender_female',
  'gender_male',
  'gender_unknown',
  'not_set',
  'years_old',
];
