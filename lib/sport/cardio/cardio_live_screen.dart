import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/design.dart';
import '../../models/cardio_session_models.dart';
import '../../services/auth_service.dart';
import '../../services/cardio_calculator.dart';
import '../../services/localization_service.dart';
import '../../services/location_service.dart';
import '../../services/pedometer_service.dart';
import '../../services/translations.dart';
import '../../services/unit_service.dart';
import 'cardio_finish_sheet.dart';

/// Une séance cardio en direct.
///
/// Une activité en cours occupe tout l'écran sur l'encre — le langage établi
/// par le viseur des caméras : un seul chiffre qui mène, une ligne
/// d'indication, rien d'autre. Le temps est ce chiffre ; distance, allure et
/// kcal sont trois valeurs tabulaires dessous.
///
/// Deux choses changent par rapport à l'ancien écran. La pause ne coupe plus
/// le GPS : le flux continue, on suspend seulement le chronomètre et on
/// retranche à la reprise la distance dérivée pendant l'arrêt — reprendre
/// n'attend donc aucune réacquisition. Et il n'y a plus de simulateur : sans
/// GPS l'écran le dit et compte le temps, il n'invente pas de kilomètres.
class CardioLiveScreen extends StatefulWidget {
  const CardioLiveScreen({
    super.key,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    this.objective,
  });

  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final CardioObjective? objective;

  @override
  State<CardioLiveScreen> createState() => _CardioLiveScreenState();
}

class _CardioLiveScreenState extends State<CardioLiveScreen> {
  final PedometerService _pedometer = PedometerService();
  StreamSubscription<LocationPoint>? _points;
  Timer? _ticker;

  late final DateTime _startedAt = DateTime.now();
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStart;

  bool _gps = false;
  bool _gpsAsked = false;
  bool _steps = false;
  bool _paused = false;
  bool _finishing = false;

  /// La distance parcourue pendant les pauses, retranchée du total GPS.
  double _drift = 0;
  double _distanceAtPause = 0;

  double _distance = 0;
  double _speed = 0;
  int _stepCount = 0;

  Duration get _elapsed => _segmentStart == null ? _accumulated : _accumulated + DateTime.now().difference(_segmentStart!);

