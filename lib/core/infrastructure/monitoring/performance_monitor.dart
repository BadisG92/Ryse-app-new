import 'dart:async';
import '../logging/app_logger.dart';

/// Moniteur de performance pour diagnostiquer et optimiser l'app
/// Mesure les temps de réponse et identifie les goulots d'étranglement
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;
  
  PerformanceMonitor._internal();
  
  final AppLogger _logger = AppLogger.instance;
  final Map<String, Stopwatch> _activeOperations = {};
  final Map<String, List<Duration>> _operationHistory = {};
  
  /// Démarre le monitoring d'une opération
  void startOperation(String operationName) {
    if (_activeOperations.containsKey(operationName)) {
      _logger.w('⚠️ Opération $operationName déjà en cours', tag: 'PERF');
      return;
    }
    
    final stopwatch = Stopwatch()..start();
    _activeOperations[operationName] = stopwatch;
    _logger.i('⏱️ Début: $operationName', tag: 'PERF');
  }
  
  /// Termine le monitoring d'une opération
  Duration? endOperation(String operationName) {
    final stopwatch = _activeOperations.remove(operationName);
    if (stopwatch == null) {
      _logger.w('⚠️ Opération $operationName non trouvée', tag: 'PERF');
      return null;
    }
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    // Stocker l'historique
    _operationHistory[operationName] ??= [];
    _operationHistory[operationName]!.add(duration);
    
    // Analyser la performance
    _analyzePerformance(operationName, duration);
    
    _logger.performance(operationName, duration);
    return duration;
  }
  
  /// Wrapper pour monitorer automatiquement une fonction
  Future<T> monitor<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      _logger.e('❌ Échec: $operationName', error: e, tag: 'PERF');
      rethrow;
    }
  }
  
  /// Analyse la performance et émet des alertes si nécessaire
  void _analyzePerformance(String operationName, Duration duration) {
    final history = _operationHistory[operationName]!;
    
    // Seuils d'alerte (ajustables selon l'opération)
    final thresholds = _getThresholds(operationName);
    
    if (duration > thresholds.critical) {
      _logger.e('🚨 CRITIQUE: $operationName trop lent (${duration.inMilliseconds}ms)', tag: 'PERF');
    } else if (duration > thresholds.warning) {
      _logger.w('⚠️ LENT: $operationName (${duration.inMilliseconds}ms)', tag: 'PERF');
    } else if (duration < thresholds.excellent) {
      _logger.i('⚡ EXCELLENT: $operationName (${duration.inMilliseconds}ms)', tag: 'PERF');
    } else {
      _logger.i('✅ OK: $operationName (${duration.inMilliseconds}ms)', tag: 'PERF');
    }
    
    // Analyse de tendance (si on a assez d'historique)
    if (history.length >= 3) {
      _analyzeTrend(operationName, history);
    }
  }
  
  /// Analyse les tendances de performance
  void _analyzeTrend(String operationName, List<Duration> history) {
    final recent = history.take(3).toList();
    final avgRecent = recent.fold(Duration.zero, (sum, d) => sum + d) ~/ recent.length;
    
    if (history.length >= 6) {
      final older = history.skip(3).take(3).toList();
      final avgOlder = older.fold(Duration.zero, (sum, d) => sum + d) ~/ older.length;
      
      final improvement = ((avgOlder.inMilliseconds - avgRecent.inMilliseconds) / avgOlder.inMilliseconds * 100);
      
      if (improvement > 20) {
        _logger.i('📈 AMÉLIORATION: $operationName +${improvement.toInt()}%', tag: 'PERF');
      } else if (improvement < -20) {
        _logger.w('📉 DÉGRADATION: $operationName ${improvement.toInt()}%', tag: 'PERF');
      }
    }
  }
  
  /// Seuils de performance par type d'opération
  _PerformanceThresholds _getThresholds(String operationName) {
    // Seuils adaptés selon le type d'opération
    if (operationName.contains('auth') || operationName.contains('login')) {
      return _PerformanceThresholds(
        excellent: const Duration(milliseconds: 500),
        warning: const Duration(milliseconds: 2000),
        critical: const Duration(seconds: 5),
      );
    }
    
    if (operationName.contains('cache') || operationName.contains('storage')) {
      return _PerformanceThresholds(
        excellent: const Duration(milliseconds: 50),
        warning: const Duration(milliseconds: 200),
        critical: const Duration(milliseconds: 500),
      );
    }
    
    if (operationName.contains('api') || operationName.contains('network')) {
      return _PerformanceThresholds(
        excellent: const Duration(milliseconds: 300),
        warning: const Duration(seconds: 1),
        critical: const Duration(seconds: 3),
      );
    }
    
    // Seuils par défaut
    return _PerformanceThresholds(
      excellent: const Duration(milliseconds: 100),
      warning: const Duration(milliseconds: 500),
      critical: const Duration(seconds: 1),
    );
  }
  
  /// Rapport complet de performance
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'active_operations': _activeOperations.keys.toList(),
      'operations_history': <String, dynamic>{},
    };
    
    // Statistiques par opération
    for (final entry in _operationHistory.entries) {
      final operationName = entry.key;
      final history = entry.value;
      
      if (history.isEmpty) continue;
      
      final durations = history.map((d) => d.inMilliseconds).toList()..sort();
      final avg = durations.fold(0, (sum, d) => sum + d) / durations.length;
      final median = durations[durations.length ~/ 2];
      final min = durations.first;
      final max = durations.last;
      
      report['operations_history'][operationName] = {
        'count': history.length,
        'avg_ms': avg.round(),
        'median_ms': median,
        'min_ms': min,
        'max_ms': max,
        'recent_trend': _getTrendDescription(operationName),
      };
    }
    
    return report;
  }
  
  String _getTrendDescription(String operationName) {
    final history = _operationHistory[operationName];
    if (history == null || history.length < 3) return 'insufficient_data';
    
    final recent = history.takeLast(3).map((d) => d.inMilliseconds).toList();
    final trend = (recent.last - recent.first) / recent.first * 100;
    
    if (trend > 10) return 'degrading';
    if (trend < -10) return 'improving';
    return 'stable';
  }
  
  /// Nettoie l'historique ancien pour éviter la surcharge mémoire
  void cleanupHistory({int keepLastN = 10}) {
    for (final key in _operationHistory.keys.toList()) {
      final history = _operationHistory[key]!;
      if (history.length > keepLastN) {
        _operationHistory[key] = history.takeLast(keepLastN).toList();
      }
    }
    
    _logger.i('🧹 Historique nettoyé (gardé $keepLastN dernières mesures)', tag: 'PERF');
  }
  
  /// Reset complet du monitoring
  void reset() {
    _activeOperations.clear();
    _operationHistory.clear();
    _logger.i('🔄 Monitoring reset', tag: 'PERF');
  }
}

class _PerformanceThresholds {
  final Duration excellent;
  final Duration warning;
  final Duration critical;
  
  _PerformanceThresholds({
    required this.excellent,
    required this.warning,
    required this.critical,
  });
}

/// Extensions pour faciliter l'usage
extension PerformanceMonitoringExtensions on Future<T> {
  /// Monitor automatiquement un Future
  Future<T> monitored(String operationName) {
    return PerformanceMonitor.instance.monitor(operationName, () => this);
  }
}

extension ListExtensions<T> on List<T> {
  /// Prend les N derniers éléments
  List<T> takeLast(int n) {
    if (n >= length) return this;
    return sublist(length - n);
  }
}