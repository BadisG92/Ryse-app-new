import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../models/nutrition_models.dart' as nutrition_models;
import '../models/openfoodfacts_models.dart';
import '../services/openfoodfacts_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../config/supabase_config.dart';
import '../types/database_types.dart';
import '../components/ui/nutrition_widgets.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool isFromDashboard;
  final Function(nutrition_models.FoodItem)? onFoodScanned;
  
  const BarcodeScannerScreen({
    super.key, 
    this.isFromDashboard = false,
    this.onFoodScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Camera + ML Kit variables
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;
  bool isCameraInitialized = false;
  bool isFlashOn = false;
  bool hasResult = false;
  bool isLoadingProduct = false;
  bool isProcessingBarcode = false;
  String? errorMessage;
  
  // Product variables
  OpenFoodFactsProduct? _scannedProduct;
  nutrition_models.FoodItem? _pendingDashboardFoodItem;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quantityController.text = '100';
    _initializeScanner();
  }

  @override
  void dispose() {
    _disposeCamera();
    _barcodeScanner?.close();
    _quantityController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeScanner() async {
    print('DEBUG: Initialisation du scanner...');
    print('DEBUG: Plateforme détectée: $defaultTargetPlatform');
    
    // Sur web, on ne peut pas utiliser la caméra avec ML Kit
    if (kIsWeb) {
      print('DEBUG: Plateforme Web détectée - caméra désactivée');
      setState(() {
        errorMessage = 'Scanner automatique non disponible sur web. Utilisez la saisie manuelle.';
      });
      return;
    }
    
    await _requestCameraPermission();
    await _initializeCamera();
    _barcodeScanner = BarcodeScanner();
    print('DEBUG: Scanner initialisé avec succès');
  }

  Future<void> _requestCameraPermission() async {
    print('DEBUG: Demande de permission caméra...');
    final status = await Permission.camera.request();
    print('DEBUG: Status permission caméra: $status');
    if (status != PermissionStatus.granted) {
      print('DEBUG: Permission caméra refusée');
      setState(() {
        errorMessage = 'Permission de caméra requise pour scanner les codes-barres';
      });
    } else {
      print('DEBUG: Permission caméra accordée');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      print('DEBUG: Recherche des caméras...');
      final cameras = await availableCameras();
      print('DEBUG: ${cameras.length} caméra(s) trouvée(s)');
      
      if (cameras.isEmpty) {
        print('DEBUG: Aucune caméra disponible');
        setState(() {
          errorMessage = 'Aucune caméra disponible';
        });
        return;
      }

      print('DEBUG: Création du CameraController...');
      _cameraController = CameraController(
        cameras.first,
        defaultTargetPlatform == TargetPlatform.iOS 
          ? ResolutionPreset.high  // iOS gère mieux la haute résolution pour la détection
          : ResolutionPreset.medium, // Android reste en medium pour les performances
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888  // Format optimal pour iOS + ML Kit
          : ImageFormatGroup.nv21,     // Format par défaut pour Android
      );

      print('DEBUG: Initialisation de la caméra...');
      await _cameraController!.initialize();
      print('DEBUG: Caméra initialisée avec succès');
      
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
          errorMessage = null;
        });
        
        print('DEBUG: Démarrage du stream d\'images...');
        // Commencer le stream d'images pour la détection
        _cameraController!.startImageStream(_detectBarcode);
        print('DEBUG: Stream d\'images démarré');
      }
    } catch (e) {
      print('DEBUG: Erreur lors de l\'initialisation: $e');
      setState(() {
        errorMessage = 'Erreur d\'initialisation de la caméra: $e';
      });
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  Future<void> _detectBarcode(CameraImage image) async {
    if (isProcessingBarcode || hasResult) return;

    print('DEBUG: Traitement d\'une image (${image.width}x${image.height})...');
    isProcessingBarcode = true;
    
    try {
      // Gestion différente selon la plateforme pour optimiser la détection
      late final InputImage inputImage;
      
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        print('DEBUG: Création InputImage pour iOS (bgra8888)');
        // Pour iOS: utiliser bgra8888 qui est plus performant
        inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _getImageRotation(),
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        print('DEBUG: Création InputImage pour Android (nv21)');
        // Pour Android: utiliser nv21 comme auparavant
        final bytes = _concatenatePlanes(image.planes);
        inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _getImageRotation(),
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      print('DEBUG: Recherche de codes-barres avec ML Kit...');
      final List<Barcode> barcodes = await _barcodeScanner!.processImage(inputImage);
      print('DEBUG: ${barcodes.length} code(s)-barres trouvé(s)');
      
      if (barcodes.isNotEmpty && mounted) {
        final barcode = barcodes.first;
        print('DEBUG: Code-barres détecté: ${barcode.rawValue}');
        if (barcode.rawValue != null) {
          print('DEBUG: Arrêt du stream et traitement du produit...');
          // Arrêter le stream d'images
          await _cameraController?.stopImageStream();
          // Traiter le code-barres détecté
          await _fetchProductData(barcode.rawValue!);
        }
      }
    } catch (e) {
      print('DEBUG: Erreur détection barcode: $e');
    } finally {
      isProcessingBarcode = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation _getImageRotation() {
    if (_cameraController == null) return InputImageRotation.rotation0deg;
    
    // Pour iOS, généralement portrait en mode normal
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputImageRotation.rotation90deg;
    } else {
      // Pour Android, peut varier selon l'orientation
      return InputImageRotation.rotation0deg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: hasResult ? _buildResultScreen() : _buildScannerScreen(),
      ),
    );
  }

  Widget _buildScannerScreen() {
    return Stack(
      children: [
        // Vue caméra
        _buildCameraView(),
        
        // Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Row(
                children: [
                  // Bouton flash
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        isFlashOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
                        color: isFlashOn ? Colors.yellow : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton saisie manuelle
                  GestureDetector(
                    onTap: _showManualBarcodeInput,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        LucideIcons.type,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Zone de scan overlay
        Center(
          child: Container(
            width: 280,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Coins de la zone de scan
                _buildScanCorners(),
                
                // Loading indicator during product fetch
                if (isLoadingProduct)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                ),
              ],
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          bottom: 200,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.scan,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  isLoadingProduct ? 'Récupération du produit...' : 'Scannez le code-barres',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  isLoadingProduct 
                      ? 'Recherche dans la base de données...'
                      : 'Placez le code-barres dans la zone de scan',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        // Bouton saisie manuelle en bas
        if (!isLoadingProduct)
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showManualBarcodeInput,
                icon: const Icon(
                  LucideIcons.type,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Saisir le code manuellement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScanCorners() {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: -2,
          left: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF0B132B), width: 4),
                left: BorderSide(color: Color(0xFF0B132B), width: 4),
              ),
            ),
          ),
        ),
        // Top-right corner
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF0B132B), width: 4),
                right: BorderSide(color: Color(0xFF0B132B), width: 4),
              ),
            ),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: -2,
          left: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF0B132B), width: 4),
                left: BorderSide(color: Color(0xFF0B132B), width: 4),
              ),
            ),
          ),
        ),
        // Bottom-right corner
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF0B132B), width: 4),
                right: BorderSide(color: Color(0xFF0B132B), width: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView() {
    if (errorMessage != null) {
      return _buildErrorView();
    } else if (isCameraInitialized && _cameraController != null) {
      return _buildCameraPreview();
    } else {
      return _buildLoadingView();
    }
  }

  Widget _buildCameraPreview() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                kIsWeb ? LucideIcons.monitor : LucideIcons.cameraOff,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (kIsWeb)
                ElevatedButton(
                  onPressed: _showManualBarcodeInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Saisir un code-barres',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _initializeCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    try {
      setState(() {
        isFlashOn = !isFlashOn;
      });
      
      if (_cameraController != null) {
        await _cameraController!.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }
    } catch (e) {
      print('Erreur toggle flash: $e');
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  void _showManualBarcodeInput() {
    final TextEditingController barcodeController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.type,
                      color: Color(0xFF0B132B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Saisie manuelle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrez le code-barres du produit que vous souhaitez ajouter :',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: barcodeController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B132B),
                          width: 2,
                        ),
                      ),
                      hintText: 'Ex: 3229820129488',
                      prefixIcon: const Icon(
                        LucideIcons.scan,
                        color: Colors.grey,
                      ),
                      suffixIcon: barcodeController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                barcodeController.clear();
                                setState(() {});
                              },
                              icon: const Icon(LucideIcons.x),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Exemples de codes-barres pour les tests
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 Codes-barres de test :',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            barcodeController.text = '3229820129488';
                            setState(() {});
                          },
                          child: const Text(
                            '• 3229820129488 (Muesli Bjorg)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            barcodeController.text = '3017620422003';
                            setState(() {});
                          },
                          child: const Text(
                            '• 3017620422003 (Nutella)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            barcodeController.text = '7622210951557';
                            setState(() {});
                          },
                          child: const Text(
                            '• 7622210951557 (KitKat Chunky)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: (barcodeController.text.isNotEmpty && !isLoading)
                      ? () async {
                          setState(() => isLoading = true);
                          Navigator.pop(context);
                          await _fetchProductData(barcodeController.text);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Rechercher',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchProductData(String barcode) async {
    setState(() {
      isLoadingProduct = true;
    });

    try {
      final product = await OpenFoodFactsService.getProduct(barcode);

      if (OpenFoodFactsService.isProductFound(product)) {
        setState(() {
          _scannedProduct = product;
          _quantityController.text = product.defaultQuantity.round().toString();
          isLoadingProduct = false;
          hasResult = true;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = OpenFoodFactsService.getErrorMessage(product);
          isLoadingProduct = false;
          hasResult = true;
          _scannedProduct = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la récupération du produit';
        isLoadingProduct = false;
        hasResult = true;
        _scannedProduct = null;
      });
    }
  }

  Widget _buildResultScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    errorMessage != null ? 'Erreur' : 'Produit trouvé',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: errorMessage != null ? _buildErrorContent() : _buildProductContent(),
          ),
          
          if (errorMessage == null && _scannedProduct != null)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.x,
            size: 64,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vérifiez que le code-barres est lisible et réessayez.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  hasResult = false;
                  errorMessage = null;
                  _scannedProduct = null;
                });
                _initializeCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scanner un autre produit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    if (_scannedProduct == null) return const SizedBox();

    return StatefulBuilder(
      builder: (context, setModalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du produit
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _scannedProduct!.imageUrl != null && _scannedProduct!.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _scannedProduct!.imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 200,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
              ),
              
              const SizedBox(height: 20),
              
              // Informations du produit
              Text(
                _scannedProduct!.productName ?? 'Produit sans nom',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _buildProductSubtitle(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Informations nutritionnelles
              if (_scannedProduct!.nutriments != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      // Calories en premier
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            '${_getCalculatedCalories().round()} kcal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0B132B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Protéines
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Protéines',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${_getCalculatedProtein().toStringAsFixed(1)} g',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Glucides
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Glucides',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${_getCalculatedCarbs().toStringAsFixed(1)} g',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Lipides
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lipides',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '${_getCalculatedFat().toStringAsFixed(1)} g',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Quantité
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _scannedProduct?.unit ?? 'grammes',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Bouton principal : Ajouter au repas
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: errorMessage == null ? _handleAddToMeal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ajouter au repas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton tertiaire : Scanner un autre produit
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  hasResult = false;
                  errorMessage = null;
                  _scannedProduct = null;
                });
                _initializeCamera();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(
                  color: Color(0xFF0B132B),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Scanner un autre produit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0B132B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildProductSubtitle() {
    final parts = <String>[];
    
    if (_scannedProduct!.brands != null && _scannedProduct!.brands!.isNotEmpty) {
      parts.add('Marque: ${_scannedProduct!.brands!}');
    }
    
    if (_scannedProduct!.quantity != null && _scannedProduct!.quantity!.isNotEmpty) {
      parts.add(_scannedProduct!.quantity!);
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'Aucune information supplémentaire';
  }

  double _getCalculatedCalories() {
    if (_scannedProduct?.nutriments == null) return 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    return (_scannedProduct!.nutriments!.caloriesPer100g * quantity / 100);
  }

  double _getCalculatedProtein() {
    if (_scannedProduct?.nutriments == null) return 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    return (_scannedProduct!.nutriments!.proteinsPer100g * quantity / 100);
  }

  double _getCalculatedCarbs() {
    if (_scannedProduct?.nutriments == null) return 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    return (_scannedProduct!.nutriments!.carbohydratesPer100g * quantity / 100);
  }

  double _getCalculatedFat() {
    if (_scannedProduct?.nutriments == null) return 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    return (_scannedProduct!.nutriments!.fatPer100g * quantity / 100);
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.package,
            size: 48,
            color: Color(0xFF64748B),
          ),
          SizedBox(height: 8),
          Text(
            'Image du produit',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aucune image disponible',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddToMeal() {
    if (_scannedProduct == null) return;
    
    if (widget.isFromDashboard) {
      // Mode dashboard
      final quantity = double.tryParse(_quantityController.text) ?? 100.0;
      final unit = _scannedProduct!.unit;
      final foodItem = nutrition_models.FoodItem(
        name: _scannedProduct!.productName ?? 'Produit scanné',
        calories: _getCalculatedCalories().round(),
        proteins: _getCalculatedProtein(),
        carbs: _getCalculatedCarbs(),
        fats: _getCalculatedFat(),
        portion: '${quantity.round()} $unit',
        isScanned: true,
      );
      
      _handleDashboardFoodSelection(foodItem);
    } else {
      // Mode journal
      _showSaveChoiceDialog();
    }
  }

  void _handleDashboardFoodSelection(nutrition_models.FoodItem foodItem) {
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
    } else {
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          NutritionQuickActionsSection.showMealSelectionWithDetectedFood(context, foodItem);
        }
      });
    }
  }

  void _showSaveChoiceDialog() async {
    if (_scannedProduct == null) return;
    
    final user = AuthService().currentUser;
    if (user != null && _scannedProduct!.barcode != null) {
      final existingFood = await DatabaseService.checkCustomFoodExistsByBarcode(
        user.id, 
        _scannedProduct!.barcode!
      );
      
      if (existingFood != null) {
        await _addExistingScannedFood(existingFood);
        return;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.scan,
                    size: 32,
                    color: Color(0xFF0B132B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sauvegarder l\'aliment ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Souhaitez-vous ajouter "${_scannedProduct!.productName ?? 'ce produit'}" à vos aliments personnalisés pour une réutilisation future ?',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _addScannedFoodDirectly();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Non, juste ajouter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveAndAddScannedFood();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Oui, sauvegarder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addExistingScannedFood(Food existingFood) async {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final unit = _scannedProduct!.unit;
    
    final foodItem = nutrition_models.FoodItem(
      id: existingFood.id,
      name: existingFood.getLocalizedName('fr'),
      calories: _getCalculatedCalories().round(),
      proteins: _getCalculatedProtein(),
      carbs: _getCalculatedCarbs(),
      fats: _getCalculatedFat(),
      portion: '${quantity.round()} $unit',
      isCustom: true,
      isScanned: true,
    );
    
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
    } else {
      _closeScreenWithSnackBar();
    }
  }

  Future<void> _addScannedFoodDirectly() async {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final unit = _scannedProduct!.unit;
    
    String productName = _scannedProduct!.productName ?? 
                        _scannedProduct!.brands ?? 
                        'Produit scanné ${_scannedProduct!.barcode ?? ''}';
    
    final foodItem = nutrition_models.FoodItem(
      name: productName,
      calories: _getCalculatedCalories().round(),
      proteins: _getCalculatedProtein(),
      carbs: _getCalculatedCarbs(),
      fats: _getCalculatedFat(),
      portion: '${quantity.round()} $unit',
      isCustom: false,
      isScanned: true,
    );
    
    if (widget.onFoodScanned != null) {
      Navigator.pop(context);
      widget.onFoodScanned!(foodItem);
    } else {
      _closeScreenWithSnackBar();
    }
  }

  Future<void> _saveAndAddScannedFood() async {
    if (_scannedProduct == null) return;

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous devez être connecté pour sauvegarder un aliment'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String productName = _scannedProduct!.productName ?? 
                          _scannedProduct!.brands ?? 
                          'Produit scanné ${_scannedProduct!.barcode ?? ''}';

      final currentQuantity = double.tryParse(_quantityController.text) ?? 100.0;
      final originalCalories = _scannedProduct!.nutriments?.energyKcal100g ?? 0.0;
      final originalProteins = _scannedProduct!.nutriments?.proteins100g ?? 0.0;
      final originalCarbs = _scannedProduct!.nutriments?.carbohydrates100g ?? 0.0;
      final originalFats = _scannedProduct!.nutriments?.fat100g ?? 0.0;

      final isWeightBasedUnit = _scannedProduct!.unit == 'g' || _scannedProduct!.unit == 'ml';
      
      final finalCalories = isWeightBasedUnit ? originalCalories.round() : _getCalculatedCalories().round();
      final finalProteins = isWeightBasedUnit ? originalProteins : _getCalculatedProtein();
      final finalCarbs = isWeightBasedUnit ? originalCarbs : _getCalculatedCarbs();
      final finalFats = isWeightBasedUnit ? originalFats : _getCalculatedFat();
      final finalQuantity = isWeightBasedUnit ? 100.0 : currentQuantity;
      final finalUnit = _scannedProduct!.unit;

      final customFood = {
        'user_id': user.id,
        'name': productName,
        'calories': finalCalories,
        'proteins': finalProteins,
        'carbs': finalCarbs,
        'fats': finalFats,
        'reference_quantity': finalQuantity,
        'reference_unit_fr': finalUnit,
        'reference_unit_en': finalUnit,
        'origin': 'barcode',
        'barcode': _scannedProduct!.barcode,
      };

      final response = await SupabaseConfig.client
          .from('custom_foods')
          .insert(customFood)
          .select()
          .single();

      final userQuantity = double.tryParse(_quantityController.text) ?? 100.0;
      final userUnit = _scannedProduct!.unit;
      
      final foodItem = nutrition_models.FoodItem(
        id: response['id'].toString(),
        name: productName,
        calories: _getCalculatedCalories().round(),
        proteins: _getCalculatedProtein(),
        carbs: _getCalculatedCarbs(),
        fats: _getCalculatedFat(),
        portion: '${userQuantity.round()} $userUnit',
        isCustom: true,
        isScanned: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName ajouté à vos aliments personnalisés'),
            backgroundColor: const Color(0xFF0B132B),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (widget.onFoodScanned != null) {
        Navigator.pop(context);
        widget.onFoodScanned!(foodItem);
      } else {
        _closeScreenWithSnackBar();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _closeScreenWithSnackBar() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    Navigator.pop(context);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Produit ajouté au repas'),
        backgroundColor: Color(0xFF0B132B),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
        ),
      ),
    );
  }
}