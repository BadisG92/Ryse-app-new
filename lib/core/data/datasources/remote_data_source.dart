import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../../infrastructure/logging/app_logger.dart';
import '../../infrastructure/network/network_retry_policy.dart';

/// Interface pour toutes les data sources remote
abstract class RemoteDataSource {
  /// Client Supabase
  SupabaseClient get client => SupabaseConfig.client;
  
  /// Logger
  final AppLogger logger = AppLogger.instance;
  
  /// Retry policy
  final NetworkRetryPolicy retryPolicy = NetworkRetryPolicy();
  
  /// Circuit breakers par service
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  
  /// User ID actuel
  String? get currentUserId => client.auth.currentUser?.id;
  
  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUserId != null;
  
  /// Execute une requête avec gestion d'erreur et logging
  Future<T> executeQuery<T>(Future<T> Function() query, {String? operation}) async {
    final opName = operation ?? 'Database query';
    
    try {
      logger.d('Executing: $opName', tag: 'DATA');
      final stopwatch = Stopwatch()..start();
      
      final result = await query();
      
      stopwatch.stop();
      logger.performance(opName, stopwatch.elapsed);
      
      return result;
    } on PostgrestException catch (e) {
      logger.e('Postgres error in $opName', error: e, tag: 'DATA');
      throw DataSourceException(
        message: e.message,
        code: e.code,
        details: e.details,
      );
    } catch (e, stack) {
      logger.e('Unexpected error in $opName', error: e, stackTrace: stack, tag: 'DATA');
      throw DataSourceException(
        message: 'Erreur inattendue: $e',
      );
    }
  }
  
  /// Execute une requête avec retry automatique et circuit breaker
  Future<T> executeWithRetry<T>(
    Future<T> Function() query, {
    String? operation,
    String? serviceName,
  }) async {
    final opName = operation ?? 'Database operation';
    final service = serviceName ?? 'default';
    
    // Obtenir ou créer le circuit breaker pour ce service
    final circuitBreaker = _circuitBreakers.putIfAbsent(
      service,
      () => CircuitBreaker(name: service),
    );
    
    // Exécuter avec circuit breaker et retry policy
    return await circuitBreaker.execute(() async {
      return await retryPolicy.execute(
        () => executeQuery(query, operation: opName),
        operationName: opName,
        shouldRetry: NetworkRetryPolicy.isRetriableError,
        onRetry: (attempt, delay) {
          logger.i('Retrying $opName (attempt $attempt) after ${delay.inMilliseconds}ms', tag: 'RETRY');
        },
      );
    });
  }
  
  /// Helper pour les requêtes de sélection
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? columns,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
  }) async {
    return executeQuery(() async {
      var query = client.from(table).select(columns ?? '*');
      
      // Appliquer les filtres
      filters?.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      
      // Construire et exécuter la requête avec typage strict
      PostgrestFilterBuilder<List<Map<String, dynamic>>> typedQuery = query;
      PostgrestTransformBuilder<List<Map<String, dynamic>>>? transformQuery;
      
      // Appliquer ordre et limite si nécessaire
      if (orderBy != null && limit != null) {
        transformQuery = typedQuery.order(orderBy).limit(limit);
      } else if (orderBy != null) {
        transformQuery = typedQuery.order(orderBy);
      } else if (limit != null) {
        transformQuery = typedQuery.limit(limit);
      }
      
      final result = await (transformQuery ?? typedQuery);
      return List<Map<String, dynamic>>.from(result);
    });
  }
  
  /// Helper pour l'insertion
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return executeQuery(() async {
      final result = await client.from(table).insert(data).select().single();
      return result;
    });
  }
  
  /// Helper pour la mise à jour
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    return executeQuery(() async {
      var query = client.from(table).update(data);
      
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      final result = await query.select().single();
      return result;
    });
  }
  
  /// Helper pour la suppression
  Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    return executeQuery(() async {
      var query = client.from(table).delete();
      
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      await query;
    });
  }
}

/// Exception personnalisée pour les data sources
class DataSourceException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  DataSourceException({
    required this.message,
    this.code,
    this.details,
  });
  
  @override
  String toString() => 'DataSourceException: $message (code: $code)';
  
  /// Vérifie si c'est une erreur réseau
  bool get isNetworkError => code == 'network_error' || message.contains('network');
  
  /// Vérifie si c'est une erreur d'authentification
  bool get isAuthError => code == 'auth_error' || code == '401';
}