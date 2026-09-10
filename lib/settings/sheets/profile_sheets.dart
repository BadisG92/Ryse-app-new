import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../settings_data.dart';
import '../widgets/controls.dart';

/// Qui tu es : le sexe, l'âge, la taille, le poids.
///
/// Quatre valeurs qui servent à calculer le métabolisme, donc les calories.
/// Rien d'autre n'a sa place ici — l'objectif est sa propre feuille, parce
/// qu'on le change pour d'autres raisons et bien plus souvent.
class ProfileSheet {
  ProfileSheet._();

  static const _genders = ['male', 'female', 'other'];

  static Future<bool> show(BuildContext context, {required String lang, required SettingsProfile p}) async {
    final ok = await showRyzeSheet<bool>(
      context,
      title: 'settings_profile'.tr(lang),
      builder: (sheet) => _Body(lang: lang, p: p),
    );
    return ok ?? false;
  }

  static String genderOf(int i) => _genders[i.clamp(0, 2)];
  static int indexOfGender(String g) => _genders.indexOf(g).clamp(0, 2);
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.p});

  final String lang;
  final SettingsProfile p;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late int _gender = ProfileSheet.indexOfGender(widget.p.gender);
  late int _age = widget.p.age;
  late double _height = widget.p.heightCm;
  late double _weight = widget.p.weightKg;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final units = UnitService.instance;
    final metric = units.isMetric;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingChoice(
          label: 'gender'.tr(lang),
          options: ['male'.tr(lang), 'female'.tr(lang), 'other'.tr(lang)],
          index: _gender,
          onChanged: (i) => setState(() => _gender = i),
        ),
        SizedBox(height: context.vw(2.6)),
        SettingStepper(
          label: 'age'.tr(lang),
          value: '$_age',
          unit: 'settings_year_short'.tr(lang),
          onLess: _age > 13 ? () => setState(() => _age--) : null,
          onMore: _age < 100 ? () => setState(() => _age++) : null,
        ),
        // Un pas de un centimètre en impérial ne bougeait le chiffre affiché
        // qu'un tap sur trois : le pouce vaut deux virgule cinq quatre
        // centimètres. Le pas est celui de l'unité qu'on lit — le poids le
        // faisait déjà juste à côté.
        SettingStepper(
          label: 'height'.tr(lang),
          value: metric ? _height.round().toString() : (_height / 2.54).round().toString(),
          unit: metric ? 'cm' : 'in',
          onLess: _height > 120 ? () => setState(() => _height -= metric ? 1 : 2.54) : null,
          onMore: _height < 230 ? () => setState(() => _height += metric ? 1 : 2.54) : null,
        ),
        SettingStepper(
          label: 'weight'.tr(lang),
          value: units.displayWeight(_weight).toStringAsFixed(1),
          unit: units.weightUnit,
          onLess: _weight > 30 ? () => setState(() => _weight -= metric ? 0.5 : 0.4535924) : null,
          onMore: _weight < 250 ? () => setState(() => _weight += metric ? 0.5 : 0.4535924) : null,
        ),
        SettingSave(
          label: 'save'.tr(lang),
          onTap: () {
            widget.p
              ..gender = ProfileSheet.genderOf(_gender)
              ..age = _age
              ..heightCm = _height
              ..weightKg = _weight;
            RyzeFeedback.confirm();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

/// L'objectif : perdre, maintenir, prendre — et le poids visé.
///
/// Le niveau d'activité est ici aussi : il ne décrit pas qui tu es mais ce
/// que tu comptes faire, et c'est lui qui pèse le plus sur les calories.
class GoalSettingsSheet {
  GoalSettingsSheet._();

  static const goals = ['lose', 'maintain', 'gain'];
  static const activities = ['low', 'moderate', 'high'];

  static Future<bool> show(BuildContext context, {required String lang, required SettingsProfile p}) async {
    final ok = await showRyzeSheet<bool>(
      context,
      title: 'settings_objectives'.tr(lang),
      builder: (sheet) => _GoalBody(lang: lang, p: p),
    );
    return ok ?? false;
  }
}

class _GoalBody extends StatefulWidget {
  const _GoalBody({required this.lang, required this.p});

  final String lang;
  final SettingsProfile p;

  @override
  State<_GoalBody> createState() => _GoalBodyState();
}

class _GoalBodyState extends State<_GoalBody> {
  late int _goal = GoalSettingsSheet.goals.indexOf(widget.p.mainGoal).clamp(0, 2);
  late int _activity = GoalSettingsSheet.activities.indexOf(widget.p.activityLevel).clamp(0, 2);
  late double _target = widget.p.targetWeightKg > 0 ? widget.p.targetWeightKg : widget.p.weightKg;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final units = UnitService.instance;
    final step = units.isMetric ? 0.5 : 0.4535924;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingChoice(
          label: 'main_goal'.tr(lang),
          options: ['weight_loss'.tr(lang), 'maintenance'.tr(lang), 'weight_gain'.tr(lang)],
          index: _goal,
          onChanged: (i) => setState(() => _goal = i),
        ),
        SizedBox(height: context.vw(3.6)),
        SettingChoice(
          label: 'activity_level'.tr(lang),
          options: ['low_active'.tr(lang), 'moderate'.tr(lang), 'very_active'.tr(lang)],
          index: _activity,
          onChanged: (i) => setState(() => _activity = i),
        ),
        // Maintenir son poids ne demande pas de poids cible : la question
        // n'apparaît que quand elle a un sens.
        if (_goal != 1) ...[
          SizedBox(height: context.vw(2.6)),
          SettingStepper(
            label: 'target_weight'.tr(lang),
            value: units.displayWeight(_target).toStringAsFixed(1),
            unit: units.weightUnit,
            onLess: _target > 30 ? () => setState(() => _target -= step) : null,
            onMore: _target < 250 ? () => setState(() => _target += step) : null,
          ),
        ],
        SettingSave(
          label: 'save'.tr(lang),
          onTap: () {
            widget.p
              ..mainGoal = GoalSettingsSheet.goals[_goal]
              ..activityLevel = GoalSettingsSheet.activities[_activity]
              ..targetWeightKg = _goal == 1 ? widget.p.weightKg : _target;
            RyzeFeedback.confirm();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

/// Ce que tu ne manges pas.
class RestrictionsSheet {
  RestrictionsSheet._();

  static const keys = ['vegetarian', 'vegan', 'pescetarian', 'other'];

  static Future<bool> show(BuildContext context, {required String lang, required SettingsProfile p}) async {
    final ok = await showRyzeSheet<bool>(
      context,
      title: 'dietary_restrictions'.tr(lang),
      builder: (sheet) => _RestrictionsBody(lang: lang, p: p),
    );
    return ok ?? false;
  }
}

class _RestrictionsBody extends StatefulWidget {
  const _RestrictionsBody({required this.lang, required this.p});

  final String lang;
  final SettingsProfile p;

  @override
  State<_RestrictionsBody> createState() => _RestrictionsBodyState();
}

class _RestrictionsBodyState extends State<_RestrictionsBody> {
  late final Set<String> _picked = {...widget.p.restrictions};

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: context.vw(2.1),
          runSpacing: context.vw(2.1),
          children: [
            for (var i = 0; i < RestrictionsSheet.keys.length; i++)
              OnbChip(
                label: RestrictionsSheet.keys[i].tr(lang),
                selected: _picked.contains(RestrictionsSheet.keys[i]),
                index: i,
                onTap: () => setState(() {
                  final k = RestrictionsSheet.keys[i];
                  _picked.contains(k) ? _picked.remove(k) : _picked.add(k);
                }),
              ),
          ],
        ),
        SettingSave(
          label: 'save'.tr(lang),
          onTap: () {
            widget.p.restrictions = _picked.toList();
            RyzeFeedback.confirm();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
