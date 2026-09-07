import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../design/feedback.dart';
import '../../services/localization_service.dart';
import '../../services/native_speech_service.dart';
import '../../services/translations.dart';
import '../../services/workout_voice_service.dart';

/// Dicter une série : « douze reps, soixante kilos ».
///
/// C'est le chemin vocal par série de l'ancien écran, le seul qui vivait,
/// sorti de ses 5 000 lignes. Le service natif est construit au premier tap
/// sur le micro — pas à l'ouverture de la séance, où il instanciait les
/// plugins de parole avant qu'on sache si on s'en servirait.
class SessionVoice extends ChangeNotifier {
  SessionVoice({required this.onFilled});

  /// La série est comprise : reps, et poids en kilos s'il a été dit.
  final void Function(int setIndex, int? reps, double? weightKg) onFilled;

  HybridVoiceService? _service;
  bool _ready = false;
  bool listening = false;
  bool _processing = false;
  int? setIndex;
  String heard = '';
  int _retries = 0;
  static const _maxRetries = 3;
  Timer? _autoStop;
  DateTime? _lastValid;

  /// Vrai si le micro a répondu. Faux : le pavé reste, la barre le dit.
  Future<bool> start(int index) async {
    _service ??= HybridVoiceService();
    if (!_ready) {
      try {
        _ready = await _service!.initialize();
      } catch (_) {
        _ready = false;
      }
      if (!_ready) return false;
    }

    _processing = false;
    _autoStop?.cancel();
    _lastValid = null;
    setIndex = index;
    heard = '';
    listening = true;
    RyzeFeedback.confirm();
    notifyListeners();

    await _service!.startListening(
      onPartialResult: (text) {
        heard = text;
        notifyListeners();
        final parsed = _service!.parseVoiceInput(text);
        if (parsed != null && parsed.hasData) {
          final now = DateTime.now();
          if (_lastValid == null || now.difference(_lastValid!).inMilliseconds > 1000) {
            _lastValid = now;
            _autoStop?.cancel();
            // Une seconde et demie de silence après une série comprise : on
            // arrête sans attendre que l'utilisateur le fasse.
            _autoStop = Timer(const Duration(milliseconds: 1500), () {
              if (listening && !_processing) unawaited(stop());
            });
          }
        }
      },
      onFinalResult: (text) async {
        if (_processing) return;
        _processing = true;
        heard = text;
        notifyListeners();
        _autoStop?.cancel();
        await stop();
        _processing = false;
      },
    );
    return true;
  }

  Future<void> stop() async {
    _processing = false;
    _autoStop?.cancel();
    _lastValid = null;
    final service = _service;
    final index = setIndex;
    if (service == null) return;
    try {
      await service.stopListening();
    } catch (_) {}

    final WorkoutSetData? data = service.parseVoiceInput(heard);
    if (data != null && data.hasData && index != null) {
      _retries = 0;
      onFilled(index, data.reps, data.weight);
      unawaited(service.speak(service.getConfirmationMessage(data)));
      RyzeFeedback.success();
      _reset();
      return;
    }

    _retries++;
    if (_retries < _maxRetries) {
      final lang = LocalizationService.instance.currentLanguageCode;
      unawaited(service.speak('did_not_understand_retry'.tr(lang)));
      listening = false;
      notifyListeners();
      return;
    }
    _retries = 0;
    unawaited(service.speak(service.getErrorMessage()));
    RyzeFeedback.failure();
    _reset();
  }

  void cancel() {
    _autoStop?.cancel();
    unawaited(_service?.stopListening());
    _reset();
  }

  void _reset() {
    listening = false;
    heard = '';
    setIndex = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoStop?.cancel();
    try {
      _service?.dispose();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [VOICE] dispose: $e');
    }
    super.dispose();
  }
}
