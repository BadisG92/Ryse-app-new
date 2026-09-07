import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design/design.dart';
import '../../../services/translations.dart';
import '../../../services/unit_service.dart';
import '../session_models.dart';

/// Ce que l'utilisateur a décidé en terminant.
class FinishChoice {
  const FinishChoice({required this.intensity, required this.minutes, required this.saveAsProgram});

  /// La valeur telle que la base la connaît : 'Faible', 'Modéré', 'Élevé'.
  final String intensity;
  final int minutes;
  final bool saveAsProgram;
}

/// Une seule feuille à la place des quatre dialogues de l'ancien écran.
///
/// Le résumé (durée, séries, volume, kcal), l'intensité en trois puces, la
/// durée ajustable par cinq minutes, une rangée cochable « enregistrer comme
/// programme » quand la séance n'en vient pas déjà d'un, une ligne muette
/// pour les séries non validées, un bouton. Les kcal sont recalculées à
/// chaque changement par `kcalFor`, jamais inventées.
class FinishSheet {
  FinishSheet._();

  static const List<String> intensities = ['Faible', 'Modéré', 'Élevé'];

  static Future<FinishChoice?> show(
    BuildContext context, {
    required String lang,
    required LiveSession session,
    required int elapsedMinutes,
    required int Function(String intensity, int minutes) kcalFor,
  }) {
    return showRyzeSheet<FinishChoice>(
      context,
      title: 'session_finish_title'.tr(lang),
      subtitle: session.name,
      builder: (sheet) => _Finish(lang: lang, session: session, minutes: elapsedMinutes, kcalFor: kcalFor),
    );
  }
}

class _Finish extends StatefulWidget {
  const _Finish({required this.lang, required this.session, required this.minutes, required this.kcalFor});

  final String lang;
  final LiveSession session;
  final int minutes;
  final int Function(String, int) kcalFor;

  @override
  State<_Finish> createState() => _FinishState();
}

class _FinishState extends State<_Finish> {
  int _intensity = 1;
  late int _minutes = widget.minutes.clamp(1, 600);
  bool _save = false;

  String get _intensityValue => FinishSheet.intensities[_intensity];

  static String _intensityKey(int i) => const ['workout_intensity_low', 'workout_intensity_moderate', 'workout_intensity_high'][i];

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final s = widget.session;
    final units = UnitService.instance;
    final volume = units.displayWeight(s.volumeKg);
    final kcal = widget.kcalFor(_intensityValue, _minutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _Stat(value: '${s.doneSets}', label: 'session_sets_done'.tr(lang))),
            Expanded(child: _Stat(value: volume.round().toString(), label: '${'session_volume'.tr(lang)} · ${units.weightUnit}')),
            Expanded(child: _Stat(value: '$kcal', label: 'session_kcal_estimated'.tr(lang), amber: true)),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        Text('session_intensity'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Row(
          children: [
            for (var i = 0; i < FinishSheet.intensities.length; i++) ...[
              if (i > 0) SizedBox(width: context.vw(2.1)),
              Expanded(
                child: OnbChip(
                  label: _intensityKey(i).tr(lang),
                  selected: _intensity == i,
                  index: i,
                  onTap: () => setState(() => _intensity = i),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vw(4.1)),
        Text('session_duration'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Row(
          children: [
            _Step(icon: LucideIcons.minus, onTap: _minutes > 5 ? () => setState(() => _minutes -= 5) : null),
            Expanded(
              child: Center(
                child: RollingNumber(
                  '$_minutes ${'minutes'.tr(lang)}',
                  style: RyzeText.display(context, 6.2, weight: FontWeight.w600),
                ),
              ),
            ),
            _Step(icon: LucideIcons.plus, onTap: _minutes < 600 ? () => setState(() => _minutes += 5) : null),
          ],
        ),
        if (!s.isFromProgram) ...[
          SizedBox(height: context.vw(4.1)),
          Pressable(
            onTap: () {
              RyzeFeedback.select();
              setState(() => _save = !_save);
            },
            child: AnimatedContainer(
              duration: RyzeDurations.tap,
              curve: RyzeCurves.out,
              padding: EdgeInsets.symmetric(horizontal: context.vw(3.6), vertical: context.vw(3.1)),
              decoration: BoxDecoration(
                color: _save ? RyzeColors.ink : RyzeColors.surf,
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                border: Border.all(color: _save ? RyzeColors.ink : RyzeColors.line),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.bookmark, size: context.vw(4.6), color: _save ? RyzeColors.surf : RyzeColors.ink),
                  SizedBox(width: context.vw(2.6)),
                  Expanded(
                    child: Text(
                      'session_save_as_program'.tr(lang),
                      style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: _save ? RyzeColors.surf : RyzeColors.ink),
                    ),
                  ),
                  Container(
                    width: context.vw(5.6),
                    height: context.vw(5.6),
                    decoration: BoxDecoration(
                      color: _save ? RyzeColors.surf : Colors.transparent,
                      borderRadius: BorderRadius.circular(RyzeRadius.xs),
                      border: Border.all(color: _save ? RyzeColors.surf : RyzeColors.line, width: 1.4),
                    ),
                    child: _save ? Icon(LucideIcons.check, size: context.vw(3.6), color: RyzeColors.ink) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (s.undoneSets > 0) ...[
          SizedBox(height: context.vw(3.1)),
          Text(
            'session_undone_sets'.tr(lang).replaceAll('{n}', '${s.undoneSets}'),
            textAlign: TextAlign.center,
            style: RyzeText.body(context, 3.1, color: RyzeColors.mute),
          ),
        ],
        SizedBox(height: context.vw(4.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.confirm();
            Navigator.pop(context, FinishChoice(intensity: _intensityValue, minutes: _minutes, saveAsProgram: _save));
          },
          child: Container(
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RyzeColors.ink,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: RyzeShadow.soft,
            ),
            child: Text('session_finish'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.amber = false});

  final String value;
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: RyzeText.display(context, 7.2, weight: FontWeight.w600).copyWith(
            color: amber ? RyzeColors.accInk : RyzeColors.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: RyzeText.body(context, 2.9, color: RyzeColors.mute)),
      ],
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
        width: context.vw(11.3),
        height: context.vw(11.3),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          shape: BoxShape.circle,
          border: Border.all(color: RyzeColors.line),
        ),
        child: Icon(icon, size: context.vw(4.6), color: onTap == null ? RyzeColors.mute2 : RyzeColors.ink),
      ),
    );
  }
}
