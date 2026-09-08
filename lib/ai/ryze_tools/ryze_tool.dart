import 'package:flutter/foundation.dart';

import '../ryze_persona.dart';

/// Ce qu'un outil rend une fois qu'il a agi.
class RyzeToolResult {
  const RyzeToolResult({
    required this.ok,
    required this.summary,
    this.data = const {},
    this.undo,
    this.payload,
  });

  /// L'action a-t-elle abouti ?
  final bool ok;

  /// Une phrase courte, dans la langue de l'utilisateur, pour la transcription.
  final String summary;

  /// Ce qui repart au modèle. Il doit pouvoir constater l'effet, pas le
  /// deviner : c'est cette réponse qui l'autorise à dire que c'est fait.
  final Map<String, dynamic> data;

  /// De quoi défaire, quand l'action se défait proprement.
  final Future<void> Function()? undo;

  /// Un objet pour la surface, que le modèle ne voit jamais.
  ///
  /// Une création ne rend pas un fait accompli mais une proposition — un repas
  /// avec ses macros, une séance avec ses exercices. Chaque surface la montre à
  /// sa façon : la conversation en fait une carte, l'écran du planificateur en
  /// remplit ses pages par jour. C'est ce qui permet aux deux de partager le
  /// même outil sans partager leur mise en scène.
  final Object? payload;

  factory RyzeToolResult.failed(String summary) =>
      RyzeToolResult(ok: false, summary: summary, data: {'error': summary});

  Map<String, dynamic> toResponse() => {'ok': ok, 'summary': summary, ...data};
}

/// Une action proposée, en attente du oui de l'utilisateur.
///
/// Elle n'est pas encore faite : le modèle reçoit « en attente de validation »
/// et non un succès, pour qu'il n'annonce pas ce qui n'a pas eu lieu.
class RyzePending {
  const RyzePending({
    required this.id,
    required this.toolName,
    required this.title,
    this.detail,
    required this.commit,
  });

  final String id;
  final String toolName;

  /// Ce que la carte annonce.
  final String title;

  /// Le détail sous le titre, quand il y en a un.
  final String? detail;

  /// Ce qui se produit si l'utilisateur valide.
  final Future<RyzeToolResult> Function() commit;
}

/// Un outil que Ryze peut appeler.
class RyzeTool {
  const RyzeTool({
    required this.name,
    required this.declaration,
    required this.execute,
    this.needsConfirmation = _never,
    this.preview,
    this.surfaces = const {RyzeSurface.coach},
  });

  /// Le nom vu par le modèle. Préfixé par domaine : `journal.`, `plan.`,
  /// `sport.`, `nav.`, `memory.`.
  final String name;

  /// Le schéma envoyé au modèle.
  final Map<String, dynamic> declaration;

  /// Ce que fait l'outil.
  final Future<RyzeToolResult> Function(Map<String, dynamic> args) execute;

  /// Faut-il demander avant ?
  ///
  /// Oui pour ce qui se défait mal : un poids enregistré, un repas marqué
  /// mangé. Non pour ce qui se défait d'un geste, comme un verre d'eau, qui
  /// reçoit une barre d'annulation à la place.
  final bool Function(Map<String, dynamic> args) needsConfirmation;

  /// Ce que la carte de validation annonce, quand il en faut une.
  final Future<RyzePending> Function(Map<String, dynamic> args)? preview;

  /// Sur quelles surfaces cet outil est proposé.
  final Set<RyzeSurface> surfaces;

  static bool _never(Map<String, dynamic> _) => false;
}

/// Les outils dont Ryze dispose, selon la surface.
class RyzeToolRegistry {
  RyzeToolRegistry(this._tools);

  final List<RyzeTool> _tools;

  /// Les outils proposés sur cette surface.
  List<RyzeTool> forSurface(RyzeSurface surface) =>
      _tools.where((t) => t.surfaces.contains(surface)).toList();

  /// Les déclarations à envoyer au modèle.
  List<Map<String, dynamic>> declarationsFor(RyzeSurface surface) =>
      forSurface(surface).map((t) => t.declaration).toList();

  RyzeTool? byName(String name) {
    for (final t in _tools) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Tous les outils, quelle que soit la surface.
  List<RyzeTool> get all => List.unmodifiable(_tools);

  /// Vérifie que le registre tient debout : des noms uniques, des schémas
  /// exploitables. Rend la liste des reproches, vide quand tout va bien.
  @visibleForTesting
  List<String> validate() {
    final problems = <String>[];
    final seen = <String>{};

    for (final t in _tools) {
      if (!seen.add(t.name)) problems.add('nom en double : ${t.name}');

      // Gemini n'accepte que ces caractères, et pas au-delà de 63.
      if (!RegExp(r'^[a-zA-Z0-9_.-]{1,63}$').hasMatch(t.name)) {
        problems.add('nom invalide : ${t.name}');
      }
      if (t.declaration['name'] != t.name) {
        problems.add('${t.name} : le schéma annonce ${t.declaration['name']}');
      }

      final desc = t.declaration['description'];
      if (desc is! String || desc.trim().isEmpty) {
        problems.add('${t.name} : sans description');
      }

      final params = t.declaration['parameters'];
      if (params is! Map) {
        problems.add('${t.name} : sans paramètres');
      } else if (params['type'] != 'object') {
        problems.add('${t.name} : paramètres non typés');
      }

      // Un outil qui demande confirmation doit savoir dire quoi.
      if (t.needsConfirmation(const {}) && t.preview == null) {
        problems.add('${t.name} : demande confirmation sans carte');
      }
      if (t.surfaces.isEmpty) problems.add('${t.name} : sur aucune surface');
    }
    return problems;
  }
}

/// Raccourci pour écrire un schéma sans répéter la même structure.
Map<String, dynamic> toolSchema({
  required String name,
  required String description,
  Map<String, dynamic> properties = const {},
  List<String> required = const [],
}) =>
    {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': properties,
        'required': required,
      },
    };
