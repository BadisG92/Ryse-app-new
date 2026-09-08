import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// L'eau du jour sur l'accueil : les mêmes verres que dans le journal.
///
/// C'était une carte pleine largeur dont un gris montait par le bas. Deux
/// choses n'allaient pas. Le gris, d'abord : il ne dit pas l'eau, il dit une
/// jauge, et une jauge grise sur une carte blanche fait une tache. La carte
/// ensuite : l'application a déjà une façon de montrer l'eau — des verres
/// qu'on remplit — et en inventer une seconde pour la même chose oblige à
/// apprendre deux fois.
///
/// Ce sont donc les verres, à l'identique, avec la même ligne de compte
/// au-dessus. Un tap remplit ou vide, un appui long demande une autre
/// quantité — les gestes du journal, appris une fois.
class WaterTile extends StatelessWidget {
  const WaterTile({
    super.key,
    required this.lang,
    required this.litres,
    required this.goal,
    required this.shown,
    required this.onSet,
    required this.onMore,
  });

  final String lang;
  final double litres;
  final double goal;

  /// Faux jusqu'à l'entrée de la page : les verres se remplissent alors un
  /// par un, avec le décalage que porte déjà `GlassRow`.
  final bool shown;

  /// Le nombre de verres visé. Monter en ajoute un, descendre en retire un.
  final ValueChanged<int> onSet;

  /// Une autre quantité qu'un verre.
  final VoidCallback onMore;

  static String _litres(double v, String lang) {
    final n = NumberFormat.decimalPattern(lang)..maximumFractionDigits = 2;
    return n.format(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('nutri_water'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
            Text(
              '${_litres(litres, lang)} ${'nutri_water_of'.tr(lang).replaceAll('{n}', _litres(goal, lang))}',
              style: RyzeText.body(context, 3.4, weight: FontWeight.w600)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        SizedBox(height: context.vw(2.6)),
        GlassRow(
          litres: litres,
          goalLitres: goal,
          shown: shown,
          onSet: onSet,
          onOther: onMore,
        ),
      ],
    );
  }
}
