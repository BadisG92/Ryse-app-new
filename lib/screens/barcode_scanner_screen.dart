import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final Function(dynamic)? onFoodScanned;

  const BarcodeScannerScreen({
    super.key,
    this.isFromDashboard = false,
    this.onFoodScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  CameraController? controller;
  bool isPermissionGranted = false;
  bool isLoading = true;
  String? scannedBarcode;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      print('🔍 [iOS 18 WORKAROUND] === DÉBUT INITIALISATION CAMÉRA ===');

      // iOS 18 Workaround: Utiliser directement availableCameras()
      // Le package camera va automatiquement demander les permissions
      print('🔍 [iOS 18 WORKAROUND] Recherche des caméras (iOS va demander permission)...');

      final cameras = await availableCameras();
      print('🔍 [iOS 18 WORKAROUND] Caméras trouvées: ${cameras.length}');

      if (cameras.isEmpty) {
        print('🔍 [iOS 18 WORKAROUND] ATTENTION: Aucune caméra disponible (simulateur?)');
        setState(() {
          isPermissionGranted = true; // Marquer comme ayant permission pour afficher l'UI
          isLoading = false;
        });
        return;
      }

      print('🔍 [iOS 18 WORKAROUND] Initialisation du contrôleur de caméra...');

      // Initialisation de la caméra - ceci va déclencher la demande de permission iOS native
      controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
      print('🔍 [iOS 18 WORKAROUND] ✅ Caméra initialisée avec succès - Permission accordée!');

      if (mounted) {
        setState(() {
          isPermissionGranted = true;
          isLoading = false;
        });
      }

      print('🔍 [iOS 18 WORKAROUND] === FIN INITIALISATION CAMÉRA ===');

    } catch (e, stackTrace) {
      print('🔍 [iOS 18 WORKAROUND] ❌ ERREUR (probablement permission refusée): $e');

      // Analyser le type d'erreur pour donner un feedback approprié
      final errorMsg = e.toString().toLowerCase();
      final isPermissionError = errorMsg.contains('permission') ||
                               errorMsg.contains('authorized') ||
                               errorMsg.contains('access');

      if (mounted) {
        setState(() {
          isPermissionGranted = !isPermissionError; // Si pas d'erreur de permission, considérer comme OK
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  void _simulateBarcodeDetection() {
    if (isProcessing) return;

    // Simulate barcode detection with a mock barcode
    final mockBarcode = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      isProcessing = true;
      scannedBarcode = mockBarcode;
    });

    _handleScannedBarcode(mockBarcode);
  }

  void _handleScannedBarcode(String barcode) async {
    try {
      // Simulate product search
      await Future.delayed(const Duration(milliseconds: 500));

      // Create simple object with barcode
      if (!mounted) return;
      final locService = Provider.of<LocalizationService>(context, listen: false);
      final scannedData = {
        'barcode': barcode,
        'name': locService.currentLanguageCode == 'fr' ? 'Produit scanné: $barcode' : 'Scanned product: $barcode',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (widget.isFromDashboard && widget.onFoodScanned != null) {
        // Return data to dashboard
        widget.onFoodScanned!(scannedData);
        if (mounted) Navigator.of(context).pop();
      } else {
        // Show result dialog
        _showResultDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      final locService = Provider.of<LocalizationService>(context, listen: false);
      _showErrorDialog(locService.currentLanguageCode == 'fr' ? 'Erreur lors de la recherche du produit: $e' : 'Error searching for product: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _showResultDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Code-barres scanné !' : 'Barcode scanned!',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Code-barres détecté :' : 'Detected barcode:',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                barcode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Vous pouvez maintenant intégrer cette fonctionnalité avec votre système de gestion des aliments.' : 'You can now integrate this functionality with your food management system.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isProcessing = false;
                scannedBarcode = null;
              });
            },
            child: Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Scanner un autre' : 'Scan another',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Erreur' : 'Error',
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isProcessing = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            locService.currentLanguageCode == 'fr' ? 'Scanner de codes-barres' : 'Barcode Scanner',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (isPermissionGranted && !isLoading && controller != null)
            IconButton(
              icon: const Icon(LucideIcons.flashlight, color: Colors.black),
              onPressed: () async {
                try {
                  await controller!.setFlashMode(
                    controller!.value.flashMode == FlashMode.off
                      ? FlashMode.torch
                      : FlashMode.off
                  );
                } catch (e) {
                  // Flash not supported
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Initialisation de la caméra...' : 'Initializing camera...',
              ),
            ),
          ],
        ),
      );
    }

    if (!isPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.camera,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Permission caméra requise' : 'Camera permission required',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                locService.currentLanguageCode == 'fr' ? 'Autorisez l\'accès à la caméra pour scanner les codes-barres' : 'Allow camera access to scan barcodes',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    await _initializeCamera();
                  },
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Réessayer' : 'Try again',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    // iOS 18 Workaround: Informer l'utilisateur d'aller manuellement aux paramètres
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            locService.currentLanguageCode == 'fr' ? 'Paramètres iOS' : 'iOS Settings',
                          ),
                        ),
                        content: Consumer<LocalizationService>(
                          builder: (context, locService, child) => Text(
                            locService.currentLanguageCode == 'fr'
                              ? 'Veuillez aller dans Paramètres > Confidentialité et sécurité > Appareil photo et activer l\'accès pour cette app.'
                              : 'Please go to Settings > Privacy & Security > Camera and enable access for this app.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Aide pour les paramètres' : 'Settings help',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview or placeholder
        if (controller != null && controller!.value.isInitialized)
          Positioned.fill(
            child: CameraPreview(controller!),
          )
        else
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        locService.currentLanguageCode == 'fr'
                          ? 'Caméra simulée\n(Fonctionne sur appareil réel)'
                          : 'Simulated camera\n(Works on real device)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Overlay with instructions
        _buildScannerOverlay(),

        // Processing indicator
        if (isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Recherche du produit...' : 'Searching product...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black54,
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 50),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner indicators
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.green, width: 4),
                        left: BorderSide(color: Colors.green, width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.green, width: 4),
                        right: BorderSide(color: Colors.green, width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.green, width: 4),
                        left: BorderSide(color: Colors.green, width: 4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.green, width: 4),
                        right: BorderSide(color: Colors.green, width: 4),
                      ),
                    ),
                  ),
                ),
                // Tap to scan button
                Center(
                  child: GestureDetector(
                    onTap: _simulateBarcodeDetection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' ? 'Toucher pour scanner' : 'Tap to scan',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, child) => Text(
                      locService.currentLanguageCode == 'fr' ? 'Placez le code-barres dans le cadre et touchez pour scanner' : 'Place the barcode within the frame and tap to scan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}