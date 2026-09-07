import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../models/notification_models.dart';
import '../../services/coach_personality_service.dart';
import '../../services/haptic_service.dart';
import '../../services/localization_service.dart';
import '../../services/notification_service.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import '../../services/weekly_bilan_service.dart';
import '../widgets/controls.dart';

/// Coach Ryze : le ton qu'il prend, et le bilan qu'il envoie.
class CoachSheet {
  CoachSheet._();

  static Future<void> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<void>(
      context,
      title: 'settings_coach'.tr(lang),
      keyboard: true,
      builder: (sheet) => _CoachBody(lang: lang),
    );
  }
}

class _CoachBody extends StatefulWidget {
  const _CoachBody({required this.lang});

  final String lang;

  @override
  State<_CoachBody> createState() => _CoachBodyState();
}

class _CoachBodyState extends State<_CoachBody> {
  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  CoachPersonalityType _type = CoachPersonalityType.friendly;
  final TextEditingController _custom = TextEditingController();
  bool _bilan = false;
  int _day = 7;
  int _hour = 19;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await CoachPersonalityService.instance.getPersonality();
      final enabled = await WeeklyBilanService.instance.isWeeklyBilanEnabled();
      final day = await WeeklyBilanService.instance.getBilanDay();
      final hour = await WeeklyBilanService.instance.getBilanHour();
      if (!mounted) return;
      setState(() {
        _type = p.type;
        _custom.text = p.customText ?? '';
        _bilan = enabled;
        _day = day ?? 7;
        _hour = hour;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(10)),
        child: const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2)),
      );
    }
    const types = CoachPersonalityType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: context.vw(2.1),
          runSpacing: context.vw(2.1),
          children: [
            for (var i = 0; i < types.length; i++)
              OnbChip(
                label: '${CoachPersonalityService.getEmoji(types[i])} ${CoachPersonalityService.getLocalizedLabel(types[i], lang)}',
                selected: _type == types[i],
                index: i,
                onTap: () => setState(() => _type = types[i]),
              ),
          ],
        ),
        if (_type == CoachPersonalityType.custom) ...[
          SettingLabel('settings_custom_personality'.tr(lang)),
          Container(
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
              border: Border.all(color: RyzeColors.line),
            ),
            child: TextField(
              controller: _custom,
              maxLines: 3,
              minLines: 2,
              style: RyzeText.body(context, 3.6, height: 1.4),
              cursorColor: RyzeColors.ink,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(context.vw(3.6)),
              ),
            ),
          ),
        ],
        SettingLabel('weekly_bilan_enabled'.tr(lang)),
        SettingToggle(label: 'settings_notif_recap'.tr(lang), value: _bilan, onChanged: (v) => setState(() => _bilan = v)),
        if (_bilan) ...[
          SettingChoice(
            label: 'weekly_bilan_day'.tr(lang),
            options: [for (final d in _days) d.tr(lang)],
            index: (_day - 1).clamp(0, 6),
            onChanged: (i) => setState(() => _day = i + 1),
          ),
          SizedBox(height: context.vw(1.5)),
          SettingStepper(
            label: 'weekly_bilan_hour'.tr(lang),
            value: '${_hour}h',
            unit: null,
            onLess: _hour > 6 ? () => setState(() => _hour--) : null,
            onMore: _hour < 23 ? () => setState(() => _hour++) : null,
          ),
        ],
        SettingSave(
          label: 'save'.tr(lang),
          onTap: () async {
            final nav = Navigator.of(context);
            await CoachPersonalityService.instance.setPersonality(
              _type,
              customText: _type == CoachPersonalityType.custom ? _custom.text.trim() : null,
            );
            await WeeklyBilanService.instance.setBilanDay(_day);
            await WeeklyBilanService.instance.setBilanHour(_hour);
            RyzeFeedback.confirm();
            nav.pop();
          },
        ),
      ],
    );
  }
}

/// Les notifications : la maîtresse d'abord, puis ce qu'on veut recevoir.
///
/// Chaque changement est enregistré tout de suite — un interrupteur qui
/// attend un bouton « enregistrer » est un interrupteur qu'on croit avoir
/// actionné.
class NotificationsSheet {
  NotificationsSheet._();

