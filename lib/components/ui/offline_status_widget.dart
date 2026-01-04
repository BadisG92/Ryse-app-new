import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/offline_workout_service.dart';

class OfflineStatusWidget extends StatefulWidget {
  final bool compact;
  
  const OfflineStatusWidget({
    super.key,
    this.compact = false,
  });

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  final OfflineWorkoutService _offlineService = OfflineWorkoutService();
  OfflineStatus? _status;
  
  @override
  void initState() {
    super.initState();
    _listenToStatus();
  }
  
  void _listenToStatus() {
    _offlineService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const SizedBox.shrink();
    }
    
    // Mode compact pour l'affichage dans le header
    if (widget.compact) {
      if (_status!.isOnline && _status!.pendingSessionsCount == 0) {
        // Tout est synchronisé - afficher badge vert
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 14,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                'Synchronisé',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      } else if (!_status!.isOnline) {
        // Mode hors ligne
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Hors ligne',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      } else if (_status!.isSyncing) {
        // Synchronisation en cours
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Synchronisation...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      } else if (_status!.pendingSessionsCount > 0) {
        // Séances en attente
        return GestureDetector(
          onTap: () => _showSyncDetails(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_status!.pendingSessionsCount} en attente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return const SizedBox.shrink();
    }
    
    // Mode complet pour la section musculation
    if (!_status!.isOnline || _status!.pendingSessionsCount > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _status!.isOnline 
              ? Colors.amber.withOpacity(0.1) 
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _status!.isOnline 
                ? Colors.amber.withOpacity(0.3) 
                : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _status!.isOnline ? LucideIcons.clock : LucideIcons.wifiOff,
              size: 20,
              color: _status!.isOnline ? Colors.amber[700] : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status!.isOnline 
                        ? 'Séances en attente de synchronisation'
                        : 'Mode hors ligne activé',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _status!.isOnline ? Colors.amber[700] : Colors.orange,
                    ),
                  ),
                  if (_status!.pendingSessionsCount > 0)
                    Text(
                      '${_status!.pendingSessionsCount} séance${_status!.pendingSessionsCount > 1 ? 's' : ''} à synchroniser',
                      style: TextStyle(
                        fontSize: 12,
                        color: _status!.isOnline 
                            ? Colors.amber[600] 
                            : Colors.orange[700],
                      ),
                    ),
                  if (!_status!.isOnline)
                    Text(
                      'Les séances seront synchronisées automatiquement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                ],
              ),
            ),
            if (_status!.isOnline && _status!.pendingSessionsCount > 0 && !_status!.isSyncing)
              IconButton(
                onPressed: () {
                  _offlineService.forceSynchronization();
                },
                icon: Icon(
                  LucideIcons.refreshCw,
                  size: 20,
                  color: Colors.amber[700],
                ),
                tooltip: 'Forcer la synchronisation',
              ),
            if (_status!.isSyncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
          ],
        ),
      );
    }
    
    // Cache valide et prêt pour le mode hors ligne
    if (_status!.cacheValid) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.circleCheck,
              size: 20,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prêt pour le mode hors ligne',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'Exercices et programmes disponibles hors connexion',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF10B981).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Synchronisation des séances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            if (_status != null && _status!.pendingSessionsCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_status!.pendingSessionsCount} séance${_status!.pendingSessionsCount > 1 ? 's' : ''} en attente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _status!.isOnline 
                                ? 'Prêtes à être synchronisées'
                                : 'Seront synchronisées au retour du réseau',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_status!.isOnline && !_status!.isSyncing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _offlineService.forceSynchronization();
                    },
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    label: const Text('Synchroniser maintenant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (_status!.isSyncing)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Synchronisation en cours...',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Toutes les séances sont synchronisées',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}