import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../sport_goal.dart';

/// Fixer, changer ou retirer l'objectif de séances par semaine.
///
/// Cinq puces, pré-sélectionnée sur la fréquence déclarée à l'inscription —
/// une suggestion dite comme telle, pas un objectif posé d'office. Rend le
/// chiffre choisi, `0` pour « pas d'objectif », nul si on referme sans rien
/// décider.
class GoalSheet {
  GoalSheet._();

  static Future<int?> show(BuildContext context, {required String lang, required int? current}) {
    return showRyzeSheet<int>(
      context,
      title: 'sport_goal_title'.tr(lang),
      subtitle: current == null ? 'sport_goal_hint'.tr(lang).replaceAll('{n}', '${SportGoal.suggested()}') : null,
      builder: (sheet) => _Body(lang: lang, initial: current ?? SportGoal.suggested()),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.initial});

  final String lang;
  final int initial;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < SportGoal.choices.length; i++) ...[
              if (i > 0) SizedBox(width: context.vw(2.1)),
              Expanded(
                child: OnbChip(
                  label: '${SportGoal.choices[i]}',
                  selected: _value == SportGoal.choices[i],
                  index: i,
                  onTap: () => setState(() => _value = SportGoal.choices[i]),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vw(1.5)),
        Text('sport_goal_unit'.tr(lang), textAlign: TextAlign.center, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
        SizedBox(height: context.vw(4.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.confirm();
            Navigator.pop(context, _value);
          },
          child: Container(
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RyzeColors.ink,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: RyzeShadow.soft,
            ),
            child: Text('save'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
          ),
        ),
        SizedBox(height: context.vw(2.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.tap();
            Navigator.pop(context, 0);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(2.6)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.x, size: context.vw(3.6), color: RyzeColors.mute),
                SizedBox(width: context.vw(1.5)),
                Text('sport_goal_none'.tr(lang), style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: RyzeColors.mute)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