  static Future<void> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<void>(
      context,
      title: 'settings_notifications'.tr(lang),
      builder: (sheet) => const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatefulWidget {
  const _NotificationsBody();

  @override
  State<_NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<_NotificationsBody> {
  late final NotificationPreferences _p = NotificationService().getPreferences();

  Future<void> _save() async {
    setState(() {});
    await NotificationService().savePreferences(_p);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;
    final on = _p.notificationsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingToggle(
          label: 'settings_notif_master'.tr(lang),
          value: on,
          onChanged: (v) {
            _p.notificationsEnabled = v;
            RyzeFeedback.select();
            _save();
          },
        ),
        AnimatedSize(
          duration: RyzeDurations.enter,
          curve: RyzeCurves.out,
          alignment: Alignment.topCenter,
          child: !on
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(color: RyzeColors.line, height: 1),
                    SettingToggle(
                      label: 'settings_notif_meals'.tr(lang),
                      value: _p.mealRemindersEnabled,
                      onChanged: (v) {
                        _p.mealRemindersEnabled = v;
                        RyzeFeedback.select();
                        _save();
                      },
                    ),
                    if (_p.mealRemindersEnabled) ...[
                      SettingStepper(
                        label: 'breakfast'.tr(lang),
                        value: '${_p.breakfastTime}h',
                        unit: null,
                        onLess: _p.breakfastTime > 4 ? () { _p.breakfastTime--; _save(); } : null,
                        onMore: _p.breakfastTime < 12 ? () { _p.breakfastTime++; _save(); } : null,
                      ),
                      SettingStepper(
                        label: 'lunch'.tr(lang),
                        value: '${_p.lunchTime}h',
                        unit: null,
                        onLess: _p.lunchTime > 10 ? () { _p.lunchTime--; _save(); } : null,
                        onMore: _p.lunchTime < 16 ? () { _p.lunchTime++; _save(); } : null,
                      ),
                      SettingStepper(
                        label: 'dinner'.tr(lang),
                        value: '${_p.dinnerTime}h',
                        unit: null,
                        onLess: _p.dinnerTime > 16 ? () { _p.dinnerTime--; _save(); } : null,
                        onMore: _p.dinnerTime < 23 ? () { _p.dinnerTime++; _save(); } : null,
                      ),
                    ],
                    const Divider(color: RyzeColors.line, height: 1),
                    SettingToggle(
                      label: 'settings_notif_water'.tr(lang),
                      hint: 'settings_water_per_day'.tr(lang).replaceAll('{n}', '${_p.waterReminderFrequency}'),
                      value: _p.waterRemindersEnabled,
                      onChanged: (v) {
                        _p.waterRemindersEnabled = v;
                        RyzeFeedback.select();
                        _save();
                      },
                    ),
                    if (_p.waterRemindersEnabled)
                      SettingChoice(
                        options: const ['1', '2', '3', '4'],
                        index: (_p.waterReminderFrequency - 1).clamp(0, 3),
                        onChanged: (i) {
                          _p.waterReminderFrequency = i + 1;
                          RyzeFeedback.select();
                          _save();
                        },
                      ),
                    const Divider(color: RyzeColors.line, height: 1),
                    SettingToggle(
                      label: 'settings_notif_sessions'.tr(lang),
                      value: _p.plannedActivityReminderEnabled,
                      onChanged: (v) {
                        _p.plannedActivityReminderEnabled = v;
                        RyzeFeedback.select();
                        _save();
                      },
                    ),
                    SettingToggle(
                      label: 'settings_notif_streak'.tr(lang),
                      value: _p.streakProtectionEnabled,
                      onChanged: (v) {
                        _p.streakProtectionEnabled = v;
                        RyzeFeedback.select();
                        _save();
                      },
                    ),
                    SettingToggle(
                      label: 'settings_notif_recap'.tr(lang),
                      value: _p.weeklyRecapEnabled,
                      onChanged: (v) {
                        _p.weeklyRecapEnabled = v;
                        RyzeFeedback.select();
                        _save();
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Langue, unités, haptique, début de semaine.
class PreferencesSheet {
  PreferencesSheet._();

  static const languages = ['fr', 'en', 'de'];
  static const _labels = ['Français', 'English', 'Deutsch'];

  static Future<void> show(BuildContext context, {required String lang}) {
    return showRyzeSheet<void>(
      context,
      title: 'settings_preferences'.tr(lang),
      builder: (sheet) => const _PreferencesBody(),
    );
  }
}

class _PreferencesBody extends StatefulWidget {
  const _PreferencesBody();

  @override
  State<_PreferencesBody> createState() => _PreferencesBodyState();
}

class _PreferencesBodyState extends State<_PreferencesBody> {
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final lang = loc.currentLanguageCode;
    final units = UnitService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingChoice(
          label: 'language'.tr(lang),
          options: PreferencesSheet._labels,
          index: PreferencesSheet.languages.indexOf(lang).clamp(0, 2),
          onChanged: (i) async {
            RyzeFeedback.select();
            await loc.setLanguage(PreferencesSheet.languages[i]);
            if (mounted) setState(() {});
          },
        ),
        SizedBox(height: context.vw(3.6)),
        SettingChoice(
          label: 'measurement_system'.tr(lang),
          options: ['metric'.tr(lang), 'imperial'.tr(lang)],
          index: units.isMetric ? 0 : 1,
          onChanged: (i) async {
            RyzeFeedback.select();
            await units.setImperial(i == 1);
            if (mounted) setState(() {});
          },
        ),
        SizedBox(height: context.vw(2.1)),
        const Divider(color: RyzeColors.line, height: 1),
        SettingToggle(
          label: 'haptic_feedback'.tr(lang),
          hint: 'haptic_feedback_subtitle'.tr(lang),
          value: HapticService.instance.isEnabled,
          onChanged: (v) async {
            await HapticService.instance.setEnabled(v);
            if (v) RyzeFeedback.select();
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}
