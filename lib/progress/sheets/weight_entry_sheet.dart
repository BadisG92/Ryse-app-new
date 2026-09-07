import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../../services/weight_service.dart';

/// Noter son poids.
///
/// Une règle plutôt qu'un champ : on se pèse à 100 g près autour d'une valeur
/// qu'on connaît déjà, et faire glisser depuis le dernier poids demande moins
/// que de retaper trois chiffres. La valeur de départ est la dernière pesée.
class WeightEntrySheet {
  WeightEntrySheet._();

  /// Rend vrai si un poids a été enregistré.
  static Future<bool> show(BuildContext context, {required String lang, required double currentKg}) async {
    final kg = await showRyzeSheet<double>(
      context,
      title: 'progress_log_weight'.tr(lang),
      builder: (sheet) => _Body(lang: lang, currentKg: currentKg),
    );
    if (kg == null || !context.mounted) return false;
    try {
      await WeightService.saveWeightEntry(kg);
      if (!context.mounted) return true;
      RyzeFeedback.success();
      RyzeUndo.note(context, message: 'progress_weight_saved'.tr(lang));
      return true;
    } catch (_) {
      if (context.mounted) RyzeUndo.failed(context, message: 'progress_weight_failed'.tr(lang));
      return false;
    }
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.currentKg});

  final String lang;
  final double currentKg;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late double _kg = widget.currentKg > 0 ? widget.currentKg : 70;

  void _bump(double deltaShown) {
    final units = UnitService.instance;
    // La règle bouge dans l'unité de l'utilisateur ; la base reste en kilos.
    final step = units.isMetric ? deltaShown : deltaShown / 2.2046226218;
    setState(() => _kg = (_kg + step).clamp(25, 300));
    RyzeFeedback.tap();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final units = UnitService.instance;
    final shown = units.displayWeight(_kg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Step(icon: LucideIcons.minus, onTap: () => _bump(-0.1)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RollingNumber(
                    shown.toStringAsFixed(1),
                    style: RyzeText.display(context, 13, weight: FontWeight.w600).copyWith(height: 1),
                  ),
                  SizedBox(width: context.vw(1.5)),
                  Padding(
                    padding: EdgeInsets.only(bottom: context.vw(1.5)),
                    child: Text(units.weightUnit, style: RyzeText.body(context, 3.9, color: RyzeColors.mute)),
                  ),
                ],
              ),
            ),
            _Step(icon: LucideIcons.plus, onTap: () => _bump(0.1)),
          ],
        ),
        SizedBox(height: context.vw(2.1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Pill(label: '−1', onTap: () => _bump(-1)),
            SizedBox(width: context.vw(2.1)),
            _Pill(label: '−0,5', onTap: () => _bump(-0.5)),
            SizedBox(width: context.vw(2.1)),
            _Pill(label: '+0,5', onTap: () => _bump(0.5)),
            SizedBox(width: context.vw(2.1)),
            _Pill(label: '+1', onTap: () => _bump(1)),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.confirm();
            Navigator.pop(context, _kg);
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
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: context.vw(12.3),
        height: context.vw(12.3),
        decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
        child: Icon(icon, size: context.vw(5.1), color: RyzeColors.ink),
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
        height: context.vw(9.2),
        padding: EdgeInsets.symmetric(horizontal: context.vw(3.6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.pill),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Text(label, style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
      ),
    );
  }
}
