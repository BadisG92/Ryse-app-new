import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coach_chat_models.dart';
import '../services/coach_preference_extractor.dart';
import 'prompts/persona_strings.dart';

/// Les tiroirs de la mémoire de Ryze.
enum MemoryCategory {
  allergy('allergies'),
  dietaryRestriction('dietary_restrictions'),
  foodPreference('food_preferences'),
  fitnessConstraint('fitness_constraints'),
  workoutTime('preferred_workout_times'),
  note('custom_notes');

  const MemoryCategory(this.jsonKey);

  /// La clé de ce tiroir dans le document `preferences`.
  final String jsonKey;

  static MemoryCategory? fromKey(String key) {
    for (final c in MemoryCategory.values) {
      if (c.jsonKey == key || c.name == key) return c;
    }
    return null;
  }
}

/// Un fait retenu, et son tiroir.
class MemoryItem {
  const MemoryItem(this.category, this.text);

  final MemoryCategory category;
  final String text;

  /// La forme sur laquelle deux faits se comparent.
  String get key => CoachPreferenceExtractor.normalizeFact(text);

  @override
  String toString() => text;
}

/// Ce que Ryze retient de l'utilisateur.
///
/// Une seule porte d'écriture. La colonne `preferences` porte aussi ce que
/// l'onboarding y a mis, et deux fonctions la reconstruisaient de zéro à
/// partir des six listes qu'elles connaissaient : la première extraction
/// effaçait définitivement ce que l'utilisateur avait raconté à l'inscription.
/// Tout passe désormais par [save], qui relit, fusionne, et garde les clés
/// qu'il ne connaît pas.
///
/// L'extraction automatique change aussi de rythme. Elle tournait **après
/// chaque réponse**, sur **toute** la conversation, et se terminait par une
/// reconstruction de la session qui coupait le fil en pleine discussion. Elle
/// tourne maintenant au plus une fois par jour de conversation, sur les seuls
/// messages nouveaux, et ne touche jamais la session en cours.
class RyzeMemory {
  RyzeMemory._();

  static final RyzeMemory instance = RyzeMemory._();

  /// Paresseux : construire le service ne doit pas exiger que Supabase soit
  /// démarré, sinon les fonctions pures ci-dessous deviennent intestables.
  SupabaseClient get _client => Supabase.instance.client;

  UserCoachPreferences? _cached;

  /// Au-delà, un tiroir oublie ses plus vieux faits.
  ///
  /// Sans plafond, la fusion en union de sets ne perdait jamais rien : la
  /// mémoire enflait à chaque extraction et finissait par occuper le prompt.
  static const int maxPerCategory = 15;

  /// Et tous tiroirs confondus.
  static const int maxTotal = 60;

  // -------------------------------------------------------------- lecture

  Future<UserCoachPreferences?> load({bool force = false}) async {
    if (_cached != null && !force) return _cached;

    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('user_coach_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return null;
      _cached = UserCoachPreferences.fromJson(row);
      return _cached;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeMemory: lecture impossible : $e');
      return _cached;
    }
  }

  /// Les faits retenus, tiroir par tiroir, dans l'ordre où ils comptent.
  ///
  /// Les contraintes physiques et les allergies passent devant : ce sont
  /// celles qui changent ce que Ryze a le droit de proposer.
  static List<MemoryItem> itemsOf(UserCoachPreferences? prefs) {
    if (prefs == null) return const [];
    final out = <MemoryItem>[];
    void add(MemoryCategory c, List<String> values) {
      for (final v in values) {
        final text = v.trim();
        if (text.isNotEmpty) out.add(MemoryItem(c, text));
      }
    }

    add(MemoryCategory.allergy, prefs.allergies);
    add(MemoryCategory.fitnessConstraint, prefs.fitnessConstraints);
    add(MemoryCategory.dietaryRestriction, prefs.dietaryRestrictions);
    add(MemoryCategory.foodPreference, prefs.foodPreferences);
    add(MemoryCategory.workoutTime, prefs.preferredWorkoutTimes);
    add(MemoryCategory.note, prefs.customNotes);
    return out;
  }

  /// Les lignes prêtes pour le bloc de contexte, dans la langue voulue.
  static List<String> promptLines(UserCoachPreferences? prefs, PersonaStrings s) {
    final lines = <String>[];

    // Ce que l'onboarding a recueilli garde sa place en tête : c'est le
    // pourquoi de l'utilisateur, pas un détail alimentaire.
    final insights = prefs?.onboardingInsights?.trim();
    if (insights != null && insights.isNotEmpty) {
      lines.addAll(insights.split('\n').map((l) => l.replaceFirst(RegExp(r'^[-•]\s*'), '').trim()).where((l) => l.isNotEmpty));
    }

    for (final item in itemsOf(prefs)) {
      lines.add('${_categoryLabel(item.category, s)} : ${item.text}');
    }
    return lines;
  }

