import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/hiit_models.dart';
import '../../services/translations.dart';

/// Régler un HIIT : trois réglages, un aperçu, un bouton.
///
/// L'ancien écran demandait trois nombres au clavier puis calculait les
/// tours en silence. Ici chaque réglage est une paire de pas — la valeur
/// reste lisible pendant qu'on la change — et l'aperçu se recalcule à
/// chaque appui : on voit le nombre de tours avant de commencer.
class HiitSetupSheet {
  HiitSetupSheet._();

  static Future<HiitWorkout?> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<HiitWorkout>(
      context,
      title: 'hiit_setup_title'.tr(lang),
      builder: (sheet) => _Setup(lang: lang),
    );
  }
}

class _Setup extends StatefulWidget {
  const _Setup({required this.lang});

  final String lang;

  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  int _minutes = 15;
  int _work = 30;
  int _rest = 30;

  int get _rounds {
    final cycle = _work + _rest;
    if (cycle <= 0) return 0;
    return ((_minutes * 60) / cycle).floor().clamp(1, 200);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stepper(
          label: 'hiit_total_duration'.tr(lang),
          value: '$_minutes',
          unit: 'hiit_unit_min'.tr(lang),
          onLess: _minutes > 5 ? () => setState(() => _minutes -= 5) : null,
          onMore: _minutes < 60 ? () => setState(() => _minutes += 5) : null,
        ),
        _Stepper(
          label: 'hiit_work_time'.tr(lang),
          value: '$_work',
          unit: 'hiit_unit_sec'.tr(lang),
          onLess: _work > 10 ? () => setState(() => _work -= 5) : null,
          onMore: _work < 120 ? () => setState(() => _work += 5) : null,
        ),
        _Stepper(
          label: 'hiit_rest_time'.tr(lang),
          value: '$_rest',
          unit: 'hiit_unit_sec'.tr(lang),
          onLess: _rest > 5 ? () => setState(() => _rest -= 5) : null,
          onMore: _rest < 120 ? () => setState(() => _rest += 5) : null,
        ),
        SizedBox(height: context.vw(2.6)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Column(
            children: [
              Text('hiit_preview'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
              SizedBox(height: context.vw(1)),
              RollingNumber('$_rounds', style: RyzeText.display(context, 11, weight: FontWeight.w600)),
              Text(
                '${'hiit_cycles_count'.tr(lang)} · $_work ${'hiit_unit_sec'.tr(lang)} / $_rest ${'hiit_unit_sec'.tr(lang)}',
                textAlign: TextAlign.center,
                style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
        SizedBox(height: context.vw(4.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.confirm();
            Navigator.pop(
              context,
              HiitWorkout(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                title: 'hiit_custom_title'.tr(lang),
                description: '',
                workDuration: _work,
                restDuration: _rest,
                totalDuration: _minutes,
                totalRounds: _rounds,
              ),
            );
          },
          child: Container(
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RyzeColors.ink,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: RyzeShadow.soft,
            ),
            child: Text('hiit_start'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.unit, required this.onLess, required this.onMore});

  final String label;
  final String value;
  final String unit;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.1)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: RyzeText.body(context, 3.6, weight: FontWeight.w600))),
          _Step(icon: LucideIcons.minus, onTap: onLess),
          SizedBox(
            width: context.vw(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RollingNumber(value, style: RyzeText.display(context, 6.2, weight: FontWeight.w600)),
                SizedBox(width: context.vw(1)),
                Padding(
                  padding: EdgeInsets.only(bottom: context.vw(0.8)),
                  child: Text(unit, style: RyzeText.body(context, 2.9, color: RyzeColors.mute2)),
                ),
              ],
            ),
          ),
          _Step(icon: LucideIcons.plus, onTap: onMore),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

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
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          shape: BoxShape.circle,
          border: Border.all(color: RyzeColors.line),
        ),
        child: Icon(icon, size: context.vw(4.1), color: onTap == null ? RyzeColors.mute2 : RyzeColors.ink),
      ),
    );
  }
}
