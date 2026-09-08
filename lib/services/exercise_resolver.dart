import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sport_models.dart';
import 'localization_service.dart';

/// À quel exercice réel correspond un nom écrit librement.
///
/// Ryze peut proposer n'importe quel exercice, y compris un que le catalogue
/// ne connaît pas. Sans point de passage unique, chaque orthographe créait sa
/// propre ligne : « Développé couché », « developpe-couche » et
/// « Bankdrücken » devenaient trois exercices, et le détail de l'exercice
/// n'affichait qu'un tiers des séances à chaque fois.
///
/// Tout ce qui nomme un exercice passe donc par ici, et en ressort avec une
/// ligne réelle : celle du catalogue quand elle existe, sinon un exercice
/// personnalisé, créé une seule fois quelle que soit la façon de l'écrire.
///
/// La garantie ne repose pas sur ce fichier seul : `custom_exercises` porte un
/// index unique sur (utilisateur, nom normalisé), et [normalize] est le miroir
/// exact de la fonction SQL `ryze_normalize_exercise`. Si les deux venaient à
/// diverger, l'insertion échouerait au lieu de créer un doublon.
class ExerciseResolver {
  ExerciseResolver._();

  static final _client = Supabase.instance.client;

  /// Le catalogue avec ses trois langues, pour reconnaître un exercice quelle
  /// que soit la langue dans laquelle il a été nommé.
  static List<_CatalogueEntry>? _catalogue;
  static DateTime? _catalogueAt;
  static const _catalogueTtl = Duration(hours: 1);

  /// Deux noms se ressemblent assez pour être le même exercice à partir d'ici.
  /// Volontairement haut : un faux positif fusionne deux exercices distincts,
  /// ce qui est plus coûteux qu'un doublon.
  static const double _similarityThreshold = 0.8;

  // ---------------------------------------------------------------- normalisation

  /// La forme comparable d'un nom d'exercice.
  ///
  /// Minuscules, ß déplié, accents retirés, tout ce qui n'est ni lettre ni
  /// chiffre remplacé par une espace, espaces resserrés.
  ///
  /// **Miroir exact de `public.ryze_normalize_exercise(text)`.** Toute
  /// modification ici doit être portée dans la migration correspondante, sinon
  /// l'index unique de la base ne protège plus ce que ce code croit protéger.
  static String normalize(String value) {
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const plain = 'aaaaaaceeeeiiiinooooouuuuyyoa';

    final lower = value.toLowerCase().replaceAll('ß', 'ss');
    final buffer = StringBuffer();
    var pendingSpace = false;

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      final mapped = index >= 0 ? plain[index] : char;

      final isWord = (mapped.codeUnitAt(0) >= 0x61 && mapped.codeUnitAt(0) <= 0x7A) ||
          (mapped.codeUnitAt(0) >= 0x30 && mapped.codeUnitAt(0) <= 0x39);

      if (isWord) {
        if (pendingSpace && buffer.isNotEmpty) buffer.write(' ');
        pendingSpace = false;
        buffer.write(mapped);
      } else {
        pendingSpace = true;
      }
    }

