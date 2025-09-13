import 'dart:async';
import 'dart:math';
import '../logging/app_logger.dart';

/// Politique de retry intelligent pour les appels réseau
class NetworkRetryPolicy {
  final AppLogger _logger = AppLogger.instance;
  
  // Configuration par défaut
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool useJitter;
  
  NetworkRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });
  
  /// Exécute une fonction avec retry automatique
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    operationName ??= 'Network operation';
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.d('$operationName - Attempt $attempt/$maxAttempts', tag: 'RETRY');
        
        // Mesurer la performance
        final stopwatch = Stopwatch()..start();
        final result = await operation();
        stopwatch.stop();
        
        _logger.performance(operationName, stopwatch.elapsed);
        
        return result;
      } catch (error, stackTrace) {
        final isLastAttempt = attempt == maxAttempts;
        
        // Vérifier si on doit réessayer
        if (isLastAttempt || (shouldRetry != null && !shouldRetry(error))) {
          _logger.e(
            '$operationName failed after $attempt attempts',
            error: error,
            stackTrace: stackTrace,
            tag: 'RETRY',
          );
          rethrow;
        }
        
        // Calculer le délai avant le prochain essai
        final delay = _calculateDelay(attempt);
        
        _logger.w(
          '$operationName failed (attempt $attempt), retrying in ${delay.inMilliseconds}ms',
          error: error,
          tag: 'RETRY',
        );
        
        // Callback optionnel
        onRetry?.call(attempt, delay);
        
        // Attendre avant de réessayer
        await Future.delayed(delay);
      }
    }
    
    // Ne devrait jamais arriver, mais pour la sécurité du type
    throw Exception('$operationName failed after $maxAttempts attempts');
  }
  
  /// Calcule le délai avec exponential backoff et jitter
  Duration _calculateDelay(int attempt) {
    // Exponential backoff: delay = initialDelay * (multiplier ^ attempt)
    var delayMs = initialDelay.inMilliseconds * pow(backoffMultiplier, attempt - 1);
    
    // Limiter au délai maximum
    delayMs = min(delayMs, maxDelay.inMilliseconds.toDouble());
    
    // Ajouter du jitter pour éviter le "thundering herd"
    if (useJitter) {
      final jitter = Random().nextDouble() * 0.3; // ±30% de variation
      delayMs = delayMs * (0.85 + jitter); // Entre 85% et 115% du délai
    }
    
    return Duration(milliseconds: delayMs.round());
  }
  
  /// Détermine si une erreur est retriable
  static bool isRetriableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Erreurs réseau retriables
    final retriablePatterns = [
      'network',
      'timeout',
      'connection',
      'socket',
      'unreachable',
      'temporary',
      '503', // Service Unavailable
      '504', // Gateway Timeout
      '429', // Too Many Requests
      'rate limit',
    ];
    
    for (final pattern in retriablePatterns) {
      if (errorString.contains(pattern)) {
        return true;
      }
    }
    
    // Erreurs non-retriables
    final nonRetriablePatterns = [
      '400', // Bad Request
      '401', // Unauthorized
      '403', // Forbidden
      '404', // Not Found
      'invalid',
      'malformed',
      'authentication',
      'permission',
    ];
    
    for (final pattern in nonRetriablePatterns) {
      if (errorString.contains(pattern)) {
        return false;
      }
    }
    
    // Par défaut, on réessaye
    return true;
  }
}

/// Circuit breaker pour éviter de surcharger un service défaillant
class CircuitBreaker {
  final AppLogger _logger = AppLogger.instance;
  
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;
  
  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 60),
    this.halfOpenTimeout = const Duration(seconds: 10),
  });
  
  /// Exécute une opération avec protection circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Vérifier l'état du circuit
    switch (_state) {
      case CircuitBreakerState.open:
        // Circuit ouvert, rejeter immédiatement ou passer en half-open
        if (!_shouldAttemptReset()) {
          throw CircuitBreakerOpenException(
            'Circuit breaker $name is OPEN (failures: $_failureCount)',
          );
        }
        _state = CircuitBreakerState.halfOpen;
        _logger.i('Circuit breaker $name: HALF-OPEN', tag: 'CIRCUIT');
        // Continuer avec halfOpen ci-dessous
        continue halfOpen;
        
      halfOpen:
      case CircuitBreakerState.halfOpen:
        // État half-open, tester avec timeout court
        try {
          final result = await operation().timeout(halfOpenTimeout);
          _onSuccess();
          return result;
        } catch (e) {
          _onFailure();
          rethrow;
        }
        
      case CircuitBreakerState.closed:
        // Circuit fermé, opération normale
        try {
          final result = await operation();
          _onSuccess();
          return result;
        } catch (e) {
          _onFailure();
          rethrow;
        }
    }
  }
  
  void _onSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      // Succès en half-open, fermer le circuit
      _logger.i('Circuit breaker $name: CLOSED (recovered)', tag: 'CIRCUIT');
      _state = CircuitBreakerState.closed;
      _failureCount = 0;
      _resetTimer?.cancel();
    }
  }
  
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold && _state != CircuitBreakerState.open) {
      // Ouvrir le circuit
      _logger.w(
        'Circuit breaker $name: OPEN (failures: $_failureCount)',
        tag: 'CIRCUIT',
      );
      _state = CircuitBreakerState.open;
      
      // Programmer la réinitialisation
      _resetTimer?.cancel();
      _resetTimer = Timer(resetTimeout, () {
        _state = CircuitBreakerState.halfOpen;
        _logger.i('Circuit breaker $name: HALF-OPEN (timeout)', tag: 'CIRCUIT');
      });
    }
  }
  
  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return true;
    
    final elapsed = DateTime.now().difference(_lastFailureTime!);
    return elapsed >= resetTimeout;
  }
  
  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
  
  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
    _logger.i('Circuit breaker $name: RESET', tag: 'CIRCUIT');
  }
  
  void dispose() {
    _resetTimer?.cancel();
  }
}

enum CircuitBreakerState {
  closed, // Normal, laisse passer
  open, // Bloque les requêtes
  halfOpen, // Test de récupération
}

class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}