  static String _categoryLabel(MemoryCategory c, PersonaStrings s) => switch (s.lang) {
        'fr' => switch (c) {
            MemoryCategory.allergy => 'Allergie',
            MemoryCategory.fitnessConstraint => 'Contrainte physique',
            MemoryCategory.dietaryRestriction => 'Régime',
            MemoryCategory.foodPreference => 'Goût',
            MemoryCategory.workoutTime => 'Horaire',
            MemoryCategory.note => 'Note',
          },
        'de' => switch (c) {
            MemoryCategory.allergy => 'Allergie',
            MemoryCategory.fitnessConstraint => 'Körperliche Einschränkung',
            MemoryCategory.dietaryRestriction => 'Ernährungsweise',
            MemoryCategory.foodPreference => 'Vorliebe',
            MemoryCategory.workoutTime => 'Trainingszeit',
            MemoryCategory.note => 'Notiz',
          },
        _ => switch (c) {
            MemoryCategory.allergy => 'Allergy',
            MemoryCategory.fitnessConstraint => 'Physical constraint',
            MemoryCategory.dietaryRestriction => 'Diet',
            MemoryCategory.foodPreference => 'Preference',
            MemoryCategory.workoutTime => 'Training time',
            MemoryCategory.note => 'Note',
          },
      };

  // -------------------------------------------------------------- écriture

  /// Retenir un fait. Rend faux si rien n'a changé.
  Future<bool> remember(MemoryCategory category, String fact) async {
    final text = fact.trim();
    if (text.isEmpty) return false;

    final prefs = await load();
    final current = _listOf(prefs, category);

    // Le dédoublonnage passe par la même normalisation que les exercices :
    // « sans gluten » et « Sans gluten, » sont le même fait.
    final merged = CoachPreferenceExtractor.mergeList(current, [text]);
    if (merged.length == current.length) return false;

    return save({category.jsonKey: capped(merged)});
  }

  /// Oublier un fait. Rend faux s'il n'était pas là.
  Future<bool> forget(MemoryCategory category, String fact) async {
    final prefs = await load();
    final current = _listOf(prefs, category);
    final key = CoachPreferenceExtractor.normalizeFact(fact);

    final kept = current
        .where((v) => CoachPreferenceExtractor.normalizeFact(v) != key)
        .toList();
    if (kept.length == current.length) return false;

    return save({category.jsonKey: kept});
  }

  /// Écrit dans `preferences` sans jamais perdre ce qu'on n'a pas relu.
  ///
  /// C'est la seule écriture de cette colonne.
  Future<bool> save(Map<String, dynamic> patch) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final existing = await _client
          .from('user_coach_preferences')
          .select('preferences')
          .eq('user_id', user.id)
          .maybeSingle();

      final merged = UserCoachPreferences.mergePreferencesJson(
        existing?['preferences'] as Map<String, dynamic>?,
        patch,
      );

      await _client.from('user_coach_preferences').upsert(
        {
          'user_id': user.id,
          'preferences': merged,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      _cached = null;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeMemory: écriture impossible : $e');
      return false;
    }
  }

  /// Garde les plus récents quand un tiroir déborde.
  static List<String> capped(List<String> values) =>
      values.length <= maxPerCategory
          ? values
          : values.sublist(values.length - maxPerCategory);

  static List<String> _listOf(UserCoachPreferences? p, MemoryCategory c) => switch (c) {
        MemoryCategory.allergy => p?.allergies ?? const [],
        MemoryCategory.dietaryRestriction => p?.dietaryRestrictions ?? const [],
        MemoryCategory.foodPreference => p?.foodPreferences ?? const [],
        MemoryCategory.fitnessConstraint => p?.fitnessConstraints ?? const [],
        MemoryCategory.workoutTime => p?.preferredWorkoutTimes ?? const [],
        MemoryCategory.note => p?.customNotes ?? const [],
      };

  // ------------------------------------------------------------ extraction

  /// L'extraction est-elle due ?
  ///
  /// Au plus une fois par jour de conversation, et seulement si assez de
  /// messages nouveaux sont arrivés depuis la dernière. Elle tournait après
  /// **chaque** réponse, sur toute la conversation.
  static bool isDue({
    required DateTime? lastExtractionAt,
    required int newMessagesSince,
    DateTime? now,
  }) {
    if (newMessagesSince < 4) return false;
    if (lastExtractionAt == null) return true;

    final today = now ?? DateTime.now();
    final last = lastExtractionAt;
    final sameDay = last.year == today.year && last.month == today.month && last.day == today.day;
    return !sameDay;
  }

  /// Les messages arrivés depuis la dernière extraction.
  static List<CoachMessage> since(List<CoachMessage> all, DateTime? lastExtractionAt) {
    if (lastExtractionAt == null) return all;
    return all.where((m) => m.createdAt.isAfter(lastExtractionAt)).toList();
  }

  /// Lance l'extraction si elle est due, en arrière-plan.
  ///
  /// Ne touche jamais la conversation en cours : le bloc mémoire sera relu au
  /// prochain envoi. L'ancien code reconstruisait la session Gemini ici même,
  /// ce qui coupait le fil en pleine discussion.
  Future<bool> extractIfDue(List<CoachMessage> allMessages) async {
    final prefs = await load();
    final nouveaux = since(allMessages, prefs?.lastExtractionAt);

    if (!isDue(
      lastExtractionAt: prefs?.lastExtractionAt,
      newMessagesSince: nouveaux.length,
    )) {
      return false;
    }

    try {
      final extracted = await CoachPreferenceExtractor.instance
          .extractFromMessages(nouveaux, prefs);
      if (extracted == null) return false;

      final patch = <String, dynamic>{
        for (final c in MemoryCategory.values) c.jsonKey: capped(_listOf(extracted, c)),
      };
      final ok = await save(patch);

      if (ok) {
        await _client
            .from('user_coach_preferences')
            .update({'last_extraction_at': DateTime.now().toIso8601String()})
            .eq('user_id', _client.auth.currentUser!.id);
        _cached = null;
      }
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeMemory: extraction impossible : $e');
      return false;
    }
  }

  void clearCache() => _cached = null;
}
