import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../models/cardio_session_models.dart';
import '../../services/sport_session_flow.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';

/// La fin d'une séance cardio ou HIIT : une feuille, jamais un dialogue.
///
/// Le résumé, l'intensité en trois puces, un bouton. L'écriture passe par
/// `SportSessionFlow.finishCardio` — le seul chemin — et la pilule d'accusé
/// dit ce qui a été enregistré. Un échec le dit aussi, sans rien perdre de
/// ce que l'utilisateur a sous les yeux.
class CardioFinishSheet {
  CardioFinishSheet._();

  static const List<String> intensities = ['Faible', 'Modéré', 'Élevé'];

  static Future<bool> show(
    BuildContext context, {
    required String lang,
    required CardioSessionData session,
    String? notes,
    int defaultIntensity = 1,
  }) async {
    final choice = await showRyzeSheet<String>(
      context,
      title: 'cardio_summary_title'.tr(lang),
      subtitle: session.activityTitle,
      dismissible: false,
      builder: (sheet) => _Body(lang: lang, session: session, defaultIntensity: defaultIntensity),
    );
    if (choice == null || !context.mounted) return false;

    final result = await SportSessionFlow.finishCardio(session, intensity: choice, notes: notes);
    if (!context.mounted) return result.saved;
    if (result.saved) {
      RyzeFeedback.success();
      RyzeUndo.note(
        context,
        message: 'cardio_saved_ack'.tr(lang).replaceAll('{min}', '${result.minutes}').replaceAll('{kcal}', '${result.kcal}'),
      );
    } else {
      RyzeUndo.failed(context, message: 'cardio_save_failed'.tr(lang));
    }
    return result.saved;
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.session, required this.defaultIntensity});

  final String lang;
  final CardioSessionData session;
  final int defaultIntensity;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late int _intensity = widget.defaultIntensity;

  static String _key(int i) => const ['workout_intensity_low', 'workout_intensity_moderate', 'workout_intensity_high'][i];

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final s = widget.session;
    final units = UnitService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _Stat(value: '${s.duration.inMinutes}', label: 'minutes'.tr(lang))),
            if (s.distance > 0)
              Expanded(child: _Stat(value: units.displayDistance(s.distance).toStringAsFixed(2), label: units.distanceUnit)),
            if (s.steps > 0) Expanded(child: _Stat(value: '${s.steps}', label: 'cardio_steps_label'.tr(lang))),
            Expanded(child: _Stat(value: '${s.calories}', label: 'nutri_kcal'.tr(lang), amber: true)),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        Text('session_intensity'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Row(
          children: [
            for (var i = 0; i < CardioFinishSheet.intensities.length; i++) ...[
              if (i > 0) SizedBox(width: context.vw(2.1)),
              Expanded(
                child: OnbChip(
                  label: _key(i).tr(lang),
                  selected: _intensity == i,
                  index: i,
                  onTap: () => setState(() => _intensity = i),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.vw(4.1)),
        Pressable(
          onTap: () {
            RyzeFeedback.confirm();
            Navigator.pop(context, CardioFinishSheet.intensities[_intensity]);
          },
          child: Container(
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RyzeColors.ink,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: RyzeShadow.soft,
            ),
            child: Text('cardio_validate'.tr(lang), style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
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
          maxLines: 1,
          style: RyzeText.display(context, 6.7, weight: FontWeight.w600).copyWith(
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
