import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/cardio_session_models.dart';
import '../../models/hiit_models.dart';
import '../../services/auth_service.dart';
import '../../services/calorie_burn_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'cardio_finish_sheet.dart';

/// Le HIIT en direct.
///
/// Le fond **est** le signal : encre pendant l'effort, papier pendant le
/// repos. On sait où on en est sans lire — utile quand on est à quatre
/// pattes. Le décompte est le seul grand chiffre ; « tour 4 / 12 » dit le
/// reste. Une bascule = une haptique ; la fin = une réussite.
///
/// Un seul chemin de fin : arrêt anticipé et fin naturelle passent par la
/// même feuille de résumé. Les calories viennent de `CalorieBurnService`
/// (l'ancien écran multipliait les minutes par douze) et la durée est celle
/// vraiment écoulée (il traitait des minutes comme des secondes, si bien
/// qu'un HIIT de quinze minutes s'enregistrait à zéro).
class HiitLiveScreen extends StatefulWidget {
  const HiitLiveScreen({super.key, required this.workout});

  final HiitWorkout workout;

  @override
  State<HiitLiveScreen> createState() => _HiitLiveScreenState();
}

class _HiitLiveScreenState extends State<HiitLiveScreen> {
  Timer? _ticker;
  late final DateTime _startedAt = DateTime.now();

  bool _work = true;
  bool _paused = false;
  bool _done = false;
  bool _finishing = false;
  int _round = 1;
  int _remaining = 0;

  /// Les secondes d'effort et de repos réellement faites, pas celles prévues.
  int _elapsedSeconds = 0;

  String get _lang => LocalizationService.instance.currentLanguageCode;

  int get _phaseTotal => _work ? widget.workout.workDuration : widget.workout.restDuration;

