import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../services/global_state_manager.dart';
import 'prompts/persona_strings.dart';

/// Les morceaux de contexte que Ryze peut recevoir.
///
/// Le prompt du coach reconstruisait tout, à chaque ouverture, en huit
/// requêtes : l'ouverture était lente et rien n'était réutilisé. Un bloc se
/// calcule une fois, se garde, et ne se refait que lorsque la donnée qu'il
/// décrit a bougé.
enum RyzeBlock {
  /// Le bilan du jour : calories, macros, eau.
  today,

  /// Les repas notés aujourd'hui.
  meals,

  /// Sexe, âge, objectif, poids, niveau d'activité, série en cours.
  profile,

  /// Ce que la semaine contient, séances **et repas**.
  weekPlan,

  /// Les habitudes des quatorze derniers jours, en deux lignes.
  history14d,

  /// Les dernières séances et les derniers cardios.
  recentSessions,

  /// La tendance du poids sur quatre semaines.
  weightTrend,

  /// Ce que Ryze a retenu de l'utilisateur.
  memory,

  /// Réservé au planificateur : jours disponibles, cibles par repas.
  plannerWindow,

  /// Les mouvements que le catalogue connaît déjà, par groupe musculaire.
  ///
  /// En dernier parce que c'est une référence et non une donnée de
  /// l'utilisateur : ce qui le concerne se lit en premier.
  exercises,
}

/// Un bloc rendu, avec l'heure à laquelle il a été calculé.
class _Cached {
  _Cached(this.text) : at = DateTime.now();
  final String text;
  final DateTime at;
}

/// Ce que Ryze sait de l'utilisateur au moment où il répond.
///
/// Chaque bloc est un couple : une fonction qui va chercher la donnée, et une
/// fonction pure qui la met en mots. La seconde se teste sans base ; c'est
/// elle qui porte les bornes et la langue.
///
/// Le cache est invalidé par les événements de l'application plutôt que par
/// une durée seule : boire un verre d'eau refait le bloc du jour, terminer une
/// séance refait les séances et la semaine, minuit refait tout. Une
/// conversation ouverte voit donc les changements sans qu'on la redémarre —
/// l'ancien code reconstruisait la session Gemini entière pour ça, en perdant
/// le fil.
class RyzeContext {
  RyzeContext._();

  static final RyzeContext instance = RyzeContext._();

  final Map<RyzeBlock, _Cached> _cache = {};
  StreamSubscription<StateChangeEvent>? _events;

  /// Au-delà, un bloc est refait même si rien n'a bougé.
  static const Duration ttl = Duration(minutes: 10);

  // ------------------------------------------------------------- bornes

  /// Au-delà, les repas du jour sont résumés plutôt qu'énumérés.
  ///
  /// Ce bloc n'avait aucune borne : une journée bien suivie produisait une
  /// ligne par aliment, sans plafond, dans un prompt déjà chargé.
  static const int maxMealLines = 20;

  /// Le nombre de séances et de cardios rappelés.
  static const int maxSessions = 5;

  /// Le nombre d'éléments de mémoire injectés.
  static const int maxMemoryItems = 40;

  // ------------------------------------------------- écoute des changements

  /// Branche l'invalidation sur les événements de l'application.
  ///
  /// Idempotent : un second appel ne crée pas un second abonnement.
  void listen() {
    if (_events != null) return;
    _events = GlobalStateManager.instance.events.listen((e) {
      invalidate(blocksFor(e.type));
    });
  }

  /// Quels blocs un changement rend faux.
  static Set<RyzeBlock> blocksFor(ChangeType type) => switch (type) {
        ChangeType.water ||
        ChangeType.calories ||
        ChangeType.macros =>
          {RyzeBlock.today},
        ChangeType.meals => {RyzeBlock.today, RyzeBlock.meals, RyzeBlock.weekPlan},
        ChangeType.workout || ChangeType.sport => {
            RyzeBlock.recentSessions,
            RyzeBlock.weekPlan,
          },
        ChangeType.planner => {RyzeBlock.weekPlan, RyzeBlock.plannerWindow},
        ChangeType.goals => {RyzeBlock.profile, RyzeBlock.today},
        ChangeType.streak => {RyzeBlock.profile},
        // Un nouveau jour, ou un lot de changements : plus rien n'est sûr.
        ChangeType.dayReset || ChangeType.batch || ChangeType.other =>
          RyzeBlock.values.toSet(),
      };

  void invalidate(Set<RyzeBlock> blocks) {
    for (final b in blocks) {
      _cache.remove(b);
    }
  }

  void clear() => _cache.clear();

  void dispose() {
    _events?.cancel();
    _events = null;
    _cache.clear();
  }

  /// Ce que le cache contient, pour les tests et le débogage.
  @visibleForTesting
  Set<RyzeBlock> get cached => _cache.keys.toSet();

  /// Rend un bloc, en le calculant seulement s'il manque ou s'il a vieilli.
  Future<String> block(RyzeBlock block, Future<String> Function() build) async {
    final hit = _cache[block];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) return hit.text;

