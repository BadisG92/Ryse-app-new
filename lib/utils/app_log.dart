import 'package:flutter/foundation.dart';

/// Logger sécurisé pour Ryze App
///
/// Les logs ne s'affichent QUE en mode debug (kDebugMode = true).
/// En production (release build), tous les appels sont ignorés → zéro impact performance.
///
/// Usage:
/// ```dart
/// import '../utils/app_log.dart';
///
/// appLog('Message simple');
/// appLog('Message avec tag', tag: 'AUTH');
/// appLogError('Erreur détectée', error: e, stackTrace: st);
/// appLogInfo('Information');
/// appLogSuccess('Opération réussie');
/// appLogWarning('Attention');
/// ```

/// Log standard avec tag optionnel
void appLog(String message, {String tag = ''}) {
  if (kDebugMode) {
    final prefix = tag.isNotEmpty ? '[$tag] ' : '';
    debugPrint('$prefix$message');
  }
}

/// Log d'erreur avec détails (error object + stack trace)
void appLogError(String message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    debugPrint('❌ ERROR: $message');
    if (error != null) debugPrint('   Error: $error');
    if (stackTrace != null) debugPrint('   Stack: $stackTrace');
  }
}

/// Log informatif avec emoji
void appLogInfo(String message) {
  if (kDebugMode) {
    debugPrint('ℹ️ $message');
  }
}

/// Log de succès avec emoji
void appLogSuccess(String message) {
  if (kDebugMode) {
    debugPrint('✅ $message');
  }
}

/// Log d'avertissement avec emoji
void appLogWarning(String message) {
  if (kDebugMode) {
    debugPrint('⚠️ $message');
  }
}

/// Log de debug avec emoji
void appLogDebug(String message) {
  if (kDebugMode) {
    debugPrint('🔍 DEBUG: $message');
  }
}

/// Log de performance avec emoji
void appLogPerf(String message) {
  if (kDebugMode) {
    debugPrint('⚡ PERF: $message');
  }
}

/// Log de data avec emoji
void appLogData(String message) {
  if (kDebugMode) {
    debugPrint('📊 DATA: $message');
  }
}
