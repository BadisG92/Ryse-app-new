import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/ui/numeric_text_field.dart';
import '../../design/design.dart';
import '../../models/cardio_session_models.dart';
import '../../services/auth_service.dart';
import '../../services/cardio_calculator.dart';
import '../../services/ryze_dates.dart';
import '../../services/sport_session_flow.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';

/// Déclarer une séance qu'on a faite sans l'app.
///
/// L'ancien écran faisait 1 187 lignes, trois snackbars rouges de validation
/// et un dialogue de résumé avant d'enregistrer. Ici : le jour en puces, la
/// durée en pas, la distance dans un champ, l'intensité en trois puces —
/// et l'estimation de calories qui roule en direct, comme la portion à
/// Nutrition. Le bouton ne s'allume que quand la durée existe : la
/// validation est dans le champ, pas dans un message.
class ManualCardioSheet {
  ManualCardioSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String lang,
    required String activityType,
    required String activityTitle,
    required String formatTitle,
    CardioObjective? objective,
  }) async {
    final result = await showRyzeSheet<_Entry>(
      context,
      title: 'cardio_manual_title'.tr(lang),
      subtitle: activityTitle,
      keyboard: true,
      builder: (sheet) => _Body(lang: lang, activityType: activityType, objective: objective),
    );
    if (result == null || !context.mounted) return false;

    final start = DateTime(result.day.year, result.day.month, result.day.day, 12);
    final session = CardioSessionData(
      activityType: activityType,
      activityTitle: activityTitle,
      formatTitle: formatTitle,
      startTime: start,
      endTime: start.add(result.duration),
      duration: result.duration,
      distance: result.distanceKm,
      calories: result.kcal,
      averageSpeed: result.duration.inMinutes > 0 && result.distanceKm > 0 ? result.distanceKm / (result.duration.inMinutes / 60) : 0,
    );
    final outcome = await SportSessionFlow.finishCardio(session, intensity: result.intensity);
    if (!context.mounted) return outcome.saved;
    if (outcome.saved) {
      RyzeFeedback.success();
      RyzeUndo.note(
        context,
        message: 'cardio_saved_ack'.tr(lang).replaceAll('{min}', '${outcome.minutes}').replaceAll('{kcal}', '${outcome.kcal}'),
      );
    } else {
      RyzeUndo.failed(context, message: 'cardio_save_failed'.tr(lang));
    }
    return outcome.saved;
  }
}

class _Entry {
  const _Entry({required this.day, required this.duration, required this.distanceKm, required this.kcal, required this.intensity});

  final DateTime day;
  final Duration duration;
  final double distanceKm;
  final int kcal;
  final String intensity;
}

class _Body extends StatefulWidget {
  const _Body({required this.lang, required this.activityType, required this.objective});

  final String lang;
  final String activityType;
  final CardioObjective? objective;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const List<String> _intensities = ['Faible', 'Modéré', 'Élevé'];

  late DateTime _day = _startOfToday();
  late int _minutes = widget.objective?.targetDuration?.inMinutes ?? 30;
  int _intensity = 1;
  final TextEditingController _distance = TextEditingController();

  static DateTime _startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final target = widget.objective?.targetDistance;
    if (target != null && target > 0) {
      _distance.text = UnitService.instance.displayDistance(target).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _distance.dispose();
    super.dispose();
  }

  double get _distanceKm {
    final raw = double.tryParse(_distance.text.replaceAll(',', '.')) ?? 0;
    if (raw <= 0) return 0;
    final units = UnitService.instance;
    // Le champ est dans l'unité de l'utilisateur ; la base est en kilomètres.
    return units.isMetric ? raw : raw * 1.609344;
  }

  int get _kcal {
    if (_minutes <= 0) return 0;
    final d = Duration(minutes: _minutes);
    final km = _distanceKm;
    return CardioCalculator.calculateCalories(
      activityType: widget.activityType,
      duration: d,
      averageSpeed: km > 0 ? km / (_minutes / 60) : null,
      distance: km > 0 ? km : null,
      userWeight: AuthService().currentUser?.weight ?? 70.0,
    );
  }

