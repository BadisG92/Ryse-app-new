/// Base repository interface pour toutes les entités
abstract class BaseRepository<T> {
  /// Récupère une entité par son ID
  Future<T?> getById(String id);
  
  /// Récupère toutes les entités
  Future<List<T>> getAll();
  
  /// Sauvegarde une entité (create ou update)
  Future<T> save(T entity);
  
  /// Supprime une entité
  Future<bool> delete(String id);
  
  /// Observe les changements d'une entité
  Stream<T?> watchById(String id);
  
  /// Observe les changements de toutes les entités
  Stream<List<T>> watchAll();
}

/// Repository Result pour gérer les succès/erreurs
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final bool isFromCache;
  
  const RepositoryResult.success(this.data, {this.isFromCache = false})
      : error = null,
        isSuccess = true;
        
  const RepositoryResult.failure(this.error)
      : data = null,
        isSuccess = false,
        isFromCache = false;
        
  /// Permet de mapper le résultat
  RepositoryResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return RepositoryResult.success(mapper(data as T), isFromCache: isFromCache);
    }
    return RepositoryResult.failure(error);
  }
}