    try {
      final text = await build();
      _cache[block] = _Cached(text);
      return text;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeContext: bloc $block indisponible : $e');
      // Un bloc qui échoue ne fait pas tomber le prompt : il s'absente.
      return hit?.text ?? '';
    }
  }

  // ------------------------------------------------------------- rendu

  /// Assemble les blocs dans l'ordre, en sautant ceux qui sont vides.
  static String assemble(Map<RyzeBlock, String> blocks) {
    final out = <String>[];
    for (final b in RyzeBlock.values) {
      final text = blocks[b]?.trim() ?? '';
      if (text.isNotEmpty) out.add(text);
    }
    return out.join('\n\n');
  }

  /// Un titre de section, suivi de son contenu.
  static String section(PersonaStrings s, String labelKey, String body) {
    final text = body.trim();
    if (text.isEmpty) return '';
    return '## ${s.label(labelKey)}\n$text';
  }

  // ------------------------------------------------- rendus purs, testables

  /// Quel jour on est, et quelle heure il est.
  ///
  /// Ryze ne le savait pas. Aucune date, aucune heure ne figurait dans son
  /// prompt, ni du côté de la conversation ni, après la fusion, du côté du
  /// planificateur. « Une séance demain » n'était donc pas un calcul mais une
  /// devinette, et elle tombait volontiers sur aujourd'hui.
  ///
  /// L'heure est celle de l'appareil, avec son décalage, parce que c'est
  /// l'heure que l'utilisateur a sous les yeux en écrivant.
  static String renderNow(PersonaStrings s, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final locale = switch (s.lang) { 'fr' => 'fr_FR', 'de' => 'de_DE', _ => 'en_US' };

    final jour = DateFormat('EEEE', locale).format(now);
    final date = DateFormat('d MMMM yyyy', locale).format(now);
    final heure = DateFormat('HH:mm', locale).format(now);

    final minutes = now.timeZoneOffset.inMinutes;
    final signe = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    final utc = 'UTC$signe${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}';

    return section(s, 'section_now', [
      '$jour $date, $heure ($utc)',
      _relativeDays(s, now),
      _daysLeft(s, now),
    ].join('\n'));
  }

  /// Les jours de cette semaine qui restent à remplir.
  ///
  /// L'écran du planificateur avait ce bloc, la conversation ne l'avait pas.
  /// Le même modèle, avec les mêmes outils, plaçait donc trois séances lundi,
  /// mardi et jeudi un mercredi soir : il savait la date, il n'avait jamais
  /// fait la soustraction. Le planificateur, lui, répondait jeudi, vendredi,
  /// samedi.
  ///
  /// Le garde-fou côté base refuse bien ces jours, mais refuser après coup
  /// n'est pas comprendre : l'utilisateur voyait trois cartes en erreur au
  /// lieu de trois séances.
  static String _daysLeft(PersonaStrings s, DateTime now) {
    final locale = switch (s.lang) { 'fr' => 'fr_FR', 'de' => 'de_DE', _ => 'en_US' };
    final fmt = DateFormat('EEEE', locale);

    // La semaine se termine dimanche : ce qui reste va d'aujourd'hui à là.
    final restants = <String>[
      for (var i = 0; i <= DateTime.sunday - now.weekday; i++)
        fmt.format(now.add(Duration(days: i))),
    ];

    if (restants.length <= 1) {
      return switch (s.lang) {
        'fr' => 'Cette semaine, il ne reste qu\'aujourd\'hui.',
        'de' => 'Diese Woche bleibt nur noch heute.',
        _ => 'Only today is left this week.',
      };
    }

    final liste = restants.join(', ');
    return switch (s.lang) {
      'fr' => 'Il reste $liste. Les autres jours de la semaine sont passés : '
          'n\'y place rien.',
      'de' => 'Es bleiben $liste. Die anderen Tage der Woche sind vorbei: '
          'plane nichts darauf.',
      _ => '$liste are left. The other days of this week are behind us: '
          'do not plan anything on them.',
    };
  }

  /// Les jours nommés, rattachés à une date, pour que « demain » se calcule
  /// au lieu de se deviner.
  static String _relativeDays(PersonaStrings s, DateTime now) {
    final locale = switch (s.lang) { 'fr' => 'fr_FR', 'de' => 'de_DE', _ => 'en_US' };
    final fmt = DateFormat('EEEE d MMMM', locale);

    final aujourd = fmt.format(now);
    final demain = fmt.format(now.add(const Duration(days: 1)));

    return switch (s.lang) {
      'fr' => '« aujourd\'hui » = $aujourd. « demain » = $demain.',
      'de' => '„heute“ = $aujourd. „morgen“ = $demain.',
      _ => '"today" = $aujourd. "tomorrow" = $demain.',
    };
  }

  /// Le bilan du jour.
  static String renderToday(
    PersonaStrings s, {
    required int calorieGoal,
    required int caloriesEaten,
    required int proteins,
    required int proteinsGoal,
    required int carbs,
    required int carbsGoal,
    required int fats,
    required int fatsGoal,
    required double waterL,
    required double waterGoalL,
  }) {
    final remaining = calorieGoal - caloriesEaten;
    final lines = [
      '${s.label('goal')} : $calorieGoal kcal',
      '${s.label('eaten_of')} : $caloriesEaten kcal',
      '${s.label('remaining')} : $remaining kcal',
      'P $proteins/$proteinsGoal g · G $carbs/$carbsGoal g · L $fats/$fatsGoal g',
      '${s.label('water')} : ${waterL.toStringAsFixed(1)}/${waterGoalL.toStringAsFixed(1)} L',
    ];
    return section(s, 'section_today', lines.join('\n'));
  }

  /// Les repas du jour, bornés.
  ///
  /// Au-delà de [maxMealLines], le reste est compté plutôt qu'énuméré : mieux
  /// vaut une ligne de plus que trente lignes qui poussent le reste dehors.
  static String renderMeals(PersonaStrings s, List<String> lines) {
    if (lines.isEmpty) return section(s, 'section_meals', s.label('no_meals_today'));

    final shown = lines.take(maxMealLines).map((l) => '- $l').toList();
    final extra = lines.length - shown.length;
    if (extra > 0) shown.add('- (+$extra)');
    return section(s, 'section_meals', shown.join('\n'));
  }

  /// Le profil.
  static String renderProfile(
    PersonaStrings s, {
    String? gender,
    int? age,
    String? fitnessGoal,
    double? currentWeight,
    double? targetWeight,
    String? activityLevel,
    int streak = 0,
  }) {
    String genderLabel() => switch (gender) {
          'female' => s.label('gender_female'),
          'male' => s.label('gender_male'),
          _ => s.label('gender_unknown'),
        };

    final lines = <String>[
      genderLabel(),
      if (age != null) '$age ${s.label('years_old')}',
      if (fitnessGoal != null && fitnessGoal.isNotEmpty) fitnessGoal,
      if (currentWeight != null)
        targetWeight != null
            ? '${currentWeight.toStringAsFixed(1)} kg → ${targetWeight.toStringAsFixed(1)} kg'
            : '${currentWeight.toStringAsFixed(1)} kg',
      if (activityLevel != null && activityLevel.isNotEmpty) activityLevel,
      if (streak > 0) '$streak ${s.label('streak_days')}',
    ];
    return section(s, 'section_profile', lines.join(' · '));
  }

  /// La tendance du poids, absente du prompt jusqu'ici.
  ///
  /// Le coach ne voyait que le poids courant et la cible, donc il ne pouvait
  /// pas dire si ça montait ou si ça descendait.
  static String renderWeightTrend(
    PersonaStrings s, {
    required double current,
    required double fourWeeksAgo,
    double? target,
  }) {
    final delta = current - fourWeeksAgo;
    final sign = delta > 0 ? '+' : '';
    final lines = <String>[
      '${current.toStringAsFixed(1)} kg',
      '4 sem. : $sign${delta.toStringAsFixed(1)} kg',
      if (target != null) '${s.label('goal')} : ${target.toStringAsFixed(1)} kg',
    ];
    return section(s, 'section_weight', lines.join(' · '));
  }

  /// Ce que Ryze a retenu, borné.
  static String renderMemory(PersonaStrings s, List<String> items) {
    if (items.isEmpty) return section(s, 'section_memory', s.label('none_recorded'));

    final shown = items.take(maxMemoryItems).map((i) => '- $i').toList();
    final extra = items.length - shown.length;
    if (extra > 0) shown.add('- (+$extra)');
    return section(s, 'section_memory', shown.join('\n'));
  }

  /// Les dernières séances, bornées.
  static String renderSessions(PersonaStrings s, List<String> lines) {
    if (lines.isEmpty) return section(s, 'section_sessions', s.label('no_sessions'));
    return section(s, 'section_sessions', lines.take(maxSessions * 2).map((l) => '- $l').join('\n'));
  }

  /// Les mouvements que le catalogue connaît, groupe par groupe.
  ///
  /// Le générateur de séance a toujours reçu cette liste ; le chat, jamais.
  /// Il nommait donc les exercices de mémoire, et « bent over row » ne
  /// rejoignait pas « Rowing barre » : un seul mouvement, deux lignes, deux
  /// historiques de charge, et une progression coupée en deux.
  ///
  /// Ce n'est pas une contrainte. Le catalogue est incomplet et Ryze doit
  /// pouvoir en sortir ; la consigne qui accompagne la liste le dit. Elle
  /// fixe l'orthographe de ce qui existe déjà, rien de plus.
  ///
  /// Une ligne par groupe, les noms séparés par des virgules : c'est trois
  /// fois plus court qu'une puce par exercice pour la même information.
  static String renderExercises(PersonaStrings s, Map<String, List<String>> byGroup) {
    if (byGroup.isEmpty) return '';

    final lines = <String>[s.label('exercises_hint'), ''];
    for (final entry in byGroup.entries) {
      final names = entry.value.where((n) => n.trim().isNotEmpty).toList();
      if (names.isEmpty) continue;
      lines.add('${entry.key} : ${names.join(', ')}');
    }
    if (lines.length <= 2) return '';

    return section(s, 'section_exercises', lines.join('\n'));
  }
}
