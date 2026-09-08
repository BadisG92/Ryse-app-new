import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../session_controller.dart';

/// Le pavé de l'écran, à la place du clavier système.
///
/// Le pavé numérique d'iOS n'a pas de touche Retour : c'est ce qui avait
/// forcé l'ancien écran à empiler des minuteurs et des marges magiques pour
/// suivre le focus. Ici les touches sont à nous, grandes, avec les pas qu'on
/// fait vraiment en salle (−2,5 · +2,5 · +5 pour le poids), le micro, et un
/// seul bouton principal : *Suivant* sur le poids, *Valider* sur les reps.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.controller, required this.lang, required this.onMic});

  final SessionController controller;
  final String lang;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final weight = controller.editingField == EditField.weight;
    final decimal = lang == 'en' ? '.' : ',';
    final gutter = context.vw(4.1);

    return Container(
      padding: EdgeInsets.fromLTRB(gutter, context.vw(2.6), gutter, context.vw(2.1)),
      decoration: BoxDecoration(
        color: RyzeColors.paper,
        border: Border(top: BorderSide(color: RyzeColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Les pas. Appliqués à ce qui est tapé, sinon à la valeur, sinon
          // au fantôme : on ne repart jamais de zéro.
          Row(
            children: [
              for (final step in weight ? const [-2.5, 2.5, 5.0] : const [-1.0, 1.0])
                Padding(
                  padding: EdgeInsets.only(right: context.vw(2.1)),
                  child: _Pill(
                    label: (step > 0 ? '+' : '−') + _fmt(step.abs(), decimal),
                    onTap: () => controller.bump(step),
                  ),
                ),
              const Spacer(),
              _Round(icon: LucideIcons.mic, label: 'session_dictate'.tr(lang), onTap: onMic),
            ],
          ),
          SizedBox(height: context.vw(2.1)),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: EdgeInsets.only(bottom: context.vw(1.5)),
              child: Row(children: [for (final k in row) _Key(label: k, onTap: () => controller.type(k))]),
            ),
          Row(
            children: [
              _Key(label: decimal, enabled: weight, onTap: () => controller.type('.')),
              _Key(label: '0', onTap: () => controller.type('0')),
              _Key(icon: LucideIcons.delete, onTap: () => controller.type('⌫')),
            ],
          ),
          SizedBox(height: context.vw(2.1)),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: controller.closePad,
                  child: Container(
                    height: context.vw(12.3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RyzeColors.surf,
                      borderRadius: BorderRadius.circular(RyzeRadius.sm),
                      border: Border.all(color: RyzeColors.line),
                    ),
                    child: Text('cancel'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(width: context.vw(2.6)),
              Expanded(
                flex: 2,
                child: Pressable(
                  onTap: () {
                    final i = controller.editingSet;
                    if (i == null) return;
                    if (weight) {
                      controller.next();
                    } else {
                      controller.completeSet(i);
                    }
                  },
                  child: Container(
                    height: context.vw(12.3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: RyzeColors.ink,
                      borderRadius: BorderRadius.circular(RyzeRadius.sm),
                      boxShadow: RyzeShadow.soft,
                    ),
                    child: Text(
                      (weight ? 'session_next' : 'session_validate').tr(lang),
                      style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v, String decimal) {
    final s = v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return s.replaceAll('.', decimal);
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap, this.enabled = true});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.vw(0.8)),
        child: Pressable(
          onTap: enabled ? onTap : null,
          child: Container(
            height: context.vw(12.8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? RyzeColors.surf : RyzeColors.paper2,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              border: Border.all(color: RyzeColors.line),
            ),
            child: icon != null
                ? Icon(icon, size: context.vw(5.1), color: RyzeColors.ink)
                : Text(
                    label!,
                    style: RyzeText.display(context, 6.2, weight: FontWeight.w600).copyWith(
                      color: enabled ? RyzeColors.ink : RyzeColors.mute2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: context.vw(9.7),
        padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Text(
          label,
          style: RyzeText.body(context, 3.4, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: context.vw(9.7),
          height: context.vw(9.7),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            shape: BoxShape.circle,
            border: Border.all(color: RyzeColors.line),
          ),
          child: Icon(icon, size: context.vw(4.6), color: RyzeColors.ink),
        ),
      ),
    );
  }
}
