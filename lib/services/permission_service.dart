import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    print('🔍 [DEBUG PERMISSION] Vérification du statut de la permission caméra...');
    final status = await Permission.camera.status;
    print('🔍 [DEBUG PERMISSION] Statut initial: $status');

    if (status.isDenied || status.isRestricted) {
      print('🔍 [DEBUG PERMISSION] Permission refusée/restreinte, demande en cours...');
      final result = await Permission.camera.request();
      print('🔍 [DEBUG PERMISSION] Résultat de la demande: $result');
      return result == PermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      print('🔍 [DEBUG PERMISSION] Permission définitivement refusée, ouverture des paramètres...');
      await openAppSettings();
      return false;
    }

    print('🔍 [DEBUG PERMISSION] Permission déjà accordée: ${status.isGranted}');
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