    return buffer.toString();
  }

  /// Le rapprochement entre deux noms, sur leurs mots.
  ///
  /// Sert de rattrapage quand l'égalité stricte échoue : un mot en trop, un
  /// ordre différent. Elle ne rattrape pas une faute de frappe à l'intérieur
  /// d'un mot, et c'est voulu — mieux vaut créer l'exercice que de le confondre
  /// avec un autre.
  static double similarity(String a, String b) {
    final left = normalize(a).split(' ').where((t) => t.isNotEmpty).toSet();
    final right = normalize(b).split(' ').where((t) => t.isNotEmpty).toSet();
    if (left.isEmpty || right.isEmpty) return 0;
    final union = left.union(right).length;
    if (union == 0) return 0;
    return left.intersection(right).length / union;
  }

  // ---------------------------------------------------------------- résolution

  /// L'exercice réel derrière un nom écrit librement.
  ///
  /// [canonicalEnglishName] est le nom anglais que le modèle donne en plus du
  /// nom localisé. Il fait s'effondrer les variantes entre langues sans coûter
  /// une recherche de plus : « développé couché » et « Bankdrücken » portent
  /// tous les deux « bench press ».
  ///
  /// Rend `null` seulement si le nom est vide ou si l'utilisateur n'est pas
  /// connecté ; dans tous les autres cas il y a un exercice au bout.
  static Future<Exercise?> resolve({
    required String name,
    String? canonicalEnglishName,
    String? muscleGroup,
    String? equipment,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final candidates = <String>[
      trimmed,
      if (canonicalEnglishName != null && canonicalEnglishName.trim().isNotEmpty)
        canonicalEnglishName.trim(),
    ];

    // 1. Le catalogue, sur les trois langues et sur le nom canonique.
    final catalogue = await _loadCatalogue();
    for (final candidate in candidates) {
      final hit = _matchCatalogue(catalogue, candidate, muscleGroup);
      if (hit != null) return hit;
    }

    // 2. Les exercices que cet utilisateur possède déjà.
    final own = await _loadOwnExercises();
    for (final candidate in candidates) {
      final key = normalize(candidate);
      for (final entry in own) {
        if (normalize(entry.name) == key) return entry;
      }
    }

    // 3. Le rattrapage par ressemblance, catalogue puis exercices propres.
    final loose = _matchLoosely(catalogue, own, candidates, muscleGroup);
    if (loose != null) return loose;

    // 4. Rien ne correspond : l'exercice devient une ligne à lui.
    return _createOwnExercise(
      name: trimmed,
      muscleGroup: muscleGroup,
      equipment: equipment,
      description: description,
    );
  }

  /// Rapproche un nom du catalogue, en tranchant les ex æquo.
  ///
  /// Le catalogue porte quelques exercices en double, le même mouvement classé
  /// sous deux muscles. Quand le modèle a dit quel muscle il visait, on suit ce
  /// qu'il a dit ; sinon on prend toujours le même, pour que deux appels
  /// identiques rendent le même exercice.
  static Exercise? _matchCatalogue(
    List<_CatalogueEntry> catalogue,
    String candidate,
    String? muscleGroup,
  ) {
    final key = normalize(candidate);
    if (key.isEmpty) return null;

    final hits = catalogue.where((e) => e.keys.contains(key)).toList();
    if (hits.isEmpty) return null;
    return _pickBest(hits, muscleGroup).toExercise();
  }

  static Exercise? _matchLoosely(
    List<_CatalogueEntry> catalogue,
    List<Exercise> own,
    List<String> candidates,
    String? muscleGroup,
  ) {
    _CatalogueEntry? bestEntry;
    Exercise? bestOwn;
    var bestScore = _similarityThreshold;

    for (final candidate in candidates) {
      for (final entry in catalogue) {
        for (final other in entry.names) {
          final score = similarity(candidate, other);
          if (score > bestScore) {
            bestScore = score;
            bestEntry = entry;
            bestOwn = null;
          }
        }
      }
      for (final entry in own) {
        final score = similarity(candidate, entry.name);
        if (score > bestScore) {
          bestScore = score;
          bestOwn = entry;
          bestEntry = null;
        }
      }
    }

    if (bestOwn != null) return bestOwn;
    if (bestEntry != null) {
      if (kDebugMode) {
        debugPrint('🔗 ExerciseResolver: "${candidates.first}" rapproché de "${bestEntry.localizedName}" (${bestScore.toStringAsFixed(2)})');
      }
      return bestEntry.toExercise();
    }
    return null;
  }

  static _CatalogueEntry _pickBest(List<_CatalogueEntry> hits, String? muscleGroup) {
    if (hits.length == 1) return hits.first;
    if (muscleGroup != null && muscleGroup.trim().isNotEmpty) {
      final wanted = normalize(muscleGroup);
      for (final hit in hits) {
        if (hit.groupKeys.contains(wanted)) return hit;
      }
    }
    final sorted = [...hits]..sort((a, b) => a.id.compareTo(b.id));
    return sorted.first;
  }

  // ---------------------------------------------------------------- création

  /// Crée l'exercice pour cet utilisateur, ou rend celui qui existait déjà.
  ///
  /// L'index unique de la base est la vraie protection : si deux appels
  /// concurrents demandent le même nom, le second reçoit une violation
  /// d'unicité et relit la ligne au lieu d'en créer une seconde.
  static Future<Exercise?> _createOwnExercise({
    required String name,
    String? muscleGroup,
    String? equipment,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final lang = LocalizationService.instance.currentLanguageCode;
    final group = (muscleGroup ?? '').trim();

    try {
      final row = await _client
          .from('custom_exercises')
          .insert({
            'user_id': userId,
            'name': name,
            // Le groupe musculaire n'était jamais écrit : les exercices
            // personnalisés sortaient donc du classement par muscle.
            'muscle_group': group.isEmpty ? null : group,
            'muscle_group_fr': group.isEmpty ? 'Personnalisé' : group,
            'muscle_group_en': group.isEmpty ? 'Custom' : group,
            'muscle_group_de': group.isEmpty ? 'Eigene' : group,
            'equipment': (equipment ?? '').trim(),
            'description': (description ?? '').trim(),
            'visible_list': true,
          })
          .select('id, name, muscle_group, muscle_group_$lang, equipment, description')
          .single();

      _ownExercises = null; // le prochain appel relira la liste
      return _ownFromRow(row, lang);
    } on PostgrestException catch (e) {
      // 23505 : l'exercice existe déjà sous une autre orthographe.
      if (e.code == '23505') {
        final existing = await _client
            .from('custom_exercises')
            .select('id, name, muscle_group, muscle_group_$lang, equipment, description')
            .eq('user_id', userId)
            .eq('normalized_name', normalize(name))
            .maybeSingle();
        if (existing != null) return _ownFromRow(existing, lang);
      }
      if (kDebugMode) debugPrint('❌ ExerciseResolver: création refusée ($name) : ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ExerciseResolver: création impossible ($name) : $e');
      return null;
    }
  }

  // ---------------------------------------------------------------- lectures

  static Future<List<_CatalogueEntry>> _loadCatalogue() async {
    final fresh = _catalogueAt != null &&
        DateTime.now().difference(_catalogueAt!) < _catalogueTtl;
    if (_catalogue != null && fresh) return _catalogue!;

    try {
      final rows = await _client
          .from('exercises')
          .select('id, name_fr, name_en, name_de, muscle_group, muscle_group_fr, muscle_group_en, muscle_group_de, equipment, description');

      final lang = LocalizationService.instance.currentLanguageCode;
      _catalogue = (rows as List)
          .map((r) => _CatalogueEntry.fromRow(r as Map<String, dynamic>, lang))
          .toList();
      _catalogueAt = DateTime.now();
      return _catalogue!;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ExerciseResolver: catalogue indisponible : $e');
      return _catalogue ?? const [];
    }
  }

  static List<Exercise>? _ownExercises;
  static DateTime? _ownAt;

  static Future<List<Exercise>> _loadOwnExercises() async {
    final fresh = _ownAt != null && DateTime.now().difference(_ownAt!) < _catalogueTtl;
    if (_ownExercises != null && fresh) return _ownExercises!;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    try {
      final lang = LocalizationService.instance.currentLanguageCode;
      final rows = await _client
          .from('custom_exercises')
          .select('id, name, muscle_group, muscle_group_$lang, equipment, description')
          .eq('user_id', userId);

      _ownExercises = (rows as List)
          .map((r) => _ownFromRow(r as Map<String, dynamic>, lang))
          .toList();
      _ownAt = DateTime.now();
      return _ownExercises!;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ExerciseResolver: exercices personnels indisponibles : $e');
      return _ownExercises ?? const [];
    }
  }

  static Exercise _ownFromRow(Map<String, dynamic> row, String lang) {
    final group = (row['muscle_group_$lang'] as String?)?.trim();
    return Exercise(
      id: row['id'] as String,
      name: (row['name'] as String?)?.trim() ?? '',
      muscleGroup: (group != null && group.isNotEmpty)
          ? group
          : ((row['muscle_group'] as String?)?.trim() ?? ''),
      equipment: (row['equipment'] as String?)?.trim() ?? '',
      description: (row['description'] as String?)?.trim() ?? '',
      isCustom: true,
    );
  }

  /// Toutes les formes sous lesquelles cet exercice a pu être écrit.
  ///
  /// Sert à relire l'historique : le détail d'un exercice doit rassembler les
  /// séances enregistrées sous une autre orthographe, ou dans une autre langue
  /// avant que l'utilisateur ne change la sienne. La colonne normalisée de
  /// l'historique se compare directement à cette liste.
  ///
  /// Rend au minimum la forme normalisée du nom demandé, donc jamais vide pour
  /// un nom non vide.
  static Future<List<String>> aliasesFor(String name) async {
    final key = normalize(name);
    if (key.isEmpty) return const [];

    final aliases = <String>{key};

    final catalogue = await _loadCatalogue();
    for (final entry in catalogue) {
      if (entry.keys.contains(key)) aliases.addAll(entry.keys);
    }

    final own = await _loadOwnExercises();
    for (final entry in own) {
      if (normalize(entry.name) == key) aliases.add(normalize(entry.name));
    }

    return aliases.toList();
  }

  /// Après une déconnexion, ou quand la langue change.
  static void clearCache() {
    _catalogue = null;
    _catalogueAt = null;
    _ownExercises = null;
    _ownAt = null;
  }
}

/// Une ligne du catalogue, avec ses noms dans les trois langues.
class _CatalogueEntry {
  _CatalogueEntry({
    required this.id,
    required this.names,
    required this.localizedName,
    required this.muscleGroup,
    required this.groupKeys,
    required this.equipment,
    required this.description,
  }) : keys = names.map(ExerciseResolver.normalize).where((k) => k.isNotEmpty).toSet();

  final String id;

  /// Les noms connus, toutes langues confondues.
  final List<String> names;
  final Set<String> keys;
  final String localizedName;
  final String muscleGroup;
  final Set<String> groupKeys;
  final String equipment;
  final String description;

  factory _CatalogueEntry.fromRow(Map<String, dynamic> row, String lang) {
    String text(String key) => (row[key] as String?)?.trim() ?? '';

    final fr = text('name_fr');
    final en = text('name_en');
    final de = text('name_de');
    final localized = switch (lang) {
      'en' => en.isNotEmpty ? en : fr,
      'de' => de.isNotEmpty ? de : (en.isNotEmpty ? en : fr),
      _ => fr.isNotEmpty ? fr : en,
    };

    final groups = [
      text('muscle_group'),
      text('muscle_group_fr'),
      text('muscle_group_en'),
      text('muscle_group_de'),
    ].where((g) => g.isNotEmpty);

    final localizedGroup = text('muscle_group_$lang');

    return _CatalogueEntry(
      id: row['id'] as String,
      names: [fr, en, de].where((n) => n.isNotEmpty).toList(),
      localizedName: localized,
      muscleGroup: localizedGroup.isNotEmpty ? localizedGroup : text('muscle_group'),
      groupKeys: groups.map(ExerciseResolver.normalize).toSet(),
      equipment: text('equipment'),
      description: text('description'),
    );
  }

  Exercise toExercise() => Exercise(
        id: id,
        name: localizedName,
        muscleGroup: muscleGroup,
        equipment: equipment,
        description: description,
      );
}
