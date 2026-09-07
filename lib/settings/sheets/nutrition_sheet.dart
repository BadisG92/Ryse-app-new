import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../settings_data.dart';
import '../widgets/controls.dart';

/// Les calories et la répartition des macros.
///
/// Deux façons de s'en servir : *Recalculer* remet les valeurs que le profil
/// implique, ou on règle soi-même — les calories au pas de 50, puis la part
/// de chaque macro. Les grammes se déduisent des calories et des parts, donc
/// ils ne peuvent jamais se contredire, ce qui arrivait quand les quatre
/// nombres étaient quatre champs indépendants.
class NutritionSheet {
  NutritionSheet._();

  static const List<({String label, double p, double c, double f})> presets = [
    (label: 'balanced', p: 0.30, c: 0.40, f: 0.30),
    (label: 'weight_loss_full', p: 0.35, c: 0.30, f: 0.35),
    (label: 'weight_gain_full', p: 0.30, c: 0.45, f: 0.25),
  ];

  static Future<bool> show(BuildContext context, {required String lang, required SettingsProfile p}) async {
    final ok = await showRyzeSheet<bool>(
      context,
      title: 'settings_nutrition'.tr(lang),
      subtitle: 'settings_macros_hint'.tr(lang),
      builder: (sheet) => _Body(lang: lang, p: p),
    );
    return ok ?? false;
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.p});

  final String lang;
  final SettingsProfile p;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late int _kcal = widget.p.calories;
  late double _pPct;
  late double _cPct;
  late double _fPct;
  late bool _custom = widget.p.hasCustomMacros;

  @override
  void initState() {
    super.initState();
    final total = widget.p.calories <= 0 ? 1 : widget.p.calories;
    _pPct = (widget.p.protein * 4 / total).clamp(0.1, 0.6);
    _cPct = (widget.p.carbs * 4 / total).clamp(0.1, 0.7);
    _fPct = (1 - _pPct - _cPct).clamp(0.15, 0.5);
    _normalise();
  }

  void _normalise() {
    final sum = _pPct + _cPct + _fPct;
    if (sum <= 0) return;
    _pPct /= sum;
    _cPct /= sum;
    _fPct /= sum;
  }

  /// Bouger une part reprend la différence sur les deux autres, au prorata :
  /// la somme reste 100 % sans que l'utilisateur ait à faire l'arithmétique.
  void _setPart(int which, double v) {
    v = v.clamp(0.10, 0.65);
    final others = which == 0 ? [_cPct, _fPct] : (which == 1 ? [_pPct, _fPct] : [_pPct, _cPct]);
    final rest = 1 - v;
    final sumOthers = others[0] + others[1];
    final a = sumOthers <= 0 ? rest / 2 : others[0] / sumOthers * rest;
    final b = rest - a;
    setState(() {
      _custom = true;
      switch (which) {
        case 0:
          _pPct = v;
          _cPct = a;
          _fPct = b;
        case 1:
          _cPct = v;
          _pPct = a;
          _fPct = b;
        default:
          _fPct = v;
          _pPct = a;
          _cPct = b;
      }
    });
  }

  int get _protein => (_kcal * _pPct / 4).round();
  int get _carbs => (_kcal * _cPct / 4).round();
  int get _fat => (_kcal * _fPct / 9).round();

  void _recompute() {
    final c = widget.p.computed();
    final total = c.calories <= 0 ? 1 : c.calories;
    setState(() {
      _kcal = c.calories;
      _pPct = c.protein * 4 / total;
      _cPct = c.carbs * 4 / total;
      _fPct = c.fat * 9 / total;
      _custom = false;
      _normalise();
    });
    RyzeFeedback.confirm();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final numbers = NumberFormat.decimalPattern(lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingStepper(
          label: 'daily_calorie_goal'.tr(lang),
          value: numbers.format(_kcal),
          unit: 'nutri_kcal'.tr(lang),
          onLess: _kcal > 1000 ? () => setState(() => _kcal -= 50) : null,
          onMore: _kcal < 6000 ? () => setState(() => _kcal += 50) : null,
        ),
        SettingLabel('macronutrient_distribution'.tr(lang)),
        _Macro(label: 'proteins'.tr(lang), grams: _protein, pct: _pPct, onChanged: (v) => _setPart(0, v)),
        _Macro(label: 'carbohydrates'.tr(lang), grams: _carbs, pct: _cPct, onChanged: (v) => _setPart(1, v)),
        _Macro(label: 'fats'.tr(lang), grams: _fat, pct: _fPct, onChanged: (v) => _setPart(2, v)),
        SettingLabel('predefined_distributions'.tr(lang)),
        Wrap(
          spacing: context.vw(2.1),
          runSpacing: context.vw(2.1),
          children: [
            for (var i = 0; i < NutritionSheet.presets.length; i++)
              OnbChip(
                label: NutritionSheet.presets[i].label.tr(lang),
                selected: (_pPct - NutritionSheet.presets[i].p).abs() < 0.02 && (_cPct - NutritionSheet.presets[i].c).abs() < 0.02,
                index: i,
                onTap: () => setState(() {
                  _pPct = NutritionSheet.presets[i].p;
                  _cPct = NutritionSheet.presets[i].c;
                  _fPct = NutritionSheet.presets[i].f;
                  _custom = true;
                }),
              ),
          ],
        ),
        SizedBox(height: context.vw(3.6)),
        Pressable(
          onTap: _recompute,
          child: Container(
            height: context.vw(12.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              border: Border.all(color: RyzeColors.idle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.refreshCw, size: context.vw(4.1), color: RyzeColors.ink),
                SizedBox(width: context.vw(1.5)),
                Flexible(
                  child: Text(
                    'recalculate_nutrition_plan'.tr(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RyzeText.body(context, 3.4, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        SettingSave(
          label: 'save'.tr(lang),
          onTap: () {
            widget.p
              ..calories = _kcal
              ..protein = _protein
              ..carbs = _carbs
              ..fat = _fat
              ..hasCustomMacros = _custom;
            RyzeFeedback.confirm();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

/// Une macro : son nom, ses grammes, sa part — et la barre qu'on tire.
class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.grams, required this.pct, required this.onChanged});

  final String label;
  final int grams;
  final double pct;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: RyzeText.body(context, 3.4, weight: FontWeight.w600))),
              Text(
                '$grams g · ${(pct * 100).round()} %',
                style: RyzeText.body(context, 3.1, color: RyzeColors.mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: RyzeColors.ink,
              inactiveTrackColor: RyzeColors.idle,
              thumbColor: RyzeColors.ink,
              overlayColor: RyzeColors.ink.withValues(alpha: 0.08),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: pct.clamp(0.10, 0.65),
              min: 0.10,
              max: 0.65,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
