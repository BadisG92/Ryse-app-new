import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Vérification du statut de la permission caméra...');
    final status = await Permission.camera.status;
    if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Statut initial: $status');

    if (status.isDenied || status.isRestricted) {
      if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Permission refusée/restreinte, demande en cours...');
      final result = await Permission.camera.request();
      if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Résultat de la demande: $result');
      return result == PermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Permission définitivement refusée, ouverture des paramètres...');
      await openAppSettings();
      return false;
    }

    if (kDebugMode) debugPrint('🔍 [DEBUG PERMISSION] Permission déjà accordée: ${status.isGranted}');
    return status.isGranted;
  }

  static Future<void> checkAndRequestPermissions() async {
    // Vérifier et demander la permission caméra
    await requestCameraPermission();

    // Vous pouvez ajouter d'autres permissions ici si nécessaire
    // await Permission.photos.request();
    // await Permission.location.request();
  }
}