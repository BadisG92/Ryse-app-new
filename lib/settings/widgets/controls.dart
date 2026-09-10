import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';

/// Les trois commandes dont toutes les feuilles de réglages ont besoin.
///
/// Elles vivent ici plutôt que d'être recopiées dans chaque feuille : sept
/// feuilles qui redessinent chacune leur pas et leur interrupteur, c'est
/// exactement ce que faisait l'ancien écran de 4 090 lignes.

/// Un réglage numérique : le libellé, la valeur, deux pas.
class SettingStepper extends StatelessWidget {
  const SettingStepper({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onLess,
    required this.onMore,
  });

  final String label;
  final String value;
  final String? unit;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vw(1.5)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: RyzeText.body(context, 3.6, weight: FontWeight.w600))),
          _Round(icon: LucideIcons.minus, onTap: onLess),
          SizedBox(
            width: context.vw(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RollingNumber(value, style: RyzeText.display(context, 5.6, weight: FontWeight.w600)),
                if (unit != null) ...[
                  SizedBox(width: context.vw(1)),
                  Padding(
                    padding: EdgeInsets.only(bottom: context.vw(0.6)),
                    child: Text(unit!, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
                  ),
                ],
              ],
            ),
          ),
          _Round(icon: LucideIcons.plus, onTap: onMore),
        ],
      ),
    );
  }
}

/// Un interrupteur, avec sa raison d'être en dessous quand elle aide.
class SettingToggle extends StatelessWidget {
  const SettingToggle({super.key, required this.label, this.hint, required this.value, required this.onChanged});

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        onChanged(!value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(2.6)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                  if (hint != null) Text(hint!, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
                ],
              ),
            ),
            SizedBox(width: context.vw(3.1)),
            AnimatedContainer(
              duration: RyzeDurations.tap,
              curve: RyzeCurves.out,
              width: context.vw(13),
              height: context.vw(7.4),
              padding: const EdgeInsets.all(2),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? RyzeColors.ink : RyzeColors.idle,
                borderRadius: BorderRadius.circular(RyzeRadius.pill),
              ),
              child: Container(
                width: context.vw(6.2),
                height: context.vw(6.2),
                decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un choix parmi quelques-uns, en puces qui vont à la ligne.
class SettingChoice extends StatelessWidget {
  const SettingChoice({super.key, this.label, required this.options, required this.index, required this.onChanged});

  final String? label;
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Un choix est un réglage, comme l'interrupteur et le pas : son
        // intitulé s'écrit comme les leurs. Il portait le style d'un titre de
        // section, donc « Jour du bilan » s'affichait en petit et en gris
        // juste au-dessus d'« Heure du bilan » en grand et en encre — deux
        // réglages voisins, deux niveaux de titre.
        if (label != null) ...[
          Text(label!, style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
          SizedBox(height: context.vw(1.5)),
        ],
        Wrap(
          spacing: context.vw(2.1),
          runSpacing: context.vw(2.1),
          children: [
            for (var i = 0; i < options.length; i++)
              OnbChip(label: options[i], selected: i == index, index: i, onTap: () => onChanged(i)),
          ],
        ),
      ],
    );
  }
}

/// Le titre d'un bloc dans une feuille.
class SettingLabel extends StatelessWidget {
  const SettingLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.vw(3.6), bottom: context.vw(1.5)),
      child: Text(text, style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
    );
  }
}

/// Le bouton plein qui ferme une feuille de réglage.
class SettingSave extends StatelessWidget {
  const SettingSave({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.vw(4.1)),
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: context.vw(13.3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: RyzeColors.ink,
            borderRadius: BorderRadius.circular(RyzeRadius.sm),
            boxShadow: RyzeShadow.soft,
          ),
          child: Text(label, style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              RyzeFeedback.tap();
              onTap!();
            },
      child: Container(
        width: context.vw(10.3),
        height: context.vw(10.3),
        decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
        child: Icon(icon, size: context.vw(4.1), color: onTap == null ? RyzeColors.mute2 : RyzeColors.ink),
      ),
    );
  }
}
