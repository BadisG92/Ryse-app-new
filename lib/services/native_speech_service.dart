import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'localization_service.dart';
import 'workout_voice_service.dart'; // Pour réutiliser WorkoutSetData et parsing

/// Service de reconnaissance vocale native iOS
/// Utilise directement le Speech Framework d'Apple pour qualité maximale
class NativeSpeechService {
  static const MethodChannel _methodChannel = MethodChannel('com.ryze.speech/native');
  static const EventChannel _eventChannel = EventChannel('com.ryze.speech/events');

  Stream<Map<String, dynamic>>? _eventStream;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  bool _isListening = false;
  bool get isListening => _isListening;

  Function(String)? _onPartialResult;
  Function(String)? _onFinalResult;
  Function(String)? _onError;

  /// Vérifier si la reconnaissance native est disponible (iOS uniquement)
  static bool get isSupported => Platform.isIOS;

  /// Demander les permissions
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Vérifier si le service est disponible
  Future<bool> isAvailable() async {
    if (!isSupported) return false;

    try {
      final result = await _methodChannel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking availability: $e');
      return false;
    }
  }

  /// Définir la langue de reconnaissance
  Future<void> setLocale(String localeId) async {
    if (!isSupported) return;

    try {
      await _methodChannel.invokeMethod('setLocale', {'localeId': localeId});
      debugPrint('✅ Locale set to: $localeId');
    } catch (e) {
      debugPrint('❌ Error setting locale: $e');
    }
  }

  /// Démarrer l'écoute
  Future<void> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    Function(String)? onError,
  }) async {
    if (!isSupported) {
      onError?.call('Native speech not supported on this platform');
      return;
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return;
    }

    _onPartialResult = onPartialResult;
    _onFinalResult = onFinalResult;
    _onError = onError;

    // Définir la langue selon les paramètres de l'app
    final lang = LocalizationService.instance.currentLanguageCode;
    final localeId = lang == 'fr' ? 'fr_FR' : 'en_US';
    await setLocale(localeId);

    // S'abonner au stream d'événements
    _eventStream = _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });

    _eventSubscription = _eventStream!.listen(
      _handleEvent,
      onError: (error) {
        debugPrint('❌ Event stream error: $error');
        _onError?.call(error.toString());
        stopListening();
      },
    );

    try {
      final result = await _methodChannel.invokeMethod<bool>('startListening');
      if (result == true) {
        _isListening = true;
        debugPrint('✅ Native speech recognition started');
      } else {
        debugPrint('❌ Failed to start listening');
        _onError?.call('Failed to start listening');
      }
    } catch (e) {
      debugPrint('❌ Error starting listening: $e');
      _onError?.call(e.toString());
      await _eventSubscription?.cancel();
      _eventSubscription = null;
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    if (!isSupported || !_isListening) return;

    try {
      await _methodChannel.invokeMethod('stopListening');
      _isListening = false;
      debugPrint('🛑 Native speech recognition stopped');
    } catch (e) {
      debugPrint('❌ Error stopping listening: $e');
    }

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    _onPartialResult = null;
    _onFinalResult = null;
    _onError = null;
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'partial':
        final text = event['text'] as String? ?? '';
        _onPartialResult?.call(text);
        debugPrint('🎤 Partial: "$text"');

      case 'final':
        final text = event['text'] as String? ?? '';
        _onFinalResult?.call(text);
        debugPrint('✅ Final: "$text"');

      case 'error':
        final message = event['message'] as String? ?? 'Unknown error';
        _onError?.call(message);
        debugPrint('❌ Error: $message');
        stopListening();

      case 'availability':
        final available = event['available'] as bool? ?? false;
        debugPrint('🎤 Availability changed: $available');

      default:
        debugPrint('⚠️ Unknown event type: $type');
    }
  }

  /// Libérer les ressources
  void dispose() {
    stopListening();
  }
}

/// Service vocal hybride qui utilise le natif sur iOS et speech_to_text sur Android
class HybridVoiceService {
  final NativeSpeechService _nativeService = NativeSpeechService();
  final WorkoutVoiceService _fallbackService = WorkoutVoiceService();

  bool get isListening => NativeSpeechService.isSupported
      ? _nativeService.isListening
      : _fallbackService.isListening;

  /// Initialiser le service
  Future<bool> initialize() async {
    if (NativeSpeechService.isSupported) {
      // iOS : Utiliser le service natif
      final hasPermission = await _nativeService.requestPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ Permission denied, falling back to speech_to_text');
        return await _fallbackService.initialize();
      }

      final isAvailable = await _nativeService.isAvailable();
      if (!isAvailable) {
        debugPrint('⚠️ Native service not available, falling back to speech_to_text');
        return await _fallbackService.initialize();
      }

      debugPrint('✅ Using native iOS Speech Framework');
      return true;
    } else {
      // Android : Utiliser speech_to_text
      debugPrint('✅ Using speech_to_text (Android)');
      return await _fallbackService.initialize();
    }
  }

  /// Démarrer l'écoute
  Future<void> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
  }) async {
    if (NativeSpeechService.isSupported) {
      // iOS : Service natif
      await _nativeService.startListening(
        onPartialResult: onPartialResult,
        onFinalResult: onFinalResult,
        onError: (error) {
          debugPrint('❌ Native error: $error, falling back');
          // En cas d'erreur, on pourrait fallback vers speech_to_text
        },
      );
    } else {
      // Android : speech_to_text
      await _fallbackService.startListening(
        onPartialResult: onPartialResult,
        onFinalResult: onFinalResult,
      );
    }
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    if (NativeSpeechService.isSupported) {
      await _nativeService.stopListening();
    } else {
      await _fallbackService.stopListening();
    }
  }

  /// Parser l'input vocal (réutilise la logique existante)
  WorkoutSetData? parseVoiceInput(String text) {
    return _fallbackService.parseVoiceInput(text);
  }

  /// Message de confirmation
  String getConfirmationMessage(WorkoutSetData data) {
    return _fallbackService.getConfirmationMessage(data);
  }

  /// Message d'erreur
  String getErrorMessage() {
    return _fallbackService.getErrorMessage();
  }

  /// Feedback vocal
  Future<void> speak(String text) async {
    await _fallbackService.speak(text);
  }

  /// Libérer les ressources
  void dispose() {
    _nativeService.dispose();
    _fallbackService.dispose();
  }
}