  @override
  void initState() {
    super.initState();
    _remaining = widget.workout.workDuration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _paused || _done) return;
    setState(() {
      _elapsedSeconds++;
      if (_remaining > 1) {
        _remaining--;
      } else {
        _next();
      }
    });
  }

  void _next() {
    if (_work) {
      _work = false;
      _remaining = widget.workout.restDuration;
      RyzeFeedback.confirm();
      return;
    }
    if (_round < widget.workout.totalRounds) {
      _round++;
      _work = true;
      _remaining = widget.workout.workDuration;
      RyzeFeedback.confirm();
      return;
    }
    _done = true;
    _ticker?.cancel();
    RyzeFeedback.success();
    // La feuille arrive juste après la frame, sinon elle s'ouvrirait pendant
    // le setState qui vient de nous appeler.
    WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
  }

  void _togglePause() {
    RyzeFeedback.tap();
    setState(() => _paused = !_paused);
  }

  Future<void> _close() async {
    if (_done || _elapsedSeconds < 20) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final lang = _lang;
    final wasPaused = _paused;
    setState(() => _paused = true);
    final choice = await showRyzeSheet<String>(
      context,
      title: 'hiit_leave_title'.tr(lang),
      subtitle: 'hiit_rounds_done'.tr(lang).replaceAll('{n}', '${_round - 1}').replaceAll('{total}', '${widget.workout.totalRounds}'),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.play, label: 'session_continue'.tr(lang), onTap: () => Navigator.pop(sheet, 'stay')),
          RyzeSheetRow(icon: LucideIcons.check, label: 'cardio_finish'.tr(lang), onTap: () => Navigator.pop(sheet, 'finish')),
          RyzeSheetRow(icon: LucideIcons.trash2, label: 'cardio_leave_discard'.tr(lang), danger: true, onTap: () => Navigator.pop(sheet, 'quit')),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'finish':
        await _finish();
      case 'quit':
        Navigator.of(context).pop();
      default:
        setState(() => _paused = wasPaused);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    final lang = _lang;
    final minutes = (_elapsedSeconds / 60).round().clamp(1, 600);
    final kcal = CalorieBurnService.calculateKcal(
      'hiit',
      AuthService().currentUser?.weight ?? 70.0,
      minutes,
      intensity: 'Élevé',
    );
    final roundsDone = _done ? widget.workout.totalRounds : (_round - 1).clamp(0, widget.workout.totalRounds);
    final session = CardioSessionData(
      activityType: 'hiit',
      activityTitle: 'sport_hiit'.tr(lang),
      formatTitle: widget.workout.title,
      startTime: _startedAt,
      endTime: DateTime.now(),
      duration: Duration(seconds: _elapsedSeconds),
      calories: kcal,
    );
    await CardioFinishSheet.show(
      context,
      lang: lang,
      session: session,
      defaultIntensity: 2,
      notes: '${'hiit_session_completed_rounds'.tr(lang)}: $roundsDone/${widget.workout.totalRounds}',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final effort = _work && !_done;
    final bg = effort ? RyzeColors.ink : RyzeColors.paper;
    final fg = effort ? RyzeColors.surf : RyzeColors.ink;
    final mute = effort ? RyzeColors.surf.withValues(alpha: 0.55) : RyzeColors.mute;
    final progress = _phaseTotal > 0 ? (1 - _remaining / _phaseTotal).clamp(0.0, 1.0) : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: effort ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: AnimatedContainer(
          duration: RyzeDurations.fill,
          curve: RyzeCurves.out,
          color: bg,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.vw(5.1), context.vw(2.1), context.vw(5.1), 0),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: _close,
                          child: Container(
                            width: context.vw(9.7),
                            height: context.vw(9.7),
                            decoration: BoxDecoration(
                              color: effort ? RyzeColors.surf.withValues(alpha: 0.12) : RyzeColors.surf,
                              shape: BoxShape.circle,
                              border: effort ? null : Border.all(color: RyzeColors.line),
                            ),
                            child: Icon(LucideIcons.x, size: context.vw(4.6), color: fg),
                          ),
                        ),
                        SizedBox(width: context.vw(3.1)),
                        Expanded(
                          child: Text(
                            widget.workout.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: fg),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _done
                        ? 'hiit_session_finished'.tr(lang)
                        : (_paused ? 'cardio_pause_label'.tr(lang) : (effort ? 'hiit_session_effort'.tr(lang) : 'hiit_session_rest'.tr(lang))),
                    style: RyzeText.body(context, 4.6, weight: FontWeight.w600, color: effort ? RyzeColors.acc : RyzeColors.accInk),
                  ),
                  SizedBox(height: context.vw(1)),
                  RollingNumber(
                    '$_remaining',
                    style: RyzeText.display(context, 26, weight: FontWeight.w600).copyWith(color: fg, height: 1),
                  ),
                  SizedBox(height: context.vw(2.6)),
                  Text(
                    'hiit_round_of'.tr(lang).replaceAll('{n}', '$_round').replaceAll('{total}', '${widget.workout.totalRounds}'),
                    style: RyzeText.body(context, 3.6, color: mute).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  SizedBox(height: context.vw(4.1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.vw(14)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(RyzeRadius.pill),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(color: effort ? RyzeColors.surf.withValues(alpha: 0.18) : RyzeColors.idle),
                            FractionallySizedBox(
                              widthFactor: progress,
                              heightFactor: 1,
                              child: Container(color: RyzeColors.acc),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(context.vw(5.1), 0, context.vw(5.1), context.vw(4.1)),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Control(
                            label: _paused ? 'cardio_resume'.tr(lang) : 'cardio_pause_label'.tr(lang),
                            icon: _paused ? LucideIcons.play : LucideIcons.pause,
                            effort: effort,
                            onTap: _done ? null : _togglePause,
                          ),
                        ),
                        SizedBox(width: context.vw(3.1)),
                        Expanded(
                          flex: 2,
                          child: _Control(
                            label: 'cardio_finish'.tr(lang),
                            icon: LucideIcons.check,
                            effort: effort,
                            filled: true,
                            onTap: _finish,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.label, required this.icon, required this.effort, required this.onTap, this.filled = false});

  final String label;
  final IconData icon;
  final bool effort;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (filled) {
      bg = effort ? RyzeColors.surf : RyzeColors.ink;
      fg = effort ? RyzeColors.ink : RyzeColors.surf;
    } else {
      bg = effort ? RyzeColors.surf.withValues(alpha: 0.12) : RyzeColors.surf;
      fg = effort ? RyzeColors.surf : RyzeColors.ink;
    }
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: RyzeDurations.fill,
        height: context.vw(13.3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
          border: !filled && !effort ? Border.all(color: RyzeColors.line) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.vw(4.1), color: onTap == null ? fg.withValues(alpha: 0.4) : fg),
            SizedBox(width: context.vw(2.1)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: onTap == null ? fg.withValues(alpha: 0.4) : fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
