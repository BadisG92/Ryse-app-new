import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/haptic_service.dart';

/// What the phone answers with when the user does something.
///
/// Five moments, named after what happens rather than after how strong the
/// buzz is, so a screen never has to decide between `lightImpact` and
/// `selectionClick` on its own:
///
/// - [tap] a control reacted: a glass filled, a tile pressed
/// - [select] something changed without being written: a page, a row opening
/// - [confirm] a sheet or a menu opened
/// - [removed] something was taken back
/// - [success] something was written and counted: a meal logged, a goal met
///
/// Haptics go through the app's existing [HapticService], which already reads
/// the user's preference. The click is the system's own, so it costs no
/// dependency and follows the ring switch on iOS; it is off by default because
/// a tracker used in public should be silent unless asked.
class RyzeFeedback {
  RyzeFeedback._();

  static const String _soundKey = 'ryze_sound_enabled';
  static bool _sound = false;
  static bool _loaded = false;

  /// Read once at start-up, next to `HapticService.initialize()`.
  static Future<void> initialize() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_soundKey) ?? false;
    _loaded = true;
  }

  static bool get soundEnabled => _sound;

  static Future<void> setSoundEnabled(bool on) async {
    _sound = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, on);
  }

  static void _click() {
    if (_sound) SystemSound.play(SystemSoundType.click);
  }

  /// A control reacted under the finger.
  static Future<void> tap() async {
    _click();
    await HapticService.instance.lightImpact();
  }

  /// A choice was made, nothing written yet.
  static Future<void> select() async {
    _click();
    await HapticService.instance.selectionClick();
  }

  /// A sheet, a menu, a page arrived.
  static Future<void> confirm() async {
    await HapticService.instance.mediumImpact();
  }

  /// Something was taken back.
  static Future<void> removed() async {
    await HapticService.instance.mediumImpact();
  }

  /// Something was written and counted. The one moment that earns two beats.
  static Future<void> success() async {
    _click();
    await HapticService.instance.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticService.instance.lightImpact();
  }

  /// Something failed. Never silent, even with sound off.
  static Future<void> failure() async {
    await HapticService.instance.heavyImpact();
  }
}
