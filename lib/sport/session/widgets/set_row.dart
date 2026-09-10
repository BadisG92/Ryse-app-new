import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/localization_service.dart';
import '../../../services/translations.dart';
import '../../../services/unit_service.dart';
import '../session_controller.dart';
import '../session_models.dart';

/// Une série : son numéro, le poids, `×`, les reps, la coche.
///
/// Les deux cellules montrent ce qui est enregistré en grand, ou ce qui
/// serait pris — la dernière fois, la série d'avant — en fantôme. L'état est
/// le remplissage, comme partout dans le système : blanc bord clair à faire,
/// bord navy en saisie, navy plein faite. La coche seule suffit quand le
/// fantôme est juste : c'est le geste à un tap.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.ghost,
    required this.editing,
    required this.buffer,
    required this.onTapWeight,
    required this.onTapReps,
    required this.onCheck,
    this.onLongPress,
  });

  final int index;
  final LiveSet set;
  final ({double? weightKg, int? reps}) ghost;

  /// La cellule en saisie sur cette rangée, s'il y en a une.
  final EditField? editing;
  final String buffer;

  final VoidCallback onTapWeight;
  final VoidCallback onTapReps;
  final VoidCallback onCheck;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final units = UnitService.instance;
    final done = set.done;
    final record = done && set.record;
    final fg = done ? RyzeColors.surf : RyzeColors.ink;

    String weightText;
    bool weightGhost;
    if (editing == EditField.weight && buffer.isNotEmpty) {
      weightText = buffer.replaceAll('.', _decimal());
      weightGhost = false;
    } else if (set.weightKg > 0) {
      weightText = _w(units.displayWeight(set.weightKg));
      weightGhost = false;
    } else if (ghost.weightKg != null) {
      weightText = _w(units.displayWeight(ghost.weightKg!));
      weightGhost = true;
    } else {
      weightText = '—';
      weightGhost = true;
    }

    String repsText;
    bool repsGhost;
    if (editing == EditField.reps && buffer.isNotEmpty) {
      repsText = buffer;
      repsGhost = false;
    } else if (set.reps > 0) {
      repsText = '${set.reps}';
      repsGhost = false;
    } else if (ghost.reps != null) {
      repsText = '${ghost.reps}';
      repsGhost = true;
    } else {
      repsText = '—';
      repsGhost = true;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        margin: EdgeInsets.only(bottom: context.vw(1.8)),
        padding: EdgeInsets.symmetric(horizontal: context.vw(2.6), vertical: context.vw(1.5)),
        decoration: BoxDecoration(
          color: done ? RyzeColors.ink : RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
          // Un record garde le fond de l'encre et prend le trait de l'ambre :
          // c'est Ryze qui rend quelque chose, pas l'utilisateur qui choisit.
          border: Border.all(color: record ? RyzeColors.acc : (done ? RyzeColors.ink : RyzeColors.line), width: record ? 1.4 : 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: context.vw(5.6),
              child: Text(
                '${index + 1}',
                style: RyzeText.body(context, 3.3, weight: FontWeight.w600, color: done ? RyzeColors.surf.withValues(alpha: 0.7) : RyzeColors.mute2),
              ),
            ),
            Expanded(
              child: _Cell(
                text: weightText,
                unit: units.weightUnit,
                ghost: weightGhost,
                active: editing == EditField.weight,
                done: done,
                fg: fg,
                onTap: done ? null : onTapWeight,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.vw(1.5)),
              child: Text('×', style: RyzeText.body(context, 3.9, color: done ? RyzeColors.surf.withValues(alpha: 0.6) : RyzeColors.mute2)),
            ),
            Expanded(
              child: _Cell(
                text: repsText,
                unit: null,
                ghost: repsGhost,
                active: editing == EditField.reps,
                done: done,
                fg: fg,
                onTap: done ? null : onTapReps,
              ),
            ),
            if (record) ...[
              SizedBox(width: context.vw(1.5)),
              Text(
                'session_record'.tr(LocalizationService.instance.currentLanguageCode),
                style: RyzeText.body(context, 2.6, weight: FontWeight.w700, color: RyzeColors.acc),
              ),
            ],
            SizedBox(width: context.vw(2.1)),
            Semantics(
              button: true,
              child: Pressable(
                onTap: onCheck,
                child: RyzeLanding(
                  on: done,
                  amount: 0.18,
                    child: Container(
                    width: context.vw(9.2),
                    height: context.vw(9.2),
                    decoration: BoxDecoration(
                      color: done ? RyzeColors.surf : RyzeColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: done ? RyzeColors.surf : RyzeColors.ink, width: 1.4),
                    ),
                    child: Icon(LucideIcons.check, size: context.vw(4.1), color: record ? RyzeColors.accInk : RyzeColors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Le poids affiché, avec le séparateur décimal de la langue de l'app.
  ///
  /// `toStringAsFixed` écrit toujours un point : le pavé proposait une
  /// virgule à un francophone (`number_pad`, lui, lisait la bonne langue) et
  /// la rangée réaffichait un point juste au-dessus.
  static String _w(double v) =>
      (v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1)).replaceAll('.', _decimal());

  /// La langue de l'app, pas celle de Flutter : `Localizations.localeOf`
  /// répond `en` partout tant que `MaterialApp` n'a pas de locale.
  static String _decimal() => LocalizationService.instance.currentLanguageCode == 'en' ? '.' : ',';
}

/// Une valeur qu'on presse pour la changer.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.text,
    required this.unit,
    required this.ghost,
    required this.active,
    required this.done,
    required this.fg,
    required this.onTap,
  });

  final String text;
  final String? unit;
  final bool ghost;
  final bool active;
  final bool done;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = done ? fg : (ghost ? RyzeColors.mute : RyzeColors.ink);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: RyzeDurations.tap,
        curve: RyzeCurves.out,
        constraints: BoxConstraints(minHeight: context.vw(11.3)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? Colors.transparent : (active ? RyzeColors.surf : RyzeColors.paper),
          borderRadius: BorderRadius.circular(RyzeRadius.xs),
          border: Border.all(color: active ? RyzeColors.ink : Colors.transparent, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: (ghost && !done ? RyzeText.body(context, 4.6, weight: FontWeight.w500) : RyzeText.display(context, 5.6, weight: FontWeight.w600))
                  .copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()], height: 1.1),
            ),
            if (unit != null) ...[
              SizedBox(width: context.vw(1)),
              Padding(
                padding: EdgeInsets.only(bottom: context.vw(0.6)),
                child: Text(unit!, style: RyzeText.body(context, 2.9, color: done ? fg.withValues(alpha: 0.7) : RyzeColors.mute2)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
