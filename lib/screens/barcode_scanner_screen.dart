import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

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
  late MobileScannerController controller;
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
    // Demander la permission d'utiliser la caméra
    final permission = await Permission.camera.request();
    
    if (permission == PermissionStatus.granted) {
      setState(() {
        isPermissionGranted = true;
      });
      
      // Initialiser le contrôleur du scanner
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isPermissionGranted = false;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (isPermissionGranted) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.displayValue;
      
      if (code != null && code.isNotEmpty) {
        setState(() {
          isProcessing = true;
          scannedBarcode = code;
        });
        
        _handleScannedBarcode(code);
      }
    }
  }

  void _handleScannedBarcode(String barcode) async {
    // Vibration légère pour indiquer la détection
    // HapticFeedback.lightImpact();
    
    try {
      // Simuler la recherche du produit
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Créer un objet simple avec le code-barres
      final locService = Provider.of<LocalizationService>(context, listen: false);
      final scannedData = {
        'barcode': barcode,
        'name': 'scanned_product'.tr(locService.currentLanguageCode) + ': $barcode',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (widget.isFromDashboard && widget.onFoodScanned != null) {
        // Retourner les données au dashboard
        widget.onFoodScanned!(scannedData);
        Navigator.of(context).pop();
      } else {
        // Afficher le résultat
        _showResultDialog(barcode);
      }
    } catch (e) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      _showErrorDialog('product_search_error'.tr(locService.currentLanguageCode) + ': $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showResultDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LocalizationService>(
          builder: (context, locService, child) => Text(
            'barcode_scanned'.tr(locService.currentLanguageCode),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                'detected_barcode'.tr(locService.currentLanguageCode),
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
                'integrate_functionality'.tr(locService.currentLanguageCode),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retourner à l'écran précédent
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
                'scan_another'.tr(locService.currentLanguageCode),
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
            'error'.tr(locService.currentLanguageCode),
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
            'barcode_scanner'.tr(locService.currentLanguageCode),
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
          if (isPermissionGranted && !isLoading)
            IconButton(
              icon: const Icon(LucideIcons.flashlight, color: Colors.black),
              onPressed: () => controller.toggleTorch(),
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
                'camera_initialization'.tr(locService.currentLanguageCode),
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
                'camera_permission_required'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                'allow_camera_access_barcode'.tr(locService.currentLanguageCode),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'open_settings'.tr(locService.currentLanguageCode),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Scanner de codes-barres
        MobileScanner(
          controller: controller,
          onDetect: _onBarcodeDetected,
        ),
        
        // Overlay avec instructions
        _buildScannerOverlay(),
        
        // Indicateur de traitement
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
                      'searching_product'.tr(locService.currentLanguageCode),
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
                // Coins du cadre
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
                      'place_barcode_in_frame'.tr(locService.currentLanguageCode),
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