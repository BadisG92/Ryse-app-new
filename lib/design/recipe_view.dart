import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/translations.dart';
import 'tokens.dart';
import 'type.dart';

/// Une recette telle que Ryze l'écrit.
///
/// Le modèle rend une seule chaîne : la description, puis les ingrédients, la
/// préparation et une astuce, séparés par `---` et introduits par le nom de
/// leur section. Un seul écran savait la découper, et il exigeait des
/// intitulés exacts en majuscules suivis d'un deux-points collé. Le modèle
/// écrit « Ingrédients : » avec l'espace de la typographie française, et
/// « Conseil » aussi souvent qu'« Astuce ». Rien ne correspondait, donc tout
/// retombait dans un bloc unique — et les deux autres écrans, eux, affichaient
/// la chaîne brute avec ses tirets.
class RecipeText {
  const RecipeText({
    this.summary = '',
    this.ingredients = '',
    this.steps = '',
    this.tip = '',
  });

  /// La phrase qui présente le plat.
  final String summary;

  /// Ce qu'il faut, une ligne par ingrédient.
  final String ingredients;

  /// Comment le faire.
  final String steps;

  /// Le conseil du coach, quand il y en a un.
  final String tip;

  bool get hasSections => ingredients.isNotEmpty || steps.isNotEmpty || tip.isNotEmpty;
  bool get isEmpty => summary.isEmpty && !hasSections;

  /// Les mots qui ouvrent une section, dans les trois langues et dans les
  /// formes que le modèle emploie réellement.
  static const _ingredients = ['ingrédients', 'ingredients', 'zutaten'];
  static const _steps = ['recette', 'préparation', 'preparation', 'recipe', 'steps', 'method', 'instructions', 'étapes', 'etapes', 'zubereitung', 'rezept', 'anleitung'];
  static const _tip = ['astuce', 'conseil', 'tip', 'tips', 'tipp', 'hinweis'];

  /// Le nom de section en tête d'un morceau, s'il y en a un.
  ///
  /// Tolère la casse, l'accent, l'espace avant le deux-points, un tiret ou un
  /// point à la place, et le gras Markdown autour.
  static String? _headOf(String part) {
    final first = part.split('\n').first.trim().replaceAll('*', '');
    final marque = RegExp(r'^([^:：\-–—.]{0,20})\s*[:：\-–—.]').firstMatch(first);
    if (marque == null) return null;
    return marque.group(1)!.trim().toLowerCase();
  }

  static String _bodyOf(String part) {
    final lines = part.trim().split('\n');
    final first = lines.first.replaceAll('*', '');
    final coupe = RegExp(r'^[^:：\-–—.]{0,20}\s*[:：\-–—.]\s*').firstMatch(first);
    if (coupe == null) return part.trim();

    final reste = first.substring(coupe.end).trim();
    final suite = lines.skip(1).join('\n').trim();
    return [if (reste.isNotEmpty) reste, if (suite.isNotEmpty) suite].join('\n').trim();
  }

  /// Lit ce que le modèle a écrit.
  static RecipeText parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const RecipeText();

    final parts = text.split('---').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return const RecipeText();

    var summary = '';
    var ingredients = '';
    var steps = '';
    var tip = '';

    for (final part in parts) {
      final head = _headOf(part);
      final body = _bodyOf(part);

      if (head != null && _ingredients.any(head.contains)) {
        ingredients = body;
      } else if (head != null && _steps.any(head.contains)) {
        steps = body;
      } else if (head != null && _tip.any(head.contains)) {
        tip = body;
      } else if (summary.isEmpty) {
        // Le premier morceau sans intitulé présente le plat.
        summary = part;
      } else {
        // Un morceau de plus, sans nom : il rejoint la présentation plutôt
        // que d'être perdu.
        summary = '$summary\n\n$part';
      }
    }

    return RecipeText(summary: summary, ingredients: ingredients, steps: steps, tip: tip);
  }
}

/// La recette à l'écran, la même partout.
class RecipeView extends StatelessWidget {
  const RecipeView({super.key, required this.lang, required this.recipe});

  final String lang;
  final RecipeText recipe;

  @override
  Widget build(BuildContext context) {
    if (recipe.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.summary.isNotEmpty)
          Text(recipe.summary, style: RyzeText.body(context, 3.6, height: 1.5)),
        if (recipe.ingredients.isNotEmpty)
          _Section(
            icon: LucideIcons.shoppingBasket,
            title: 'recipe_ingredients'.tr(lang),
            body: recipe.ingredients,
          ),
        if (recipe.steps.isNotEmpty)
          _Section(
            icon: LucideIcons.chefHat,
            title: 'recipe_steps'.tr(lang),
            body: recipe.steps,
          ),
        if (recipe.tip.isNotEmpty)
          _Section(
            icon: LucideIcons.lightbulb,
            title: 'recipe_tip'.tr(lang),
            body: recipe.tip,
            quiet: true,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    this.quiet = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// L'astuce se pose sur un fond, elle n'est pas de la même nature que la
  /// liste des courses.
  final bool quiet;

  /// Une ligne d'ingrédient ou d'étape, quel que soit le tiret employé.
  static final _bullet = RegExp(r'^\s*(?:[-*•·]|\d+[.)])\s+');

  @override
  Widget build(BuildContext context) {
    final lignes = body
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final enListe = lignes.length > 1 && lignes.every((l) => _bullet.hasMatch(l));

    return Padding(
      padding: EdgeInsets.only(top: context.vw(4.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.vw(4.1), color: RyzeColors.mute),
              SizedBox(width: context.vw(2.1)),
              Text(
                title.toUpperCase(),
                style: RyzeText.body(context, 3.0, weight: FontWeight.w700, color: RyzeColors.mute)
                    .copyWith(letterSpacing: 0.6),
              ),
            ],
          ),
          SizedBox(height: context.vw(1.8)),
          Container(
            width: double.infinity,
            padding: quiet ? EdgeInsets.all(context.vw(3.1)) : EdgeInsets.zero,
            decoration: quiet
                ? BoxDecoration(
                    color: RyzeColors.paper2,
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  )
                : null,
            child: enListe
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final l in lignes)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.vw(1.2)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: RyzeText.body(context, 3.5, color: RyzeColors.mute2)),
                              Expanded(
                                child: Text(
                                  l.replaceFirst(_bullet, ''),
                                  style: RyzeText.body(context, 3.5, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : Text(body.trim(), style: RyzeText.body(context, 3.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