  String get _lang => LocalizationService.instance.currentLanguageCode;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _points?.cancel();
    LocationService.stopLocationTracking();
    if (_steps) _pedometer.stopTracking();
    super.dispose();
  }

  Future<void> _start() async {
    _segmentStart = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    if (widget.activityType == 'walking') {
      try {
        _steps = await _pedometer.startTracking();
      } catch (_) {
        _steps = false;
      }
    }

    try {
      LocationService.clearRoute();
      final ok = await LocationService.checkAndRequestPermissions();
      if (ok) {
        final started = await LocationService.startLocationTracking();
        if (started) {
          _gps = true;
          _points = LocationService.locationStream?.listen((_) {});
        }
      }
    } catch (_) {
      _gps = false;
    }
    if (mounted) setState(() => _gpsAsked = true);
  }

  void _tick() {
    if (!mounted) return;
    if (!_paused && _gps) {
      final raw = LocationService.calculateTotalDistance();
      _distance = (raw - _drift).clamp(0, double.infinity);
      _speed = LocationService.calculateAverageSpeed();
    }
    if (!_paused && _steps) {
      _stepCount = _pedometer.getSessionSteps();
    }
    setState(() {});
    _checkTarget();
  }

  int get _kcal {
    if (_elapsed.inSeconds < 30) return 0;
    return CardioCalculator.calculateCalories(
      activityType: widget.activityType,
      duration: _elapsed,
      averageSpeed: _gps ? _speed : null,
      distance: _gps ? _distance : null,
      userWeight: AuthService().currentUser?.weight ?? 70.0,
    );
  }

  bool _targetAnnounced = false;

  void _checkTarget() {
    final o = widget.objective;
    if (o == null || _targetAnnounced) return;
    final progress = CardioCalculator.calculateObjectiveProgress(
      objective: o,
      currentDistance: _distance,
      currentDuration: _elapsed,
    );
    if (progress >= 1) {
      _targetAnnounced = true;
      RyzeFeedback.success();
    }
  }

  void _togglePause() {
    RyzeFeedback.tap();
    setState(() {
      if (_paused) {
        // Ce qui a dérivé pendant l'arrêt ne compte pas ; le flux, lui, n'a
        // jamais été coupé, donc rien à réacquérir.
        if (_gps) _drift += LocationService.calculateTotalDistance() - _distanceAtPause;
        _segmentStart = DateTime.now();
        _paused = false;
      } else {
        _accumulated = _elapsed;
        _segmentStart = null;
        if (_gps) _distanceAtPause = LocationService.calculateTotalDistance();
        _paused = true;
      }
    });
  }

  Future<void> _close() async {
    final lang = _lang;
    if (_elapsed.inSeconds < 30) {
      Navigator.of(context).pop();
      return;
    }
    final choice = await showRyzeSheet<String>(
      context,
      title: 'cardio_leave_title'.tr(lang),
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
        return;
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    final now = DateTime.now();
    final session = CardioSessionData(
      activityType: widget.activityType,
      activityTitle: widget.activityTitle,
      formatTitle: widget.formatTitle,
      startTime: _startedAt,
      endTime: now,
      duration: _elapsed,
      distance: _gps ? _distance : 0,
      targetDistance: widget.objective?.targetDistance,
      targetDuration: widget.objective?.targetDuration,
      route: _gps ? LocationService.currentRoute : const [],
      averageSpeed: _gps ? _speed : 0,
      steps: _stepCount,
      calories: _kcal,
    );
    await CardioFinishSheet.show(context, lang: _lang, session: session);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final units = UnitService.instance;
    final o = widget.objective;
    final progress = o == null
        ? null
        : CardioCalculator.calculateObjectiveProgress(objective: o, currentDistance: _distance, currentDuration: _elapsed);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: RyzeColors.ink,
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
                            color: RyzeColors.surf.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.x, size: context.vw(4.6), color: RyzeColors.surf),
                        ),
                      ),
                      SizedBox(width: context.vw(3.1)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.activityTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: RyzeColors.surf)),
                            Text(
                              _gpsLine(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RyzeText.body(context, 3.1, color: _gps ? RyzeColors.acc : RyzeColors.surf.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                RollingNumber(
                  _hms(_elapsed),
                  style: RyzeText.display(context, 17, weight: FontWeight.w600).copyWith(color: RyzeColors.surf, height: 1),
                ),
                if (progress != null) ...[
                  SizedBox(height: context.vw(3.6)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.vw(14)),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(RyzeRadius.pill),
                          child: SizedBox(
                            height: 4,
                            child: Stack(
                              children: [
                                Container(color: RyzeColors.surf.withValues(alpha: 0.18)),
                                FractionallySizedBox(widthFactor: progress, heightFactor: 1, child: Container(color: RyzeColors.acc)),
                              ],
                            ),
                          ),
                        ),
                        if (progress >= 1) ...[
                          SizedBox(height: context.vw(1.5)),
                          Text('cardio_target_reached'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.acc)),
                        ],
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(5.1)),
                  child: Row(
                    children: [
                      if (_gps)
                        Expanded(
                          child: _Metric(
                            value: units.displayDistance(_distance).toStringAsFixed(2),
                            label: units.distanceUnit,
                          ),
                        ),
                      if (_gps)
                        Expanded(
                          child: _Metric(value: _pace(units), label: 'cardio_pace'.tr(lang)),
                        ),
                      if (_steps)
                        Expanded(
                          child: _Metric(value: '$_stepCount', label: 'cardio_steps_label'.tr(lang)),
                        ),
                      Expanded(
                        child: _Metric(value: '$_kcal', label: 'nutri_kcal'.tr(lang), amber: true),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.vw(7)),
                Padding(
                  padding: EdgeInsets.fromLTRB(context.vw(5.1), 0, context.vw(5.1), context.vw(4.1)),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Control(
                          label: _paused ? 'cardio_resume'.tr(lang) : 'cardio_pause_label'.tr(lang),
                          icon: _paused ? LucideIcons.play : LucideIcons.pause,
                          onTap: _togglePause,
                        ),
                      ),
                      SizedBox(width: context.vw(3.1)),
                      Expanded(
                        flex: 2,
                        child: _Control(
                          label: 'cardio_finish'.tr(lang),
                          icon: LucideIcons.check,
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
    );
  }

  String _gpsLine(String lang) {
    if (_paused) return 'cardio_pause_label'.tr(lang);
    if (!_gpsAsked) return 'cardio_gps_searching'.tr(lang);
    if (!_gps) return 'cardio_no_gps'.tr(lang);
    return widget.formatTitle.isEmpty ? 'cardio_gps_on'.tr(lang) : widget.formatTitle;
  }

  /// L'allure, en minutes par unité de distance — le chiffre que lit un
  /// coureur. Sans vitesse crédible, un tiret plutôt qu'un nombre inventé.
  String _pace(UnitService units) {
    final d = units.displayDistance(_distance);
    if (d <= 0.05 || _elapsed.inSeconds < 30) return '—';
    final secondsPerUnit = _elapsed.inSeconds / d;
    if (secondsPerUnit > 3600) return '—';
    final m = secondsPerUnit ~/ 60;
    final s = (secondsPerUnit % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}";
  }

  static String _hms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.amber = false});

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
            color: amber ? RyzeColors.acc : RyzeColors.surf,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(label, maxLines: 1, style: RyzeText.body(context, 2.9, color: RyzeColors.surf.withValues(alpha: 0.55))),
      ],
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.label, required this.icon, required this.onTap, this.filled = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: context.vw(13.3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? RyzeColors.surf : RyzeColors.surf.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(RyzeRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.vw(4.1), color: filled ? RyzeColors.ink : RyzeColors.surf),
            SizedBox(width: context.vw(2.1)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: filled ? RyzeColors.ink : RyzeColors.surf),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
