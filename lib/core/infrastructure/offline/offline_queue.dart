import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logging/app_logger.dart';

/// Queue pour gérer les opérations offline
/// Stocke les actions et les synchronise quand la connexion revient
class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._internal();
  static OfflineQueue get instance => _instance;
  
  OfflineQueue._internal();
  
  final AppLogger _logger = AppLogger.instance;
  
  // Queue des opérations en attente
  final List<QueuedOperation> _queue = [];
  
  // État de la connexion
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Timer pour le retry
  Timer? _retryTimer;
  
  // Callbacks pour notifier l'UI
  final _statusController = StreamController<QueueStatus>.broadcast();
  Stream<QueueStatus> get statusStream => _statusController.stream;
  
  /// Initialise la queue offline
  Future<void> initialize() async {
    _logger.i('Initializing offline queue');
    
    // Charger les opérations sauvegardées
    await _loadPersistedQueue();
    
    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      
      _logger.i('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      
      if (wasOffline && _isOnline) {
        _logger.i('Back online, processing queue');
        _processQueue();
      }
      
      _notifyStatus();
    });
    
    // Vérifier la connexion initiale
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult.any((result) => result != ConnectivityResult.none);
    
    if (_isOnline && _queue.isNotEmpty) {
      _processQueue();
    }
  }
  
  /// Ajoute une opération à la queue
  Future<String> enqueue(QueuedOperation operation) async {
    _logger.d('Enqueuing operation: ${operation.type}', tag: 'QUEUE');
    
    _queue.add(operation);
    await _persistQueue();
    
    _notifyStatus();
    
    // Si online, traiter immédiatement
    if (_isOnline) {
      _processQueue();
    }
    
    return operation.id;
  }
  
  /// Traite la queue
  Future<void> _processQueue() async {
    if (_queue.isEmpty) return;
    
    _logger.i('Processing ${_queue.length} queued operations');
    
    final toProcess = List<QueuedOperation>.from(_queue);
    
    for (final operation in toProcess) {
      if (operation.attempts >= operation.maxAttempts) {
        _logger.w('Operation ${operation.id} exceeded max attempts, removing from queue');
        _queue.remove(operation);
        continue;
      }
      
      try {
        _logger.d('Processing operation ${operation.id} (attempt ${operation.attempts + 1})');
        
        // Exécuter l'opération
        final success = await _executeOperation(operation);
        
        if (success) {
          _logger.i('Operation ${operation.id} completed successfully');
          _queue.remove(operation);
        } else {
          _handleFailedOperation(operation);
        }
      } catch (e, stack) {
        _logger.e('Error processing operation ${operation.id}', error: e, stackTrace: stack);
        _handleFailedOperation(operation);
      }
    }
    
    await _persistQueue();
    _notifyStatus();
  }
  
  /// Exécute une opération
  Future<bool> _executeOperation(QueuedOperation operation) async {
    switch (operation.type) {
      case OperationType.addFood:
        return await _executeAddFood(operation);
      case OperationType.addWater:
        return await _executeAddWater(operation);
      case OperationType.updateProfile:
        return await _executeUpdateProfile(operation);
      case OperationType.syncData:
        return await _executeSyncData(operation);
      default:
        _logger.w('Unknown operation type: ${operation.type}');
        return false;
    }
  }
  
  Future<bool> _executeAddFood(QueuedOperation operation) async {
    try {
      // TODO: Appeler le repository pour ajouter la nourriture
      // final repository = NutritionRepositoryImpl.instance;
      // final result = await repository.addFoodEntry(...);
      // return result.isSuccess;
      
      // Pour l'instant, simuler
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _logger.e('Failed to add food', error: e);
      return false;
    }
  }
  
  Future<bool> _executeAddWater(QueuedOperation operation) async {
    try {
      // TODO: Implémenter
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _logger.e('Failed to add water', error: e);
      return false;
    }
  }
  
  Future<bool> _executeUpdateProfile(QueuedOperation operation) async {
    try {
      // TODO: Implémenter
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _logger.e('Failed to update profile', error: e);
      return false;
    }
  }
  
  Future<bool> _executeSyncData(QueuedOperation operation) async {
    try {
      // TODO: Implémenter la sync complète
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      _logger.e('Failed to sync data', error: e);
      return false;
    }
  }
  
  /// Gère une opération échouée
  void _handleFailedOperation(QueuedOperation operation) {
    operation.attempts++;
    operation.lastAttempt = DateTime.now();
    
    // Calculer le délai avant le prochain essai (exponential backoff)
    final delay = _calculateBackoffDelay(operation.attempts);
    
    _logger.d('Operation ${operation.id} failed, retry in ${delay.inSeconds}s');
    
    // Programmer le retry
    _scheduleRetry(delay);
  }
  
  /// Calcule le délai de backoff exponentiel
  Duration _calculateBackoffDelay(int attempts) {
    // 2^attempts secondes, max 5 minutes
    final seconds = (2 << (attempts - 1)).clamp(1, 300);
    return Duration(seconds: seconds);
  }
  
  /// Programme un retry
  void _scheduleRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_isOnline) {
        _processQueue();
      }
    });
  }
  
  /// Persiste la queue sur le disque
  Future<void> _persistQueue() async {
    try {
      // TODO: Utiliser Hive ou SharedPreferences pour persister
      // Pour l'instant, utiliser SharedPreferences
      // final data = _queue.map((op) => op.toJson()).toList();
      // await prefs.setString('offline_queue', jsonEncode(data));
      _logger.v('Queue persisted with ${_queue.length} operations');
    } catch (e) {
      _logger.e('Failed to persist queue', error: e);
    }
  }
  
  /// Charge la queue depuis le disque
  Future<void> _loadPersistedQueue() async {
    try {
      // TODO: Charger depuis Hive ou SharedPreferences
      _logger.v('Loading persisted queue');
    } catch (e) {
      _logger.e('Failed to load persisted queue', error: e);
    }
  }
  
  /// Notifie les changements de statut
  void _notifyStatus() {
    final status = QueueStatus(
      isOnline: _isOnline,
      pendingOperations: _queue.length,
      operations: List.unmodifiable(_queue),
    );
    _statusController.add(status);
  }
  
  /// Nettoie les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _statusController.close();
  }
  
  /// Vide la queue (pour debug/test)
  Future<void> clearQueue() async {
    _queue.clear();
    await _persistQueue();
    _notifyStatus();
    _logger.i('Queue cleared');
  }
  
  /// Récupère le statut actuel
  QueueStatus get currentStatus => QueueStatus(
    isOnline: _isOnline,
    pendingOperations: _queue.length,
    operations: List.unmodifiable(_queue),
  );
}

/// Opération en queue
class QueuedOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  DateTime? lastAttempt;
  int attempts;
  final int maxAttempts;
  
  QueuedOperation({
    String? id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.lastAttempt,
    this.attempts = 0,
    this.maxAttempts = 5,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'lastAttempt': lastAttempt?.toIso8601String(),
    'attempts': attempts,
    'maxAttempts': maxAttempts,
  };
  
  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
    id: json['id'],
    type: OperationType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => OperationType.unknown,
    ),
    data: json['data'],
    createdAt: DateTime.parse(json['createdAt']),
    lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt']) : null,
    attempts: json['attempts'] ?? 0,
    maxAttempts: json['maxAttempts'] ?? 5,
  );
}

/// Types d'opérations
enum OperationType {
  addFood,
  addWater,
  updateProfile,
  deleteFood,
  updateWorkout,
  syncData,
  unknown,
}

/// Statut de la queue
class QueueStatus {
  final bool isOnline;
  final int pendingOperations;
  final List<QueuedOperation> operations;
  
  const QueueStatus({
    required this.isOnline,
    required this.pendingOperations,
    required this.operations,
  });
}