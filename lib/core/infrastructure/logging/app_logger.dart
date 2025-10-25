import 'package:flutter/foundation.dart';
/// Logger professionnel pour l'application
/// Remplace tous les debugPrint() statements
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static AppLogger get instance => _instance;
  
  AppLogger._internal();
  
  // Niveaux de log
  static const int _verbose = 0;
  static const int _debug = 1;
  static const int _info = 2;
  static const int _warning = 3;
  static const int _error = 4;
  static const int _critical = 5;
  
  // Niveau actuel (peut être configuré)
  int _currentLevel = _debug;
  
  // Buffer pour les logs (pour debug et crash reporting)
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  
  // Mode production vs debug
  bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  
  void setLevel(int level) {
    _currentLevel = level;
  }
  
  /// Log verbose (très détaillé)
  void v(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_verbose, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log debug
  void d(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log info
  void i(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning
  void w(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log error
  void e(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log critical (crashes, data loss)
  void c(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(_critical, message, tag: tag, error: error, stackTrace: stackTrace);
    // En production, envoyer aux services de crash reporting
    if (isProduction) {
      _sendToCrashlytics(message, error, stackTrace);
    }
  }
  
  /// Log network (spécial pour les appels API)
  void network(String message, {Map<String, dynamic>? request, Map<String, dynamic>? response}) {
    final details = <String, dynamic>{};
    if (request != null) details['request'] = request;
    if (response != null) details['response'] = response;
    
    _log(_debug, message, tag: 'NETWORK', extra: details);
  }
  
  /// Log performance
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    final message = '$operation took ${duration.inMilliseconds}ms';
    _log(_info, message, tag: 'PERF', extra: metadata);
    
    // Alert si trop lent
    if (duration.inMilliseconds > 1000) {
      w('Slow operation detected: $operation', tag: 'PERF');
    }
  }
  
  void _log(
    int level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (level < _currentLevel) return;
    
    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag ?? _getCallerTag(),
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
    
    // Ajouter au buffer
    _addToBuffer(entry);
    
    // Afficher en console (seulement en debug)
    if (!isProduction) {
      _printToConsole(entry);
    }
  }
  
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }
  
  void _printToConsole(LogEntry entry) {
    final emoji = _getEmoji(entry.level);
    final levelName = _getLevelName(entry.level);
    final timestamp = entry.timestamp.toIso8601String().split('T')[1].split('.')[0];
    
    var output = '$emoji [$timestamp] [${entry.tag}] $levelName: ${entry.message}';
    
    if (entry.error != null) {
      output += '\n    Error: ${entry.error}';
    }
    
    if (entry.stackTrace != null && entry.level >= _error) {
      output += '\n    Stack: ${entry.stackTrace}';
    }
    
    // Utiliser print seulement ici, centralisé
    // ignore: avoid_print
    debugPrint(output);
  }
  
  String _getCallerTag() {
    try {
      final stack = StackTrace.current.toString().split('\n');
      // Trouver l'appelant (skip les frames du logger)
      for (final frame in stack) {
        if (!frame.contains('app_logger.dart') && 
            frame.contains('.dart')) {
          // Extraire le nom du fichier
          final match = RegExp(r'(\w+\.dart)').firstMatch(frame);
          if (match != null) {
            return match.group(1)!.replaceAll('.dart', '').toUpperCase();
          }
        }
      }
    } catch (_) {}
    return 'APP';
  }
  
  String _getEmoji(int level) {
    switch (level) {
      case _verbose: return '🔍';
      case _debug: return '🐛';
      case _info: return '💡';
      case _warning: return '⚠️';
      case _error: return '❌';
      case _critical: return '🔥';
      default: return '📝';
    }
  }
  
  String _getLevelName(int level) {
    switch (level) {
      case _verbose: return 'VERBOSE';
      case _debug: return 'DEBUG';
      case _info: return 'INFO';
      case _warning: return 'WARNING';
      case _error: return 'ERROR';
      case _critical: return 'CRITICAL';
      default: return 'LOG';
    }
  }
  
  void _sendToCrashlytics(String message, dynamic error, StackTrace? stackTrace) {
    // TODO: Intégrer avec Firebase Crashlytics ou Sentry
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  /// Récupère les derniers logs pour debug
  List<String> getRecentLogs({int count = 100}) {
    final logs = _logBuffer.take(count).map((e) => 
      '[${e.timestamp.toIso8601String()}] ${e.tag}: ${e.message}'
    ).toList();
    return logs.reversed.toList();
  }
  
  /// Vide le buffer de logs
  void clearLogs() {
    _logBuffer.clear();
  }
}

/// Entrée de log
class LogEntry {
  final int level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;
  
  LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.extra,
  });
}

/// Extension pour faciliter l'usage
extension LoggerX on Object {
  AppLogger get logger => AppLogger.instance;
}