  static String _key(int i) => const ['workout_intensity_low', 'workout_intensity_moderate', 'workout_intensity_high'][i];

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final units = UnitService.instance;
    final days = [for (var i = 6; i >= 0; i--) _startOfToday().subtract(Duration(days: i))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('cardio_manual_date'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        SizedBox(
          height: context.vw(13.3),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: days.length,
            separatorBuilder: (_, __) => SizedBox(width: context.vw(2.1)),
            itemBuilder: (_, i) {
              final d = days[days.length - 1 - i];
              final on = d == _day;
              return Pressable(
                onTap: () {
                  RyzeFeedback.select();
                  setState(() => _day = d);
                },
                child: AnimatedContainer(
                  duration: RyzeDurations.tap,
                  curve: RyzeCurves.out,
                  width: context.vw(13.3),
                  decoration: BoxDecoration(
                    color: on ? RyzeColors.ink : RyzeColors.surf,
                    borderRadius: BorderRadius.circular(RyzeRadius.sm),
                    border: Border.all(color: on ? RyzeColors.ink : RyzeColors.line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(RyzeDates.short(d, lang), style: RyzeText.body(context, 2.6, weight: FontWeight.w600, color: on ? RyzeColors.surf.withValues(alpha: 0.7) : RyzeColors.mute2)),
                      Text('${d.day}', style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: on ? RyzeColors.surf : RyzeColors.ink)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.vw(4.1)),
        Text('cardio_manual_duration'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(1.5)),
        Row(
          children: [
            _Step(icon: LucideIcons.minus, onTap: _minutes > 5 ? () => setState(() => _minutes -= 5) : null),
            Expanded(
              child: Center(
                child: RollingNumber(_hm(lang), style: RyzeText.display(context, 6.7, weight: FontWeight.w600)),
              ),
            ),
            _Step(icon: LucideIcons.plus, onTap: _minutes < 600 ? () => setState(() => _minutes += 5) : null),
          ],
        ),
        SizedBox(height: context.vw(3.6)),
        Row(
          children: [
            Expanded(
              child: Text('${'cardio_manual_distance'.tr(lang)} · ${units.distanceUnit}', style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
            ),
            SizedBox(
              width: context.vw(28),
              child: Container(
                decoration: BoxDecoration(
                  color: RyzeColors.surf,
                  borderRadius: BorderRadius.circular(RyzeRadius.sm),
                  border: Border.all(color: RyzeColors.line),
                ),
                child: NumericTextField(
                  controller: _distance,
                  hintText: '0',
                  textAlign: TextAlign.center,
                  allowDecimals: true,
                  minValue: 0,
                  maxValue: 500,
                  onChanged: (_) => setState(() {}),
                  style: RyzeText.display(context, 5.1, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: RyzeText.display(context, 5.1, weight: FontWeight.w600).copyWith(color: RyzeColors.mute2),
                    contentPadding: EdgeInsets.symmetric(vertical: context.vw(2.6)),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.vw(4.1)),
        Text('session_intensity'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Row(
          children: [
            for (var i = 0; i < _intensities.length; i++) ...[
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.6)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Row(
            children: [
              Expanded(child: Text('cardio_estimated'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute))),
              RollingNumber('$_kcal', style: RyzeText.display(context, 6.2, weight: FontWeight.w600).copyWith(color: RyzeColors.accInk)),
              SizedBox(width: context.vw(1.5)),
              Text('nutri_kcal'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
            ],
          ),
        ),
        SizedBox(height: context.vw(4.1)),
        Pressable(
          onTap: _minutes <= 0
              ? null
              : () {
                  RyzeFeedback.confirm();
                  Navigator.pop(
                    context,
                    _Entry(
                      day: _day,
                      duration: Duration(minutes: _minutes),
                      distanceKm: _distanceKm,
                      kcal: _kcal,
                      intensity: _intensities[_intensity],
                    ),
                  );
                },
          child: AnimatedContainer(
            duration: RyzeDurations.tap,
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _minutes > 0 ? RyzeColors.ink : RyzeColors.idle,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              boxShadow: _minutes > 0 ? RyzeShadow.soft : null,
            ),
            child: Text(
              'cardio_validate'.tr(lang),
              style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: _minutes > 0 ? RyzeColors.surf : RyzeColors.mute),
            ),
          ),
        ),
      ],
    );
  }

  String _hm(String lang) {
    final h = _minutes ~/ 60;
    final m = _minutes % 60;
    if (h == 0) return '$m ${'cardio_manual_minutes'.tr(lang)}';
    if (m == 0) return '$h ${'cardio_manual_hours'.tr(lang)}';
    return '$h ${'cardio_manual_hours'.tr(lang)} $m';
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
