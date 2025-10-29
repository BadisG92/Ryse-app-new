import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gestionnaire centralisé d'erreurs Supabase
/// Gère les erreurs réseau et fournit des fallbacks appropriés
class SupabaseErrorHandler {
  /// Vérifie si une erreur est liée à la connectivité réseau
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed to fetch') ||
        errorString.contains('clientexception') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection closed') ||
        error is http.ClientException;
  }

  /// Vérifie si une erreur est temporaire (peut être réessayée)
  static bool isTemporaryError(dynamic error) {
    return isNetworkError(error) ||
        error.toString().contains('timeout') ||
        error.toString().contains('temporarily unavailable');
  }

  /// Exécute une requête Supabase avec gestion d'erreur et retry
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    T? fallbackValue,
    int maxRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts <= maxRetries) {
      try {
        debugPrint('🔄 [$operationName] Tentative ${attempts + 1}/${maxRetries + 1}');
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;

        if (isNetworkError(e)) {
          debugPrint('🌐 [$operationName] Erreur réseau détectée: $e');

          // Si on a épuisé les tentatives ou qu'on a un fallback, on arrête
          if (attempts > maxRetries) {
            if (fallbackValue != null) {
              debugPrint('⚠️ [$operationName] Utilisation de la valeur de fallback après ${attempts} tentatives');
              return fallbackValue;
            }
            debugPrint('❌ [$operationName] Échec définitif après ${attempts} tentatives');
            throw NetworkException(
              message: 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
              originalError: e,
              operationName: operationName,
            );
          }

          // Attendre avant de réessayer
          debugPrint('⏳ [$operationName] Nouvelle tentative dans ${retryDelay.inMilliseconds} ms...');
          await Future.delayed(retryDelay);
        } else {
          // Erreur non-réseau, on ne réessaie pas
          debugPrint('❌ [$operationName] Erreur non-réseau: $e');
          rethrow;
        }
      }
    }

    // Si on arrive ici, c'est qu'on a épuisé les tentatives
    if (fallbackValue != null) {
      debugPrint('⚠️ [$operationName] Utilisation de la valeur de fallback finale');
      return fallbackValue;
    }

    throw lastError;
  }

  /// Log une erreur de manière formatée
  static void logError(String operationName, dynamic error, {StackTrace? stackTrace}) {
    debugPrint('❌ Erreur [$operationName]: $error');
    if (isNetworkError(error)) {
      debugPrint('   Type: Erreur réseau (vérifiez la connexion internet)');
    } else {
      debugPrint('   Type: Erreur serveur ou application');
    }

    if (stackTrace != null && kDebugMode) {
      debugPrint('   Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
    }
  }

  /// Message d'erreur user-friendly en fonction du type d'erreur
  static String getUserFriendlyMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    } else if (error.toString().contains('unauthorized') || error.toString().contains('401')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    } else if (error.toString().contains('forbidden') || error.toString().contains('403')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    } else if (error.toString().contains('not found') || error.toString().contains('404')) {
      return 'Ressource introuvable.';
    } else if (error.toString().contains('500') || error.toString().contains('internal server')) {
      return 'Erreur serveur temporaire. Réessayez dans quelques instants.';
    } else {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}

/// Exception personnalisée pour les erreurs réseau
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;
  final String operationName;

  NetworkException({
    required this.message,
    required this.originalError,
    required this.operationName,
  });

  @override
  String toString() => 'NetworkException [$operationName]: $message';
}
